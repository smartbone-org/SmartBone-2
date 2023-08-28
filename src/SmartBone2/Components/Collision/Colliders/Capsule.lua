local function solve(p0, d0, len, p1)
	local v = p1 - p0
	local k = v:Dot(d0)
	k = math.clamp(k, -len, len)
	return p0 + d0 * k
end

local function ClosestPointFunc(cframe, length, radius, point)
	local l0 = solve(cframe.Position, cframe.RightVector, length / 2, point)

	local distance = (l0 - point).Magnitude
	local normal = (point - l0).Unit
	local is_inside = (distance <= radius)

	return is_inside, l0 + (normal * radius), normal
end

return function(CapsuleCFrame, CapsuleSize, Point, Radius)
	debug.profilebegin("Capsule Testing")
	local CapsuleRadius = math.min(CapsuleSize.Y, CapsuleSize.Z) / 2
	local CapsuleLength = CapsuleSize.X

	local IsInside, ClosestPoint, Normal = ClosestPointFunc(CapsuleCFrame, CapsuleLength, CapsuleRadius, Point)

	if IsInside then
		return IsInside, ClosestPoint, Normal
	end

	local DistanceToCp = (ClosestPoint - Point).Magnitude

	IsInside = (DistanceToCp < Radius)
	debug.profileend()
	return IsInside, ClosestPoint, Normal
end
