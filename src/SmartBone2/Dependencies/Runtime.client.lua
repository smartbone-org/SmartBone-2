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
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local BonePhysics = SmartboneClass.new()
local Dependencies = SmartboneModule.Dependencies
local DebugUi = require(Dependencies.DebugUi)
local Iris = require(Dependencies.Iris)
local ShouldDebug = RunService:IsStudio()

local ColliderTranslations = {
	Block = "Box",
	Ball = "Sphere",
	Capsule = "Capsule",
	Sphere = "Sphere",
	Box = "Box",
	Cylinder = "Cylinder",
}

local function GetCollider(Object: BasePart)
	-- Any shapes which arent defined in the translation table are defaulted to box

	local ColliderModule = Object:FindFirstChild("self.Collider")
	local ColliderDescription

	if ColliderModule and ColliderModule:IsA("ModuleScript") then
		local RawColliderData = require(ColliderModule)
		local ColliderData
		pcall(function()
			ColliderData = HttpService:JSONDecode(RawColliderData)
		end)

		ColliderDescription = ColliderData
	end

	if ColliderDescription then
		return ColliderDescription
	end

	-- Only runs if there was no collider module or the collider data wasn't valid json

	local function GetShapeName(obj)
		local ShapeAttribute = obj:GetAttribute("ColliderShape")

		if ShapeAttribute then
			return ShapeAttribute
		end

		if obj:IsA("Part") then -- Allow meshes and unions to have colliders
			return obj.Shape.Name
		end

		return "Box"
	end

	local ColliderType = ColliderTranslations[GetShapeName(Object)] or "Box"

	ColliderDescription = {
		{
			Type = ColliderType,
			ScaleX = 1,
			ScaleY = 1,
			ScaleZ = 1,
			OffsetX = 0,
			OffsetY = 0,
			OffsetZ = 0,
			RotationX = 0,
			RotationY = 0,
			RotationZ = 0,
		},
	}

	return ColliderDescription
end

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
	DRAW_FILL_COLLIDERS = Iris.State(false),
	DRAW_CONTACTS = Iris.State(false),
}

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

	if ColliderKey and RootColliderKey then
		if ColliderKey ~= RootColliderKey then
			return
		end
	end

	local ColliderObject = GetCollider(Object)

	BonePhysics:LoadRawCollider(ColliderObject, Object)
end)

RunService.RenderStepped:Connect(function(deltaTime)
	BonePhysics:StepBoneTrees(deltaTime)

	if BonePhysics.ShouldDestroy then
		BonePhysics:Destroy()
		Actor:Destroy()
		return
	end

	if ShouldDebug then
		BonePhysics:DrawDebug(
			DebugState.DRAW_COLLIDERS:get(),
			DebugState.DRAW_CONTACTS:get(),
			DebugState.DRAW_PHYSICAL_BONE:get(),
			DebugState.DRAW_BONE:get(),
			DebugState.DRAW_AXIS_LIMITS:get(),
			DebugState.DRAW_ROOT_PART:get(),
			DebugState.DRAW_FILL_COLLIDERS:get()
		)
	end
end)
