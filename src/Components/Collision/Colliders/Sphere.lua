--!native
local function SafeUnit(v3)
	if vector.magnitude(v3) == 0 then
		return vector.zero
	end

	return vector.normalize(v3)
end

local function ClosestPointFunc(position, radius, point)
	local distance = vector.magnitude(position - point)
	local normal = SafeUnit(point - position)
	local is_inside = (distance <= radius)

	return is_inside, position + (normal * radius), normal
end

return function(Sphere0Point, Sphere0Radius, Sphere1Point, Sphere1Radius)
	debug.profilebegin("Sphere Testing")
	Sphere0Point = Sphere0Point.Position
	Sphere0Radius = math.min(Sphere0Radius.X, Sphere0Radius.Y, Sphere0Radius.Z) * 0.5

	local IsInside, ClosestPoint, Normal = ClosestPointFunc(Sphere0Point, Sphere0Radius, Sphere1Point)

	if IsInside then
		return IsInside, ClosestPoint, Normal
	end

	local DistanceToCp = vector.magnitude(ClosestPoint - Sphere1Point)

	IsInside = (DistanceToCp < Sphere1Radius)
	debug.profileend()
	return IsInside, ClosestPoint, Normal
end
