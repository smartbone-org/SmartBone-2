--- @class Plane
--- Renders a wireframe plane.
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

--- @within Plane
--- @function Draw
--- @param Position Vector3
--- @param Normal Vector3
--- @param Size Vector3
function Gizmo:Draw(Position: Vector3, Normal: Vector3, Size: Vector3)
	local Ceive = self.Ceive

	if not Ceive.Enabled then
		return
	end

    Size *= Vector3.new(1, 1, 0)

    local Transform = CFrame.lookAt(Position, Position + Normal)

	local Uv = Transform.UpVector
	local Rv = Transform.RightVector
	local Lv = Transform.LookVector
	local sO2 = Size / 2
	local sUv = Uv * sO2.Y
	local sRv = Rv * sO2.X
	local sLv = Lv * sO2.Z

	local function CalculateZFace(lUv, lRv, lLv)
		local TopLeft = Position + (lUv - lRv + lLv)
		local TopRight = Position + (lUv + lRv + lLv)
		local BottomLeft = Position + (-lUv - lRv + lLv)
		local BottomRight = Position + (-lUv + lRv + lLv)

		Ceive.Ray:Draw(TopLeft, TopRight)
		Ceive.Ray:Draw(TopLeft, BottomLeft)

		Ceive.Ray:Draw(TopRight, BottomRight)
		Ceive.Ray:Draw(TopRight, BottomLeft)

		Ceive.Ray:Draw(BottomLeft, BottomRight)
	end

	CalculateZFace(sUv, sRv, sLv)
end

--- @within Plane
--- @function Create
--- @param Position Vector3
--- @param Normal Vector3
--- @param Size Vector3
--- @return {Position: Vector3, Normal: Vector3, Size: Vector3, DrawTriangles: boolean, Color3: Color3, AlwaysOnTop: boolean, Transparency: number, Enabled: boolean, Destroy: boolean}
function Gizmo:Create(Position: Vector3, Normal: Vector3, Size: Vector3)
	local PropertyTable = {
		Position = Position,
		Normal = Normal,
        Size = Size,
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

	self:Draw(PropertyTable.Position, PropertyTable.Normal, PropertyTable.Size)
end

return Gizmo