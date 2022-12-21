#!/bin/bash

# Get the path to the PID file
pid_file="/tmp/datashare.pid"
pid=$(cat $pid_file 2>/dev/null)
# Collect Datashare conviguration env
datashare_version=__version__
datashare_data_path="/Users/${USER}/Datashare"
datashare_index_path="/Users/${USER}/Library/Datashare/index"
datashare_plugins_path="/Users/${USER}/Library/datashare/plugins"
datashare_extensions_path="/Users/${USER}/Library/datashare/extensions"
# Java binary to use to start Datashare
java_bin=/Library/Java/JavaVirtualMachines/adoptopenjdk-8.jre/Contents/Home/bin/java

function on_exit_remove_pid_file {
    rm -f $pid_file
}

function save_pid {
    echo $$ > "$pid_file"
}

function start_datashare {
    mkdir -p "${datashare_index_path}" "${datashare_plugins_path}" "${datashare_extensions_path}"

    if [[ -z "${DS_JAVA_OPTS}" ]]; then
        mem_allocated=$(sysctl -a | grep hw.memsize | awk '{print $2"/(2*1024^2)"}' | bc)
        DS_JAVA_OPTS="-Xmx${mem_allocated}m"
    fi

    cd "/Users/${USER}/Library/Datashare" || exit # needed for /dist

    $java_bin \
        -DPROD_MODE=true \
        -Dfile.encoding=UTF-8 \
        -Djava.system.class.loader=org.icij.datashare.DynamicClassLoader \
        -cp "./dist:/Applications/Datashare.app/Contents/Resources/datashare-dist-${datashare_version}-all.jar" org.icij.datashare.Main \
        --data-dir "$datashare_data_path" \
        --queueType memory \
        --busType memory \
        --dataSourceUrl jdbc:sqlite:file:"/Users/${USER}/Library/Datashare/dist/datashare.db" \
        --settings ./dist/datashare.conf \
        --mode EMBEDDED \
        --browserOpenLink true \
        --elasticsearchDataPath "$datashare_index_path" \
        --pluginsDir "${datashare_plugins_path}" \
        --extensionsDir "${datashare_extensions_path}"
}

# Ensure the PID file is removed when the script exits
trap on_exit_remove_pid_file EXIT

# Check if the PID file exists and is already running
if [ -f "$pid_file" ] && kill -0 $pid > /dev/null 2>&1
then
    echo "Datashare is already running (PID: $pid)" 
else
    # If the PID file does not exist, store its PID in the PID file
    save_pid
    # Finally, start Datashare
    start_datashare
fi
