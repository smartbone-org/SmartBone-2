local EditingBones = {}
local EditingColliders = {}

local function DrawVector3(Iris, State, Min, Max)
	local CurrentVec = State:get()

	Iris.Text("X:")
	local X = Iris.DragNum({ "", 0.1, Min, Max, "%.3f" }, { number = CurrentVec.X })
	Iris.Text("Y:")
	local Y = Iris.DragNum({ "", 0.1, Min, Max, "%.3f" }, { number = CurrentVec.Y })
	Iris.Text("Z:")
	local Z = Iris.DragNum({ "", 0.1, Min, Max, "%.3f" }, { number = CurrentVec.Z })

	State:set(Vector3.new(X.number.value, Y.number.value, Z.number.value))
end

local function BoneEditor(Iris, BoneObject)
	local Window = Iris.Window({ `{BoneObject.Bone.Name} - Bone Editor` })
	Window.isOpened.value = true

	Iris.SameLine()
	Iris.Text("Radius:")
	local Radius = Iris.InputNum({ "", 0.1, 0, math.huge, "%.3f" }, { number = BoneObject.Radius })
	BoneObject.Radius = Radius.number.value
	Iris.End()

	Iris.SameLine()
	Iris.Text("Restitution:")
	local Restitution = Iris.InputNum({ "", 0.1, 0, math.huge, "%.3f" }, { number = BoneObject.Restitution })
	BoneObject.Restitution = Restitution.number.value
	Iris.End()

	Iris.SameLine()
	Iris.Text("Anchored:")
	local IsAnchored = Iris.Checkbox({ "" }, { isChecked = BoneObject.Anchored })
	BoneObject.Anchored = IsAnchored.isChecked.value
	Iris.End()

	Iris.Text("Axis Lock")
	Iris.SameLine()
	Iris.Text("X: ")
	local XAxisLocked = Iris.Checkbox({ "" }, { isChecked = BoneObject.AxisLocked[1] })
	Iris.Text("Y: ")
	local YAxisLocked = Iris.Checkbox({ "" }, { isChecked = BoneObject.AxisLocked[2] })
	Iris.Text("Z: ")
	local ZAxisLocked = Iris.Checkbox({ "" }, { isChecked = BoneObject.AxisLocked[3] })
	Iris.End()

	BoneObject.AxisLocked = {
		XAxisLocked.isChecked.value,
		YAxisLocked.isChecked.value,
		ZAxisLocked.isChecked.value,
	}

	Iris.Text("Axis Limits")
	Iris.Indent()
	Iris.Tree("X")
	Iris.SameLine()
	Iris.Text("Min: ")
	local XMin = Iris.DragNum({ "", 0.05, -math.huge, math.huge, "%.3f" }, { number = BoneObject.XAxisLimits.Min })
	Iris.End()
	Iris.SameLine()
	Iris.Text("Max: ")
	local XMax = Iris.DragNum({ "", 0.05, -math.huge, math.huge, "%.3f" }, { number = BoneObject.XAxisLimits.Max })
	Iris.End()
	Iris.End()

	Iris.Tree("Y")
	Iris.SameLine()
	Iris.Text("Min: ")
	local YMin = Iris.DragNum({ "", 0.05, -math.huge, math.huge, "%.3f" }, { number = BoneObject.YAxisLimits.Min })
	Iris.End()
	Iris.SameLine()
	Iris.Text("Max: ")
	local YMax = Iris.DragNum({ "", 0.05, -math.huge, math.huge, "%.3f" }, { number = BoneObject.YAxisLimits.Max })
	Iris.End()
	Iris.End()

	Iris.Tree("Z")
	Iris.SameLine()
	Iris.Text("Min: ")
	local ZMin = Iris.DragNum({ "", 0.05, -math.huge, math.huge, "%.3f" }, { number = BoneObject.ZAxisLimits.Min })
	Iris.End()
	Iris.SameLine()
	Iris.Text("Max: ")
	local ZMax = Iris.DragNum({ "", 0.05, -math.huge, math.huge, "%.3f" }, { number = BoneObject.ZAxisLimits.Max })
	Iris.End()
	Iris.End()

	Iris.End()

	local XMinValue = XMin.number.value
	local XMaxValue = math.max(XMinValue, XMax.number.value)

	local YMinValue = YMin.number.value
	local YMaxValue = math.max(YMinValue, YMax.number.value)

	local ZMinValue = ZMin.number.value
	local ZMaxValue = math.max(ZMinValue, ZMax.number.value)

	BoneObject.XAxisLimits = NumberRange.new(XMinValue, XMaxValue)
	BoneObject.YAxisLimits = NumberRange.new(YMinValue, YMaxValue)
	BoneObject.ZAxisLimits = NumberRange.new(ZMinValue, ZMaxValue)

	Iris.End()

	if Window.closed() then
		EditingBones[BoneObject] = nil
	end
