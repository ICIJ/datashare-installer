cd $Env:APPDATA\Datashare # needed for /app and /dist

java -cp "dist;\Program Files\Datashare-5.8.21\Datashare-5.8.21.jar" -DPROD_MODE=true org.icij.datashare.Main -d $Env:APPDATA\Datashare\data\ --queueType memory --busType memory --dataSourceUrl jdbc:sqlite:file:$Env:APPDATA\Datashare\dist\datashare.db --mode EMBEDDED --elasticsearchDataPath $Env:APPDATA\Datashare\es\