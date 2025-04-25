--[[

    Acts as a wrapper for Gizmo.lua, respects IsStudio and AllowLiveGameDebug

]]

local Dependencies = script.Parent.Parent

local Config = require(Dependencies:WaitForChild("Config"))
local Gizmo = require(script:WaitForChild("Gizmo"))

local IsStudio = game:GetService("RunService"):IsStudio()
local IsEnabled = IsStudio or Config.ALLOW_LIVE_GAME_DEBUG
if IsEnabled then
	Gizmo.Init()
end

type ICeive = Gizmo.ICeive & { Init: nil }

local Wrapper: ICeive = setmetatable({}, {
	__index = function(_, Index)
		if IsEnabled then
			return Gizmo[Index]
		else
			local GizmoFunctions = {
				SetStyle = true,
				AddDebrisInSeconds = true,
				PushProperty = true,
				PopProperty = true,
				AddDebrisInFrames = true,
				SetEnabled = true,
				DoCleaning = true,
				ScheduleCleaning = true,
				TweenProperties = true,
			}

			if GizmoFunctions[Index] then
				return function() end
			end

			return {
				Draw = function() end,
				Create = function() end,
			}
		end
	end,
}) :: any

return table.freeze(Wrapper)
