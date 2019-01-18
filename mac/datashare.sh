#!/bin/bash

datashare_version=${VERSION}
redis_image=redis:4.0.1-alpine
elasticsearch_image=docker.elastic.co/elasticsearch/elasticsearch:6.3.0
data_path="\${HOME}/Datashare"
dist_path="/Users/\${USER}/Library/Datashare_Models"

function create_docker_compose_file {
cat > /tmp/datashare.yml << EOF
version: '2'
services:
  datashare:
    image: icij/datashare:\${datashare_version}
    command: "-w"
    ports:
      - "8080:8080"
    volumes:
      - "\${dist_path}:/home/datashare/dist"
      - "\${data_path}:/home/datashare/data:ro"

  redis:
    image: \${redis_image}
    ports:
      - 6379:6379

  elasticsearch:
    image: \${elasticsearch_image}
    environment:
      - "http.host=0.0.0.0"
      - "transport.host=0.0.0.0"
      - "cluster.name=datashare"
      - "discovery.type=single-node"
      - "discovery.zen.minimum_master_nodes=1"
      - "xpack.license.self_generated.type=basic"
      - "http.cors.enabled=true"
      - "http.cors.allow-origin=*"
      - "http.cors.allow-methods=OPTIONS, HEAD, GET, POST, PUT, DELETE"
    ports:
      - "9200:9200"
EOF
}

function wait_datashare_is_up {
    echo -n "waiting for datashare to be up..."
    for i in \`seq 1 300\`; do
        sleep 0.1
        curl --silent localhost:8080 > /dev/null
        if [ \$? -eq 0 ]; then
            echo "OK"
            return
        fi
    done
    echo "KO"
}

if [[ -z "\$(docker ps -q 2>/dev/null)" ]]; then
  echo -n "docker service is not running, launching it..."
  open --background -a Docker && while ! docker system info > /dev/null 2>&1; do sleep 1; done
  echo "OK"
fi

create_docker_compose_file

datashare_id=\$(docker-compose -f /tmp/datashare.yml -p datashare ps -q datashare)
datashare_status=\$(docker inspect ${datashare_id} -f "{{.State.Status}}")

if [[ "\${datashare_status}" == "running" ]]; then
    echo "datashare is \${datashare_status}, restarting it"
    docker-compose -f /tmp/datashare.yml -p datashare restart datashare
else
    docker-compose -f /tmp/datashare.yml -p datashare up -d
fi

wait_datashare_is_up
open http://localhost:8080
