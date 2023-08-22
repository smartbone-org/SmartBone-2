local HttpService = game:GetService("HttpService")

local Dependencies = script.Parent.Parent.Parent:WaitForChild("Dependencies")
local CollisionSolvers = script.Parent:WaitForChild("Colliders")
local BoxSolver = require(CollisionSolvers:WaitForChild("Box"))
local CapsuleSolver = require(CollisionSolvers:WaitForChild("Capsule"))
local SphereSolver = require(CollisionSolvers:WaitForChild("Sphere"))
local WedgeSolver = require(CollisionSolvers:WaitForChild("Wedge"))

local Gizmo = require(Dependencies:WaitForChild("Gizmo"))
Gizmo.Init()

local Class = {}
Class.__index = Class

function Class.new()
	return setmetatable({
		Type = "Box",
		Scale = Vector3.zero,
		Offset = Vector3.zero,
		Rotation = Vector3.zero,

		Object = nil,

		Transform = CFrame.identity,
		Size = Vector3.zero,

		GUID = HttpService:GenerateGUID(),
	}, Class)
end

function Class:UpdateTransform()
	if self.Object == nil then
		return
	end

	local Object = self.Object
	local ObjectCFrame = Object.CFrame
	local ObjectPosition = Object.Position
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

function Class:GetClosestPoint(Point, Radius)
	self:UpdateTransform()

	-- Determine which collision solver we should send this off to

	local Type = self.Type

	if Type == "Box" then
		return BoxSolver(self.Transform, self.Size, Point, Radius)
	end

	if Type == "Capsule" then
		return CapsuleSolver(self.Transform, self.Size, Point, Radius)
	end

	if Type == "Wedge" then
		return WedgeSolver(self.Transform, self.Size, Point, Radius)
	end

	if Type == "Sphere" then
		return SphereSolver(self.Transform, self.Size, Point, Radius)
	end
end

function Class:DrawDebug()
	local COLLIDER_COLOR = Color3.new(0.509803, 0.933333, 0.427450)

	local Type = self.Type
	local Transform = self.Transform
	local Size = self.Size

	Gizmo.PushProperty("AlwaysOnTop", false)

	if Type == "Box" then
		Gizmo.PushProperty("Color3", COLLIDER_COLOR)
		Gizmo.Box:Draw(Transform, Size)
	end

	if Type == "Capsule" then
		local CapsuleRadius = math.min(Size.Y, Size.Z) / 2
		local CapsuleLength = Size.X

		Gizmo.PushProperty("Color3", COLLIDER_COLOR)
		Gizmo.Capsule:Draw(Transform, CapsuleRadius, CapsuleLength, 15)
	end

	if Type == "Wedge" then
		Gizmo.PushProperty("Color3", COLLIDER_COLOR)
		Gizmo.Wedge:Draw(Transform, Size)
	end

	if Type == "Sphere" then
		local Radius = math.min(Size.X, Size.Y, Size.Z) / 2

		Gizmo.PushProperty("Color3", COLLIDER_COLOR)
		Gizmo.Sphere:Draw(Transform, Radius, 15, 360)
	end
end

return Class
