--!native
--!strict
local Class = {}

local Dependencies = script.Parent
local Config = require(Dependencies:WaitForChild("Config"))
local Utilities = require(Dependencies:WaitForChild("Utilities"))

-- Calculates frustum planes and normals based on the camera state
function Class.GetCFrames(camera: Camera, distance: number)
	debug.profilebegin("Frustum::GetCFrames")

	-- Extract camera orientation and position
	local cameraCFrame = camera.CFrame
	local cameraPos = cameraCFrame.Position
	local rightVec = cameraCFrame.RightVector
	local upVec = cameraCFrame.UpVector

	-- Half distance to near-mid plane
	local distance2 = distance * 0.5

	-- Field of view scaling
	local tanFov = math.tan(((camera.FieldOfView + 5) * 0.5) * 0.017453)
	local farPlaneHeight2 = tanFov * distance
	local aspectRatio = camera.ViewportSize.X / camera.ViewportSize.Y
	local farPlaneWidth2 = farPlaneHeight2 * aspectRatio

	-- Position of far plane
	local farPlaneCFrame = cameraCFrame * CFrame.new(0, 0, -distance)

	-- Far plane corners
	local farPlaneTopRight = farPlaneCFrame * Vector3.new(farPlaneWidth2, farPlaneHeight2, 0)
	local farPlaneBottomLeft = farPlaneCFrame * Vector3.new(-farPlaneWidth2, -farPlaneHeight2, 0)
	local farPlaneBottomRight = farPlaneCFrame * Vector3.new(farPlaneWidth2, -farPlaneHeight2, 0)

	-- Transform to local frustum space
	local frustumCFrameInverse = (cameraCFrame * CFrame.new(0, 0, -distance2)):Inverse()

	-- Plane normals
	local rightNormal = upVec:Cross(farPlaneBottomRight - cameraPos).Unit
	local leftNormal = upVec:Cross(farPlaneBottomLeft - cameraPos).Unit
	local topNormal = rightVec:Cross(cameraPos - farPlaneTopRight).Unit
	local bottomNormal = rightVec:Cross(cameraPos - farPlaneBottomRight).Unit

	debug.profileend()
	return frustumCFrameInverse, farPlaneWidth2, farPlaneHeight2, distance2, rightNormal, leftNormal, topNormal, bottomNormal, cameraCFrame
end

-- Checks if a 3D point lies inside the frustum
function Class.InViewFrustum(
	point: Vector3,
	frustumCFrameInverse: CFrame,
	farPlaneWidth2: number,
	farPlaneHeight2: number,
	distance2: number,
	rightNormal: Vector3,
	leftNormal: Vector3,
	topNormal: Vector3,
	bottomNormal: Vector3,
	cameraCf: CFrame
): boolean
	debug.profilebegin("Frustum::InViewFrustum")

	-- Transform point into frustum-local space
	local cameraPos = cameraCf.Position
	local relativeToOBB = frustumCFrameInverse * point

	-- Check against axis-aligned box bounds
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

	-- Direction vector from camera to point
	local lookToCell = point - cameraPos

	-- Check against frustum planes
	if
		rightNormal:Dot(lookToCell) < 0
		or leftNormal:Dot(lookToCell) > 0
		or topNormal:Dot(lookToCell) < 0
		or bottomNormal:Dot(lookToCell) > 0
	then
		debug.profileend()
		return false
	end

	debug.profileend()
	return true
end

-- Checks if a 3D object lies inside the frustum
function Class.ObjectInFrustum(
	Object: BasePart,
	frustumCFrameInverse: CFrame,
	farPlaneWidth2: number,
	farPlaneHeight2: number,
	distance2: number,
	rightNormal: Vector3,
	leftNormal: Vector3,
	topNormal: Vector3,
	bottomNormal: Vector3,
	cameraCFrame: CFrame
): boolean
	debug.profilebegin("Frustum::ObjectInFrustum")

	-- Object transform
	local CF = Object.CFrame
	local Size = Object.Size

	-- Midpoint along far plane
	local HalfFarPlane = Config.FAR_PLANE * 0.5
	local LinePosition = cameraCFrame.Position + cameraCFrame.LookVector * HalfFarPlane

	-- Closest point from object to camera view line
	local Closest = Utilities.ClosestPointOnLine(LinePosition, cameraCFrame.LookVector, HalfFarPlane, CF.Position)

	-- Check if object is inside box from closest point
	local Inside, point = Utilities.ClosestPointInBox(CF, Size, Closest)

	if Inside then
		debug.profileend()
		return true
	end

	-- Fallback: check closest point against frustum
	if Class.InViewFrustum(
		point,
		frustumCFrameInverse,
		farPlaneWidth2,
		farPlaneHeight2,
		distance2,
		rightNormal,
		leftNormal,
		topNormal,
		bottomNormal,
		cameraCFrame
	) then
		debug.profileend()
		return true
	end

	debug.profileend()
	return false
end

return Class
