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

	TransformOffset: CFrame,
	LastTransformOffset: CFrame,
	ParentTransformOffset: CFrame,
	LocalTransformOffset: CFrame,
	RestPosition: Vector3,
	BoneTransform: CFrame,
	CalculatedWorldCFrame: CFrame,
	CalculatedWorldPosition: Vector3,

	Position: Vector3,
	LastPosition: Vector3,

	Anchored: boolean,
	AxisLocked: { [number]: boolean },
	XAxisLimits: NumberRange,
	YAxisLimits: NumberRange,
	ZAxisLimits: NumberRange,
}

local function ClipVector(LastPosition, Position, Vector)
	LastPosition *= (Vector3.one - Vector)
	LastPosition += (Position * Vector)
	return LastPosition
end

local function SolveWind(self, BoneTree)
	local Settings = BoneTree.Settings

	local TimeModifier = BoneTree.WindOffset
		+ (
			((os.clock() - (self.HeirarchyLength / 5)) + (self.TransformOffset.Position - BoneTree.Root.WorldPosition).Magnitude / 5)
			* Settings.WindInfluence
		)

	local WindMove

	if Settings.WindType == "Sine" then
		local sineWave = math.sin(TimeModifier * Settings.WindSpeed)
		WindMove = Vector3.new(
			Settings.WindDirection.X + (Settings.WindDirection.X * sineWave),
			Settings.WindDirection.Y + (Settings.WindDirection.Y * sineWave),
			Settings.WindDirection.Z + (Settings.WindDirection.Z * sineWave)
		)
	elseif Settings.WindType == "Noise" then
		local frequency = TimeModifier * Settings.WindSpeed
		local seed = BoneTree.WindOffset
		local amp = Settings.WindStrength * 10

		local X = math.noise(frequency, 0, seed) * amp
		local Y = math.noise(frequency, 0, -seed) * amp
		local Z = math.noise(frequency, 0, seed + seed) * amp

		WindMove = Vector3.new(
			Settings.WindDirection.X + (Settings.WindDirection.X * X),
			Settings.WindDirection.Y + (Settings.WindDirection.Y * Y),
			Settings.WindDirection.Z + (Settings.WindDirection.Z * Z)
		)
	elseif Settings.WindType == "Hybrid" then
		local sineWave = math.sin(TimeModifier * Settings.WindSpeed)
		WindMove = Vector3.new(
			Settings.WindDirection.X + (Settings.WindDirection.X * sineWave),
			Settings.WindDirection.Y + (Settings.WindDirection.Y * sineWave),
			Settings.WindDirection.Z + (Settings.WindDirection.Z * sineWave)
		)

		local frequency = TimeModifier * Settings.WindSpeed
		local seed = BoneTree.WindOffset
		local amp = Settings.WindStrength * 10

		local X = math.noise(frequency, 0, seed) * amp
		local Y = math.noise(frequency, 0, -seed) * amp
		local Z = math.noise(frequency, 0, seed + seed) * amp

		WindMove += Vector3.new(
			Settings.WindDirection.X + (Settings.WindDirection.X * X),
			Settings.WindDirection.Y + (Settings.WindDirection.Y * Y),
			Settings.WindDirection.Z + (Settings.WindDirection.Z * Z)
		)
		WindMove /= 2
	end

	WindMove /= self.FreeLength
	WindMove *= (Settings.WindInfluence * (Settings.WindStrength / 100)) * (math.clamp(self.HeirarchyLength, 1, 10) / 10)
	WindMove *= self.Weight

	return WindMove
end

local Class = {}
Class.__index = Class

