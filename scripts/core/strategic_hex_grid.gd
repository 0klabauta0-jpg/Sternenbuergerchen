extends RefCounted
## Shared projection for the v2 star system. Positions crossing the existing
## travel API remain normalized; the authored coordinates and route are axial.
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const SIZE := Vector2i(256, 256)
const EXTENT := Vector2(256.0, 221.70250336881628)
const ORBITS := {"moon_orbit": "moon", "planet_orbit": "planet",
	"glut_1a_orbit": "glut_1a", "glut_1b_orbit": "glut_1b", "polisa_orbit": "glut_2"}
const ORBIT_MARKER_IDS := ["orbit_1", "orbit_2", "orbit_3"]

static func from_offset(offset: Vector2i) -> Vector2i:
	return Vector2i(offset.x - floori(offset.y * 0.5), offset.y)

static func to_offset(cell: Vector2i) -> Vector2i:
	return Vector2i(cell.x + floori(cell.y * 0.5), cell.y)

static func contains(cell: Vector2i) -> bool:
	return Rect2i(Vector2i.ZERO, SIZE).has_point(to_offset(cell))

static func normalized(cell: Vector2i) -> Vector2:
	return HEX.axial_to_plane(Vector2(cell)) / EXTENT

static func cell_at(position: Vector2) -> Vector2i:
	return HEX.round_axial(HEX.plane_to_axial(position * EXTENT))

static func pair(value: Variant) -> Vector2:
	return Vector2(float(value[0]), float(value[1])) if value is Array and value.size() == 2 else Vector2.ZERO

static func cell_from_record(record: Dictionary) -> Vector2i:
	return Vector2i(pair(record.get("hex", [])))


static func orbit_marker(orbit: Dictionary, marker_id: String) -> Dictionary:
	for marker: Dictionary in orbit.get("markers", []):
		if marker.get("id") == marker_id:
			return marker
	return {}


static func can_jump_to_marker(travel: Dictionary, orbit_id: String, marker_id: String) -> bool:
	if String(travel.get("phase", "grounded")) not in ["orbit", "stopped"]:
		return false
	return orbit_id != String(travel.get("orbit_id", "")) or marker_id != String(travel.get("orbit_marker_id", ORBIT_MARKER_IDS[0]))


static func route_control(origin: Vector2, destination: Vector2) -> Vector2:
	var direction := (destination - origin) * EXTENT
	if direction.is_zero_approx():
		return origin
	var side := direction.orthogonal().normalized() * minf(direction.length() * 0.13, 9.0)
	return (origin.lerp(destination, 0.5) + 2.0 * side / EXTENT).clamp(Vector2.ZERO, Vector2.ONE)


static func route_point(origin: Vector2, control: Vector2, destination: Vector2, progress: float) -> Vector2:
	return origin.lerp(control, progress).lerp(control.lerp(destination, progress), progress)


static func route_heading(origin: Vector2, control: Vector2, destination: Vector2, progress: float) -> float:
	return ((control - origin).lerp(destination - control, progress) * EXTENT).angle()


static func route(origin: Vector2, control: Vector2, destination: Vector2) -> Array[Vector2i]:
	var start := cell_at(origin)
	var finish := cell_at(destination)
	var result: Array[Vector2i] = [start]
	var included := {start: true}
	var steps := maxi(HEX.distance(start, finish) * 8, 1)
	for i in range(1, steps + 1):
		var point := route_point(origin, control, destination, float(i) / steps)
		var offset := to_offset(cell_at(point))
		var cell := from_offset(offset.clamp(Vector2i.ZERO, SIZE - Vector2i.ONE))
		if cell == result[-1]:
			continue
		var bridge := HEX.line(result[-1], cell)
		for index in range(1, bridge.size()):
			var step := bridge[index]
			if included.has(step):
				while result[-1] != step:
					included.erase(result.pop_back())
			else:
				included[step] = true
				result.append(step)
	return result
