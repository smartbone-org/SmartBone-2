local Terrain = workspace.Terrain

--- @class VolumeCylinder
--- Renders a CylinderHandleAdornment.
local Gizmo = {}
Gizmo.__index = Gizmo

function Gizmo.Init(Ceive, Propertys, Request, Release, Retain, Register)
	local self = setmetatable({}, Gizmo)

	self.Ceive = Ceive
	self.Propertys = Propertys
	self.Request = Request
	self.Release = Release
	self.Retain = Retain
	self.Register = Register

	return self
end

--- @within VolumeCylinder
--- @function Draw
--- @param Transform CFrame
--- @param Radius number
--- @param Length number
--- @param InnerRadius number?
--- @param Angle number?
function Gizmo:Draw(Transform: CFrame, Radius: number, Length: number, InnerRadius: number?, Angle: number?)
	local Ceive = self.Ceive

	if not Ceive.Enabled then
		return
	end

	local Cylinder = self.Request("CylinderHandleAdornment")
	Cylinder.Color3 = self.Propertys.Color3
	Cylinder.Transparency = self.Propertys.Transparency

	Cylinder.CFrame = Transform
	Cylinder.Height = Length
	Cylinder.Radius = Radius
	Cylinder.InnerRadius = InnerRadius or 0
	Cylinder.Angle = Angle or 360
	Cylinder.AlwaysOnTop = self.Propertys.AlwaysOnTop
	Cylinder.ZIndex = 1
	Cylinder.Adornee = Terrain
	Cylinder.Parent = Terrain

	Ceive.ActiveInstances += 1

	self.Register(Cylinder)
end

--- @within VolumeCylinder
--- @function Create
--- @param Transform CFrame
--- @param Radius number
--- @param Length number
--- @param InnerRadius number?
--- @param Angle number?
--- @return {Transform: CFrame, Radius: number, Length: number, InnerRadius: number?, Angle: number?, Color3: Color3, AlwaysOnTop: boolean, Transparency: number, Enabled: boolean, Destroy: boolean}
function Gizmo:Create(Transform: CFrame, Radius: number, Length: number, InnerRadius: number?, Angle: number?)
	local PropertyTable = {
		Transform = Transform,
		Radius = Radius,
		Length = Length,
		InnerRadius = InnerRadius or 0,
		Angle = Angle or 360,
		AlwaysOnTop = self.Propertys.AlwaysOnTop,
		Transparency = self.Propertys.Transparency,
		Color3 = self.Propertys.Color3,
		Enabled = true,
		Destroy = false,
	}

	self.Retain(self, PropertyTable)

	return PropertyTable
end

function Gizmo:Update(PropertyTable)
	local Ceive = self.Ceive

	Ceive.PushProperty("AlwaysOnTop", PropertyTable.AlwaysOnTop)
	Ceive.PushProperty("Transparency", PropertyTable.Transparency)
	Ceive.PushProperty("Color3", PropertyTable.Color3)

	self:Draw(PropertyTable.Transform, PropertyTable.Radius, PropertyTable.Length, PropertyTable.InnerRadius, PropertyTable.Angle)
end

return Gizmo