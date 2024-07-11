--!nocheck
--!native
local Dependencies = script.Parent.Parent:WaitForChild("Dependencies")
local Config = require(Dependencies:WaitForChild("Config"))
local Gizmo = require(Dependencies:WaitForChild("Gizmo"))
local Utilities = require(Dependencies:WaitForChild("Utilities"))
local IsStudio = game:GetService("RunService"):IsStudio()

if IsStudio or Config.ALLOW_LIVE_GAME_DEBUG then
	Gizmo.Init()
end

local Constraints = script.Parent:WaitForChild("Constraints")
local AxisConstraint = require(Constraints:WaitForChild("AxisConstraint"))
local CollisionConstraint = require(Constraints:WaitForChild("CollisionConstraint"))
local DistanceConstraint = require(Constraints:WaitForChild("DistanceConstraint"))
local FrictionConstraint = require(Constraints:WaitForChild("FrictionConstraint"))
local RopeConstraint = require(Constraints:WaitForChild("RopeConstraint"))
local RotationConstraint = require(Constraints:WaitForChild("RotationConstraint"))
local SpringConstraint = require(Constraints:WaitForChild("SpringConstraint"))

local SB_ASSERT_CB = Utilities.SB_ASSERT_CB
--local SB_VERBOSE_LOG = Utilities.SB_VERBOSE_LOG

local function SafeUnit(Vector: Vector3): Vector3
	if Vector.Magnitude == 0 then
		return Vector3.zero
	else
		return Vector.Unit
	end
end

type bool = boolean

type ImOverlay = {
	Begin: (Text: string, BackgroundColor: Color3?, TextColor: Color3?) -> (),
	End: () -> (),
	Text: (Text: string, BackgroundColor: Color3?, TextColor: Color3?) -> ()
}

export type IBone = {
	Bone: Bone,
	RootBone: Bone,
	RootPart: BasePart,
	FreeLength: number,
	Weight: number,
	ParentIndex: number,
	HeirarchyLength: number,
	Transform: CFrame,
	LocalTransform: CFrame,
	Radius: number,
	Friction: number,
	RotationLimit: number,
	Force: Vector3?,
	Gravity: Vector3?,

	SolvedAnimatedCFrame: bool,
	HasChild: bool,
	--NumberOfChildren: number,
	IsSkippingUpdates: bool,

	--RotationSum: Vector3,

	AnimatedWorldCFrame: CFrame,
	TransformOffset: CFrame,
	LocalTransformOffset: CFrame,
	RestPosition: Vector3,
	CalculatedWorldCFrame: CFrame,

	Position: Vector3,
	LastPosition: Vector3,

	ActiveWeld: bool,
	WeldPosition: Vector3,
	WeldCFrame: CFrame,

	Anchored: bool,
	AxisLocked: { [number]: bool },
	XAxisLimits: NumberRange,
	YAxisLimits: NumberRange,
	ZAxisLimits: NumberRange,

	CollisionHits: { [number]: BasePart }
}

local function IsNaN(Value: any): bool
	if Value ~= Value then
		return true
	end

	return false
end

local SolvedTransformedCFrames = {}

-- I beg roblox to make TransformedWorldCFrame parallel safe
local function QueryTransformedWorldCFrameNonSmartbone(OriginBone: Bone): CFrame
do end	
local Solved = SolvedTransformedCFrames[OriginBone]
	if Solved then
		if Solved.Frame == shared.FrameCounter then
			return Solved.CFrame
		end
	end

	local Parent = OriginBone.Parent :: Bone | BasePart
	local ParentCFrame

	if Parent:IsA("Bone") then
		ParentCFrame = QueryTransformedWorldCFrameNonSmartbone(Parent)
	else -- This should always be a basepart unless someone has the weirdest model setup ever. If that person is you, why?
		ParentCFrame = Parent.CFrame
	end

	local Result = ParentCFrame * OriginBone.TransformedCFrame

	SolvedTransformedCFrames[OriginBone] = { Frame = shared.FrameCounter, CFrame = Result }
do end	

return Result
end

