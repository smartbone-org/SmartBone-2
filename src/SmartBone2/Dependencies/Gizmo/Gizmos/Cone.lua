local Rad90D = math.rad(90)

--- @class Cone
--- Renders a wireframe cone.
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

--- @within Cone
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

	Transform *= CFrame.Angles(-Rad90D, 0, 0)

	local TopOfCone = Transform.Position + Transform.UpVector * (Length / 2)
	local BottomOfCone = Transform.Position + -Transform.UpVector * (Length / 2)

	TopOfCone = CFrame.lookAt(TopOfCone, TopOfCone + Transform.UpVector)
	BottomOfCone = CFrame.lookAt(BottomOfCone, BottomOfCone - Transform.UpVector)

	local AnglePerChunk = math.floor(360 / Subdivisions)

	local Last
	local First

	for i = 0, 360, AnglePerChunk do
		local XMagnitude = math.sin(math.rad(i)) * Radius
		local YMagnitude = math.cos(math.rad(i)) * Radius

		local VertexOffset = (Transform.LookVector * YMagnitude) + (Transform.RightVector * XMagnitude)
		local VertexPosition = BottomOfCone.Position + VertexOffset

		if not Last then
			Last = VertexPosition
			First = VertexPosition

			Ceive.Ray:Draw(VertexPosition, TopOfCone.Position)

			continue
		end

		Ceive.Ray:Draw(VertexPosition, TopOfCone.Position)
		Ceive.Ray:Draw(Last, VertexPosition)

		Last = VertexPosition
	end

	Ceive.Ray:Draw(Last, First)
end

--- @within Cone
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