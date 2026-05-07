extends SceneTree

const NPC_VISUAL_MAPPING_PATH: String = "res://data/npc_unit_visual_mapping.json"
const SNIPER_MODEL_PATH: String = "res://Assets/used/npc/weapon_pack/models/sniper.glb"
const ROCKET_MODEL_PATH: String = "res://Assets/used/npc/weapon_pack/models/rocketlauncherModern.glb"
const SNIPER_PREVIEW_PATH: String = "res://Assets/used/npc/weapon_pack/previews/sniper.png"
const ROCKET_PREVIEW_PATH: String = "res://Assets/used/npc/weapon_pack/previews/rocketlauncherModern.png"

const WEAPON_DATA_SCRIPT: GDScript = preload("res://scripts/core/weapon_data.gd")
const LOADOUT_MODIFIER_RESOLVER_SCRIPT: GDScript = preload("res://scripts/command/loadout_modifier_resolver.gd")
const FOB_SCREEN_SCRIPT: GDScript = preload("res://scripts/meta/fob_screen.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_190 Weapon Visual Loadout Expansion and Scale ===")
	_test_weapon_catalog_and_alias_contract()
	_test_fob_selector_expands_with_previews()
	_test_visual_mapping_contract()
	await _test_runtime_visuals_and_simulation_boundary()
	_test_no_absolute_local_asset_paths()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_weapon_catalog_and_alias_contract() -> void:
	var all_ids: PackedStringArray = WEAPON_DATA_SCRIPT.call("get_all_weapon_ids")
	_assert(all_ids.has("sniper"), "Weapon catalog defines stable sniper ID")
	_assert(all_ids.has("rocket_launcher"), "Weapon catalog defines stable rocket_launcher ID")
	_assert(String(WEAPON_DATA_SCRIPT.call("normalize_weapon_id", "panzerfaust")) == "rocket_launcher", "Panzerfaust aliases to rocket_launcher")
	_assert(String(WEAPON_DATA_SCRIPT.call("normalize_weapon_id", "raketenwerfer")) == "rocket_launcher", "Raketenwerfer aliases to rocket_launcher")
	_assert(String(WEAPON_DATA_SCRIPT.call("normalize_weapon_id", "sniper_rifle")) == "sniper", "Sniper rifle aliases to sniper")
	_assert(String(WEAPON_DATA_SCRIPT.call("get_preview_path", "sniper")) == SNIPER_PREVIEW_PATH, "Sniper catalog points at the curated preview")
	_assert(String(WEAPON_DATA_SCRIPT.call("get_preview_path", "rocket_launcher")) == ROCKET_PREVIEW_PATH, "Rocket launcher catalog points at the curated preview")
	_assert(String(WEAPON_DATA_SCRIPT.call("get_visual_loadout_id", "sniper")) == "sniper_rifle", "Sniper catalog points at its visual loadout")
	_assert(String(WEAPON_DATA_SCRIPT.call("get_visual_loadout_id", "panzerfaust")) == "rocket_launcher", "Panzerfaust catalog resolves to rocket visual loadout")
	_assert(bool(WEAPON_DATA_SCRIPT.call("is_attack_weapon_id", "sniper")), "Sniper stays an attack weapon")
	_assert(bool(WEAPON_DATA_SCRIPT.call("is_attack_weapon_id", "rocket_launcher")), "Rocket launcher stays an attack weapon")

	var resolver = LOADOUT_MODIFIER_RESOLVER_SCRIPT.new()
	var sniper_modifiers = resolver.call("resolve_for_unit", "sniper_probe", {"weapon_1": "sniper", "weapon_2": "smg", "armor": "medium"})
	var rocket_modifiers = resolver.call("resolve_for_unit", "rocket_probe", {"weapon_1": "panzerfaust", "weapon_2": "smg", "armor": "medium"})
	var sniper_dict: Dictionary = Dictionary(sniper_modifiers.call("to_dict")) if sniper_modifiers != null else {}
	var rocket_dict: Dictionary = Dictionary(rocket_modifiers.call("to_dict")) if rocket_modifiers != null else {}
	_assert(String(sniper_dict.get("weapon_1_id", "")) == "sniper", "Loadout modifiers preserve sniper ID")
	_assert(String(rocket_dict.get("weapon_1_id", "")) == "rocket_launcher", "Loadout modifiers normalize panzerfaust to rocket_launcher")


