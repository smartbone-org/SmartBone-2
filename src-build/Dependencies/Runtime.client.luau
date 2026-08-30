local Actor: Actor = script.Parent
local SmartboneModule

local CONNECTIONS = {}

local function c(Conn: RBXScriptConnection)
	table.insert(CONNECTIONS, Conn)
end

local function cleanup()
	for _, Conn: RBXScriptConnection in CONNECTIONS do
		Conn:Disconnect()
	end
end

-- A worker hosts however many objects the pool assigned it, so these stay bound for its lifetime.
-- Messages are queued here and drained during the serial phase, since loading a root writes instances.
local SetupQueue = {}
local FreeQueue = {}

c(Actor:BindToMessage("Setup", function(m_Object, m_ColliderDescriptions, m_SmartBone)
	SmartboneModule = m_SmartBone

	table.insert(SetupQueue, { m_Object, m_ColliderDescriptions })
end))

c(Actor:BindToMessage("Free", function(m_Object)
	table.insert(FreeQueue, m_Object)
end))

repeat
	task.wait()
until SmartboneModule

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local SmartboneClass = require(SmartboneModule)
local Dependencies = SmartboneModule.Dependencies
local DebugUi = require(Dependencies.Debug.DebugUi)
local Iris
local Config = require(SmartboneModule.Config)
local Utilities = require(Dependencies.Utilities)
local ShouldDebug = RunService:IsStudio() or Config.ALLOW_LIVE_GAME_DEBUG
local OverlayEvent = SmartboneModule:WaitForChild("OverlayEvent")

local ForceDestroy = false

local Roots = {} -- { {Object = BasePart, Physics = SmartBone} }
local RootByObject = {}

-- So much work for such a basic debug tool
local ImOverlay = {
	Begin = function(...)
		OverlayEvent:Fire("Begin", ...)
	end,
	End = function(...)
		OverlayEvent:Fire("End", ...)
	end,
	Text = function(...)
		OverlayEvent:Fire("Text", ...)
	end,
}

-- Frame counter for getting animatedworldcframe
shared.FrameCounter = 0
local FrameCounterOverflow = 131072

if ShouldDebug then
	Iris = require(Dependencies.Iris)
	if not Iris.HasInit() then
		Iris = Iris.Init()
	end
end

local DebugState

if ShouldDebug then
	DebugState = {
		DRAW_BONE = Iris.State(false),
		DRAW_PHYSICAL_BONE = Iris.State(false),
		DRAW_ROOT_PART = Iris.State(false),
		DRAW_BOUNDING_BOX = Iris.State(false),
		DRAW_AXIS_LIMITS = Iris.State(false),
		DRAW_COLLIDERS = Iris.State(false),
		DRAW_COLLIDER_INFLUENCE = Iris.State(false),
		DRAW_COLLIDER_AWAKE = Iris.State(false),
		DRAW_COLLIDER_BROADPHASE = Iris.State(false),
		DRAW_FILL_COLLIDERS = Iris.State(false),
		DRAW_CONTACTS = Iris.State(false),
		DRAW_ROTATION_LIMITS = Iris.State(false),
		DRAW_ACCELERATION_INFO = Iris.State(false),
	}

	Iris:Connect(function()
		for _, Entry in Roots do
			if Entry.Object:GetAttribute("Debug") ~= nil then
				DebugUi(Iris, Entry.Physics, DebugState)
			end
		end
	end)
end

local function AddRoot(Object: BasePart, ColliderDescriptions)
	local Physics = SmartboneClass.new()

	Physics:LoadObject(Object)

	for _, ColliderDescription in ColliderDescriptions do
		Physics:LoadRawCollider(ColliderDescription[1], ColliderDescription[2])
	end

	local Entry = { Object = Object, Physics = Physics }

	table.insert(Roots, Entry)
	RootByObject[Object] = Entry
end

local function RemoveRoot(Index: number)
	local Entry = Roots[Index]

	RootByObject[Entry.Object] = nil
	table.remove(Roots, Index)

	Entry.Physics:Destroy()
end

c(CollectionService:GetInstanceAddedSignal("SmartCollider"):Connect(function(Object: BasePart)
	if not Object:IsA("BasePart") then
		return
	end

	local ColliderKey = tostring(Object:GetAttribute("ColliderKey"))
	local Description

	for _, Entry in Roots do
		if ColliderKey ~= tostring(Entry.Object:GetAttribute("ColliderKey")) then
			continue
		end

		Description = Description or Utilities.GetCollider(Object)

		Entry.Physics:LoadRawCollider(Description, Object)
	end
end))

c(CollectionService:GetInstanceRemovedSignal("SmartCollider"):Connect(function(Object: BasePart)
	for _, Entry in Roots do
		for _, ColliderObject in Entry.Physics.ColliderObjects do
			if ColliderObject:GetObject() == Object then
				ColliderObject.Destroyed = true
			end
		end
	end
end))

c(Actor:BindToMessage("Destroy", function()
	ForceDestroy = true
end))

c(RunService.Heartbeat:ConnectParallel(function(deltaTime)
	shared.FrameCounter += 1

	if shared.FrameCounter > FrameCounterOverflow then
		shared.FrameCounter = 0
	end

	local NeedsSerial = ForceDestroy or #SetupQueue ~= 0 or #FreeQueue ~= 0

	for _, Entry in Roots do
		if Entry.Physics:StepParallel(deltaTime) or Entry.Physics.ShouldDestroy then
			NeedsSerial = true
		end
	end

	local WantsDebug = false

	if ShouldDebug then
		for _, Entry in Roots do
			if Entry.Object:GetAttribute("Debug") ~= nil then
				WantsDebug = true
				break
			end
		end
	end

	if not NeedsSerial and not WantsDebug then
		return
	end

	-- Single transition for every root this worker owns
	task.synchronize()

	for _, Entry in Roots do
		Entry.Physics:ApplyPending()
	end

	for i = #Roots, 1, -1 do
		if ForceDestroy or Roots[i].Physics.ShouldDestroy then
			RemoveRoot(i)
		end
	end

	if ForceDestroy then
		cleanup()
		return
	end

	for _, Item in SetupQueue do
		AddRoot(Item[1], Item[2])
	end
	table.clear(SetupQueue)

	for _, Object in FreeQueue do
		local Entry = RootByObject[Object]
		local Index = Entry and table.find(Roots, Entry)

		if Index then
			RemoveRoot(Index)
		end
	end
	table.clear(FreeQueue)

	if not WantsDebug then
		return
	end

	for _, Entry in Roots do
		if Entry.Object:GetAttribute("Debug") == nil then
			continue
		end

		Entry.Physics:DrawDebug(
			DebugState.DRAW_COLLIDERS:get(),
			DebugState.DRAW_CONTACTS:get(),
			DebugState.DRAW_PHYSICAL_BONE:get(),
			DebugState.DRAW_BONE:get(),
			DebugState.DRAW_AXIS_LIMITS:get(),
			DebugState.DRAW_ROOT_PART:get(),
			DebugState.DRAW_FILL_COLLIDERS:get(),
			DebugState.DRAW_COLLIDER_INFLUENCE:get(),
			DebugState.DRAW_COLLIDER_AWAKE:get(),
			DebugState.DRAW_COLLIDER_BROADPHASE:get(),
			DebugState.DRAW_BOUNDING_BOX:get(),
			DebugState.DRAW_ROTATION_LIMITS:get(),
			DebugState.DRAW_ACCELERATION_INFO:get()
		)

		Entry.Physics:DrawOverlay(ImOverlay)
	end
end))
