$env:Path = "C:\Program Files\Go\bin;" + $env:Path
cd c:\Users\Pipo\.gemini\antigravity\playground\cobalt-hawking\core
go mod tidy
cd ..
git add core/go.sum
git commit -m "Add go.sum for caching"
git push origin main
git tag -f v1.0.2
git push -f origin v1.0.2
