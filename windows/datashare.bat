@echo off

set CURRENT_RUNNING_BATCH_PATH=%~dp0
PowerShell.exe -Command "& '%CURRENT_RUNNING_BATCH_PATH%\datashare.ps1'"
PAUSE
