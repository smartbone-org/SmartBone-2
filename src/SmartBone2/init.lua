--!nocheck

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
	Capsule = "Capsule",
	Sphere = "Sphere",
	Box = "Box",
	Cylinder = "Cylinder",
}

local function CopyPasteAttributes(Object1: BasePart, Object2: BasePart)
	for k, v in Object1:GetAttributes() do
		Object2:SetAttribute(k, v)
	end
end

local SB_INDENT_LOG = Utilities.SB_INDENT_LOG
local SB_UNINDENT_LOG = Utilities.SB_UNINDENT_LOG
local SB_ASSERT_CB = Utilities.SB_ASSERT_CB
local SB_VERBOSE_LOG = Utilities.SB_VERBOSE_LOG
local SB_VERBOSE_WARN = Utilities.SB_VERBOSE_WARN
local SB_VERBOSE_ERROR = Utilities.SB_VERBOSE_ERROR

--- @class SmartBone
--- Root for all SmartBone objects.

--- @within SmartBone
--- @readonly
--- @prop ID string
--- Unique ID of the root object

--- @within SmartBone
--- @prop BoneTrees table
--- Table of all bone trees under this root

--- @within SmartBone
--- @prop ColliderObjects table
--- Table of all colliders assigned to this root

--- @within SmartBone
--- @prop ShouldDestroy boolean
--- True if the root has no bonetrees, this is already handled by the runtime

local Class = {}
Class.__index = Class

--- @within SmartBone
--- @return SmartBone
function Class.new()
	local self = setmetatable({
		ID = HttpService:GenerateGUID(false),
		BoneTrees = {},
		ColliderObjects = {},
		ShouldDestroy = false,
	}, Class)

	return self
end

-- Private Functions

--- @private
--- @within SmartBone
--- @param BoneTree table
--- @param BoneObject Bone
--- @param ParentIndex number
--- @param HeirarchyLength number
--- :::caution Caution:
--- Private Functions can change syntax at any time without warning. Only use these if you're prepared to fix any issues that arise.
--- :::
--- Used to add a bone to the provided bone tree
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
		SB_VERBOSE_LOG("Anchoring bone")
		Bone.Anchored = true
	end

	Bone.ParentIndex = ParentIndex

	table.insert(BoneTree.Bones, Bone)
end

