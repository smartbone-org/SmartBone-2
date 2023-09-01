local Actor: Actor = script.Parent
local Object
local ColliderDescriptions
local Smartbone

local Setup = false

local Bind
Bind = Actor:BindToMessage("Setup", function(m_Object, m_ColliderDescriptions, m_SmartBone)
	Object = m_Object
	ColliderDescriptions = m_ColliderDescriptions
	Smartbone = m_SmartBone

	Setup = true

	Bind:Disconnect()
end)

repeat
	task.wait()
until Setup

local RunService = game:GetService("RunService")
local BonePhysics = require(Smartbone).new()

Actor.Name = `{Object.Name} - {BonePhysics.ID}`

BonePhysics:LoadObject(Object)

for _, ColliderDescription in ColliderDescriptions do
	BonePhysics:LoadRawCollider({ ColliderDescription[1] }, ColliderDescription[2])
end

RunService.RenderStepped:Connect(function(deltaTime)
	BonePhysics:StepBoneTrees(deltaTime)
	BonePhysics:UpdateBoneTrees()
end)
