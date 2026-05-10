extends SceneTree

const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/ui/main_menu.tscn")
const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")
const START_ROSTER_GENERATOR_SCRIPT: GDScript = preload("res://scripts/meta/start_roster_generator.gd")
const PORTRAIT_IDENTITY_CATALOG_SCRIPT: GDScript = preload("res://scripts/meta/portrait_identity_catalog.gd")
const NPC_RANK_BADGE_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/npc_rank_badge_resolver.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== BUGFIX Character Team Editor Usability Pass ===")
	_test_rookie_budget_policy_contract()
	_test_rank_badges_expose_dynamic_help_details()
	await _test_team_editor_character_identity_and_metric_persistence()
	await _test_help_hover_ignores_freed_controls()
	await _test_map_editor_layer_stack_hint()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_rookie_budget_policy_contract() -> void:
	var editor: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("normalize_team_editor"))
	var policy: Dictionary = Dictionary(editor.get("point_budget_policy", {}))
	var size_policy: Dictionary = Dictionary(editor.get("team_size_policy", {}))
	_assert(int(editor.get("point_budget_max", 0)) == 30, "Team editor keeps the Rookie total budget at 30")
	_assert(int(policy.get("min_per_stat", -1)) == 0 and int(policy.get("max_per_stat", 0)) == 10, "Team editor exposes per-focus min/max")
	for definition_variant in Array(editor.get("stat_definitions", [])):
		var definition: Dictionary = Dictionary(definition_variant)
		_assert(not String(definition.get("effect_text", "")).strip_edges().is_empty(), "Stat %s explains its derived effect" % String(definition.get("id", "")))
	_assert(int(size_policy.get("singleplayer_initial_min", 0)) == 20 and int(size_policy.get("singleplayer_initial_max", 0)) == 30, "Singleplayer start size policy is visible")
	_assert(int(size_policy.get("multiplayer_side_cap", 0)) == 40, "Multiplayer side cap is documented for UI scroll planning")


func _test_rank_badges_expose_dynamic_help_details() -> void:
	var shooter_profile: Dictionary = {
		"role_name": "Marksman",
		"weapon_1_id": "rifle",
		"skill_values": {
			"accuracy": 0.82,
			"leadership": 0.24,
		},
		"platform_values": {},
	}
	var badges: Array = Array(NPC_RANK_BADGE_RESOLVER_SCRIPT.call("derive_badges", shooter_profile, 3))
	var shooter_badge: Dictionary = _find_badge(badges, "shooter")
	_assert(not shooter_badge.is_empty(), "Shooter badge can be derived from weapon and Accuracy")
	_assert(String(shooter_badge.get("help_id", "")) == "character_sheet.rank_badge.shooter", "Shooter badge exposes a granular help id")
	_assert(String(shooter_badge.get("reason", "")).contains("Accuracy"), "Shooter badge reason explains the source value")
	_assert(String(shooter_badge.get("detail_text", "")).contains("0.68"), "Shooter badge detail exposes the threshold formula")
	var badge_control := TextureRect.new()
	NPC_RANK_BADGE_RESOLVER_SCRIPT.call("apply_badge_help_metadata", badge_control, shooter_badge)
	_assert(String(badge_control.get_meta("help_id", "")) == "character_sheet.rank_badge.shooter", "Badge controls carry the granular contextual help id")
	_assert(String(badge_control.tooltip_text).contains("Accuracy"), "Badge native tooltip keeps the composition text for FOB/Homebase")
	badge_control.free()


