@echo off
cd /d "%~dp0"
if exist "%~dp0assets\boot.img" (
  set "FLIPPER_LAUNCHER=Start-Flipper.ps1"
) else (
  set "FLIPPER_LAUNCHER=Prepare-Package.ps1"
)
if "%~1"=="" (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0%FLIPPER_LAUNCHER%"
) else (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0%FLIPPER_LAUNCHER%" -ImageArchive "%~1"
)
pause
