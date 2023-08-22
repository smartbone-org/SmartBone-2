local function Map(n, start, stop, newStart, newStop)
	return ((n - start) / (stop - start)) * (newStop - newStart) + newStart
end

--- @class Mesh
--- Renders a wireframe mesh.
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

--- @within Mesh
--- @function Draw
--- @param Transform CFrame
--- @param Size Vector3
--- @param Vertices table
--- @param Faces table
function Gizmo:Draw(Transform: CFrame, Size: Vector3, Vertices, Faces)
	local Ceive = self.Ceive

	if not Ceive.Enabled then
		return
	end

	local maxX = -math.huge
	local maxY = -math.huge
	local maxZ = -math.huge

	local minX = math.huge
	local minY = math.huge
	local minZ = math.huge

	for _, vertex in Vertices do
		maxX = math.max(maxX, vertex.x)
		maxY = math.max(maxY, vertex.y)
		maxZ = math.max(maxZ, vertex.z)

		minX = math.min(minX, vertex.x)
		minY = math.min(minY, vertex.y)
		minZ = math.min(minZ, vertex.z)
	end

	for i, vertex in Vertices do
		local vX = Map(vertex.x, minX, maxX, -0.5, 0.5)
		local vY = Map(vertex.y, minY, maxY, -0.5, 0.5)
		local vZ = Map(vertex.z, minZ, maxZ, -0.5, 0.5)

		local vertexCFrame = Transform * CFrame.new(Vector3.new(vX, vY, vZ) * Size)
		Vertices[i] = vertexCFrame
	end

	for _, face in Faces do
		if #face == 3 then
			local vCF1 = Vertices[face[1].v]
			local vCF2 = Vertices[face[2].v]
			local vCF3 = Vertices[face[3].v]

			Ceive.Ray:Draw(vCF1.Position, vCF2.Position)
			Ceive.Ray:Draw(vCF2.Position, vCF3.Position)
			Ceive.Ray:Draw(vCF3.Position, vCF1.Position)
		else
			local vCF1 = Vertices[face[1].v]
			local vCF2 = Vertices[face[2].v]
			local vCF3 = Vertices[face[3].v]
			local vCF4 = Vertices[face[4].v]

			Ceive.Ray:Draw(vCF1.Position, vCF2.Position)
			Ceive.Ray:Draw(vCF1.Position, vCF4.Position)
			Ceive.Ray:Draw(vCF4.Position, vCF2.Position)

			Ceive.Ray:Draw(vCF3.Position, vCF4.Position)
			Ceive.Ray:Draw(vCF2.Position, vCF3.Position)
		end
	end
end

--- @within Mesh
--- @function Create
--- @param Transform CFrame
--- @param Size Vector3
--- @param Vertices table
--- @param Faces table
--- @return {Transform: CFrame, Size: Vector3, Vertices: {}, Faces: {}, Color3: Color3, AlwaysOnTop: boolean, Transparency: number, Enabled: boolean, Destroy: boolean}
function Gizmo:Create(Transform: CFrame, Size: Vector3, Vertices, Faces)
	local PropertyTable = {
		Transform = Transform,
		Size = Size,
		Vertices = Vertices,
		Faces = Faces,
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

	self:Draw(PropertyTable.Transform, PropertyTable.Size, PropertyTable.Vertices, PropertyTable.Faces)
end

return Gizmo