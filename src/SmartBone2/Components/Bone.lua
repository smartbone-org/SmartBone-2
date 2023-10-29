--!nocheck
local Dependencies = script.Parent.Parent:WaitForChild("Dependencies")
local Gizmo = require(Dependencies:WaitForChild("Gizmo"))
local Utilities = require(Dependencies:WaitForChild("Utilities"))
Gizmo.Init()

local Constraints = script.Parent:WaitForChild("Constraints")
local AxisConstraint = require(Constraints:WaitForChild("AxisConstraint"))
local CollisionConstraint = require(Constraints:WaitForChild("CollisionConstraint"))
local DistanceConstraint = require(Constraints:WaitForChild("DistanceConstraint"))
local SpringConstraint = require(Constraints:WaitForChild("SpringConstraint"))

export type IBone = {
	Bone: Bone,
	FreeLength: number,
	Weight: number,
	ParentIndex: number,
	HeirarchyLength: number,
	Transform: CFrame,
	LocalTransform: CFrame,
	RootTransform: CFrame,
	Radius: number,

	AnimatedWorldCFrame: CFrame,
	TransformOffset: CFrame,
	LocalTransformOffset: CFrame,
	RestPosition: Vector3,
	CalculatedWorldCFrame: CFrame,

	Position: Vector3,
	LastPosition: Vector3,

	Anchored: boolean,
	AxisLocked: { [number]: boolean },
	XAxisLimits: NumberRange,
	YAxisLimits: NumberRange,
	ZAxisLimits: NumberRange,
}

local function QueryTransformedWorldCFrame(Bone: Bone)
	local Parent = Bone.Parent
	local ParentCFrame

	if Parent:IsA("Bone") then
		ParentCFrame = QueryTransformedWorldCFrame(Parent)
	else
		ParentCFrame = Parent.CFrame
	end

	return ParentCFrame:ToWorldSpace(Bone.TransformedCFrame)
end

local function ClipVector(LastPosition, Position, Vector)
	LastPosition *= (Vector3.one - Vector)
	LastPosition += (Position * Vector)
	return LastPosition
end

