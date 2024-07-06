--!native
local function SafeUnit(v3)
	if v3.Magnitude == 0 then
		return Vector3.zero
	end

	return v3.Unit
end

local function ClosestPointFunc(position, radius, point)
	local distance = (position - point).Magnitude
	local normal = SafeUnit(point - position)
	local is_inside = (distance <= radius)

	return is_inside, position + (normal * radius), normal
end

return function(Sphere0Point, Sphere0Radius, Sphere1Point, Sphere1Radius)
do end	
Sphere0Point = Sphere0Point.Position
	Sphere0Radius = math.min(Sphere0Radius.X, Sphere0Radius.Y, Sphere0Radius.Z) * 0.5

	local IsInside, ClosestPoint, Normal = ClosestPointFunc(Sphere0Point, Sphere0Radius, Sphere1Point)

	if IsInside then
		return IsInside, ClosestPoint, Normal
	end

	local DistanceToCp = (ClosestPoint - Sphere1Point).Magnitude

	IsInside = (DistanceToCp < Sphere1Radius)
do end	
return IsInside, ClosestPoint, Normal
end
