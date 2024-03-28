local DistanceConstraint = require(script.Parent:WaitForChild("DistanceConstraint"))

local function CreateBone(Position, FreeLength, Parent)
	return {
		Position = Position,
		FreeLength = FreeLength,
		ParentIndex = Parent,
	}
end

return function()
	local BoneTree = {
		Bones = {
			CreateBone(Vector3.zero, 3, 0),
			CreateBone(Vector3.yAxis, 3, 1),
		},
	}

	describe("Distance Constraint", function()
		local Bone = BoneTree.Bones[2]

		local function Callback()
			local NewPosition = DistanceConstraint(Bone, Bone.Position, BoneTree)

			expect(NewPosition.Magnitude).to.equal(Bone.FreeLength)

			Bone.Position = NewPosition
		end

		for i = 1, 10 do
			it(`Should limit to {Bone.FreeLength} studs #{i}`, Callback)
			Bone.FreeLength = math.random(1, 20)
		end
	end)
end
