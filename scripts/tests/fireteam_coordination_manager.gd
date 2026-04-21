class_name FireteamCoordinationManager
extends RefCounted

const DEFAULT_COORDINATION_RADIUS: float = 96.0

var coordination_radius: float = DEFAULT_COORDINATION_RADIUS
var _sequence: int = 0


func resolve_bounding_assignments(execution_targets: Array, leadership_by_fireteam: Dictionary) -> Array:
	var assignments: Array = []
	for index in range(execution_targets.size()):
		var a: Dictionary = Dictionary(execution_targets[index])
		if not _is_valid_execution_target(a):
			continue
		for other_index in range(index + 1, execution_targets.size()):
			var b: Dictionary = Dictionary(execution_targets[other_index])
			if not _is_valid_execution_target(b):
				continue
			if int(a.get("phase", -1)) != int(b.get("phase", -1)):
				continue
			var a_target: Vector2 = Vector2(a.get("target_position", Vector2.ZERO))
			var b_target: Vector2 = Vector2(b.get("target_position", Vector2.ZERO))
			if a_target.distance_to(b_target) > coordination_radius:
				continue
			var a_fireteam_id: String = String(a.get("fireteam_id", "")).strip_edges().to_lower()
			var b_fireteam_id: String = String(b.get("fireteam_id", "")).strip_edges().to_lower()
			var a_leadership: float = float(leadership_by_fireteam.get(a_fireteam_id, 0.0))
			var b_leadership: float = float(leadership_by_fireteam.get(b_fireteam_id, 0.0))
			var advance_fireteam_id: String = a_fireteam_id
			var cover_fireteam_id: String = b_fireteam_id
			if b_leadership > a_leadership:
				advance_fireteam_id = b_fireteam_id
				cover_fireteam_id = a_fireteam_id
			_sequence += 1
			assignments.append({
				"coordination_id": "coord_%04d" % _sequence,
				"phase": int(a.get("phase", -1)),
				"advance_fireteam_id": advance_fireteam_id,
				"cover_fireteam_id": cover_fireteam_id,
				"advance_target_position": a_target if advance_fireteam_id == a_fireteam_id else b_target,
				"cover_target_position": b_target if cover_fireteam_id == b_fireteam_id else a_target,
				"status": "active",
			})
	return assignments


func rotate_assignment(assignment: Dictionary, ready_fireteam_id: String) -> Dictionary:
	if assignment.is_empty():
		return {}
	var normalized_ready_fireteam_id: String = ready_fireteam_id.strip_edges().to_lower()
	if normalized_ready_fireteam_id != String(assignment.get("advance_fireteam_id", "")).strip_edges().to_lower():
		return assignment.duplicate(true)
	var rotated := assignment.duplicate(true)
	rotated["advance_fireteam_id"] = String(assignment.get("cover_fireteam_id", "")).strip_edges().to_lower()
	rotated["cover_fireteam_id"] = normalized_ready_fireteam_id
	rotated["status"] = "rotated"
	return rotated


func _is_valid_execution_target(target: Dictionary) -> bool:
	if String(target.get("fireteam_id", "")).strip_edges().is_empty():
		return false
	if typeof(target.get("target_position", null)) != TYPE_VECTOR2:
		return false
	return true
