local DefaultObjectSettings = require(script.Parent:WaitForChild("DefaultObjectSettings"))

local module = {}

function module.Lerp(A: any, B: any, C: any)
	return A + (B - A) * C
end

function module.GetRotationBetween(U: Vector3, V: Vector3, Axis: Vector3)
	local Dot, UXV = U:Dot(V), U:Cross(V)
	if Dot < -0.999999999 then
		return CFrame.fromAxisAngle(Axis, math.pi)
	end
	return CFrame.new(0, 0, 0, UXV.X, UXV.Y, UXV.Z, 1 + Dot)
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

function module.WaitForChildOfClass(parent: Instance, className: string, timeOut: number)
	local start = os.clock()
	timeOut = timeOut or 10
	repeat
		task.wait()
	until parent:FindFirstChildOfClass(className) or os.clock() - start > timeOut
	return parent:FindFirstChildOfClass(className)
end

return module
