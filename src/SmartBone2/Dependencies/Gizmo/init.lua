--!nocheck

-- CeiveImGizmo
-- https://github.com/JakeyWasTaken/CeiveImGizmo

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Terrain = workspace.Terrain

local AOTWireframeHandle: WireframeHandleAdornment = Terrain:FindFirstChild("AOTGizmoAdornment")
local WireframeHandle: WireframeHandleAdornment = Terrain:FindFirstChild("GizmoAdornment")

if not AOTWireframeHandle then
	AOTWireframeHandle = Instance.new("WireframeHandleAdornment")
	AOTWireframeHandle.Adornee = Terrain
	AOTWireframeHandle.ZIndex = 1
	AOTWireframeHandle.AlwaysOnTop = true
	AOTWireframeHandle.Name = "AOTGizmoAdornment"
	AOTWireframeHandle.Parent = Terrain
end

if not WireframeHandle then
	WireframeHandle = Instance.new("WireframeHandleAdornment")
	WireframeHandle.Adornee = Terrain
	WireframeHandle.ZIndex = 1
	WireframeHandle.AlwaysOnTop = false
	WireframeHandle.Name = "GizmoAdornment"
	WireframeHandle.Parent = Terrain
end

local Gizmos = script:WaitForChild("Gizmos")

local ActiveObjects = {}
local RetainObjects = {}
local Debris = {}
local Tweens = {}
local PropertyTable = { AlwaysOnTop = true }
local Pool = {}

local CleanerScheduled = false

local function Retain(Gizmo, GizmoProperties)
	table.insert(RetainObjects, { Gizmo, GizmoProperties })
end

local function Register(object)
	table.insert(ActiveObjects, object)
end

local function Release(object)
	local ClassName = object.ClassName

	if not Pool[ClassName] then
		Pool[ClassName] = {}
	end

	object:Remove()
	table.insert(Pool[ClassName], object)
end

local function Request(ClassName)
	if not Pool[ClassName] then
		return Instance.new(ClassName)
	elseif not Pool[ClassName][1] then
		return Instance.new(ClassName)
	end

	local Object = Pool[ClassName][1]
	table.remove(Pool[ClassName], 1)

	return Object
end

local function Lerp(a, b, t)
	return a + (b - a) * t
end

local function deepCopy(original)
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then
			v = deepCopy(v)
		end
		copy[k] = v
	end
	return copy
end

-- Types

type IRay = {
	Draw: (self: IRay, Origin: Vector3, End: Vector3) -> (),
	Create: (
		self: IRay,
		Origin: Vector3,
		End: Vector3
	) -> { Origin: Vector3, End: Vector3, Color3: Color3, AlwaysOnTop: boolean, Transparency: number },
}

type IBox = {
	Draw: (self: IBox, Transform: CFrame, Size: Vector3, DrawTriangles: boolean) -> (),
	Create: (
		self: IBox,
		Transform: CFrame,
		Size: Vector3,
		DrawTriangles: boolean
	) -> {
		Transform: CFrame,
		Size: Vector3,
		DrawTriangles: boolean,
		Color3: Color3,
		AlwaysOnTop: boolean,
		Transparency: number,
		Enabled: boolean,
		Destroy: boolean,
	},
}

type IPlane = {
	Draw: (self: IPlane, Position: Vector3, Normal: Vector3, Size: Vector3) -> (),
	Create: (
		self: IPlane,
		Position: Vector3,
		Normal: Vector3,
		Size: Vector3
	) -> {
		Position: Vector3,
		Normal: Vector3,
		Size: Vector3,
		DrawTriangles: boolean,
		Color3: Color3,
		AlwaysOnTop: boolean,
		Transparency: number,
		Enabled: boolean,
		Destroy: boolean,
	},
}

type IWedge = {
	Draw: (self: IWedge, Transform: CFrame, Size: Vector3, DrawTriangles: boolean) -> (),
	Create: (
		self: IWedge,
		Transform: CFrame,
		Size: Vector3,
		DrawTriangles: boolean
	) -> {
		Transform: CFrame,
		Size: Vector3,
		DrawTriangles: boolean,
		Color3: Color3,
		AlwaysOnTop: boolean,
		Transparency: number,
		Enabled: boolean,
		Destroy: boolean,
	},
}

