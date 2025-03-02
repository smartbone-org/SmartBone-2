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
	return p0 + d0 * k, k
end

local function ProjectOnPlane(pos, normal, point)
	local d = point - pos
	local v_dot = d:Dot(normal)
	local v = point - v_dot * normal

	return v
end

local function ClosestPointFunc(cframe, size, point)
	local radius = (size.Y < size.Z and size.Y or size.Z) * 0.5
	local length = size.X * 0.5
	local l0, k = solve(cframe.Position, cframe.RightVector, length, point)

	local endPlane = cframe.Position + -cframe.RightVector * length
	local topPlane = cframe.Position + cframe.RightVector * length

	local endPlaneN = -cframe.RightVector
	local topPlaneN = cframe.RightVector

	local projEnd = ProjectOnPlane(endPlane, endPlaneN, point)
	local projTop = ProjectOnPlane(topPlane, topPlaneN, point)

	local function GetFinalProj(proj, o)
		local projDir = SafeUnit(proj - o)
		local projDistance = vector.magnitude(proj - o)
		return o + projDir * (projDistance < radius and projDistance or radius)
	end

	projEnd = GetFinalProj(projEnd, endPlane)
	projTop = GetFinalProj(projTop, topPlane)

	local radiusDistance = vector.magnitude(l0 - point)
	local radiusNormal = SafeUnit(point - l0)
	local radiusInside = (radiusDistance <= radius)
	local radiusPosition = l0 + (radiusNormal * radius)

	local d0 = vector.magnitude(projTop - point)
	local d1 = vector.magnitude(projEnd - point)
	local d2 = vector.magnitude(radiusPosition - point)

	local d = math.min(d0, d1, d2)

	if k == length or d == d0 then
		local dot = SafeUnit(point - projTop):Dot(topPlaneN)
		return dot < 0, projTop, topPlaneN
	elseif k == -length or d == d1 then
		local dot = SafeUnit(point - projEnd):Dot(endPlaneN)
		return dot < 0, projEnd, endPlaneN
	end

	return radiusInside, radiusPosition, radiusNormal
end

return function(CylinderCFrame, CylinderSize, Point, Radius) -- IsInside, PushPosition, PushNormal
	debug.profilebegin("Cylinder Testing")
	local IsInside, PushPosition, PushNormal = ClosestPointFunc(CylinderCFrame, CylinderSize, Point)

	if IsInside then
		return IsInside, PushPosition, PushNormal
	end

	local PointDistance = vector.magnitude(PushPosition - Point)

	IsInside = PointDistance < Radius
	debug.profileend()
	return IsInside, PushPosition, PushNormal
end
