local Actor: Actor = script.Parent
local Object
local ColliderDescriptions
local SmartboneModule
local SmartboneClass

local Setup = false

local Bind
Bind = Actor:BindToMessage("Setup", function(m_Object, m_ColliderDescriptions, m_SmartBone)
	Object = m_Object
	ColliderDescriptions = m_ColliderDescriptions
	SmartboneModule = m_SmartBone
	SmartboneClass = require(m_SmartBone)

	Setup = true

	Bind:Disconnect()
end)

repeat
	task.wait()
until Setup

local RunService = game:GetService("RunService")
local BonePhysics = SmartboneClass.new()
local Dependencies = SmartboneModule.Dependencies
local DebugUi = require(Dependencies.DebugUi)
local Iris = require(Dependencies.Iris)

if not Iris.HasInit() then
	Iris = Iris.Init()
end

Actor.Name = `{Object.Name} - {BonePhysics.ID}`

BonePhysics:LoadObject(Object)

for _, ColliderDescription in ColliderDescriptions do
	BonePhysics:LoadRawCollider({ ColliderDescription[1] }, ColliderDescription[2])
end

local DebugState = {
	DRAW_BONE = Iris.State(false),
	DRAW_PHYSICAL_BONE = Iris.State(false),
	DRAW_ROOT_PART = Iris.State(false),
	DRAW_AXIS_LIMITS = Iris.State(false),
	DRAW_COLLIDERS = Iris.State(false),
	DRAW_FILL_COLLIDERS = Iris.State(false),
	DRAW_CONTACTS = Iris.State(false),
}

Iris:Connect(function()
	if Object:GetAttribute("Debug") ~= nil then
		DebugUi(Iris, BonePhysics, DebugState)
	end
end)

RunService.RenderStepped:Connect(function(deltaTime)
	BonePhysics:StepBoneTrees(deltaTime)

	if BonePhysics.ShouldDestroy then
		BonePhysics:Destroy()
		Actor:Destroy()
		return
	end

	BonePhysics:DrawDebug(
		DebugState.DRAW_COLLIDERS:get(),
		DebugState.DRAW_CONTACTS:get(),
		DebugState.DRAW_PHYSICAL_BONE:get(),
		DebugState.DRAW_BONE:get(),
		DebugState.DRAW_AXIS_LIMITS:get(),
		DebugState.DRAW_ROOT_PART:get(),
		DebugState.DRAW_FILL_COLLIDERS:get()
	)
end)
