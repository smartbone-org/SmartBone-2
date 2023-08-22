--- @class Arrow
--- Renders a wireframe arrow.
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


--- @within Arrow
--- @function Draw
--- @param Origin Vector3
--- @param End Vector3
--- @param Radius number
--- @param Length number
--- @param Subdivisions number
function Gizmo:Draw(Origin: Vector3, End: Vector3, Radius: number, Length: number, Subdivisions: number)
	local Ceive = self.Ceive

	if not Ceive.Enabled then
		return
	end

	Ceive.Ray:Draw(Origin, End)

	local ArrowCFrame = CFrame.lookAt(End + ((Origin - End).Unit * (Length / 2)), End)
	Ceive.Cone:Draw(ArrowCFrame, Radius, Length, Subdivisions)
end

--- @within Arrow
--- @function Create
--- @param Origin Vector3
--- @param End Vector3
--- @param Radius number
--- @param Length number
--- @param Subdivisions number
--- @return {Origin: Vector3, End: Vector3, Radius: number, Length: number, Subdivisions: number, Color3: Color3, AlwaysOnTop: boolean, Transparency: number, Enabled: boolean, Destroy: boolean}

function Gizmo:Create(Origin: Vector3, End: Vector3, Radius: number, Length: number, Subdivisions: number)
	local PropertyTable = {
		Origin = Origin,
		End = End,
		Radius = Radius,
		Length = Length,
		Subdivisions = Subdivisions,
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

	self:Draw(PropertyTable.Origin, PropertyTable.End, PropertyTable.Radius, PropertyTable.Length, PropertyTable.Subdivisions)
end

return Gizmo