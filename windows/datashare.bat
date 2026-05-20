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

:: Detect whether the user is using the new subcommand style. Scan every arg
:: so parent-command options can appear before the subcommand name, matching
:: Main.isLegacyInvocation on the Java side.
set "IS_SUBCOMMAND="
for %%a in (%*) do (
    if /i "%%~a"=="app"       set "IS_SUBCOMMAND=1"
    if /i "%%~a"=="worker"    set "IS_SUBCOMMAND=1"
    if /i "%%~a"=="stage"     set "IS_SUBCOMMAND=1"
    if /i "%%~a"=="plugin"    set "IS_SUBCOMMAND=1"
    if /i "%%~a"=="extension" set "IS_SUBCOMMAND=1"
    if /i "%%~a"=="api-key"   set "IS_SUBCOMMAND=1"
    if /i "%%~a"=="user"      set "IS_SUBCOMMAND=1"
    if /i "%%~a"=="project"   set "IS_SUBCOMMAND=1"
    if /i "%%~a"=="help"      set "IS_SUBCOMMAND=1"
)

if defined IS_SUBCOMMAND (
    :: Subcommand style: inject path defaults so CLI invocations talk to the
    :: same DB / data dir / config as the running app. --mode is omitted
    :: because picocli subcommands force mode=CLI internally. User-supplied
    :: flags still override these (picocli takes the last value).
    %java_exe% -cp "dist;%JAR_FILE%" ^
      %DS_JAVA_OPTS% org.icij.datashare.Main ^
      --defaultUserName "%USERNAME%" ^
      --dataDir "%CURRENT_DIR%"\data ^
      --dataSourceUrl jdbc:sqlite:file:"%CURRENT_DIR%"\dist\datashare.db ^
      --settings "%CURRENT_DIR%"\dist\datashare.conf ^
      --pluginsDir "%CURRENT_DIR%"\plugins ^
      --extensionsDir "%CURRENT_DIR%"\extensions ^
      --elasticsearchPath "%CURRENT_DIR%"\elasticsearch ^
      --elasticsearchSettings "%CURRENT_DIR%"\elasticsearch.yml ^
      --elasticsearchDataPath "%CURRENT_DIR%"\index ^
      %*
) else (
    %java_exe% -cp "dist;%JAR_FILE%" ^
      %DS_JAVA_OPTS% org.icij.datashare.Main ^
      app start ^
      --dataDir "%CURRENT_DIR%"\data ^
      --batchQueueType MEMORY ^
      --queueType MEMORY ^
      --busType MEMORY ^
      --dataSourceUrl jdbc:sqlite:file:"%CURRENT_DIR%"\dist\datashare.db ^
      --settings "%CURRENT_DIR%"\dist\datashare.conf ^
      --mode EMBEDDED ^
      --browserOpenLink ^
      --elasticsearchPath "%CURRENT_DIR%"\elasticsearch ^
      --elasticsearchSettings "%CURRENT_DIR%"\elasticsearch.yml ^
      --elasticsearchDataPath "%CURRENT_DIR%"\index ^
      --pluginsDir "%CURRENT_DIR%"\plugins ^
      --extensionsDir "%CURRENT_DIR%"\extensions ^
      --batchDownloadDir "%CURRENT_DIR%"\downloads
    pause
)
