local Class = {}

function Class.GetCFrames(camera, distance)
	debug.profilebegin("Frustum::GetCFrames")
	local cameraCFrame = camera.CFrame
	local cameraPos = cameraCFrame.Position
	local rightVec, upVec = cameraCFrame.RightVector, cameraCFrame.UpVector

	local distance2 = distance * 0.5
	local farPlaneHeight2 = math.tan(((camera.FieldOfView + 5) * 0.5) * 0.017453) * distance
	local farPlaneWidth2 = farPlaneHeight2 * (camera.ViewportSize.X / camera.ViewportSize.Y)
	local farPlaneCFrame = cameraCFrame * CFrame.new(0, 0, -distance)
	local farPlaneTopRight = farPlaneCFrame * Vector3.new(farPlaneWidth2, farPlaneHeight2, 0)
	local farPlaneBottomLeft = farPlaneCFrame * Vector3.new(-farPlaneWidth2, -farPlaneHeight2, 0)
	local farPlaneBottomRight = farPlaneCFrame * Vector3.new(farPlaneWidth2, -farPlaneHeight2, 0)

	local frustumCFrameInverse = (cameraCFrame * CFrame.new(0, 0, -distance2)):Inverse()

	local rightNormal = upVec:Cross(farPlaneBottomRight - cameraPos).Unit
	local leftNormal = upVec:Cross(farPlaneBottomLeft - cameraPos).Unit
	local topNormal = rightVec:Cross(cameraPos - farPlaneTopRight).Unit
	local bottomNormal = rightVec:Cross(cameraPos - farPlaneBottomRight).Unit
	debug.profileend()
	return frustumCFrameInverse, farPlaneWidth2, farPlaneHeight2, distance2, rightNormal, leftNormal, topNormal, bottomNormal, cameraPos
end

function Class.InViewFrustum(
	point,
	frustumCFrameInverse,
	farPlaneWidth2,
	farPlaneHeight2,
	distance2,
	rightNormal,
	leftNormal,
	topNormal,
	bottomNormal,
	cameraPos
)
	debug.profilebegin("Frustum::InViewFrustum")
	-- Check if point lies outside frustum OBB
	local relativeToOBB = frustumCFrameInverse * point
	if
		relativeToOBB.X > farPlaneWidth2
		or relativeToOBB.X < -farPlaneWidth2
		or relativeToOBB.Y > farPlaneHeight2
		or relativeToOBB.Y < -farPlaneHeight2
		or relativeToOBB.Z > distance2
		or relativeToOBB.Z < -distance2
	then
		debug.profileend()
		return false
	end

	-- Check if point lies outside a frustum plane
	local lookToCell = point - cameraPos
	if rightNormal:Dot(lookToCell) < 0 or leftNormal:Dot(lookToCell) > 0 or topNormal:Dot(lookToCell) < 0 or bottomNormal:Dot(lookToCell) > 0 then
		debug.profileend()
		return false
	end

	debug.profileend()
	return true
end

function Class.ObjectInFrustum(Object, ...)
	local CF = Object.CFrame
	local Size = Object.Size

	for i = 1, 8 do
		local point = CF
			* CFrame.new(Size.X * (i % 2 == 0 and 0.5 or -0.5), Size.Y * (i % 4 > 1 and 0.5 or -0.5), Size.Z * (i % 8 > 3 and 0.5 or -0.5))

		if Class.InViewFrustum(point.Position, ...) then
			return true
		end
	end

	return false
end

return Class
