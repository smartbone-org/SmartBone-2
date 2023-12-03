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

function Gizmo:Draw(Transform: CFrame, Size: Vector3, DrawTriangles: boolean)
	local Ceive = self.Ceive

	if not Ceive.Enabled then
		return
	end

	local Position = Transform.Position
	local Uv = Transform.UpVector
	local Rv = Transform.RightVector
	local Lv = Transform.LookVector
	local sO2 = Size * 0.5
	local sUv = Uv * sO2.Y
	local sRv = Rv * sO2.X
	local sLv = Lv * sO2.Z

	local function CalculateYFace(lUv, lRv, lLv)
		local TopLeft = Position + (lUv - lRv + lLv)
		local TopRight = Position + (lUv + lRv + lLv)
		local BottomLeft = Position + (lUv - lRv - lLv)
		local BottomRight = Position + (lUv + lRv - lLv)

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

		Ceive.Ray:Draw(TopLeft, TopRight)
		Ceive.Ray:Draw(TopLeft, BottomLeft)

		Ceive.Ray:Draw(TopRight, BottomRight)
		if DrawTriangles ~= false then
			Ceive.Ray:Draw(TopRight, BottomLeft)
		end

		Ceive.Ray:Draw(BottomLeft, BottomRight)
	end

	local function CalculateXFace(lUv, lRv, lLv)
		local TopLeft = Position + (lUv - lRv - lLv)
		local TopRight = Position + (lUv - lRv + lLv)
		local BottomLeft = Position + (-lUv - lRv - lLv)
		local BottomRight = Position + (-lUv - lRv + lLv)

		Ceive.Ray:Draw(TopLeft, TopRight)
		Ceive.Ray:Draw(TopLeft, BottomLeft)

		Ceive.Ray:Draw(TopRight, BottomRight)
		if DrawTriangles ~= false then
			Ceive.Ray:Draw(TopRight, BottomLeft)
		end

		Ceive.Ray:Draw(BottomLeft, BottomRight)
	end

	CalculateXFace(sUv, sRv, sLv)
	CalculateXFace(sUv, -sRv, sLv)

	CalculateYFace(sUv, sRv, sLv)
	CalculateYFace(-sUv, sRv, sLv)

	CalculateZFace(sUv, sRv, sLv)
	CalculateZFace(sUv, sRv, -sLv)
end

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
