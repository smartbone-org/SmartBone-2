--!nocheck

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Components = script:WaitForChild("Components")
local Dependencies = script:WaitForChild("Dependencies")

local CeiveImOverlay = require(Dependencies:WaitForChild("Debug"):WaitForChild("ImOverlay"))
local Config = require(script:WaitForChild("Config"))
local Frustum = require(Dependencies:WaitForChild("Frustum"))
local Utilities = require(Dependencies:WaitForChild("Utilities"))
local ImOverlay

local BoneClass = require(Components:WaitForChild("Bone"))
local BoneTreeClass = require(Components:WaitForChild("BoneTree"))
local ColliderObjectClass = require(Components:WaitForChild("Collision"):WaitForChild("ColliderObject"))

local ActorRuntime = Dependencies:WaitForChild("Runtime")

local function CopyPasteAttributes(Object1: BasePart, Object2: BasePart)
	for k, v in Object1:GetAttributes() do
		Object2:SetAttribute(k, v)
	end
end

export type IBoneTree = BoneTreeClass.IBoneTree
export type IBone = BoneClass.IBone
export type IColliderObject = ColliderObjectClass.IColliderObject
export type IColliderTable = ColliderObjectClass.IColliderTable

type ImOverlay = {
	Begin: (Text: string, BackgroundColor: Color3?, TextColor: Color3?) -> (),
	End: () -> (),
	Text: (Text: string, BackgroundColor: Color3?, TextColor: Color3?) -> ()
}

type bool = boolean

