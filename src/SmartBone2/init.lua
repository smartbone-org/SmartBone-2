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

local HttpService = game:GetService("HttpService")
local Components = script:WaitForChild("Components")
local Dependencies = script:WaitForChild("Dependencies")

local Utilities = require(Dependencies:WaitForChild("Utilities"))

local BoneClass = require(Components:WaitForChild("Bone"))
local BoneTreeClass = require(Components:WaitForChild("BoneTree"))
local ColliderObjectClass = require(Components:WaitForChild("Collision"):WaitForChild("ColliderObject"))

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
		Colliders = {},
		Connections = {},
		WindPreviousPosition = Vector3.zero,
		Removed = false,
		RemovedEvent = Instance.new("BindableEvent"),
		InRange = false,
	}, Class)

	return self
end

-- Private Functions

function Class:m_AppendBone(BoneTree: BoneTreeClass.IBoneTree, BoneObject: Bone, HeirarchyLength: number)
	local Settings = Utilities.GatherBoneSettings(BoneObject)
	local Bone: BoneClass.IBone = BoneClass.new(BoneObject, BoneTree.Root, BoneTree.RootPart)

	for k, v in Settings do
		Bone[k] = v
	end

	local ParentIndex = HeirarchyLength
	local ParentBone = BoneTree.Bones[ParentIndex]

	if HeirarchyLength > 0 then
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

	local function AddChildren(Bone, HeirarchyLength)
		local Children = Bone:GetChildren()

		for _, Child in Children do
			if Child:IsA("Bone") then
				self:m_AppendBone(BoneTree, Child, HeirarchyLength)

				AddChildren(Child, HeirarchyLength + 1)
			end
		end

		if #Children == 0 then -- Add tail bone for transform calculations
			local Start = Bone.WorldCFrame + (Bone.WorldCFrame.UpVector.Unit * (Bone.WorldPosition - Bone.Parent.WorldPosition).Magnitude)
			local tailBone = Instance.new("Bone")
			tailBone.Parent = Bone
			tailBone.Name = Bone.Name .. "_Tail"
			tailBone.WorldCFrame = Start

			CopyPasteAttributes(Bone, tailBone)

			self:m_AppendBone(BoneTree, tailBone, HeirarchyLength)
		end
	end

	self:m_AppendBone(BoneTree, RootBone, 0)

	AddChildren(RootBone, 1)

	table.insert(self.BoneTrees, BoneTree)
end

function Class:m_PreUpdate()
	debug.profilebegin("BonePhysics::m_PreUpdate")
	for _, BoneTree in self.BoneTrees do
		BoneTree:PreUpdate()
	end
	debug.profileend()
end

function Class:m_StepPhysics(Delta: number)
	debug.profilebegin("BonePhysics::m_StepPhysics")
	for _, BoneTree in self.BoneTrees do
		BoneTree:StepPhysics(Delta)
	end
	debug.profileend()
end

function Class:m_Constrain(Delta: number)
	debug.profilebegin("BonePhysics::m_PreUpdate")
	for _, BoneTree in self.BoneTrees do
		BoneTree:Constrain(self.Colliders, Delta)
	end
	debug.profileend()
end

function Class:m_SolveTransform(Delta: number)
	debug.profilebegin("BonePhysics::m_PreUpdate")
	for _, BoneTree in self.BoneTrees do
		BoneTree:SolveTransform(Delta)
	end
	debug.profileend()
end

function Class:m_ApplyTransform()
	debug.profilebegin("BonePhysics::m_ApplyTransform")
	for _, BoneTree in self.BoneTrees do
		BoneTree:ApplyTransform()
	end
	debug.profileend()
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
			print("no root bone name", Name)
			continue
		end

		self:m_CreateBoneTree(Object, RootBone)
	end
end

function Class:LoadCollider(ColliderModule: ModuleScript, Object: BasePart)
	local RawColliderData = require(ColliderModule)
	local ColliderData = HttpService:JSONDecode(RawColliderData)

	local Collider = ColliderObjectClass.new(ColliderData, Object)

	table.insert(self.Colliders, Collider)
end

function Class:UpdateBoneTrees(Delta)
	debug.profilebegin("BonePhysics::UpdateBoneTrees")
	self:m_PreUpdate()
	self:m_StepPhysics(Delta)
	self:m_Constrain(Delta)
	self:m_SolveTransform(Delta)
	self:m_ApplyTransform()
	debug.profileend()
end

function Class:DrawDebug(DRAW_COLLIDERS, DRAW_CONTACTS, DRAW_PHYSICAL_BONE, DRAW_BONE, DRAW_AXIS_LIMITS)
	for _, BoneTree in self.BoneTrees do
		BoneTree:DrawDebug(DRAW_COLLIDERS, DRAW_CONTACTS, DRAW_PHYSICAL_BONE, DRAW_BONE, DRAW_AXIS_LIMITS)
	end

	if DRAW_COLLIDERS then
		for _, Collider in self.Colliders do
			Collider:DrawDebug()
		end
	end
end

return Class
