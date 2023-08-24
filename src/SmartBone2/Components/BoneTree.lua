--!nocheck

local WIND_SEED = 1029410295159813
local WIND_RNG = Random.new(WIND_SEED)
local Dependencies = script.Parent.Parent:WaitForChild("Dependencies")
local BoneClass = require(script.Parent:WaitForChild("Bone"))
local Gizmo = require(Dependencies:WaitForChild("Gizmo"))
Gizmo.Init()

export type IBoneTree = {
	WindOffset: number,
	Root: Bone,
	RootPart: BasePart,
	RootWorldToLocal: CFrame, -- Why does this exist?
	BoneTotalLength: number,
	DistanceFromCamera: number,
	Bones: { [number]: BoneClass.IBone },
	Settings: { [string]: any },

	LocalCFrame: CFrame,
	LocalGravity: Vector3,
	Force: Vector3,
	RestGravity: Vector3,
	ObjectMove: Vector3,
	ObjectPreviousPosition: Vector3,
}

local function SafeUnit(v3)
	if v3.Magnitude == 0 then
		return Vector3.zero
	end

	return v3.Unit
end

local Class = {}
Class.__index = Class

function Class.new(RootBone: Bone, RootPart: BasePart, Gravity: Vector3): IBoneTree
	return setmetatable({
		WindOffset = WIND_RNG:NextNumber(0, 1000000),
		Root = RootBone:IsA("Bone") and RootBone or nil,
		RootPart = RootPart,
		RootWorldToLocal = RootBone.WorldCFrame:ToObjectSpace(RootBone.CFrame), -- Why does this exist?
		BoneTotalLength = 0,
		DistanceFromCamera = 100,
		Bones = {},
		Settings = {},

		LocalCFrame = RootBone.WorldCFrame,
		LocalGravity = RootBone.CFrame:PointToWorldSpace(Gravity).Unit * Gravity.Magnitude,
		Force = Vector3.zero,
		RestGravity = Vector3.zero,
		ObjectMove = Vector3.zero,
		ObjectPreviousPosition = Vector3.zero,
	}, Class)
end

function Class:PreUpdate()
	debug.profilebegin("BoneTree::PreUpdate")
	self.ObjectMove = (self.RootPart.Position - self.ObjectPreviousPosition)
	self.ObjectPreviousPosition = self.RootPart.Position

	self.RestGravity = self.Root.CFrame:PointToWorldSpace(self.LocalGravity)

	for _, Bone in self.Bones do
		Bone:PreUpdate()
	end
	debug.profileend()
end

function Class:StepPhysics(Delta)
	debug.profilebegin("BoneTree::StepPhysics")
	local Settings = self.Settings
	local Force = Settings.Gravity
	local ForceDirection = Settings.Gravity.Unit

	local ProjectedForce = ForceDirection * math.max(self.RestGravity:Dot(ForceDirection), 0)

	Force -= ProjectedForce
	Force = (Force + Settings.Force) * Delta

	-- Remove
	Settings.WindDirection = SafeUnit(workspace.GlobalWind)
	Settings.WindSpeed = workspace.GlobalWind.Magnitude

	for _, Bone in self.Bones do
		Bone:StepPhysics(self, Force)
	end
	debug.profileend()
end

function Class:Constrain(Colliders, Delta)
	debug.profilebegin("BoneTree::Constrain")
	for _, Bone in self.Bones do
		Bone:Constrain(self, Colliders, Delta)
	end
	debug.profileend()
end

function Class:SolveTransform(Delta)
	debug.profilebegin("BoneTree::SolveTransform")
	for _, Bone in self.Bones do
		Bone:SolveTransform(self, Delta)
	end
	debug.profileend()
end

function Class:ApplyTransform()
	debug.profilebegin("BoneTree::ApplyTransform")
	for _, Bone in self.Bones do
		Bone:ApplyTransform(self)
	end
	debug.profileend()
end

function Class:DrawDebug(DRAW_COLLIDERS, DRAW_CONTACTS, DRAW_PHYSICAL_BONE, DRAW_BONE, DRAW_AXIS_LIMITS)
	debug.profilebegin("BoneTree::DrawDebug")
	local LINE_CONNECTING_COLOR = Color3.fromRGB(248, 168, 20)

	Gizmo.PushProperty("AlwaysOnTop", false)

	for i, Bone in self.Bones do
		local BonePosition = Bone.Bone.WorldPosition
		local ParentBone = self.Bones[Bone.ParentIndex]

		if i == 1 then
			continue -- Skip if we are on our root bone
		end

		Bone:DrawDebug(DRAW_COLLIDERS, DRAW_CONTACTS, DRAW_PHYSICAL_BONE, DRAW_BONE, DRAW_AXIS_LIMITS)

		if DRAW_PHYSICAL_BONE and i ~= 2 then
			Gizmo.PushProperty("Color3", LINE_CONNECTING_COLOR)
			Gizmo.Ray:Draw(ParentBone.Bone.WorldPosition, BonePosition)
		end
	end
	debug.profileend()
end

return Class
