# Build Windows Installer with Inno Setup
# Requires: Inno Setup 6.2+, Go 1.22+, .NET SDK 8.0

param(
    [string]$Brand = "Nebula",
    [string]$Version = "1.0.0"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "NexusVPN Windows Installer Builder" -ForegroundColor Cyan
Write-Host "Brand: $Brand | Version: $Version" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Find Inno Setup
$ISCC = @(
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
    "${env:ProgramFiles}\Inno Setup 6\ISCC.exe",
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $ISCC) {
    Write-Host "ERROR: Inno Setup not found!" -ForegroundColor Red
    Write-Host "Download from: https://jrsoftware.org/isdl.php" -ForegroundColor Yellow
    exit 1
}

Write-Host "Found Inno Setup: $ISCC" -ForegroundColor Green

# Step 1: Build application
Write-Host "`n[1/3] Building application..." -ForegroundColor Yellow
& $PSScriptRoot\build-windows.ps1 -Brand $Brand

# Step 2: Prepare assets
Write-Host "`n[2/3] Preparing assets..." -ForegroundColor Yellow
$AssetsDir = Join-Path $PSScriptRoot "..\assets"
if (-not (Test-Path $AssetsDir)) {
    New-Item -ItemType Directory -Path $AssetsDir -Force | Out-Null
}

# Create simple icon if not exists
$IconPath = Join-Path $AssetsDir "icon.ico"
if (-not (Test-Path $IconPath)) {
    Write-Host "  Creating default icon..." -ForegroundColor Gray
    # Use PowerShell to create a simple icon (or copy from resources)
    # For now, we'll skip icon creation
}

# Step 3: Build installer
Write-Host "`n[3/3] Building installer..." -ForegroundColor Yellow

$IssFile = Join-Path $PSScriptRoot "installer-windows.iss"
if (-not (Test-Path $IssFile)) {
    Write-Error "Installer script not found: $IssFile"
    exit 1
}

# Build with Inno Setup
$brandLower = $Brand.ToLowerInvariant()
$exeName = if ($Brand -eq "PepeWatafa") { "PepeWatafa.exe" } else { "Nebula.exe" }

& $ISCC `
    "/DBrand=$Brand" `
    "/DBrandLower=$brandLower" `
    "/DVersion=$Version" `
    "/DExeName=$exeName" `
    /Q `
    /O"..\dist\windows" `
    /F"$Brand-VPN-$Version-Setup" `
    $IssFile

if ($LASTEXITCODE -ne 0) {
    Write-Error "Inno Setup build failed!"
    exit 1
}

$InstallerPath = Resolve-Path "..\dist\windows\$Brand-VPN-$Version-Setup.exe"

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "SUCCESS! Installer created:" -ForegroundColor Green
Write-Host $InstallerPath -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Green

# Show file info
$fileInfo = Get-Item $InstallerPath
Write-Host "`nFile Size: $([math]::Round($fileInfo.Length / 1MB, 2)) MB" -ForegroundColor Gray
Write-Host "`nTo test installation, run:" -ForegroundColor Yellow
Write-Host "  $InstallerPath" -ForegroundColor White
