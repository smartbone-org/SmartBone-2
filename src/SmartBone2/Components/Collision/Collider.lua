--!nocheck

local HttpService = game:GetService("HttpService")

local Dependencies = script.Parent.Parent.Parent:WaitForChild("Dependencies")
local CollisionSolvers = script.Parent:WaitForChild("Colliders")
local BoxSolver = require(CollisionSolvers:WaitForChild("Box"))
local CapsuleSolver = require(CollisionSolvers:WaitForChild("Capsule"))
local CylinderSolver = require(CollisionSolvers:WaitForChild("Cylinder"))
local SphereSolver = require(CollisionSolvers:WaitForChild("Sphere"))

local Utilities = require(script.Parent.Parent.Parent:WaitForChild("Dependencies"):WaitForChild("Utilities"))

local SB_VERBOSE_LOG = Utilities.SB_VERBOSE_LOG

local Radians = 0.017453
local Gizmo = require(Dependencies:WaitForChild("Gizmo"))
Gizmo.Init()

local function RoundV3(Vector, Decimals)
	local X = math.floor(Vector.X * 10 ^ Decimals)
	local Y = math.floor(Vector.Y * 10 ^ Decimals)
	local Z = math.floor(Vector.Z * 10 ^ Decimals)

	return X, Y, Z
end

local function CompareV3(Vector0, Vector1, Decimals)
	local X0, Y0, Z0 = RoundV3(Vector0, Decimals)
	local X1, Y1, Z1 = RoundV3(Vector1, Decimals)

	if X0 == X1 and Y0 == Y1 and Z0 == Z1 then
		return true
	end

	return false
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
	if self.m_Object == nil then
		return
	end

	local Object = self.m_Object
	local ObjectCFrame = Object.CFrame
	local ObjectSize = Object.Size

	local Offset = self.Offset
	local Rotation = self.Rotation

	local ScaledOffset = ObjectSize * Offset

	local RotationCFrame = CFrame.Angles(Rotation.X * Radians, Rotation.Y * Radians, Rotation.Z * Radians)
	local TransformCFrame = ObjectCFrame * CFrame.new(ScaledOffset) * RotationCFrame

	self.Transform = TransformCFrame
end

function Class:FastTransform()
	local Object = self.m_Object
	local ObjectCFrame = Object.CFrame
	local ObjectSize = Object.Size

	local Scale = self.Scale
	local Offset = self.Offset

	local ScaledOffset = ObjectSize * Offset
	local ScaledSize = ObjectSize * Scale

	self.Transform = ObjectCFrame * CFrame.new(ScaledOffset)
	self.Size = ScaledSize
	self.Radius = math.sqrt((math.max(ScaledSize.X, ScaledSize.Y, ScaledSize.Z) * 0.5) ^ 2 * 2)
end

--- @within Collider
--- @param Point Vector3
--- @param Radius number
--- @return Vector3 | nil -- Returns nil if specified collider shape is invalid
function Class:GetClosestPoint(Point, Radius)
	self:FastTransform()

	-- If we are outside the radius of the bounding box don't fully update transform and don't do any collision checks
	-- Broadphase collision detection
	local PointDistance = (Point - self.Transform.Position).Magnitude
	if PointDistance > self.Radius then
		return
	end

	local PropertyChange = true

	if not self.m_Object then
		return
	end

	if self.Scale ~= self.PreviousScale then
		PropertyChange = true
		self.PreviousScale = self.Scale
	end

	if self.Offset ~= self.PreviousOffset then
		PropertyChange = true
		self.PreviousOffset = self.Offset
	end

	if self.Rotation ~= self.PreviousRotation then
		PropertyChange = true
		self.PreviousRotation = self.Rotation
	end

	if CompareV3(self.m_Object.Position, self.PreviousObjectPosition, 2) then
		PropertyChange = true
		self.PreviousObjectPosition = self.m_Object.Position
	end

	if CompareV3(self.m_Object.Orientation, self.PreviousObjectRotation, 2) then
		PropertyChange = true
		self.PreviousObjectRotation = self.m_Object.Orientation
	end

	if PropertyChange then
		self:UpdateTransform()
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

	if Type == "Cylinder" then
		return CylinderSolver(self.Transform, self.Size, Point, Radius)
	end

	-- this crashes studio cause it prints so many times
	-- warn(`Invalid collider shape: {Type} in object {self.m_Object.Name}`)

	return
end

--- @within Collider
--- @param FILL_COLLIDER boolean
function Class:DrawDebug(FILL_COLLIDER)
	local COLLIDER_COLOR = Color3.new(0.509803, 0.933333, 0.427450)
	local FILL_COLOR = Color3.new(0.901960, 0.784313, 0.513725)

	local Type = self.Type
	local Transform = self.Transform
	local Size = self.Size

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
		local CapsuleRadius = math.min(Size.Y, Size.Z) * 0.5
		local CapsuleLength = Size.X

		Gizmo.SetStyle(COLLIDER_COLOR, 0, false)
		Gizmo.Capsule:Draw(Transform, CapsuleRadius, CapsuleLength, 15)

		if FILL_COLLIDER then
			local TransformedTransform = Transform * CFrame.Angles(math.rad(90), -math.rad(90), 0)

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
		local Radius = math.min(Size.Y, Size.Z) * 0.5

		Gizmo.SetStyle(COLLIDER_COLOR, 0, false)
		Gizmo.Cylinder:Draw(Transform, Radius, Size.X, 15)

		if FILL_COLLIDER then
			Gizmo.SetStyle(FILL_COLOR, 0.75, false)
			Gizmo.VolumeCylinder:Draw(Transform, Radius, Size.X, 0, 360)
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
