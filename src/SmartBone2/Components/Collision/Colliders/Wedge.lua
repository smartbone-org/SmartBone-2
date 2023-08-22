local function ClosestPointFunc(cframe, size, point)
	local rel = cframe:pointToObjectSpace(point)
	local sx, sy, sz = size.x, size.y, size.z
	local rx, ry, rz = rel.x, rel.y, rel.z

	local cx = math.clamp(rx, -sx / 2, sx / 2)
	local cz = math.clamp(rz, -sz / 2, sz / 2)

	local maxcy = ((sy / 2) * (cz / (sz / 2)))
	local cy = math.clamp(ry, -sy / 2, maxcy)

	-- constrain to within the wedge

	if not (cx == rx and cy == ry and cz == rz) then
		local closestPoint = cframe * Vector3.new(cx, cy, cz)
		local normal = (point - closestPoint).unit

		if cy ~= ry then
			normal = cframe.YVector:Lerp(-cframe.ZVector, 0.5).Unit
		end

		return false, closestPoint, normal
	end

	-- else, they are intersecting, find the surface the point is closest to

	local posX = rx - sx / 2
	local posY = ry - maxcy
	local posZ = rz - sz / 2
	local negX = -rx - sx / 2
	local negY = -ry - sy / 2
	local negZ = -rz - sz / 2

	local max = math.max(posX, posY, posZ, negX, negY, negZ)
	if max == posX then
		local closestPoint = cframe * Vector3.new(sx / 2, ry, rz)
		return true, closestPoint, cframe.XVector
	elseif max == posY then
		local closestPoint = cframe * Vector3.new(rx, maxcy, rz)
		return true, closestPoint, cframe.YVector:Lerp(-cframe.ZVector, 0.5).Unit
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

return function(WedgeCFrame, WedgeSize, Point, Radius)
	local is_inside, closestPoint, normal = ClosestPointFunc(WedgeCFrame, WedgeSize, Point)

	if is_inside then
		return is_inside, closestPoint, normal
	end

	local DistanceToCp = (closestPoint - Point).Magnitude

	is_inside = (DistanceToCp < Radius)

	return is_inside, closestPoint, normal
end
