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
	var prepared := validate_travel_pose(_revision, position, heading)
	if not prepared.get("ok", false): return false
	_publish_travel_pose(prepared)
	return true

func validate_travel_pose(expected_revision: int, position: Vector2, heading: float, mass: Variant = null) -> Dictionary:
	if expected_revision != _revision: return {"ok":false, "reason":"stale_revision"}
	if _coordinate_frame != "strategic" or _motion_mode == "tactical" or not is_finite(position.x) or not is_finite(position.y) or not is_finite(heading):
		return {"ok":false, "reason":"invalid_travel_pose"}
	if mass != null and (typeof(mass) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(mass)) or float(mass) <= 0.0): return {"ok":false, "reason":"invalid_mass"}
	var result := {"ok":true, "position":position, "heading":heading}
	if mass != null: result["mass"] = float(mass)
	return result

func _publish_travel_pose(prepared: Dictionary) -> void:
	_position = prepared.position
	_heading = prepared.heading
	if prepared.has("mass"): _mass = float(prepared.mass)
	_revision += 1

func validate_motion(proposal: Dictionary, tick: int) -> Dictionary:
	if _craft_id.is_empty() or tick <= _tick:
		return {"ok": false, "reason": "stale_tick"}
	if proposal.get("expected_revision", -1) != _revision:
		return {"ok": false, "reason": "stale_revision"}
	if _motion_mode == "inactive" or proposal.get("motion_mode", _motion_mode) == "inactive":
		return {"ok":false, "reason":"activity_transition_required"}
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
	_apply_pose(next, tick)
	return {"ok": true, "revision": _revision}

func validate_area_transition(proposal: Dictionary, tick: int) -> Dictionary:
	# Root coordinates this preflight with travel, membership and occupancy.
	if _craft_id.is_empty() or tick <= _tick: return {"ok":false, "reason":"stale_tick"}
	if proposal.get("expected_revision", -1) != _revision: return {"ok":false, "reason":"stale_revision"}
	if _motion_mode == "inactive" or proposal.get("motion_mode", _motion_mode) == "inactive":
		return {"ok":false, "reason":"activity_transition_required"}
	if not proposal.has_all(["coordinate_frame", "space_area_id", "position_plane"]):
		return {"ok":false, "reason":"invalid_pose"}
	var next := get_snapshot()
	next.merge(proposal, true)
	if not _valid_pose(next): return {"ok":false, "reason":"invalid_pose"}
	if next.coordinate_frame == _coordinate_frame and next.space_area_id == _space_area_id:
		return {"ok":false, "reason":"same_area"}
	return {"ok":true, "next_pose":next, "tick":tick}

func validate_surface_air_transition(proposal: Dictionary, tick: int) -> Dictionary:
	# Root-private preflight for a local sortie. The caller must validate the
	# actual landing, boarding, index and saved return pose before publication.
	if _craft_id.is_empty() or tick <= _tick: return {"ok":false, "reason":"stale_tick"}
	if proposal.get("expected_revision", -1) != _revision: return {"ok":false, "reason":"stale_revision"}
	var next := get_snapshot()
	next.merge(proposal, true)
	if not _valid_pose(next): return {"ok":false, "reason":"invalid_pose"}
	var leaving_ground := (_motion_mode == "grounded" and _coordinate_frame == "strategic") or (_motion_mode == "inactive" and _coordinate_frame == "local")
	var entering_air: bool = next.motion_mode == "tactical" and next.coordinate_frame == "local" and String(next.space_area_id).begins_with("atmosphere:") and next.assist_mode == "coupled"
	var leaving_air := _motion_mode == "tactical" and _coordinate_frame == "local" and _space_area_id.begins_with("atmosphere:")
	var entering_ground: bool = (next.motion_mode == "grounded" and next.coordinate_frame == "strategic" and String(next.space_area_id).is_empty()) or (next.motion_mode == "inactive" and next.coordinate_frame == "local" and not String(next.space_area_id).begins_with("atmosphere:"))
	if not ((leaving_ground and entering_air) or (leaving_air and entering_ground)): return {"ok":false, "reason":"invalid_surface_air_transition"}
	return {"ok":true, "next_pose":next, "tick":tick}

func commit_area_transition(proposal: Dictionary, tick: int) -> Dictionary:
	var validation := validate_area_transition(proposal, tick)
	if not validation.ok: return validation
	return _publish_area_transition(validation)

func _publish_area_transition(validation: Dictionary) -> Dictionary:
	# Root-private tail after all participant validations; no second preflight.
	_apply_pose(validation.next_pose, validation.tick)
	return {"ok":true, "revision":_revision}

func validate_space_activity_transition(proposal: Dictionary, tick: int) -> Dictionary:
	# Root is responsible for gate, occupancy, and other owner preconditions.
	if _craft_id.is_empty() or tick <= _tick: return {"ok":false, "reason":"stale_tick"}
	if proposal.get("expected_revision", -1) != _revision: return {"ok":false, "reason":"stale_revision"}
	if _coordinate_frame != "local": return {"ok":false, "reason":"not_local"}
	var mode: Variant = proposal.get("motion_mode")
	if not ((_motion_mode == "tactical" and mode == "inactive") or (_motion_mode == "inactive" and mode == "tactical")):
		return {"ok":false, "reason":"invalid_activity_transition"}
	var allowed: Array = ["expected_revision", "motion_mode"] if mode == "inactive" else ["expected_revision", "motion_mode", "position_plane", "velocity_plane", "heading_rad", "angular_velocity", "assist_mode"]
	for key in proposal:
		if not allowed.has(key): return {"ok":false, "reason":"invalid_activity_transition"}
	if mode == "tactical" and typeof(proposal.get("position_plane")) != TYPE_VECTOR2:
		return {"ok":false, "reason":"invalid_pose"}
	var next := get_snapshot()
	next.merge(proposal, true)
	if not _valid_pose(next): return {"ok":false, "reason":"invalid_pose"}
	return {"ok":true, "next_pose":next, "tick":tick}

