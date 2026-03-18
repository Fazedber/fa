cd c:\Users\Pipo\.gemini\antigravity\playground\cobalt-hawking

# Update the remote URL
git remote set-url origin https://github.com/Fazedber/fa.git

Write-Host "Pushing main branch. A browser window might pop up asking you to log into GitHub! Please log in with the NEW account."
git push -u origin main

Write-Host "Tagging release v1.0.0 and pushing tag..."
git tag -f v1.0.0
git push origin v1.0.0
Write-Host "Done! The GitHub Actions server has now started compiling all three files (Mac, Windows, Android)."
