--[[

    !! THIS IS NOT MEANT TO BE USED AS A COLLIDER SOLVER, ITS MEANT TO BE USED IN OTHER COLLIDER SOLVERS !!

]]

local dot = Vector3.new().Dot
local cross = Vector3.new().Cross
local clamp = math.clamp

local function ClosestPointOnLineSegment(A, B, P)
	local AB = B - A
	local t = dot(P - A, AB) / dot(AB, AB)
	return A + clamp(t, 0, 1) * AB
end

local function ProjectOnPlane(pos, normal, point)
	local d = point - pos
	local v_dot = d:Dot(normal)
	local v = point - v_dot * normal

	return v
end

local function SameSide(p1, p2, a, b)
	local cp1 = cross(b - a, p1 - a)
	local cp2 = cross(b - a, p2 - a)
	if dot(cp1, cp2) >= 0 then
		return true
	else
		return false
	end
end

local function PointInTriangle(p, a, b, c)
	if SameSide(p, a, b, c) and SameSide(p, b, a, c) and SameSide(p, c, a, b) then
		return true
	end

	return false
end

local function ClosestPointOnTri(v0, v1, v2, point) -- ClosestPoint, Normal
	debug.profilebegin("Triangle")
	local Edge0 = ClosestPointOnLineSegment(v0, v1, point)
	local Edge1 = ClosestPointOnLineSegment(v1, v2, point)
	local Edge2 = ClosestPointOnLineSegment(v2, v0, point)

	local Normal = cross(v1 - v0, v2 - v0).Unit
	local Center = (v0 + v1 + v2) * 0.3333
	local Projected = ProjectOnPlane(Center, Normal, point)

	if PointInTriangle(point, v0, v1, v2) then
		debug.profileend()
		return Projected, Normal
	end

	local d0 = (Edge0 - point).Magnitude
	local d1 = (Edge1 - point).Magnitude
	local d2 = (Edge2 - point).Magnitude

	local d = math.min(d0, d1, d2)

	if d == d0 then
		debug.profileend()
		return Edge0, Normal
	elseif d == d1 then
		debug.profileend()
		return Edge1, Normal
	elseif d == d2 then
		debug.profileend()
		return Edge2, Normal
	end

	debug.profileend()
	return point, Normal
end

return ClosestPointOnTri
