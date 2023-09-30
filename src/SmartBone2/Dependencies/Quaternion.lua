-- v1.1.1

export type Quaternion = {
	-- Constructors

	new: (qX: number?, qY: number?, qZ: number?, qW: number?) -> Quaternion,
	fromAxisAngle: (axis: Vector3, angle: number) -> Quaternion,
	fromAxisAngleFast: (axis: Vector3, angle: number) -> Quaternion,
	fromCFrame: (cframe: CFrame) -> Quaternion,
	fromCFrameFast: (cframe: CFrame) -> Quaternion,
	fromMatrix: (vX: Vector3, vY: Vector3, vZ: Vector3?) -> Quaternion,
	fromMatrixFast: (vX: Vector3, vY: Vector3, vZ: Vector3?) -> Quaternion,
	lookAt: (from: Vector3, lookAt: Vector3, up: Vector3?) -> Quaternion,
	fromEulerAnglesXYZ: (rx: number, ry: number, rz: number) -> Quaternion,
	Angles: (rx: number, ry: number, rz: number) -> Quaternion,
	fromEulerAnglesYXZ: (rx: number, ry: number, rz: number) -> Quaternion,
	fromOrientation: (rx: number, ry: number, rz: number) -> Quaternion,
	fromEulerAngles: (rx: number, ry: number, rz: number, rotationOrder: Enum.RotationOrder?) -> Quaternion,
	fromVector: (vector: Vector3) -> Quaternion,
	RandomQuaternion: (seed: number) -> () -> Quaternion,

	-- Constants

	identity: Quaternion,
	zero: Quaternion,

	-- Properties

	X: number,
	Y: number,
	Z: number,
	W: number,
	Unit: Quaternion,
	Magnitude: number,

	-- Math operations / metamethods

	--[[ 
    add:
        Quaternion + Quaternion -> Quaternion
    
    sub:
        Quaternion - Quaternion -> Quaternion
        
    mul:
        Quaternion * Quaternion -> Quaternion
        Quaternion * number -> Quaternion
        number * Quaternion -> Quaternion
        Quaternion * CFrame -> CFrame
        Quaternion * Vector3 -> Vector3
        Vector3 * Quaternion -> CFrame
    
    
    div:
        Quaternion / Quaternion -> Quaternion
        Quaternion / number -> Quaternion
        number / Quaternion -> Quaternion
        
    unm:
        -Quaternion -> Quaternion
    
    pow:
        Quaternion ^ number -> Quaternion
    
    len:
        #Quaternion -> number
        
    lt (a < b  <internal>->  b > a):
        Quaternion < Quaternion
    
    le (a <= b  <internal>->  b >= a):
        Quaternion <= Quaternion
    
    eq (a == b): (a ~= b  <internal>->  not(a == b))
        Quaternion == Quaternion
    
    --]]

	-- Methods

	Exp: (q0: Quaternion) -> Quaternion,
	ExpMap: (q0: Quaternion, q1: Quaternion) -> Quaternion,
	ExpMapSym: (q0: Quaternion, q1: Quaternion) -> Quaternion,
	Log: (q0: Quaternion) -> Quaternion,
	LogMap: (q0: Quaternion, q1: Quaternion) -> Quaternion,
	LogMapSym: (q0: Quaternion, q1: Quaternion) -> Quaternion,
	LogInv: (q0: Quaternion, q1: Quaternion) -> Quaternion,
	Length: (q0: Quaternion) -> number,
	LengthSquared: (q0: Quaternion) -> number,
	Hypot: (q0: Quaternion) -> number,
	Normalize: (q0: Quaternion) -> Quaternion,
	IsUnit: (q0: Quaternion, epsilon: number) -> boolean,
	Dot: (q0: Quaternion, q1: Quaternion) -> number,
	Conjugate: (q0: Quaternion) -> Quaternion,
	Inverse: (q0: Quaternion) -> Quaternion,
	Negate: (q0: Quaternion) -> Quaternion,
	Difference: (q0: Quaternion, q1: Quaternion) -> Quaternion,
	Distance: (q0: Quaternion, q1: Quaternion) -> number,
	DistanceSym: (q0: Quaternion, q1: Quaternion) -> number,
	DistanceChord: (q0: Quaternion, q1: Quaternion) -> number,
	DistanceAbs: (q0: Quaternion, q1: Quaternion) -> number,
	Slerp: (q0: Quaternion, q1: Quaternion, alpha: number) -> Quaternion,
	IdentitySlerp: (q1: Quaternion, alpha: number) -> Quaternion,
	SlerpFunction: (q0: Quaternion, q1: Quaternion) -> (alpha: number) -> Quaternion,
	Intermediates: (q0: Quaternion, q1: Quaternion, n: number, includeEndpoints: boolean?) -> { Quaternion },
	Derivative: (q0: Quaternion, rate: Vector3) -> Quaternion,
	Integrate: (q0: Quaternion, rate: Vector3, timestep: number) -> Quaternion,
	ApproxEq: (q0: Quaternion, q1: Quaternion, epsilon: number) -> boolean,
	IsNaN: (q0: Quaternion) -> boolean,

	-- Deconstructors

	ToCFrame: (q0: Quaternion, position: Vector3?) -> CFrame,
	ToAxisAngle: (q0: Quaternion) -> (Vector3, number),
	ToEulerAnglesXYZ: (q0: Quaternion) -> (number, number, number),
	ToEulerAnglesYXZ: (q0: Quaternion) -> (number, number, number),
	ToOrientation: (q0: Quaternion) -> (number, number, number),
	ToEulerAngles: (q0: Quaternion, rotationOrder: Enum.RotationOrder?) -> (number, number, number),
	ToMatrix: (q0: Quaternion) -> (number, number, number, number, number, number, number, number, number),
	ToMatrixVectors: (q0: Quaternion) -> (Vector3, Vector3, Vector3),
	Vector: (q0: Quaternion) -> Vector3,
	Scalar: (q0: Quaternion) -> number,
	Imaginary: (q0: Quaternion) -> Quaternion,
	GetComponents: (q0: Quaternion) -> (number, number, number, number),
	components: (q0: Quaternion) -> (number, number, number, number),
	ToString: (q0: Quaternion, decimalPlaces: number?) -> string,
}

local EPSILON = 1e-6

--[=[
    @class Quaternion
    @grouporder ["Constructors", "Methods", "Deconstructors", "Math Operations"]
    
    Quaternions represent rotations in 3D space.
    
    It is important to note that quaternions have double cover, meaning 
    that `q0` and `-q0` encode the same rotation.
    
    
    This class is **immutable** which means once a quaternion has been
    created, its components cannot be changed. All methods create new
    quaternions.
]=]
--[=[
    @prop X number
--]=]
--[=[
    @prop Y number
--]=]
--[=[
    @prop Z number
--]=]
--[=[
    @prop W number
--]=]
--[=[
    @prop Unit Quaternion
    
    A quaternion with unit length. Result is cached.
]=]
--[=[
    @prop Magnitude number
    
    Returns the magnitude of the quaternion.
    Result is cached.
]=]
--[=[
    @prop identity Quaternion
    
    An identity quaternion with no rotation. 
    This is constant and should be accessed through the Quaternion class 
    rather than an individual Quaternion object.
]=]
--[=[
    @prop zero Quaternion
    
    The zero quaternion, this does not represent any 
    rotation as it has a magnitude of zero. This is a constant and should 
    be  accessed through the Quaternion class rather than an individual 
    Quaternion object.
]=]
local Quaternion = { _type = "Quaternion" }

