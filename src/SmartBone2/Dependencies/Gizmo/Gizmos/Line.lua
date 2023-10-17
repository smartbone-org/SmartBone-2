local Gizmo = {}
Gizmo.__index = Gizmo

function Gizmo.Init(Ceive, Propertys, Request, Release, Retain)
	local self = setmetatable({}, Gizmo)

	self.Ceive = Ceive
	self.Propertys = Propertys
	self.Request = Request
	self.Release = Release
	self.Retain = Retain

	return self
end

function Gizmo:Draw(Transform: CFrame, Length: number)
	local Ceive = self.Ceive

	if not Ceive.Enabled then
		return
	end

	local Origin = Transform.Position + (Transform.LookVector * (-Length * 0.5))
	local End = Transform.Position + (Transform.LookVector * (Length * 0.5))

	Ceive.Ray:Draw(Origin, End)
end

function Gizmo:Create(Transform: CFrame, Length: number)
	local PropertyTable = {
		Transform = Transform,
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

	self:Draw(PropertyTable.Transform, PropertyTable.Length)
end

return Gizmo
