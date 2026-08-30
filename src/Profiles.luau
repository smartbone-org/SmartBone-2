--[[

	Named setting presets, selected per object with a string attribute called "Profile".

	A profile only has to list the keys it wants to change, anything it leaves out falls back to
	DefaultObjectSettings. Individual attributes on the object still override the profile, so a
	profile is a starting point rather than a lock.

	Keys are the same ones in the docs & in DefaultObjectSettings.

	Example:

		Curtain = {
			Damping = 0.2,
			Stiffness = 0.5,
			Constraint = "Rope",
			AnchorDepth = 1,
		},

]]

return table.freeze({})
