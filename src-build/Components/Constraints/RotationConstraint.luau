local function SafeUnit(v3)
	if v3.Magnitude == 0 then
		return Vector3.zero
	end

	return v3.Unit
end

return function(self, Position, BoneTree)
	
local ParentIndex = self.ParentIndex
	local ParentBone = BoneTree.Bones[ParentIndex]

	if not ParentBone then
		
return Position
	end

	local ParentBoneLimit = ParentBone.RotationLimit

	if ParentBoneLimit >= 180 then
		
return Position
	end

	local GrandParentBone = BoneTree.Bones[ParentBone.ParentIndex]

	if not GrandParentBone then
		
return Position
	end

	local ParentBonePosition = ParentBone.Position
	local DefaultDirection = SafeUnit(ParentBone.Position - GrandParentBone.Position)

	local DistanceToParent = (Position - ParentBonePosition).Magnitude
	local DirectionToSelf = SafeUnit(Position - ParentBonePosition)

	if ParentBoneLimit <= 0 then
		
return ParentBonePosition + DefaultDirection * DistanceToParent
	end

	local RotationLimit = math.rad(self.RotationLimit)
	local VectorAngle = math.acos(DefaultDirection:Dot(DirectionToSelf))
	local LimitedVector

	if VectorAngle >= RotationLimit then
		local Cross = SafeUnit(DefaultDirection:Cross(DirectionToSelf))
		LimitedVector = CFrame.fromAxisAngle(Cross, RotationLimit) * DefaultDirection
	else
		LimitedVector = DirectionToSelf
	end

	if LimitedVector ~= LimitedVector then -- Somewhat hacky fix
		LimitedVector = DefaultDirection
	end

	Position = ParentBonePosition + LimitedVector * DistanceToParent
	

return Position
end
