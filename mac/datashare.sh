#!/bin/bash

datashare_version=${VERSION}
redis_image=redis:4.0.1-alpine
elasticsearch_image=docker.elastic.co/elasticsearch/elasticsearch:6.3.0
data_path="/Users/\${USER}/Desktop/Datashare Data"
dist_path="/Users/\${USER}/Library/Datashare Models"

function create_docker_compose_file {
cat > /tmp/datashare.yml << EOF
version: '2'
services:
  image: icij/datashare:\${datashare_version}
    command:
      -w
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

create_docker_compose_file
docker-compose -f /tmp/datashare.yml -p datashare up -d

wait_datashare_is_up
open http://localhost:8080
