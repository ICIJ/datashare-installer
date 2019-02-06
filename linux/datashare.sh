#!/bin/sh

datashare_version=1.10
redis_image=redis:4.0.1-alpine
elasticsearch_image=docker.elastic.co/elasticsearch/elasticsearch:6.3.0

MODELS_DIR=${MODELS_DIR:-${HOME}/.local/share/Datashare_Models}
mkdir -p ${MODELS_DIR}
DATA_DIR=${DATA_DIR:-${HOME}/Datashare}
mkdir -p ${DATA_DIR}
MEM_ALLOCATED_MEGA=$(free|awk '/^Mem:/{print $2"/(2*1024)"}'|bc)

if [ -z "${DS_JAVA_OPTS}" ]; then
  DS_JAVA_OPTS="-Xmx${MEM_ALLOCATED_MEGA}m"
fi

create_docker_compose_file () {
cat > /tmp/datashare.yml << EOF
version: '2'
services:
  redis:
    image: ${redis_image}
    restart: on-failure

  elasticsearch:
    image: ${elasticsearch_image}
    restart: on-failure
    environment:
      - "ES_JAVA_OPTS=-Xmx${MEM_ALLOCATED_MEGA}m"
      - "http.host=0.0.0.0"
      - "transport.host=0.0.0.0"
      - "cluster.name=datashare"
      - "discovery.type=single-node"
      - "discovery.zen.minimum_master_nodes=1"
      - "xpack.license.self_generated.type=basic"
      - "http.cors.enabled=true"
      - "http.cors.allow-origin=*"
      - "http.cors.allow-methods=OPTIONS, HEAD, GET, POST, PUT, DELETE"
EOF
}

create_docker_compose_file
docker-compose -f /tmp/datashare.yml -p datashare up -d

echo "binding data directory to ${DATA_DIR}"
echo "binding NER models directory to ${MODELS_DIR}"

image_running=$(docker inspect --format='{{.Config.Image}}' datashare 2>/dev/null)
if [ -n "${image_running}" ]; then
  docker rm -f datashare > /dev/null
fi

docker run -p 8080:8080 --network datashare_default --name datashare --rm -e DS_JAVA_OPTS="${DS_JAVA_OPTS}" \
 -e DS_DOCKER_MOUNTED_DATA_DIR=${DATA_DIR} -v ${DATA_DIR}:/home/datashare/data:ro \
 -v ${MODELS_DIR}:/home/datashare/dist -ti icij/datashare:${datashare_version} "$@"
