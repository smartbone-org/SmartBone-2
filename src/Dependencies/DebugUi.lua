local EditingBones = {}
local EditingColliders = {}

local function infoText(Iris, text)
	Iris.PushConfig({ TextColor = Iris._config.TextDisabledColor })
	Iris.Text({ text })
	Iris.PopConfig()
end

local function helpMarker(Iris, helpText)
	Iris.PushConfig({ TextColor = Iris._config.TextDisabledColor })
	local text = Iris.Text({ "(?)" })
	Iris.PopConfig()

	Iris.PushConfig({ ContentWidth = UDim.new(0, 350) })
	if text.hovered() then
		Iris.Tooltip({ helpText })
	end
	Iris.PopConfig()
end

local function BoneEditor(Iris, BoneObject)
	local Window = Iris.Window({ `Editing bone: {BoneObject.Bone.Name}` })
	Window.isOpened.value = true

	local Radius = Iris.InputNum({ "Radius", 0.1, 0, math.huge, "%.3f" }, { number = BoneObject.Radius })
	BoneObject.Radius = Radius.number.value

	local RotationLimit = Iris.InputNum({ "Rotation Limit", 0.1, 0, 180, "%.3f" }, { number = BoneObject.RotationLimit })
	BoneObject.RotationLimit = RotationLimit.number.value

	local IsAnchored = Iris.Checkbox({ "Anchored" }, { isChecked = BoneObject.Anchored })
	BoneObject.Anchored = IsAnchored.isChecked.value

	Iris.Text("Axis Lock")
	Iris.Indent()

	Iris.SameLine()
	Iris.Text("X: ")
	local XLock = Iris.Checkbox({ "" }, { isChecked = BoneObject.AxisLocked[1] })
	Iris.Text("Y: ")
	local YLock = Iris.Checkbox({ "" }, { isChecked = BoneObject.AxisLocked[2] })
	Iris.Text("Z: ")
	local ZLock = Iris.Checkbox({ "" }, { isChecked = BoneObject.AxisLocked[3] })
	Iris.End()

	Iris.End()

	local XLimit = Iris.State(Vector2.new(BoneObject.XAxisLimits.Min, BoneObject.XAxisLimits.Max))
	local YLimit = Iris.State(Vector2.new(BoneObject.YAxisLimits.Min, BoneObject.YAxisLimits.Max))
	local ZLimit = Iris.State(Vector2.new(BoneObject.ZAxisLimits.Min, BoneObject.ZAxisLimits.Max))

	Iris.Text("Axis Limits")
	Iris.Indent()

	Iris.DragVector2({ "X Axis Limit", 0.05, nil, nil, { "Min: %.2f", "Max: %.2f" } }, { number = XLimit })
	Iris.DragVector2({ "Y Axis Limit", 0.05, nil, nil, { "Min: %.2f", "Max: %.2f" } }, { number = YLimit })
	Iris.DragVector2({ "Z Axis Limit", 0.05, nil, nil, { "Min: %.2f", "Max: %.2f" } }, { number = ZLimit })

	Iris.End()

	Iris.End()

	BoneObject.AxisLocked[1] = XLock.isChecked.value
	BoneObject.AxisLocked[2] = YLock.isChecked.value
	BoneObject.AxisLocked[3] = ZLock.isChecked.value

	BoneObject.XAxisLimits = NumberRange.new(XLimit:get().X, XLimit:get().Y)
	BoneObject.YAxisLimits = NumberRange.new(YLimit:get().X, YLimit:get().Y)
	BoneObject.ZAxisLimits = NumberRange.new(ZLimit:get().X, ZLimit:get().Y)

	if Window.closed() then
		EditingBones[BoneObject] = nil
	end
end

local function ColliderEditor(Iris, Collider)
	local Window = Iris.Window({ `Editing collider of type: {Collider.Type}` })
	Window.isOpened.value = true

	local ColliderType = Iris.State(Collider.Type)
	local ColliderScale = Iris.State(Collider.Scale)
	local ColliderOffset = Iris.State(Collider.Offset)
	local ColliderRotation = Iris.State(Collider.Rotation)

	Iris.Combo({ "Collider Type" }, { index = ColliderType })
	Iris.Selectable({ "Box", "Box" }, { index = ColliderType })
	Iris.Selectable({ "Sphere", "Sphere" }, { index = ColliderType })
	Iris.Selectable({ "Capsule", "Capsule" }, { index = ColliderType })
	Iris.End()

	Iris.DragVector3({ "Scale", 0.1, 0, nil }, { number = ColliderScale })
	Iris.DragVector3({ "Offset", 0.1, nil, nil }, { number = ColliderOffset })
	Iris.DragVector3({ "Rotation", 0.5, -180, 180 }, { number = ColliderRotation })

	Collider.Type = ColliderType:get()
	Collider.Scale = ColliderScale:get()
	Collider.Offset = ColliderOffset:get()
	Collider.Rotation = ColliderRotation:get()

	Iris.End()

	if Window.closed() then
		EditingColliders[Collider] = nil
	end
