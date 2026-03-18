# NexusVPN Windows Build Script
# Requires: Go 1.22+, .NET SDK 8.0

param(
    [string]$Configuration = "Release",
    [string]$Brand = "Nebula",
    [string]$OutputDir = "..\dist\windows"
)

$ErrorActionPreference = "Stop"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$NuGetConfig = Join-Path $RepoRoot "NuGet.Config"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "NexusVPN Windows Build Script" -ForegroundColor Cyan
Write-Host "Configuration: $Configuration" -ForegroundColor Cyan
Write-Host "Brand: $Brand" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Check prerequisites
Write-Host "`nChecking prerequisites..." -ForegroundColor Yellow

$goVersion = go version 2>$null
if (-not $goVersion) {
    Write-Error "Go is not installed. Download from https://go.dev/dl/"
    exit 1
}
Write-Host "  Go: $goVersion" -ForegroundColor Green

$dotnetVersion = dotnet --version 2>$null
if (-not $dotnetVersion) {
    Write-Error ".NET SDK is not installed. Download from https://dotnet.microsoft.com/download"
    exit 1
}
Write-Host "  .NET: $dotnetVersion" -ForegroundColor Green

# Create output directory
$OutputPath = Resolve-Path (Join-Path $PSScriptRoot $OutputDir) -ErrorAction SilentlyContinue
if (-not $OutputPath) {
    New-Item -ItemType Directory -Path (Join-Path $PSScriptRoot $OutputDir) -Force | Out-Null
    $OutputPath = Resolve-Path (Join-Path $PSScriptRoot $OutputDir)
}

$BuildDir = Join-Path $OutputPath $Brand
New-Item -ItemType Directory -Path $BuildDir -Force | Out-Null

# Build Go Core
Write-Host "`n[1/3] Building Go Core..." -ForegroundColor Yellow
Push-Location (Join-Path $PSScriptRoot "..\core")
try {
    $env:CGO_ENABLED = "0"
    go mod download
    if ($LASTEXITCODE -ne 0) {
        throw "go mod download failed"
    }

    go build -trimpath -ldflags="-s -w" -o "$BuildDir\nexus-core.exe" .\cmd\desktop
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path "$BuildDir\nexus-core.exe")) {
        throw "go build failed for core desktop binary"
    }
    Write-Host "  Core built: $BuildDir\nexus-core.exe" -ForegroundColor Green
} finally {
    Pop-Location
}

# Build Windows UI
Write-Host "`n[2/3] Building Windows UI ($Brand)..." -ForegroundColor Yellow
Push-Location (Join-Path $PSScriptRoot "..\apps\windows\NexusVPN")
try {
    if (Test-Path $NuGetConfig) {
        dotnet restore --configfile $NuGetConfig
    } else {
        dotnet restore
    }
    if ($LASTEXITCODE -ne 0) {
        throw "dotnet restore failed"
    }

    dotnet publish -c $Configuration -p:AppBrand=$Brand --self-contained false -o "$BuildDir\UI"
    if ($LASTEXITCODE -ne 0) {
        throw "dotnet publish failed"
    }
    Write-Host "  UI built: $BuildDir\UI\$Brand.exe" -ForegroundColor Green
} finally {
    Pop-Location
}

# Create install scripts
Write-Host "`n[3/3] Creating installer..." -ForegroundColor Yellow

$InstallBat = @"
@echo off
echo Installing $Brand VPN...
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: Run as Administrator
    pause
    exit /b 1
)
set INSTALL_DIR=%ProgramFiles%\$Brand
mkdir "%INSTALL_DIR%" 2>nul
copy /Y "%~dp0nexus-core.exe" "%INSTALL_DIR%\"
xcopy /E /I /Y "%~dp0UI" "%INSTALL_DIR%\UI\" 2>nul
sc create $Brand binPath= ""%INSTALL_DIR%\nexus-core.exe"" start= auto
echo Installation complete!
pause
"@
$InstallBat | Out-File -FilePath (Join-Path $BuildDir "install.bat") -Encoding ASCII

$UninstallBat = @"
@echo off
echo Uninstalling $Brand VPN...
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: Run as Administrator
    pause
    exit /b 1
)
sc stop $Brand 2>nul
sc delete $Brand 2>nul
rmdir /S /Q "%ProgramFiles%\$Brand" 2>nul
echo Uninstalled!
pause
"@
$UninstallBat | Out-File -FilePath (Join-Path $BuildDir "uninstall.bat") -Encoding ASCII

# Create ZIP
$ZipFile = Join-Path $OutputPath "$Brand-Windows.zip"
Compress-Archive -Path "$BuildDir\*" -DestinationPath $ZipFile -Force

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Build complete!" -ForegroundColor Green
Write-Host "Output: $BuildDir" -ForegroundColor Green
Write-Host "Archive: $ZipFile" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
