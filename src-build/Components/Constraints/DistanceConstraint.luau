local function SafeUnit(v3)
	if v3.Magnitude == 0 then
		return Vector3.zero
	end

	return v3.Unit
end

return function(self, Position, BoneTree)
do end	
local ParentBone = BoneTree.Bones[self.ParentIndex]

	if ParentBone then
		local RestLength = self.FreeLength
		local BoneDirection = SafeUnit(Position - ParentBone.Position)

		local RestPosition = ParentBone.Position + (BoneDirection * RestLength)
do end		

return RestPosition
	end
do end	

return
end
