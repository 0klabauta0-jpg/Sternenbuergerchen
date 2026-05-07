class_name SettingsScreen
extends RefCounted

const GAME_SETTINGS_CONTRACT_SCRIPT: GDScript = preload("res://scripts/ui/game_settings_contract.gd")
const COMIC_BUBBLE_SETTINGS_SCRIPT: GDScript = preload("res://scripts/ui/comic_bubble_settings.gd")


static func build_section_snapshot(game_settings: Dictionary, comic_bubble_settings: Dictionary) -> Dictionary:
	var game_snapshot: Dictionary = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("build_snapshot", game_settings))
	var comic_snapshot: Dictionary = Dictionary(COMIC_BUBBLE_SETTINGS_SCRIPT.call("build_snapshot", comic_bubble_settings))
	return {
		"display": Dictionary(game_snapshot.get("display", {})),
		"audio": Dictionary(game_snapshot.get("audio", {})),
		"input": Dictionary(game_snapshot.get("input", {})),
		"gameplay": {
			"fog_of_war": Dictionary(game_snapshot.get("gameplay", {})),
			"contextual_help": {
				"mode": String(game_snapshot.get(GAME_SETTINGS_CONTRACT_SCRIPT.KEY_CONTEXTUAL_HELP_MODE, GAME_SETTINGS_CONTRACT_SCRIPT.CONTEXTUAL_HELP_MODE_COMPACT)),
				"valid_modes": GAME_SETTINGS_CONTRACT_SCRIPT.VALID_CONTEXTUAL_HELP_MODES,
				"default_mode": GAME_SETTINGS_CONTRACT_SCRIPT.CONTEXTUAL_HELP_MODE_COMPACT,
			},
			"comic_bubbles": comic_snapshot,
		},
		"supports_apply_cancel_reset": true,
		"rebindable_input": false,
	}


static func configure_option_button(option_button: OptionButton, items: PackedStringArray, selected_value: String, label_map: Dictionary = {}) -> void:
	if option_button == null:
		return
	option_button.clear()
	for item in items:
		option_button.add_item(String(label_map.get(String(item), String(item))))
		var item_index: int = option_button.item_count - 1
		option_button.set_item_metadata(item_index, String(item))
		if String(item) == selected_value:
			option_button.select(item_index)


static func select_option_metadata(option_button: OptionButton, selected_value: String, fallback_index: int = 0) -> void:
	if option_button == null:
		return
	for index in range(option_button.item_count):
		if String(option_button.get_item_metadata(index)) == selected_value:
			option_button.select(index)
			return
	if option_button.item_count > 0:
		option_button.select(clampi(fallback_index, 0, option_button.item_count - 1))


static func mode_label(mode: String) -> String:
	match mode.strip_edges().to_lower():
		"off":
			return "Aus"
		"minimal":
			return "Minimal"
		"debug":
			return "Debug"
		"known_terrain":
			return "Bekanntes Terrain"
		"unexplored_blackout":
			return "Blackout"
		"windowed":
			return "Fenster"
		"borderless":
			return "Randlos"
		"fullscreen":
			return "Vollbild"
		"compact":
			return "Kompakt"
		"expanded":
			return "Erweitert"
		_:
			return "Normal"
