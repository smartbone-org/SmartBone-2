local fs = require("@lune/fs")
local process = require("@lune/process")
local task = require("@lune/task")

print("Installing packages")

process.spawn("rokit", { "install" }, { stdio = "forward" })

print("Clearing old build")

if fs.isDir("./src-build") then
	fs.removeDir("./src-build")
end

print("Building darklua config")

process.spawn("lune", { "run", "scripts/darkluaconfig" }, { stdio = "forward" })

print("Starting darklua watch")

task.spawn(process.spawn, "./dev.bat", {}, { stdio = "forward" })

print("Starting server")

repeat
	task.wait()
until fs.isDir("./src-build")

task.wait()

print("Starting rojo")

process.spawn("rojo", {
	"serve",
	"dev.project.json",
}, { stdio = "forward" })
