return function(self, Position, BoneTree)
	local ParentBone = BoneTree.Bones[self.ParentIndex]

	if ParentBone then
		local RestLength = self.FreeLength
		local BoneSub = (Position - ParentBone.Position)
		local BoneDirection = BoneSub.Unit
		local BoneDistance = math.min(BoneSub.Magnitude, RestLength)

		local RestPosition = ParentBone.Position + (BoneDirection * BoneDistance)

		return RestPosition
	end
end