-- Internal functions for type checking and throwing errors

local function GetType(obj: any): string
	if obj == nil then
		return "nil"
	end
	local objMetatable = getmetatable(obj)
	if type(objMetatable) == "table" and objMetatable._type ~= nil then
		return tostring(objMetatable._type)
	else
		return typeof(obj)
	end
end

local function _safeUnit(vector: Vector3, default: Vector3): Vector3
	if vector.Magnitude > EPSILON then
		return vector.Unit
	else
		return default
	end
end

--[=[
    @function
    @group Constructors
    
    Creates a new quaternion with X, Y, Z, W values, where the 
    X, Y, Z are the imaginary components and the W component is the real 
    component.
]=]
local function new(qX: number?, qY: number?, qZ: number?, qW: number?): Quaternion
	local self = setmetatable({
		X = qX or 0,
		Y = qY or 0,
		Z = qZ or 0,
		W = qW or 1,
		_cached = {},
	} :: any, Quaternion)

	table.freeze(self)

	return self
end

Quaternion.new = new
Quaternion.identity = new(0, 0, 0, 1)
Quaternion.zero = new(0, 0, 0, 0)

-- Private Methods

local function _Orthonormalize(rightVector: Vector3, upVector: Vector3, backVector: Vector3): (Vector3, Vector3, Vector3)
	local xBasis = _safeUnit(rightVector, Vector3.xAxis)
	local _upVector = _safeUnit(upVector, Vector3.yAxis)

	local zBasis = xBasis:Cross(_upVector)
	if zBasis.Magnitude > EPSILON then
		zBasis = zBasis.Unit
	else
		zBasis = xBasis:Cross(Vector3.yAxis)
		if zBasis.Magnitude > EPSILON then
			zBasis = zBasis.Unit
		else
			zBasis = Vector3.xAxis
		end
	end

	local yBasis = zBasis:Cross(xBasis).Unit
	if zBasis:Dot(backVector) < 0 then
		zBasis = -zBasis
	end
	return xBasis, yBasis, zBasis
end

local function _fromOrthonormalizedMatrix(vX: Vector3, vY: Vector3, vZ: Vector3): Quaternion
	local m00, m10, m20 = vX.X, vX.Y, vX.Z
	local m01, m11, m21 = vY.X, vY.Y, vY.Z
	local m02, m12, m22 = vZ.X, vZ.Y, vZ.Z

	local trace = m00 + m11 + m22

	local qX, qY, qZ, qW

	if trace > 0 then
		local S = math.sqrt(trace + 1) * 2
		qX = (m21 - m12) / S
		qY = (m02 - m20) / S
		qZ = (m10 - m01) / S
		qW = 0.25 * S
	elseif m00 > m11 and m00 > m22 then
		local S = math.sqrt(1 + m00 - m11 - m22) * 2
		qX = 0.25 * S
		qY = (m01 + m10) / S
		qZ = (m02 + m20) / S
		qW = (m21 - m12) / S
	elseif m11 > m22 then
		local S = math.sqrt(1 + m11 - m00 - m22) * 2
		qX = (m01 + m10) / S
		qY = 0.25 * S
		qZ = (m12 + m21) / S
		qW = (m02 - m20) / S
	else
		local S = math.sqrt(1 + m22 - m00 - m11) * 2
		qX = (m02 + m20) / S
		qY = (m12 + m21) / S
		qZ = 0.25 * S
		qW = (m10 - m01) / S
	end

	return new(qX, qY, qZ, qW)
end

-- Public Methods

--[=[
    @function
    @group Constructors
    
    Creates a quaternion from an axis and angle. 
    Will always return a valid unit quaternion. Normalizes axis.
]=]
local function fromAxisAngle(axis: Vector3, angle: number): Quaternion
	axis = _safeUnit(axis, Vector3.xAxis)

	local ha = angle / 2
	local sha = math.sin(ha)

	local X = sha * axis.X
	local Y = sha * axis.Y
	local Z = sha * axis.Z
	local W = math.cos(ha)

	return new(X, Y, Z, W)
end

Quaternion.fromAxisAngle = fromAxisAngle

--[=[
    @function
    @group Constructors
    
    Creates a quaternion from an axis and angle. 
    Assumes axis is already normalized.
]=]
local function fromAxisAngleFast(axis: Vector3, angle: number): Quaternion
	local ha = angle / 2
	local sha = math.sin(ha)
	local shaxis = axis * sha
	local X = shaxis.X
	local Y = shaxis.Y
	local Z = shaxis.Z
	local W = math.cos(ha)

	return new(X, Y, Z, W)
end

Quaternion.fromAxisAngleFast = fromAxisAngleFast

--[=[
    @function
    @group Constructors
    
    Creates a quaternion from a CFrame. 
    Will always return a valid unit quaternion.
]=]
local function fromCFrame(cframe: CFrame): Quaternion
	local axis, angle = cframe:Orthonormalize():ToAxisAngle()
	return fromAxisAngle(axis, angle)
end

Quaternion.fromCFrame = fromCFrame

--[=[
    @function
    @group Constructors
    
    Creates a quaternion from a CFrame. 
    Assumes that the CFrame has already been orthonormalized, otherwise its
    possible that this will return a quaternion with NaN values.
]=]
local function fromCFrameFast(cframe: CFrame): Quaternion
	local axis, angle = cframe:ToAxisAngle()
	return fromAxisAngleFast(axis, angle)
end

Quaternion.fromCFrameFast = fromCFrameFast

--[=[
    @function
    @group Constructors
    
    Creates a quaternion from three vectors describing a rotation
    matrix.
    Will always return a valid unit quaternion.
]=]
local function fromMatrix(vX: Vector3, vY: Vector3, vZ: Vector3?): Quaternion
	local vXo, vYo = vX, vY
	local vZo = if vZ then vZ else vX:Cross(vY)
	return _fromOrthonormalizedMatrix(_Orthonormalize(vXo, vYo, vZo))
end

Quaternion.fromMatrix = fromMatrix

--[=[
    @function
    @group Constructors
    
    Creates a quaternion from three vectors describing a rotation
    matrix.
    Assumes the matrix is already orthonormalized, if not orthonormalized, it
    can return NaN or invalid Quaternion.
]=]
local function fromMatrixFast(vX: Vector3, vY: Vector3, vZ: Vector3?): Quaternion
	local vXo, vYo = vX.Unit, vY.Unit
	local vZo = if vZ then vZ else vX:Cross(vY).Unit
	return _fromOrthonormalizedMatrix(vXo, vYo, vZo)
end

Quaternion.fromMatrixFast = fromMatrixFast

--[=[
    @function
    @group Constructors
    
    Returns a quaternion looking at Vector3 `lookAt`, from the
    Vector3 `from`, with an optional upVector Vector3 `up`. Maintains
    the same functionality as Roblox's `CFrame.lookAt`.
    Will always return a valid unit quaternion.
]=]
local function lookAt(from: Vector3, lookAt: Vector3, up: Vector3?): Quaternion
	local lookVector = _safeUnit(lookAt - from, Vector3.zAxis)
	local _up = _safeUnit(up or Vector3.yAxis, Vector3.yAxis)

	local rightVector = lookVector:Cross(_up)
	if rightVector.Magnitude > 1e-6 then
		local rightVector = rightVector.Unit
		local upVector = rightVector:Cross(lookVector).Unit
		return _fromOrthonormalizedMatrix(rightVector, upVector, -lookVector)
	end

	local selectVector = lookVector:Cross(Vector3.xAxis)
	if selectVector.Magnitude > 1e-6 then
		local rightVector = selectVector.Unit
		local upVector = rightVector:Cross(lookVector).Unit
		return _fromOrthonormalizedMatrix(rightVector, upVector, -lookVector)
	else
		local upVector = Vector3.zAxis:Cross(lookVector)
		local upSign = upVector:Dot(Vector3.yAxis)
		upVector *= upSign
		local rightVector = lookVector:Cross(upVector)

		return _fromOrthonormalizedMatrix(rightVector, upVector, -lookVector)
	end
