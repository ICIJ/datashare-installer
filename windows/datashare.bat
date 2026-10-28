@echo off

:: Scope all variables to this launcher. Without setlocal, every `set` below
:: (CURRENT_DIR, DS_JAVA_OPTS, OMP_*, ...) would leak into the caller's cmd
:: session when launched from an interactive shell. In particular a leaked
:: OMP_THREAD_LIMIT=1 would silently throttle unrelated OpenMP programs in that
:: window. Child processes spawned during this run still inherit the vars.
setlocal

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

:: Memory settings. Neither JVM gets a heap size from this launcher. To set one,
:: define these variables either by uncommenting the `set` lines below (needs
:: admin rights, lost when Datashare is updated) or in the Windows "Environment
:: Variables" dialog (user variables, kept across Datashare updates):
::   DS_JAVA_OPTS  extra JVM options for Datashare. Without -Xmx, the JVM caps
::                 its heap at 25% of the machine RAM.
::   ES_JAVA_OPTS  JVM options for Elasticsearch. Not used here: Datashare starts
::                 elasticsearch.bat as a child process, which inherits the
::                 environment and reads it. Without it, Elasticsearch sizes
::                 its heap from the machine RAM.
:: If Datashare or Elasticsearch fails to start, we recommend these values, to
:: adjust to the available memory:
:: set "DS_JAVA_OPTS=-Xmx2g"
:: set "ES_JAVA_OPTS=-Xms2g -Xmx2g"
::
:: Set JVM options (include user-defined DS_JAVA_OPTS if they exist)
set DS_JAVA_OPTS=%DS_JAVA_OPTS% --add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.util=ALL-UNNAMED --add-opens java.base/java.net=ALL-UNNAMED -DPROD_MODE=true -Dfile.encoding=UTF-8 -Djava.system.class.loader=org.icij.datashare.DynamicClassLoader

:: OMP_THREAD_LIMIT caps tesseract/Leptonica OpenMP fan-out to one thread per
:: OCR (no CPU oversubscription, no OCR-timeout document loss). These are real
:: environment variables, NOT JVM -D options, so the spawned java -> tesseract
:: process inherits them. Set process-wide on purpose: also reaches the spaCy
:: NLP worker. Override by defining the variable before launch, e.g.
:: set OMP_THREAD_LIMIT=4 (batch cannot express a defined-empty var, so there
:: is no empty-uncap; that is the footgun being removed).
if not defined OMP_THREAD_LIMIT set "OMP_THREAD_LIMIT=1"
if not defined OMP_WAIT_POLICY set "OMP_WAIT_POLICY=passive"

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
    if /i "%%~a"=="entities"  set "IS_SUBCOMMAND=1"
    if /i "%%~a"=="help"      set "IS_SUBCOMMAND=1"
)

if defined IS_SUBCOMMAND (
    :: Subcommand style: inject path defaults so CLI invocations talk to the
    :: same DB / data dir / config as the running app. --mode is omitted
    :: because each subcommand picks its own mode on the Java side.
    :: User-supplied flags still override these (picocli takes the last value).
    %java_exe% -cp "%CURRENT_DIR%\dist;%JAR_FILE%" ^
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
    :: keep .\logs under the installation directory for the desktop app
    cd /d "%CURRENT_DIR%"
    %java_exe% -cp "%CURRENT_DIR%\dist;%JAR_FILE%" ^
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
