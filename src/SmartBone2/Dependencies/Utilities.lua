local DefaultObjectSettings = require(script.Parent:WaitForChild("DefaultObjectSettings"))

local module = {}
module.LogVerbose = false
module.LogIndent = 0

function module.GetRotationBetween(U: Vector3, V: Vector3)
	local Cos = U:Dot(V)
	local Sin = U:Cross(V).Magnitude
	local Angle = math.atan2(Sin, Cos)
	local W = U:Cross(V).Unit
	return CFrame.fromAxisAngle(W, Angle)
end

function module.GetCFrameAxis(Transform: CFrame, Axis: string)
	local X, Y, Z = Transform:ToEulerAnglesXYZ()
	if Axis == "X" then
		return X
	elseif Axis == "Y" then
		return Y
	elseif Axis == "Z" then
		return Z
	end
	return nil
end

function module.GatherObjectSettings(Object)
	local Settings = {}

	for k, v in DefaultObjectSettings do
		Settings[k] = Object:GetAttribute(k) or v
	end

	return Settings
end

function module.GatherBoneSettings(Bone)
	local XAxisLocked = Bone:GetAttribute("XAxisLocked") or false
	local YAxisLocked = Bone:GetAttribute("YAxisLocked") or false
	local ZAxisLocked = Bone:GetAttribute("ZAxisLocked") or false

	local XAxisLimits = Bone:GetAttribute("XAxisLimits") or NumberRange.new(-math.huge, math.huge)
	local YAxisLimits = Bone:GetAttribute("YAxisLimits") or NumberRange.new(-math.huge, math.huge)
	local ZAxisLimits = Bone:GetAttribute("ZAxisLimits") or NumberRange.new(-math.huge, math.huge)

	local Radius = Bone:GetAttribute("Radius") or 0

	local Settings = {
		AxisLocked = { XAxisLocked, YAxisLocked, ZAxisLocked },
		XAxisLimits = XAxisLimits,
		YAxisLimits = YAxisLimits,
		ZAxisLimits = ZAxisLimits,
		Radius = Radius,
	}

	return Settings
end

function module.SB_INDENT_LOG()
	module.LogIndent += 1
end

function module.SB_UNINDENT_LOG()
	module.LogIndent -= 1
	module.LogIndent = math.max(module.LogIndent, 0)
end

function module.SB_ASSERT_CB(condition, callback, ...)
	if condition == false or condition == nil then
		callback(...)
	end
end

function module.SB_VERBOSE_LOG(message: string)
	if not module.LogVerbose then
		return
	end

	local Indent = string.rep("    ", module.LogIndent)

	print(`{Indent}[SmartBone][Log]: {message}`)
end

function module.SB_VERBOSE_WARN(message: string)
	if not module.LogVerbose then
		return
	end

	local Indent = string.rep("    ", module.LogIndent)

	warn(`{Indent}[SmartBone][Warn]: {message}`)
end

function module.SB_VERBOSE_ERROR(message: string)
	if not module.LogVerbose then
		return
	end

	local Indent = string.rep("    ", module.LogIndent)

	error(`{Indent}[SmartBone][Error]: {message}`)
end

return module