end

Quaternion.lookAt = lookAt

--[=[
    @function
    @group Constructors
    
    Creates a quaternion using angles `rx`, `ry`, and `rz` in
    radians. Rotation is applied in Z, Y, X order.
]=]
local function fromEulerAnglesXYZ(rx: number, ry: number, rz: number): Quaternion
	local xCos = math.cos(rx / 2)
	local xSin = math.sin(rx / 2)
	local yCos = math.cos(ry / 2)
	local ySin = math.sin(ry / 2)
	local zCos = math.cos(rz / 2)
	local zSin = math.sin(rz / 2)

	local xSinyCos = xSin * yCos
	local xCosySin = xCos * ySin
	local xCosyCos = xCos * yCos
	local xSinySin = xSin * ySin

	local qX = xSinyCos * zCos + xCosySin * zSin
	local qY = xCosySin * zCos - xSinyCos * zSin
	local qZ = xCosyCos * zSin + xSinySin * zCos
	local qW = xCosyCos * zCos - xSinySin * zSin

	return new(qX, qY, qZ, qW)
end

Quaternion.fromEulerAnglesXYZ = fromEulerAnglesXYZ

--[=[
    @function
    @group Constructors
    @alias fromEulerAnglesXYZ
]=]
Quaternion.Angles = fromEulerAnglesXYZ

--[=[
    @function
    @group Constructors
    
    Creates a quaternion using angles `rx`, `ry`, and `rz` in
    radians. Rotation is applied in Z, X, Y order.
]=]
local function fromEulerAnglesYXZ(rx: number, ry: number, rz: number): Quaternion
	local xCos = math.cos(rx / 2)
	local xSin = math.sin(rx / 2)
	local yCos = math.cos(ry / 2)
	local ySin = math.sin(ry / 2)
	local zCos = math.cos(rz / 2)
	local zSin = math.sin(rz / 2)

	local xSinyCos = xSin * yCos
	local xCosySin = xCos * ySin
	local xCosyCos = xCos * yCos
	local xSinySin = xSin * ySin

	local qX = xSinyCos * zCos + xCosySin * zSin
	local qY = xCosySin * zCos - xSinyCos * zSin
	local qZ = xCosyCos * zSin - xSinySin * zCos
	local qW = xCosyCos * zCos + xSinySin * zSin

	return new(qX, qY, qZ, qW)
end

Quaternion.fromEulerAnglesYXZ = fromEulerAnglesYXZ

--[=[
    @function
    @group Constructors
    @alias fromEulerAnglesYXZ
]=]
Quaternion.fromOrientation = fromEulerAnglesYXZ

--[=[
    @function
    @group Constructors
    
    Creates a quaternion using angles `rx`, `ry`, and `rz` in
    radians. Rotation is applied in the order given by `rotationOrder`.
]=]
local function fromEulerAngles(rx: number, ry: number, rz: number, rotationOrder: Enum.RotationOrder?): Quaternion
	if not rotationOrder then
		rotationOrder = Enum.RotationOrder.XYZ
	end

	local xCos = math.cos(rx / 2)
	local yCos = math.cos(ry / 2)
	local zCos = math.cos(rz / 2)

	local xSin = math.sin(rx / 2)
	local ySin = math.sin(ry / 2)
	local zSin = math.sin(rz / 2)

	local xSinyCos = xSin * yCos
	local xCosySin = xCos * ySin
	local xCosyCos = xCos * yCos
	local xSinySin = xSin * ySin

	local qX, qY, qZ, qW

	local order = rotationOrder.Name
	if order == "XYZ" then
		qX = xSinyCos * zCos + xCosySin * zSin
		qY = xCosySin * zCos - xSinyCos * zSin
		qZ = xCosyCos * zSin + xSinySin * zCos
		qW = xCosyCos * zCos - xSinySin * zSin
	elseif order == "YXZ" then
		qX = xSinyCos * zCos + xCosySin * zSin
		qY = xCosySin * zCos - xSinyCos * zSin
		qZ = xCosyCos * zSin - xSinySin * zCos
		qW = xCosyCos * zCos + xSinySin * zSin
	elseif order == "ZXY" then
		qX = xSinyCos * zCos - xCosySin * zSin
		qY = xCosySin * zCos + xSinyCos * zSin
		qZ = xCosyCos * zSin + xSinySin * zCos
		qW = xCosyCos * zCos - xSinySin * zSin
	elseif order == "ZYX" then
		qX = xSinyCos * zCos - xCosySin * zSin
		qY = xCosySin * zCos + xSinyCos * zSin
		qZ = xCosyCos * zSin - xSinySin * zCos
		qW = xCosyCos * zCos + xSinySin * zSin
	elseif order == "YZX" then
		qX = xSinyCos * zCos + xCosySin * zSin
		qY = xCosySin * zCos + xSinyCos * zSin
		qZ = xCosyCos * zSin - xSinySin * zCos
		qW = xCosyCos * zCos - xSinySin * zSin
	elseif order == "XZY" then
		qX = xSinyCos * zCos - xCosySin * zSin
		qY = xCosySin * zCos - xSinyCos * zSin
		qZ = xCosyCos * zSin + xSinySin * zCos
		qW = xCosyCos * zCos + xSinySin * zSin
	end

	return new(qX, qY, qZ, qW)
end

Quaternion.fromEulerAngles = fromEulerAngles

--[=[
    @function
    @group Constructors
    
    Creates a quaternion from a vector, where the imaginary
    components of the quaternion are set by the vector components.
]=]
local function fromVector(vector: Vector3): Quaternion
	return new(vector.X, vector.Y, vector.Z, 0)
end

Quaternion.fromVector = fromVector

--[=[
    @function
    @group Constructors
    
    Returns a function which will return a new random quaternion every
    time that it is called.
]=]
local function RandomQuaternion(seed: number): () -> Quaternion
	local seed = seed or 1
	local random = Random.new(seed)

	local tau = 2 * math.pi
	local sqrt = math.sqrt
	local sin = math.sin
	local cos = math.cos
	return function()
		local u = random:NextNumber(0, 1)
		local v = random:NextNumber(0, 1)
		local w = random:NextNumber(0, 1)

		local omu = 1 - u
		local squ = sqrt(u)
		local sqmu = sqrt(omu)

		local tpv = tau * v
		local tpw = tau * w

		local qX = sqmu * sin(tpv)
		local qY = sqmu * cos(tpv)
		local qZ = squ * sin(tpw)
		local qW = squ * cos(tpw)
		return new(qX, qY, qZ, qW)
	end
end

Quaternion.RandomQuaternion = RandomQuaternion

--[=[
    @operator add
    @operand1 Quaternion
    @operand2 Quaternion
    @return Quaternion
    @group Math Operations
    
    Adds the the second quaternion to the first quaternion using 
    component-wise addition.
]=]

