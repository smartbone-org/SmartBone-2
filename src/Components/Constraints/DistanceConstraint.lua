local function SafeUnit(v3)
	if vector.magnitude(v3) == 0 then
		return vector.zero
	end

	return vector.normalize(v3)
end

return function(self, Position, BoneTree)
	debug.profilebegin("Distance Constraint")
	local ParentBone = BoneTree.Bones[self.ParentIndex]

	if ParentBone then
		local RestLength = self.FreeLength
		local BoneDirection = SafeUnit(Position - ParentBone.Position)

		local RestPosition = ParentBone.Position + (BoneDirection * RestLength)

		debug.profileend()
		return RestPosition
	end

	debug.profileend()
	return
end
