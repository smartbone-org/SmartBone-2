--!native
local function SafeUnit(v3)
	if vector.magnitude(v3) == 0 then
		return vector.zero
	end

	return vector.normalize(v3)
end

local function solve(p0, d0, len, p1)
	local v = p1 - p0
	local k = v:Dot(d0)
	k = math.clamp(k, -len, len)
	return p0 + d0 * k
end

local function ClosestPointFunc(cframe, length, radius, point)
	local l0 = solve(cframe.Position, cframe.UpVector, length * 0.5, point)

	local distance =vector.magnitude(l0 - point)
	local normal = SafeUnit(point - l0)
	local is_inside = (distance <= radius)

	return is_inside, l0 + (normal * radius), normal
end

return function(CapsuleCFrame, CapsuleSize, Point, Radius)
	debug.profilebegin("Capsule Testing")
	local CapsuleRadius = (CapsuleSize.Y < CapsuleSize.Z and CapsuleSize.Y or CapsuleSize.Z) * 0.5
	local CapsuleLength = CapsuleSize.X

	CapsuleCFrame *= CFrame.Angles(math.rad(90), -math.rad(90), 0) -- Optomize

	local IsInside, ClosestPoint, Normal = ClosestPointFunc(CapsuleCFrame, CapsuleLength, CapsuleRadius, Point)

	if IsInside then
		return IsInside, ClosestPoint, Normal
	end

	local DistanceToCp =vector.magnitude(ClosestPoint - Point)

	IsInside = (DistanceToCp < Radius)
	debug.profileend()
	return IsInside, ClosestPoint, Normal
end