--[=[
    @operator sub
    @operand1 Quaternion
    @operand2 Quaternion
    @return Quaternion
    @group Math Operations
    
    Subtracts the the second quaternion from the first quaternion
    using component-wise subtraction.
]=]

--[=[
    @operator mul
    @operand1 Quaternion
    @operand2 Quaternion
    @return Quaternion
    @group Math Operations
    
    Multiplies the first quaternion by the second quaternion using
    the Hamilton product. The order of multiplication is crucial, and in 
    nearly all cases, (where q0 and q1 are quaternions) q0 \* q1 is not 
    equal to q1 \* q0.
]=]

--[=[
    @operator mul
    @operand1 Quaternion
    @operand2 number
    @return Quaternion
    @group Math Operations
    
    Multiplies each component of a quaternion by a scalar value.
]=]
--[=[
    @operator mul
    @operand1 number
    @operand2 Quaternion
    @return Quaternion
    @group Math Operations
    
    Multiplies each component of a quaternion by a scalar value.
]=]

--[=[
    @operator mul
    @operand1 Quaternion
    @operand2 CFrame
    @return CFrame
    @group Math Operations
    
    Converts the Quaternion to a CFrame and multiplies them 
    together. Equivalent to `Quaternion:ToCFrame() * CFrame`.
]=]

--[=[
    @operator mul
    @operand1 Quaternion
    @operand2 Vector3
    @return Vector3
    @group Math Operations
    
    Rotates a Vector3 by a Quaternion.
]=]

--[=[
    @operator mul
    @operand1 Vector3
    @operand2 Quaternion
    @return Quaternion
    @group Math Operations
    
    Equivalent to `Quaternion.fromVector(Vector3)*Quaternion`.
]=]

--[=[
    @operator div
    @operand1 Quaternion
    @operand2 number
    @return Quaternion
    @group Math Operations
    
    Divides each component of the quaternion by the given scalar.
]=]

--[=[
    @operator div
    @operand1 number
    @operand2 Quaternion
    @return Quaternion
    @group Math Operations
    
    Each component divides the given scalar.
]=]

--[=[
    @operator div
    @operand1 Quaternion
    @operand2 Quaternion
    @return Quaternion
    @group Math Operations
    
    Multiplies the the first quaternion by the inverse of the
    second quaternion. Equivalent to `q0 * q1:Inverse()`.
]=]

--[=[
    @operator unm
    @operand1 Quaternion
    @return Quaternion
    @group Math Operations
    
    Negates each component of the Quaternion.
]=]

--[=[
    @operator pow
    @operand1 Quaternion
    @operand2 number
    @return Quaternion
    @group Math Operations
    
    Raises quaternion by the given power. Has the effect of
    scaling a rotation around the identity quaternion. For example,
    if a quaternion `q0` represents a rotation of 60 degrees around the
    X axis, doing `q0 ^ 0.5` will return a quaternion with a rotation of
    of 30 degrees around the X axis. Doing `q0 ^ 2` will return a rotation
    of 120 degrees around the X axis. The power can be any real number.
]=]

--[=[
    @operator eq
    @operand1 Quaternion
    @operand2 Quaternion
    @return Quaternion
    @group Math Operations
    
    Checks if each component of one quaternion is exactly equal
    to the components of another quaternion.
]=]

--[=[
    @operator lt
    @operand1 Quaternion
    @operand2 Quaternion
    @return boolean
    @group Math Operations
    
    Returns true if the first Quaternion has a smaller length than the
    second Quaternion.
]=]

--[=[
    @operator le
    @operand1 Quaternion
    @operand2 Quaternion
    @return boolean
    @group Math Operations
    
    Returns true if the first quaternion has a smaller or equal
    length than the second Quaternion.
]=]

--[=[
    @operator gt
    @operand1 Quaternion
    @operand2 Quaternion
    @return boolean
    @group Math Operations
    
    Returns true if the first quaternion has a greater length than the second Quaternion.
]=]

--[=[
    @operator ge
    @operand1 Quaternion
    @operand2 Quaternion
    @return boolean
    @group Math Operations
    
    Returns true if the first quaternion has a greater or equal length than the second Quaternion.
]=]

--[=[
    @operator len
    @operand1 Quaternion
    @return number
    @group Math Operations
    
    The length of the quaternion.
]=]

local function Add(q0: Quaternion, q1: Quaternion): Quaternion
	return new(q0.X + q1.X, q0.Y + q1.Y, q0.Z + q1.Z, q0.W + q1.W)
end

Quaternion.__add = Add

local function Sub(q0: Quaternion, q1: Quaternion): Quaternion
	return new(q0.X - q1.X, q0.Y - q1.Y, q0.Z - q1.Z, q0.W - q1.W)
end

Quaternion.__sub = Sub

local function Mul(op0: Quaternion | Vector3 | number, op1: Quaternion | CFrame | Vector3 | number): Quaternion | CFrame | Vector3
	local op0type = GetType(op0)
	local op1type = GetType(op1)

	if op0type == "Quaternion" and op1type == "Quaternion" then
		local q0X, q0Y, q0Z, q0W = op0.X, op0.Y, op0.Z, op0.W
		local q1X, q1Y, q1Z, q1W = op1.X, op1.Y, op1.Z, op1.W
		return new(
			q0W * q1X + q0X * q1W + q0Y * q1Z - q0Z * q1Y,
			q0W * q1Y - q0X * q1Z + q0Y * q1W + q0Z * q1X,
			q0W * q1Z + q0X * q1Y - q0Y * q1X + q0Z * q1W,
			q0W * q1W - q0X * q1X - q0Y * q1Y - q0Z * q1Z
		)
	elseif op0type == "number" and op1type == "Quaternion" then
		return new(op0 * op1.X, op0 * op1.Y, op0 * op1.Z, op0 * op1.W)
	elseif op0type == "Quaternion" and op1type == "number" then
		return new(op0.X * op1, op0.Y * op1, op0.Z * op1, op0.W * op1)
	elseif op0type == "Quaternion" and op1type == "CFrame" then
		return op0:ToCFrame() * op1
	elseif op0type == "Quaternion" and op1type == "Vector3" then
		local op0 = op0:Normalize()
		return (op0 * fromVector(op1) * op0:Conjugate()):Vector()
	elseif op0type == "Vector3" and op1type == "Quaternion" then
		return fromVector(op0) * op1
	else
		error("Cannot multiply " .. op0type .. " by " .. op1type .. ".", 2)
	end
end

Quaternion.__mul = Mul

local function Div(op0: Quaternion | number, op1: number | Quaternion): Quaternion
	local op0type = GetType(op0)
	local op1type = GetType(op1)

	if op0type == "Quaternion" and op1type == "number" then
		return new(op0.X / op1, op0.Y / op1, op0.Z / op1, op0.W / op1)
	elseif op0type == "number" and op1type == "Quaternion" then
		return new(op0 / op1.X, op0 / op1.Y, op0 / op1.Z, op0 / op1.W)
	elseif op0type == "Quaternion" and op1type == "Quaternion" then
		return Mul(op0, op1:Inverse())
	else
		error("Cannot divide " .. op0type .. " by " .. op1type .. ".", 2)
	end
end

Quaternion.__div = Div

local function unm(q0: Quaternion): Quaternion
	return new(-q0.X, -q0.Y, -q0.Z, -q0.W)
