class_name DebriefTestScreen
extends Control

signal return_to_fob_requested()
signal return_to_homebase_requested()

var _mission_result: Dictionary = {}


func _ready() -> void:
	var to_fob_button: Button = get_node("Panel/Margin/VBox/ButtonRow/ReturnToFOBButton")
	var to_homebase_button: Button = get_node("Panel/Margin/VBox/ButtonRow/ReturnToHomebaseButton")
	if not to_fob_button.pressed.is_connected(_on_return_to_fob_pressed):
		to_fob_button.pressed.connect(_on_return_to_fob_pressed)
	if not to_homebase_button.pressed.is_connected(_on_return_to_homebase_pressed):
		to_homebase_button.pressed.connect(_on_return_to_homebase_pressed)

	_render_result()


func set_mission_result(mission_result: Dictionary) -> void:
	_mission_result = mission_result.duplicate(true)
	if is_inside_tree():
		_render_result()


func get_mission_result() -> Dictionary:
	return _mission_result.duplicate(true)


func _render_result() -> void:
	var result_label: Label = get_node("Panel/Margin/VBox/ResultLabel")
	var team_state_label: Label = get_node("Panel/Margin/VBox/TeamStateLabel")

	if _mission_result.is_empty():
		result_label.text = "Mission result: pending"
		team_state_label.text = "Returned team state: unavailable"
		return

	var winner_team_id: String = String(_mission_result.get("winning_team_id", ""))
	var mission_outcome: String = String(_mission_result.get("mission_outcome", "ended"))
	var mission_goal: String = String(_mission_result.get("mission_goal", ""))
	var resolution_reason: String = String(_mission_result.get("resolution_reason", ""))
	var objective_state: String = String(_mission_result.get("objective_state", ""))
	var result_lines: PackedStringArray = []
	result_lines.append("Mission %s" % mission_outcome.to_upper())
	if not mission_goal.is_empty():
		result_lines.append("Goal: %s" % _format_goal_text(mission_goal))
	if not resolution_reason.is_empty():
		result_lines.append("Result: %s" % _format_resolution_text(resolution_reason))
	if objective_state != "inactive" and not objective_state.is_empty():
		result_lines.append("Objective state: %s" % objective_state.to_upper())
	result_lines.append("Winner: %s" % winner_team_id)
	result_label.text = "\n".join(result_lines)

	var team_state_lines: PackedStringArray = []
	for member_state in _mission_result.get("team_states", []):
		var display_name: String = String(member_state.get("display_name", member_state.get("unit_id", "")))
		var vital_state: String = String(member_state.get("vital_state", "unknown"))
		var health_points: int = int(member_state.get("health_points", -1))
		team_state_lines.append("%s: %s (%d HP)" % [display_name, vital_state, health_points])

	if team_state_lines.is_empty():
		team_state_label.text = "Returned team state: unavailable"
		return

	team_state_label.text = "Returned team state:\n%s" % "\n".join(team_state_lines)


func _format_goal_text(mission_goal: String) -> String:
	match mission_goal:
		"secure_target":
			return "SECURE TARGET"
		"neutralize_enemies":
			return "NEUTRALIZE ENEMIES"
		_:
			return mission_goal.replace("_", " ").to_upper()


func _format_resolution_text(resolution_reason: String) -> String:
	match resolution_reason:
		"objective_secured":
			return "OBJECTIVE SECURED"
		"enemy_neutralized":
			return "ENEMY FORCE NEUTRALIZED"
		"friendly_force_neutralized":
			return "FRIENDLY FORCE NEUTRALIZED"
		_:
			return resolution_reason.replace("_", " ").to_upper()


func _on_return_to_fob_pressed() -> void:
	return_to_fob_requested.emit()


func _on_return_to_homebase_pressed() -> void:
	return_to_homebase_requested.emit()
