--!nocheck

local HttpService = game:GetService("HttpService")

local Dependencies = script.Parent.Parent.Parent:WaitForChild("Dependencies")
local CollisionSolvers = script.Parent:WaitForChild("Colliders")
local BoxSolver = require(CollisionSolvers:WaitForChild("Box"))
local CapsuleSolver = require(CollisionSolvers:WaitForChild("Capsule"))
local CylinderSolver = require(CollisionSolvers:WaitForChild("Cylinder"))
local SphereSolver = require(CollisionSolvers:WaitForChild("Sphere"))

local Config = require(script.Parent.Parent.Parent:WaitForChild("Dependencies"):WaitForChild("Config"))
local Utilities = require(script.Parent.Parent.Parent:WaitForChild("Dependencies"):WaitForChild("Utilities"))

local SB_VERBOSE_LOG = Utilities.SB_VERBOSE_LOG

local Radians = 0.017453
local Gizmo = require(Dependencies:WaitForChild("Gizmo"))
local IsStudio = game:GetService("RunService"):IsStudio() or Config.ALLOW_LIVE_GAME_DEBUG

if IsStudio or Config.ALLOW_LIVE_GAME_DEBUG then
	Gizmo.Init()
end

--- @class Collider
--- Internal class for colliders
--- :::caution Caution:
--- Changes to the syntax in this class will not count to the major version in semver.
--- :::

--- @within Collider
--- @prop Type string

--- @within Collider
--- @prop Scale Vector3

--- @within Collider
--- @prop Offset Vector3

--- @within Collider
--- @prop Rotation Vector3

--- @within Collider
--- @prop PreviousScale Vector3

--- @within Collider
--- @prop PreviousOffset Vector3

--- @within Collider
--- @prop PreviousRotation Vector3

--- @within Collider
--- @private
--- @readonly
--- @prop m_Object BasePart

--- @within Collider
--- @prop InNarrowphase boolean

--- @within Collider
--- @prop ObjectConnection RBXScriptConnection

--- @within Collider
--- @prop Transform CFrame

--- @within Collider
--- @prop Size Vector3

--- @within Collider
--- @prop GUID string

local Class = {}
Class.__index = Class

--- @within Collider
function Class.new()
	local self = setmetatable({
		Type = "Box",
		Scale = Vector3.zero,
		Offset = Vector3.zero,
		Rotation = Vector3.zero,
		Radius = 0,

		PreviousScale = Vector3.zero,
		PreviousOffset = Vector3.zero,
		PreviousRotation = Vector3.zero,
		PreviousObjectPosition = Vector3.zero,
		PreviousObjectRotation = Vector3.zero,

		m_Object = nil,

		InNarrowphase = false,

		Transform = CFrame.identity,
		Size = Vector3.zero,

		GUID = HttpService:GenerateGUID(false),
	}, Class)

	return self
end

--- @within Collider
--- @param Object BasePart
function Class:SetObject(Object: BasePart)
	self.m_Object = Object

	self:UpdateTransform()
end

--- @within Collider
function Class:UpdateTransform()
do end	
local Object = self.m_Object
	local ObjectCFrame = Object.CFrame
	local ObjectSize = Object.Size

	local Scale = self.Scale
	local Offset = self.Offset
	local Rotation = self.Rotation

	local ScaledOffset = ObjectSize * Offset
	local ScaledSize = ObjectSize * Scale

	local RotationCFrame = CFrame.Angles(Rotation.X * Radians, Rotation.Y * Radians, Rotation.Z * Radians)

	self.Transform = ObjectCFrame * CFrame.new(ScaledOffset) * RotationCFrame
	self.Size = ScaledSize
	self.Radius = math.sqrt((math.max(ScaledSize.X, ScaledSize.Y, ScaledSize.Z) * 0.5) ^ 2 * 2)
do end
end

--- @within Collider
--- @param Point Vector3
--- @param Radius number
--- @return Vector3 | nil -- Returns nil if specified collider shape is invalid
function Class:GetClosestPoint(Point, Radius)
	if self.m_Object == nil then
		return
	end

	self.InNarrowphase = false

	-- Broadphase influence detection
	local PointDistance = (Point - self.Transform.Position).Magnitude - Radius

	if PointDistance > self.Radius then
		return
	end
do end
	

self.InNarrowphase = true

	local Type = self.Type

	-- Determine which collision solver we should send this off to
	local IsInside, ClosestPoint, Normal

	if Type == "Box" then
		IsInside, ClosestPoint, Normal = BoxSolver(self.Transform, self.Size, Point, Radius)
	end

	if Type == "Capsule" then
		IsInside, ClosestPoint, Normal = CapsuleSolver(self.Transform, self.Size, Point, Radius)
	end

	if Type == "Sphere" then
		IsInside, ClosestPoint, Normal = SphereSolver(self.Transform, self.Size, Point, Radius)
	end

	if Type == "Cylinder" then
		IsInside, ClosestPoint, Normal = CylinderSolver(self.Transform, self.Size, Point, Radius)
	end