local SB_INDENT_LOG = Utilities.SB_INDENT_LOG
local SB_UNINDENT_LOG = Utilities.SB_UNINDENT_LOG
-- local SB_ASSERT_CB = Utilities.SB_ASSERT_CB
local SB_VERBOSE_LOG = Utilities.SB_VERBOSE_LOG
local SB_VERBOSE_WARN = Utilities.SB_VERBOSE_WARN
-- local SB_VERBOSE_ERROR = Utilities.SB_VERBOSE_ERROR

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

		m_SteppedColliders = false,
		m_FrustumObject = { CFrame = CFrame.identity, Size = Vector3.zero },
		m_PendingApply = {},
		m_PendingDestroy = {},
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
function Class:m_AppendBone(BoneTree: IBoneTree, BoneObject: Bone, ParentIndex: number, HeirarchyLength: number)
	local Settings = Utilities.GatherBoneSettings(BoneObject)
	local Bone: IBone = BoneClass.new(BoneObject, BoneTree.Root, BoneTree.RootPart)

	for k, v in Settings do
		-- "¬" represents a nil value, this is done so we can delete attributes at runtime.
		Bone[k] = (v ~= "¬") and v or nil
	end

	local ParentBone = BoneTree.Bones[ParentIndex]

	if ParentIndex > 0 then
		local BoneLength = (ParentBone.Position - Bone.Position).Magnitude
		Bone.FreeLength = BoneLength
		Bone.Weight = BoneLength * 0.7 -- Why 0.7?
		Bone.HeirarchyLength = HeirarchyLength

		ParentBone.HasChild = true
		--ParentBone.NumberOfChildren += 1
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
	local BoneTree = BoneTreeClass.new(RootBone, RootPart, Utilities.GatherObjectSettings(RootPart))

	SB_VERBOSE_LOG(`Creating bone tree {RootPart.Name}; {RootBone.Name}`)
	SB_INDENT_LOG()

	local function AddChildren(Bone, ParentIndex, HeirarchyLength)
		SB_VERBOSE_LOG(`Adding bone: {Bone.Name}; {ParentIndex}; {HeirarchyLength}`)
		SB_INDENT_LOG()
		local Children = Bone:GetChildren()
		local HasBoneChild = false

		for _, Child in Children do
			if Child:IsA("Bone") then
				self:m_AppendBone(BoneTree, Child, ParentIndex, HeirarchyLength)

				AddChildren(Child, #BoneTree.Bones, HeirarchyLength + 1)
				HasBoneChild = true
			end
		end

		if string.sub(Bone.Name, #Bone.Name - 3, #Bone.Name) == "_end" or string.sub(Bone.Name, #Bone.Name - 4, #Bone.Name) == "_Tail" then
			HasBoneChild = true
		end

		if not HasBoneChild then -- Add tail bone for transform calculations
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
	-- Should we do frustum checks this frame, depends on config setting
	if shared.FrameCounter % Config.FRUSTUM_FREQ ~= 0 then
		return
	end
do end	

local a, b, c, d, e, f, g, h, i = Frustum.GetCFrames(workspace.CurrentCamera, Config.FAR_PLANE) -- Hard coded stud limit on any object

	local FrustumObject = self.m_FrustumObject

	for _, BoneTree in self.BoneTrees do
do end		
FrustumObject.CFrame = BoneTree.BoundingBoxCFrame
		FrustumObject.Size = BoneTree.BoundingBoxSize

		BoneTree.InView = Frustum.ObjectInFrustum(FrustumObject, a, b, c, d, e, f, g, h, i)
do end	
end
do end
end

--- @private
--- @within SmartBone
--- :::caution Caution:
--- Private Functions can change syntax at any time without warning. Only use these if you're prepared to fix any issues that arise.
--- :::
--- Detaches dead colliders and bone trees from the live lists. Parallel safe, the detached
--- objects are torn down later by m_FlushPending once we are back in serial.
function Class:m_DetachDead()
do end	
local Pending = self.m_PendingDestroy

	for i = #self.ColliderObjects, 1, -1 do
		local ColliderObject = self.ColliderObjects[i]

		if #ColliderObject.Colliders == 0 or ColliderObject.Destroyed == true then
			table.insert(Pending, ColliderObject)
			table.remove(self.ColliderObjects, i)
		end
	end

	for i = #self.BoneTrees, 1, -1 do
		local BoneTree = self.BoneTrees[i]

		if BoneTree.Destroyed then
			table.insert(Pending, BoneTree)
			table.remove(self.BoneTrees, i)
		end
	end
do end
end

--- @private
--- @within SmartBone
--- :::caution Caution:
--- Private Functions can change syntax at any time without warning. Only use these if you're prepared to fix any issues that arise.
--- :::
--- Destroys everything m_DetachDead pulled out. MUST be called from serial context.
function Class:m_FlushPending()
	local Pending = self.m_PendingDestroy

	if #Pending == 0 then
		return
	end
do end	

for _, Object in Pending do
		Object:Destroy()
	end

	table.clear(Pending)
do end
end

--- @private
--- @within SmartBone
--- :::caution Caution:
--- Private Functions can change syntax at any time without warning. Only use these if you're prepared to fix any issues that arise.
--- :::
--- Steps every collider once per frame, no matter how many bone trees consume them
function Class:m_StepColliders()
	if self.m_SteppedColliders then
		return
	end

	self.m_SteppedColliders = true
do end	

for _, ColliderObject in self.ColliderObjects do
		ColliderObject:Step()
	end
do end
end

--- @private
--- @within SmartBone
--- @param BoneTree table
--- @param Delta number
--- @return boolean -- True if the tree needs its transform applied in the serial phase
--- :::caution Caution:
--- Private Functions can change syntax at any time without warning. Only use these if you're prepared to fix any issues that arise.
--- :::
--- Runs the parallel half of a bone tree update. Applying the result is deferred to StepBoneTrees.
function Class:m_UpdateBoneTree(BoneTree: IBoneTree, Delta: number): boolean
do end
	
BoneTree:PreUpdate(Delta) -- Pre update MUST be called before we call SkipUpdate!

	if not BoneTree.InView or math.floor(BoneTree.UpdateRate) == 0 or not BoneTree.InWorkspace then
		local AlreadySkipped = BoneTree.IsSkippingUpdates

		BoneTree:SkipUpdate()
do end
		
if not AlreadySkipped then
			SB_VERBOSE_LOG(
				`Skipping BoneTree, InView: {BoneTree.InView}, Update Rate == 0: {math.floor(BoneTree.UpdateRate) == 0}, InWorkspace: {BoneTree.InWorkspace}`
			)

			return true
		end

		return false
	end

	self:m_StepColliders()

	local UpdateHz = 1 / BoneTree.UpdateRate
	local DidUpdate = false
	local Steps = 0

	BoneTree.AccumulatedDelta += Delta
	while BoneTree.AccumulatedDelta > UpdateHz and Steps < Config.MAX_SUBSTEPS do
		BoneTree.AccumulatedDelta -= UpdateHz
		Steps += 1

		DidUpdate = true

		BoneTree:StepPhysics(UpdateHz)
		BoneTree:Constrain(self.ColliderObjects, UpdateHz)
		BoneTree:SolveTransform(UpdateHz)
	end

	if BoneTree.AccumulatedDelta > UpdateHz then -- Hitched hard enough to exceed the substep budget, drop the backlog
		BoneTree.AccumulatedDelta = 0
	end
do end
	
return DidUpdate
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
		warn(`[SmartBone2::LoadObject] Cannot load an object with no roots defined {Object.Name}`)
		return
	end

	local RootNames = RootAttribute:split(",")
	local RootBonesNotLoaded = {}
	local Bones = {}

	-- Gather pre-recorded bones into table
	for _, Name in RootNames do
		RootBonesNotLoaded[Name] = true
	end

	-- Gather bones into table indexed with name
	for _, Descendant in Object:QueryDescendants("Bone") do
		if Bones[Descendant.Name] then
			warn(`[SmartBone2::LoadObject] Duplicate bones of name: {Descendant.Name} in RootPart: {Object.Name}`)
			continue
		end

		RootBonesNotLoaded[Descendant.Name] = nil
		Bones[Descendant.Name] = Descendant
	end

	-- Check for any missing bones
	if next(RootBonesNotLoaded) then
		for Name, _ in RootBonesNotLoaded do
			local Bone = Object:WaitForChild(Name, Config.ROOT_BONE_WAIT_TIME or 5)
			if Bone and Bone:IsA("Bone") then
				RootBonesNotLoaded[Bone.Name] = nil
				Bones[Bone.Name] = Bone
			end
		end

		if next(RootBonesNotLoaded) then
			warn(`[SmartBone2::LoadObject] Couldn't find all roots defined {Object.Name}`)
		end
	end

	-- Create bone trees
	for _, Name in RootNames do
		local RootBone = Bones[Name]
		if not RootBone then
			warn(`[SmartBone2::LoadObject] Couldn't find Root Bone of name: {Name} in RootPart: {Object.Name}`)
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
	assert(ColliderModule, "[SmartBone2::LoadColliderModule] No collider module passed in")

	local RawColliderData = require(ColliderModule)
	local ColliderData = HttpService:JSONDecode(RawColliderData)

	local ColliderObject = ColliderObjectClass.new(ColliderData, Object)

	table.insert(self.ColliderObjects, ColliderObject)
end

--- @within SmartBone
--- @param ColliderData table
--- @param Object BasePart
--- Loads the raw collider data onto the provided object
function Class:LoadRawCollider(ColliderData: IColliderTable, Object: BasePart)
	local ColliderObject = ColliderObjectClass.new(ColliderData, Object)

	table.insert(self.ColliderObjects, ColliderObject)
end

--- @within SmartBone
--- Resets all bone trees to their rest position
function Class:SkipUpdate()
do end	
for _, BoneTree in self.BoneTrees do
		BoneTree:SkipUpdate()
	end
do end
end

--- @within SmartBone
--- @param Delta number
--- Updates all bone trees
--- @within SmartBone
--- @param Delta number
--- @return boolean -- True if ApplyPending has work to do
--- Runs every parallel safe stage of the update. Callers hosting several roots should run this for
--- all of them before synchronizing once and calling ApplyPending on each.
function Class:StepParallel(Delta: number): boolean
	if self:m_CheckDestroy() then
		return false
	end

	if Delta <= 0 then
		SB_VERBOSE_WARN("DeltaTime is zero or sub zero, not updating.")
		return false
	end

	self.m_SteppedColliders = false

	local PendingApply = self.m_PendingApply
	table.clear(PendingApply)

	self:m_DetachDead()
	self:m_UpdateViewFrustum()

	for _, BoneTree in self.BoneTrees do
		if self:m_UpdateBoneTree(BoneTree, Delta) then
			table.insert(PendingApply, BoneTree)
		end
	end

	return #PendingApply > 0 or #self.m_PendingDestroy > 0
end

--- @within SmartBone
--- Writes everything StepParallel solved back onto the bones. Must be called from serial context.
function Class:ApplyPending()
	local PendingApply = self.m_PendingApply

	if #PendingApply ~= 0 then
do end		
for _, BoneTree in PendingApply do
			BoneTree:ApplyTransform()
		end
do end
		
table.clear(PendingApply)
	end

	self:m_FlushPending()
end

--- @within SmartBone
--- @param Delta number
--- Updates all bone trees. Convenience wrapper for a single root, synchronizes internally.
function Class:StepBoneTrees(Delta: number)
	if not self:StepParallel(Delta) then
		return
	end

	task.synchronize()
	self:ApplyPending()
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
--- @param DRAW_COLLIDER_INFLUENCE boolean
--- @param DRAW_COLLIDER_AWAKE boolean
--- @param DRAW_COLLIDER_BROADPHASE boolean
--- @param DRAW_BOUNDING_BOX boolean
--- @param DRAW_ROTATION_LIMITS boolean
--- @param DRAW_ACCELERATION_INFO boolean
--- Draws the debug gizmos
function Class:DrawDebug(
	DRAW_COLLIDERS: bool,
	DRAW_CONTACTS: bool,
	DRAW_PHYSICAL_BONE: bool,
	DRAW_BONE: bool,
	DRAW_AXIS_LIMITS: bool,
	DRAW_ROOT_PART: bool,
	DRAW_FILL_COLLIDERS: bool,
	DRAW_COLLIDER_INFLUENCE: bool,
	DRAW_COLLIDER_AWAKE: bool,
	DRAW_COLLIDER_BROADPHASE: bool,
	DRAW_BOUNDING_BOX: bool,
	DRAW_ROTATION_LIMITS: bool,
	DRAW_ACCELERATION_INFO: bool
)
	for _, BoneTree in self.BoneTrees do
		BoneTree:DrawDebug(
			DRAW_CONTACTS,
			DRAW_PHYSICAL_BONE,
			DRAW_BONE,
			DRAW_AXIS_LIMITS,
			DRAW_ROOT_PART,
			DRAW_BOUNDING_BOX,
			DRAW_ROTATION_LIMITS,
			DRAW_ACCELERATION_INFO
		)
	end

	if DRAW_COLLIDERS then
		for _, ColliderObject in self.ColliderObjects do
			ColliderObject:DrawDebug(DRAW_FILL_COLLIDERS, DRAW_COLLIDER_INFLUENCE, DRAW_COLLIDER_AWAKE, DRAW_COLLIDER_BROADPHASE)
		end
	end
end

--- @client
--- @within SmartBone
--- @param Overlay ImOverlay
--- Draws the debug overlay
function Class:DrawOverlay(Overlay: ImOverlay)
	if not Config.DEBUG_OVERLAY_ENABLED then
		return
	end

	local INSTANCE_BACKGROUND_COLOR = Color3.new(1.000000, 0.431373, 0.713725)
	local INSTANCE_TEXT_COLOR = Color3.new(1, 1, 1)
	local ROOT_BACKGROUND_COLOR = Color3.new(0.486275, 0.431373, 1.000000)
	local ROOT_TEXT_COLOR = Color3.new(1, 1, 1)

	Overlay.Begin(`SmartBone Instance ID: {self.ID}`, INSTANCE_BACKGROUND_COLOR, INSTANCE_TEXT_COLOR)
	Overlay.Text(`Frame Counter: {shared.FrameCounter}`)

	if Config.DEBUG_OVERLAY_TREE then
		for i, BoneTree in self.BoneTrees do
			if Config.DEBUG_OVERLAY_MAX_TREES > 0 then
				if Config.DEBUG_OVERLAY_TREE_OFFSET + Config.DEBUG_OVERLAY_MAX_TREES <= i then
					break
				end
			end

			if Config.DEBUG_OVERLAY_TREE_OFFSET > i then
				continue
			end

			Overlay.Begin(`Bone Tree {i}`, ROOT_BACKGROUND_COLOR, ROOT_TEXT_COLOR)
			BoneTree:DrawOverlay(Overlay)
			Overlay.End()
		end
	end

	Overlay.End()
end

--- @within SmartBone
--- Destroys the root and all its children. Must be called from serial context.
function Class:Destroy()
	SB_VERBOSE_LOG("Deleting SmartBone Object")

	self:m_FlushPending()

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
--- @return {Stop: () -> ()}
--- Collects all SmartBone objects and SmartBone colliders and starts running physics + collision on them
function Class.Start(): { Stop: () -> () }
	if not RunService:IsClient() then
		warn("Smartbone.Start() can only be called in client context.")
		return
	end

	if Class.Running then
		warn("Cannot call Smartbone.Start() multiple times")
		return
	end

	if Config.STARTUP_PRINT_ENABLED or Config.LOG_VERBOSE then
		print(`SmartBone2 v{Config.VERSION} Starting`)
	end

	Class.Running = true

	local Player = Players.LocalPlayer
	local PlayerScripts = Player:WaitForChild("PlayerScripts")

	local ActorFolder = Instance.new("Folder")
	ActorFolder.Name = "SmartBone-Actors"
	ActorFolder.Parent = PlayerScripts

	local OverlayEvent = Instance.new("BindableEvent")
	OverlayEvent.Name = "OverlayEvent"
	OverlayEvent.Parent = script

	OverlayEvent.Event:Connect(function(Type, ...)
		if not Config.DEBUG_OVERLAY_ENABLED then
			return
		end

		if Type == "Text" then
			ImOverlay:Text(...)
		elseif Type == "Begin" then
			ImOverlay:Begin(...)
		elseif Type == "End" then
			ImOverlay:End()
		end
	end)

	local ObjectToWorker: { [BasePart]: Actor } = {}
	local Workers: { Actor } = {}
	local WorkerLoad: { [Actor]: number } = {}
	local WorkerReady: { [Actor]: boolean } = {}

	local function CreateWorker(): Actor
		local Worker = Instance.new("Actor")
		local Runtime = ActorRuntime:Clone()

		Runtime.Parent = Worker
		Runtime.Enabled = true

		Worker.Name = `SmartBone Worker {#Workers + 1}`

		-- Registered before yielding so a concurrent SetupObject sees the updated worker count
		table.insert(Workers, Worker)
		WorkerLoad[Worker] = 0
		WorkerReady[Worker] = false

		Worker.Parent = ActorFolder

		-- The runtime needs a frame to bind its handlers or it misses the first message
		task.wait()

		WorkerReady[Worker] = true

		return Worker
	end

	local function GetWorker(): Actor
		local MaxActors = Config.MAX_ACTORS

		if MaxActors <= 0 or #Workers < MaxActors then
			return CreateWorker()
		end

		local Best = Workers[1]

		for _, Worker in Workers do
			if WorkerLoad[Worker] < WorkerLoad[Best] then
				Best = Worker
			end
		end

		while not WorkerReady[Best] do
			task.wait()
		end

		return Best
	end

	-- Called when an object is "freed", the worker hosting it drops that root but stays alive
	local function OnObjectFreed(Object: BasePart)
		local Worker = ObjectToWorker[Object]
		ObjectToWorker[Object] = nil

		if not Worker then
			return
		end

		WorkerLoad[Worker] = math.max(WorkerLoad[Worker] - 1, 0)

		Worker:SendMessage("Free", Object)
	end

	local CachedColliders

	local function GatherColliders()
		if CachedColliders then
			return CachedColliders
		end

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

			if Config.YIELD_ON_COLLIDER_GATHER then
				task.wait()
			end
		end

		CachedColliders = ColliderObjects

		return ColliderObjects
	end

	local function InvalidateColliders()
		CachedColliders = nil
	end

	local ColliderAddedConnection = CollectionService:GetInstanceAddedSignal("SmartCollider"):Connect(InvalidateColliders)
	local ColliderRemovedConnection = CollectionService:GetInstanceRemovedSignal("SmartCollider"):Connect(InvalidateColliders)

	local function SetupObject(Object: BasePart)
		if not Object:IsA("BasePart") then
			return
		end

		SB_VERBOSE_LOG(`Setup Object: {Object.Name}`)
		SB_INDENT_LOG()

		local GlobalColliders = GatherColliders()
		local ColliderKey = Object:GetAttribute("ColliderKey")
		local ColliderObjects

		if ColliderKey then
			ColliderObjects = GlobalColliders.Key[tostring(ColliderKey)] or {}
		else
			ColliderObjects = GlobalColliders.Raw or {}
		end

		local ColliderDescriptions = {} -- {Description, Object}

		for _, ColliderObject in ColliderObjects do
			table.insert(ColliderDescriptions, { Utilities.GetCollider(ColliderObject), ColliderObject })
		end

		local Worker = GetWorker()

		ObjectToWorker[Object] = Worker
		WorkerLoad[Worker] += 1

		Worker:SendMessage("Setup", Object, ColliderDescriptions, script)

		-- Don't have to cleanup this connection since it's tied to the instance
		-- Here we handle freeing up the actor attached to the object when it's destroyed
		Object:GetPropertyChangedSignal("Parent"):Connect(function()
			if Object.Parent ~= nil then
				return
			end

			OnObjectFreed(Object)
		end)

		SB_VERBOSE_LOG(`Runtime Started`)
		SB_UNINDENT_LOG()
	end

	local TagAddedConnection = CollectionService:GetInstanceAddedSignal("SmartBone"):Connect(SetupObject)
	local TagRemovedConnection = CollectionService:GetInstanceRemovedSignal("SmartBone"):Connect(OnObjectFreed)

	for _, Object in CollectionService:GetTagged("SmartBone") do
		SetupObject(Object)
	end

	if Config.DEBUG_OVERLAY_ENABLED then
		ImOverlay = CeiveImOverlay.new()

		local PlayerGui = Players.LocalPlayer.PlayerGui

		local DebugGui = Instance.new("ScreenGui")
		DebugGui.Name = "SmartBoneDebugOverlay"
		DebugGui.IgnoreGuiInset = true
		DebugGui.ResetOnSpawn = false
		DebugGui.Parent = PlayerGui

		ImOverlay.BackFrame.Parent = DebugGui

		RunService.RenderStepped:Connect(function()
			ImOverlay:Render()
		end)
	end

	return {
		Stop = function()
			Class.Running = false

			if TagAddedConnection then
				TagAddedConnection:Disconnect()
			end

			if TagRemovedConnection then
				TagRemovedConnection:Disconnect()
			end

			ColliderAddedConnection:Disconnect()
			ColliderRemovedConnection:Disconnect()

			if not Config.RESET_BONE_ON_DESTROY then
				ActorFolder:Destroy()
				return
			end

			for _, Actor: Actor in ActorFolder:GetChildren() do
				Actor:SendMessage("Destroy")
			end
		end,
	}
end

return Class
