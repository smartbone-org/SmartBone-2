--- @class Cylinder
--- Renders a wireframe cylinder.
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

--- @within Cylinder
--- @function Draw
--- @param Transform CFrame
--- @param Radius number
--- @param Length number
--- @param Subdivisions number
function Gizmo:Draw(Transform: CFrame, Radius: number, Length: number, Subdivisions: number)
	local Ceive = self.Ceive

	if not Ceive.Enabled then
		return
	end

	-- Draw top and bottom of cylinder
	local TopOfCylinder = Transform.Position + (Transform.UpVector * (Length / 2))
	local BottomOfCylinder = Transform.Position - (Transform.UpVector * (Length / 2))

	TopOfCylinder = CFrame.lookAt(TopOfCylinder, TopOfCylinder + Transform.UpVector)
	BottomOfCylinder = CFrame.lookAt(BottomOfCylinder, BottomOfCylinder - Transform.UpVector)

	-- Draw Cylinder Lines

	local AnglePerChunk = math.floor(360 / Subdivisions)

	local LastTop
	local LastBottom

	local FirstTop
	local FirstBottom

	for i = 0, 360, AnglePerChunk do
		local XMagnitude = math.sin(math.rad(i)) * Radius
		local YMagnitude = math.cos(math.rad(i)) * Radius

		local VertexOffset = (Transform.LookVector * YMagnitude) + (Transform.RightVector * XMagnitude)
		local TopVertexPosition = TopOfCylinder.Position + VertexOffset
		local BottomVertexPosition = BottomOfCylinder.Position + VertexOffset

		Ceive.Ray:Draw(TopVertexPosition, BottomVertexPosition)

		if not LastTop then
			LastTop = TopVertexPosition
			LastBottom = BottomVertexPosition

			FirstTop = TopVertexPosition
			FirstBottom = BottomVertexPosition

			continue
		end

		Ceive.Ray:Draw(LastTop, TopVertexPosition)
		Ceive.Ray:Draw(LastBottom, BottomVertexPosition)

		LastTop = TopVertexPosition
		LastBottom = BottomVertexPosition
	end

	Ceive.Ray:Draw(LastTop, FirstTop)
	Ceive.Ray:Draw(LastBottom, FirstBottom)
end

--- @within Cylinder
--- @function Create
--- @param Transform CFrame
--- @param Radius number
--- @param Length number
--- @param Subdivisions number
--- @return {Transform: CFrame, Radius: number, Length: number, Subdivisions: number, Color3: Color3, AlwaysOnTop: boolean, Transparency: number, Enabled: boolean, Destroy: boolean}
function Gizmo:Create(Transform: CFrame, Radius: number, Length: number, Subdivisions: number)
	local PropertyTable = {
		Transform = Transform,
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

	self:Draw(PropertyTable.Transform, PropertyTable.Radius, PropertyTable.Length, PropertyTable.Subdivisions)
end

return Gizmo