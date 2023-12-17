return function(self, Position, BoneTree)
	debug.profilebegin("Distance Constraint")
	local ParentBone = BoneTree.Bones[self.ParentIndex]

	if ParentBone then
		local RestLength = self.FreeLength
		local BoneDirection = (Position - ParentBone.Position).Unit

		local RestPosition = ParentBone.Position + (BoneDirection * RestLength)

		debug.profileend()
		return RestPosition
	end

	debug.profileend()
	return
end