func _test_team_editor_character_identity_and_metric_persistence() -> void:
	root.size = Vector2i(1920, 1080)
	var save_path: String = "user://bugfix_team_character_editor_%d/roster_v1.json" % Time.get_ticks_msec()
	var menu := MAIN_MENU_SCENE.instantiate() as Control
	root.add_child(menu)
	await _wait_frames(3)
	menu.call("set_start_roster_store_path_for_tests", save_path, "bugfix_team_character_editor", true)
	menu.call("ensure_start_roster_exists", "bugfix_team_character_editor_seed", 24)
	var library_snapshot: Dictionary = Dictionary(menu.call("get_team_library_snapshot"))
	_assert(bool(library_snapshot.get("edit_enabled", false)), "Created team list exposes an explicit edit action")
	menu.call("open_team_editor")
	menu.call("set_team_editor_view_mode_for_tests", "sheet")
	await _wait_frames(2)
	var sheet_snapshot: Dictionary = Dictionary(menu.call("get_team_editor_snapshot"))
	var selected_unit_id: String = String(sheet_snapshot.get("selected_unit_id", ""))
	_assert(bool(sheet_snapshot.get("character_name_edit_visible", false)), "Character sheet mode exposes a name editor")
	_assert(int(sheet_snapshot.get("character_portrait_option_count", 0)) >= 30, "Character sheet mode exposes portrait choices from the catalog")
	_assert(bool(sheet_snapshot.get("character_has_portrait_preview", false)), "Character sheet mode shows a live portrait preview")
	var help_ids: PackedStringArray = _collect_help_ids(menu)
	for required_help_id in [
		"team_editor.team_name",
		"team_editor.symbol",
		"character_sheet.name",
		"character_sheet.portrait",
		"character_sheet.core.accuracy",
		"character_sheet.platform.dropship_piloting",
		"character_sheet.trait.calm",
		"character_sheet.trait.steady",
	]:
		_assert(help_ids.has(required_help_id), "Team editor exposes granular help popup ID: %s" % required_help_id)
	_assert(String(sheet_snapshot.get("budget_explanation", "")).contains("NPC-Werte"), "Team focus copy explains that NPC values are edited separately")
	_assert(not bool(sheet_snapshot.get("short_description_section_visible", true)), "Team editor sheet hides the short description block")
	_assert(_scroll_has_hover_contract(menu, "TeamEditorCardsScroll") and _scroll_has_hover_contract(menu, "TeamEditorStatsScroll"), "Team editor scroll regions activate on hover")
	var set_name: Dictionary = Dictionary(menu.call("set_team_editor_unit_name_for_tests", selected_unit_id, "Edited Rookie"))
	_assert(bool(set_name.get("ok", false)) and _unit_field(menu, selected_unit_id, "display_name") == "Edited Rookie", "Character name edits persist immediately")
	var next_portrait_id: String = _find_different_portrait_id(String(_unit_field(menu, selected_unit_id, "portrait_id")))
	var set_portrait: Dictionary = Dictionary(menu.call("set_team_editor_unit_portrait_for_tests", selected_unit_id, next_portrait_id))
	_assert(bool(set_portrait.get("ok", false)) and _unit_field(menu, selected_unit_id, "portrait_id") == next_portrait_id, "Portrait selection persists immediately")
	var medical_low: Dictionary = Dictionary(menu.call("set_team_editor_stat_for_tests", "medical", 0))
	var tactics_high: Dictionary = Dictionary(menu.call("set_team_editor_stat_for_tests", "tactics", 10))
	var blocked_above_max: Dictionary = Dictionary(menu.call("set_team_editor_stat_for_tests", "tactics", 11))
	_assert(bool(medical_low.get("ok", false)) and bool(tactics_high.get("ok", false)), "Rookie budget can move points between focuses")
	_assert(int(blocked_above_max.get("value", 0)) == 10, "Per-focus max blocks values above 10")
	var old_accuracy: float = _unit_skill_value(menu, selected_unit_id, "accuracy")
	var old_function_summary: String = String(Dictionary(menu.call("get_team_editor_snapshot")).get("selected_unit_function_summary", ""))
	var plus_button := menu.find_child("MetricPlus_accuracy", true, false) as Button
	_assert(plus_button != null, "Character sheet renders editable core metric controls in the team editor")
	_assert(menu.find_child("MetricPlus_dropship_piloting", true, false) != null, "Character sheet exposes editable dropship piloting")
	_assert(menu.find_child("MetricPlus_freighter_piloting", true, false) != null, "Character sheet exposes editable freighter piloting")
	_assert(menu.find_child("MetricPlus_fighter_piloting", true, false) != null, "Character sheet exposes editable fighter piloting")
	if plus_button != null:
		plus_button.emit_signal("pressed")
		await _wait_frames(2)
	_assert(_unit_skill_value(menu, selected_unit_id, "accuracy") > old_accuracy, "Character metric edits persist back into the roster")
	var new_function_summary: String = String(Dictionary(menu.call("get_team_editor_snapshot")).get("selected_unit_function_summary", ""))
	_assert(new_function_summary != old_function_summary, "Derived function summary refreshes after a live value edit")
	_assert(menu.find_child("DerivedDetail_method_tags", true, false) != null, "Derived values show formula/detail text")
	menu.queue_free()
	await _wait_frames(2)


