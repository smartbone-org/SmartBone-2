--[[

Builds .darklua.json run via lune. If you wish to build this into a different json location specify that as a command line arg

e.g. lune run scripts/darkluaconfig
e.g. lune run scripts/darkluaconfig otherconfig.json

]]

local DEBUG_PROFILING = false
local HAS_COMMENT_FILE = false

-- Globals injected into _G
local MACROS = {}

local RULES = {
	"compute_expression",
	"remove_unused_if_branch",
	"remove_unused_while",
	"remove_empty_do",
	"remove_nil_declaration",
	"filter_after_early_return",
	-- "remove_comments" is deliberately absent, it strips --!native and --!nocheck along with
	-- everything else, which would silently disable native codegen on the hot components.
}

if not DEBUG_PROFILING then
	table.insert(RULES, "remove_debug_profiling")
end

-- !! DO NOT EDIT BELOW THIS LINE !!

local REQUIRE_RULE =
	'{"rule": "convert_require", "current": {"name": "path", "sources": {}}, "target": {"name": "roblox", "rojo_sourcemap": "sourcemap.json", "indexing_style": "wait_for_child"}}'
local MACRO_RULE = '{"rule": "inject_global_value", "identifier": "%s","value": %s}'
local COMMENT_RULE = HAS_COMMENT_FILE and '{"rule": "append_text_comment", "location": "start", "file": "COMMENT"}' or ""

local fs = require("@lune/fs")
local process = require("@lune/process")

-- Put git hash in macros so we can see it in-code
local GitHash = process.exec("git", { "log", "-1", "--format=%H" })
MACROS["GIT_HASH"] = GitHash.stdout:sub(1, 8)

local function Build()
	local tout = {}
	-- Generate Macros
	for MacroName, MacroValue in MACROS do
		if type(MacroValue) == "string" then
			MacroValue = `"{MacroValue}"`
		else
			MacroValue = tostring(MacroValue)
		end

		table.insert(tout, MACRO_RULE:format(MacroName, MacroValue))
	end

	-- Add in general rules
	for _, Rule in RULES do
		table.insert(tout, `"{Rule}"`)
	end

	-- Extra rules
	table.insert(tout, REQUIRE_RULE)
	if #COMMENT_RULE > 0 then
		table.insert(tout, COMMENT_RULE)
	end

	return `\{"rules": [{table.concat(tout, ", ")}]\}`
end

local Result = Build()
local WriteTo = process.args[1] or ".darklua.json"
fs.writeFile(WriteTo, Result)

print(`Successfully build darklua config at "{WriteTo}"`)
