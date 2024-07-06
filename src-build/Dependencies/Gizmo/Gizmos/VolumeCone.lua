local Terrain = workspace.Terrain

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

function Gizmo:Draw(Transform: CFrame, Radius: number, Length: number)
	local Ceive = self.Ceive

	if not Ceive.Enabled then
		return
	end

	local Cone = self.Request("ConeHandleAdornment")
	Cone.Color3 = self.Propertys.Color3
	Cone.Transparency = self.Propertys.Transparency

	Cone.CFrame = Transform
	Cone.AlwaysOnTop = self.Propertys.AlwaysOnTop
	Cone.ZIndex = 1
	Cone.Height = Length
	Cone.Radius = Radius
	Cone.Adornee = Terrain
	Cone.Parent = Terrain

	Ceive.ActiveInstances += 1

	self.Register(Cone)
	self.Ceive.ScheduleCleaning()
end

function Gizmo:Create(Transform: CFrame, Radius: number, Length: number)
	local PropertyTable = {
		Transform = Transform,
		Radius = Radius,
		Length = Length,
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

	self:Draw(PropertyTable.Transform, PropertyTable.Radius, PropertyTable.Length)
end

return Gizmo
