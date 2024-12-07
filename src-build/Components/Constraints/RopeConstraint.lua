local function SafeUnit(v3)
	if vector.magnitude(v3) == 0 then
		return vector.zero
	end

	return vector.normalize(v3)
end

return function(self, Position, BoneTree)
	do
	end
	local ParentBone = BoneTree.Bones[self.ParentIndex]

	if ParentBone then
		local RestLength = self.FreeLength
		local BoneSub = (Position - ParentBone.Position)
		local BoneDirection = SafeUnit(BoneSub)
		local BoneDistance = vector.magnitude(BoneSub) < RestLength and vector.magnitude(BoneSub) or RestLength

		local RestPosition = ParentBone.Position + (BoneDirection * BoneDistance)
		do
		end

		return RestPosition
	end
	do
	end

	return
end
