@echo off

cd %APPDATA%\Datashare

java -cp "dist;\Program Files\Datashare-${VERSION}\Datashare-${VERSION}-all.jar" -DPROD_MODE=true org.icij.datashare.Main -d %APPDATA%\Datashare\data --queueType memory --busType memory --dataSourceUrl jdbc:sqlite:file:%APPDATA%\Datashare\dist\datashare.db --settings %APPDATA%\Datashare\dist\datashare.conf --mode EMBEDDED --browserOpenLink true --elasticsearchDataPath %APPDATA%\Datashare\index