end

return function(Iris, RootObject, DebugState)
	local BoneObjects = {}

	for _, BoneTree in RootObject.BoneTrees do
		local RootPart = BoneTree.RootPart

		local TreeTable = BoneObjects[RootPart]

		if not TreeTable then
			BoneObjects[RootPart] = {}
			TreeTable = BoneObjects[RootPart]
		end

		table.insert(TreeTable, BoneTree)
	end

	for Bone, _ in EditingBones do
		local BoneId = `{RootObject.ID} - {Bone.ParentIndex + 1}`

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

	local BoneTreeCount = #RootObject.BoneTrees
	local ColliderCount = #RootObject.ColliderObjects

	local BoneTreeText = `{BoneTreeCount} BoneTree{BoneTreeCount == 1 and "" or "s"}`
	local ColliderText = `{ColliderCount} Collider{ColliderCount == 1 and "" or "s"}`

	Iris.Window({ `SmartBone Runtime Editor. {BoneTreeText}, {ColliderText}`, [Iris.Args.Window.NoClose] = true })

	Iris.Tree({ "Debug Gizmos", true }, { isUncollapsed = true })

	Iris.SameLine()
	Iris.Checkbox({ "Draw Internal Bone" }, { isChecked = DebugState.DRAW_BONE })
	helpMarker(Iris, "Draws a sphere with the specified radius of the bone around where SmartBone believes the bone is.")
	Iris.End()

	Iris.SameLine()
	Iris.Checkbox({ "Draw Physical Bone" }, { isChecked = DebugState.DRAW_PHYSICAL_BONE })
	helpMarker(Iris, "Draws the actual bone objects CFrame with axis arrows.")
	Iris.End()

	Iris.SameLine()
	Iris.Checkbox({ "Draw Root Part" }, { isChecked = DebugState.DRAW_ROOT_PART })
	helpMarker(Iris, "Draws a bounding box and fills in the root part.")
	Iris.End()

	Iris.SameLine()
	Iris.Checkbox({ "Draw Bounding Box" }, { isChecked = DebugState.DRAW_BOUNDING_BOX })
	helpMarker(Iris, "Draws the bounding box used for frustum culling")
	Iris.End()

	Iris.SameLine()
	Iris.Checkbox({ "Draw Axis Limits" }, { isChecked = DebugState.DRAW_AXIS_LIMITS })
	helpMarker(Iris, "Draws the axis limits for each bone.")
	Iris.End()

	Iris.SameLine()
	Iris.Checkbox({ "Draw Rotation Limits" }, { isChecked = DebugState.DRAW_ROTATION_LIMITS })
	helpMarker(Iris, "Draws the rotation limits for each bone.")
	Iris.End()

	Iris.SameLine()
	Iris.Checkbox({ "Draw Acceleration Info" }, { isChecked = DebugState.DRAW_ACCELERATION_INFO })
	helpMarker(Iris, "Draws the acceleration and the required values to derive it.")
	Iris.End()

	Iris.SameLine()
	Iris.Checkbox({ "Draw Colliders" }, { isChecked = DebugState.DRAW_COLLIDERS })
	helpMarker(Iris, "Draws all the colliders this root object can collide with.")
	Iris.End()

	Iris.SameLine()
	Iris.Checkbox({ "Draw Collider Influence" }, { isChecked = DebugState.DRAW_COLLIDER_INFLUENCE })
	helpMarker(Iris, "Shows the sphere of influence around each collider.")
	Iris.End()

	Iris.SameLine()
	Iris.Checkbox({ "Draw Collider Awake" }, { isChecked = DebugState.DRAW_COLLIDER_AWAKE })
	helpMarker(Iris, "Shows if a collider is awake or asleep.")
	Iris.End()

	Iris.SameLine()
	Iris.Checkbox({ "Draw Collider Broadphase" }, { isChecked = DebugState.DRAW_COLLIDER_BROADPHASE })
	helpMarker(Iris, "Shows if a collider isn't reaching narrowphase.")
	Iris.End()

	Iris.SameLine()
	Iris.Checkbox({ "Draw Fill Colliders" }, { isChecked = DebugState.DRAW_FILL_COLLIDERS })
	helpMarker(Iris, "Fills all colliders this root object can collide with.")
	Iris.End()

	Iris.SameLine()
	Iris.Checkbox({ "Draw Contacts" }, { isChecked = DebugState.DRAW_CONTACTS })
	helpMarker(Iris, "Draws the position and normal of the points which bones collide with colliders.")
	Iris.End()

	Iris.End()

	Iris.Separator()

	infoText(Iris, "Simulated Objects")

	for RootPart, TreeTable in BoneObjects do
		Iris.Tree(`{RootPart.Name} - Root Part`)

		for i, BoneTree in TreeTable do
			Iris.Tree(`BoneTree #{i}`)
			local ThrottledFps = string.format("%.1f", BoneTree.UpdateRate)
			local TargetFps = string.format("%.1f", BoneTree.Settings.UpdateRate)

			infoText(Iris, `Throttled Update Rate: {ThrottledFps} / {TargetFps} fps`)
			infoText(Iris, `In View: {BoneTree.InView}`)

			local ConstraintIndex = Iris.State(BoneTree.Settings.Constraint)
			local WindIndex = Iris.State(BoneTree.Settings.WindType)

			local UpdateRate = Iris.State(BoneTree.Settings.UpdateRate)
			local ActivationDistance = Iris.State(BoneTree.Settings.ActivationDistance)
			local ThrottleDistance = Iris.State(BoneTree.Settings.ThrottleDistance)

			Iris.SameLine()
			helpMarker(Iris, "The constraint used, distance is more flowy while spring is more rigid.")
			Iris.Combo({ "Constraint Type" }, { index = ConstraintIndex })
			Iris.Selectable({ "Distance", "Distance" }, { index = ConstraintIndex })
			Iris.Selectable({ "Spring", "Spring" }, { index = ConstraintIndex })
			Iris.End()
			Iris.End()

			Iris.SameLine()
			helpMarker(Iris, "The wind solver used, sine is a smoother wind, noise is more chaotic and hybrid is a mix of the two.")
			Iris.Combo({ "Wind Type" }, { index = WindIndex })
			Iris.Selectable({ "Sine", "Sine" }, { index = WindIndex })
			Iris.Selectable({ "Noise", "Noise" }, { index = WindIndex })
			Iris.Selectable({ "Hybrid", "Hybrid" }, { index = WindIndex })
			Iris.End()
			Iris.End()

			Iris.SameLine()
			helpMarker(Iris, "The target update rate for the bone tree")
			Iris.SliderNum({ "Update Rate", 5, 0, 120 }, { number = UpdateRate })
			Iris.End()

			Iris.SameLine()
			helpMarker(Iris, "The distance at which the bone tree stops updating")
			Iris.SliderNum({ "Activation Distance", 1, 0, 500 }, { number = ActivationDistance })
			Iris.End()

			Iris.SameLine()
			helpMarker(Iris, "The distance at which the bone tree starts throttling its update rate")
			Iris.SliderNum({ "Throttle Distance", 1, 0, 500 }, { number = ThrottleDistance })
			Iris.End()

			BoneTree.Settings.Constraint = ConstraintIndex:get()
			BoneTree.Settings.WindType = WindIndex:get()
			BoneTree.Settings.UpdateRate = UpdateRate:get()
			BoneTree.Settings.ActivationDistance = ActivationDistance:get()
			BoneTree.Settings.ThrottleDistance = ThrottleDistance:get()

			Iris.Table({ 4, false, false, false })

			Iris.NextColumn()
			Iris.Text("Bone #")
			Iris.NextColumn()
			Iris.Text("Bone Name")
			Iris.NextColumn()
			Iris.Text("Parent #")
			Iris.NextColumn()
			Iris.Text("Edit")

			Iris.End()

			Iris.Table({ 4 })

			for Index, Bone in BoneTree.Bones do
				-- if Index == #BoneTree.Bones then
				-- 	break
				-- end

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
			Iris.End()
		end

		Iris.End()
	end

	infoText(Iris, "Active Colliders")

	for _, ColliderObject in RootObject.ColliderObjects do
		Iris.Tree({ ColliderObject.m_Object.Name })

		infoText(Iris, "Colliders adorned to this object")

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
			Iris.Text(tostring(Collider.Type))
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
end
