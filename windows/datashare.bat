@echo off

:: Get the directory of the current file
set "CURRENT_DIR=%~dp0"

:: Remove the trailing backslash for consistency in path usage
set "CURRENT_DIR=%CURRENT_DIR:~0,-1%"

:: Ensure the current dir is active
cd "%CURRENT_DIR%"

FOR /F "tokens=*" %%i IN ('where -f java ^| findstr -R "[jdk|jre]-" ^| findstr -R -v "[jdk|jre]-[0-9]\. [jdk|jre]-1[0-6]" ^| cmd /e /v /q /c"set/p.=&&echo(^!.^!"') do SET java_exe=%%i
%java_exe% -cp "dist;%CURRENT_DIR%\datashare-dist-${VERSION}-all.jar" ^
  --add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.util=ALL-UNNAMED --add-opens java.base/java.net=ALL-UNNAMED ^
  -DPROD_MODE=true -Dfile.encoding=UTF-8 ^
  -Djava.system.class.loader=org.icij.datashare.DynamicClassLoader org.icij.datashare.Main ^
  --dataDir "%CURRENT_DIR%"\data ^
  --batchQueueType MEMORY ^
  --queueType MEMORY ^
  --busType MEMORY ^
  --dataSourceUrl jdbc:sqlite:file:"%CURRENT_DIR%"\dist\datashare.db ^
  --settings "%CURRENT_DIR%"\dist\datashare.conf ^
  --mode EMBEDDED ^
  --browserOpenLink true ^
  --elasticsearchDataPath "%CURRENT_DIR%"\index ^
  --pluginsDir "%CURRENT_DIR%"\plugins ^
  --extensionsDir "%CURRENT_DIR%"\extensions
pause