type ICircle = {
	Draw: (self: ICircle, Transform: CFrame, Radius: number, Subdivisions: number, ConnectToStart: boolean?) -> (),
	Create: (
		self: ICircle,
		Transform: CFrame,
		Radius: number,
		Subdivisions: number,
		ConnectToStart: boolean?
	) -> {
		Transform: CFrame,
		Radius: number,
		Subdivisions: number,
		ConnectToStart: boolean?,
		Color3: Color3,
		AlwaysOnTop: boolean,
		Transparency: number,
		Enabled: boolean,
		Destroy: boolean,
	},
}

type ISphere = {
	Draw: (self: ISphere, Transform: CFrame, Radius: number, Subdivisions: number, Angle: number) -> (),
	Create: (
		self: ISphere,
		Transform: CFrame,
		Radius: number,
		Subdivisions: number,
		Angle: number
	) -> {
		Transform: CFrame,
		Radius: number,
		Subdivisions: number,
		Angle: number,
		Color3: Color3,
		AlwaysOnTop: boolean,
		Transparency: number,
		Enabled: boolean,
		Destroy: boolean,
	},
}

type ICylinder = {
	Draw: (self: ICylinder, Transform: CFrame, Radius: number, Length: number, Subdivisions: number) -> (),
	Create: (
		self: ICylinder,
		Transform: CFrame,
		Radius: number,
		Length: number,
		Subdivisions: number
	) -> {
		Transform: CFrame,
		Radius: number,
		Length: number,
		Subdivisions: number,
		Color3: Color3,
		AlwaysOnTop: boolean,
		Transparency: number,
		Enabled: boolean,
		Destroy: boolean,
	},
}

type ICapsule = {
	Draw: (self: ICapsule, Transform: CFrame, Radius: number, Length: number, Subdivisions: number) -> (),
	Create: (
		self: ICapsule,
		Transform: CFrame,
		Radius: number,
		Length: number,
		Subdivisions: number
	) -> {
		Transform: CFrame,
		Radius: number,
		Length: number,
		Subdivisions: number,
		Color3: Color3,
		AlwaysOnTop: boolean,
		Transparency: number,
		Enabled: boolean,
		Destroy: boolean,
	},
}

type ICone = {
	Draw: (self: ICone, Transform: CFrame, Radius: number, Length: number, Subdivisions: number) -> (),
	Create: (
		self: ICone,
		Transform: CFrame,
		Radius: number,
		Length: number,
		Subdivisions: number
	) -> {
		Transform: CFrame,
		Radius: number,
		Length: number,
		Subdivisions: number,
		Color3: Color3,
		AlwaysOnTop: boolean,
		Transparency: number,
		Enabled: boolean,
		Destroy: boolean,
	},
}

type IArrow = {
	Draw: (self: IArrow, Origin: Vector3, End: Vector3, Radius: number, Length: number, Subdivisions: number) -> (),
	Create: (
		self: IArrow,
		Origin: Vector3,
		End: Vector3,
		Radius: number,
		Length: number,
		Subdivisions: number
	) -> {
		Origin: Vector3,
		End: Vector3,
		Radius: number,
		Length: number,
		Subdivisions: number,
		Color3: Color3,
		AlwaysOnTop: boolean,
		Transparency: number,
		Enabled: boolean,
		Destroy: boolean,
	},
}

type IMesh = {
	Draw: (self: IMesh, Transform: CFrame, Size: Vector3, Vertices: {}, Faces: {}) -> (),
	Create: (
		self: IMesh,
		Transform: CFrame,
		Size: Vector3,
		Vertices: {},
		Faces: {}
	) -> {
		Transform: CFrame,
		Size: Vector3,
		Vertices: {},
		Faces: {},
		Color3: Color3,
		AlwaysOnTop: boolean,
		Transparency: number,
		Enabled: boolean,
		Destroy: boolean,
	},
}

type ILine = {
	Draw: (self: ILine, Transform: CFrame, Length: number) -> (),
	Create: (
		self: ILine,
		Transform: CFrame,
		Length: number
	) -> { Transform: CFrame, Length: number, Color3: Color3, AlwaysOnTop: boolean, Transparency: number, Enabled: boolean, Destroy: boolean },
}

type IVolumeCone = {
	Draw: (self: IVolumeCone, Transform: CFrame, Radius: number, Length: number) -> (),
	Create: (
		self: IVolumeCone,
		Transform: CFrame,
		Radius: number,
		Length: number
	) -> {
		Transform: CFrame,
		Radius: number,
		Length: number,
		Color3: Color3,
		AlwaysOnTop: boolean,
		Transparency: number,
		Enabled: boolean,
		Destroy: boolean,
	},
}

