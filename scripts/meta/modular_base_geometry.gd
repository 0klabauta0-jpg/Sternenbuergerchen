extends RefCounted
## Shared, deterministic geometry for the modular-base owner and its projections.
const SCALE := 4.0
const ORIGIN := Vector2(15.0, 36.0)
const ROOM_SIZE := 6.0
const HALF_ROOM := 3.0
const WALL_INNER := 2.72
const DOOR_HALF := 0.72
## Source habitat bed measured from its authored GLB at the original 0.55 scale.
const BED_HALF := Vector2(0.29, 0.52)

static func center(room: Dictionary) -> Vector2:
	return ORIGIN + Vector2(int(room.get("x", 0)), int(room.get("y", 0))) * ROOM_SIZE

static func rotate_local(value: Vector2, rotation: int) -> Vector2:
	return value.rotated(-float(posmod(rotation, 4)) * PI * 0.5)

static func local_point(room: Dictionary, point: Vector2) -> Vector2:
	return rotate_local(point - center(room), -int(room.get("rotation", 0)))

static func wall_blocks(room: Dictionary, point: Vector2) -> bool:
	var local := local_point(room, point)
	var p := local.abs()
	if p.x > HALF_ROOM + 0.18 or p.y > HALF_ROOM + 0.18: return false
	var doors: Array = room.get("doors", [true,true,true,true])
	if doors.size() != 4: return true
	if p.y >= WALL_INNER and (p.x > DOOR_HALF or not bool(doors[0 if local.y < 0 else 2])): return true
	if p.x >= WALL_INNER and (p.y > DOOR_HALF or not bool(doors[3 if local.x < 0 else 1])): return true
	return false

static func bed_geometry(room: Dictionary, bed: Dictionary) -> Dictionary:
	var slot := int(bed.get("slot", 0))
	var angle := int(room.get("rotation", 0))
	var bed_local := Vector2(-0.85 if slot == 0 else 0.85, -2.0)
	var rest_local := bed_local + Vector2(0.0, 1.25)
	var sleep := center(room) + rotate_local(bed_local, angle)
	var rest := center(room) + rotate_local(rest_local, angle)
	var grid := plane_grid(rest)
	return {"id":String(bed.get("id", "")), "room_id":String(room.get("id", "")), "grid":[grid.x, grid.y], "rest_plane":[rest.x, rest.y], "sleep_plane":[sleep.x, sleep.y], "sleep_y":0.61, "surface_y":0.4763, "rotation_y":-PI * 0.5 + angle * PI * 0.5, "visual_kind":"modular_bed", "room_rotation":angle}

static func bed_blocks(bed: Dictionary, point: Vector2) -> bool:
	var raw: Array = bed.get("sleep_plane", [])
	if raw.size() != 2:return false
	var p := rotate_local(point - Vector2(float(raw[0]), float(raw[1])), -int(bed.get("room_rotation", 0))).abs()
	return p.x < BED_HALF.x + 0.20 and p.y < BED_HALF.y + 0.20

static func plane_grid(plane: Vector2) -> Vector2i:
	var row := roundi(plane.y * SCALE / (sqrt(3.0) * 0.5))
	return Vector2i(roundi(plane.x * SCALE - float(row) * 0.5), row)
