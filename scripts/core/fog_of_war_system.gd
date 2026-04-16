class_name FogOfWarSystem
extends RefCounted

var _visibility_by_team: Dictionary = {}


func set_visible(team_id: String, target_id: String, visible: bool) -> void:
	if team_id.is_empty() or target_id.is_empty():
		return

	var visibility_for_team: Dictionary = _visibility_by_team.get(team_id, {})
	visibility_for_team[target_id] = visible
	_visibility_by_team[team_id] = visibility_for_team


func is_visible(team_id: String, target_id: String) -> bool:
	if team_id.is_empty() or target_id.is_empty():
		return false

	if not _visibility_by_team.has(team_id):
		return false

	return bool(_visibility_by_team[team_id].get(target_id, false))


func update_visibility_from_los(
	team_id: String,
	observer: Node2D,
	target_id: String,
	target_position: Vector2,
	los_system,
	max_range: float = 320.0
) -> bool:
	if team_id.is_empty() or target_id.is_empty():
		return false

	if observer == null or los_system == null or not los_system.has_method("has_line_of_sight_to_position"):
		set_visible(team_id, target_id, false)
		return false

	var visible: bool = bool(los_system.call("has_line_of_sight_to_position", observer, target_position, max_range))
	set_visible(team_id, target_id, visible)
	return visible


func clear() -> void:
	_visibility_by_team.clear()
