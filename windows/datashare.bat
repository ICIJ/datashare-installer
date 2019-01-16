@echo off

docker info 2>NUL

if ERRORLEVEL 1 (
  echo docker is not running, launching it
  start "" "\Program Files\Docker\Docker\Docker for Windows.exe"
  call :wait_docker_is_up
)

set datashare_id=
for /f "delims=" %%a in ('docker-compose -p datashare ps -q datashare') do @set datashare_id=%%a
set datashare_status=
for /f "delims=" %%a in ('docker inspect %datashare_id% -f "{{.State.Status}}"') do @set datashare_status=%%a

if "%datashare_status%"=="running" (
  docker-compose -p datashare restart datashare
) else (
  docker-compose -p datashare up -d
)

call :wait_idx_is_up

if not ERRORLEVEL 1 (
  start "" http://localhost:8080
)

exit /B %ERRORLEVEL%

:wait_docker_is_up
echo|set /p="waiting for docker to be up"
for /l %%x in (1, 1, 60) do (
  docker info 2>NUL
  if not ERRORLEVEL 1 (
      echo OK
      exit /B 0
  )
  echo|set /p="."
  timeout /t 1 /nobreak > NUL
)

:wait_idx_is_up
echo|set /p="waiting for datashare to be up"
for /l %%x in (1, 1, 60) do (
    timeout /t 1 /nobreak >NUL
    curl --silent localhost:8080 >NUL
    if not ERRORLEVEL 1 (
        echo OK
        exit /B 0
    )
    echo|set /p="."
)
echo KO
exit /B %ERRORLEVEL%
