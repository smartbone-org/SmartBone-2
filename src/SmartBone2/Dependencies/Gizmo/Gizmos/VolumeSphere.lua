local Terrain = workspace.Terrain

--- @class VolumeSphere
--- Renders a SphereHandleAdornment.
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

--- @within VolumeSphere
--- @function Draw
--- @param Transform CFrame
--- @param Radius number
function Gizmo:Draw(Transform: CFrame, Radius: number)
	local Ceive = self.Ceive

	if not Ceive.Enabled then
		return
	end

	local Sphere = self.Request("SphereHandleAdornment")
	Sphere.Color3 = self.Propertys.Color3
	Sphere.Transparency = self.Propertys.Transparency

	Sphere.CFrame = Transform
	Sphere.Radius = Radius
	Sphere.AlwaysOnTop = self.Propertys.AlwaysOnTop
	Sphere.ZIndex = 1
	Sphere.Adornee = Terrain
	Sphere.Parent = Terrain

	Ceive.ActiveInstances += 1

	self.Register(Sphere)
end

--- @within VolumeSphere
--- @function Create
--- @param Transform CFrame
--- @param Radius number
--- @return {Transform: CFrame, Radius: number, Color3: Color3, AlwaysOnTop: boolean, Transparency: number, Enabled: boolean, Destroy: boolean}
function Gizmo:Create(Transform: CFrame, Radius: number)
	local PropertyTable = {
		Transform = Transform,
		Radius = Radius,
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

	self:Draw(PropertyTable.Transform, PropertyTable.Radius)
end

return Gizmo