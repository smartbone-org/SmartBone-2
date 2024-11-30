local HttpService = game:GetService("HttpService")
local Config = require(script.Parent:WaitForChild("Config"))
local DefaultObjectSettings = require(script.Parent:WaitForChild("DefaultObjectSettings"))

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

function module.GatherObjectSettings(Object: BasePart)
	local Settings = {}

	local function Expect(Value: any, Type: string, Name: string): boolean
		if typeof(Value) ~= Type then
			warn(`[SmartBone][Object] Expected attribute {Name} on {Object.Name} to be of type {Type}, got type {typeof(Value)}`)
			return false
		end

		return true
	end

	for k, v in DefaultObjectSettings do
		local Attrib = Object:GetAttribute(k)

		if Attrib ~= nil then
			if not Expect(Attrib, typeof(v), k) then
				Attrib = nil
			end
		end

		Settings[k] = Attrib == nil and v or Attrib
	end

	return Settings
end

function module.GatherBoneSettings(Bone: Bone)
	local function Attrib(Name: string): any?
		return Bone:GetAttribute(Name)
	end

	local function Expect(Value: any, Type: string, Name: string)
		if typeof(Value) ~= Type then
			warn(`[SmartBone][Bone] Expected attribute {Name} on {Bone.Name} to be of type {Type}, got type {typeof(Value)}`)
		end
	end

	local XAxisLocked = Attrib("XAxisLocked") or false
	local YAxisLocked = Attrib("YAxisLocked") or false
	local ZAxisLocked = Attrib("ZAxisLocked") or false

	local XAxisLimits = Attrib("XAxisLimits") or NumberRange.new(-math.huge, math.huge)
	local YAxisLimits = Attrib("YAxisLimits") or NumberRange.new(-math.huge, math.huge)
	local ZAxisLimits = Attrib("ZAxisLimits") or NumberRange.new(-math.huge, math.huge)

	local Radius = Attrib("Radius") or 0.25

	local RotationLimit = Attrib("RotationLimit") or 180

	local Force = Attrib("Force") or "¬"
	local Gravity = Attrib("Gravity") or "¬"

	Expect(XAxisLocked, "boolean", "XAxisLocked")
	Expect(YAxisLocked, "boolean", "YAxisLocked")
	Expect(ZAxisLocked, "boolean", "ZAxisLocked")

	Expect(XAxisLimits, "NumberRange", "XAxisLimits")
	Expect(YAxisLimits, "NumberRange", "YAxisLimits")
	Expect(ZAxisLimits, "NumberRange", "ZAxisLimits")

	Expect(Radius, "number", "Radius")
	Expect(RotationLimit, "number", "RotationLimit")

	if Force ~= "¬" then
		Expect(Force, "Vector3", "Force")
	end

	if Force ~= "¬" then
		Expect(Gravity, "Vector3", "Gravity")
	end

	local Settings = {
		AxisLocked = { XAxisLocked, YAxisLocked, ZAxisLocked },
		XAxisLimits = XAxisLimits,
		YAxisLimits = YAxisLimits,
		ZAxisLimits = ZAxisLimits,
		RotationLimit = RotationLimit,
		Radius = Radius,
		Force = Force,
		Gravity = Gravity,
	}

	return Settings
end

function module.ClosestPointOnLine(p0: Vector3, d0: Vector3, len: number, p1: Vector3): Vector3
	local v = p1 - p0
	local k = v:Dot(d0)
	k = math.clamp(k, -len, len)
	return p0 + d0 * k
end

-- IsInside, ClosestPoint, Normal
function module.ClosestPointInBox(cframe: CFrame, size: Vector3, point: Vector3): (boolean, Vector3, Vector3)
	local rel = cframe:PointToObjectSpace(point)
	local sx, sy, sz = size.X, size.X, size.Z
	local rx, ry, rz = rel.X, rel.Y, rel.Z

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
