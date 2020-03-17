#!/bin/bash

DATASHARE_VERSION=__version__

DATA_PATH="/Users/${USER}/Datashare"
INDEX_PATH="/Users/${USER}/Library/Datashare/index"
JAVA=/Library/Java/JavaVirtualMachines/adoptopenjdk-8.jdk/Contents/Home/bin/java

mkdir -p "${INDEX_PATH}"

if [[ -z "${DS_JAVA_OPTS}" ]]; then
    mem_allocated=$(sysctl -a | grep hw.memsize | awk '{print $2"/(2*1024^2)"}' | bc)
    DS_JAVA_OPTS="-Xmx${mem_allocated}m"
fi

cd "/Users/${USER}/Library/Datashare" || exit # needed for /app and /dist

$JAVA -cp "./dist:/Applications/Datashare.app/Contents/Resources/datashare-dist-${DATASHARE_VERSION}.jar" \
    -DPROD_MODE=true org.icij.datashare.Main -d "$DATA_PATH" --queueType memory --busType memory \
    --dataSourceUrl jdbc:sqlite:file:"/Users/${USER}/Library/Datashare/dist/datashare.db" \
    --configFile ./dist/datashare.conf --mode EMBEDDED \
    --elasticsearchDataPath "$INDEX_PATH"
