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

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$WindowsDistDir = Join-Path $RepoRoot "dist\windows"
New-Item -ItemType Directory -Path $WindowsDistDir -Force | Out-Null

function Get-SignToolPath {
    $candidates = @(
        Get-ChildItem -Path "${env:ProgramFiles(x86)}\Windows Kits\10\bin" -Recurse -Filter signtool.exe -ErrorAction SilentlyContinue,
        Get-ChildItem -Path "${env:ProgramFiles}\Windows Kits\10\bin" -Recurse -Filter signtool.exe -ErrorAction SilentlyContinue
    ) | Where-Object { $_ } | Sort-Object FullName -Descending

    return $candidates | Select-Object -First 1 -ExpandProperty FullName
}

$CanCodeSign = -not [string]::IsNullOrWhiteSpace($env:WINDOWS_SIGN_CERT_PATH) -and `
    -not [string]::IsNullOrWhiteSpace($env:WINDOWS_SIGN_CERT_PASSWORD)
$SignTool = $null

function Sign-Binary {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not $CanCodeSign) {
        return
    }

    if (-not (Test-Path $Path)) {
        throw "Cannot sign missing file: $Path"
    }

    & $SignTool sign `
        /fd SHA256 `
        /td SHA256 `
        /tr http://timestamp.digicert.com `
        /f $env:WINDOWS_SIGN_CERT_PATH `
        /p $env:WINDOWS_SIGN_CERT_PASSWORD `
        $Path

    if ($LASTEXITCODE -ne 0) {
        throw "Authenticode signing failed for $Path"
    }
}

if ($CanCodeSign) {
    $SignTool = Get-SignToolPath
    if (-not $SignTool) {
        throw "Windows code-signing certificate is configured, but signtool.exe was not found."
    }

    Write-Host "Found SignTool: $SignTool" -ForegroundColor Green
}

# Step 1: Build application
Write-Host "`n[1/3] Building application..." -ForegroundColor Yellow
& $PSScriptRoot\build-windows.ps1 -Brand $Brand -Version $Version

# Verify build outputs
Write-Host "`nVerifying build outputs..." -ForegroundColor Yellow
$RequiredFiles = @(
    (Join-Path $WindowsDistDir "$Brand\nexus-core.exe"),
    (Join-Path $WindowsDistDir "$Brand\UI\$Brand.exe"),
    (Join-Path $WindowsDistDir "$Brand\UI\app.ico")
)
foreach ($file in $RequiredFiles) {
    if (-not (Test-Path $file)) {
        Write-Error "Required file not found: $file"
        exit 1
    }
    Write-Host "  Found: $file" -ForegroundColor Green
}

if ($CanCodeSign) {
    Write-Host "  Signing Windows application binaries..." -ForegroundColor Gray
    Get-ChildItem -Path (Join-Path $WindowsDistDir $Brand) -Recurse -Filter *.exe -File |
        ForEach-Object { Sign-Binary -Path $_.FullName }
}

# Step 2: Prepare assets
Write-Host "`n[2/3] Preparing assets..." -ForegroundColor Yellow
$AssetsDir = Join-Path $PSScriptRoot "..\assets"
if (-not (Test-Path $AssetsDir)) {
    New-Item -ItemType Directory -Path $AssetsDir -Force | Out-Null
}

$IconPath = Join-Path $AssetsDir ($Brand.ToLowerInvariant() + ".ico")
if (-not (Test-Path $IconPath)) {
    throw "Brand icon asset was not found: $IconPath"
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
$UiOutputDir = Join-Path $WindowsDistDir "$Brand\UI"
$UiExe = Get-ChildItem -Path $UiOutputDir -Filter *.exe -File |
    Where-Object { $_.Name -notlike "*Service*" -and $_.Name -ne "nexus-core.exe" } |
    Select-Object -First 1

if (-not $UiExe) {
    Write-Error "Published Windows UI executable was not found in $UiOutputDir"
    exit 1
}

$exeName = $UiExe.Name
$appId = switch ($Brand.ToLowerInvariant()) {
    "pepewatafa" { "{{C0192F5D-6D31-4D77-B1E1-55E8C89806EA}" }
    default { "{{B4A4C4E4-5F4A-4C4E-8B4A-4C4E4F4A4C4E}" }
}

& $ISCC `
    "/DBrand=$Brand" `
    "/DBrandLower=$brandLower" `
    "/DVersion=$Version" `
    "/DExeName=$exeName" `
    "/DAppId=$appId" `
    /Q `
    "/O$WindowsDistDir" `
    /F"$Brand-VPN-$Version-Setup" `
    $IssFile

if ($LASTEXITCODE -ne 0) {
    Write-Error "Inno Setup build failed!"
    exit 1
}

$InstallerPath = Resolve-Path (Join-Path $WindowsDistDir "$Brand-VPN-$Version-Setup.exe")

if ($CanCodeSign) {
    Write-Host "  Signing installer..." -ForegroundColor Gray
    Sign-Binary -Path $InstallerPath.Path
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "SUCCESS! Installer created:" -ForegroundColor Green
Write-Host $InstallerPath -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Green

# Show file info
$fileInfo = Get-Item $InstallerPath
Write-Host "`nFile Size: $([math]::Round($fileInfo.Length / 1MB, 2)) MB" -ForegroundColor Gray
Write-Host "`nTo test installation, run:" -ForegroundColor Yellow
Write-Host "  $InstallerPath" -ForegroundColor White
