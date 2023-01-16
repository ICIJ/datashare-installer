@echo off

cd "%APPDATA%"\Datashare
java -cp "dist;\Program Files\Datashare\datashare-dist-${VERSION}-all.jar" -DPROD_MODE=true -Dfile.encoding=UTF-8 -Djava.system.class.loader=org.icij.datashare.DynamicClassLoader org.icij.datashare.Main -d "%APPDATA%"\Datashare\data --queueType MEMORY --busType MEMORY --dataSourceUrl jdbc:sqlite:file:"%APPDATA%"\Datashare\dist\datashare.db --settings "%APPDATA%"\Datashare\dist\datashare.conf --mode EMBEDDED --browserOpenLink true --elasticsearchDataPath "%APPDATA%"\Datashare\index --pluginsDir "%APPDATA%"\Datashare\plugins --extensionsDir "%APPDATA%"\Datashare\extensions

