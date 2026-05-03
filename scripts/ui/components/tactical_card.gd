class_name TacticalCard
extends PanelContainer

const TACTICAL_UI_THEME_SCRIPT: GDScript = preload("res://scripts/ui/tactical_ui_theme.gd")

var selected: bool = false


func _ready() -> void:
	apply_card_style(selected)


func apply_card_style(next_selected: bool = false) -> void:
	selected = next_selected
	TACTICAL_UI_THEME_SCRIPT.style_card(self, selected)


func ensure_content_host() -> VBoxContainer:
	var margin := get_node_or_null("MarginContainer") as MarginContainer
	if margin == null:
		margin = MarginContainer.new()
		margin.name = "MarginContainer"
		margin.add_theme_constant_override("margin_left", 8)
		margin.add_theme_constant_override("margin_top", 6)
		margin.add_theme_constant_override("margin_right", 8)
		margin.add_theme_constant_override("margin_bottom", 6)
		add_child(margin)
	var host := margin.get_node_or_null("VBoxContainer") as VBoxContainer
	if host == null:
		host = VBoxContainer.new()
		host.name = "VBoxContainer"
		host.add_theme_constant_override("separation", 4)
		margin.add_child(host)
	return host
