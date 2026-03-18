$env:Path = "C:\Program Files\Go\bin;" + $env:Path
cd c:\Users\Pipo\.gemini\antigravity\playground\cobalt-hawking\core
Write-Host "Running go mod tidy..."
go mod tidy 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) {
    Write-Host "GO MOD TIDY FAILED!"
    exit 1
}
Write-Host "Go mod tidy succeeded! Checking if go.sum exists:"
Test-Path go.sum
