#!/bin/bash

DATASHARE_VERSION=__version__

DATA_PATH="/Users/${USER}/Datashare"
INDEX_PATH="/Users/${USER}/Library/Datashare/Index"

mkdir -p "${INDEX_PATH}"

if [[ -z "${DS_JAVA_OPTS}" ]]; then
    mem_allocated=$(sysctl -a | grep hw.memsize | awk '{print $2"/(2*1024^2)"}' | bc)
    DS_JAVA_OPTS="-Xmx${mem_allocated}m"
fi

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

cd "/Users/${USER}/Library/Datashare" || exit # needed for /app and /dist

java -cp "./dist:/Applications/Datashare/Contents/Resources/datashare-dist-${DATASHARE_VERSION}.jar" \
    -DPROD_MODE=true org.icij.datashare.Main -d "$DATA_PATH" --queueType memory --busType memory \
    --dataSourceUrl jdbc:sqlite:file:"/Users/${USER}/Library/Datashare/dist/datashare.db" \
    --configFile ./dist/datashare.conf --mode EMBEDDED \
    --elasticsearchDataPath "$INDEX_PATH"

wait_datashare_is_up

open http://localhost:8080
