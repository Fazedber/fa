$env:Path = "C:\Program Files\Go\bin;C:\Users\Pipo\AppData\Local\Microsoft\dotnet;" + $env:Path
Write-Host "Paths updated. Testing..."
go version
dotnet --version

Write-Host "Proceeding to build..."
cd c:\Users\Pipo\.gemini\antigravity\playground\cobalt-hawking\scripts
.\build-windows.ps1 -Brand "NexusVPN"
