class_name StatusBadge
extends Label

const TACTICAL_UI_THEME_SCRIPT: GDScript = preload("res://scripts/ui/tactical_ui_theme.gd")

var status_key: String = "neutral"


func _ready() -> void:
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	custom_minimum_size = Vector2(62.0, 20.0)
	clip_text = true
	set_badge(text, status_key)


func set_badge(label_text: String, next_status_key: String = "neutral") -> void:
	status_key = next_status_key.strip_edges().to_lower()
	text = label_text.strip_edges().to_upper()
	if text.is_empty():
		text = "STATUS"
	TACTICAL_UI_THEME_SCRIPT.style_badge(self, status_key)
