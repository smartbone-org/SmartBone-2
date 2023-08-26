--!nocheck

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BonePhysics = require(ReplicatedStorage:WaitForChild("SmartBone"))
local DebugUi = require(script.Parent:WaitForChild("DebugUi"))
local Iris = require(script.Parent:WaitForChild("Iris")).Init()

-- local CollisionObject = workspace:WaitForChild("TestBoxCollider")
-- local CollisionModule = CollisionObject:WaitForChild("Test.collider")

BonePhysics = BonePhysics.new()

BonePhysics:LoadObject(workspace:WaitForChild("Plane"))
-- BonePhysics:LoadCollider(CollisionModule, CollisionObject)

for _, Module in workspace:WaitForChild("Colliders"):GetDescendants() do
	if not Module:IsA("ModuleScript") then
		continue
	end

	BonePhysics:LoadCollider(Module, Module.Parent)
end

local DebugState = {
	DRAW_PHYSICAL_BONE = true,
	DRAW_BONE = true,
	DRAW_AXIS_LIMITS = true,
	DRAW_COLLIDERS = true,
	DRAW_CONTACTS = true,
	UpdateRate = 60,
}

Iris:Connect(function()
	DebugUi(Iris, BonePhysics, DebugState)
end)

local AccumulatedTime = 0

game:GetService("RunService").RenderStepped:Connect(function(dt)
	AccumulatedTime += dt

	local UpdateHz = 1 / DebugState.UpdateRate

	while AccumulatedTime > 0 do
		AccumulatedTime -= UpdateHz

		BonePhysics:StepBoneTrees(UpdateHz)
	end
	BonePhysics:UpdateBoneTrees()

	BonePhysics:DrawDebug(
		DebugState.DRAW_COLLIDERS,
		DebugState.DRAW_CONTACTS,
		DebugState.DRAW_PHYSICAL_BONE,
		DebugState.DRAW_BONE,
		DebugState.DRAW_AXIS_LIMITS
	)
end)
