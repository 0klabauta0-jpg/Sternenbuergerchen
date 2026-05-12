extends Node

const LABEL_NAME: String = "ObjectiveStatusLabel"
const LABEL_OFFSET: Vector2 = Vector2(-44.0, -54.0)

@export var simulation_root_path: NodePath
@export var objective_marker_path: NodePath
@export var preview_mode: bool = false

var _status_label: Label = null
var _overlay_visible: bool = true


func _ready() -> void:
	if preview_mode:
		_remove_label()
		return
	_ensure_label()
	_apply_overlay_visibility()
	_refresh()


func _process(_delta: float) -> void:
	if preview_mode or not _overlay_visible:
		return
	_refresh()


func set_preview_mode(is_preview: bool) -> void:
	preview_mode = is_preview
	if preview_mode:
		_remove_label()
		return
	if is_inside_tree():
		_ensure_label()
		_apply_overlay_visibility()
		_refresh()


func set_overlay_visible(is_visible: bool) -> void:
	_overlay_visible = is_visible
	_apply_overlay_visibility()


func _refresh() -> void:
	if _status_label == null:
		return

	var objective_marker := get_node_or_null(objective_marker_path) as Node2D
	if objective_marker != null:
		_status_label.global_position = objective_marker.global_position + LABEL_OFFSET

	var objective_status = _get_objective_status()
	if objective_status == null:
		_status_label.text = "OBJ unavailable"
		_status_label.modulate = Color(0.9, 0.9, 0.9, 1.0)
		return

	var owner_text: String = String(objective_status.owning_team_id)
	if owner_text.is_empty():
		owner_text = "neutral"

	var progress_percent: int = int(round(clampf(float(objective_status.capture_progress), 0.0, 1.0) * 100.0))
	var capture_text: String = "CAP %d%%" % progress_percent
	if bool(objective_status.call("is_contested")):
		capture_text = "%s CONTESTED" % capture_text
	elif not String(objective_status.capturing_team_id).is_empty() and owner_text != String(objective_status.capturing_team_id):
		capture_text = "%s -> %s" % [capture_text, String(objective_status.capturing_team_id)]

	_status_label.text = "OBJ %s\n%s" % [owner_text, capture_text]
	_status_label.modulate = _build_status_color(objective_status)


func _ensure_label() -> void:
	_status_label = get_node_or_null(LABEL_NAME) as Label
	if _status_label == null:
		_status_label = Label.new()
		_status_label.name = LABEL_NAME
		_status_label.top_level = true
		_status_label.add_theme_font_size_override("font_size", 11)
		_status_label.add_theme_constant_override("outline_size", 2)
		_status_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
		add_child(_status_label)


func _apply_overlay_visibility() -> void:
	if _status_label == null:
		return
	_status_label.visible = _overlay_visible and not preview_mode


func _remove_label() -> void:
	if _status_label != null:
		_status_label.queue_free()
		_status_label = null


func _get_objective_status():
	var simulation_root = get_node_or_null(simulation_root_path)
	if simulation_root == null or not simulation_root.has_method("get_objective_status"):
		return null

	return simulation_root.call("get_objective_status")


func _build_status_color(objective_status) -> Color:
	if bool(objective_status.call("is_contested")):
		return Color(1.0, 0.78, 0.35, 1.0)

	match String(objective_status.owning_team_id):
		"team_alpha":
			return Color(0.55, 0.82, 1.0, 1.0)
		"team_bravo":
			return Color(1.0, 0.6, 0.6, 1.0)
		_:
			return Color(0.92, 0.92, 0.92, 1.0)
