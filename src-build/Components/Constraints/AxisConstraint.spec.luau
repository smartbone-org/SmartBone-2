local AxisConstraint = require(script.Parent:WaitForChild("AxisConstraint"))

return function()
	local Bone = {
		Radius = 0,
		XAxisLimits = NumberRange.new(-math.huge, math.huge),
		YAxisLimits = NumberRange.new(-math.huge, math.huge),
		ZAxisLimits = NumberRange.new(-math.huge, math.huge),
		AxisLocked = { false, false, false },
		ClipVelocity = function() end,
	}

	afterEach(function()
		Bone.AxisLocked = { false, false, false }
	end)

	describe("Axis Lock", function()
		it("Should lock X Axis", function()
			Bone.AxisLocked = { true, false, false }

			local Result = AxisConstraint(Bone, Vector3.new(-10, 0, 0), Vector3.zero, CFrame.identity)

			expect(Result.X).to.equal(0)
		end)

		it("Should lock Y Axis", function()
			Bone.AxisLocked = { false, true, false }

			local Result = AxisConstraint(Bone, Vector3.new(0, -10, 0), Vector3.zero, CFrame.identity)

			expect(Result.Y).to.equal(0)
		end)

		it("Should lock Z Axis", function()
			Bone.AxisLocked = { false, false, true }

			local Result = AxisConstraint(Bone, Vector3.new(0, 0, -10), Vector3.zero, CFrame.identity)

			expect(Result.Z).to.equal(0)
		end)
	end)

	describe("Axis Limit", function()
		describe("Should limit X Axis", function()
			it("Min Limit", function()
				Bone.XAxisLimits = NumberRange.new(-5, math.huge)

				local Result = AxisConstraint(Bone, Vector3.new(-10, 0, 0), Vector3.zero, CFrame.identity)

				expect(Result.X).to.equal(-5)
			end)

			it("Max Limit", function()
				Bone.XAxisLimits = NumberRange.new(-math.huge, 5)

				local Result = AxisConstraint(Bone, Vector3.new(10, 0, 0), Vector3.zero, CFrame.identity)

				expect(Result.X).to.equal(5)
			end)
		end)

		describe("Should limit Y Axis", function()
			it("Min Limit", function()
				Bone.YAxisLimits = NumberRange.new(-5, math.huge)

				local Result = AxisConstraint(Bone, Vector3.new(0, -10, 0), Vector3.zero, CFrame.identity)

				expect(Result.Y).to.equal(-5)
			end)

			it("Max Limit", function()
				Bone.YAxisLimits = NumberRange.new(-math.huge, 5)

				local Result = AxisConstraint(Bone, Vector3.new(0, 10, 0), Vector3.zero, CFrame.identity)

				expect(Result.Y).to.equal(5)
			end)
		end)

		describe("Should limit Z Axis", function()
			it("Min Limit", function()
				Bone.ZAxisLimits = NumberRange.new(-5, math.huge)

				local Result = AxisConstraint(Bone, Vector3.new(0, 0, -10), Vector3.zero, CFrame.identity)

				expect(Result.Z).to.equal(-5)
			end)

			it("Max Limit", function()
				Bone.ZAxisLimits = NumberRange.new(-math.huge, 5)

				local Result = AxisConstraint(Bone, Vector3.new(0, 0, 10), Vector3.zero, CFrame.identity)

				expect(Result.Z).to.equal(5)
			end)
		end)
	end)
end
