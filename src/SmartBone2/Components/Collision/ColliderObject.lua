local ColliderClass = require(script.Parent:WaitForChild("Collider"))
local Utilities = require(script.Parent.Parent.Parent:WaitForChild("Dependencies"):WaitForChild("Utilities"))

local SB_VERBOSE_LOG = Utilities.SB_VERBOSE_LOG

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

--- @class ColliderObject
--- Internal class for collider
--- :::caution Caution: Warning
--- Changes to the syntax in this class will not count to the major version in semver.
--- :::

--- @within ColliderObject
--- @private
--- @readonly
--- @prop m_Object BasePart

--- @within ColliderObject
--- @readonly
--- @prop Destroyed boolean

--- @within ColliderObject
--- @readonly
--- @prop Colliders {}

local Class = {}
Class.__index = Class

--- @within ColliderObject
--- @param ColliderTable {[number]: {Type: string, ScaleX: number, ScaleY: number, ScaleZ: number, OffsetX: number, OffsetY: number, OffsetZ: number, RotationX: number, RotationY: number, RotationZ: number}}
--- @param Object BasePart
--- @return ColliderObject
function Class.new(ColliderTable, Object: BasePart)
	local self = setmetatable({
		m_Object = Object,
		Destroyed = false,
		Colliders = {},
	}, Class)

	self:m_LoadColliderTable(ColliderTable)

	self.DestroyConnection = Object:GetPropertyChangedSignal("Parent"):Connect(function()
		if Object.Parent == nil then
			self.Destroyed = true
		end
	end)

	return self
end

--- @within ColliderObject
--- @private
--- @param Collider {Type: string, ScaleX: number, ScaleY: number, ScaleZ: number, OffsetX: number, OffsetY: number, OffsetZ: number, RotationX: number, RotationY: number, RotationZ: number}
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

--- @within ColliderObject
--- @private
--- @param ColliderTable {[number]: {Type: string, ScaleX: number, ScaleY: number, ScaleZ: number, OffsetX: number, OffsetY: number, OffsetZ: number, RotationX: number, RotationY: number, RotationZ: number}}
function Class:m_LoadColliderTable(ColliderTable: IColliderTable)
	for _, Collider in ColliderTable do
		self:m_LoadCollider(Collider)
	end
end

-- Public

--- @within ColliderObject
--- @param Point Vector3
--- @param Radius number -- Radius of bone
--- @return {[number]: {ClosestPoint: Vector3, Normal: Vector3}}
function Class:GetCollisions(Point, Radius)
	if #self.Colliders == 0 then
		return {}
	end

	local Collisions = {}

	for _, Collider in self.Colliders do
		local IsInside, ClosestPoint, Normal = Collider:GetClosestPoint(Point, Radius)

		if IsInside then
			table.insert(Collisions, { ClosestPoint = ClosestPoint, Normal = Normal })
		end
	end

	return Collisions
end

--- @within ColliderObject
--- @param FILL_COLLIDERS boolean
function Class:DrawDebug(FILL_COLLIDERS)
	for _, Collider in self.Colliders do
		Collider:DrawDebug(FILL_COLLIDERS)
	end
end

--- @within ColliderObject
function Class:Destroy()
	SB_VERBOSE_LOG(`Collider object destroying, object: {self.m_Object}`)

	self.DestroyConnection:Disconnect()

	if #self.Colliders ~= 0 then
		for _, Collider in self.Colliders do
			Collider:Destroy()
		end
	end

	setmetatable(self, nil)
end

return Class
