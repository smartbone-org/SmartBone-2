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

function Gizmo:Draw(Transform: CFrame, Radius: number, Subdivisions: number, Angle: number, ConnectToStart: boolean?)
	local Ceive = self.Ceive

	if not Ceive.Enabled then
		return
	end

	local AnglePerChunk = math.floor(Angle / Subdivisions)

	local PreviousVertex 	
local FirstVertex 
	
local FinishingAngle = 0

	for i = 0, Angle, AnglePerChunk do
		local XMagnitude = math.sin(math.rad(i)) * Radius
		local YMagnitude = math.cos(math.rad(i)) * Radius

		local VertexPosition = Transform.Position + ((Transform.UpVector * YMagnitude) + (Transform.RightVector * XMagnitude))

		if PreviousVertex == nil then
			PreviousVertex = VertexPosition
			FirstVertex = VertexPosition
			FinishingAngle = i
			continue
		end

		Ceive.Ray:Draw(PreviousVertex, VertexPosition)
		PreviousVertex = VertexPosition
		FinishingAngle = i
	end

	if FinishingAngle ~= Angle then
		local XMagnitude = math.sin(math.rad(Angle)) * Radius
		local YMagnitude = math.cos(math.rad(Angle)) * Radius

		local VertexPosition = Transform.Position + ((Transform.UpVector * YMagnitude) + (Transform.RightVector * XMagnitude))

		Ceive.Ray:Draw(PreviousVertex, VertexPosition)
	end

	if ConnectToStart ~= false then
		Ceive.Ray:Draw(PreviousVertex, FirstVertex)
	end

	return PreviousVertex
end

function Gizmo:Create(Transform: CFrame, Radius: number, Subdivisions: number, Angle: number, ConnectToStart: boolean?)
	local PropertyTable = {
		Transform = Transform,
		Radius = Radius,
		Subdivisions = Subdivisions,
		Angle = Angle,
		ConnectToStart = ConnectToStart,
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

	self:Draw(PropertyTable.Transform, PropertyTable.Radius, PropertyTable.Subdivisions, PropertyTable.Angle, PropertyTable.ConnectToStart)
end

return Gizmo
