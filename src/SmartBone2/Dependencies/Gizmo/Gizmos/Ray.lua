--- @class Ray
--- Renders a line between two points.
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

--- @within Ray
--- @function Draw
--- @param Origin Vector3
--- @param End Vector3
function Gizmo:Draw(Origin: Vector3, End: Vector3)
	local Ceive = self.Ceive
	
	if not Ceive.Enabled then
		return
	end
	
	if self.Propertys.AlwaysOnTop then
		Ceive.AOTWireframeHandle:AddLine(Origin, End)
	else
		Ceive.WireframeHandle:AddLine(Origin, End)
	end
	
	self.Ceive.ActiveRays += 1
	
	self.Ceive.ScheduleCleaning()
end

--- @within Ray
--- @function Create
--- @param Origin Vector3
--- @param End Vector3
--- @return {Origin: Vector3, End: Vector3, Color3: Color3, AlwaysOnTop: boolean, Transparency: number}
function Gizmo:Create(Origin: Vector3, End: Vector3)
	local PropertyTable = {
		Origin = Origin,
		End = End,
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
	
	self:Draw(PropertyTable.Origin, PropertyTable.End)
end

return Gizmo