func _test_fob_selector_expands_with_previews() -> void:
	var fob_screen = FOB_SCREEN_SCRIPT.new()
	var option_button := OptionButton.new()
	fob_screen.call("_populate_weapon_option_button", option_button, "panzerfaust")
	var ids: PackedStringArray = _option_metadata_ids(option_button)
	_assert(ids.size() >= 5, "#13 LOADOUT weapon selector contains the expanded compact option set")
	_assert(ids.has("smg") and ids.has("rifle") and ids.has("sniper") and ids.has("rocket_launcher") and ids.has("medictool"), "#13 LOADOUT selector includes base, new and support weapons")
	_assert(_selected_metadata_id(option_button) == "rocket_launcher", "#13 LOADOUT can preselect rocket launcher aliases")
	_assert(String(fob_screen.call("_weapon_id_from_index", ids.find("sniper"))) == "sniper", "#13 LOADOUT selector writes sniper ID")
	_assert(String(fob_screen.call("_weapon_id_from_index", ids.find("rocket_launcher"))) == "rocket_launcher", "#13 LOADOUT selector writes rocket_launcher ID")
	_assert(String(fob_screen.call("_get_weapon_preview_path", "sniper")) == SNIPER_PREVIEW_PATH, "#13 LOADOUT sniper preview uses project path")
	_assert(String(fob_screen.call("_get_weapon_preview_path", "panzerfaust")) == ROCKET_PREVIEW_PATH, "#13 LOADOUT rocket alias preview uses project path")
	option_button.queue_free()
	fob_screen.queue_free()


func _test_visual_mapping_contract() -> void:
	var mapping: Dictionary = _load_json(NPC_VISUAL_MAPPING_PATH)
	var loadouts: Dictionary = Dictionary(mapping.get("visual_loadouts", {}))
	var weapon_loadouts: Dictionary = Dictionary(mapping.get("weapon_visual_loadouts", {}))
	_assert(String(weapon_loadouts.get("sniper", "")) == "sniper_rifle", "NPC visual mapping connects sniper to sniper_rifle loadout")
	_assert(String(weapon_loadouts.get("rocket_launcher", "")) == "rocket_launcher", "NPC visual mapping connects rocket_launcher to rocket_launcher loadout")
	_assert(String(weapon_loadouts.get("panzerfaust", "")) == "rocket_launcher", "NPC visual mapping keeps panzerfaust alias visible")
	_assert(_loadout_maps_asset(loadouts, "sniper_rifle", SNIPER_MODEL_PATH), "Sniper visual loadout maps the curated GLB")
	_assert(_loadout_maps_asset(loadouts, "rocket_launcher", ROCKET_MODEL_PATH), "Rocket visual loadout maps the curated GLB")
	_assert(ResourceLoader.exists(SNIPER_MODEL_PATH), "Sniper GLB is importable from project path")
	_assert(ResourceLoader.exists(ROCKET_MODEL_PATH), "Rocket launcher GLB is importable from project path")
	_assert(ResourceLoader.exists(SNIPER_PREVIEW_PATH), "Sniper preview is importable from project path")
	_assert(ResourceLoader.exists(ROCKET_PREVIEW_PATH), "Rocket launcher preview is importable from project path")
	_assert(_attachment_socket(loadouts, "sniper_rifle") == "RightHandSocket", "Sniper visual uses a hand socket")
	_assert(_attachment_socket(loadouts, "rocket_launcher") == "BackSocket", "Rocket launcher visual uses the documented BackSocket")
	_assert(_attachment_scale(loadouts, "sniper_rifle") > 0.0 and _attachment_scale(loadouts, "sniper_rifle") <= 0.03, "Sniper scale is explicitly bounded")
	_assert(_attachment_scale(loadouts, "rocket_launcher") > 0.0 and _attachment_scale(loadouts, "rocket_launcher") <= 0.03, "Rocket launcher scale is explicitly bounded")
	_assert(not _entry_has_combat_fields(Dictionary(loadouts.get("sniper_rifle", {}))), "Sniper visual loadout stays visual-only")
	_assert(not _entry_has_combat_fields(Dictionary(loadouts.get("rocket_launcher", {}))), "Rocket launcher visual loadout stays visual-only")


