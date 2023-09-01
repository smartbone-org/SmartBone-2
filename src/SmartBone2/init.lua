--[[

    How do we define colliders?

    Colliders need to be under an object, their scale and cframe will be relative to
    that object, now how do we define the colliders which each mesh should interact with
    
    We could define the objects and their collider module through code,
    but that would go against the simplicity with the current smart bone module.

    However making colliders is an involved process which would involve a plugin.
    Code defining the objects which we use for colliders isnt out of the question.

    Other ideas:

    Using InstanceValues to reference objects which we search for modules
    that end with .collider?

    --

    I think this module is going to be you have to use code to interface with it anyway,
    thats what I'd like it to be same with smartbone. The idea that you just add a tag and it
    finds objects to use just seems prone to issues and edge cases.

    Possible api:

    local ObjectPhysics = BonePhysics.new()
    ObjectPhysics:LoadObject(Object0)
    ObjectPhysics:LoadObject(Object1)

    ObjectPhysics:LoadCollider(Object2, ColliderModule)

    ObjectPhysics:Destroy()
]]

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Components = script:WaitForChild("Components")
local Dependencies = script:WaitForChild("Dependencies")

local Frustum = require(Dependencies:WaitForChild("Frustum"))
local Utilities = require(Dependencies:WaitForChild("Utilities"))

local BoneClass = require(Components:WaitForChild("Bone"))
local BoneTreeClass = require(Components:WaitForChild("BoneTree"))
local ColliderObjectClass = require(Components:WaitForChild("Collision"):WaitForChild("ColliderObject"))

local ActorRuntime = Dependencies:WaitForChild("Runtime")

local ColliderTranslations = {
	Block = "Box",
	Ball = "Sphere",
}

local function CopyPasteAttributes(Object1: BasePart, Object2: BasePart)
	for k, v in Object1:GetAttributes() do
		Object2:SetAttribute(k, v)
	end
end

local Class = {}
Class.__index = Class

function Class.new()
	local self = setmetatable({
		ID = HttpService:GenerateGUID(false),
		Time = 0,
		BoneTrees = {},
		ColliderObjects = {},
		Connections = {},
		WindPreviousPosition = Vector3.zero,
		Removed = false,
		RemovedEvent = Instance.new("BindableEvent"),
		InRange = false,
	}, Class)

	return self
end

-- Private Functions

function Class:m_AppendBone(BoneTree: BoneTreeClass.IBoneTree, BoneObject: Bone, ParentIndex: number, HeirarchyLength: number)
	local Settings = Utilities.GatherBoneSettings(BoneObject)
	local Bone: BoneClass.IBone = BoneClass.new(BoneObject, BoneTree.Root, BoneTree.RootPart)

	for k, v in Settings do
		Bone[k] = v
	end

	local ParentBone = BoneTree.Bones[ParentIndex]

	if ParentIndex > 0 then
		local BoneLength = (ParentBone.Position - Bone.Position).Magnitude
		Bone.FreeLength = BoneLength
		Bone.Weight = BoneLength * 0.7 -- Why 0.7?
		Bone.HeirarchyLength = HeirarchyLength
	end

	if HeirarchyLength <= BoneTree.Settings.AnchorDepth then
		Bone.Anchored = true
	end

	Bone.ParentIndex = ParentIndex

	table.insert(BoneTree.Bones, Bone)
end

