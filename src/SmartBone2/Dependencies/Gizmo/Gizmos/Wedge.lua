--- @class Wedge
--- Renders a wireframe wedge.
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

--- @within Wedge
--- @function Draw
--- @param Transform CFrame
--- @param Size Vector3
--- @param DrawTriangles boolean?
function Gizmo:Draw(Transform: CFrame, Size: Vector3, DrawTriangles: boolean)
	local Ceive = self.Ceive

	if not Ceive.Enabled then
		return
	end

	local Position = Transform.Position
	local Uv = Transform.UpVector
	local Rv = Transform.RightVector
	local Lv = Transform.LookVector
	local sO2 = Size / 2
	local sUv = Uv * sO2.Y
	local sRv = Rv * sO2.X
	local sLv = Lv * sO2.Z

	local YTopLeft
	local YTopRight

	local ZBottomLeft
	local ZBottomRight

	local function CalculateYFace(lUv, lRv, lLv)
		local TopLeft = Position + (lUv - lRv + lLv)
		local TopRight = Position + (lUv + lRv + lLv)
		local BottomLeft = Position + (lUv - lRv - lLv)
		local BottomRight = Position + (lUv + lRv - lLv)

		YTopLeft = TopLeft
		YTopRight = TopRight

		Ceive.Ray:Draw(TopLeft, TopRight)
		Ceive.Ray:Draw(TopLeft, BottomLeft)

		Ceive.Ray:Draw(TopRight, BottomRight)
		if DrawTriangles ~= false then
			Ceive.Ray:Draw(TopRight, BottomLeft)
		end

		Ceive.Ray:Draw(BottomLeft, BottomRight)
	end

	local function CalculateZFace(lUv, lRv, lLv)
		local TopLeft = Position + (lUv - lRv + lLv)
		local TopRight = Position + (lUv + lRv + lLv)
		local BottomLeft = Position + (-lUv - lRv + lLv)
		local BottomRight = Position + (-lUv + lRv + lLv)

		ZBottomLeft = TopLeft
		ZBottomRight = TopRight

		Ceive.Ray:Draw(TopLeft, TopRight)
		Ceive.Ray:Draw(TopLeft, BottomLeft)

		Ceive.Ray:Draw(TopRight, BottomRight)
		if DrawTriangles ~= false then
			Ceive.Ray:Draw(TopRight, BottomLeft)
		end

		Ceive.Ray:Draw(BottomLeft, BottomRight)
	end

	CalculateYFace(-sUv, sRv, sLv)

	CalculateZFace(sUv, sRv, -sLv)

	Ceive.Ray:Draw(YTopLeft, ZBottomLeft)
	Ceive.Ray:Draw(YTopRight, ZBottomRight)
	if DrawTriangles ~= false then
		Ceive.Ray:Draw(YTopRight, ZBottomLeft)
	end
end

--- @within Wedge
--- @function Create
--- @param Transform CFrame
--- @param Size Vector3
--- @param DrawTriangles boolean?
--- @return {Transform: CFrame, Size: Vector3, DrawTriangles: boolean, Color3: Color3, AlwaysOnTop: boolean, Transparency: number, Enabled: boolean, Destroy: boolean}
function Gizmo:Create(Transform: CFrame, Size: Vector3, DrawTriangles: boolean)
	local PropertyTable = {
		Transform = Transform,
		Size = Size,
		DrawTriangles = DrawTriangles,
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

	self:Draw(PropertyTable.Transform, PropertyTable.Size, PropertyTable.DrawTriangles)
end

return Gizmo