func _test_runtime_visuals_and_simulation_boundary() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_190_weapon_visuals", Vector2i(4, 1), Vector2.ZERO)
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	var simulation_root: Node = SIMULATION_ROOT_SCRIPT.new()
	root.add_child(simulation_root)
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	var sniper_unit := _make_unit("task_190_sniper_probe", "team_alpha", "security_guard", "sniper", Vector2(0.0, 0.0))
	var rocket_unit := _make_unit("task_190_rocket_probe", "team_alpha", "support", "rocket_launcher", Vector2(64.0, 32.0))
	var alias_unit := _make_unit("task_190_panzerfaust_probe", "team_alpha", "support", "panzerfaust", Vector2(128.0, 64.0))
	root.add_child(sniper_unit)
	root.add_child(rocket_unit)
	root.add_child(alias_unit)
	var command_count_before: int = _array_property_size(simulation_root, "command_queue")
	var effect_count_before: int = _array_property_size(simulation_root, "effects_queue")
	primary_view.call("set_unit_nodes", [sniper_unit, rocket_unit, alias_unit])
	await _wait_frames(12)

	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(snapshot.get("unit_visual_loadout_count", 0)) >= 3, "Runtime resolves new weapon visual loadouts")
	_assert(int(snapshot.get("unit_visual_loadout_error_count", 0)) == 0, "Runtime new weapon visual loadouts have no missing-asset errors")
	_assert(int(snapshot.get("unit_blaster_attachment_count", 0)) >= 3, "Runtime attaches visible weapon models")
	var unit_root := primary_view.get_node_or_null("ViewportContainer/SubViewport/WorldRoot/UnitRoot3D")
	_assert(_proxy_has_visual(unit_root, "UnitProxy_task_190_sniper_probe", "BlasterVisual_sniper"), "Sniper probe renders the sniper model")
	_assert(_proxy_has_visual(unit_root, "UnitProxy_task_190_rocket_probe", "BlasterVisual_rocketlauncherModern"), "Rocket probe renders the rocket model")
	_assert(_proxy_has_visual(unit_root, "UnitProxy_task_190_panzerfaust_probe", "BlasterVisual_rocketlauncherModern"), "Panzerfaust alias renders the rocket model")
	var rocket_visual := _find_proxy_visual(unit_root, "UnitProxy_task_190_rocket_probe", "BlasterVisual_rocketlauncherModern") as Node3D
	_assert(rocket_visual != null and String(rocket_visual.get_meta("attachment_socket", "")) == "BackSocket", "Rocket visual is attached through BackSocket")
	_assert(rocket_visual != null and rocket_visual.scale.x <= 0.03, "Rocket visual runtime scale stays bounded")
	await _wait_frames(2)
	_assert(_array_property_size(simulation_root, "command_queue") == command_count_before, "Weapon visuals do not enqueue SimulationRoot commands")
	_assert(_array_property_size(simulation_root, "effects_queue") == effect_count_before, "Weapon visuals do not enqueue SimulationRoot effects")

	primary_view.queue_free()
	simulation_root.queue_free()
	sniper_unit.queue_free()
	rocket_unit.queue_free()
	alias_unit.queue_free()
	await process_frame


func _test_no_absolute_local_asset_paths() -> void:
	for file_path in [
		"res://scripts/meta/fob_screen.gd",
		"res://scripts/core/weapon_data.gd",
		"res://data/npc_unit_visual_mapping.json",
	]:
		var text: String = _read_text_file(file_path)
		_assert(not text.contains("C:" + "\\" + "Users" + "\\"), "%s does not reference local user asset paths" % file_path)


func _make_unit(unit_id: String, team_id: String, role_id: String, weapon_id: String, position: Vector2) -> Node2D:
	var unit := TEST_UNIT_SCRIPT.new() as Node2D
	unit.unit_id = unit_id
	unit.team_id = team_id
	unit.role_id = role_id
	unit.weapon_1_id = weapon_id
	unit.weapon_2_id = "smg"
	unit.global_position = position
	return unit


func _option_metadata_ids(option_button: OptionButton) -> PackedStringArray:
	var ids := PackedStringArray()
	for index in range(option_button.item_count):
		var metadata_id: String = String(option_button.get_item_metadata(index)).strip_edges()
		if not metadata_id.is_empty():
			ids.append(metadata_id)
	return ids


func _selected_metadata_id(option_button: OptionButton) -> String:
	var selected_index: int = option_button.selected
	if selected_index < 0:
		return ""
	return String(option_button.get_item_metadata(selected_index)).strip_edges()


func _loadout_maps_asset(loadouts: Dictionary, loadout_id: String, expected_path: String) -> bool:
	var loadout: Dictionary = Dictionary(loadouts.get(loadout_id, {}))
	return String(loadout.get("blaster_path", "")) == expected_path


func _attachment_socket(loadouts: Dictionary, loadout_id: String) -> String:
	return String(Dictionary(Dictionary(loadouts.get(loadout_id, {})).get("blaster_attachment", {})).get("socket_name", "")).strip_edges()


func _attachment_scale(loadouts: Dictionary, loadout_id: String) -> float:
	return float(Dictionary(Dictionary(loadouts.get(loadout_id, {})).get("blaster_attachment", {})).get("scale", 0.0))


func _proxy_has_visual(unit_root: Node, proxy_name: String, visual_prefix: String) -> bool:
	return _find_proxy_visual(unit_root, proxy_name, visual_prefix) != null


func _find_proxy_visual(unit_root: Node, proxy_name: String, visual_prefix: String) -> Node:
	var proxy := unit_root.get_node_or_null(proxy_name) if unit_root != null else null
	return _find_node_with_prefix(proxy, visual_prefix) if proxy != null else null


func _find_node_with_prefix(node: Node, prefix: String) -> Node:
	if node == null:
		return null
	if String(node.name).begins_with(prefix):
		return node
	for child in node.get_children():
		var found: Node = _find_node_with_prefix(child, prefix)
		if found != null:
			return found
	return null


func _entry_has_combat_fields(entry: Dictionary) -> bool:
	for forbidden_key in ["damage_per_hit", "base_hit_chance", "effective_range", "ticks_between_attacks", "ammo", "reload_time", "splash_radius"]:
		if entry.has(forbidden_key):
			return true
	return false


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func _read_text_file(file_path: String) -> String:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _array_property_size(node: Node, property_name: String) -> int:
	if node == null:
		return 0
	var value = node.get(property_name)
	return Array(value).size() if value is Array else 0


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