type IVolumeBox = {
	Draw: (self: IVolumeBox, Transform: CFrame, Size: Vector3) -> (),
	Create: (
		self: IVolumeBox,
		Transform: CFrame,
		Size: Vector3
	) -> { Transform: CFrame, Size: Vector3, Color3: Color3, AlwaysOnTop: boolean, Transparency: number, Enabled: boolean, Destroy: boolean },
}

type IVolumeSphere = {
	Draw: (self: IVolumeSphere, Transform: CFrame, Radius: number) -> (),
	Create: (
		self: IVolumeSphere,
		Transform: CFrame,
		Radius: number
	) -> { Transform: CFrame, Radius: number, Color3: Color3, AlwaysOnTop: boolean, Transparency: number, Enabled: boolean, Destroy: boolean },
}

type IVolumeCylinder = {
	Draw: (self: IVolumeCylinder, Transform: CFrame, Radius: number, Length: number, InnerRadius: number?, Angle: number?) -> (),
	Create: (
		self: IVolumeCylinder,
		Transform: CFrame,
		Radius: number,
		Length: number,
		InnerRadius: number?,
		Angle: number?
	) -> {
		Transform: CFrame,
		Radius: number,
		Length: number,
		InnerRadius: number?,
		Angle: number?,
		Color3: Color3,
		AlwaysOnTop: boolean,
		Transparency: number,
		Enabled: boolean,
		Destroy: boolean,
	},
}

type IVolumeArrow = {
	Draw: (self: IVolumeArrow, Origin: Vector3, End: Vector3, CylinderRadius: number, ConeRadius: number, Length: number, UseCylinder: boolean?) -> (),
	Create: (
		self: IVolumeArrow,
		Origin: Vector3,
		End: Vector3,
		CylinderRadius: number,
		ConeRadius: number,
		Length: number,
		UseCylinder: boolean?
	) -> {
		Origin: Vector3,
		End: Vector3,
		CylinderRadius: number,
		ConeRadius: number,
		Length: number,
		UseCylinder: boolean?,
		Color3: Color3,
		AlwaysOnTop: boolean,
		Transparency: number,
		Enabled: boolean,
		Destroy: boolean,
	},
}

type IStyles = {
	Color: string,
	Transparency: number,
	AlwaysOnTop: boolean,
}

type ICeive = {
	ActiveRays: number,
	ActiveInstances: number,

	PushProperty: (Property: string, Value: any?) -> (),
	PopProperty: (Property: string) -> any?,
	SetStyle: (Color: Color3?, Transparency: number?, AlwaysOnTop: boolean?) -> (),
	AddDebrisInSeconds: (Seconds: number, Callback: () -> ()) -> (),
	AddDebrisInFrames: (Frames: number, Callback: () -> ()) -> (),
	SetEnabled: (Value: boolean) -> (),
	DoCleaning: () -> (),
	ScheduleCleaning: () -> (),
	TweenProperies: (Properties: {}, Goal: {}, TweenInfo: TweenInfo) -> () -> (),
	Init: () -> (),

	Styles: IStyles,

	Ray: IRay,
	Line: ILine,
	Box: IBox,
	Plane: IPlane,
	Wedge: IWedge,
	Circle: ICircle,
	Sphere: ISphere,
	Cylinder: ICylinder,
	Capsule: ICapsule,
	Cone: ICone,
	Arrow: IArrow,
	Mesh: IMesh,
	VolumeCone: IVolumeCone,
	VolumeBox: IVolumeBox,
	VolumeSphere: IVolumeSphere,
	VolumeCylinder: IVolumeCylinder,
	VolumeArrow: IVolumeArrow,
}

-- Ceive

local Styles = {
	Color = "Color3",
	Transparency = "Transparency",
	AlwaysOnTop = "AlwaysOnTop",
}

local Ceive: ICeive = {
	Enabled = true,
	ActiveRays = 0,
	ActiveInstances = 0,

	Styles = Styles,

	AOTWireframeHandle = AOTWireframeHandle,
	WireframeHandle = WireframeHandle,
}

function Ceive.GetPoolSize(): number
	local n = 0

	for _, t in Pool do
		n += #t
	end

	return n
end

