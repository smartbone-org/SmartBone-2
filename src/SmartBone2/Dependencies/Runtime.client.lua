local Actor: Actor = script.Parent
local RootObject
local ColliderDescriptions
local SmartboneModule
local SmartboneClass

local Setup = false

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
local Iris = require(Dependencies.Iris)
local Utilities = require(Dependencies.Utilities)
local ShouldDebug = RunService:IsStudio()

if not Iris.HasInit() then
	Iris = Iris.Init()
end

Actor.Name = `{RootObject.Name} - {BonePhysics.ID}`

BonePhysics:LoadObject(RootObject)

for _, ColliderDescription in ColliderDescriptions do
	BonePhysics:LoadRawCollider(ColliderDescription[1], ColliderDescription[2])
end

local DebugState = {
	DRAW_BONE = Iris.State(false),
	DRAW_PHYSICAL_BONE = Iris.State(false),
	DRAW_ROOT_PART = Iris.State(false),
	DRAW_AXIS_LIMITS = Iris.State(false),
	DRAW_COLLIDERS = Iris.State(false),
	DRAW_COLLIDER_INFLUENCE = Iris.State(false),
	DRAW_COLLIDER_AWAKE = Iris.State(false),
	DRAW_COLLIDER_BROADPHASE = Iris.State(false),
	DRAW_FILL_COLLIDERS = Iris.State(false),
	DRAW_CONTACTS = Iris.State(false),
}

-- ShouldDebug is just if we are in studio or not
if ShouldDebug then
	Iris:Connect(function()
		if RootObject:GetAttribute("Debug") ~= nil then
			DebugUi(Iris, BonePhysics, DebugState)
		end
	end)
end

CollectionService:GetInstanceAddedSignal("SmartCollider"):Connect(function(Object: BasePart)
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
end)

local Connection

Connection = RunService.RenderStepped:Connect(function(deltaTime)
	BonePhysics:StepBoneTrees(deltaTime)

	if BonePhysics.ShouldDestroy then
		task.synchronize()
		Connection:Disconnect()
		BonePhysics:Destroy()
		Actor:Destroy()
		return
	end

	-- ShouldDebug is just if we are in studio or not
	if ShouldDebug then
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
			DebugState.DRAW_COLLIDER_BROADPHASE:get()
		)
	end
end)