function Class.new(Bone: Bone, RootBone: Bone, RootPart: BasePart)
	return setmetatable({
		Bone = Bone,
		FreeLength = -1,
		Weight = 1 * 0.7,
		ParentIndex = -1,
		HeirarchyLength = 0,
		Transform = Bone.WorldCFrame:ToObjectSpace(RootBone.WorldCFrame):Inverse(),
		LocalTransform = Bone.CFrame:ToObjectSpace(RootBone.CFrame):Inverse(),
		RootTransform = RootBone.WorldCFrame:ToObjectSpace(RootPart.CFrame):Inverse(),
		RootPart = RootPart,
		RootBone = RootBone,
		Radius = 0,
		Restitution = 0,

		TransformOffset = CFrame.identity, -- If this bone is the root part then this is our cframe relative to root part if it isnt root then its relative to its parent (AT THE START OF THE SIMULATION)
		LastTransformOffset = CFrame.identity,
		ParentTransformOffset = CFrame.identity,
		LocalTransformOffset = CFrame.identity, -- Our CFrame relative to the root bone when we first start the simulation
		RestPosition = Vector3.zero,
		BoneTransform = CFrame.identity,
		CalculatedWorldCFrame = Bone.WorldCFrame,
		CalculatedWorldPosition = Bone.WorldPosition,

		Position = Bone.WorldPosition,
		LastPosition = Bone.WorldPosition,

		Anchored = false,
		AxisLocked = { false, false, false },
		XAxisLimits = NumberRange.new(-math.huge, math.huge),
		YAxisLimits = NumberRange.new(-math.huge, math.huge),
		ZAxisLimits = NumberRange.new(-math.huge, math.huge),

		PreviousVelocity = Vector3.zero,
		NextVelocity = Vector3.zero,

		-- Debug
		CollisionsData = {},
	}, Class)
end

function Class:ImpulseVelocity(Velocity)
	self.NextVelocity += Velocity
end

function Class:ClipVelocity(Position, Vector)
	self.LastPosition = ClipVector(self.LastPosition, Position, Vector)
end

function Class:PreUpdate() -- Parallel safe
	debug.profilebegin("Bone::PreUpdate")
	local RootPart = self.RootPart
	local Root = self.RootBone

	self.LastTransformOffset = self.TransformOffset
	if self.Bone == self.RootBone then
		self.TransformOffset = RootPart.CFrame * self.RootTransform
	else
		self.TransformOffset = Root.WorldCFrame * self.Transform
	end
	self.LocalTransformOffset = Root.CFrame * self.LocalTransform
	debug.profileend()
end

function Class:StepPhysics(BoneTree, Force) -- Parallel safe
	debug.profilebegin("Bone::StepPhysics")
	if self.Anchored then
		self.LastPosition = self.TransformOffset.Position
		self.Position = self.TransformOffset.Position

		debug.profileend()
		return
	end

	local Settings = BoneTree.Settings

	local Velocity = (self.Position - self.LastPosition) + self.NextVelocity
	local Move = (BoneTree.ObjectMove * Settings.Inertia)
	local WindMove = SolveWind(self, BoneTree)

	self.LastPosition = self.Position
	self.Position += Velocity * (1 - Settings.Damping) + Force + Move + WindMove

	self.PreviousVelocity = Velocity
	self.NextVelocity = Vector3.zero
	debug.profileend()
end

function Class:Constrain(BoneTree, Colliders, Delta) -- Parallel safe
	debug.profilebegin("Bone::Constrain")
	if self.Anchored then
		debug.profileend()
		return
	end

	local Position = self.Position
	local RootPart = self.RootPart
	local RootCFrame: CFrame = RootPart.CFrame

	Position = AxisConstraint(self, Position, RootCFrame)

	if #Colliders ~= 0 then
		Position = CollisionConstraint(self, Position, Colliders)
	end

	if BoneTree.Settings.Constraint == "Spring" then
		Position = SpringConstraint(self, Position, BoneTree, Delta)
	elseif BoneTree.Settings.Constraint == "Distance" then
		Position = DistanceConstraint(self, Position, BoneTree)
	end

	self.Position = Position
	debug.profileend()
end

