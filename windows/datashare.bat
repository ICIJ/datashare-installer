@echo off

docker ps >NULL 2>&1 
if ERRORLEVEL 1 (
  echo docker is not running, launching it
  start "" "\Program Files\Docker\Docker\Docker for Windows.exe"
  call :wait_docker_is_up
)

docker-compose up -d

call :wait_idx_is_up

if not ERRORLEVEL 1 (
  start "" http://localhost:8080
)

exit /B %ERRORLEVEL%


:wait_docker_is_up
echo|set /p="waiting for docker to be up"
for /l %%x in (1, 1, 60) do (
  docker ps >NULL 2>&1
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
