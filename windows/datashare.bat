@echo off

:: Get the directory of the current file
set "CURRENT_DIR=%~dp0"
:: Remove the trailing backslash for consistency in path usage
if "%CURRENT_DIR:~-1%"=="\" set "CURRENT_DIR=%CURRENT_DIR:~0,-1%"

:: Check if we are in the AppData/Roaming directory and try to find the installation directory
if /i "%CURRENT_DIR%"=="%APPDATA%\Datashare" (
    if exist "%ProgramFiles%\Datashare\datashare.bat" (
        set "CURRENT_DIR=%ProgramFiles%\Datashare"
    )
)

:: Ensure the current dir is active
cd /d "%CURRENT_DIR%"

:: Check if the Datashare JAR exists in the current directory
set "JAR_FILE="
for %%f in ("%CURRENT_DIR%\datashare-dist-*-all.jar") do set "JAR_FILE=%%f"

if not defined JAR_FILE (
    echo Datashare JAR file not found in %CURRENT_DIR%.
    echo Please ensure you are running this script from the installation directory.
    pause
    exit /b 1
)

:: Create the dist and default directories in current dir if they don't exist
for %%d in (dist data index plugins extensions) do (
    if not exist "%CURRENT_DIR%\%%d\" mkdir "%CURRENT_DIR%\%%d"
)

:: Filter for java version 21
set java_exe=
set "JAVA_VER="
for /f "tokens=3" %%g in ('java -version 2^>^&1 ^| findstr /i "version"') do (
    set JAVA_VER=%%g
)

if not defined JAVA_VER (
    echo Java is not installed or not in PATH.
    pause
    exit /b 1
)

set JAVA_VER=%JAVA_VER:"=%

for /f "delims=. tokens=1" %%v in ("%JAVA_VER%") do (
    set JAVA_MAJOR_VER=%%v
)

if "%JAVA_MAJOR_VER%" == "21" (
    set java_exe=java
)

if "%java_exe%" == "" (
    echo Java 21 is required. Found version %JAVA_VER%.
    pause
    exit /b 1
)

:: Set JVM options (include user-defined DS_JAVA_OPTS if they exist)
set DS_JAVA_OPTS=%DS_JAVA_OPTS% --add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.util=ALL-UNNAMED --add-opens java.base/java.net=ALL-UNNAMED -DPROD_MODE=true -Dfile.encoding=UTF-8 -Djava.system.class.loader=org.icij.datashare.DynamicClassLoader

%java_exe% -cp "dist;%JAR_FILE%" ^
  %DS_JAVA_OPTS% org.icij.datashare.Main ^
  --dataDir "%CURRENT_DIR%"\data ^
  --batchQueueType MEMORY ^
  --queueType MEMORY ^
  --busType MEMORY ^
  --dataSourceUrl jdbc:sqlite:file:"%CURRENT_DIR%"\dist\datashare.db ^
  --settings "%CURRENT_DIR%"\dist\datashare.conf ^
  --mode EMBEDDED ^
  --browserOpenLink true ^
  --elasticsearchPath "%CURRENT_DIR%"\elasticsearch ^
  --elasticsearchSettings "%CURRENT_DIR%"\elasticsearch.yml ^
  --elasticsearchDataPath "%CURRENT_DIR%"\index ^
  --pluginsDir "%CURRENT_DIR%"\plugins ^
  --extensionsDir "%CURRENT_DIR%"\extensions ^
  --batchDownloadDir "%CURRENT_DIR%"\downloads
pause
