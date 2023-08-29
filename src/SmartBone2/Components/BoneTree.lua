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
	BoneTotalLength: number,
	Bones: { [number]: BoneClass.IBone },
	Settings: { [string]: any },
	UpdateRate: number,
	InView: boolean,

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

local function map(n, start, stop, newStart, newStop, withinBounds)
	local value = ((n - start) / (stop - start)) * (newStop - newStart) + newStart

	--// Returns basic value
	if not withinBounds then
		return value
	end

	--// Returns values constrained to exact range
	if newStart < newStop then
		return math.max(math.min(value, newStop), newStart)
	else
		return math.max(math.min(value, newStart), newStop)
	end
end

local Class = {}
Class.__index = Class

function Class.new(RootBone: Bone, RootPart: BasePart, Gravity: Vector3): IBoneTree
	return setmetatable({
		WindOffset = WIND_RNG:NextNumber(0, 1000000),
		Root = RootBone:IsA("Bone") and RootBone or nil,
		RootPart = RootPart,
		BoneTotalLength = 0,
		Bones = {},
		Settings = {},
		UpdateRate = 0,
		InView = true,

		LocalCFrame = RootBone.WorldCFrame,
		LocalGravity = RootBone.CFrame:PointToWorldSpace(Gravity).Unit * Gravity.Magnitude,
		Force = Vector3.zero,
		RestGravity = Vector3.zero,
		ObjectMove = Vector3.zero,
		ObjectPreviousPosition = RootPart.Position,
	}, Class)
end

function Class:UpdateThrottling(RootPosition)
	debug.profilebegin("Throttling")
	local Settings = self.Settings

	local Camera = workspace.CurrentCamera
	local Distance = (RootPosition - Camera.CFrame.Position).Magnitude

	if Distance > Settings.ActivationDistance then
		self.UpdateRate = 0
		debug.profileend()
		return
	end

	local UpdateRate = 1 - map(Distance, Settings.ThrottleDistance, Settings.ActivationDistance, 0, 1, true)
	self.UpdateRate = Settings.UpdateRate * UpdateRate
	debug.profileend()
end

function Class:PreUpdate()
	debug.profilebegin("BoneTree::PreUpdate")
	local RootPartCFrame = self.RootPart.CFrame
	local RootPartPosition = RootPartCFrame.Position

	self.ObjectMove = (RootPartPosition - self.ObjectPreviousPosition)
	self.ObjectPreviousPosition = RootPartPosition

	self.RestGravity = RootPartCFrame * self.LocalGravity
	self:UpdateThrottling(RootPartPosition)

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

	debug.profilebegin("p0")
	local DGrav = self.RestGravity:Dot(ForceDirection)
	local ProjectedForce = ForceDirection * (DGrav < 0 and 0 or DGrav)
	debug.profileend()

	debug.profilebegin("p1")
	Force -= ProjectedForce
	Force = (Force + Settings.Force) * Delta
	debug.profileend()

	-- Remove
	local GW = workspace.GlobalWind
	Settings.WindDirection = SafeUnit(GW)
	Settings.WindSpeed = GW.Magnitude

	for _, Bone in self.Bones do
		Bone:StepPhysics(self, Force)
	end
	debug.profileend()
end

function Class:Constrain(ColliderObjects, Delta)
	debug.profilebegin("BoneTree::Constrain")
	for _, Bone in self.Bones do
		Bone:Constrain(self, ColliderObjects, Delta)
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
