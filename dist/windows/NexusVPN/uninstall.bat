@echo off
echo Uninstalling NexusVPN VPN...
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: Run as Administrator
    pause
    exit /b 1
)
sc stop NexusVPN 2>nul
sc delete NexusVPN 2>nul
rmdir /S /Q "%ProgramFiles%\NexusVPN" 2>nul
echo Uninstalled!
pause
