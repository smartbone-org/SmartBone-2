--!native
local Dependencies = script.Parent
local Config = require(Dependencies:WaitForChild("Config"))
local Utilities = require(Dependencies:WaitForChild("Utilities"))

local Class = {}

function Class.GetCFrames(camera, distance)
do end	
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
do end	
return frustumCFrameInverse, farPlaneWidth2, farPlaneHeight2, distance2, rightNormal, leftNormal, topNormal, bottomNormal, cameraCFrame
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
	cameraCf
)
do end
	
local cameraPos = cameraCf.Position

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
do end		
return false
	end

	-- Check if point lies outside a frustum plane
	local lookToCell = point - cameraPos
	if rightNormal:Dot(lookToCell) < 0 or leftNormal:Dot(lookToCell) > 0 or topNormal:Dot(lookToCell) < 0 or bottomNormal:Dot(lookToCell) > 0 then
do end		
return false
	end
do end	

return true
end

function Class.ObjectInFrustum(
	Object,
	frustumCFrameInverse,
	farPlaneWidth2,
	farPlaneHeight2,
	distance2,
	rightNormal,
	leftNormal,
	topNormal,
	bottomNormal,
	cameraCFrame
)
	local CF = Object.CFrame
	local Size = Object.Size

	-- Allows for really big root parts to still be checked correctly
	local HalfFarPlane = Config.FAR_PLANE * 0.5
	local LinePosition = cameraCFrame.Position + (cameraCFrame.LookVector * HalfFarPlane)

	local Closest = Utilities.ClosestPointOnLine(LinePosition, cameraCFrame.LookVector, HalfFarPlane, CF.Position)
	local Inside, point = Utilities.ClosestPointInBox(CF, Size, Closest)

	if Inside then
		return true
	end

	if
		Class.InViewFrustum(
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
		)
	then
		return true
	end

	return false
end

return Class
