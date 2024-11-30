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

function Gizmo:Draw(Origin: Vector3, End: Vector3, CylinderRadius: number, ConeRadius: number, Length: number, UseCylinder: boolean?)
	local Ceive = self.Ceive

	if not Ceive.Enabled then
		return
	end

	local ArrowCFrame = CFrame.lookAt(End - (End - Origin).Unit * (Length * 0.5), End)

	if UseCylinder == true then
		local BottomCone = ArrowCFrame.Position
		local CylinderLength = (BottomCone - Origin).Magnitude
		local CylinderCFrame = CFrame.lookAt((Origin + BottomCone) * 0.5, End)

		Ceive.VolumeCylinder:Draw(CylinderCFrame, CylinderRadius, CylinderLength)
	else
		Ceive.Ray:Draw(Origin, End)
	end

	Ceive.VolumeCone:Draw(ArrowCFrame, ConeRadius, Length)
	self.Ceive.ScheduleCleaning()
end

function Gizmo:Create(Origin: Vector3, End: Vector3, CylinderRadius: number, ConeRadius: number, Length: number, UseCylinder: boolean?)
	local PropertyTable = {
		Origin = Origin,
		End = End,
		CylinderRadius = CylinderRadius,
		ConeRadius = ConeRadius,
		Length = Length,
		UseCylinder = UseCylinder,
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

	self:Draw(PropertyTable.Origin, PropertyTable.End, PropertyTable.Radius, PropertyTable.Length, PropertyTable.UseCylinder)
end

return Gizmo
