@echo off
docker-compose up -d

call :wait_idx_is_up

if not ERRORLEVEL 1 (
  start "" http://localhost:8080
)

exit /B %ERRORLEVEL%

:wait_idx_is_up
echo|set /p="waiting for datashare to be up"
for /l %%x in (1, 1, 30) do (
    ping -n 1 127.0.0.1 >nul
    curl --silent localhost:8080 >nul
    if not ERRORLEVEL 1 (
        echo OK
        exit /B 0
    )
    echo|set /p="."
)
echo KO
exit /B %ERRORLEVEL%