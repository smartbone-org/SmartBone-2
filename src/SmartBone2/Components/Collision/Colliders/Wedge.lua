local MeshData = {
	{ -- back tri 1
		v0 = Vector3.new(0.5, 0.5, -0.5),
		v1 = Vector3.new(0.5, 0, -0.5),
		v2 = Vector3.new(-0.5, -0.5, -0.5),
	},

	{ -- back tri 2
		v0 = Vector3.new(0.5, 0.5, -0.5),
		v1 = Vector3.new(-0.5, 0.5, -0.5),
		v2 = Vector3.new(-0.5, -0.5, -0.5),
	},

	{ -- bottom tri 1
		v0 = Vector3.new(0.5, -0.5, -0.5),
		v1 = Vector3.new(0.5, -0.5, 0.5),
		v2 = Vector3.new(-0.5, -0.5, 0.5),
	},

	{ -- bottom tri 2
		v0 = Vector3.new(0.5, -0.5, -0.5),
		v1 = Vector3.new(-0.5, -0.5, -0.5),
		v2 = Vector3.new(-0.5, -0.5, 0.5),
	},

	{ -- front tri 1
		v0 = Vector3.new(0.5, 0.5, -0.5),
		v1 = Vector3.new(0.5, -0.5, 0.5),
		v2 = Vector3.new(-0.5, -0.5, 0.5),
	},

	{ -- front tri 2
		v0 = Vector3.new(0.5, 0.5, -0.5),
		v1 = Vector3.new(-0.5, 0.5, -0.5),
		v2 = Vector3.new(-0.5, -0.5, 0.5),
	},
}

type RawMeshData = {
	[number]: {
		v0: Vector3,
		v1: Vector3,
		v2: Vector3,
	},
}

local Triangle = require(script.Parent:WaitForChild("Triangle"))

local function ParseMeshData(Transform, Size, Data): RawMeshData
	local NewData = {}

	for ti, Tri in Data do
		NewData[ti] = {}
		for vi, Vert in Tri do
			NewData[ti][vi] = (Transform * CFrame.new(Vert * Size)).Position
		end
	end

	return NewData
end

return function(Transform, Size, Point, Radius) -- Sphere vs Wedge
	debug.profilebegin("Wedge Testing")

	local TransformedMeshData = ParseMeshData(Transform, Size, MeshData)

	local ClosestPoint = Point
	local ClosestNormal = Vector3.zero
	local Distance = math.huge

	for _, Tri in TransformedMeshData do
		local Closest, Normal = Triangle(Tri.v0, Tri.v1, Tri.v2, Point)
		local D = (Closest - Point).Magnitude
		if D < Distance then
			ClosestPoint = Closest
			ClosestNormal = Normal
			Distance = D
		end
	end

	local PointDirection = (ClosestPoint - Point).Unit
	local NormalInside = PointDirection:Dot(ClosestNormal) < 0

	local IsInside = (ClosestPoint - Point).Magnitude <= Radius or NormalInside
	debug.profileend()
	return IsInside, ClosestPoint, ClosestNormal
end
