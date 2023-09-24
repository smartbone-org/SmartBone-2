local HttpService = game:GetService("HttpService")

local Dependencies = script.Parent.Parent.Parent:WaitForChild("Dependencies")
local CollisionSolvers = script.Parent:WaitForChild("Colliders")
local BoxSolver = require(CollisionSolvers:WaitForChild("Box"))
local CapsuleSolver = require(CollisionSolvers:WaitForChild("Capsule"))
local SphereSolver = require(CollisionSolvers:WaitForChild("Sphere"))

local Gizmo = require(Dependencies:WaitForChild("Gizmo"))
Gizmo.Init()

--- @class Collider
--- Internal class for colliders
--- :::caution Caution: Warning
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

		PreviousScale = Vector3.zero,
		PreviousOffset = Vector3.zero,
		PreviousRotation = Vector3.zero,

		m_Object = nil,
		ObjectConnection = nil,

		Transform = CFrame.identity,
		Size = Vector3.zero,

		GUID = HttpService:GenerateGUID(),
	}, Class)

	return self
end

--- @within Collider
--- @param Object BasePart
function Class:SetObject(Object: BasePart)
	if self.ObjectConnection then
		self.ObjectConnection:Disconnect()
	end

	self.m_Object = Object

	self:UpdateTransform()

	self.ObjectConnection = Object.Changed:Connect(function(Prop)
		if Prop == "CFrame" or Prop == "Size" then
			self:UpdateTransform()
		end
	end)
end

--- @within Collider
function Class:UpdateTransform()
	if self.m_Object == nil then
		return
	end

	local Object = self.m_Object
	local ObjectCFrame = Object.CFrame
	local ObjectPosition = ObjectCFrame.Position
	local ObjectSize = Object.Size

	local Scale = self.Scale
	local Offset = self.Offset
	local Rotation = self.Rotation

	local ScaledOffset = ObjectSize * Offset
	local ScaledSize = ObjectSize * Scale

	local RotationCFrame = CFrame.Angles(math.rad(Rotation.X), math.rad(Rotation.Y), math.rad(Rotation.Z))
	local TransformCFrame = CFrame.new(ObjectPosition + ScaledOffset) * ObjectCFrame.Rotation * RotationCFrame

	self.Transform = TransformCFrame
	self.Size = ScaledSize
end

--- @within Collider
--- @param Point Vector3
--- @param Radius number
function Class:GetClosestPoint(Point, Radius)
	if self.Scale ~= self.PreviousScale then
		self:UpdateTransform()
		self.PreviousScale = self.Scale
	end

	if self.Offset ~= self.PreviousOffset then
		self:UpdateTransform()
		self.PreviousOffset = self.Offset
	end

	if self.Rotation ~= self.PreviousRotation then
		self:UpdateTransform()
		self.PreviousRotation = self.Rotation
	end

	local Type = self.Type

	-- Determine which collision solver we should send this off to
	if Type == "Box" then
		return BoxSolver(self.Transform, self.Size, Point, Radius)
	end

	if Type == "Capsule" then
		return CapsuleSolver(self.Transform, self.Size, Point, Radius)
	end

	if Type == "Sphere" then
		return SphereSolver(self.Transform, self.Size, Point, Radius)
	end

	warn(`Invalid collider shape: {Type}`)
end

--- @within Collider
--- @param FILL_COLLIDER boolean
function Class:DrawDebug(FILL_COLLIDER)
	local COLLIDER_COLOR = Color3.new(0.509803, 0.933333, 0.427450)
	local FILL_COLOR = Color3.new(0.901960, 0.784313, 0.513725)

	local Type = self.Type
	local Transform = self.Transform
	local Size = self.Size

	Gizmo.PushProperty("AlwaysOnTop", false)

	if Type == "Box" then
		Gizmo.PushProperty("Color3", COLLIDER_COLOR)
		Gizmo.Box:Draw(Transform, Size)

		if FILL_COLLIDER then
			Gizmo.SetStyle(FILL_COLOR, 0.75, false)
			Gizmo.VolumeBox:Draw(Transform, Size)
			Gizmo.PushProperty("Transparency", 0)
		end

		return
	end

	if Type == "Capsule" then
		local CapsuleRadius = math.min(Size.Y, Size.Z) / 2
		local CapsuleLength = Size.X

		Gizmo.PushProperty("Color3", COLLIDER_COLOR)
		Gizmo.Capsule:Draw(Transform, CapsuleRadius, CapsuleLength, 15)

		if FILL_COLLIDER then
			local TransformedTransform = Transform * CFrame.Angles(math.rad(90), -math.rad(90), 0)

			local Top = TransformedTransform.Position + TransformedTransform.UpVector * (CapsuleLength / 2)
			local Bottom = TransformedTransform.Position - TransformedTransform.UpVector * (CapsuleLength / 2)

			Gizmo.SetStyle(FILL_COLOR, 0.75, false)
			Gizmo.VolumeCylinder:Draw(Transform, CapsuleRadius, CapsuleLength)
			Gizmo.VolumeSphere:Draw(CFrame.new(Top), CapsuleRadius)
			Gizmo.VolumeSphere:Draw(CFrame.new(Bottom), CapsuleRadius)
			Gizmo.PushProperty("Transparency", 0)
		end

		return
	end

	if Type == "Sphere" then
		local Radius = math.min(Size.X, Size.Y, Size.Z) / 2

		Gizmo.PushProperty("Color3", COLLIDER_COLOR)
		Gizmo.Sphere:Draw(Transform, Radius, 15, 360)

		if FILL_COLLIDER then
			Gizmo.SetStyle(FILL_COLOR, 0.75, false)
			Gizmo.VolumeSphere:Draw(Transform, Radius)
			Gizmo.PushProperty("Transparency", 0)
		end

		return
	end
end

--- @within Collider
function Class:Destroy()
	if self.ObjectConnection then
		self.ObjectConnection:Disconnect()
	end

	setmetatable(self, nil)
end

return Class
