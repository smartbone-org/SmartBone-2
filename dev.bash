#!/bin/bash

npx nodemon --watch src -d 2 -e lua,luau --exec "rojo sourcemap src.project.json --output sourcemap.json" &
npx nodemon --watch src -e lua,luau --exec "darklua process src/ src-build/" &
npx nodemon --watch src -e lua,luau --exec "lune run scripts/darkluaconfig" &
