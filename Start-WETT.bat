@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0WETT.ps1"
if errorlevel 1 (
    echo.
    echo WETT exited with an error. Review the Logs folder.
    pause
)
endlocal