end

Quaternion.__unm = unm
Quaternion.Negate = unm

local function Pow(q0: Quaternion, number: number)
	local aW, aX, aY, aZ = q0.W, q0.X, q0.Y, q0.Z

	local im = aX * aX + aY * aY + aZ * aZ
	local aMag = math.sqrt(aW * aW + im)
	local aIm = math.sqrt(im)
	local cMag = aMag ^ number

	if aIm <= EPSILON * aMag then
		return Quaternion.new(0, 0, 0, cMag)
	end

	local rx = aX / aIm
	local ry = aY / aIm
	local rz = aZ / aIm

	local cAng = number * math.atan2(aIm, aW)
	local cCos = math.cos(cAng)
	local cSin = math.sin(cAng)
	local cMagcSin = cMag * cSin

	local cW = cMag * cCos
	local cX = cMagcSin * rx
	local cY = cMagcSin * ry
	local cZ = cMagcSin * rz

	return Quaternion.new(cX, cY, cZ, cW)
end

Quaternion.__pow = Pow

local function eq(q0: Quaternion, q1: Quaternion): boolean
	local op0type = GetType(q0)
	local op1type = GetType(q1)

	if op0type == "Quaternion" and op1type == op0type then
		return q0.X == q1.X and q0.Y == q1.Y and q0.Z == q1.Z and q0.W == q1.W
	else
		return false
	end
end

Quaternion.__eq = eq

local function lt(q0: Quaternion, q1: Quaternion)
	local q0l = q0:Length()
	local q1l = q1:Length()

	return q0l < q1l
end

Quaternion.__lt = lt

local function le(q0: Quaternion, q1: Quaternion)
	local q0l = q0:Length()
	local q1l = q1:Length()

	return q0l <= q1l
end

Quaternion.__le = le

--[=[
    @method
    @group Methods
    
    The exponential of a quaternion.
]=]
local function Exp(q0: Quaternion): Quaternion
	local qX, qY, qZ, qW = q0.X, q0.Y, q0.Z, q0.W

	local m = math.exp(qW)
	local vv = qX * qX + qY * qY + qZ * qZ
	if vv > 0 then
		local v = vv ^ 0.5
		local s = m * math.sin(v) / v
		return new(qX * s, qY * s, qZ * s, m * math.cos(v))
	else
		return new(0, 0, 0, m)
	end
end

Quaternion.Exp = Exp

--[=[
    @method
    @group Methods
    
    The exponential map on the Riemannian manifold described by
    the quaternion space.
]=]
local function ExpMap(q0: Quaternion, q1: Quaternion): Quaternion
	return Mul(q0, Exp(q1))
end

Quaternion.ExpMap = ExpMap

--[=[
    @method
    @group Methods
    
    The symmetrized exponential map on the quaternion Riemannian
    manifold.
]=]
local function ExpMapSym(q0: Quaternion, q1: Quaternion): Quaternion
	local sqrtQ = Pow(q0, 0.5)
	return Mul(Mul(sqrtQ, Exp(q1)), sqrtQ)
end

Quaternion.ExpMapSym = ExpMapSym

--[=[
    @method
    @group Methods
    
    The logarithm of a quaternion.
]=]
local function Log(q0: Quaternion): Quaternion
	local qX, qY, qZ, qW = q0.X, q0.Y, q0.Z, q0.W

	local vv = qX * qX + qY * qY + qZ * qZ
	local mm = qW * qW + vv
	if mm > 0 then
		if vv > 0 then
			local m = mm ^ 0.5
			local s = math.acos(qW / m) / (vv ^ 0.5)
			return new(qX * s, qY * s, qZ * s, math.log(m))
		else
			return new(0, 0, 0, math.log(mm) / 2)
		end
	else
		return new(0, 0, 0, -math.huge)
	end
end

Quaternion.Log = Log

--[=[
    @method
    @group Methods
    
    The logarithm map on the quaternion Riemannian manifold.
]=]
local function LogMap(q0: Quaternion, q1: Quaternion): Quaternion
	return Log(Mul(q0:Inverse(), q1))
end

Quaternion.LogMap = LogMap

--[=[
    @method
    @group Methods
    
    The symmetrized logarithm map on the quaternion Riemannian 
    manifold.
]=]
local function LogMapSym(q0: Quaternion, q1: Quaternion): Quaternion
	local invSqrtq0 = Pow(q0, -0.5)
	return Log(Mul(Mul(invSqrtq0, q1), invSqrtq0))
end

Quaternion.LogMapSym = LogMapSym

--[=[
    @method
    @group Methods
    
    The length of the quaternion.
]=]
local function Length(q0: Quaternion): number
	local qX, qY, qZ, qW = q0.X, q0.Y, q0.Z, q0.W
	return (qX * qX + qY * qY + qZ * qZ + qW * qW) ^ 0.5
end

Quaternion.Length = Length
Quaternion.__len = Length

--[=[
    @method
    @group Methods
    
    The sum of the squares length of the quaternion.
]=]
local function LengthSquared(q0: Quaternion): number
	local qX, qY, qZ, qW = q0.X, q0.Y, q0.Z, q0.W
	return qX * qX + qY * qY + qZ * qZ + qW * qW
end

Quaternion.LengthSquared = LengthSquared

--[=[
    @method
    @group Methods
    
    A numerically stable way to get the length of a quaternion.
]=]
local function Hypot(q0: Quaternion): number
	local qX, qY, qZ, qW = q0.X, q0.Y, q0.Z, q0.W
	local maxComp = math.max(qX, qY, qZ, qW)
	if maxComp > 0 then
		local normalizedQ = q0 / maxComp
		local length = Length(normalizedQ) * maxComp

		return length
	end
	return 0
end

Quaternion.Hypot = Hypot

--[=[
    @method
    @group Methods
    
    The normalized quaternion with a length of one. Passing the
    zero Quaternion into this will return the identity Quaternion.
]=]
local function Normalize(q0: Quaternion): Quaternion
	local length = Length(q0)
	if length > 0 then
		return Div(q0, length)
	else
		return Quaternion.identity
	end
end

Quaternion.Normalize = Normalize

--[=[
    @method
    @group Methods
    
    Returns true if the given quaternion has a length close to
    one, within 1 +- epsilon range.
]=]
local function IsUnit(q0: Quaternion, epsilon: number): boolean
	if not epsilon then
		epsilon = EPSILON
	end
	return math.abs(1 - Length(q0)) < epsilon
end

Quaternion.IsUnit = IsUnit

--[=[
    @method
    @group Deconstructors
    
    Returns a CFrame with the same rotation as the given 
    quaternion. If a position is supplied, the CFrame will have that
    position. The given quaternion will be normalized.
]=]
local function ToCFrame(q0: Quaternion, position: Vector3?): CFrame
	q0 = Normalize(q0)

	local vectorPos = position or Vector3.new()
	return CFrame.new(vectorPos.X, vectorPos.Y, vectorPos.Z, q0.X, q0.Y, q0.Z, q0.W)
end

Quaternion.ToCFrame = ToCFrame

--[=[
    @method
    @group Methods
    
    Returns the dot product between two quaternions.
]=]
local function Dot(q0: Quaternion, q1: Quaternion): number
	return q0.X * q1.X + q0.Y * q1.Y + q0.Z * q1.Z + q0.W * q1.W
end

Quaternion.Dot = Dot

