local fs = require("@lune/fs")
local process = require("@lune/process")
local task = require("@lune/task")

print("Installing packages")

process.exec("rokit", { "install" }, { stdio = "forward" })

-- src-build is the published wally artifact, clearing it here is what drops files whose source
-- was renamed or moved. The watcher below rebuilds it immediately.
print("Clearing old build")

if fs.isDir("./src-build") then
	fs.removeDir("./src-build")
end

print("Building darklua config")

process.exec("lune", { "run", "scripts/darkluaconfig" }, { stdio = "forward" })

print("Starting darklua watch")

if process.os == "macos" then
	task.spawn(process.exec, "./dev.bash", {}, { stdio = "forward" })
else
	task.spawn(process.exec, "./dev.bat", {}, { stdio = "forward" })
end

print("Starting server")

repeat
	task.wait()
until fs.isFile("./src-build/init.luau")

task.wait()

print("Starting rojo")

process.exec("rojo", {
	"serve",
	"dev.project.json",
}, { stdio = "forward" })
