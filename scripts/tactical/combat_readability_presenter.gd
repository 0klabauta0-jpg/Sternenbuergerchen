class_name CombatReadabilityPresenter
extends RefCounted

const CONTACT_LINE_NAME: String = "CombatContactLine"
const EVENT_LABEL_NAME: String = "CombatEventLabel"
const WINNER_LABEL_NAME: String = "CombatWinnerLabel"

var _contact_line: Line2D = null
var _event_label: Label = null
var _winner_label: Label = null


func ensure_nodes(scene_root: Node, preview_mode: bool) -> void:
	if preview_mode:
		return
	if scene_root == null:
		return

	_contact_line = scene_root.get_node_or_null(CONTACT_LINE_NAME) as Line2D
	if _contact_line == null:
		_contact_line = Line2D.new()
		_contact_line.name = CONTACT_LINE_NAME
		_contact_line.default_color = Color(1.0, 0.92, 0.35, 0.9)
		_contact_line.width = 2.0
		_contact_line.z_index = 20
		scene_root.add_child(_contact_line)

	_event_label = scene_root.get_node_or_null(EVENT_LABEL_NAME) as Label
	if _event_label == null:
		_event_label = Label.new()
		_event_label.name = EVENT_LABEL_NAME
		_event_label.top_level = true
		_event_label.position = Vector2(16.0, 220.0)
		_event_label.add_theme_font_size_override("font_size", 14)
		_event_label.add_theme_constant_override("outline_size", 2)
		_event_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
		scene_root.add_child(_event_label)

	_winner_label = scene_root.get_node_or_null(WINNER_LABEL_NAME) as Label
	if _winner_label == null:
		_winner_label = Label.new()
		_winner_label.name = WINNER_LABEL_NAME
		_winner_label.top_level = true
		_winner_label.position = Vector2(280.0, 16.0)
		_winner_label.add_theme_font_size_override("font_size", 20)
		_winner_label.add_theme_constant_override("outline_size", 3)
		_winner_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
		scene_root.add_child(_winner_label)


func remove_nodes() -> void:
	if _contact_line != null:
		_contact_line.queue_free()
		_contact_line = null
	if _event_label != null:
		_event_label.queue_free()
		_event_label = null
	if _winner_label != null:
		_winner_label.queue_free()
		_winner_label = null


func apply_overlay_visibility(status_label: Node, overlays_visible: bool, preview_mode: bool) -> void:
	var should_show: bool = overlays_visible and not preview_mode
	if status_label != null:
		status_label.set("visible", should_show)
	if _contact_line != null:
		_contact_line.visible = should_show
	if _event_label != null:
		_event_label.visible = should_show
	if _winner_label != null:
		_winner_label.visible = should_show


func update_event_label(event_text: String) -> void:
	if _event_label == null:
		return
	_event_label.text = "Event: %s" % event_text


func update_status_label(status_label: Node, state_name: String, context: Dictionary, overlays_visible: bool, preview_mode: bool) -> void:
	if status_label == null:
		return
	if preview_mode:
		status_label.set("visible", false)
		return
	status_label.set("visible", overlays_visible)
	status_label.set("text", build_status_text(state_name, context))


func update_winner_label(context: Dictionary) -> void:
	if _winner_label == null:
		return
	if bool(context.get("combat_finished", false)) and not String(context.get("winning_team_id", "")).is_empty():
		var result_text: String = String(context.get("result", "")).to_upper()
		var condition_text: String = String(context.get("win_condition_type", ""))
		_winner_label.text = "%s\nWinner: %s\nCondition: %s" % [result_text, String(context.get("winning_team_id", "")), condition_text]
		return
	_winner_label.text = ""


func set_contact_line(attacker: Node, target: Node, color: Color = Color(1.0, 0.18, 0.12, 0.92)) -> void:
	if _contact_line == null:
		return
	_contact_line.default_color = color
	_free_extra_contact_lines()
	_contact_line.clear_points()
	if attacker is Node2D and target is Node2D:
		_contact_line.add_point((attacker as Node2D).position)
		_contact_line.add_point((target as Node2D).position)


## Gefechtstakt: weitere Paare desselben Schritts. Die Linien haengen als Kinder an der ersten und verschwinden mit ihr.
func add_contact_line(attacker: Node, target: Node, color: Color = Color(1.0, 0.18, 0.12, 0.92)) -> void:
	if _contact_line == null or not (attacker is Node2D and target is Node2D):
		return
	var extra: Line2D = Line2D.new()
	extra.default_color = color
	extra.width = _contact_line.width
	extra.add_point((attacker as Node2D).position)
	extra.add_point((target as Node2D).position)
	_contact_line.add_child(extra)


func clear_contact_line() -> void:
	if _contact_line != null:
		_free_extra_contact_lines()
		_contact_line.clear_points()


func _free_extra_contact_lines() -> void:
	for extra in _contact_line.get_children():
		extra.queue_free()


func build_status_text(state_name: String, context: Dictionary) -> String:
	var lines: PackedStringArray = []
	lines.append("Combat: %s" % state_name)
	lines.append("Win condition: %s" % String(context.get("win_condition", "")))

	if bool(context.get("combat_finished", false)) and not String(context.get("winning_team_id", "")).is_empty():
		lines.append("Winner: %s" % String(context.get("winning_team_id", "")))

	lines.append("Enemies fit: %d" % int(context.get("enemy_fit_count", 0)))
	lines.append("Friendlies fit: %d" % int(context.get("friendly_fit_count", 0)))
	lines.append("Duration: %.1fs" % float(context.get("duration_seconds", 0.0)))
	lines.append(String(context.get("objective_status_text", "")))
	lines.append(String(context.get("wave_status_text", "")))

	if bool(context.get("show_hold_timer", false)):
		lines.append("Hold timer: %.1fs / %.1fs" % [float(context.get("objective_defense_elapsed_seconds", 0.0)), float(context.get("objective_defense_hold_seconds", 0.0))])

	lines.append("Next shot: %s" % String(context.get("attack_readiness_text", "")))
	lines.append("Last event: %s" % String(context.get("last_event_text", "")))

	var last_contact: Dictionary = Dictionary(context.get("last_contact", {}))
	if not last_contact.is_empty():
		lines.append("Last contact: %s -> %s" % [String(last_contact.get("attacker_id", "")), String(last_contact.get("target_id", ""))])

	return "\n".join(lines)


func get_presenter_snapshot() -> Dictionary:
	return {
		"contact_line_ready": _contact_line != null,
		"event_label_ready": _event_label != null,
		"winner_label_ready": _winner_label != null,
		"node_names": PackedStringArray([CONTACT_LINE_NAME, EVENT_LABEL_NAME, WINNER_LABEL_NAME]),
	}
