cd c:\Users\Pipo\.gemini\antigravity\playground\cobalt-hawking
git restore .github/workflows/

$step = @"
    - name: Resolve Go Modules
      run: |
        cd core
        go get ./...
        go mod tidy
"@
$stepWin = @"
    - name: Resolve Go Modules
      shell: pwsh
      run: |
        cd core
        go get ./...
        go mod tidy
"@

$f1 = ".github/workflows/build-installers.yml"
$c1 = Get-Content $f1 -Raw
$c1 = $c1 -replace '(?m)^(\s+)- name: Set up \.NET', ("$stepWin`n`n`$1- name: Set up .NET")
$c1 = $c1 -replace '(?m)^(\s+)- name: Install dependencies', ("$step`n`n`$1- name: Install dependencies")
$c1 = $c1 -replace '(?m)^(\s+)- name: Set up JDK', ("$step`n`n`$1- name: Set up JDK")
Set-Content $f1 $c1

$f2 = ".github/workflows/build-core.yml"
$c2 = Get-Content $f2 -Raw
$c2 = $c2 -replace '(?m)^(\s+)- name: Verify modules', ("$step`n`n`$1- name: Verify modules")
$c2 = $c2 -replace '(?m)^(\s+)- name: Build Core Daemon', ("$step`n`n`$1- name: Build Core Daemon")
$c2 = $c2 -replace '(?m)^(\s+)- name: Install NDK and Gomobile', ("$step`n`n`$1- name: Install NDK and Gomobile")
$c2 = $c2 -replace '(?m)^(\s+)- name: Bind macOS Framework', ("$step`n`n`$1- name: Bind macOS Framework")
Set-Content $f2 $c2

git add .
git commit -m "Auto-resolve Go modules in cloud - clean regex"
git tag -f v1.0.4
git push origin main
git push -f origin v1.0.4