func commit_space_activity_transition(proposal: Dictionary, tick: int) -> Dictionary:
	var validation := validate_space_activity_transition(proposal, tick)
	if not validation.ok: return validation
	return _publish_space_activity_transition(validation)

func _publish_space_activity_transition(validation: Dictionary) -> Dictionary:
	# Root-private synchronous tail after fresh validation of every participant.
	_apply_pose(validation.next_pose, validation.tick)
	return {"ok":true, "revision":_revision}

func _apply_pose(next: Dictionary, tick: int) -> void:
	_position = next.position_plane
	_velocity = next.velocity_plane
	_heading = float(next.heading_rad)
	_angular_velocity = float(next.angular_velocity)
	_assist_mode = String(next.assist_mode)
	_motion_mode = String(next.motion_mode)
	_mass = float(next.mass)
	_coordinate_frame = next.coordinate_frame
	_space_area_id = next.space_area_id
	_tick = tick
	_revision += 1

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
	if pose.get("motion_mode", "grounded") == "inactive" and frame != "local": return false
	return pose.get("assist_mode", "coupled") in ["coupled", "decoupled"] and pose.get("motion_mode", "grounded") in ["grounded", "travel", "tactical", "inactive"]

# Detached preparations	are scoped to this owner and cannot be replayed after
# another commit. They do not publish flight state until the caller commits.
class PreparedFlightCheckpoint extends RefCounted:
	pass
var _flight_checkpoint_preparations: Dictionary = {}

func export_checkpoint_state() -> Dictionary:
	var data := get_snapshot()
	data["schema"] = "space_flight_checkpoint.v1"
	data["position_plane"] = [_position.x, _position.y]
	data["velocity_plane"] = [_velocity.x, _velocity.y]
	return data

func prepare_checkpoint_restore(data: Dictionary) -> Dictionary:
	var keys := ["schema", "craft_id", "position_plane", "velocity_plane", "heading_rad", "angular_velocity", "assist_mode", "motion_mode", "mass", "revision", "tick", "space_area_id", "coordinate_frame"]
	if data.size() != keys.size() or not data.has_all(keys) or data.schema != "space_flight_checkpoint.v1" or data.craft_id != _craft_id or _craft_id.is_empty():
		return {"ok":false, "reason":"invalid_flight_checkpoint"}
	var pose := data.duplicate(true)
	for key in ["position_plane", "velocity_plane"]:
		var v: Variant = data[key]
		if not v is Array or v.size() != 2 or typeof(v[0]) not in [TYPE_INT, TYPE_FLOAT] or typeof(v[1]) not in [TYPE_INT, TYPE_FLOAT]:
			return {"ok":false, "reason":"invalid_flight_checkpoint"}
		pose[key] = Vector2(float(v[0]), float(v[1]))
	for key in ["revision", "tick"]:
		var value: Variant = data[key]
		if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)) or float(value) != floor(float(value)) or float(value) < (-1 if key == "tick" else 0) or float(value) > 1000000000000.0:
			return {"ok":false, "reason":"invalid_flight_checkpoint"}
	for id in _flight_checkpoint_preparations.keys():
		if _flight_checkpoint_preparations[id].handle.get_ref() == null: _flight_checkpoint_preparations.erase(id)
	if not _valid_pose(pose) or _flight_checkpoint_preparations.size() >= 32:
		return {"ok":false, "reason":"invalid_flight_checkpoint"}
	var handle := PreparedFlightCheckpoint.new()
	_flight_checkpoint_preparations[handle.get_instance_id()] = {"handle":weakref(handle), "source_snapshot":get_snapshot(), "pose":pose}
	return {"ok":true, "prepared":handle}

func commit_checkpoint_restore(handle: RefCounted) -> Dictionary:
	if handle == null or not _flight_checkpoint_preparations.has(handle.get_instance_id()):
		return {"ok":false, "reason":"flight_checkpoint_unknown"}
	var prepared: Dictionary = _flight_checkpoint_preparations[handle.get_instance_id()]
	_flight_checkpoint_preparations.erase(handle.get_instance_id())
	if prepared.handle.get_ref() != handle or prepared.source_snapshot != get_snapshot():
		return {"ok":false, "reason":"flight_checkpoint_changed"}
	var pose: Dictionary = prepared.pose
	_position = pose.position_plane
	_velocity = pose.velocity_plane
	_heading = float(pose.heading_rad)
	_angular_velocity = float(pose.angular_velocity)
	_assist_mode = pose.assist_mode
	_motion_mode = pose.motion_mode
	_mass = float(pose.mass)
	_space_area_id = pose.space_area_id
	_coordinate_frame = pose.coordinate_frame
	_revision = int(pose.revision)
	_tick = int(pose.tick)
	return {"ok":true}
