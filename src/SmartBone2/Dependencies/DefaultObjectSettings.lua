local FORCE_MULTIPLIER = 0.2

return {
	Damping = 0.1,
	Stiffness = 0.2,
	Inertia = 0,
	Elasticity = 3,
	BlendWeight = 1,
	AnchorDepth = 0,
	Constraint = "Distance",
	WindType = "Hybrid",
	Force = Vector3.yAxis * FORCE_MULTIPLIER,
	Gravity = -Vector3.yAxis,
	WindInfluence = 1,
	WindStrength = 2,
	AnchorsRotate = false,
	UpdateRate = 60,
	ActivationDistance = 45,
	ThrottleDistance = 15,
}
