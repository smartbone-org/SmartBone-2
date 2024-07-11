--!native
return function(self, Position, RestPosition, BoneTree, Delta)
do end
	
local Settings = BoneTree.Settings
	local Stiffness = Settings.Stiffness
	local Elasticity = Settings.Elasticity

	local ParentBone = BoneTree.Bones[self.ParentIndex]

	if ParentBone then
		local RestLength = self.FreeLength

		if Stiffness > 0 or Elasticity > 0 then
			local ParentBoneCFrame = CFrame.new(ParentBone.Position) * ParentBone.TransformOffset.Rotation
			RestPosition = RestPosition or (ParentBoneCFrame * CFrame.new(self.LocalTransformOffset.Position)).Position

			local ElasticDifference = RestPosition - Position
			Position += ElasticDifference * (Elasticity * Delta)

			if Stiffness > 0 then
				local StiffDifference = RestPosition - Position
				local Length = StiffDifference.Magnitude
				local MaxLength = RestLength * (1 - Stiffness) * 2
				if Length > MaxLength then
					Position += StiffDifference * ((Length - MaxLength) / Length)
				end
			end
		end

		local Difference = ParentBone.Position - Position
		local Length = Difference.Magnitude
		if Length > 0 then
			Position += Difference * ((Length - RestLength) / Length)
		end
	end
do end
	
return Position
end
