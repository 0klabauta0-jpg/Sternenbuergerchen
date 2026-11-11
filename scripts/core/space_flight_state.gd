extends RefCounted
## Per-craft movement data. Mutations are intended only for the runtime owner.

var _craft_id: String = ""
var _position := Vector2.ZERO
var _velocity := Vector2.ZERO
var _heading := 0.0
var _angular_velocity := 0.0
var _assist_mode := "coupled"
var _motion_mode := "grounded"
var _mass := 1.0
var _revision := 0
var _tick := -1
var _space_area_id := ""
var _coordinate_frame := "strategic"

func configure(craft_id: String, pose: Dictionary) -> Dictionary:
	if craft_id.strip_edges().is_empty() or not _valid_pose(pose):
		return {"ok": false, "reason": "invalid_pose"}
	_craft_id = craft_id
	_position = pose.position_plane
	_velocity = pose.get("velocity_plane", Vector2.ZERO)
	_heading = float(pose.get("heading_rad", 0.0))
	_angular_velocity = float(pose.get("angular_velocity", 0.0))
	_assist_mode = String(pose.get("assist_mode", "coupled"))
	_motion_mode = String(pose.get("motion_mode", "grounded"))
	_mass = float(pose.get("mass", 1.0))
	_space_area_id = String(pose.get("space_area_id", ""))
	_coordinate_frame = String(pose.get("coordinate_frame", "strategic"))
	_revision = 0
	_tick = -1
	return {"ok": true}

func get_snapshot() -> Dictionary:
	return {"craft_id": _craft_id, "position_plane": _position, "velocity_plane": _velocity,
		"heading_rad": _heading, "angular_velocity": _angular_velocity, "assist_mode": _assist_mode,
		"motion_mode": _motion_mode, "mass": _mass, "revision": _revision, "tick": _tick,
		"space_area_id": _space_area_id, "coordinate_frame": _coordinate_frame}

func bind_craft(craft_id: String, allow_rebind: bool = false) -> bool:
	if craft_id.strip_edges().is_empty() or (not allow_rebind and _craft_id != "__unassigned__" and _craft_id != craft_id):
		return false
	_craft_id = craft_id
	return true

func commit_travel_pose(position: Vector2, heading: float) -> bool:
	if _motion_mode == "tactical" or not is_finite(position.x) or not is_finite(position.y) or not is_finite(heading):
		return false
	_position = position
	_heading = heading
	_revision += 1
	return true

func validate_motion(proposal: Dictionary, tick: int) -> Dictionary:
	if _craft_id.is_empty() or tick <= _tick:
		return {"ok": false, "reason": "stale_tick"}
	if proposal.get("expected_revision", -1) != _revision:
		return {"ok": false, "reason": "stale_revision"}
	if proposal.get("space_area_id", _space_area_id) != _space_area_id or proposal.get("coordinate_frame", _coordinate_frame) != _coordinate_frame:
		return {"ok": false, "reason": "area_transition_required"}
	var next := get_snapshot()
	next.merge(proposal, true)
	if not _valid_pose(next):
		return {"ok": false, "reason": "invalid_pose"}
	return {"ok": true}

func commit_motion(proposal: Dictionary, tick: int) -> Dictionary:
	var validation := validate_motion(proposal, tick)
	if not validation.ok:
		return validation
	var next := get_snapshot()
	next.merge(proposal, true)
	_position = next.position_plane
	_velocity = next.velocity_plane
	_heading = float(next.heading_rad)
	_angular_velocity = float(next.angular_velocity)
	_assist_mode = String(next.assist_mode)
	_motion_mode = String(next.motion_mode)
	_mass = float(next.mass)
	_tick = tick
	_revision += 1
	return {"ok": true, "revision": _revision}

static func _valid_pose(pose: Dictionary) -> bool:
	if typeof(pose.get("position_plane")) != TYPE_VECTOR2 or typeof(pose.get("velocity_plane", Vector2.ZERO)) != TYPE_VECTOR2:
		return false
	for value in [pose.position_plane, pose.get("velocity_plane", Vector2.ZERO)]:
		if not is_finite(value.x) or not is_finite(value.y): return false
	for key in ["heading_rad", "angular_velocity", "mass"]:
		var value: Variant = pose.get(key, 1.0 if key == "mass" else 0.0)
		if typeof(value) not in [TYPE_FLOAT, TYPE_INT] or not is_finite(float(value)): return false
	if float(pose.get("mass", 1.0)) <= 0.0: return false
	var area: Variant = pose.get("space_area_id", "")
	var frame: Variant = pose.get("coordinate_frame", "strategic")
	if typeof(area) != TYPE_STRING or typeof(frame) != TYPE_STRING: return false
	if frame == "strategic" and not String(area).is_empty(): return false
	if frame == "local" and String(area).strip_edges().is_empty(): return false
	if frame not in ["strategic", "local"]: return false
	return pose.get("assist_mode", "coupled") in ["coupled", "decoupled"] and pose.get("motion_mode", "grounded") in ["grounded", "travel", "tactical"]
