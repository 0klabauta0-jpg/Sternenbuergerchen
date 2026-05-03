class_name CommandButton
extends Button

const TACTICAL_UI_THEME_SCRIPT: GDScript = preload("res://scripts/ui/tactical_ui_theme.gd")

var command_id: String = ""
var status_key: String = "neutral"


func _ready() -> void:
	clip_text = true
	custom_minimum_size = Vector2(maxf(custom_minimum_size.x, 64.0), maxf(custom_minimum_size.y, 22.0))
	TACTICAL_UI_THEME_SCRIPT.style_command_button(self, status_key)


func configure(next_text: String, next_command_id: String = "", next_tooltip: String = "", next_status_key: String = "neutral", next_icon: Texture2D = null) -> void:
	text = next_text.strip_edges()
	command_id = next_command_id.strip_edges()
	tooltip_text = next_tooltip.strip_edges()
	status_key = next_status_key.strip_edges().to_lower()
	icon = next_icon
	TACTICAL_UI_THEME_SCRIPT.style_command_button(self, status_key)