--[=[
    @method
    @group Methods
    
    The conjugate of the Quaternion. The imaginary components are
    negated.
]=]
local function Conjugate(q0: Quaternion): Quaternion
	return new(-q0.X, -q0.Y, -q0.Z, q0.W)
end

Quaternion.Conjugate = Conjugate

--[=[
    @method
    @group Methods
    
    The inverse of the Quaternion. Mulitplying a quaternion by
    its own inverse will result in the identity Quaternion.
]=]
local function Inverse(q0: Quaternion): Quaternion
	local qX, qY, qZ, qW = q0.X, q0.Y, q0.Z, q0.W
	local length = qX * qX + qY * qY + qZ * qZ + qW * qW

	return new(-q0.X / length, -q0.Y / length, -q0.Z / length, q0.W / length)
end

Quaternion.Inverse = Inverse

--[=[
    @method
    @group Methods
    
    Returns the angular velocity between two quaternions.
]=]
local function LogInv(q0: Quaternion, q1: Quaternion): Quaternion
	return Log(Mul(q0, Inverse(q1)))
end

Quaternion.LogInv = LogInv

--[=[
    @method
    @group Methods
    
    Returns the negated version of the given quaternion.
]=]
local function Negate(q0: Quaternion): Quaternion
	return new(-q0.X, -q0.Y, -q0.Z, -q0.W)
end

Quaternion.Negate = Negate
Quaternion.__unm = Negate

--[=[
    @method
    @group Methods
    
    Returns the quaternion which has the minimal rotation to get
    from `q0` to `q1` using the double cover property of quaternions.
    If `q2 = q0:Difference(q1)`, then `q0 \* q2 = q1`, or `q0 \* q2 = -q1` 
    (the same rotation). If you don't want to take advantage of the double 
    cover property, then you can do `q2 = q0 \* q1:Inverse()`, where
    `q0 \* q2 = q1` all of the time.
]=]
local function Difference(q0: Quaternion, q1: Quaternion): Quaternion
	if Dot(q0, q1) < 0 then
		q0 = unm(q0)
	end
	return Mul(Inverse(q0), q1)
end

Quaternion.Difference = Difference

--[=[
    @method
    @group Methods
    
    Returns the intrinsic geodesic distance between two 
    quaternions. Output will be in the range 0-2pi for unit quaternions.
]=]
local function Distance(q0: Quaternion, q1: Quaternion): number
	return Length(LogMap(q0, q1)) * 2
end

Quaternion.Distance = Distance

--[=[
    @method
    @group Methods
    
    Returns the symmetrized geodesic distance between two 
    quaternions. Output will be in the range 0-pi for unit quaternions.
]=]
local function DistanceSym(q0: Quaternion, q1: Quaternion): number
	return Length(Log(Difference(q0, q1))) * 2
end

Quaternion.DistanceSym = DistanceSym

--[=[
    @method
    @group Methods
    
    Returns the chord distance of the shortest path/arc between 
    two quaternions.
]=]
local function DistanceChord(q0: Quaternion, q1: Quaternion): number
	return math.sin(DistanceSym(q0, q1) / 2) * 2
end

Quaternion.DistanceChord = DistanceChord

--[=[
    @method
    @group Methods
    
    Returns the absolute distance between two 
    quaternions, accounting for sign ambiguity.
]=]
local function DistanceAbs(q0: Quaternion, q1: Quaternion): number
	local q0minusq1 = Sub(q0, q1)
	local q0plusq1 = Add(q0, q1)
	local dMinus = Length(q0minusq1)
	local dPlus = Length(q0plusq1)

	if dMinus < dPlus then
		return dMinus
	end
	return dPlus
end

Quaternion.DistanceAbs = DistanceAbs

--[=[
    @method
    @group Methods
    
    Returns a quaternion along the great circle arc between two
    existing quaternion endpoints lying on the unit radius hypersphere.
    Alpha can be any real number.
]=]
local function Slerp(q0: Quaternion, q1: Quaternion, alpha: number): Quaternion
	q0 = Normalize(q0)
	q1 = Normalize(q1)

	local dot = Dot(q0, q1)

	if dot < 0 then
		q0 = unm(q0)
		dot = -dot
	end

	if dot >= 1 then
		return Normalize(Add(q0, Mul(Sub(q1, q0), alpha)))
	end

	local theta0 = math.acos(dot)
	local sinTheta0 = math.sin(theta0)

	local theta = theta0 * alpha
	local sinTheta = math.sin(theta)

	local s0 = math.cos(theta) - dot * sinTheta / sinTheta0
	local s1 = sinTheta / sinTheta0
	return Normalize(Add(Mul(s0, q0), Mul(s1, q1)))
end

Quaternion.Slerp = Slerp

--[=[
    @method
    @group Methods
    
    Returns a quaternion along the great circle arc between the
    identity quaternion and the given quaternion lying on the unit radius
    hypersphere. Alpha can be any real number.
]=]
local function IdentitySlerp(q1: Quaternion, alpha: number): Quaternion
	local q0 = 1
	q1 = Normalize(q1)
	local dot = q1.W

	if dot < 0 then
		q0 = -1
		dot = -dot
	end

	if dot >= 1 then
		return Normalize(new(q1.X * alpha, q1.Y * alpha, q1.Z * alpha, (q1.W - q0) * alpha + q0))
	end

	local theta0 = math.acos(dot)
	local sinTheta0 = math.sin(theta0)

	local theta = theta0 * alpha
	local sinTheta = math.sin(theta)

	local s0 = math.cos(theta) - dot * sinTheta / sinTheta0
	local s1 = sinTheta / sinTheta0
	return Normalize(new(q1.X * s1, q1.Y * s1, q1.Z * s1, q0 * s0 + q1.W * s1))
end

Quaternion.IdentitySlerp = IdentitySlerp

--[=[
    @method
    @group Methods
    
    Returns a function which can be used to calculate a quaternion
    along the great circle arc between the two given quaternions lying on
    the unit radius hypersphere. For example:
    `slerp = q0:SlerpFunction(q1)`, and then `q2 = slerp(alpha)`.
]=]
local function SlerpFunction(q0: Quaternion, q1: Quaternion): (alpha: number) -> Quaternion
	q0 = Normalize(q0)
	q1 = Normalize(q1)

	local dot = Dot(q0, q1)

	if dot < 0 then
		q0 = unm(q0)
		dot = -dot
	end

	if dot >= 1 then
		local subQ = Sub(q1, q0)

		return function(alpha: number)
			return Normalize(Add(q0, Mul(subQ, alpha)))
		end
	end

	local theta0 = math.acos(dot)
	local sinTheta0 = math.sin(theta0)

	return function(alpha: number)
		local theta = theta0 * alpha
		local sinTheta = math.sin(theta)

		local s0 = math.cos(theta) - dot * sinTheta / sinTheta0
		local s1 = sinTheta / sinTheta0
		return Normalize(Add(Mul(s0, q0), Mul(s1, q1)))
	end
end

Quaternion.SlerpFunction = SlerpFunction

--[=[
    @method
    @group Methods
    
    Generates an iterable sequence of n evenly spaces quaternion
    rotations between any two existing quaternion endpoints lying on the
    unit radius hypersphere.
]=]
local function Intermediates(q0: Quaternion, q1: Quaternion, n: number, includeEndpoints: boolean?): { Quaternion }
	includeEndpoints = includeEndpoints or false

	local stepSize = 1 / (n + 1)
	local steps = if includeEndpoints then { q0 } else {}

	local slerpFunc = SlerpFunction(q0, q1)

	for i = 1, n do
		local qi = slerpFunc(stepSize * i)
		table.insert(steps, qi)
	end

	if includeEndpoints then
		table.insert(steps, q1)
	end

	return steps