-- Gets transformedworldcframe using the parents animatedcframe instead of traversing the tree of bones for each bone, increases performance a ton
local function QueryTransformedWorldCFrame(BoneTree, Bone: IBone): CFrame
do end	
Bone.SolvedAnimatedCFrame = true

	local ParentIndex = Bone.ParentIndex
	local BoneObject = Bone.Bone

	if ParentIndex < 1 then -- We are no longer in the smartbone tree
do end		
return QueryTransformedWorldCFrameNonSmartbone(BoneObject)
	end

	local ParentBone: IBone = BoneTree.Bones[ParentIndex]

	if not ParentBone.SolvedAnimatedCFrame then
		ParentBone.AnimatedWorldCFrame = QueryTransformedWorldCFrame(BoneTree, ParentBone)
	end
do end	

return ParentBone.AnimatedWorldCFrame * BoneObject.TransformedCFrame
end

local function ClipVector(LastPosition: Vector3, Position: Vector3, Vector: Vector3): Vector3
	LastPosition *= (Vector3.one - Vector)
	LastPosition += (Position * Vector)
	return LastPosition
end

local function GetFriction(Object0: BasePart, Object1: BasePart): number
	local Prop0 = Object0.CurrentPhysicalProperties
	local Prop1 = Object1.CurrentPhysicalProperties

	local f0 = Prop0.Friction
	local w0 = Prop0.FrictionWeight

	local f1 = Prop1.Friction
	local w1 = Prop1.FrictionWeight

	return (f0 * w0 + f1 * w1) / (w0 + w1)
end

local function SolveWind(self: IBone, BoneTree: any, Velocity: Vector3): Vector3
do end	
local Settings = BoneTree.Settings
	local WindType = Settings.WindType

	if WindType ~= "Sine" and WindType ~= "Noise" and WindType ~= "Hybrid" then
