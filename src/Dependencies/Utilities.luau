local HttpService = game:GetService("HttpService")
local DefaultObjectSettings = require(script.Parent:WaitForChild("DefaultObjectSettings"))
local Config = require(script.Parent:WaitForChild("Config"))

local ColliderTranslations = {
	Block = "Box",
	Ball = "Sphere",
	Capsule = "Capsule",
	Sphere = "Sphere",
	Box = "Box",
	Cylinder = "Cylinder",
}

local function SafeUnit(Vector: Vector3): Vector3
	if Vector.Magnitude == 0 then
		return -Vector3.yAxis
	end

	return Vector.Unit
end

local module = {}
module.LogIndent = 0

function module.GetRotationBetween(U: Vector3, V: Vector3)
	local Cos = U:Dot(V)
	local Sin = U:Cross(V).Magnitude
	local Angle = math.atan2(Sin, Cos)
	local W = SafeUnit(U:Cross(V))

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
		local Attrib = Object:GetAttribute(k)
		Settings[k] = Attrib == nil and v or Attrib
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

	local Radius = Bone:GetAttribute("Radius") or 0.25

	local RotationLimit = Bone:GetAttribute("RotationLimit") or 180

	local Settings = {
		AxisLocked = { XAxisLocked, YAxisLocked, ZAxisLocked },
		XAxisLimits = XAxisLimits,
		YAxisLimits = YAxisLimits,
		ZAxisLimits = ZAxisLimits,
		RotationLimit = RotationLimit,
		Radius = Radius,
	}

	return Settings
end

function module.ClosestPointOnLine(p0, d0, len, p1): Vector3
	local v = p1 - p0
	local k = v:Dot(d0)
	k = math.clamp(k, -len, len)
	return p0 + d0 * k
end

-- IsInside, ClosestPoint, Normal
function module.ClosestPointInBox(cframe, size, point): (boolean, Vector3, Vector3)
	local rel = cframe:pointToObjectSpace(point)
	local sx, sy, sz = size.x, size.y, size.z
	local rx, ry, rz = rel.x, rel.y, rel.z

	if rel ~= rel or size ~= size then -- NaN
		return false, cframe.Position, Vector3.yAxis
	end

	-- constrain to within the box
	local cx = math.clamp(rx, -sx * 0.5, sx * 0.5)
	local cy = math.clamp(ry, -sy * 0.5, sy * 0.5)
	local cz = math.clamp(rz, -sz * 0.5, sz * 0.5)

	if not (cx == rx and cy == ry and cz == rz) then
		local closestPoint = cframe * Vector3.new(cx, cy, cz)
		local normal = (point - closestPoint).unit
		return false, closestPoint, normal
	end

	-- else, they are intersecting, find the surface the point is closest to

	local posX = rx - sx * 0.5
	local posY = ry - sy * 0.5
	local posZ = rz - sz * 0.5
	local negX = -rx - sx * 0.5
	local negY = -ry - sy * 0.5
	local negZ = -rz - sz * 0.5

	local max = math.max(posX, posY, posZ, negX, negY, negZ)
	if max == posX then
		local closestPoint = cframe * Vector3.new(sx * 0.5, ry, rz)
		return true, closestPoint, cframe.XVector
	elseif max == posY then
		local closestPoint = cframe * Vector3.new(rx, sy * 0.5, rz)
		return true, closestPoint, cframe.YVector
	elseif max == posZ then
		local closestPoint = cframe * Vector3.new(rx, ry, sz * 0.5)
		return true, closestPoint, cframe.ZVector
	elseif max == negX then
		local closestPoint = cframe * Vector3.new(-sx * 0.5, ry, rz)
		return true, closestPoint, -cframe.XVector
	elseif max == negY then
		local closestPoint = cframe * Vector3.new(rx, -sy * 0.5, rz)
		return true, closestPoint, -cframe.YVector
	elseif max == negZ then
		local closestPoint = cframe * Vector3.new(rx, ry, -sz * 0.5)
		return true, closestPoint, -cframe.ZVector
	end

	-- Shouldnt reach
	warn("CLOSEST POINT ON BOX FAIL")
	return false, Vector3.zero, Vector3.yAxis
end

function module.GetCollider(Object: BasePart)
	-- Any shapes which arent defined in the translation table are defaulted to box

	local ColliderModule = Object:FindFirstChild("self.Collider")
	local ColliderDescription

	if ColliderModule and ColliderModule:IsA("ModuleScript") then
		local RawColliderData = require(ColliderModule)
		local ColliderData
		pcall(function()
			ColliderData = HttpService:JSONDecode(RawColliderData)
		end)

		ColliderDescription = ColliderData
	end

	if ColliderDescription then
		return ColliderDescription
	end

	-- Only runs if there was no collider module or the collider data wasn't valid json

	local function GetShapeName(obj)
		local ShapeAttribute = obj:GetAttribute("ColliderShape")

		if ShapeAttribute then
			return ShapeAttribute
		end

		if obj:IsA("Part") then -- Allow meshes and unions to have colliders
			return obj.Shape.Name
		end

		return "Box"
	end

	local ColliderType = ColliderTranslations[GetShapeName(Object)] or "Box"

	ColliderDescription = {
		{
			Type = ColliderType,
			ScaleX = 1,
			ScaleY = 1,
			ScaleZ = 1,
			OffsetX = 0,
			OffsetY = 0,
			OffsetZ = 0,
			RotationX = 0,
			RotationY = 0,
			RotationZ = 0,
		},
	}

	return ColliderDescription
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
	if not Config.LOG_VERBOSE then
		return
	end

	local Indent = string.rep("    ", module.LogIndent)

	print(`{Indent}[SmartBone][Log]: {message}`)
end

function module.SB_VERBOSE_WARN(message: string)
	if not Config.LOG_VERBOSE then
		return
	end

	local Indent = string.rep("    ", module.LogIndent)

	warn(`{Indent}[SmartBone][Warn]: {message}`)
end

function module.SB_VERBOSE_ERROR(message: string)
	if not Config.LOG_VERBOSE then
		return
	end

	local Indent = string.rep("    ", module.LogIndent)

	error(`{Indent}[SmartBone][Error]: {message}`)
end

return module