end

Quaternion.Intermediates = Intermediates

--[=[
    @method
    @group Methods
    
    The instantaneous quaternion derivative representing a 
    quaternion rotating at a 3D rate vector `rate`.
]=]
local function Derivative(q0: Quaternion, rate: Vector3): Quaternion
	return Mul(Mul(0.5, q0), fromVector(rate))
end

Quaternion.Derivative = Derivative

--[=[
    @method
    @group Methods
    
    Advance a time varying Quaternion to its value at a time
    `timestep` in the future. The solution is closed form given the
    assumption that rate is constant over the interval of length 
    `timestep`.
]=]
local function Integrate(q0: Quaternion, rate: Vector3, timestep: number): Quaternion
	q0 = Normalize(q0)

	local rotationVector = (rate * timestep)
	local rotationMag = rotationVector.Magnitude
	if rotationMag > 0 then
		local axis = rotationVector / rotationMag
		local angle = rotationMag
		local q1 = fromAxisAngle(axis, angle)
		return Normalize(Mul(q0, q1))
	else
		return q0
	end
end

Quaternion.Integrate = Integrate

--[=[
    @method
    @group Methods
    
    Returns true if the symmetrized geodesic distance is less
    than `epsilon`.
]=]
local function ApproxEq(q0: Quaternion, q1: Quaternion, epsilon: number?): boolean
	epsilon = epsilon or EPSILON
	return DistanceSym(q0, q1) < epsilon
end

Quaternion.ApproxEq = ApproxEq

--[=[
    @method
    @group Methods
    
    Returns true if any component of the quaternion is NaN.
]=]
local function IsNaN(q0: Quaternion): boolean
	local qX, qY, qZ, qW = q0.X, q0.Y, q0.Z, q0.W
	return qX ~= qX or qY ~= qY or qZ ~= qZ or qW ~= qW
end

Quaternion.IsNaN = IsNaN

local function _toRotationMatrix(q0: Quaternion)
	q0 = Normalize(q0)
	local qX, qY, qZ, qW = q0.X, q0.Y, q0.Z, q0.W

	local sqX = qX * qX
	local sqY = qY * qY
	local sqZ = qZ * qZ
	local sqW = qW * qW

	local m00 = sqX - sqY - sqZ + sqW
	local m11 = -sqX + sqY - sqZ + sqW
	local m22 = -sqX - sqY + sqZ + sqW

	local qXqY = qX * qY
	local qZqW = qZ * qW
	local m10 = 2 * (qXqY + qZqW)
	local m01 = 2 * (qXqY - qZqW)

	local qXqZ = qX * qZ
	local qYqW = qY * qW
	local m20 = 2 * (qXqZ - qYqW)
	local m02 = 2 * (qXqZ + qYqW)

	local qYqZ = qY * qZ
	local qXqW = qX * qW
	local m21 = 2 * (qYqZ + qXqW)
	local m12 = 2 * (qYqZ - qXqW)

	return m00, m01, m02, m10, m11, m12, m20, m21, m22
end

--[=[
    @method
    @group Deconstructors
    
    Converts quaternion to axis angle representation. Quaternion
    is normalized before conversion.
]=]
local function ToAxisAngle(q0: Quaternion): (Vector3, number)
	q0 = Normalize(q0)
	local qX, qY, qZ, qW = q0.X, q0.Y, q0.Z, q0.W

	local angle = 2 * math.acos(qW)
	local s = math.sqrt(1 - qW * qW)

	if s < EPSILON then
		return Vector3.new(qX, qY, qZ), angle
	else
		return Vector3.new(qX / s, qY / s, qZ / s), angle
	end
end

Quaternion.ToAxisAngle = ToAxisAngle

--[=[
    @method
    @group Deconstructors
    
    Converts quaternion to it's matrix representation in 
    `m00, m01, m02, m10, m11, m12, m20, m21, m22` order as a tuple. 
    Quaternion is normalized before conversion.
]=]
local function ToMatrix(q0: Quaternion): (number, number, number, number, number, number, number, number, number)
	return _toRotationMatrix(q0)
end

Quaternion.ToMatrix = ToMatrix

--[=[
    @method
    @group Deconstructors
    
    Converts quaternion to it's matrix representation with three
    vectors, each representation a column of the rotation matrix.
    Quaternion is normalized before conversion.
    Returns RightVector, UpVector, BackVector.
]=]
local function ToMatrixVectors(q0: Quaternion): (Vector3, Vector3, Vector3)
	local m00, m01, m02, m10, m11, m12, m20, m21, m22 = _toRotationMatrix(q0)

	--Right, Up, Back
	return Vector3.new(m00, m10, m20), Vector3.new(m01, m11, m21), Vector3.new(m02, m12, m22)
end

Quaternion.ToMatrixVectors = ToMatrixVectors

--[=[
    @method
    @group Deconstructors
    
    Returns the imaginary components of the quaternion as a Vector.
]=]
local function Vector(q0: Quaternion): Vector3
	return Vector3.new(q0.X, q0.Y, q0.Z)
end

Quaternion.Vector = Vector

--[=[
    @method
    @group Deconstructors
    
    Returns a new quaternion with the same real component as
    the given quaternion, but with the imaginary components set to zero.
]=]
local function Real(q0: Quaternion): Quaternion
	return new(0, 0, 0, q0.W)
end

Quaternion.Real = Real

--[=[
    @method
    @group Deconstructors
    
    Returns a new quaternion with the same imaginary components as
    the given quaternion, but with the real component set to zero.
]=]
local function Imaginary(q0: Quaternion): Quaternion
	return new(q0.X, q0.Y, q0.Z, 0)
end

Quaternion.Imaginary = Imaginary

--[=[
    @method
    @group Deconstructors
    
    Converts the quaternion to euler angles representation in
    X, Y, Z order. Quaternion is normalized before conversion.
]=]
local function ToEulerAnglesXYZ(q0: Quaternion): (number, number, number)
	q0 = Normalize(q0)
	local qX, qY, qZ, qW = q0.X, q0.Y, q0.Z, q0.W
	local rX, rY, rZ

	local test = qY * qW + qX * qZ
	if math.abs(test) > 0.499999 then
		local sign = test > 0 and 1 or -1
		rX = sign * 2 * math.atan2(qZ, qW)
		rY = sign * math.pi / 2
		rZ = 0
		return rX, rY, rZ
	end

	local sqy = qY * qY
	rX = math.atan2(2 * (qX * qW - qY * qZ), 1 - 2 * (qX * qX + sqy))
	rY = math.asin(2 * test)
	rZ = math.atan2(2 * (qZ * qW - qX * qY), 1 - 2 * (qZ * qZ + sqy))

	return rX, rY, rZ
end

local function ToEulerAnglesXZY(q0: Quaternion): (number, number, number)
	q0 = Normalize(q0)
	local qX, qY, qZ, qW = q0.X, q0.Y, q0.Z, q0.W
	local rX, rY, rZ

	local test = qZ * qW - qX * qY
	if math.abs(test) > 0.5 - EPSILON then
		local sign = test >= 0 and 1 or -1
		rX = sign * 2 * -math.atan2(qY, qW)
		rY = 0
		rZ = sign * math.pi / 2
		return rX, rY, rZ
	end

	local sqz = qZ * qZ
	rX = math.atan2(2 * (qX * qW + qY * qZ), 1 - 2 * (qX * qX + sqz))
	rY = math.atan2(2 * (qX * qZ + qY * qW), 1 - 2 * (qY * qY + sqz))
	rZ = math.asin(2 * test)

	return rX, rY, rZ