function Class:m_CreateBoneTree(RootPart: BasePart, RootBone: Bone)
	local Settings = Utilities.GatherObjectSettings(RootPart)
	local BoneTree = BoneTreeClass.new(RootBone, RootPart, Settings.Gravity)

	BoneTree.Settings = Settings

	local function AddChildren(Bone, ParentIndex, HeirarchyLength)
		local Children = Bone:GetChildren()

		for _, Child in Children do
			if Child:IsA("Bone") then
				self:m_AppendBone(BoneTree, Child, ParentIndex, HeirarchyLength)

				AddChildren(Child, #BoneTree.Bones, HeirarchyLength + 1)
			end
		end

		if #Children == 0 then -- Add tail bone for transform calculations
			local Start = Bone.WorldCFrame + (Bone.WorldCFrame.UpVector.Unit * (Bone.WorldPosition - Bone.Parent.WorldPosition).Magnitude)
			local tailBone = Instance.new("Bone")
			tailBone.Parent = Bone
			tailBone.Name = Bone.Name .. "_Tail"
			tailBone.WorldCFrame = Start

			CopyPasteAttributes(Bone, tailBone)

			self:m_AppendBone(BoneTree, tailBone, #BoneTree.Bones, HeirarchyLength)
		end
	end

	self:m_AppendBone(BoneTree, RootBone, 0, 0)

	AddChildren(RootBone, 1, 1)

	table.insert(self.BoneTrees, BoneTree)
end

function Class:m_UpdateViewFrustum()
	debug.profilebegin("BonePhysics::m_UpdateViewFrustum")
	local a, b, c, d, e, f, g, h, i = Frustum.GetCFrames(workspace.CurrentCamera, 500) -- Hard coded 500 stud limit on any object

	for _, BoneTree in self.BoneTrees do
		debug.profilebegin("BoneTree::m_UpdateViewFrustum")
		BoneTree.InView = Frustum.ObjectInFrustum(BoneTree.RootPart, a, b, c, d, e, f, g, h, i)
		debug.profileend()
	end
	debug.profileend()
end

function Class:m_UpdateBoneTree(BoneTree, Delta)
	debug.profilebegin("BonePhysics::m_UpdateBoneTree")
	BoneTree:PreUpdate()

	if not BoneTree.InView then
		BoneTree:SkipUpdate()
		return
	end

	if BoneTree.UpdateRate == 0 then
		BoneTree:SkipUpdate()
		return
	end

	local UpdateHz = 1 / BoneTree.UpdateRate
	local DidUpdate = false

	BoneTree.AccumulatedDelta += Delta
	while BoneTree.AccumulatedDelta > 0 do
		BoneTree.AccumulatedDelta -= UpdateHz

		DidUpdate = true

		BoneTree:PreUpdate()
		BoneTree:StepPhysics(UpdateHz)
		BoneTree:Constrain(self.ColliderObjects, UpdateHz)
		BoneTree:SolveTransform(UpdateHz)
	end
	debug.profileend()

	if DidUpdate then
		task.synchronize()
		BoneTree:ApplyTransform()
	end
end

-- Public Functions

function Class:LoadObject(Object: BasePart)
	local RootAttribute = Object:GetAttribute("Roots")

	if not RootAttribute then
		warn(`[BonePhysics::LoadObject] Cannot load an object with no roots defined {Object.Name}`)
		return
	end

	local RootNames = RootAttribute:split(",")

	for _, Name in RootNames do
		local RootBone = Object:FindFirstChild(Name)
		if not RootBone then
			warn(`[BonePhysics::LoadObject] Couldn't find Root Bone of name: {Name}`)
			continue
		end

		self:m_CreateBoneTree(Object, RootBone)
	end
end

function Class:LoadColliderModule(ColliderModule: ModuleScript, Object: BasePart)
	local RawColliderData = require(ColliderModule)
	local ColliderData = HttpService:JSONDecode(RawColliderData)

	local ColliderObject = ColliderObjectClass.new(ColliderData, Object)

	table.insert(self.ColliderObjects, ColliderObject)
end

function Class:LoadRawCollider(ColliderData: {}, Object: BasePart)
	local ColliderObject = ColliderObjectClass.new(ColliderData, Object)

	table.insert(self.ColliderObjects, ColliderObject)
end

function Class:SkipUpdate()
	debug.profilebegin("BonePhysics::SkipUpdate")
	for _, BoneTree in self.BoneTrees do
		BoneTree:SkipUpdate()
	end
	debug.profileend()
end

function Class:StepBoneTrees(Delta)
	task.desynchronize()
	self:m_UpdateViewFrustum()
	for _, BoneTree in self.BoneTrees do
		self:m_UpdateBoneTree(BoneTree, Delta)
	end
	task.synchronize()
end

function Class:UpdateBoneTrees()
	-- self:m_ApplyTransform()
end

function Class:DrawDebug(DRAW_COLLIDERS, DRAW_CONTACTS, DRAW_PHYSICAL_BONE, DRAW_BONE, DRAW_AXIS_LIMITS)
	for _, BoneTree in self.BoneTrees do
		BoneTree:DrawDebug(DRAW_COLLIDERS, DRAW_CONTACTS, DRAW_PHYSICAL_BONE, DRAW_BONE, DRAW_AXIS_LIMITS)
	end

	if DRAW_COLLIDERS then
		for _, ColliderObject in self.ColliderObjects do
			ColliderObject:DrawDebug()
		end
	end
end

function Class.Start()
	if not RunService:IsClient() then
		warn("Smartbone.Start() can only be called in client context.")
		return
	end

	if Class.Running then
		warn("Cannot call Smartbone.Start() multiple times")
		return
	end

	Class.Running = true

	local Player = Players.LocalPlayer
	local PlayerScripts = Player:WaitForChild("PlayerScripts")

	local ActorFolder = Instance.new("Folder")
	ActorFolder.Name = "SmartBone-Actors"
	ActorFolder.Parent = PlayerScripts

	local function GatherColliders()
		local ColliderObjects = {
			Key = {},
			Raw = {},
		}

		for _, Object in CollectionService:GetTagged("SmartCollider") do
			if not Object:IsA("BasePart") then
				continue
			end

			local ColliderKey = Object:GetAttribute("ColliderKey")

			if ColliderKey then
				ColliderKey = tostring(ColliderKey)

				if not ColliderObjects.Key[ColliderKey] then
					ColliderObjects.Key[ColliderKey] = {}
				end

				table.insert(ColliderObjects.Key[ColliderKey], Object)
			end

			table.insert(ColliderObjects.Raw, Object)
		end

		return ColliderObjects
	end

	local function GetCollider(Object: BasePart)
		-- Any shapes which arent defined in the translation table are defaulted to box

		local ColliderModule = Object:FindFirstChild("self.Collider")
		local ColliderDescription

		if ColliderModule then
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

		local ColliderType = ColliderTranslations[Object.Shape.Name] or "Box"

		ColliderDescription = {
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
		}

		return ColliderDescription
	end

	local function SetupObject(Object: BasePart)
		if not Object:IsA("BasePart") then
			return
		end

		local GlobalColliders = GatherColliders()
		local ColliderKey = Object:GetAttribute("ColliderKey")

		local ColliderObjects = ColliderKey and GlobalColliders.Key[tostring(ColliderKey)] or GlobalColliders.Raw
		local ColliderDescriptions = {} -- {Description, Object}

		for _, ColliderObject in ColliderObjects do
			table.insert(ColliderDescriptions, { GetCollider(ColliderObject), ColliderObject })
		end

		local Actor = Instance.new("Actor")
		local Runtime = ActorRuntime:Clone()

		Runtime.Parent = Actor
		Runtime.Enabled = true

		Actor.Parent = ActorFolder

		Actor:SendMessage("Setup", Object, ColliderDescriptions, script)
	end

	CollectionService:GetInstanceAddedSignal("SmartBone"):Connect(SetupObject)

	for _, Object in CollectionService:GetTagged("SmartBone") do
		SetupObject(Object)
	end
end

return Class