do end		
return Vector3.zero -- If the wind type the user inputted doesnt exist, I would throw an error / warn but that would crash studio :(
	end

	local TimeModifier = BoneTree.WindOffset
		+ (
			((os.clock() - (self.HeirarchyLength * 0.2)) + (self.TransformOffset.Position - BoneTree.Root.WorldPosition).Magnitude * 0.2) -- * 0.2 is / 5
			* Settings.WindInfluence
		)

	local WindSpeed = Settings.WindSpeed
	local WindStrength = Settings.WindStrength

	if WindSpeed == Vector3.zero or WindStrength == 0 then
do end		
return Vector3.zero
	end

	-- Velocity multiplier
	local WindDirection = Settings.WindDirection
	local VelocityDirection = SafeUnit(Velocity)
do end	


local WindDamper = 1 - math.abs(VelocityDirection:Dot(WindDirection))

	-- This section of code manages the following:
	-- If we are going into the wind then if our bone speed is the same as the wind speed then we should apply double the wind speed, contrary
	-- If we are going with the wind if our bone speed is the same as the wind speed then we wind speed should be zero for this bone.
	if WindSpeed > 0 then
		if VelocityDirection:Dot(WindDirection) > 0 then -- Going with the wind
			local SpeedMatch = 1 - Velocity.Magnitude / WindSpeed
			WindDamper *= math.abs(SpeedMatch)
		else -- Going against the wind
			local SpeedMatch = 1 + Velocity.Magnitude / WindSpeed
			WindDamper *= SpeedMatch
		end
	end
do end
	
WindSpeed *= WindDamper

	local function EaseInExpo(x: number): number
		return x == 0 and 0 or 2 ^ (10 * x - 10)
	end

	local SpeedAlpha = Velocity.Magnitude < 100 and Velocity.Magnitude or 100
	local SpeedMultiplier = EaseInExpo(SpeedAlpha)
	TimeModifier *= math.max(SpeedMultiplier, 1)

	if WindSpeed < 1 then
		WindSpeed *= SpeedMultiplier
	else
		local Mult = SpeedMultiplier / 2
		WindSpeed *= (Mult > 1 and Mult or 1)
	end

	local WindMove

	local function GetNoise(X, Y, Z, Map) -- Returns noise between 0, 1
do end		
local Value = math.noise(X, Y, Z)
		Value = math.clamp(Value, -1, 1)

		if Map then
			Value ^= 2
		end
do end		
return Value
	end

	local function SampleGust()
		local Length = 0.3
		local Freq = 1
		return math.sin(TimeModifier * Freq) * Length + (1 - Length)
	end

	local function SampleSin()
do end		
local Freq = WindStrength ^ 0.8
		local Power = WindSpeed * 2

		-- Multiple octaves of sin waves
		local Sin0 = math.sin(TimeModifier * Freq)
		local Sin1 = math.cos(TimeModifier / 10 * Freq)
		local Sin2 = math.sin(TimeModifier * 2 * Freq)
		local Sin3 = math.cos(TimeModifier * 3 * Freq)
		local Wave = (Sin0 + Sin1 + Sin2 + Sin3) / 4
		local ScaledWave = Wave * 0.5 + 0.5
		Wave *= Power
		ScaledWave *= Power
do end		
return WindDirection * (ScaledWave > Wave and ScaledWave or Wave)
	end

	local function SampleNoise(CustomAmp, Map)
do end		
CustomAmp = CustomAmp or 0

		local Freq = WindStrength ^ 0.8
		local Power = WindSpeed * 2
		local Seed = BoneTree.WindOffset

		local X = GetNoise(Freq, 0, Seed, Map) * (Power + CustomAmp)
		local Y = GetNoise(0, Freq, Seed, Map) * (Power + CustomAmp)
		local Z = GetNoise(Seed, 0, Freq, Map) * (Power + CustomAmp)
do end		
return WindDirection * Vector3.new(X, Y, Z)
	end
do end	

if Settings.WindType == "Sine" then
do end		
WindMove = SampleSin() * SampleGust()
do end	
elseif Settings.WindType == "Noise" then
do end		
WindMove = SampleNoise(0, true) * SampleGust()
do end	
elseif Settings.WindType == "Hybrid" then
do end		
WindMove = SampleSin() * SampleGust()
		WindMove += SampleNoise(0.5, true) * SampleGust()
		WindMove *= 0.5
do end	
end
do end
	
WindMove /= self.FreeLength < 0.01 and 0.01 or self.FreeLength
	WindMove *= (Settings.WindInfluence * (WindStrength * 0.01)) * (math.clamp(self.HeirarchyLength, 1, 10) * 0.1)
	WindMove *= self.Weight
do end	

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
--- @readonly
--- @prop RootPart BasePart

--- @within Bone
--- @readonly
--- @prop RootBone Bone

--- @within Bone
--- @prop Radius number

--- @within Bone
--- @prop Friction number

--- @within Bone
--- @prop RotationLimit number

--- @within Bone
--- @prop Force Vector3?

--- @within Bone
--- @prop Gravity Vector3?

--- @within Bone
--- @prop SolvedAnimatedCFrame boolean
--- Describes if this bone has already solved its animated world cframe, this is used for optimization.

--- @within Bone
--- @prop HasChild boolean

--- @within Bone
--- @readonly
--- @prop AnimatedWorldCFrame CFrame
--- Bone.TransformedWorldCFrame

--- @within Bone
--- @prop StartingCFrame CFrame

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
--- @prop LastPosition Vector3
--- Internal representation of the bone's position last frame

--- @within Bone
--- @prop WeldPosition Vector3

--- @within Bone
--- @prop WeldCFrame CFrame

--- @within Bone
--- @prop ActiveWeld boolean
--- Describes if this bone has a weld

--- @within Bone
--- @prop RigidWeld boolean
--- If the bone has a weld, is it rigid

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
--- @prop IsSkippingUpdates boolean

--- @within Bone
--- @prop CollisionHits {}

--- @within Bone
--- @prop CollisionData {}
--- Debug property, holds information about the collisions that the bone had this frame

local Class = {}
Class.__index = Class

function Class.new(Bone: Bone, RootBone: Bone, RootPart: BasePart): IBone
	local ParentCFrame = Bone.Parent:IsA("Bone") and Bone.Parent.TransformedWorldCFrame or RootPart.CFrame

	local self = setmetatable({
		Bone = Bone,
		FreeLength = -1,
		Weight = 0.7,
		ParentIndex = -1,
		HeirarchyLength = 0,
		Transform = Bone.TransformedWorldCFrame:ToObjectSpace(ParentCFrame):Inverse(),
		LocalTransform = Bone.TransformedCFrame:ToObjectSpace(RootBone.TransformedCFrame):Inverse(),
		RootPart = RootPart,
		RootBone = RootBone,
		Radius = 0,
		Friction = 0,
		RotationLimit = 0,
		Force = nil,
		Gravity = nil,

		SolvedAnimatedCFrame = false,
		HasChild = false,
		--NumberOfChildren = 0,
		--RotationSum = Vector3.zero,

		AnimatedWorldCFrame = Bone.TransformedWorldCFrame,
		StartingCFrame = Bone.TransformedCFrame,
		TransformOffset = CFrame.identity,
		LocalTransformOffset = CFrame.identity,
		RestPosition = Vector3.zero,
		CalculatedWorldCFrame = Bone.TransformedWorldCFrame,

		Position = Bone.TransformedWorldCFrame.Position,
		LastPosition = Bone.TransformedWorldCFrame.Position,

		WeldPosition = Vector3.zero,
		WeldCFrame = CFrame.identity,
		ActiveWeld = false,
		RigidWeld = false,

		Anchored = false,
		AxisLocked = { false, false, false },
		XAxisLimits = NumberRange.new(-math.huge, math.huge),
		YAxisLimits = NumberRange.new(-math.huge, math.huge),
		ZAxisLimits = NumberRange.new(-math.huge, math.huge),

		IsSkippingUpdates = false,

		CollisionHits = {},

		-- Debug
		CollisionsData = {},
	}, Class)

	self.AttributeConnection = Bone.AttributeChanged:Connect(function(Attribute)
		-- Do this cause of axis lock
		local Settings = Utilities.GatherBoneSettings(Bone)

		for k, v in Settings do
			-- ¬ represents a nil value, this is done so we can delete attributes at runtime.
			self[k] = (v ~= "¬") and v or nil
		end
	end)

	return self :: IBone
end

--- @within Bone
--- @param Position Vector3
--- @param Vector Vector3
--- Clips velocity on specified vector, Position is where we are at our current physics step (Before we set self.Position)
function Class:ClipVelocity(Position: Vector3, Vector: Vector3)
	self.LastPosition = ClipVector(self.LastPosition, Position, Vector)
end

--- @within Bone
--- @param BoneTree BoneTree
function Class:PreUpdate(BoneTree) -- Parallel safe
do end	
local Root = BoneTree.Bones[1]
	local Parent = BoneTree.Bones[self.ParentIndex]

	self.AnimatedWorldCFrame = QueryTransformedWorldCFrame(BoneTree, self)

	local SmartWeld = self.Bone:FindFirstChild("SmartWeld")

	-- Pyramid of weld
	self.ActiveWeld = false
	if SmartWeld then
		if SmartWeld:IsA("ObjectValue") then
			local WeldTo = SmartWeld.Value

			self.RigidWeld = (SmartWeld:GetAttribute("Rigid") == true) or false

			if WeldTo then
				if WeldTo:IsA("Attachment") then -- Attachment also covers bones
					self.WeldPosition = WeldTo.WorldPosition
					self.WeldCFrame = WeldTo.WorldCFrame
					self.ActiveWeld = true
				elseif WeldTo:IsA("BasePart") then
					self.WeldPosition = WeldTo.Position
					self.WeldCFrame = WeldTo.CFrame
					self.ActiveWeld = true
				end
			end
		end
	end

	if self.ParentIndex < 1 then -- Force anchor the root bone
		self.Anchored = true
	end

	if self.Bone == self.RootBone then
		-- Curse Non-SmartBone Objects!
		local ParentCFrame

		if self.Bone.Parent:IsA("Bone") then
			ParentCFrame = QueryTransformedWorldCFrameNonSmartbone(self.Bone.Parent)
		else
			ParentCFrame = self.RootPart.CFrame
		end

		self.TransformOffset = ParentCFrame * self.Transform
	else
		self.TransformOffset = Parent.AnimatedWorldCFrame * self.Transform
	end

	self.LocalTransformOffset = Root.Bone.CFrame * self.LocalTransform
do end
end

--- @within Bone
--- @param BoneTree BoneTree
--- @param Force Vector3
--- @param Delta number -- Δt
--- Force passed in via BoneTree:StepPhysics()
function Class:StepPhysics(BoneTree, Force: Vector3, Delta: number) -- Parallel safe
do end	
if self.Anchored then
		self.LastPosition = self.AnimatedWorldCFrame.Position
		self.Position = self.AnimatedWorldCFrame.Position
do end		

return
	end

	-- Custom forces per bone
	if self.Force or self.Gravity then
do end		
Force = (self.Gravity or BoneTree.Settings.Gravity)

		Force = (Force + (self.Force or BoneTree.Settings.Force)) * Delta
do end	
end
do end	

local Settings = BoneTree.Settings

	local Velocity = (self.Position - self.LastPosition)
	local Move = (BoneTree.ObjectAcceleration * Settings.Inertia)
	local WindMove = SolveWind(self, BoneTree, Velocity)

	self.LastPosition = self.Position
	self.Position += Velocity * (1 - Settings.Damping) + Force + Move + WindMove
do end do end

end

--- @within Bone
--- @param BoneTree BoneTree
--- @param ColliderObjects Vector3
--- @param Delta number -- Δt
function Class:Constrain(BoneTree, ColliderObjects, Delta: number) -- Parallel safe
do end	
if self.Anchored then
do end		
return
	end

	local Position = self.Position
	local RootPart = self.RootPart
	local RootCFrame: CFrame = RootPart.CFrame

	-- Friction must be first
	Position = FrictionConstraint(self, Position, self.LastPosition)

	if #ColliderObjects ~= 0 then
		Position = CollisionConstraint(self, Position, ColliderObjects)
	end

	if BoneTree.Settings.Constraint == "Spring" then
		Position = SpringConstraint(self, Position, nil, BoneTree, Delta)
	elseif BoneTree.Settings.Constraint == "Distance" then
		Position = DistanceConstraint(self, Position, BoneTree)
	elseif BoneTree.Settings.Constraint == "Rope" then
		Position = RopeConstraint(self, Position, BoneTree)
	else
		-- Go to anchored position if our constraint type is incorrect
		Position = self.AnimatedWorldCFrame.Position
	end

	Position = AxisConstraint(self, Position, self.LastPosition, RootCFrame)
	Position = RotationConstraint(self, Position, BoneTree)

	if self.ActiveWeld then
		if self.RigidWeld then
			-- Solve Transform has the rest of this implementation.
			Position = self.WeldPosition
		else
			Position = SpringConstraint(self, Position, self.WeldPosition, BoneTree, Delta)
		end
	end

	self.Friction = 0

	for _, HitPart in self.CollisionHits do
		-- Use whatever object has the higher friction
		local Friction = GetFriction(self.RootPart, HitPart)
		self.Friction = Friction < self.Friction and self.Friction or Friction
	end

	self.Position = Position
do end
end

--- @within Bone
--- Returns bone to rest position
function Class:SkipUpdate()
	if self.IsSkippingUpdates == false and Config.RESET_TRANSFORM_ON_SKIP then
		--SB_VERBOSE_LOG("Skipping bone, resetting transform.")
		self.CalculatedWorldCFrame = self.AnimatedWorldCFrame
		self.IsSkippingUpdates = true
	end

	self.LastPosition = self.AnimatedWorldCFrame.Position + (self.LastPosition - self.Position)
	self.Position = self.AnimatedWorldCFrame.Position
end

--- @within Bone
--- @param BoneTree BoneTree
--- @param Delta number -- Δt
--- Solves the cframe of the bones
function Class:SolveTransform(BoneTree, Delta: number) -- Parallel safe
do end	
if self.ParentIndex < 1 then
do end		
return
	end

	self.IsSkippingUpdates = false

	local ParentBone: IBone = BoneTree.Bones[self.ParentIndex]
	local BoneParent = ParentBone.Bone

	if ParentBone and BoneParent then
		local ReferenceCFrame = ParentBone.TransformOffset
		local v1 = self.Position - ParentBone.Position
		local Rotation = Utilities.GetRotationBetween(ReferenceCFrame.UpVector, v1).Rotation * ReferenceCFrame.Rotation

		local factor = 0.00001
		local alpha = math.min(1 - factor ^ Delta, 1)

		--local ShouldAverage = ParentBone.NumberOfChildren > 1

		if ParentBone.ActiveWeld and ParentBone.RigidWeld then
			ParentBone.CalculatedWorldCFrame = ParentBone.WeldCFrame
		--elseif ShouldAverage then
		--	ParentBone.RotationSum += Vector3.new(Rotation:ToEulerAnglesXYZ())
		else
			ParentBone.CalculatedWorldCFrame = BoneParent.WorldCFrame:Lerp(CFrame.new(ParentBone.Position) * Rotation, alpha)
			--ParentBone.CalculatedWorldCFrame = CFrame.new(ParentBone.Position) * Rotation
		end

		SB_ASSERT_CB(not IsNaN(ParentBone.CalculatedWorldCFrame.Position), warn, "If you see this report this as a bug, (NaN Calc world cframe)")
	end
do end
end

--- @within Bone
--- @param BoneTree BoneTree
--- Sets the world cframes of the bones to the calculated world cframe (solved in Bone:SolveTransform())
function Class:ApplyTransform(BoneTree)
do end
	
self.SolvedAnimatedCFrame = false

	if self.ParentIndex < 1 then
do end		
return
	end

	local ParentBone: IBone = BoneTree.Bones[self.ParentIndex]
	local BoneParent = ParentBone.Bone

	-- We check if the magnitude of rotation sum is zero because that tells us if it has already been averaged by another bone.
	-- if ParentBone.NumberOfChildren > 1 and ParentBone.RotationSum.Magnitude ~= 0 then
	-- 	local AverageRotation = ParentBone.RotationSum / ParentBone.NumberOfChildren
	-- 	ParentBone.CalculatedWorldCFrame = CFrame.new(ParentBone.Position)
	-- 		* CFrame.fromEulerAnglesXYZ(AverageRotation.X, AverageRotation.Y, AverageRotation.Z)
	-- 	ParentBone.RotationSum = Vector3.zero
	-- end

	if ParentBone and BoneParent then
		if ParentBone.Anchored and BoneTree.Settings.AnchorsRotate == false then -- Anchored and anchors do not rotate
			BoneParent.WorldCFrame = ParentBone.TransformOffset
		--elseif ParentBone.Anchored then -- Anchored and anchors rotate
		--	BoneParent.WorldCFrame = CFrame.new(ParentBone.Position) * ParentBone.CalculatedWorldCFrame.Rotation
		else -- Not anchored
			BoneParent.WorldCFrame = ParentBone.CalculatedWorldCFrame
		end
	end
do end
end

--- @client
--- @within Bone
--- @param BoneTree any
--- @param DRAW_CONTACTS boolean
--- @param DRAW_PHYSICAL_BONE boolean
--- @param DRAW_BONE boolean
--- @param DRAW_AXIS_LIMITS boolean
--- @param DRAW_ROTATION_LIMIT boolean
function Class:DrawDebug(BoneTree, DRAW_CONTACTS: bool, DRAW_PHYSICAL_BONE: bool, DRAW_BONE: bool, DRAW_AXIS_LIMITS: bool, DRAW_ROTATION_LIMIT: bool)
do end	
local BONE_POSITION_COLOR = Color3.fromRGB(255, 0, 0)
	local BONE_LAST_POSITION_COLOR = Color3.fromRGB(255, 94, 0)
	local BONE_POSITION_RAY_COLOR = Color3.fromRGB(234, 1, 255)
	local BONE_SPHERE_COLOR = Color3.fromRGB(0, 255, 255)
	local BONE_FRONT_ARROW_COLOR = Color3.fromRGB(255, 0, 0)
	local BONE_UP_ARROW_COLOR = Color3.fromRGB(0, 255, 0)
	local BONE_RIGHT_ARROW_COLOR = Color3.fromRGB(0, 0, 255)
	local ROTATION_CONE_COLOR = Color3.fromRGB(0, 183, 255)
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

	local ROTATION_CONE_LENGTH = 1

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

	-- Draw rotation limit

	if DRAW_ROTATION_LIMIT and self.RotationLimit < 180 and self.RotationLimit > 0 and self.ParentIndex > 0 and self.HasChild then
		local ConeRadius
		local InverseDirection = 1
		if self.RotationLimit < 89.5 then
			ConeRadius = ROTATION_CONE_LENGTH * math.tan(math.rad(self.RotationLimit))
		elseif self.RotationLimit > 90 then
			InverseDirection = -1			
ConeRadius = ROTATION_CONE_LENGTH * math.tan(math.rad(180 - self.RotationLimit))
		else
			ROTATION_CONE_LENGTH = 0
			ConeRadius = 5
		end

		ConeRadius = math.min(ConeRadius, 5)

		if ConeRadius == 5 then
			ROTATION_CONE_LENGTH = 0
		end

		local ConeDirection = (self.Position - BoneTree.Bones[self.ParentIndex].Position).Unit * InverseDirection

		local NewBoneCFrame =
			CFrame.lookAt(BonePosition + ConeDirection * (ROTATION_CONE_LENGTH * 0.5), BonePosition + -ConeDirection * 500, BoneCFrame.LookVector)

		Gizmo.PushProperty("Color3", ROTATION_CONE_COLOR)
		Gizmo.Cone:Draw(NewBoneCFrame, ConeRadius, ROTATION_CONE_LENGTH, 8 + ConeRadius * 2)
	end
do end

end

--- @client
--- @within Bone
function Class:DrawOverlay(Overlay: ImOverlay)
	Overlay.Text(`Bone: {self.Bone.Name}`)

	if Config.DEBUG_OVERLAY_BONE_INFO or Config.DEBUG_OVERLAY_BONE_NUMERICS then
		Overlay.Text(`Free Length: {self.FreeLength}`)
		Overlay.Text(`Weight: {self.Weight}`)
		Overlay.Text(`Parent Index: {self.ParentIndex}`)
		Overlay.Text(`Heirarchy Length: {self.HeirarchyLength}`)
		Overlay.Text(`Radius: {self.Radius}`)
		Overlay.Text(`Friction: {self.Friction}`)
		Overlay.Text(`Rotation Limit: {self.RotationLimit}`)
	end

	if Config.DEBUG_OVERLAY_BONE_INFO or Config.DEBUG_OVERLAY_BONE_CONSTRAIN then
		Overlay.Text(`Anchored: {self.Anchored}`)
		Overlay.Text(`Axis Locked: {self.AxisLocked[1]}, {self.AxisLocked[2]}, {self.AxisLocked[3]}`)
		Overlay.Text(`X Axis Limit: {self.XAxisLimits}`)
		Overlay.Text(`Y Axis Limit: {self.YAxisLimits}`)
		Overlay.Text(`Z Axis Limit: {self.ZAxisLimits}`)
	end

	if Config.DEBUG_OVERLAY_BONE_INFO or Config.DEBUG_OVERLAY_BONE_WELD then
		Overlay.Text(`Active Weld: {self.ActiveWeld}`)
		Overlay.Text(`Rigid Weld: {self.RigidWeld}`)
		Overlay.Text(`Weld Position: {string.format("%.3f, %.3f, %.3f", self.WeldPosition.X, self.WeldPosition.Y, self.WeldPosition.Z)}`)
	end

	if Config.DEBUG_OVERLAY_BONE_INFO or Config.DEBUG_OVERLAY_BONE_FORCES then
		local Force = self.Force and string.format("%.3f, %.3f, %.3f", self.Force.X, self.Force.Y, self.Force.Z) or "-, -, -"
		local Gravity = self.Gravity and string.format("%.3f, %.3f, %.3f", self.Gravity.X, self.Gravity.Y, self.Gravity.Z) or "-, -, -"

		Overlay.Text(`Force: {Force}`)
		Overlay.Text(`Gravity: {Gravity}`)
	end
end

function Class:Destroy()
	if Config.RESET_BONE_ON_DESTROY then
		task.synchronize()
		self.Bone.CFrame = self.StartingCFrame
	end

	self.AttributeConnection:Disconnect()

	setmetatable(self, nil)
end

return Class