function Class:SolveTransform(BoneTree, Delta) -- Parallel safe
	debug.profilebegin("Bone::SolveTransform")
	if self.ParentIndex < 1 then
		debug.profileend()
		return
	end

	local ParentBone = BoneTree.Bones[self.ParentIndex]
	local BoneParent = ParentBone.Bone

	if ParentBone and BoneParent and BoneParent:IsA("Bone") and BoneParent ~= BoneTree.RootBone then
		local X = Utilities.GetCFrameAxis(BoneParent.WorldCFrame, "X")
		local _, Y, Z = ParentBone.TransformOffset:ToEulerAnglesXYZ()

		local RefrenceRotation = CFrame.fromEulerAnglesXYZ(X, Y, Z).Rotation
		local ReferenceCFrame = CFrame.new(BoneParent.WorldPosition) * RefrenceRotation

		local Vector0 = ReferenceCFrame:PointToObjectSpace(ParentBone.LocalTransformOffset.Position)
		local Vector1 = self.Position - ParentBone.Position

		local Rotation = Utilities.GetRotationBetween(ReferenceCFrame.UpVector, Vector1, Vector0).Rotation * ReferenceCFrame.Rotation

		local Alpha = 0.99999 ^ Delta

		ParentBone.CalculatedWorldCFrame = BoneParent.WorldCFrame:Lerp(CFrame.new(ParentBone.Position) * Rotation, Alpha)
	end
	debug.profileend()
end

function Class:ApplyTransform(BoneTree)
	debug.profilebegin("Bone::ApplyTransform")
	if self.ParentIndex < 1 then
		debug.profileend()
		return
	end

	local ParentBone = BoneTree.Bones[self.ParentIndex]
	local BoneParent = ParentBone.Bone

	if ParentBone and BoneParent and BoneParent:IsA("Bone") and BoneParent ~= BoneTree.RootBone then
		if ParentBone.Anchored and BoneTree.Settings.AnchorsRotate == false then
			BoneParent.WorldCFrame = ParentBone.TransformOffset
		else
			BoneParent.WorldCFrame = ParentBone.CalculatedWorldCFrame
		end
	end
	debug.profileend()
end

