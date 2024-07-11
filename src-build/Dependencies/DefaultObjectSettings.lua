local FORCE_MULTIPLIER = 0.2

return {
	Damping = 0.1,
	Stiffness = 0.2,
	Inertia = 0,
	Elasticity = 3,
	AnchorDepth = 0,

	AnchorsRotate = false,

	Constraint = "Spring",
	Force = Vector3.yAxis * FORCE_MULTIPLIER,
	Gravity = -Vector3.yAxis,

	WindType = "Hybrid",
	MatchWorkspaceWind = true,
	WindInfluence = 1,
	WindStrength = 2,
	WindSpeed = 1,
	WindDirection = Vector3.xAxis,

	UpdateRate = 60,
	ActivationDistance = 45,
	ThrottleDistance = 15,
}
