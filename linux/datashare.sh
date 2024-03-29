#!/bin/sh

datashare_version=__version__
redis_image=redis:4.0.1-alpine
elasticsearch_image=docker.elastic.co/elasticsearch/elasticsearch:7.9.1

DATASHARE_HOME="${HOME}"/.local/share/datashare
mkdir -p "${DATASHARE_HOME}"/dist "${DATASHARE_HOME}"/index "${DATASHARE_HOME}"/plugins "${DATASHARE_HOME}"/extensions "${HOME}"/Datashare

MEM_ALLOCATED_MEGA=$(LC_ALL=C free|awk '/^M[^:]+:/{print $2"/(2*1024)"}'|bc)
BIND_HOST=127.0.0.1

if [ -z "${DS_JAVA_OPTS}" ] && [ -n "${MEM_ALLOCATED_MEGA}" ]; then
  DS_JAVA_OPTS="-Xmx${MEM_ALLOCATED_MEGA}m"
fi

docker_compose () {
  if ! command -v docker-compose &> /dev/null
  then
    docker compose --compatibility $@
  else
    docker-compose $@
  fi
}

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
    volumes:
      - ${DATASHARE_HOME}/index:/usr/share/elasticsearch/data
    environment:
      - "ES_JAVA_OPTS=${DS_JAVA_OPTS}"
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
docker_compose -f /tmp/datashare.yml -p datashare up -d

echo "binding data directory to ${DATA_DIR}"
echo "binding NER models directory to ${DATASHARE_HOME}/dist"

image_running=$(docker inspect --format='{{.Config.Image}}' datashare 2>/dev/null)
if [ -n "${image_running}" ]; then
  docker rm -f datashare > /dev/null
fi

docker run -p $BIND_HOST:8080:8080 --network datashare_default --name datashare --rm -e DS_JAVA_OPTS="${DS_JAVA_OPTS}" \
 -e DS_DOCKER_MOUNTED_DATA_DIR=${HOME}/Datashare -v ${HOME}/Datashare:/home/datashare/data:ro \
 -v ${DATASHARE_HOME}/plugins:/home/datashare/plugins -v ${DATASHARE_HOME}/extensions:/home/datashare/extensions \
 -v ${DATASHARE_HOME}/dist:/home/datashare/dist -ti icij/datashare:${datashare_version} --dataSourceUrl jdbc:sqlite:/home/datashare/dist/database.sqlite \
 --pluginsDir /home/datashare/plugins  --extensionsDir /home/datashare/extensions "$@"
