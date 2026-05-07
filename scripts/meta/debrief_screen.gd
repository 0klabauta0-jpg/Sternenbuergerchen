class_name DebriefTestScreen
extends Control

const PERSONNEL_EVENT_MODEL_SCRIPT: GDScript = preload("res://scripts/meta/personnel_event_model.gd")
const AIR_ASSET_RECOVERY_STATE_SCRIPT: GDScript = preload("res://scripts/meta/air_asset_recovery_state.gd")

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
	_apply_contextual_help_ids()


func set_mission_result(mission_result: Dictionary) -> void:
	_mission_result = mission_result.duplicate(true)
	if is_inside_tree():
		_render_result()


func get_mission_result() -> Dictionary:
	return _mission_result.duplicate(true)


func _render_result() -> void:
	var result_label: Label = get_node("Panel/Margin/VBox/ResultLabel")
	var team_state_label: Label = get_node("Panel/Margin/VBox/TeamStateLabel")
	var air_asset_label: Label = _ensure_air_asset_events_label()
	var character_events_label: Label = _ensure_character_events_label()
	var personnel_events_label: Label = _ensure_personnel_events_label()
	_apply_help_id(character_events_label, "debrief.character_updates")
	_apply_help_id(air_asset_label, "fob.flightdeck")

	if _mission_result.is_empty():
		result_label.text = "Mission result: pending"
		team_state_label.text = "Returned team state: unavailable"
		air_asset_label.text = "Air asset: pending"
		character_events_label.text = "Character updates: pending"
		personnel_events_label.text = "Personnel updates: pending"
		return

	var winner_team_id: String = String(_mission_result.get("winning_team_id", ""))
	var result: String = String(_mission_result.get("result", "ended"))
	var mission_outcome: String = String(_mission_result.get("mission_outcome", "ended"))
	var win_condition_type: String = String(_mission_result.get("win_condition_type", ""))
	var duration_seconds: float = float(_mission_result.get("duration_seconds", 0.0))
	var objective_captured: bool = bool(_mission_result.get("objective_captured", false))

	var winner_text: String = winner_team_id
	if winner_text.is_empty():
		winner_text = "unknown"

	result_label.text = "Mission %s\nResult: %s\nWinner: %s\nCondition: %s\nDuration: %.1fs\nObjective captured: %s" % [
		mission_outcome,
		result.to_upper(),
		winner_text,
		win_condition_type,
		duration_seconds,
		"yes" if objective_captured else "no",
	]

	var team_state_lines: PackedStringArray = []
	for member_state in _mission_result.get("team_states", []):
		var display_name: String = String(member_state.get("display_name", member_state.get("unit_id", "")))
		var vital_state: String = String(member_state.get("vital_state", "unknown"))
		var health_points: int = int(member_state.get("health_points", -1))
		team_state_lines.append("%s: %s (%d HP)" % [display_name, vital_state, health_points])

	if team_state_lines.is_empty():
		team_state_label.text = "Returned team state: unavailable"
	else:
		team_state_label.text = "Returned team state:\n%s" % "\n".join(team_state_lines)

	var recovery_state: Dictionary = Dictionary(_mission_result.get("air_asset_recovery", {})).duplicate(true)
	if recovery_state.is_empty():
		air_asset_label.text = "Air asset: no loss reported"
	else:
		air_asset_label.text = String(AIR_ASSET_RECOVERY_STATE_SCRIPT.call("build_debrief_summary", recovery_state))

	var character_event_lines: PackedStringArray = []
	for event_variant in Array(_mission_result.get("character_events", [])):
		if typeof(event_variant) != TYPE_DICTIONARY:
			continue
		var event: Dictionary = Dictionary(event_variant)
		var summary_text: String = String(event.get("summary_text", "")).strip_edges()
		if summary_text.is_empty():
			continue
		character_event_lines.append(summary_text)
		if character_event_lines.size() >= 5:
			break
	if character_event_lines.is_empty():
		character_events_label.text = "Character updates: none"
	else:
		character_events_label.text = "Character updates:\n%s" % "\n".join(character_event_lines)

	var personnel_event_lines: PackedStringArray = PackedStringArray()
	for event_variant in Array(_mission_result.get("personnel_events", [])):
		if typeof(event_variant) != TYPE_DICTIONARY:
			continue
		var message: String = String(PERSONNEL_EVENT_MODEL_SCRIPT.call("format_event_message", Dictionary(event_variant))).strip_edges()
		if message.is_empty():
			continue
		personnel_event_lines.append(message)
		if personnel_event_lines.size() >= 5:
			break
	if personnel_event_lines.is_empty():
		personnel_events_label.text = "Personnel updates: none"
	else:
		personnel_events_label.text = "Personnel updates:\n%s" % "\n".join(personnel_event_lines)


func _ensure_character_events_label() -> Label:
	var vbox := get_node("Panel/Margin/VBox") as VBoxContainer
	var existing := vbox.get_node_or_null("CharacterEventsLabel") as Label
	if existing != null:
		return existing
	var label := Label.new()
	label.name = "CharacterEventsLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var button_row := vbox.get_node_or_null("ButtonRow")
	if button_row != null:
		vbox.add_child(label)
		vbox.move_child(label, button_row.get_index())
	else:
		vbox.add_child(label)
	return label


func _ensure_air_asset_events_label() -> Label:
	var vbox := get_node("Panel/Margin/VBox") as VBoxContainer
	var existing := vbox.get_node_or_null("AirAssetEventsLabel") as Label
	if existing != null:
		return existing
	var label := Label.new()
	label.name = "AirAssetEventsLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var button_row := vbox.get_node_or_null("ButtonRow")
	if button_row != null:
		vbox.add_child(label)
		vbox.move_child(label, button_row.get_index())
	else:
		vbox.add_child(label)
	return label


func _apply_contextual_help_ids() -> void:
	_apply_help_id(get_node_or_null("Panel/Margin/VBox/CharacterEventsLabel") as Control, "debrief.character_updates")
	_apply_help_id(get_node_or_null("Panel/Margin/VBox/AirAssetEventsLabel") as Control, "fob.flightdeck")


func _apply_help_id(control: Control, help_id: String) -> void:
	if control == null:
		return
	var normalized_id: String = help_id.strip_edges()
	if normalized_id.is_empty():
		return
	control.set_meta("help_id", normalized_id)
	control.tooltip_text = ""


func _ensure_personnel_events_label() -> Label:
	var vbox := get_node("Panel/Margin/VBox") as VBoxContainer
	var existing := vbox.get_node_or_null("PersonnelEventsLabel") as Label
	if existing != null:
		return existing
	var label := Label.new()
	label.name = "PersonnelEventsLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var button_row := vbox.get_node_or_null("ButtonRow")
	if button_row != null:
		vbox.add_child(label)
		vbox.move_child(label, button_row.get_index())
	else:
		vbox.add_child(label)
	return label


func _on_return_to_fob_pressed() -> void:
	return_to_fob_requested.emit()


func _on_return_to_homebase_pressed() -> void:
	return_to_homebase_requested.emit()
