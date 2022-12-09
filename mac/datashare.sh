#!/bin/bash

datashare_version=__version__
redis_image=redis:4.0.1-alpine
elasticsearch_image=docker.elastic.co/elasticsearch/elasticsearch:7.9.1
data_path="${HOME}/Datashare"
dist_path="/Users/${USER}/Library/Datashare_Models"
index_path="/Users/${USER}/Library/Datashare_Index"
plugins_path="/Users/${USER}/Library/datashare/plugins"
extensions_path="/Users/${USER}/Library/datashare/extensions"
mkdir -p "${index_path}" "${plugins_path}" "${extensions_path}"

if [[ -z "${DS_JAVA_OPTS}" ]]; then
    mem_allocated=$(sysctl -a | grep hw.memsize | awk '{print $2"/(2*1024^2)"}' | bc)
    DS_JAVA_OPTS="-Xmx${mem_allocated}m"
fi

function docker_compose {
  if ! command -v docker-compose &> /dev/null
  then
    docker compose --compatibility $@
  else
    docker-compose $@
  fi
}

function create_docker_compose_file {
cat > /tmp/datashare.yml << EOF
version: '2'
services:
  datashare:
    image: icij/datashare:${datashare_version}
    restart: on-failure
    environment:
      - "DS_JAVA_OPTS=${DS_JAVA_OPTS}"
      - "DS_DOCKER_MOUNTED_DATA_DIR=${data_path}"
    command: --dataSourceUrl jdbc:sqlite:/home/datashare/dist/database.sqlite --pluginsDir /home/datashare/plugins --extensionsDir /home/datashare/extensions
    ports:
      - "127.0.0.1:8080:8080"
    volumes:
      - "${dist_path}:/home/datashare/dist"
      - "${data_path}:/home/datashare/data:ro"
      - "${plugins_path}:/home/datashare/plugins"
      - "${extensions_path}:/home/datashare/extensions"

  redis:
    image: ${redis_image}
    restart: on-failure

  elasticsearch:
    image: ${elasticsearch_image}
    restart: on-failure
    volumes:
      - ${index_path}:/usr/share/elasticsearch/data
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

function wait_datashare_is_up {
    echo -n "waiting for datashare to be up..."
    for i in `seq 1 300`; do
        sleep 0.1
        curl --silent localhost:8080 > /dev/null
        if [ $? -eq 0 ]; then
            echo "OK"
            return
        fi
    done
    echo "KO"
}

if [[ -z "$(docker ps -q 2>/dev/null)" ]]; then
  echo -n "docker service is not running, launching it..."
  open --background -a Docker && while ! docker system info > /dev/null 2>&1; do sleep 1; done
  echo "OK"
fi

create_docker_compose_file

datashare_id=$(docker_compose -f /tmp/datashare.yml -p datashare ps -q datashare)
if [[ -n "${datashare_id}" ]]; then
    datashare_status=$(docker inspect ${datashare_id} -f "{{.State.Status}}")
    datashare_running_version=$(docker inspect ${datashare_id} -f '{{.Config.Image}}' | awk -F ':' '{print $2}')
fi

if [[ "${datashare_status}" == "running" && "${datashare_running_version}" == "${datashare_version}" ]]; then
    echo "datashare is ${datashare_status}, restarting it"
    docker_compose -f /tmp/datashare.yml -p datashare restart datashare
else
    docker_compose -f /tmp/datashare.yml -p datashare up -d
fi

wait_datashare_is_up
open http://localhost:8080
