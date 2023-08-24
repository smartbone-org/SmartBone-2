local function ReflectVector(Direction, SurfaceNormal)
	return (Direction - (2 * Direction:Dot(SurfaceNormal) * SurfaceNormal))
end

return function(self, Position, Colliders)
	debug.profilebegin("Collision Constraint")
	local Collisions = {}

	for _, Collider in Colliders do
		local ColliderCollisions = Collider:GetCollisions(Position, self.Radius)
		for _, Collision in ColliderCollisions do
			table.insert(Collisions, Collision)
		end
	end

	for _, Collision in Collisions do
		Position = Collision.ClosestPoint + (Collision.Normal * self.Radius)
		-- self:ClipVelocity(Position, Collision.Normal) -- This causes some weird glitching issues, not sure why tbh

		local NormalVelocity = (self.PreviousVelocity * Collision.Normal).Magnitude * self.Restitution
		local Impulse = ReflectVector(-Collision.Normal, Collision.Normal) * NormalVelocity

		self:ImpulseVelocity(Impulse)
	end

	self.CollisionsData = Collisions
	debug.profileend()

	return Position
end
