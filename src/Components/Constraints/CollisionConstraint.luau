return function(self, Position, Colliders)
	debug.profilebegin("Collision Constraint")
	local Collisions = self.CollisionsData
	local HitParts = self.CollisionHits

	table.clear(Collisions)
	table.clear(HitParts)

	for _, Collider in Colliders do
		if Collider:GetCollisions(Position, self.Radius, Collisions) then
			table.insert(HitParts, Collider:GetObject())
		end
	end

	for _, Collision in Collisions do
		Position = Collision.ClosestPoint + (Collision.Normal * self.Radius)
		-- self:ClipVelocity(Position, Collision.Normal) -- This causes some weird glitching issues, not sure why tbh
	end
	debug.profileend()

	return Position
end
