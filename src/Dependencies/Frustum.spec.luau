local Frustum = require(script.Parent:WaitForChild("Frustum"))

return function()
	local FakeCamera = {
		CFrame = CFrame.identity,
		FieldOfView = 70,
		ViewportSize = Vector2.new(1920, 1080),
	}

	local ReturnedCFrames = {}

	describe("Generates CFrames", function()
		local SolveStart = os.clock()
		local SolveEnd

		ReturnedCFrames = table.pack(Frustum.GetCFrames(FakeCamera, 500))
		SolveEnd = os.clock()

		ReturnedCFrames["n"] = nil

		print(`Solved view frustum in {string.format("%.2f", (SolveEnd - SolveStart) * 1e6)}μs`)
	end)

	describe("Point In View", function()
		local CloseInView = Vector3.new(0, 0, -5)
		local FarPlaneView = Vector3.new(0, 0, -550)
		local OutOfView = Vector3.new(0, 0, 5)

		it("Close In View Point", function()
			expect(Frustum.InViewFrustum(CloseInView, table.unpack(ReturnedCFrames))).to.equal(true)
		end)

		it("Past FarPlane Point", function()
			expect(Frustum.InViewFrustum(FarPlaneView, table.unpack(ReturnedCFrames))).to.equal(false)
		end)

		it("Out Of View Point", function()
			expect(Frustum.InViewFrustum(OutOfView, table.unpack(ReturnedCFrames))).to.equal(false)
		end)
	end)

	describe("Object In View", function()
		local CloseFakeObject = {
			CFrame = CFrame.new(0, 0, -5),
			Size = Vector3.new(1, 1, 3),
		}

		local FarFakeObject = {
			CFrame = CFrame.new(0, 0, -550),
			Size = Vector3.new(1, 1, 3),
		}

		local OutOfViewFakeObject = {
			CFrame = CFrame.new(0, 0, 5),
			Size = Vector3.new(1, 1, 3),
		}

		it("Close In View Object", function()
			expect(Frustum.ObjectInFrustum(CloseFakeObject, table.unpack(ReturnedCFrames))).to.equal(true)
		end)

		it("Past FarPlane Object", function()
			expect(Frustum.ObjectInFrustum(FarFakeObject, table.unpack(ReturnedCFrames))).to.equal(false)
		end)

		it("Out Of View Object", function()
			expect(Frustum.ObjectInFrustum(OutOfViewFakeObject, table.unpack(ReturnedCFrames))).to.equal(false)
		end)
	end)
end