local function SolveWind(self, BoneTree)
	local Settings = BoneTree.Settings

	local TimeModifier = BoneTree.WindOffset
		+ (
			((os.clock() - (self.HeirarchyLength * 0.2)) + (self.TransformOffset.Position - BoneTree.Root.WorldPosition).Magnitude * 0.2) -- * 0.2 is / 5
			* Settings.WindInfluence
		)

	local WindMove

	local function GetNoise(X, Y, Z, Map) -- Returns noise between 0, 1
		local Value = math.noise(X, Y, Z)
		Value = math.clamp(Value, -1, 1)

		if Map then
			Value ^= 2
		end

		return Value
	end

	local function SampleSin()
		local Freq = Settings.WindSpeed ^ 0.8
		local Power = Settings.WindSpeed ^ 0.9
		local Amp = Settings.WindStrength * 10
		local Sin1 = math.sin(TimeModifier * Freq) ^ 2
		local Sin2 = math.cos(TimeModifier * Freq) ^ 2 - 0.2
		local Wave = (Sin1 > Sin2 and Sin1 or Sin2) * (Power + Amp)
		return Settings.WindDirection * Wave
	end

	local function SampleNoise(CustomAmp, Map)
		CustomAmp = CustomAmp or 0

		local Freq = Settings.WindSpeed ^ 0.8
		local Power = Settings.WindSpeed ^ 0.9
		local Amp = Settings.WindStrength * 10
		local Seed = BoneTree.WindOffset

		local X = GetNoise(Freq, 0, Seed, Map) * (Power + Amp + CustomAmp)
		local Y = GetNoise(0, Freq, Seed, Map) * (Power + Amp + CustomAmp)
		local Z = GetNoise(Seed, 0, Freq, Map) * (Power + Amp + CustomAmp)

		return Settings.WindDirection * Vector3.new(X, Y, Z)
	end

	if Settings.WindType == "Sine" then
		WindMove = SampleSin()
	elseif Settings.WindType == "Noise" then
		WindMove = SampleNoise(0, true)
	elseif Settings.WindType == "Hybrid" then
		WindMove = SampleSin()
		WindMove += SampleNoise(0.5, true)
		WindMove *= 0.5
	else
		return WindMove -- If the wind type the user inputted doesnt exist, I would throw an error / warn but that would crash studio :(
	end

	WindMove /= self.FreeLength
	WindMove *= (Settings.WindInfluence * (Settings.WindStrength * 0.01)) * (math.clamp(self.HeirarchyLength, 1, 10) * 0.1)
	WindMove *= self.Weight

	return WindMove
end

--- @class Bone
--- Internal class for all bones
--- :::caution Caution:
--- Changes to the syntax in this class will not count to the major version in semver.
--- :::

--- @within Bone
--- @readonly
--- @prop Bone Bone

--- @within Bone
--- @prop FreeLength number

--- @within Bone
--- @prop Weight number

--- @within Bone
--- @readonly
--- @prop ParentIndex number

--- @within Bone
--- @readonly
--- @prop HeirarchyLength number

--- @within Bone
--- @prop Transform CFrame

--- @within Bone
--- @prop LocalTransform CFrame

--- @within Bone
--- @prop RootTransform CFrame

--- @within Bone
--- @readonly
--- @prop RootPart BasePart

--- @within Bone
--- @readonly
--- @prop RootBone Bone

--- @within Bone
--- @prop Radius number

--- @within Bone
--- @readonly
--- @prop AnimatedWorldCFrame CFrame
--- Bone.TransformedWorldCFrame

--- @within Bone
--- @readonly
--- @prop TransformOffset CFrame

--- @within Bone
--- @readonly
--- @prop LocalTransformOffset CFrame

--- @within Bone
--- @readonly
--- @prop RestPosition Vector3

--- @within Bone
--- @readonly
--- @prop CalculatedWorldCFrame CFrame

--- @within Bone
--- @prop Position Vector3
--- Internal representation of the bone

--- @within Bone
--- @prop Anchored boolean

--- @within Bone
--- @prop AxisLocked { boolean, boolean, boolean }
--- XYZ order

--- @within Bone
--- @prop XAxisLimits NumberRange

--- @within Bone
--- @prop YAxisLimits NumberRange

--- @within Bone
--- @prop ZAxisLimits NumberRange

--- @within Bone
--- @prop FirstSkipUpdate boolean

--- @within Bone
--- @prop CollisionData {}

local Class = {}
Class.__index = Class

function Class.new(Bone: Bone, RootBone: Bone, RootPart: BasePart)
	return setmetatable({
		Bone = Bone,
		FreeLength = -1,
		Weight = 1 * 0.7,
		ParentIndex = -1,
		HeirarchyLength = 0,
		Transform = Bone.TransformedWorldCFrame:ToObjectSpace(RootBone.TransformedWorldCFrame):Inverse(),
		LocalTransform = Bone.CFrame:ToObjectSpace(RootBone.CFrame):Inverse(),
		RootTransform = RootBone.WorldCFrame:ToObjectSpace(RootPart.CFrame):Inverse(),
		RootPart = RootPart,
		RootBone = RootBone,
		Radius = 0,

		AnimatedWorldCFrame = Bone.TransformedWorldCFrame,
		TransformOffset = CFrame.identity, -- If this bone is the root part then this is our cframe relative to root part if it isnt root then its relative to its parent (AT THE START OF THE SIMULATION)
		LocalTransformOffset = CFrame.identity, -- Our CFrame relative to the root bone when we first start the simulation
		RestPosition = Vector3.zero,
		CalculatedWorldCFrame = Bone.TransformedWorldCFrame,

		Position = Bone.TransformedWorldCFrame.Position,
		LastPosition = Bone.TransformedWorldCFrame.Position,

		Anchored = false,
		AxisLocked = { false, false, false },
		XAxisLimits = NumberRange.new(-math.huge, math.huge),
		YAxisLimits = NumberRange.new(-math.huge, math.huge),
		ZAxisLimits = NumberRange.new(-math.huge, math.huge),

		FirstSkipUpdate = false,

		-- Debug
		CollisionsData = {},
	}, Class)
end

--- @within Bone
--- @param Position Vector3
--- @param Vector Vector3
--- Clips velocity on specified vector, Position is where we are at our current physics step (Before we set self.Position)
function Class:ClipVelocity(Position, Vector)
	self.LastPosition = ClipVector(self.LastPosition, Position, Vector)
end

--- @within Bone
--- @param BoneTree BoneTree
function Class:PreUpdate(BoneTree) -- Parallel safe
	debug.profilebegin("Bone::PreUpdate")
	local RootPart = self.RootPart
	local Root = BoneTree.Bones[1]

	self.AnimatedWorldCFrame = QueryTransformedWorldCFrame(self.Bone)

	if self.ParentIndex < 1 then -- Force anchor the root bone
		self.Anchored = true
	end

	if self.Bone == self.RootBone then
		self.TransformOffset = RootPart.CFrame * self.RootTransform
	else
		self.TransformOffset = Root.AnimatedWorldCFrame * self.Transform
	end
	self.LocalTransformOffset = Root.Bone.CFrame * self.LocalTransform
	debug.profileend()
end

--- @within Bone
--- @param BoneTree BoneTree
--- @param Force Vector3
--- Force passed in via BoneTree:StepPhysics()
function Class:StepPhysics(BoneTree, Force) -- Parallel safe
	debug.profilebegin("Bone::StepPhysics")
	if self.Anchored then
		self.LastPosition = self.AnimatedWorldCFrame.Position
		self.Position = self.AnimatedWorldCFrame.Position

		debug.profileend()
		return
	end

	local Settings = BoneTree.Settings

	local Velocity = (self.Position - self.LastPosition)
	local Move = (BoneTree.ObjectMove * Settings.Inertia)
	local WindMove = SolveWind(self, BoneTree)

	self.LastPosition = self.Position
	self.Position += Velocity * (1 - Settings.Damping) + Force + Move + WindMove

	debug.profileend()
end

--- @within Bone
--- @param BoneTree BoneTree
--- @param ColliderObjects Vector3
--- @param Delta number -- Δt
function Class:Constrain(BoneTree, ColliderObjects, Delta) -- Parallel safe
	debug.profilebegin("Bone::Constrain")
	if self.Anchored then
		debug.profileend()
		return
	end

	local Position = self.Position
	local RootPart = self.RootPart
	local RootCFrame: CFrame = RootPart.CFrame

	if #ColliderObjects ~= 0 then
		Position = CollisionConstraint(self, Position, ColliderObjects)
	end

	if BoneTree.Settings.Constraint == "Spring" then
		Position = SpringConstraint(self, Position, BoneTree, Delta)
	elseif BoneTree.Settings.Constraint == "Distance" then
		Position = DistanceConstraint(self, Position, BoneTree)
	end

	Position = AxisConstraint(self, Position, self.LastPosition, RootCFrame)

	self.Position = Position
	debug.profileend()
end

--- @within Bone
--- Returns bone to rest position
function Class:SkipUpdate()
	if self.FirstSkipUpdate == false then
		self.Bone.WorldCFrame = self.TransformOffset
		self.FirstSkipUpdate = true
	end

	self.AnimatedWorldCFrame = self.Bone.TransformedWorldCFrame
	self.Position = self.Bone.WorldPosition
	self.LastPosition = self.Position
end

--- @within Bone
--- @param BoneTree BoneTree
--- @param Delta number -- Δt
--- Solves the cframe of the bones
function Class:SolveTransform(BoneTree, Delta) -- Parallel safe
	debug.profilebegin("Bone::SolveTransform")
	if self.ParentIndex < 1 then
		debug.profileend()
		return
	end

	local ParentBone = BoneTree.Bones[self.ParentIndex]
	local BoneParent = ParentBone.Bone

	if ParentBone and BoneParent and BoneParent:IsA("Bone") and BoneParent ~= BoneTree.RootBone then
		local ReferenceCFrame = ParentBone.TransformOffset
		local v1 = self.Position - ParentBone.Position
		local Rotation = Utilities.GetRotationBetween(ReferenceCFrame.UpVector, v1).Rotation * ReferenceCFrame.Rotation

		local factor = 0.00001
		local alpha = (1 - factor ^ Delta)

		ParentBone.CalculatedWorldCFrame = BoneParent.WorldCFrame:Lerp(CFrame.new(ParentBone.Position) * Rotation, alpha)
	end
	debug.profileend()
end

--- @within Bone
--- @param BoneTree BoneTree
--- Sets the world cframes of the bones to the calculated world cframe (solved in Bone:SolveTransform())
function Class:ApplyTransform(BoneTree)
	debug.profilebegin("Bone::ApplyTransform")

	-- self.AnimatedWorldCFrame = self.Bone.TransformedWorldCFrame

	if self.ParentIndex < 1 then
		debug.profileend()
		return
	end

	self.FirstSkipUpdate = false

	local ParentBone = BoneTree.Bones[self.ParentIndex]
	local BoneParent = ParentBone.Bone

	if ParentBone and BoneParent and BoneParent:IsA("Bone") and BoneParent ~= BoneTree.RootBone then
		if ParentBone.Anchored and BoneTree.Settings.AnchorsRotate == false then
			BoneParent.WorldCFrame = ParentBone.TransformOffset
		else
			if ParentBone.Anchored and BoneTree.Settings.AnchorsRotate == true then
				BoneParent.WorldCFrame = ParentBone.TransformOffset * ParentBone.CalculatedWorldCFrame.Rotation
				debug.profileend()
				return
			end

			BoneParent.WorldCFrame = ParentBone.CalculatedWorldCFrame
		end
	end
	debug.profileend()
end

--- @within Bone
--- @param DRAW_CONTACTS any
--- @param DRAW_PHYSICAL_BONE any
--- @param DRAW_BONE any
--- @param DRAW_AXIS_LIMITS any
function Class:DrawDebug(DRAW_CONTACTS, DRAW_PHYSICAL_BONE, DRAW_BONE, DRAW_AXIS_LIMITS)
	debug.profilebegin("Bone::DrawDebug")
	local BONE_POSITION_COLOR = Color3.fromRGB(255, 0, 0)
	local BONE_LAST_POSITION_COLOR = Color3.fromRGB(255, 94, 0)
	local BONE_POSITION_RAY_COLOR = Color3.fromRGB(234, 1, 255)
	local BONE_SPHERE_COLOR = Color3.fromRGB(0, 255, 255)
	local BONE_FRONT_ARROW_COLOR = Color3.fromRGB(255, 0, 0)
	local BONE_UP_ARROW_COLOR = Color3.fromRGB(0, 255, 0)
	local BONE_RIGHT_ARROW_COLOR = Color3.fromRGB(0, 0, 255)
	local AXIS_X_COLOR = Color3.fromRGB(255, 0, 0)
	local AXIS_Y_COLOR = Color3.fromRGB(0, 255, 0)
	local AXIS_Z_COLOR = Color3.fromRGB(0, 0, 255)
	local AXIS_ARROW_RADIUS = 0.05
	local AXIS_ARROW_LENGTH = 0.15

	local COLLISION_CONTACT_SPHERE_COLOR = Color3.fromRGB(28, 41, 224)
	local COLLISION_CONTACT_NORMAL_COLOR = Color3.fromRGB(255, 27, 27)
	local COLLISION_CONTACT_SPHERE_RADIUS = 0.08
	local COLLISION_CONTACT_ARROW_LENGTH = 0.15
	local COLLISION_CONTACT_ARROW_RADIUS = 0.05
	local COLLISION_CONTACT_ARROW_EXPANSION = 0.5

	local BONE_ARROW_LENGTH = 0.05
	local BONE_ARROW_RADIUS = 0.015
	local BONE_CYLINDER_RADIUS = 0.005
	local BONE_ARROW_EXPANSION = 0.25
	local BONE_RADIUS = 0.08

	local BoneCFrame = self.AnimatedWorldCFrame
	local BonePosition = BoneCFrame.Position
	local BonePositionCFrame = CFrame.new(self.Position)
	local BoneLastPositionCFrame = CFrame.new(self.LastPosition)

	-- Draw our internal bone

	if DRAW_BONE then
		Gizmo.PushProperty("AlwaysOnTop", false)

		Gizmo.PushProperty("Color3", BONE_POSITION_COLOR)
		Gizmo.Sphere:Draw(BonePositionCFrame, self.Radius, 10, 360)

		Gizmo.PushProperty("Color3", BONE_LAST_POSITION_COLOR)
		Gizmo.Sphere:Draw(BoneLastPositionCFrame, self.Radius, 10, 360)

		Gizmo.PushProperty("Color3", BONE_POSITION_RAY_COLOR)
		Gizmo.Ray:Draw(self.Position, self.LastPosition)
	end

	-- Draw our axis Limits

	if DRAW_AXIS_LIMITS and not self.Anchored then
		local XLock = self.AxisLocked[1]
		local YLock = self.AxisLocked[2]
		local ZLock = self.AxisLocked[3]

		local RootPart = self.RootPart
		local Offset = RootPart.CFrame:PointToObjectSpace(BonePosition)

		local XVector = RootPart.CFrame.RightVector
		local YVector = RootPart.CFrame.UpVector
		local ZVector = RootPart.CFrame.LookVector

		local Size = Vector3.new(5, 5, 0)

		if not XLock then
			Gizmo.PushProperty("Color3", AXIS_X_COLOR)
			Gizmo.Arrow:Draw(BonePosition - XVector * 2, BonePosition + XVector * 2, AXIS_ARROW_RADIUS, AXIS_ARROW_LENGTH, 9)

			local MinXLimit = self.XAxisLimits.Min - Offset.X
			local MaxXLimit = self.XAxisLimits.Max - Offset.X

			Gizmo.Plane:Draw(BonePosition + XVector * MinXLimit, XVector, Size)
			Gizmo.Plane:Draw(BonePosition + XVector * MaxXLimit, XVector, Size)
		end

		if not YLock then
			Gizmo.PushProperty("Color3", AXIS_Y_COLOR)
			Gizmo.Arrow:Draw(BonePosition - YVector * 2, BonePosition + YVector * 2, AXIS_ARROW_RADIUS, AXIS_ARROW_LENGTH, 9)

			local MinYLimit = self.YAxisLimits.Min - Offset.Y
			local MaxYLimit = self.YAxisLimits.Max - Offset.Y

			Gizmo.Plane:Draw(BonePosition + YVector * MinYLimit, YVector, Size)
			Gizmo.Plane:Draw(BonePosition + YVector * MaxYLimit, YVector, Size)
		end

		if not ZLock then
			Gizmo.PushProperty("Color3", AXIS_Z_COLOR)
			Gizmo.Arrow:Draw(BonePosition - ZVector * 2, BonePosition + ZVector * 2, AXIS_ARROW_RADIUS, AXIS_ARROW_LENGTH, 9)

			local MinZLimit = self.ZAxisLimits.Min - Offset.Z
			local MaxZLimit = self.ZAxisLimits.Max - Offset.Z

			Gizmo.Plane:Draw(BonePosition - ZVector * MinZLimit, ZVector, Size)
			Gizmo.Plane:Draw(BonePosition - ZVector * MaxZLimit, ZVector, Size)
		end
	end

	-- Draw the physical bone object

	if DRAW_PHYSICAL_BONE then
		Gizmo.PushProperty("Color3", BONE_SPHERE_COLOR)
		Gizmo.Sphere:Draw(BoneCFrame, BONE_RADIUS, 5, 360)

		Gizmo.PushProperty("Color3", BONE_FRONT_ARROW_COLOR)
		Gizmo.VolumeArrow:Draw(
			BonePosition,
			BonePosition + BoneCFrame.LookVector * BONE_ARROW_EXPANSION,
			BONE_CYLINDER_RADIUS,
			BONE_ARROW_RADIUS,
			BONE_ARROW_LENGTH,
			true
		)

		Gizmo.PushProperty("Color3", BONE_UP_ARROW_COLOR)
		Gizmo.VolumeArrow:Draw(
			BonePosition,
			BonePosition + BoneCFrame.UpVector * BONE_ARROW_EXPANSION,
			BONE_CYLINDER_RADIUS,
			BONE_ARROW_RADIUS,
			BONE_ARROW_LENGTH,
			true
		)

		Gizmo.PushProperty("Color3", BONE_RIGHT_ARROW_COLOR)
		Gizmo.VolumeArrow:Draw(
			BonePosition,
			BonePosition + BoneCFrame.RightVector * BONE_ARROW_EXPANSION,
			BONE_CYLINDER_RADIUS,
			BONE_ARROW_RADIUS,
			BONE_ARROW_LENGTH,
			true
		)
	end

	-- Draw our collision contacts

	if DRAW_CONTACTS and not self.Anchored then
		for _, Collision in self.CollisionsData do
			Gizmo.PushProperty("Color3", COLLISION_CONTACT_SPHERE_COLOR)
			Gizmo.Sphere:Draw(CFrame.new(Collision.ClosestPoint), COLLISION_CONTACT_SPHERE_RADIUS, 5, 360)

			Gizmo.PushProperty("Color3", COLLISION_CONTACT_NORMAL_COLOR)
			Gizmo.Arrow:Draw(
				Collision.ClosestPoint,
				Collision.ClosestPoint + Collision.Normal * COLLISION_CONTACT_ARROW_EXPANSION,
				COLLISION_CONTACT_ARROW_RADIUS,
				COLLISION_CONTACT_ARROW_LENGTH,
				9
			)
		end
	end

	debug.profileend()
end

function Class:Destroy()
	setmetatable(self, nil)
end

return Class
