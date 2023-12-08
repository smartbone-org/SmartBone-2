return function(self, Position, LastPosition)
	local Alpha = 1 - self.Friction

	return LastPosition:Lerp(Position, Alpha)
end
