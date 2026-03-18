$ErrorActionPreference = "Continue"
$ProgressPreference = 'SilentlyContinue'

Write-Host "============================"
Write-Host "Installing Build Tools FAST..."
Write-Host "============================"

# Download and Install Go
Write-Host "1. Downloading Go 1.22.1..."
try {
    Invoke-WebRequest -Uri "https://go.dev/dl/go1.22.1.windows-amd64.msi" -OutFile "$env:TEMP\go.msi" -UseBasicParsing
    Write-Host "Installing Go (this may take a minute)..."
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$env:TEMP\go.msi`" /quiet /qn /norestart" -Wait
    Write-Host "Go successfully installed!"
} catch {
    Write-Host "Failed to install Go: $_"
}

# Download and Install .NET 8 SDK
Write-Host "2. Downloading .NET 8 SDK..."
try {
    Invoke-WebRequest -Uri "https://dot.net/v1/dotnet-install.ps1" -OutFile "$env:TEMP\dotnet-install.ps1" -UseBasicParsing
    Write-Host "Installing .NET 8 SDK..."
    & "$env:TEMP\dotnet-install.ps1" -Channel 8.0 -NoPath
    Write-Host ".NET SDK successfully installed!"
} catch {
    Write-Host "Failed to install .NET SDK: $_"
}

# Update Path for current session
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
$env:Path += ";$env:USERPROFILE\AppData\Local\Microsoft\dotnet"

# Verify installations
Write-Host "============================"
Write-Host "Verifying toolchains..."
go version
dotnet --version
Write-Host "============================"

# Proceed to build
Write-Host "Building Windows Application..."
cd $PSScriptRoot
.\build-windows.ps1 -Brand "NexusVPN"
