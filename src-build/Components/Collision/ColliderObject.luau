local ColliderClass = require(script.Parent:WaitForChild("Collider"))
local Utilities = require(script.Parent.Parent.Parent:WaitForChild("Dependencies"):WaitForChild("Utilities"))

local SB_VERBOSE_LOG = Utilities.SB_VERBOSE_LOG
local SleepCycleInterval = 0.2

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
	RotationZ: number
}

type bool = boolean

export type IColliderTable = { [number]: IRawCollider }
export type IColliderObject = {
	m_Object: BasePart,
	m_Awake: bool,
	m_LastSleepCycle: number,
	Destroyed: bool,
	Colliders: IColliderTable
}

--- @class ColliderObject
--- Internal class for collider
--- :::caution Caution:
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
function Class.new(ColliderTable: IColliderTable, Object: BasePart): IColliderObject
	local self = setmetatable({
		m_Object = Object,
		m_Awake = true,
		m_LastSleepCycle = 0,
		Destroyed = false,
		Colliders = {},
	}, Class)

	self:m_LoadColliderTable(ColliderTable)

	self.DestroyConnection = Object:GetPropertyChangedSignal("Parent"):Connect(function()
		if Object.Parent == nil then
			self.Destroyed = true
		end
	end)

	return self :: IColliderObject
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
--- @return BasePart
function Class:GetObject()
	return self.m_Object
end

--- @within ColliderObject
--- @param Point Vector3
--- @param Radius number -- Radius of bone
--- @param Collisions {[number]: {ClosestPoint: Vector3, Normal: Vector3}} -- Appended to in place
--- @return boolean
function Class:GetCollisions(Point, Radius, Collisions)
do end	
if not self.m_Object then
do end		
return false
	end

	if #self.Colliders == 0 then
do end		
return false
	end
do end	

local Clock = os.clock()
	if Clock - self.m_LastSleepCycle >= SleepCycleInterval then -- Run sleep conditions every 5th of a second
		self.m_LastSleepCycle = Clock

		if self.m_Object:IsDescendantOf(workspace) then -- If our object is not a descendant of workspace put it to sleep
			self.m_Awake = true
		else
			self.m_Awake = false
		end
	end
do end
	
if not self.m_Awake then
do end		
return false
	end

	local DidCollide = false
do end	

for _, Collider in self.Colliders do
do end		
local IsInside, ClosestPoint, Normal = Collider:GetClosestPoint(Point, Radius)
do end
		
if IsInside then
			DidCollide = true
			table.insert(Collisions, { ClosestPoint = ClosestPoint, Normal = Normal })
		end
	end
do end do end
	

return DidCollide
end

--- @within ColliderObject
function Class:Step()
do end	
for _, Collider in self.Colliders do
		Collider:Step()
	end
do end
end

--- @within ColliderObject
--- @param FILL_COLLIDERS boolean
--- @param SHOW_INFLUENCE boolean
--- @param SHOW_AWAKE boolean
--- @param SHOW_BROADPHASE boolean
function Class:DrawDebug(FILL_COLLIDERS, SHOW_INFLUENCE, SHOW_AWAKE, SHOW_BROADPHASE)
	for _, Collider in self.Colliders do
		Collider:DrawDebug(self, FILL_COLLIDERS, SHOW_INFLUENCE, SHOW_AWAKE, SHOW_BROADPHASE)
		Collider.InNarrowphase = false
	end
end

--- @within ColliderObject
function Class:Destroy() -- Must be called from serial context
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
