class_name ProgressLine
extends VBoxContainer

const TACTICAL_UI_THEME_SCRIPT: GDScript = preload("res://scripts/ui/tactical_ui_theme.gd")

var _label: Label
var _progress_bar: ProgressBar


func _ready() -> void:
	_ensure_ui()


func set_progress(label_text: String, value: float, max_value: float = 1.0, status_key: String = "neutral") -> void:
	_ensure_ui()
	var safe_max: float = maxf(max_value, 0.001)
	_label.text = "%s %.0f%%" % [label_text.strip_edges(), clampf(value / safe_max, 0.0, 1.0) * 100.0]
	_progress_bar.max_value = safe_max
	_progress_bar.value = clampf(value, 0.0, safe_max)
	TACTICAL_UI_THEME_SCRIPT.style_label(_label, true, 8)
	TACTICAL_UI_THEME_SCRIPT.style_progress_bar(_progress_bar, status_key)


func _ensure_ui() -> void:
	add_theme_constant_override("separation", 2)
	custom_minimum_size = Vector2(maxf(custom_minimum_size.x, 78.0), maxf(custom_minimum_size.y, 20.0))
	if _label == null:
		_label = get_node_or_null("ProgressLabel") as Label
		if _label == null:
			_label = Label.new()
			_label.name = "ProgressLabel"
			_label.clip_text = true
			add_child(_label)
	if _progress_bar == null:
		_progress_bar = get_node_or_null("ProgressBar") as ProgressBar
		if _progress_bar == null:
			_progress_bar = ProgressBar.new()
			_progress_bar.name = "ProgressBar"
			_progress_bar.show_percentage = false
			_progress_bar.custom_minimum_size = Vector2(0.0, 6.0)
			add_child(_progress_bar)