end

local function ColliderEditor(Iris, Collider)
	local Window = Iris.Window({ `{Collider.Type} - Collider Editor` })
	Window.isOpened.value = true

	local ComboIndex = Iris.State(Collider.Type)
	local ColliderScale = Iris.State(Collider.Scale)
	local ColliderOffset = Iris.State(Collider.Offset)
	local ColliderRotation = Iris.State(Collider.Rotation)

	Iris.SameLine()
	Iris.Text("Collider Type:")
	Iris.Combo({ "" }, { index = ComboIndex })
	Iris.Selectable({ "Box", "Box" }, { index = ComboIndex })
	Iris.Selectable({ "Sphere", "Sphere" }, { index = ComboIndex })
	Iris.Selectable({ "Capsule", "Capsule" }, { index = ComboIndex })
	Iris.End()
	Iris.End()

	Iris.Tree("Scale")
	DrawVector3(Iris, ColliderScale, 0, math.huge)
	Iris.End()

	Iris.Tree("Offset")
	DrawVector3(Iris, ColliderOffset, -math.huge, math.huge)
	Iris.End()

	Iris.Tree("Rotation")
	DrawVector3(Iris, ColliderRotation, -180, 180)
	Iris.End()

	Collider.Type = ComboIndex:get()
	Collider.Scale = ColliderScale:get()
	Collider.Offset = ColliderOffset:get()
	Collider.Rotation = ColliderRotation:get()

	Iris.End()

	if Window.closed() then
		EditingColliders[Collider] = nil
	end
end

