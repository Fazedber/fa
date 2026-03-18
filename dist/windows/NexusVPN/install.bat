@echo off
echo Installing NexusVPN VPN...
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: Run as Administrator
    pause
    exit /b 1
)
set INSTALL_DIR=%ProgramFiles%\NexusVPN
mkdir "%INSTALL_DIR%" 2>nul
copy /Y "%~dp0nexus-core.exe" "%INSTALL_DIR%\"
xcopy /E /I /Y "%~dp0UI" "%INSTALL_DIR%\UI\" 2>nul
sc create NexusVPN binPath= ""%INSTALL_DIR%\nexus-core.exe"" start= auto
echo Installation complete!
pause
