local ColliderClass = require(script.Parent:WaitForChild("Collider"))

type IRawCollider = {
	Type: string,
	ScaleX: number,
	ScaleY: number,
	ScaleZ: number,
	OffsetX: number,
	OffsetY: number,
	OffsetZ: number,
	RotationX: number,
	RotationY: number,
	RotationZ: number,
}

type IColliderTable = { [number]: IRawCollider }

local Class = {}
Class.__index = Class

function Class.new(ColliderTable, Object)
	local self = setmetatable({
		m_Object = Object,
		Colliders = {},
	}, Class)

	self:m_LoadColliderTable(ColliderTable)

	return self
end

function Class:m_LoadCollider(Collider: IRawCollider)
	local FormattedScale = Vector3.new(Collider.ScaleX, Collider.ScaleY, Collider.ScaleZ)
	local FormattedOffset = Vector3.new(Collider.OffsetX, Collider.OffsetY, Collider.OffsetZ)
	local FormattedRotation = Vector3.new(Collider.RotationX, Collider.RotationY, Collider.RotationZ)

	local ColliderSolver = ColliderClass.new()
	ColliderSolver.Scale = FormattedScale
	ColliderSolver.Offset = FormattedOffset
	ColliderSolver.Rotation = FormattedRotation
	ColliderSolver.Type = Collider.Type
	ColliderSolver:SetObject(self.m_Object)

	table.insert(self.Colliders, ColliderSolver)
end

function Class:m_LoadColliderTable(ColliderTable: IColliderTable)
	for _, Collider in ColliderTable do
		self:m_LoadCollider(Collider)
	end
end

-- Public

function Class:GetCollisions(Point, Radius)
	local Collisions = {}

	for _, Collider in self.Colliders do
		local IsInside, ClosestPoint, Normal = Collider:GetClosestPoint(Point, Radius)

		if IsInside then
			table.insert(Collisions, { ClosestPoint = ClosestPoint, Normal = Normal })
		end
	end

	return Collisions
end

function Class:DrawDebug()
	for _, Collider in self.Colliders do
		Collider:DrawDebug()
	end
end

return Class
