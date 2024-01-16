return function(self, Position, BoneTree)
    debug.profilebegin("Rotation Constraint")
    local ParentIndex = self.ParentIndex
    local ParentBone = BoneTree.Bones[ParentIndex]

    if not ParentBone then
        debug.profileend()
        return Position
    end

    local GrandParentBone = BoneTree.Bones[ParentBone.ParentIndex]

    if not GrandParentBone then
        debug.profileend()
        return Position
    end

    local ParentBoneLimit = ParentBone.RotationLimit
    local ParentBonePosition = ParentBone.Position
    local DefaultDirection = (ParentBone.Position - GrandParentBone.Position).Unit

    local DistanceToParent = (Position - ParentBonePosition).Magnitude
    local DirectionToSelf = (Position - ParentBonePosition).Unit

    if ParentBoneLimit >= 180 then
        debug.profileend()
        return Position
    elseif ParentBoneLimit <= 0 then
        debug.profileend()
        return ParentBonePosition + DefaultDirection * DistanceToParent
    end

    local RotationLimit = math.rad(self.RotationLimit)
    local VectorAngle = math.acos(DefaultDirection:Dot(DirectionToSelf))
    local LimitedVector

	if VectorAngle >= RotationLimit then
		local Cross = DefaultDirection:Cross(DirectionToSelf).Unit
		LimitedVector = CFrame.fromAxisAngle(Cross, RotationLimit) * DefaultDirection
    else
        LimitedVector = DirectionToSelf
	end

    Position = ParentBonePosition + LimitedVector * DistanceToParent

    debug.profileend()
    return Position
end