--- @private
--- @within SmartBone
--- @param RootPart BasePart
--- @param RootBone Bone
--- :::caution Caution:
--- Private Functions can change syntax at any time without warning. Only use these if you're prepared to fix any issues that arise.
--- :::
--- Creates a bone tree from the RootPart and RootBone and then adds all child bones via m_AppendBone
function Class:m_CreateBoneTree(RootPart: BasePart, RootBone: Bone)
	local Settings = Utilities.GatherObjectSettings(RootPart)
	local BoneTree = BoneTreeClass.new(RootBone, RootPart, Settings.Gravity)

	BoneTree.Settings = Settings

	SB_VERBOSE_LOG(`Creating bone tree {RootPart.Name}; {RootBone.Name}`)
	SB_INDENT_LOG()

	local function AddChildren(Bone, ParentIndex, HeirarchyLength)
		SB_VERBOSE_LOG(`Adding bone: {Bone.Name}; {ParentIndex}; {HeirarchyLength}`)
		SB_INDENT_LOG()
		local Children = Bone:GetChildren()

		for _, Child in Children do
			if Child:IsA("Bone") then
				self:m_AppendBone(BoneTree, Child, ParentIndex, HeirarchyLength)

				AddChildren(Child, #BoneTree.Bones, HeirarchyLength + 1)
			end
		end

		if #Children == 0 then -- Add tail bone for transform calculations
			SB_VERBOSE_LOG(`Adding tail bone`)
			local Parent = Bone.Parent
			local ParentWorldPosition = Parent:IsA("Bone") and Parent.WorldPosition or Parent.Position

			local Start = Bone.WorldCFrame + (Bone.WorldCFrame.UpVector.Unit * (Bone.WorldPosition - ParentWorldPosition).Magnitude)
			local tailBone = Instance.new("Bone")
			tailBone.Parent = Bone
			tailBone.Name = Bone.Name .. "_Tail"
			tailBone.WorldCFrame = Start

			CopyPasteAttributes(Bone, tailBone)

			self:m_AppendBone(BoneTree, tailBone, #BoneTree.Bones, HeirarchyLength)
		end

		SB_UNINDENT_LOG()
	end

	self:m_AppendBone(BoneTree, RootBone, 0, 0)

	AddChildren(RootBone, 1, 1)

	table.insert(self.BoneTrees, BoneTree)

	SB_UNINDENT_LOG()
end

--- @private
--- @within SmartBone
--- :::caution Caution:
--- Private Functions can change syntax at any time without warning. Only use these if you're prepared to fix any issues that arise.
--- :::
--- Updates the view frustum used for optimization
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

function Class:m_CleanColliders()
	debug.profilebegin("Clean Colliders")
	if #self.ColliderObjects ~= 0 then -- Micro optomizations
		for i, ColliderObject in self.ColliderObjects do
			if #ColliderObject.Colliders == 0 or ColliderObject.Destroyed == true then
				SB_VERBOSE_WARN(`Deleting Collider Object`)
				SB_INDENT_LOG()
				ColliderObject:Destroy()
				SB_UNINDENT_LOG()
				table.remove(self.ColliderObjects, i)
			end
		end
	end
	debug.profileend()
end

--- @private
--- @within SmartBone
--- @param BoneTree table
--- @param Delta number
--- :::caution Caution:
--- Private Functions can change syntax at any time without warning. Only use these if you're prepared to fix any issues that arise.
--- :::
--- Constrains each bone in the provided bone tree and cleans up colliders
function Class:m_ConstrainBoneTree(BoneTree: BoneTreeClass.IBoneTree, Delta: number)
	debug.profilebegin("BonePhysics::m_ConstrainBoneTree")

	BoneTree:Constrain(self.ColliderObjects, Delta)

	debug.profileend()
end

--- @private
--- @within SmartBone
--- @param BoneTree table
--- @param Index number
--- @param Delta number
--- :::caution Caution:
--- Private Functions can change syntax at any time without warning. Only use these if you're prepared to fix any issues that arise.
--- :::
--- Updates the provided bone tree with all optomizations
function Class:m_UpdateBoneTree(BoneTree, Index, Delta)
	debug.profilebegin("BonePhysics::m_UpdateBoneTree")

	if BoneTree.Destroyed then
		BoneTree:Destroy()
		table.remove(self.BoneTrees, Index)
		return
	end

	BoneTree:PreUpdate()

	if not BoneTree.InView or BoneTree.UpdateRate == 0 then
		task.synchronize()
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
		self:m_ConstrainBoneTree(BoneTree, Delta)
		BoneTree:SolveTransform(UpdateHz)
	end
	debug.profileend()

	if DidUpdate then
		task.synchronize()
		BoneTree:ApplyTransform()
	end
end

--- @private
--- @within SmartBone
--- @return boolean
--- :::caution Caution:
--- Private Functions can change syntax at any time without warning. Only use these if you're prepared to fix any issues that arise.
--- :::
--- Returns true if the root should be destroyed
function Class:m_CheckDestroy()
	self.ShouldDestroy = false

	if #self.BoneTrees == 0 then
		self.ShouldDestroy = true
		return true
	end

	return false
end

-- Public Functions

--- @within SmartBone
--- @param Object BasePart
--- Loads the provided object
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
			warn(`[BonePhysics::LoadObject] Couldn't find Root Bone of name: {Name} in RootPart: {Object.Name}`)
			continue
		end

		self:m_CreateBoneTree(Object, RootBone)
	end
end

--- @within SmartBone
--- @param ColliderModule ModuleScript
--- @param Object BasePart
--- Loads the provided collider module onto the provided object
function Class:LoadColliderModule(ColliderModule: ModuleScript, Object: BasePart)
	assert(ColliderModule, "[BonePhysics::LoadColliderModule] No collider module passed in")

	local RawColliderData = require(ColliderModule)
	local ColliderData = HttpService:JSONDecode(RawColliderData)

	local ColliderObject = ColliderObjectClass.new(ColliderData, Object)

	table.insert(self.ColliderObjects, ColliderObject)
end

--- @within SmartBone
--- @param ColliderData table
--- @param Object BasePart
--- Loads the raw collider data onto the provided object
function Class:LoadRawCollider(ColliderData: {}, Object: BasePart)
	local ColliderObject = ColliderObjectClass.new(ColliderData, Object)

	table.insert(self.ColliderObjects, ColliderObject)
end

--- @within SmartBone
--- Resets all bone trees to their rest position
function Class:SkipUpdate()
	debug.profilebegin("BonePhysics::SkipUpdate")
	for _, BoneTree in self.BoneTrees do
		BoneTree:SkipUpdate()
	end
	debug.profileend()
end

--- @within SmartBone
--- @param Delta number
--- Updates all bone trees
function Class:StepBoneTrees(Delta)
	if self:m_CheckDestroy() then
		return
	end

	self:m_CleanColliders()

	task.desynchronize()
	self:m_UpdateViewFrustum()
	for i, BoneTree in self.BoneTrees do
		self:m_UpdateBoneTree(BoneTree, i, Delta)
	end
	task.synchronize()
end

--- @client
--- @within SmartBone
--- @param DRAW_COLLIDERS boolean
--- @param DRAW_CONTACTS boolean
--- @param DRAW_PHYSICAL_BONE boolean
--- @param DRAW_BONE boolean
--- @param DRAW_AXIS_LIMITS boolean
--- @param DRAW_ROOT_PART boolean
--- @param DRAW_FILL_COLLIDERS boolean
--- Draws the debug gizmos
function Class:DrawDebug(DRAW_COLLIDERS, DRAW_CONTACTS, DRAW_PHYSICAL_BONE, DRAW_BONE, DRAW_AXIS_LIMITS, DRAW_ROOT_PART, DRAW_FILL_COLLIDERS)
	for _, BoneTree in self.BoneTrees do
		BoneTree:DrawDebug(DRAW_CONTACTS, DRAW_PHYSICAL_BONE, DRAW_BONE, DRAW_AXIS_LIMITS, DRAW_ROOT_PART)
	end

	if DRAW_COLLIDERS then
		for _, ColliderObject in self.ColliderObjects do
			ColliderObject:DrawDebug(DRAW_FILL_COLLIDERS)
		end
	end
end

--- @within SmartBone
--- Destroys the root and all its children
function Class:Destroy()
	for _, BoneTree in self.BoneTrees do
		BoneTree:Destroy()
	end

	for _, ColliderObject in self.ColliderObjects do
		ColliderObject:Destroy()
	end

	setmetatable(self, nil)
end

--- @client
--- @within SmartBone
--- Collects all SmartBone objects and SmartBone colliders and starts running physics + collision on them
function Class.Start()
	if not RunService:IsClient() then
		warn("Smartbone.Start() can only be called in client context.")
		return
	end

	if Class.Running then
		warn("Cannot call Smartbone.Start() multiple times")
		return
	end

	SB_VERBOSE_LOG(".Start()")

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

			SB_VERBOSE_LOG(`Adding collider: {Object.Name}, Collider Key: {ColliderKey}`)
			table.insert(ColliderObjects.Raw, Object)
		end

		return ColliderObjects
	end

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

	local function SetupObject(Object: BasePart)
		if not Object:IsA("BasePart") then
			return
		end

		SB_VERBOSE_LOG(`Setup Object: {Object.Name}`)
		SB_INDENT_LOG()

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

		SB_VERBOSE_LOG(`Runtime Started`)
		SB_UNINDENT_LOG()
	end

	CollectionService:GetInstanceAddedSignal("SmartBone"):Connect(SetupObject)

	for _, Object in CollectionService:GetTagged("SmartBone") do
		SetupObject(Object)
	end
end

return Class