end

--[=[
    @method
    @group Deconstructors
    
    Converts the quaternion to euler angles representation in
    Y, X, Z order. Quaternion is normalized before conversion.
]=]
local function ToEulerAnglesYXZ(q0: Quaternion): (number, number, number)
	q0 = Normalize(q0)
	local qX, qY, qZ, qW = q0.X, q0.Y, q0.Z, q0.W
	local rX, rY, rZ

	local test = qX * qW - qY * qZ
	if math.abs(test) > 0.5 - EPSILON then
		local sign = test >= 0 and 1 or -1
		rX = sign * math.pi / 2
		rY = sign * 2 * -math.atan2(qZ, qW)
		rZ = 0
		return rX, rY, rZ
	end

	local sqx = qX * qX
	rX = math.asin(2 * test)
	rY = math.atan2(2 * (qX * qZ + qY * qW), 1 - 2 * (qY * qY + sqx))
	rZ = math.atan2(2 * (qX * qY + qZ * qW), 1 - 2 * (qZ * qZ + sqx))

	return rX, rY, rZ
end

local function ToEulerAnglesYZX(q0: Quaternion): (number, number, number)
	q0 = Normalize(q0)
	local qX, qY, qZ, qW = q0.X, q0.Y, q0.Z, q0.W
	local rX, rY, rZ

	local test = qZ * qW + qX * qY
	if math.abs(test) > 0.5 - EPSILON then
		local sign = test >= 0 and 1 or -1
		rX = 0
		rY = sign * 2 * math.atan2(qX, qW)
		rZ = sign * math.pi / 2
		return rX, rY, rZ
	end

	local sqz = qZ * qZ
	rX = math.atan2(2 * (qX * qW - qY * qZ), 1 - 2 * (qX * qX + sqz))
	rY = math.atan2(2 * (qY * qW - qX * qZ), 1 - 2 * (qY * qY + sqz))
	rZ = math.asin(2 * test)

	return rX, rY, rZ
end

local function ToEulerAnglesZXY(q0: Quaternion): (number, number, number)
	q0 = Normalize(q0)
	local qX, qY, qZ, qW = q0.X, q0.Y, q0.Z, q0.W
	local rX, rY, rZ

	local test = qX * qW + qY * qZ
	if math.abs(test) > 0.5 - EPSILON then
		local sign = test >= 0 and 1 or -1
		rX = sign * math.pi / 2
		rY = 0
		rZ = sign * 2 * math.atan2(qY, qW)
		return rX, rY, rZ
	end

	local sqx = qX * qX
	rX = math.asin(2 * test)
	rY = math.atan2(2 * (qY * qW - qX * qZ), 1 - 2 * (qY * qY + sqx))
	rZ = math.atan2(2 * (qZ * qW - qX * qY), 1 - 2 * (qZ * qZ + sqx))

	return rX, rY, rZ
end

local function ToEulerAnglesZYX(q0: Quaternion): (number, number, number)
	q0 = Normalize(q0)
	local qX, qY, qZ, qW = q0.X, q0.Y, q0.Z, q0.W
	local rX, rY, rZ

	local test = qY * qW - qX * qZ
	if math.abs(test) > 0.5 - EPSILON then
		local sign = test >= 0 and 1 or -1
		rX = 0
		rY = sign * math.pi / 2
		rZ = sign * 2 * -math.atan2(qX, qW)
		return rX, rY, rZ
	end

	local sqy = qY * qY
	rX = math.atan2(2 * (qX * qW + qY * qZ), 1 - 2 * (qX * qX + sqy))
	rY = math.asin(2 * test)
	rZ = math.atan2(2 * (qX * qY + qZ * qW), 1 - 2 * (qZ * qZ + sqy))

	return rX, rY, rZ
end

local TO_EULER_ANGLES_MAP = {
	["XYZ"] = ToEulerAnglesXYZ,
	["XZY"] = ToEulerAnglesXZY,
	["YZX"] = ToEulerAnglesYZX,
	["YXZ"] = ToEulerAnglesYXZ,
	["ZXY"] = ToEulerAnglesZXY,
	["ZYX"] = ToEulerAnglesZYX,
}

--[=[
    @method
    @group Deconstructors
    
    Converts the quaternion to euler angles representation.
    Quaternion is normalized before conversion. The result is dependent
    on the given `rotationOrder`. Defaults to "XYZ".
]=]
local function ToEulerAngles(q0: Quaternion, rotationOrder: Enum.RotationOrder?): (number, number, number)
	if not rotationOrder then
		rotationOrder = Enum.RotationOrder.XYZ
	end

	return TO_EULER_ANGLES_MAP[rotationOrder.Name](q0)
end

Quaternion.ToEulerAngles = ToEulerAngles
Quaternion.ToEulerAnglesXYZ = ToEulerAnglesXYZ
Quaternion.ToEulerAnglesYXZ = ToEulerAnglesYXZ

--[=[
    @method
    @group Deconstructors
    @alias ToEulerAnglesYXZ
]=]
Quaternion.ToOrientation = ToEulerAnglesYXZ

--[=[
    @method
    @group Deconstructors
    
    Returns the components of the quaternion in X, Y, Z, W order.
]=]
local function GetComponents(q0: Quaternion): (number, number, number, number)
	return q0.X, q0.Y, q0.Z, q0.W
end

Quaternion.GetComponents = GetComponents

--[=[
    @method
    @group Deconstructors
    @alias GetComponents
]=]
Quaternion.components = GetComponents

local function round(number: number, decimalPlaces: number?): string
	if decimalPlaces then
		decimalPlaces = math.max(0, decimalPlaces)
		local formatString = string.format("%%.%df", decimalPlaces)
		local roundedNumberString = string.format(formatString, number)
		return roundedNumberString
	end
	return tostring(number)
end

--[=[
    @method
    @group Deconstructors
    
    Converts quaternion to string representation. If
    `decimalPlaces` is given, each component in the string will be rounded
    to the given places.
]=]
local function ToString(q0: Quaternion, decimalPlaces: number?): string
	return round(q0.X, decimalPlaces)
		.. ", "
		.. round(q0.Y, decimalPlaces)
		.. ", "
		.. round(q0.Z, decimalPlaces)
		.. ", "
		.. round(q0.W, decimalPlaces)
end

Quaternion.__tostring = ToString
Quaternion.ToString = ToString

function Quaternion.__index(q0, key)
	local functionIndex = Quaternion[key]
	if functionIndex then
		return functionIndex
	end
	local lower = string.lower(key)
	local cached = rawget(q0, "_cached")
	if lower == "unit" then
		if not cached.unit then
			local norm = Normalize(q0)
			cached.unit = norm
			return norm
		end
		return cached.unit
	elseif lower == "magnitude" then
		if not cached.magnitude then
			local mag = Length(q0)
			cached.magnitude = mag
			return mag
		end
		return cached.magnitude
	end
	return nil
end

function Quaternion.__newindex(_, key)
	error(tostring(key) .. " cannot be assigned to")
end

table.freeze(Quaternion)

return Quaternion
