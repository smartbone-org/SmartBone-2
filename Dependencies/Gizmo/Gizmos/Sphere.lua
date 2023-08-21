local Rad90D = math.rad(90)

--- @class Sphere
--- Renders a wireframe sphere.
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

--- @within Sphere
--- @function Draw
--- @param Transform CFrame
--- @param Radius number
--- @param Subdivisions number
--- @param Angle number
function Gizmo:Draw(Transform: CFrame, Radius: number, Subdivisions: number, Angle: number)
	local Ceive = self.Ceive

	if not Ceive.Enabled then
		return
	end

	Ceive.Circle:Draw(Transform, Radius, Subdivisions, Angle)
	Ceive.Circle:Draw(Transform * CFrame.Angles(0, Rad90D, 0), Radius, Subdivisions, Angle)
	Ceive.Circle:Draw(Transform * CFrame.Angles(Rad90D, 0, 0), Radius, Subdivisions, Angle)
end

--- @within Sphere
--- @function Create
--- @param Transform CFrame
--- @param Radius number
--- @param Subdivisions number
--- @param Angle number
--- @return {Transform: CFrame, Radius: number, Subdivisions: number, Angle: number, Color3: Color3, AlwaysOnTop: boolean, Transparency: number, Enabled: boolean, Destroy: boolean}
function Gizmo:Create(Transform: CFrame, Radius: number, Subdivisions: number, Angle: number)
	local PropertyTable = {
		Transform = Transform,
		Radius = Radius,
		Subdivisions = Subdivisions,
		Angle = Angle,
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

	self:Draw(PropertyTable.Transform, PropertyTable.Radius, PropertyTable.Subdivisions, PropertyTable.Angle)
end

return Gizmo