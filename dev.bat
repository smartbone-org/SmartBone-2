@echo off

start /b npx nodemon --watch src -d 1 -e lua,luau --exec "rojo sourcemap src.project.json --output sourcemap.json"
start /b npx nodemon --watch src -e lua,luau --exec "darklua process src/ src-build/"
