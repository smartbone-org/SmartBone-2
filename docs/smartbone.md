---
sidebar_position: 2
---
# SmartBone

### Setup

- Select any MeshPart with Bones under it

- Add the tag “SmartBone” to the MeshPart.

- Add a string attribute called “Roots” to the MeshPart and fill it with the name(s) of the bone(s) you want to be root(s).

- Separate each bone name with “,” and the Module will automatically sort your bone(s) into a list.

- An example of a SmartBone object with multiple roots would have a Roots attribute that looks like this: “Root1,Root2,Root3”

- Make sure you don’t add any spaces or characters unless they are part of the name of the bone(s) you want to be included

### Friction

Friction is controlled by the root part and the colliding objects physical properties.

### Constraints

Each constraint has it's own purpose,

- Spring will return the bone to its rest position sort of like jelly

- Distance will keep the bones at a fixed distance from eachother and is always pulled downwards

- Rope will keep the bones distance between 0 and their rest length and is always pulled downwards

---
### Attributes

**All attributes listed here are optional and not required to get a SmartBone object working.**

- \[*Any*\] Debug - If this attribute exists in a SmartBone object then the SmartBone Runtime Editor will appear allowing you to change attributes and visualise certain things in real time.

- \[*Number*\] Damping – How slowed down the calculated motion of the SmartBone(s) will be.

- \[*Number*\] Stiffness – How much of the bone(s) original CFrame is preserved.

- \[*Number*\] Inertia – How much the of the movement of the object is ignored.

- \[*Number*\] Elasticity – How much force is applied to return each bone to its original CFrame.

- \[*Vector3*\] Gravity – Direction and Magnitude of Gravity in World Space.

- \[*Vector3*\] Force – Additional Force applied to Bones in World Space. Supplementary to Gravity.

- \[*String*\] Constraint - Option between Spring, Distance and Rope.

- \[*String*\] WindType - Option between Sine, Noise and Hybrid.

- \[*Boolean*\] MatchWorkspaceWind - If true then wind is dependent on workspace.GlobalWind.

- \[*Number*\] WindInfluence – How much influence wind has on the SmartBone object.

- \[*Number*\] WindStrength - The "density" of the air.

- \[*Number*\] WindSpeed - The speed which wind travels at, only important if MatchWorkspaceWind is false.

- \[*Vector3*\] WindDirection - The direction in which the wind travels, only important if MatchWorkspaceWind is false.

- \[*String*\] ColliderKey - If this attribute is set then the object will only collide with colliders that have the same collider key.

- \[*Number*\] AnchorDepth – This will determine how far down in heirarchy from the Root that bones will be Anchored.

- \[*Boolean*\] AnchorsRotate – If true, the root bone(s) will rotate along with the rest of the bone(s), but remain in static position. If false, the root bone(s) will remain completely static in both Position and Orientation.

- \[*Number*\] UpdateRate – The rate in frames-per-second at which SmartBone will simulate.

- \[*Number*\] ActivationDistance – The distance in studs at which the SmartBone stops simulation.

- \[*Number*\] ThrottleDistance – The distance in studs at which the SmartBone begins to throttle simulation rates based on distance. Scales based on UpdateRate.
