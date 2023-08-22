local function ClosestPointFunc(position, radius, point)
	local distance = (position - point).Magnitude
	local normal = (point - position).Unit
	local is_inside = (distance <= radius)

	return is_inside, position + (normal * radius), normal
end

return function(Sphere0Point, Sphere0Radius, Sphere1Point, Sphere1Radius)
	Sphere0Point = Sphere0Point.Position
	Sphere0Radius = math.min(Sphere0Radius.X, Sphere0Radius.Y, Sphere0Radius.Z) / 2

	local IsInside, ClosestPoint, Normal =
		ClosestPointFunc(Sphere0Point, Sphere0Radius, Sphere1Point)

	if IsInside then
		return IsInside, ClosestPoint, Normal
	end

	local DistanceToCp = (ClosestPoint - Sphere1Point).Magnitude

	IsInside = (DistanceToCp < Sphere1Radius)

	return IsInside, ClosestPoint, Normal
end
