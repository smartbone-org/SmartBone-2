return function(self, Position, Colliders)
do end	
local Collisions = {}
	local HitParts = {}

	for _, Collider in Colliders do
		local ColliderCollisions = Collider:GetCollisions(Position, self.Radius)

		if #ColliderCollisions > 0 then
			table.insert(HitParts, Collider:GetObject())
		end

		for _, Collision in ColliderCollisions do
			table.insert(Collisions, Collision)
		end
	end

	for _, Collision in Collisions do
		Position = Collision.ClosestPoint + (Collision.Normal * self.Radius)
		-- self:ClipVelocity(Position, Collision.Normal) -- This causes some weird glitching issues, not sure why tbh
	end

	self.CollisionsData = Collisions
	self.CollisionHits = HitParts
do end
	
return Position
end
