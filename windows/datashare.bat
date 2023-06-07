@echo off

cd "%APPDATA%"\Datashare
set jre_version=11
FOR /F "tokens=*" %%i IN ('where -f java ^| findstr -R "[jdk|jre]-%jre_version%" ^|  cmd /e /v /q /c"set/p.=&&echo(^!.^!"') do SET java_exe=%%i
%java_exe% -cp "dist;\Program Files\Datashare\datashare-dist-${VERSION}-all.jar" ^
  --add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.util=ALL-UNNAMED ^
  -DPROD_MODE=true -Dfile.encoding=UTF-8 ^
  -Djava.system.class.loader=org.icij.datashare.DynamicClassLoader org.icij.datashare.Main ^
  --dataDir "%APPDATA%"\Datashare\data ^
  --batchQueueType MEMORY ^
  --queueType MEMORY ^
  --busType MEMORY ^
  --dataSourceUrl jdbc:sqlite:file:"%APPDATA%"\Datashare\dist\datashare.db ^
  --settings "%APPDATA%"\Datashare\dist\datashare.conf ^
  --mode EMBEDDED ^
  --browserOpenLink true ^
  --elasticsearchDataPath "%APPDATA%"\Datashare\index ^
  --pluginsDir "%APPDATA%"\Datashare\plugins ^
  --extensionsDir "%APPDATA%"\Datashare\extensions
pause
