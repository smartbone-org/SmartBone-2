--[[

Builds .darklua.json run via lune. If you wish to build this into a different json location specify that as a command line arg

e.g. lune run build-darkluaconfig
e.g. lune run build-darkluaconfig otherconfig.json

]]

-- Globals injected into _G
local DEBUG_PROFILING = false
local MACROS = {}

local RULES = {
	"compute_expression",
	"remove_unused_if_branch",
	"remove_unused_while",
	"remove_nil_declaration",
	"filter_after_early_return",
}

if not DEBUG_PROFILING then
	table.insert(RULES, "remove_debug_profiling")
end

table.insert(RULES, "remove_empty_do")

local REQUIRE_ALIASES = {}

-- !! DO NOT EDIT BELOW THIS LINE !!

local REQUIRE_RULE =
	'{"rule": "convert_require", "current": {"name": "path", "sources": {%s}}, "target": {"name": "roblox", "rojo_sourcemap": "sourcemap.json", "indexing_style": "wait_for_child"}}'
local MACRO_RULE = '{"rule": "inject_global_value", "identifier": "%s","value": %s}'
local COMMENT_RULE = ""

local fs = require("@lune/fs")
local process = require("@lune/process")

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

	-- Add in require rule
	local aliases = {}
	for alias, location in REQUIRE_ALIASES do
		table.insert(aliases, `"{alias}": "{location}"`)
	end

	-- Extra rules
	table.insert(tout, REQUIRE_RULE:format(table.concat(aliases, ", ")))
	table.insert(tout, COMMENT_RULE)

	return `\{"rules": [{table.concat(tout, ", ")}]\}`
end

local Result = Build()
local WriteTo = process.args[1] or ".darklua.json"
fs.writeFile(WriteTo, Result)

print(`Successfully build darklua config at "{WriteTo}"`)
