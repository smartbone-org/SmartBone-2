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

function Gizmo:Draw(Transform: CFrame, Size: Vector3)
	local Ceive = self.Ceive

	if not Ceive.Enabled then
		return
	end

	local Box = self.Request("BoxHandleAdornment")
	Box.Color3 = self.Propertys.Color3
	Box.Transparency = self.Propertys.Transparency

	Box.CFrame = Transform
	Box.Size = Size
	Box.AlwaysOnTop = self.Propertys.AlwaysOnTop
	Box.ZIndex = 1
	Box.Adornee = Terrain
	Box.Parent = Terrain

	Ceive.ActiveInstances += 1

	self.Register(Box)
	self.Ceive.ScheduleCleaning()
end

function Gizmo:Create(Transform: CFrame, Size: Vector3)
	local PropertyTable = {
		Transform = Transform,
		Size = Size,
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

	self:Draw(PropertyTable.Transform, PropertyTable.Size)
end

return Gizmo
