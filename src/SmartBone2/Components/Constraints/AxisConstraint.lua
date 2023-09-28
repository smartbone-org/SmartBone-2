return function(self, Position, RootCFrame)
	debug.profilebegin("Axis Constraint")
	local RootOffset = RootCFrame:PointToObjectSpace(Position)

	local X = RootOffset.X
	local Y = RootOffset.Y
	local Z = RootOffset.Z

	local XLimit = self.XAxisLimits
	local YLimit = self.YAxisLimits
	local ZLimit = self.ZAxisLimits

	local XLock = self.AxisLocked[1] and 0 or 1
	local YLock = self.AxisLocked[2] and 0 or 1
	local ZLock = self.AxisLocked[3] and 0 or 1

	-- If our radius is > than the diff between min and max
	local XMin = XLimit.Min + self.Radius
	local XMax = XMin <= (XLimit.Max - self.Radius) and XLimit.Max - self.Radius or XMin

	local YMin = YLimit.Min + self.Radius
	local YMax = YMin <= (YLimit.Max - self.Radius) and YLimit.Max - self.Radius or YMin

	local ZMin = ZLimit.Min + self.Radius
	local ZMax = ZMin <= (ZLimit.Max - self.Radius) and ZLimit.Max - self.Radius or ZMin

	X = math.clamp(X, XMin, XMax)
	Y = math.clamp(Y, YMin, YMax)
	Z = math.clamp(Z, ZMin, ZMax)

	X *= XLock
	Y *= YLock
	Z *= ZLock

	local WorldSpace = RootCFrame:PointToWorldSpace(Vector3.new(X, Y, Z))

	Position = WorldSpace

	local XAxis = RootCFrame.RightVector
	local YAxis = RootCFrame.UpVector
	local ZAxis = RootCFrame.LookVector

	-- Remove our velocity on the vectors we collided with, stops any weird jittering.
	if X ~= RootOffset.X then
		local Normal = X == XMin and XAxis or -XAxis -- If we are colliding with the XMin limit then use the XAxis if we collide with XMax then use -XAxis
		self:ClipVelocity(Position, Normal)
	end

	if Y ~= RootOffset.Y then
		local Normal = Y == YMin and YAxis or -YAxis
		self:ClipVelocity(Position, Normal)
	end

	if Z ~= RootOffset.Z then
		local Normal = Z == ZMin and ZAxis or -ZAxis
		self:ClipVelocity(Position, Normal)
	end
	debug.profileend()

	return Position
end
