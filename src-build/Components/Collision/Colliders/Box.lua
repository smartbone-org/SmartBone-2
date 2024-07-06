local function SafeUnit(v3)
	if v3.Magnitude == 0 then
		return Vector3.zero
	end

	return v3.Unit
end

local function ClosestPointFunc(cframe, size, point)
	local rel = cframe:pointToObjectSpace(point)
	local sx, sy, sz = size.x, size.y, size.z
	local rx, ry, rz = rel.x, rel.y, rel.z

	-- constrain to within the box
	local cx = math.clamp(rx, -sx * 0.5, sx * 0.5)
	local cy = math.clamp(ry, -sy * 0.5, sy * 0.5)
	local cz = math.clamp(rz, -sz * 0.5, sz * 0.5)

	if not (cx == rx and cy == ry and cz == rz) then
		local closestPoint = cframe * Vector3.new(cx, cy, cz)
		local normal = SafeUnit(point - closestPoint)
		return false, closestPoint, normal
	end

	-- else, they are intersecting, find the surface the point is closest to

	local posX = rx - sx * 0.5
	local posY = ry - sy * 0.5
	local posZ = rz - sz * 0.5
	local negX = -rx - sx * 0.5
	local negY = -ry - sy * 0.5
	local negZ = -rz - sz * 0.5

	local max = math.max(posX, posY, posZ, negX, negY, negZ)
	if max == posX then
		local closestPoint = cframe * Vector3.new(sx * 0.5, ry, rz)
		return true, closestPoint, cframe.XVector
	elseif max == posY then
		local closestPoint = cframe * Vector3.new(rx, sy * 0.5, rz)
		return true, closestPoint, cframe.YVector
	elseif max == posZ then
		local closestPoint = cframe * Vector3.new(rx, ry, sz * 0.5)
		return true, closestPoint, cframe.ZVector
	elseif max == negX then
		local closestPoint = cframe * Vector3.new(-sx * 0.5, ry, rz)
		return true, closestPoint, -cframe.XVector
	elseif max == negY then
		local closestPoint = cframe * Vector3.new(rx, -sy * 0.5, rz)
		return true, closestPoint, -cframe.YVector
	elseif max == negZ then
		local closestPoint = cframe * Vector3.new(rx, ry, -sz * 0.5)
		return true, closestPoint, -cframe.ZVector
	end

	-- Shouldnt reach
	warn("CLOSEST POINT ON BOX FAIL")
	return false, cframe.Position, Vector3.zero
end

return function(BoxCFrame, BoxSize, Point, Radius) -- Sphere vs Box
do end	
local IsInside, ClosestPoint, Normal = ClosestPointFunc(BoxCFrame, BoxSize, Point)

	if IsInside then
		return IsInside, ClosestPoint, Normal
	end

	local DistanceToCp = (ClosestPoint - Point).Magnitude

	IsInside = (DistanceToCp < Radius)
do end	
return IsInside, ClosestPoint, Normal
end