function Class:DrawDebug(_, DRAW_CONTACTS, DRAW_PHYSICAL_BONE, DRAW_BONE, DRAW_AXIS_LIMITS)
	debug.profilebegin("Bone::DrawDebug")
	local BONE_POSITION_COLOR = Color3.fromRGB(255, 1, 1)
	local BONE_LAST_POSITION_COLOR = Color3.fromRGB(255, 94, 1)
	local BONE_POSITION_RAY_COLOR = Color3.fromRGB(234, 1, 255)
	local BONE_SPHERE_COLOR = Color3.fromRGB(0, 255, 255)
	local BONE_FRONT_ARROW_COLOR = Color3.fromRGB(255, 0, 0)
	local BONE_UP_ARROW_COLOR = Color3.fromRGB(0, 255, 0)
	local BONE_RIGHT_ARROW_COLOR = Color3.fromRGB(0, 0, 255)
	local AXIS_X_COLOR = Color3.fromRGB(255, 0, 0)
	local AXIS_Y_COLOR = Color3.fromRGB(0, 255, 0)
	local AXIS_Z_COLOR = Color3.fromRGB(0, 0, 255)

	local COLLISION_CONTACT_SPHERE_COLOR = Color3.fromRGB(28, 41, 224)
	local COLLISION_CONTACT_NORMAL_COLOR = Color3.fromRGB(255, 27, 27)
	local COLLISION_CONTACT_SPHERE_RADIUS = 0.08
	local COLLISION_CONTACT_ARROW_LENGTH = 0.15
	local COLLISION_CONTACT_ARROW_RADIUS = 0.05
	local COLLISION_CONTACT_ARROW_EXPANSION = 0.5

	local BONE_ARROW_LENGTH = 0.15
	local BONE_ARROW_RADIUS = 0.05
	local BONE_ARROW_EXPANSION = 0.5
	local BONE_RADIUS = 0.08

	local BonePosition = self.Bone.WorldPosition
	local BoneCFrame = self.Bone.WorldCFrame
	local BonePositionCFrame = CFrame.new(self.Position)
	local BoneLastPositionCFrame = CFrame.new(self.LastPosition)

	-- Draw our internal bone

	if DRAW_BONE then
		Gizmo.PushProperty("AlwaysOnTop", false)

		Gizmo.PushProperty("Color3", BONE_POSITION_COLOR)
		Gizmo.Sphere:Draw(BonePositionCFrame, self.Radius, 20, 360)

		Gizmo.PushProperty("Color3", BONE_LAST_POSITION_COLOR)
		Gizmo.Sphere:Draw(BoneLastPositionCFrame, self.Radius, 20, 360)

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
			Gizmo.Ray:Draw(BonePosition - XVector * 2, BonePosition + XVector * 2)

			local MinXLimit = self.XAxisLimits.Min - Offset.X
			local MaxXLimit = self.XAxisLimits.Max - Offset.X

			Gizmo.Plane:Draw(BonePosition + XVector * MinXLimit, XVector, Size)
			Gizmo.Plane:Draw(BonePosition + XVector * MaxXLimit, XVector, Size)
		end

		if not YLock then
			Gizmo.PushProperty("Color3", AXIS_Y_COLOR)
			Gizmo.Ray:Draw(BonePosition - YVector * 2, BonePosition + YVector * 2)

			local MinYLimit = self.YAxisLimits.Min - Offset.Y
			local MaxYLimit = self.YAxisLimits.Max - Offset.Y

			Gizmo.Plane:Draw(BonePosition + YVector * MinYLimit, YVector, Size)
			Gizmo.Plane:Draw(BonePosition + YVector * MaxYLimit, YVector, Size)
		end

		if not ZLock then
			Gizmo.PushProperty("Color3", AXIS_Z_COLOR)
			Gizmo.Ray:Draw(BonePosition - ZVector * 2, BonePosition + ZVector * 2)

			local MinZLimit = self.ZAxisLimits.Min - Offset.Z
			local MaxZLimit = self.ZAxisLimits.Max - Offset.Z

			Gizmo.Plane:Draw(BonePosition - ZVector * MinZLimit, ZVector, Size)
			Gizmo.Plane:Draw(BonePosition - ZVector * MaxZLimit, ZVector, Size)
		end
	end

	-- Draw the physical bone object

	if DRAW_PHYSICAL_BONE then
		Gizmo.PushProperty("Color3", BONE_SPHERE_COLOR)
		Gizmo.Sphere:Draw(BoneCFrame, BONE_RADIUS, 20, 360)

		Gizmo.PushProperty("Color3", BONE_FRONT_ARROW_COLOR)
		Gizmo.Arrow:Draw(BonePosition, BonePosition + BoneCFrame.LookVector * BONE_ARROW_EXPANSION, BONE_ARROW_RADIUS, BONE_ARROW_LENGTH, 9)

		Gizmo.PushProperty("Color3", BONE_UP_ARROW_COLOR)
		Gizmo.Arrow:Draw(BonePosition, BonePosition + BoneCFrame.UpVector * BONE_ARROW_EXPANSION, BONE_ARROW_RADIUS, BONE_ARROW_LENGTH, 9)

		Gizmo.PushProperty("Color3", BONE_RIGHT_ARROW_COLOR)
		Gizmo.Arrow:Draw(BonePosition, BonePosition + BoneCFrame.RightVector * BONE_ARROW_EXPANSION, BONE_ARROW_RADIUS, BONE_ARROW_LENGTH, 9)
	end

	-- Draw our collision contacts

	if DRAW_CONTACTS and not self.Anchored then
		for _, Collision in self.CollisionsData do
			Gizmo.PushProperty("Color3", COLLISION_CONTACT_SPHERE_COLOR)
			Gizmo.Sphere:Draw(CFrame.new(Collision.ClosestPoint), COLLISION_CONTACT_SPHERE_RADIUS, 20, 360)

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

return Class