do end
	

return IsInside, ClosestPoint, Normal
end

--- @within Collider
function Class:Step()
do end	
self:UpdateTransform()
do end
end

--- @within Collider
--- @param ColliderObject ColliderObject
--- @param FILL_COLLIDER boolean
--- @param SHOW_INFLUENCE boolean
--- @param SHOW_AWAKE boolean
--- @param SHOW_BROADPHASE boolean
function Class:DrawDebug(ColliderObject, FILL_COLLIDER, SHOW_INFLUENCE, SHOW_AWAKE, SHOW_BROADPHASE)
	local COLLIDER_COLOR = Color3.new(0.509803, 0.933333, 0.427450)
	local FILL_COLOR = Color3.new(0.901960, 0.784313, 0.513725)
	local SLEEP_COLOR = Color3.new(1, 0, 1)
	local BROADPHASE_COLOR = Color3.new(0, 1, 1)
	local INFLUENCE_COLOR = Color3.new(1, 0.3, 0.3)

	local Type = self.Type
	local Transform = self.Transform
	local Size = self.Size

	if not ColliderObject.m_Awake and SHOW_AWAKE then
		COLLIDER_COLOR = SLEEP_COLOR
	end

	if self.InNarrowphase == false and SHOW_BROADPHASE then
		FILL_COLOR = BROADPHASE_COLOR
	end

	if SHOW_INFLUENCE then
		Gizmo.SetStyle(INFLUENCE_COLOR, 0, false)
		Gizmo.Sphere:Draw(Transform, self.Radius, 25, 360)
	end

	if Type == "Box" then
		Gizmo.SetStyle(COLLIDER_COLOR, 0, false)
		Gizmo.Box:Draw(Transform, Size)

		if FILL_COLLIDER then
			Gizmo.SetStyle(FILL_COLOR, 0.75, false)
			Gizmo.VolumeBox:Draw(Transform, Size)
			Gizmo.PushProperty("Transparency", 0)
		end

		return
	end

	if Type == "Capsule" then
		local CapsuleRadius = (Size.Y < Size.Z and Size.Y or Size.Z) * 0.5
		local CapsuleLength = Size.X

		local TransformedTransform = Transform * CFrame.Angles(math.rad(90), -math.rad(90), 0)

		Gizmo.SetStyle(COLLIDER_COLOR, 0, false)
		Gizmo.Capsule:Draw(TransformedTransform, CapsuleRadius, CapsuleLength, 15)

		if FILL_COLLIDER then
			local Top = TransformedTransform.Position + TransformedTransform.UpVector * (CapsuleLength * 0.5)
			local Bottom = TransformedTransform.Position - TransformedTransform.UpVector * (CapsuleLength * 0.5)

			Gizmo.SetStyle(FILL_COLOR, 0.75, false)
			Gizmo.VolumeCylinder:Draw(Transform, CapsuleRadius, CapsuleLength)
			Gizmo.VolumeSphere:Draw(CFrame.new(Top), CapsuleRadius)
			Gizmo.VolumeSphere:Draw(CFrame.new(Bottom), CapsuleRadius)
			Gizmo.PushProperty("Transparency", 0)
		end

		return
	end

	if Type == "Sphere" then
		local Radius = math.min(Size.X, Size.Y, Size.Z) * 0.5

		Gizmo.SetStyle(COLLIDER_COLOR, 0, false)
		Gizmo.Sphere:Draw(Transform, Radius, 15, 360)

		if FILL_COLLIDER then
			Gizmo.SetStyle(FILL_COLOR, 0.75, false)
			Gizmo.VolumeSphere:Draw(Transform, Radius)
			Gizmo.PushProperty("Transparency", 0)
		end

		return
	end

	if Type == "Cylinder" then
		local Radius = (Size.Y < Size.Z and Size.Y or Size.Z) * 0.5

		Gizmo.SetStyle(COLLIDER_COLOR, 0, false)
		Gizmo.Cylinder:Draw(Transform * CFrame.Angles(0, 0, math.rad(90)), Radius, Size.X, 15)

		if FILL_COLLIDER then
			Gizmo.SetStyle(FILL_COLOR, 0.75, false)
			Gizmo.VolumeCylinder:Draw(Transform * CFrame.Angles(0, -math.rad(90), 0), Radius, Size.X, 0, 360)
			Gizmo.PushProperty("Transparency", 0)
		end

		return
	end
end

--- @within Collider
function Class:Destroy()
	SB_VERBOSE_LOG(`Collider destroying, object: {self.m_Object}`)

	setmetatable(self, nil)
end

return Class
