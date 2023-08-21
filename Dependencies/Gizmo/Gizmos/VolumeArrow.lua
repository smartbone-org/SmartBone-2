--- @class VolumeArrow
--- Renders an arrow with a ConeHandleAdornment instead of a wireframe cone.
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

--- @within VolumeArrow
--- @function Draw
--- @param Origin Vector3
--- @param End Vector3
--- @param CylinderRadius number
--- @param ConeRadius number
--- @param Length number
--- @param UseCylinder boolean?
function Gizmo:Draw(Origin: Vector3, End: Vector3, CylinderRadius: number, ConeRadius: number, Length: number, UseCylinder: boolean?)
	local Ceive = self.Ceive

	if not Ceive.Enabled then
		return
	end
	
	local ArrowCFrame = CFrame.lookAt(End - (End - Origin).Unit * (Length / 2), End)

	if UseCylinder == true then
		local Direction = (End - Origin).Unit
		local BottomCone = ArrowCFrame.Position
		local CylinderLength = (BottomCone - Origin).Magnitude
		local CylinderCFrame = CFrame.lookAt( (Origin + BottomCone) / 2, End )

		Ceive.VolumeCylinder:Draw(CylinderCFrame, CylinderRadius, CylinderLength)
	else
		Ceive.Ray:Draw(Origin, End)
	end

	Ceive.VolumeCone:Draw(ArrowCFrame, ConeRadius, Length)
end

--- @within VolumeArrow
--- @function Create
--- @param Origin Vector3
--- @param End Vector3
--- @param CylinderRadius number
--- @param ConeRadius number
--- @param Length number
--- @param UseCylinder boolean?
--- @return {Origin: Vector3, End: Vector3, CylinderRadius: number, ConeRadius: number, Length: number,  UseCylinder: boolean?, Color3: Color3, AlwaysOnTop: boolean, Transparency: number, Enabled: boolean, Destroy: boolean}
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