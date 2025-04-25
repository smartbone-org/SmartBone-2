local function SafeUnit(v3)
	if v3.Magnitude == 0 then
		return Vector3.zero
	end

	return v3.Unit
end

local inf = math.huge

return function(self, Position, LastPosition, RootCFrame)
do end	
local RootOffset = RootCFrame:Inverse() * Position

	local X = RootOffset.X
	local Y = RootOffset.Y
	local Z = RootOffset.Z

	local XLimit = self.XAxisLimits
	local YLimit = self.YAxisLimits
	local ZLimit = self.ZAxisLimits

	local XLock = self.AxisLocked[1] and 0 or 1
	local YLock = self.AxisLocked[2] and 0 or 1
	local ZLock = self.AxisLocked[3] and 0 or 1

	-- Most bones probably wont have an axis limit, this allows us to skip all the other stuff
	if XLimit.Min == -inf and XLimit.Max == inf and YLimit.Min == -inf and YLimit.Max == inf and ZLimit.Min == -inf and ZLimit.Max == inf then
		if XLock == 1 and YLock == 1 and ZLock == 1 then
do end			
return Position
		else
			return RootCFrame * Vector3.new(X * XLock, Y * YLock, Z * ZLock)
		end
	end

	-- If our radius is > than the diff between min and max
	-- We do this because its faster than math.min() ¯\_(ツ)_/¯
	local XMin = XLimit.Min + self.Radius
	local XMax = XMin <= (XLimit.Max - self.Radius) and XLimit.Max - self.Radius or XMin

	local YMin = YLimit.Min + self.Radius
	local YMax = YMin <= (YLimit.Max - self.Radius) and YLimit.Max - self.Radius or YMin

	local ZMin = ZLimit.Min + self.Radius
	local ZMax = ZMin <= (ZLimit.Max - self.Radius) and ZLimit.Max - self.Radius or ZMin

	X = X < XMin and XMin or (X > XMax and XMax or X)
	Y = Y < YMin and YMin or (Y > YMax and YMax or Y)
	Z = Z < ZMin and ZMin or (Z > ZMax and ZMax or Z)

	X *= XLock
	Y *= YLock
	Z *= ZLock

	local WorldSpace = RootCFrame * Vector3.new(X, Y, Z)

	Position = WorldSpace

	local XAxis = RootCFrame.RightVector
	local YAxis = RootCFrame.UpVector
	local ZAxis = RootCFrame.LookVector

	local DifferenceDirection = SafeUnit(Position - LastPosition)

	-- Remove our velocity on the vectors we collided with, stops any weird jittering.
	if X ~= RootOffset.X then
		local Normal = XAxis:Dot(DifferenceDirection) < 0 and -XAxis or XAxis
		self:ClipVelocity(Position, Normal)
	end

	if Y ~= RootOffset.Y then
		local Normal = YAxis:Dot(DifferenceDirection) < 0 and -YAxis or YAxis
		self:ClipVelocity(Position, Normal)
	end

	if Z ~= RootOffset.Z then
		local Normal = ZAxis:Dot(DifferenceDirection) > 0 and -ZAxis or ZAxis
		self:ClipVelocity(Position, Normal)
	end
do end
	
return Position
end