function Ceive.PushProperty(Property, Value)
	PropertyTable[Property] = Value

	if Property == "AlwaysOnTop" then
		return
	end

	pcall(function()
		AOTWireframeHandle[Property] = Value
		WireframeHandle[Property] = Value
	end)
end

function Ceive.PopProperty(Property): any
	if PropertyTable[Property] then
		return PropertyTable[Property]
	end

	return AOTWireframeHandle[Property]
end

function Ceive.SetStyle(Color, Transparency, AlwaysOnTop)
	if Color and typeof(Color) == "Color3" then
		Ceive.PushProperty("Color3", Color)
	end

	if Transparency and typeof(Transparency) == "number" then
		Ceive.PushProperty("Transparency", Transparency)
	end

	if AlwaysOnTop and typeof(AlwaysOnTop) == "boolean" then
		Ceive.PushProperty("AlwaysOnTop", AlwaysOnTop)
	end
end

function Ceive.DoCleaning()
	AOTWireframeHandle:Clear()
	WireframeHandle:Clear()

	for _, Object in ActiveObjects do
		Release(Object)
	end

	ActiveObjects = {}

	Ceive.ActiveRays = 0
	Ceive.ActiveInstances = 0
end

function Ceive.ScheduleCleaning()
	if CleanerScheduled then
		return
	end

	CleanerScheduled = true

	task.delay(0, function()
		Ceive.DoCleaning()

		CleanerScheduled = false
	end)
end

function Ceive.AddDebrisInSeconds(Seconds: number, Callback)
	table.insert(Debris, { "Seconds", Seconds, os.clock(), Callback })
end

function Ceive.AddDebrisInFrames(Frames: number, Callback)
	table.insert(Debris, { "Frames", Frames, 0, Callback })
end

function Ceive.TweenProperties(Properties: {}, Goal: {}, TweenInfo: TweenInfo): () -> ()
	local p_Properties = Properties
	local c_Properties = deepCopy(Properties)

	table.insert(Tweens, {
		p_Properties = p_Properties,
		Properties = c_Properties,
		Goal = Goal,
		TweenInfo = TweenInfo,
		Time = 0,
	})

	local TweenIndex = #Tweens

	return function()
		table.remove(Tweens, TweenIndex)
	end
end

function Ceive.Init()
	RunService.RenderStepped:Connect(function(dt)
		for i, Tween in Tweens do
			Tween.Time += dt
			local Alpha = Tween.Time / Tween.TweenInfo.Time

			if Alpha > 1 then
				Alpha = 1
			end

			local function LerpProperty(Start, End, Time)
				if type(Start) == "number" then
					return Lerp(Start, End, Time)
				end

				return Start:Lerp(End, Time)
			end

			for k, v in Tween.Properties do
				if not Tween.Goal[k] then
					continue
				end

				local TweenAlpha = TweenService:GetValue(Alpha, Tween.TweenInfo.EasingStyle, Tween.TweenInfo.EasingDirection)
				local PropertyValue = LerpProperty(v, Tween.Goal[k], TweenAlpha)

				Tween.p_Properties[k] = PropertyValue
			end

			if Alpha == 1 then
				table.remove(Tweens, i)
			end
		end

		for i, DebrisObject in Debris do
			local DebrisType = DebrisObject[1]
			local DebrisLifetime = DebrisObject[2]
			local DebrisBirth = DebrisObject[3]
			local DebrisCallback = DebrisObject[4]

			if DebrisType == "Seconds" then
				if os.clock() - DebrisBirth > DebrisLifetime then
					table.remove(Debris, i)
					continue
				end

				DebrisCallback()

				continue
			end

			if DebrisBirth > DebrisLifetime then
				table.remove(Debris, i)
				continue
			end

			DebrisObject[2] += 1 -- Add 1 frame to the counter

			DebrisCallback()
		end

		for i, Gizmo in RetainObjects do
			local GizmoPropertys = Gizmo[2]

			if not GizmoPropertys.Enabled then
				continue
			end

			if GizmoPropertys.Destroy then
				table.remove(RetainObjects, i)
			end

			Gizmo[1]:Update(GizmoPropertys)
		end
	end)
end

function Ceive.SetEnabled(Value)
	Ceive.Enabled = Value

	if Value == false then
		Ceive.DoCleaning()
	end
end

-- Load Gizmos

for _, Gizmo in Gizmos:GetChildren() do
	Ceive[Gizmo.Name] = require(Gizmo).Init(Ceive, PropertyTable, Request, Release, Retain, Register)
end

return Ceive