return function(Iris, BoneObject, DebugState)
	--[[
        local BoneObjects = {
            [Plane] = {
                Tree0,
                Tree1
            }
        }
    ]]

	local BoneObjects = {}

	for _, BoneTree in BoneObject.BoneTrees do
		local RootPart = BoneTree.RootPart

		local BoneTable = BoneObjects[RootPart]

		if not BoneTable then
			BoneObjects[RootPart] = {}
			BoneTable = BoneObjects[RootPart]
		end

		table.insert(BoneTable, BoneTree)
	end

	for Bone, _ in EditingBones do
		local BoneId = `{Bone.Bone.Name} - {Bone.RootPart.Name}`

		Iris.PushId(BoneId)
		BoneEditor(Iris, Bone)
		Iris.PopId()
	end

	for Collider, _ in EditingColliders do
		local ColliderId = Collider.GUID

		Iris.PushId(ColliderId)
		ColliderEditor(Iris, Collider)
		Iris.PopId()
	end

	Iris.Window({ `Bone Object Editor`, [Iris.Args.Window.NoClose] = true })

	Iris.SameLine()
	Iris.Text("Draw Bone <-")
	local DrawBone = Iris.Checkbox({ "" }, { isChecked = DebugState.DRAW_BONE })
	Iris.End()

	Iris.SameLine()
	Iris.Text("Draw Physical Bone <-")
	local DrawPhysicalBone = Iris.Checkbox({ "" }, { isChecked = DebugState.DRAW_PHYSICAL_BONE })
	Iris.End()

	Iris.SameLine()
	Iris.Text("Draw Axis Limits <-")
	local DrawAxisLimits = Iris.Checkbox({ "" }, { isChecked = DebugState.DRAW_AXIS_LIMITS })
	Iris.End()

	Iris.SameLine()
	Iris.Text("Draw Colliders <-")
	local DrawColliders = Iris.Checkbox({ "" }, { isChecked = DebugState.DRAW_COLLIDERS })
	Iris.End()

	Iris.SameLine()
	Iris.Text("Draw Contacts <-")
	local DrawContacts = Iris.Checkbox({ "" }, { isChecked = DebugState.DRAW_CONTACTS })
	Iris.End()

	Iris.SameLine()
	Iris.Text("Update Rate:")
	local UpdateRate = Iris.InputNum({ "", 1, 0, math.huge }, { number = DebugState.UpdateRate })
	Iris.End()

	DebugState.DRAW_BONE = DrawBone.isChecked.value
	DebugState.DRAW_PHYSICAL_BONE = DrawPhysicalBone.isChecked.value
	DebugState.DRAW_AXIS_LIMITS = DrawAxisLimits.isChecked.value
	DebugState.DRAW_COLLIDERS = DrawColliders.isChecked.value
	DebugState.DRAW_CONTACTS = DrawContacts.isChecked.value
	DebugState.UpdateRate = UpdateRate.number.value

	Iris.Separator()

	Iris.PushConfig({ TextColor = Iris._config.TextDisabledColor })
	Iris.Tree({ "Simulated Objects" })
	Iris.PopConfig()

	for RootPart, BoneTable in BoneObjects do
		Iris.Tree({ `{RootPart.Name} - Root Part` })

		for _, BoneTree in BoneTable do
			Iris.Table({ 4, false, false, false })

			Iris.NextColumn()
			Iris.Text("Index")
			Iris.NextColumn()
			Iris.Text("Object Name")
			Iris.NextColumn()
			Iris.Text("Parent Index")
			Iris.NextColumn()
			Iris.Text("Edit")

			Iris.End()

			Iris.Table({ 4 })

			for Index, Bone in BoneTree.Bones do
				Iris.NextColumn()
				Iris.Text(tostring(Index))
				Iris.NextColumn()
				Iris.Text(Bone.Bone.Name)
				Iris.NextColumn()
				Iris.Text(tostring(Bone.ParentIndex))
				Iris.NextColumn()
				Iris.SameLine()
				Iris.Text("")
				if Iris.SmallButton({ "Edit" }).clicked() then
					EditingBones[Bone] = true
				end
				Iris.End()
			end

			Iris.End()
		end

		Iris.End()
	end
	Iris.End()

	Iris.PushConfig({ TextColor = Iris._config.TextDisabledColor })
	Iris.Tree({ "Collider Objects" })
	Iris.PopConfig()

	for _, ColliderObject in BoneObject.Colliders do
		Iris.Tree({ ColliderObject.m_Object.Name })

		Iris.Table({ 5, false, false, false })
		Iris.NextColumn()
		Iris.Text("Type")
		Iris.NextColumn()
		Iris.Text("Scale")
		Iris.NextColumn()
		Iris.Text("Offset")
		Iris.NextColumn()
		Iris.Text("Rotation")
		Iris.NextColumn()
		Iris.Text("Edit")
		Iris.End()

		Iris.Table({ 5 })
		for _, Collider in ColliderObject.Colliders do
			Iris.NextColumn()
			Iris.Text(Collider.Type)
			Iris.NextColumn()
			Iris.Text(tostring(Collider.Scale))
			Iris.NextColumn()
			Iris.Text(tostring(Collider.Offset))
			Iris.NextColumn()
			Iris.Text(tostring(Collider.Rotation))
			Iris.NextColumn()
			Iris.SameLine()
			Iris.Text("")

			if Iris.SmallButton({ "Edit" }).clicked() then
				EditingColliders[Collider] = true
			end
			Iris.End()
		end
		Iris.End()

		Iris.End()
	end

	Iris.End()
	Iris.End()
end
