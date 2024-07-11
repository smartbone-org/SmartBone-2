local Actor: Actor = script.Parent
local RootObject
local ColliderDescriptions
local SmartboneModule
local SmartboneClass

local Setup = false

local CONNECTIONS = {}

local function c(Conn: RBXScriptConnection)
	table.insert(CONNECTIONS, Conn)
end

local function cleanup()
	for _, Conn: RBXScriptConnection in CONNECTIONS do
		Conn:Disconnect()
	end
end

local Bind
Bind = Actor:BindToMessage("Setup", function(m_Object, m_ColliderDescriptions, m_SmartBone)
	RootObject = m_Object
	ColliderDescriptions = m_ColliderDescriptions
	SmartboneModule = m_SmartBone
	SmartboneClass = require(m_SmartBone)

	Setup = true

	Bind:Disconnect()
end)

repeat
	task.wait()
until Setup

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local BonePhysics = SmartboneClass.new()
local Dependencies = SmartboneModule.Dependencies
local DebugUi = require(Dependencies.DebugUi)
local Iris
local Config = require(Dependencies.Config)
local Utilities = require(Dependencies.Utilities)
local ShouldDebug = RunService:IsStudio() or Config.ALLOW_LIVE_GAME_DEBUG
local OverlayEvent = SmartboneModule:WaitForChild("OverlayEvent")

local ForceDestroy = false

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

Actor.Name = `{RootObject.Name} - {BonePhysics.ID}`

BonePhysics:LoadObject(RootObject)

for _, ColliderDescription in ColliderDescriptions do
	BonePhysics:LoadRawCollider(ColliderDescription[1], ColliderDescription[2])
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
end

-- ShouldDebug is just if we are in studio or not
if ShouldDebug then
	Iris:Connect(function()
		if RootObject:GetAttribute("Debug") ~= nil then
			DebugUi(Iris, BonePhysics, DebugState)
		end
	end)
end

c(CollectionService:GetInstanceAddedSignal("SmartCollider"):Connect(function(Object: BasePart)
	if not Object:IsA("BasePart") then
		return
	end

	local ColliderKey = Object:GetAttribute("ColliderKey")
	local RootColliderKey = RootObject:GetAttribute("ColliderKey")

	if tostring(ColliderKey) ~= tostring(RootColliderKey) then
		return
	end

	local ColliderObject = Utilities.GetCollider(Object)

	BonePhysics:LoadRawCollider(ColliderObject, Object)
end))

c(Actor:BindToMessage("Destroy", function()
	ForceDestroy = true
end))

c(RunService.Heartbeat:ConnectParallel(function(deltaTime)
	shared.FrameCounter += 1

	if shared.FrameCounter > FrameCounterOverflow then
		shared.FrameCounter = 0
	end

	BonePhysics:StepBoneTrees(deltaTime)

	if BonePhysics.ShouldDestroy or ForceDestroy then
		BonePhysics:Destroy()

		task.synchronize()
		cleanup()
		Actor:Destroy()
		return
	end

	-- ShouldDebug is just if we are in studio or not
	if ShouldDebug then
		if RootObject:GetAttribute("Debug") ~= nil then
			task.synchronize()
			BonePhysics:DrawDebug(
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

			BonePhysics:DrawOverlay(ImOverlay)
		end
	end
end))
