$VERSION=$args[0]

cd $Env:APPDATA\Datashare # needed for /dist

java -cp "dist;\Program Files\Datashare-$VERSION\Datashare-$VERSION-all.jar" -DPROD_MODE=true org.icij.datashare.Main `
    -d $Env:APPDATA\Datashare\data --queueType memory --busType memory `
    --dataSourceUrl jdbc:sqlite:file:$Env:APPDATA\Datashare\dist\datashare.db `
    --configFile $Env:APPDATA\Datashare\dist\datashare.conf --mode EMBEDDED `
    --elasticsearchDataPath $Env:APPDATA\Datashare\index
