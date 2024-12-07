local RopeConstraint = require(script.Parent:WaitForChild("RopeConstraint"))

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
			CreateBone(vector.zero, 3, 0),
			CreateBone(Vector3.yAxis * 10, 3, 1),
		},
	}

	describe("Rope Constraint", function()
		local Bone = BoneTree.Bones[2]
		local i = 0

		local ReRun

		local function LimitCallback()
			local NewPosition = RopeConstraint(Bone, Bone.Position, BoneTree)

			expect(vector.magnitude(NewPosition)).to.equal(Bone.FreeLength)

			Bone.FreeLength = math.random(1, 20)

			ReRun()
		end

		local function SameCallback()
			local NewPosition = RopeConstraint(Bone, Bone.Position, BoneTree)

			expect(vector.magnitude(NewPosition)).to.equal(vector.magnitude(Bone.Position))

			Bone.FreeLength = math.random(1, 20)

			ReRun()
		end

		ReRun = function()
			if i >= 10 then
				return
			end

			i += 1

			if vector.magnitude(Bone.Position) < Bone.FreeLength then
				it(`Should stay the same #{i}`, SameCallback)
			else
				it(`Should limit to {Bone.FreeLength} studs #{i}`, LimitCallback)
			end
		end

		ReRun()
	end)
end
