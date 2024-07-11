# SmartBone2 Development

## Installing

If you don't have aftman or npm / nodejs go to these links:
https://github.com/LPGhatguy/aftman/releases/latest
https://nodejs.org/en/download/prebuilt-installer

Install aftman packages:
`aftman install`

Install nodemon:
`npm install nodemon`

## Building

Build the darklua config via this:
`lune run build-darkluaconfig`

You can edit the darklua rules via the `build-darkluaconfig.luau` file.

Run `dev.bat` and close the terminal when your finished developing.

You should serve dev.project.json not default.project.json

If you need debug profiling then change the `DEBUG_PROFILING` variable