func _test_help_hover_ignores_freed_controls() -> void:
	var menu := MAIN_MENU_SCENE.instantiate() as Control
	root.add_child(menu)
	await _wait_frames(3)
	var hover_target := Button.new()
	hover_target.name = "FreedHelpHoverProbe"
	menu.add_child(hover_target)
	menu.call("_on_help_target_entered", hover_target, "team_editor.stat.tactics")
	var hover_token: int = int(menu.get("_help_hover_token"))
	hover_target.queue_free()
	await _wait_frames(2)
	_assert(not bool(menu.call("_help_hover_is_current", hover_token, "team_editor.stat.tactics", hover_target)), "Main menu help hover ignores controls freed before the delayed popup")
	await _wait_frames(40)
	var help_snapshot: Dictionary = Dictionary(menu.call("get_contextual_help_snapshot"))
	var popup_snapshot: Dictionary = Dictionary(help_snapshot.get("popup", {}))
	_assert(not bool(popup_snapshot.get("visible", false)), "Delayed help popup stays hidden after its hover target was freed")
	menu.queue_free()
	await _wait_frames(2)


func _test_map_editor_layer_stack_hint() -> void:
	var editor := MAP_EDITOR_SCENE.instantiate()
	root.add_child(editor)
	await _wait_frames(14)
	_assert(bool(editor.call("select_grid_for_authoring", Vector2i(1, 1))), "Map editor can select a tile for layer-stack inspection")
	var map_data = editor.get("_terrain_map_data")
	var tile_data = map_data.call("get_tile_at_grid", Vector2i(1, 1)) if map_data != null else null
	_assert(tile_data != null, "Selected map tile exists")
	if tile_data != null:
		tile_data.type_id = "station_wall"
		tile_data.object_type_id = "spacekit_satellite_dish"
		editor.call("_refresh_property_panel")
		var selected_tile: Dictionary = Dictionary(Dictionary(editor.call("get_map_editor_usability_snapshot", false)).get("selected_tile", {}))
		var layer_stack: Dictionary = Dictionary(selected_tile.get("layer_stack", {}))
		_assert(String(layer_stack.get("structure_layer", "")) == "station_wall", "Layer stack keeps the structure layer")
		_assert(String(layer_stack.get("object_layer", "")) == "spacekit_satellite_dish", "Layer stack keeps an object on top of the structure")
		_assert(bool(layer_stack.get("has_object_on_structure", false)), "Map editor documents object-on-structure stacking")
		_assert(String(layer_stack.get("help_text", "")).contains("Satellitenschuessel"), "Layer stack tooltip explains the satellite dish workflow")
	editor.queue_free()
	await _wait_frames(2)


func _unit_field(menu: Control, unit_id: String, key: String) -> Variant:
	for unit_variant in Array(Dictionary(menu.get("_start_roster")).get("units", [])):
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit: Dictionary = Dictionary(unit_variant)
		if String(unit.get("unit_id", "")) == unit_id:
			return unit.get(key)
	return null


func _unit_skill_value(menu: Control, unit_id: String, skill_id: String) -> float:
	var skill_values: Dictionary = Dictionary(_unit_field(menu, unit_id, "skill_values"))
	return float(skill_values.get(skill_id, 0.0))


func _find_badge(badges: Array, badge_key: String) -> Dictionary:
	for badge_variant in badges:
		if typeof(badge_variant) != TYPE_DICTIONARY:
			continue
		var badge: Dictionary = Dictionary(badge_variant)
		if String(badge.get("badge_key", "")).strip_edges() == badge_key:
			return badge
	return {}


func _find_different_portrait_id(current_id: String) -> String:
	for entry_variant in Array(PORTRAIT_IDENTITY_CATALOG_SCRIPT.call("get_candidate_entries")):
		var entry: Dictionary = Dictionary(entry_variant)
		var entry_id: String = String(entry.get("id", ""))
		if not entry_id.is_empty() and entry_id != current_id:
			return entry_id
	return current_id


func _scroll_has_hover_contract(root_node: Node, node_name: String) -> bool:
	var scroll := root_node.find_child(node_name, true, false) as ScrollContainer
	return scroll != null and bool(scroll.get_meta("hover_scroll_enabled", false)) and scroll.focus_mode == Control.FOCUS_ALL


func _collect_help_ids(node: Node) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	if node == null:
		return result
	if node.has_meta("help_id"):
		var help_id: String = String(node.get_meta("help_id", "")).strip_edges()
		if not help_id.is_empty() and not result.has(help_id):
			result.append(help_id)
	for child in node.get_children():
		for child_help_id in _collect_help_ids(child):
			if not result.has(child_help_id):
				result.append(child_help_id)
	return result


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
