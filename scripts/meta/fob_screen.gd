class_name FOBTestScreen
extends Control

signal back_requested()
signal mission_start_requested(selected_unit_ids, mission_goal)

const DEFAULT_MISSION_GOAL: String = "secure_target"
const ALLOWED_MISSION_GOALS: PackedStringArray = [
	"secure_target",
	"neutralize_enemies",
]

var _selected_unit_ids: PackedStringArray = []
var _last_mission_result: Dictionary = {}
var _mission_goal: String = DEFAULT_MISSION_GOAL


func _ready() -> void:
	var back_button: Button = get_node("Panel/Margin/VBox/ButtonRow/BackButton")
	var start_button: Button = get_node("Panel/Margin/VBox/ButtonRow/StartMissionButton")
	var mission_goal_button: Button = get_node("Panel/Margin/VBox/MissionGoalButton")
	if not back_button.pressed.is_connected(_on_back_button_pressed):
		back_button.pressed.connect(_on_back_button_pressed)
	if not start_button.pressed.is_connected(_on_start_mission_button_pressed):
		start_button.pressed.connect(_on_start_mission_button_pressed)
	if not mission_goal_button.pressed.is_connected(_on_mission_goal_button_pressed):
		mission_goal_button.pressed.connect(_on_mission_goal_button_pressed)

	_render_team()


func set_team(selected_unit_ids: PackedStringArray) -> void:
	_selected_unit_ids = selected_unit_ids.duplicate()
	if is_inside_tree():
		_render_team()


func get_team() -> PackedStringArray:
	return _selected_unit_ids.duplicate()


func set_mission_goal(mission_goal: String) -> void:
	_mission_goal = _normalize_mission_goal(mission_goal)
	if is_inside_tree():
		_render_team()


func get_mission_goal() -> String:
	return _mission_goal


func set_last_mission_result(mission_result: Dictionary) -> void:
	_last_mission_result = mission_result.duplicate(true)
	if is_inside_tree():
		_render_team()


func clear_last_mission_result() -> void:
	_last_mission_result.clear()
	if is_inside_tree():
		_render_team()


func request_mission_start() -> void:
	if _selected_unit_ids.is_empty():
		return

	mission_start_requested.emit(get_team(), get_mission_goal())


func _render_team() -> void:
	var team_status_label: Label = get_node("Panel/Margin/VBox/TeamStatusLabel")
	var mission_result_label: Label = get_node("Panel/Margin/VBox/MissionResultLabel")
	var mission_goal_button: Button = get_node("Panel/Margin/VBox/MissionGoalButton")
	var start_button: Button = get_node("Panel/Margin/VBox/ButtonRow/StartMissionButton")
	start_button.disabled = _selected_unit_ids.is_empty()
	mission_goal_button.text = "Mission Goal: %s" % _format_goal_text(_mission_goal)

	if _selected_unit_ids.is_empty():
		team_status_label.text = "FOB team: none\nStatus: waiting for transfer"
		mission_result_label.text = "Last mission: none"
		return

	team_status_label.text = "FOB team: %s\nStatus: ready for mission start" % ", ".join(_selected_unit_ids)
	mission_result_label.text = _build_mission_result_text()


func _build_mission_result_text() -> String:
	if _last_mission_result.is_empty():
		return "Last mission: none"

	var lines: PackedStringArray = []
	lines.append(
		"Last mission: %s (%s)" % [
			String(_last_mission_result.get("mission_outcome", "ended")),
			String(_last_mission_result.get("winning_team_id", "unknown")),
		]
	)

	for member_state in _last_mission_result.get("team_states", []):
		lines.append(
			"%s: %s" % [
				String(member_state.get("unit_id", "")),
				String(member_state.get("vital_state", "unknown")),
			]
		)

	return "\n".join(lines)


func _cycle_mission_goal() -> void:
	var current_index: int = ALLOWED_MISSION_GOALS.find(_mission_goal)
	if current_index < 0:
		current_index = 0

	var next_index: int = (current_index + 1) % ALLOWED_MISSION_GOALS.size()
	set_mission_goal(ALLOWED_MISSION_GOALS[next_index])


func _normalize_mission_goal(mission_goal: String) -> String:
	if ALLOWED_MISSION_GOALS.has(mission_goal):
		return mission_goal

	return DEFAULT_MISSION_GOAL


func _format_goal_text(mission_goal: String) -> String:
	match mission_goal:
		"secure_target":
			return "SECURE TARGET"
		"neutralize_enemies":
			return "NEUTRALIZE ENEMIES"
		_:
			return mission_goal.replace("_", " ").to_upper()


func _on_back_button_pressed() -> void:
	back_requested.emit()


func _on_mission_goal_button_pressed() -> void:
	_cycle_mission_goal()


func _on_start_mission_button_pressed() -> void:
	request_mission_start()
