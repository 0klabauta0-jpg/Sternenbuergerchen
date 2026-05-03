class_name UnitRosterRow
extends HBoxContainer

const STATUS_BADGE_SCRIPT: GDScript = preload("res://scripts/ui/components/status_badge.gd")
const TACTICAL_UI_THEME_SCRIPT: GDScript = preload("res://scripts/ui/tactical_ui_theme.gd")

var _name_label: Label
var _role_label: Label
var _status_badge: Label


func _ready() -> void:
	_ensure_ui()


func set_unit_snapshot(snapshot: Dictionary) -> void:
	_ensure_ui()
	var display_name: String = String(snapshot.get("display_name", snapshot.get("name", "Unknown"))).strip_edges()
	var role_text: String = String(snapshot.get("role", snapshot.get("role_name", ""))).strip_edges()
	var status_text: String = String(snapshot.get("status", snapshot.get("vital_state", "ready"))).strip_edges()
	var status_key: String = String(snapshot.get("status_key", status_text)).strip_edges().to_lower()
	_name_label.text = display_name if not display_name.is_empty() else "Unknown"
	_role_label.text = role_text if not role_text.is_empty() else "Operator"
	_status_badge.set_badge(status_text if not status_text.is_empty() else "Ready", status_key)


func _ensure_ui() -> void:
	add_theme_constant_override("separation", 6)
	custom_minimum_size = Vector2(maxf(custom_minimum_size.x, 220.0), maxf(custom_minimum_size.y, 24.0))
	if _name_label == null:
		_name_label = get_node_or_null("NameLabel") as Label
		if _name_label == null:
			_name_label = Label.new()
			_name_label.name = "NameLabel"
			_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_name_label.clip_text = true
			add_child(_name_label)
	if _role_label == null:
		_role_label = get_node_or_null("RoleLabel") as Label
		if _role_label == null:
			_role_label = Label.new()
			_role_label.name = "RoleLabel"
			_role_label.custom_minimum_size = Vector2(72.0, 0.0)
			_role_label.clip_text = true
			add_child(_role_label)
	if _status_badge == null:
		_status_badge = get_node_or_null("StatusBadge") as Label
		if _status_badge == null:
			_status_badge = STATUS_BADGE_SCRIPT.new()
			_status_badge.name = "StatusBadge"
			add_child(_status_badge)
	TACTICAL_UI_THEME_SCRIPT.style_label(_name_label, false, 10)
	TACTICAL_UI_THEME_SCRIPT.style_label(_role_label, true, 9)
