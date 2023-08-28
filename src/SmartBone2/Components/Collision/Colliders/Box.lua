local function ClosestPointFunc(cframe, size, point)
	local rel = cframe:pointToObjectSpace(point)
	local sx, sy, sz = size.x, size.y, size.z
	local rx, ry, rz = rel.x, rel.y, rel.z

	-- constrain to within the box
	local cx = math.clamp(rx, -sx / 2, sx / 2)
	local cy = math.clamp(ry, -sy / 2, sy / 2)
	local cz = math.clamp(rz, -sz / 2, sz / 2)

	if not (cx == rx and cy == ry and cz == rz) then
		local closestPoint = cframe * Vector3.new(cx, cy, cz)
		local normal = (point - closestPoint).unit
		return false, closestPoint, normal
	end

	-- else, they are intersecting, find the surface the point is closest to

	local posX = rx - sx / 2
	local posY = ry - sy / 2
	local posZ = rz - sz / 2
	local negX = -rx - sx / 2
	local negY = -ry - sy / 2
	local negZ = -rz - sz / 2

	local max = math.max(posX, posY, posZ, negX, negY, negZ)
	if max == posX then
		local closestPoint = cframe * Vector3.new(sx / 2, ry, rz)
		return true, closestPoint, cframe.XVector
	elseif max == posY then
		local closestPoint = cframe * Vector3.new(rx, sy / 2, rz)
		return true, closestPoint, cframe.YVector
	elseif max == posZ then
		local closestPoint = cframe * Vector3.new(rx, ry, sz / 2)
		return true, closestPoint, cframe.ZVector
	elseif max == negX then
		local closestPoint = cframe * Vector3.new(-sx / 2, ry, rz)
		return true, closestPoint, -cframe.XVector
	elseif max == negY then
		local closestPoint = cframe * Vector3.new(rx, -sy / 2, rz)
		return true, closestPoint, -cframe.YVector
	elseif max == negZ then
		local closestPoint = cframe * Vector3.new(rx, ry, -sz / 2)
		return true, closestPoint, -cframe.ZVector
	end
end

return function(BoxCFrame, BoxSize, Point, Radius) -- Sphere vs Box
	debug.profilebegin("Box Testing")
	local IsInside, ClosestPoint, Normal = ClosestPointFunc(BoxCFrame, BoxSize, Point)

	if IsInside then
		return IsInside, ClosestPoint, Normal
	end

	local DistanceToCp = (ClosestPoint - Point).Magnitude

	IsInside = (DistanceToCp < Radius)
	debug.profileend()
	return IsInside, ClosestPoint, Normal
end
