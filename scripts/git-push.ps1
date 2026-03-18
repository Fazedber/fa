cd c:\Users\Pipo\.gemini\antigravity\playground\cobalt-hawking
git init

$name = git config user.name
$email = git config user.email
if (-not $name) { git config --global user.name "Pipo" }
if (-not $email) { git config --global user.email "pipo@example.com" }

git add .
git commit -m "Initial commit for Release"
git branch -M main

# If remote exists, update it, otherwise add it
$remote = git remote get-url origin 2>$null
if ($remote) {
    git remote set-url origin https://github.com/pipopaaa/na.git
} else {
    git remote add origin https://github.com/pipopaaa/na.git
}

Write-Host "Pushing main branch. A browser window might pop up asking you to log into GitHub! Please log in."
git push -u origin main

Write-Host "Tagging release v1.0.0 and pushing tag..."
git tag v1.0.0
git push origin v1.0.0
Write-Host "Done!"
