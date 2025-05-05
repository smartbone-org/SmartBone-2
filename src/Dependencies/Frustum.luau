--!native
--!strict
local Class = {}

local Dependencies = script.Parent
local Config = require(Dependencies:WaitForChild("Config"))
local Utilities = require(Dependencies:WaitForChild("Utilities"))

function Class.GetCFrames(camera: Camera, distance: number)
	local cameraCFrame = camera.CFrame
	local cameraPos = cameraCFrame.Position
	local rightVec = cameraCFrame.RightVector
	local upVec = cameraCFrame.UpVector

	local distance2 = distance * 0.5
	local tanFov = math.tan(((camera.FieldOfView + 5) * 0.5) * 0.017453)
	local farPlaneHeight2 = tanFov * distance
	local aspectRatio = camera.ViewportSize.X / camera.ViewportSize.Y
	local farPlaneWidth2 = farPlaneHeight2 * aspectRatio
	local farPlaneCFrame = cameraCFrame * CFrame.new(0, 0, -distance)

	local farPlaneTopRight = farPlaneCFrame * Vector3.new(farPlaneWidth2, farPlaneHeight2, 0)
	local farPlaneBottomLeft = farPlaneCFrame * Vector3.new(-farPlaneWidth2, -farPlaneHeight2, 0)
	local farPlaneBottomRight = farPlaneCFrame * Vector3.new(farPlaneWidth2, -farPlaneHeight2, 0)

	local frustumCFrameInverse = (cameraCFrame * CFrame.new(0, 0, -distance2)):Inverse()

	local rightNormal = upVec:Cross(farPlaneBottomRight - cameraPos).Unit
	local leftNormal = upVec:Cross(farPlaneBottomLeft - cameraPos).Unit
	local topNormal = rightVec:Cross(cameraPos - farPlaneTopRight).Unit
	local bottomNormal = rightVec:Cross(cameraPos - farPlaneBottomRight).Unit

	return frustumCFrameInverse, farPlaneWidth2, farPlaneHeight2, distance2, rightNormal, leftNormal, topNormal, bottomNormal, cameraCFrame
end

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
	local cameraPos = cameraCf.Position
	local relativeToOBB = frustumCFrameInverse * point

	if
		relativeToOBB.X > farPlaneWidth2
		or relativeToOBB.X < -farPlaneWidth2
		or relativeToOBB.Y > farPlaneHeight2
		or relativeToOBB.Y < -farPlaneHeight2
		or relativeToOBB.Z > distance2
		or relativeToOBB.Z < -distance2
	then
		return false
	end

	local lookToCell = point - cameraPos

	if
		rightNormal:Dot(lookToCell) < 0
		or leftNormal:Dot(lookToCell) > 0
		or topNormal:Dot(lookToCell) < 0
		or bottomNormal:Dot(lookToCell) > 0
	then
		return false
	end

	return true
end

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
	local CF = Object.CFrame
	local Size = Object.Size

	local HalfFarPlane = Config.FAR_PLANE * 0.5
	local LinePosition = cameraCFrame.Position + cameraCFrame.LookVector * HalfFarPlane

	local Closest = Utilities.ClosestPointOnLine(LinePosition, cameraCFrame.LookVector, HalfFarPlane, CF.Position)
	local Inside, point = Utilities.ClosestPointInBox(CF, Size, Closest)

	if Inside then
		return true
	end

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
		return true
	end

	return false
end

return Class
