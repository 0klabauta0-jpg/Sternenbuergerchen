class_name UITooltipIconHelper
extends RefCounted

const TACTICAL_UI_THEME_SCRIPT: GDScript = preload("res://scripts/ui/tactical_ui_theme.gd")

const CURATED_ICON_PATHS := {
	"check": "res://Assets/kenney_ui-pack/PNG/Grey/Default/icon_checkmark.png",
	"cross": "res://Assets/kenney_ui-pack/PNG/Grey/Default/icon_cross.png",
	"circle": "res://Assets/kenney_ui-pack/PNG/Grey/Default/icon_circle.png",
	"star": "res://Assets/kenney_ui-pack/PNG/Grey/Default/star.png",
	"arrow_e": "res://Assets/kenney_ui-pack/PNG/Grey/Double/arrow_basic_e_small.png",
	"panel": "res://Assets/kenney_ui-pack-space-expansion/PNG/Grey/Default/bar_square_large.png",
	"button": "res://Assets/kenney_ui-pack-space-expansion/PNG/Grey/Default/button_square_header_small_rectangle_screws.png",
	"cursor_select": "res://Assets/kenney_cursor-pixel-pack/Tiles/tile_0000.png",
}


static func get_curated_icon_paths() -> Dictionary:
	return CURATED_ICON_PATHS.duplicate()


static func load_icon(icon_id: String) -> Texture2D:
	var normalized_id: String = icon_id.strip_edges().to_lower()
	var path: String = String(CURATED_ICON_PATHS.get(normalized_id, "")).strip_edges()
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


static func apply_tooltip(control: Control, tooltip_text: String) -> void:
	if control == null:
		return
	control.tooltip_text = tooltip_text.strip_edges()


static func create_icon_texture_rect(icon_id: String, size: Vector2 = TACTICAL_UI_THEME_SCRIPT.COMPACT_ICON_SIZE, tooltip_text: String = "") -> TextureRect:
	var texture_rect := TextureRect.new()
	texture_rect.texture = load_icon(icon_id)
	texture_rect.custom_minimum_size = size
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.mouse_filter = Control.MOUSE_FILTER_PASS if not tooltip_text.strip_edges().is_empty() else Control.MOUSE_FILTER_IGNORE
	apply_tooltip(texture_rect, tooltip_text)
	return texture_rect
