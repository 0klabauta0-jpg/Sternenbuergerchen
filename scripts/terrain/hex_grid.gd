class_name HexGrid
extends RefCounted

## Versioned axial pointy-top geometry. Adjacent centers are one plane unit apart.
const TOPOLOGY_ID: String = "hex_axial_v1"
const LEGACY_TOPOLOGY_ID: String = "square8"
const SQRT_THREE: float = 1.7320508075688772
const DEFAULT_RADIUS: float = 0.5773502691896258
const DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
	Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1),
]


static func axial_to_plane(axial: Vector2) -> Vector2:
	return Vector2(axial.x + 0.5 * axial.y, 0.5 * SQRT_THREE * axial.y)


static func plane_to_axial(plane: Vector2) -> Vector2:
	var r: float = 2.0 * plane.y / SQRT_THREE
	return Vector2(plane.x - 0.5 * r, r)


static func round_axial(axial: Vector2) -> Vector2i:
	var cube_x: float = axial.x
	var cube_z: float = axial.y
	var cube_y: float = -cube_x - cube_z
	var rounded_x: int = roundi(cube_x)
	var rounded_y: int = roundi(cube_y)
	var rounded_z: int = roundi(cube_z)
	var error_x: float = absf(float(rounded_x) - cube_x)
	var error_y: float = absf(float(rounded_y) - cube_y)
	var error_z: float = absf(float(rounded_z) - cube_z)
	if error_x > error_y and error_x > error_z:
		rounded_x = -rounded_y - rounded_z
	elif error_y > error_z:
		rounded_y = -rounded_x - rounded_z
	else:
		rounded_z = -rounded_x - rounded_y
	return Vector2i(rounded_x, rounded_z)


static func neighbor_directions() -> Array[Vector2i]:
	return DIRECTIONS.duplicate()


static func neighbors(center: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for direction in DIRECTIONS:
		result.append(center + direction)
	return result


static func are_neighbors(a: Vector2i, b: Vector2i) -> bool:
	return distance(a, b) == 1


static func distance(a: Vector2i, b: Vector2i) -> int:
	var delta: Vector2i = a - b
	return maxi(maxi(absi(delta.x), absi(delta.y)), absi(delta.x + delta.y))


static func line(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	# Canonical endpoint order guarantees reciprocal LOS on exact rounding ties,
	# even where float interpolation would otherwise choose a different side.
	if a.x > b.x or (a.x == b.x and a.y > b.y):
		var reversed: Array[Vector2i] = line(b, a)
		reversed.reverse()
		return reversed
	var result: Array[Vector2i] = []
	var steps: int = distance(a, b)
	if steps == 0:
		result.append(a)
		return result
	# A shared small cube-plane nudge resolves exact edge ties deterministically.
	var nudge := Vector2(0.000001, 0.000001)
	for index in range(steps + 1):
		var axial: Vector2 = Vector2(a).lerp(Vector2(b), float(index) / float(steps)) + nudge
		var rounded: Vector2i = round_axial(axial)
		if result.is_empty() or rounded != result[-1]:
			result.append(rounded)
	return result


static func corners(center: Vector2 = Vector2.ZERO, radius: float = DEFAULT_RADIUS) -> PackedVector2Array:
	var result := PackedVector2Array()
	for index in range(6):
		var angle: float = deg_to_rad(30.0 + 60.0 * float(index))
		result.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return result
