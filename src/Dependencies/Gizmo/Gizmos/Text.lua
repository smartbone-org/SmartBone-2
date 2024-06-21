local DROP_SHADOW = true
local OFFSET_PERCENTAGE = 0.00175

local Camera = workspace.CurrentCamera

local Gizmo = {}
Gizmo.__index = Gizmo

function Gizmo.Init(Ceive, Propertys, Request, Release, Retain)
	local self = setmetatable({}, Gizmo)

	self.Ceive = Ceive
	self.Propertys = Propertys
	self.Request = Request
	self.Release = Release
	self.Retain = Retain

	return self
end

function Gizmo:Draw(Origin: Vector3, Text: string, Size: number?)
	local Ceive = self.Ceive

	if not Ceive.Enabled then
		return
	end

	if self.Propertys.AlwaysOnTop then
		if DROP_SHADOW then
			local DistanceToCamera = (Origin - Camera.CFrame.Position).Magnitude
			local PrevColor = Ceive.PopProperty("Color3")

			Ceive.PushProperty("Color3", Color3.new())
			local Offset = -(Vector3.xAxis + Vector3.yAxis).Unit
			Ceive.AOTWireframeHandle:AddText(Origin + Offset * (DistanceToCamera * OFFSET_PERCENTAGE), Text, Size)
			Ceive.PushProperty("Color3", PrevColor)
		end

		Ceive.AOTWireframeHandle:AddText(Origin, Text, Size)
	else
		if DROP_SHADOW then
			local DistanceToCamera = (Origin - Camera.CFrame.Position).Magnitude
			local PrevColor = Ceive.PopProperty("Color3")

			Ceive.PushProperty("Color3", Color3.new())
			local Offset = -(Vector3.xAxis + Vector3.yAxis).Unit
			Ceive.WireframeHandle:AddText(Origin + Offset * (DistanceToCamera * OFFSET_PERCENTAGE), Text, Size)
			Ceive.PushProperty("Color3", PrevColor)
		end

		Ceive.WireframeHandle:AddText(Origin, Text, Size)
	end

	-- Should text count to active rays?
	--self.Ceive.ActiveRays += 1

	self.Ceive.ScheduleCleaning()
end

function Gizmo:Create(Origin: Vector3, Text: string, Size: number?)
	local PropertyTable = {
		Origin = Origin,
		Text = Text,
		Size = Size,
		AlwaysOnTop = self.Propertys.AlwaysOnTop,
		Transparency = self.Propertys.Transparency,
		Color3 = self.Propertys.Color3,
		Enabled = true,
		Destroy = false,
	}

	self.Retain(self, PropertyTable)

	return PropertyTable
end

function Gizmo:Update(PropertyTable)
	local Ceive = self.Ceive

	Ceive.PushProperty("AlwaysOnTop", PropertyTable.AlwaysOnTop)
	Ceive.PushProperty("Transparency", PropertyTable.Transparency)
	Ceive.PushProperty("Color3", PropertyTable.Color3)

	self:Draw(PropertyTable.Origin, PropertyTable.Text, PropertyTable.Size)
end

return Gizmo
