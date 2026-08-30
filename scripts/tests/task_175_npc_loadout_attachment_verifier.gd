extends SceneTree

const LIVE_MISSION_SCENE_PATH: String = "res://scenes/tests/mission_reactivity_test.tscn"
const NPC_VISUAL_MAPPING_PATH: String = "res://data/npc_unit_visual_mapping.json"
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

const BLASTER_A_PATH: String = "res://Assets/used/npc/blaster_kit/models/blaster-a.glb"
const BLASTER_B_PATH: String = "res://Assets/used/npc/blaster_kit/models/blaster-b.glb"
const BLASTER_F_PATH: String = "res://Assets/used/npc/blaster_kit/models/blaster-f.glb"
const BLASTER_P_PATH: String = "res://Assets/used/npc/blaster_kit/models/blaster-p.glb"
const BROKEN_BLASTER_PATH: String = "res://Assets/used/npc/blaster_kit/models/missing-task-175.glb"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_175 NPC Loadout Attachment Verifier ===")
	_test_mapping_loadout_contract()
	await _test_runtime_loadout_override_and_missing_diagnosis()
	await _test_live_visual_loadouts_do_not_mutate_simulation()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit(1 if _failed > 0 else 0)
func _test_mapping_loadout_contract() -> void:
	var mapping: Dictionary = _load_json(NPC_VISUAL_MAPPING_PATH)
	_assert(not mapping.is_empty(), "NPC visual mapping is loadable")
	var defaults: Dictionary = Dictionary(mapping.get("defaults", {}))
	_assert(String(defaults.get("visual_loadout_id", "")) == "standard_rifle", "Defaults select a visual loadout")

	var loadouts: Dictionary = Dictionary(mapping.get("visual_loadouts", {}))
	for loadout_id in ["standard_rifle", "compact_blaster", "medictool_blaster", "heavy_blaster"]:
		var loadout: Dictionary = Dictionary(loadouts.get(loadout_id, {}))
		_assert(not loadout.is_empty(), "%s visual loadout exists" % loadout_id)
		_assert(ResourceLoader.exists(String(loadout.get("helmet_path", ""))), "%s loadout maps a loadable helmet" % loadout_id)
		_assert(ResourceLoader.exists(String(loadout.get("blaster_path", ""))), "%s loadout maps a loadable blaster" % loadout_id)
		_assert(not _entry_has_combat_fields(loadout), "%s loadout stays visual-only" % loadout_id)

	var weapon_loadouts: Dictionary = Dictionary(mapping.get("weapon_visual_loadouts", {}))
	_assert(String(weapon_loadouts.get("rifle", "")) == "standard_rifle", "Rifle maps to standard rifle visual loadout")
	_assert(String(weapon_loadouts.get("smg", "")) == "standard_rifle", "SMG maps to blaster-a visual loadout")
	_assert(String(weapon_loadouts.get("medictool", "")) == "medictool_blaster", "Medictool maps to blaster-b visual loadout")
	_assert(String(weapon_loadouts.get("rail_gun", "")) == "heavy_blaster", "Rail gun maps to heavy blaster visual loadout")

	var visual_entries: Dictionary = Dictionary(mapping.get("unit_visuals", {}))
	_assert(_resolve_visual_attachment_path(mapping, Dictionary(visual_entries.get("team_alpha", {})), "blaster_path") == BLASTER_A_PATH, "Team alpha keeps the TASK_174 default blaster")
	_assert(_resolve_visual_attachment_path(mapping, Dictionary(visual_entries.get("team_bravo", {})), "blaster_path") == BLASTER_F_PATH, "Team bravo selects compact blaster through loadout")
	var unit_entries: Dictionary = Dictionary(mapping.get("unit_ids", {}))
	_assert(_resolve_visual_attachment_path(mapping, Dictionary(unit_entries.get("enemy_echo", {})), "blaster_path") == BLASTER_P_PATH, "Unit override selects heavy blaster through loadout")


func _test_runtime_loadout_override_and_missing_diagnosis() -> void:
	var mapping: Dictionary = _build_probe_mapping()
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_175_loadout_probe", Vector2i(4, 1), Vector2.ZERO)
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	primary_view.set("_npc_unit_visual_mapping", mapping)

	var default_unit := _make_unit("task_175_default_probe", "team_alpha", "security_guard", "rifle", Vector2(0.0, 0.0))
	var smg_unit := _make_unit("task_175_smg_probe", "team_alpha", "security_guard", "smg", Vector2(64.0, 32.0))
	var medictool_unit := _make_unit("task_175_medictool_probe", "team_alpha", "security_guard", "rifle", Vector2(128.0, 64.0), "medictool")
	var broken_unit := _make_unit("task_175_missing_probe", "team_alpha", "security_guard", "rifle", Vector2(192.0, 96.0))
	root.add_child(default_unit)
	root.add_child(smg_unit)
	root.add_child(medictool_unit)
	root.add_child(broken_unit)
	primary_view.call("set_unit_nodes", [default_unit, smg_unit, medictool_unit, broken_unit])
	await _wait_frames(10)

	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(snapshot.get("unit_visual_loadout_count", 0)) >= 4, "Runtime proxies resolve visual loadouts")
	_assert(int(snapshot.get("unit_visual_loadout_error_count", 0)) == 1, "Broken visual loadout records one diagnostic error")
	_assert(int(snapshot.get("unit_blaster_error_count", 0)) == 1, "Broken visual loadout exposes a blaster attachment error")

	var unit_root := primary_view.get_node_or_null("ViewportContainer/SubViewport/WorldRoot/UnitRoot3D")
	_assert(_proxy_has_visual(unit_root, "UnitProxy_task_175_default_probe", "BlasterVisual_blaster-a"), "Default probe keeps standard rifle blaster")
	_assert(_proxy_has_visual(unit_root, "UnitProxy_task_175_smg_probe", "BlasterVisual_blaster-a"), "SMG weapon override selects blaster-a")
	_assert(_proxy_has_visual(unit_root, "UnitProxy_task_175_medictool_probe", "BlasterVisual_blaster-b"), "Medictool weapon override selects blaster-b")
	_assert(_proxy_has_visual(unit_root, "UnitProxy_task_175_missing_probe", "MissingAsset_unit_blaster"), "Broken visual loadout renders missing-asset diagnosis")

	primary_view.queue_free()
	default_unit.queue_free()
	smg_unit.queue_free()
	medictool_unit.queue_free()
	broken_unit.queue_free()
	await process_frame


func _test_live_visual_loadouts_do_not_mutate_simulation() -> void:
	var packed_scene := load(LIVE_MISSION_SCENE_PATH) as PackedScene
	_assert(packed_scene != null, "Live mission scene loads")
	if packed_scene == null:
		return
	var live_scene := packed_scene.instantiate()
	root.add_child(live_scene)
	await _wait_frames(18)
	await _wait_physics_frames(4)

	var simulation_root: Node = live_scene.get_node_or_null("SimulationRoot")
	var command_count_before: int = _get_array_property_size(simulation_root, "command_queue")
	var effect_count_before: int = _get_array_property_size(simulation_root, "effects_queue")
	var primary_view: Node = live_scene.get_node_or_null("Primary3DView")
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot")) if primary_view != null else {}
	var animated_count: int = int(snapshot.get("animated_unit_model_count", 0))
	_assert(animated_count >= 2, "Live mission has animated unit proxies")
	_assert(int(snapshot.get("unit_visual_loadout_count", 0)) >= animated_count, "Live animated proxies resolve visual loadouts")
	_assert(int(snapshot.get("unit_visual_loadout_error_count", 0)) == 0, "Live visual loadouts have no missing attachment errors")

	await _wait_frames(4)
	_assert(_get_array_property_size(simulation_root, "command_queue") == command_count_before, "Visual loadouts do not enqueue SimulationRoot commands")
	_assert(_get_array_property_size(simulation_root, "effects_queue") == effect_count_before, "Visual loadouts do not enqueue SimulationRoot effects")

	live_scene.queue_free()
	await process_frame


func _build_probe_mapping() -> Dictionary:
	var mapping: Dictionary = _load_json(NPC_VISUAL_MAPPING_PATH).duplicate(true)
	var default_visual: Dictionary = Dictionary(Dictionary(mapping.get("unit_visuals", {})).get("default", {}))
	var unit_entries: Dictionary = Dictionary(mapping.get("unit_ids", {})).duplicate(true)
	var smg_entry: Dictionary = default_visual.duplicate(true)
	smg_entry.erase("visual_loadout_id")
	smg_entry.erase("loadout_id")
	unit_entries["task_175_smg_probe"] = smg_entry
	var medictool_entry: Dictionary = default_visual.duplicate(true)
	unit_entries["task_175_medictool_probe"] = medictool_entry
	var broken_entry: Dictionary = default_visual.duplicate(true)
	broken_entry["visual_loadout_id"] = "broken_blaster"
	unit_entries["task_175_missing_probe"] = broken_entry
	mapping["unit_ids"] = unit_entries
	var loadouts: Dictionary = Dictionary(mapping.get("visual_loadouts", {})).duplicate(true)
	loadouts["broken_blaster"] = {
		"helmet_path": "res://Assets/used/npc/animated_characters/accessories/astroHelmet.fbx",
		"blaster_path": BROKEN_BLASTER_PATH,
	}
	mapping["visual_loadouts"] = loadouts
	return mapping


func _make_unit(unit_id: String, team_id: String, role_id: String, weapon_id: String, position: Vector2, weapon_2_id: String = "rifle") -> Node2D:
	var unit := TEST_UNIT_SCRIPT.new() as Node2D
	unit.unit_id = unit_id
	unit.team_id = team_id
	unit.role_id = role_id
	unit.weapon_1_id = weapon_id
	unit.weapon_2_id = weapon_2_id
	unit.global_position = position
	return unit


func _resolve_visual_attachment_path(mapping: Dictionary, visual_entry: Dictionary, key: String) -> String:
	var direct_path: String = String(visual_entry.get(key, "")).strip_edges()
	if not direct_path.is_empty():
		return direct_path
	var loadout_id: String = String(visual_entry.get("visual_loadout_id", visual_entry.get("loadout_id", ""))).strip_edges().to_lower()
	if loadout_id.is_empty():
		loadout_id = String(Dictionary(mapping.get("defaults", {})).get("visual_loadout_id", "")).strip_edges().to_lower()
	var loadout: Dictionary = Dictionary(Dictionary(mapping.get("visual_loadouts", {})).get(loadout_id, {}))
	return String(loadout.get(key, "")).strip_edges()


func _proxy_has_visual(unit_root: Node, proxy_name: String, visual_prefix: String) -> bool:
	var proxy := unit_root.get_node_or_null(proxy_name) if unit_root != null else null
	return proxy != null and _find_node_with_prefix(proxy, visual_prefix) != null


func _find_node_with_prefix(node: Node, prefix: String) -> Node:
	if String(node.name).begins_with(prefix):
		return node
	for child in node.get_children():
		var found: Node = _find_node_with_prefix(child, prefix)
		if found != null:
			return found
	return null


func _entry_has_combat_fields(entry: Dictionary) -> bool:
	for forbidden_key in ["damage_per_hit", "base_hit_chance", "effective_range", "ticks_between_attacks", "ammo", "reload_time"]:
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
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func _get_array_property_size(node: Node, property_name: String) -> int:
	if node == null:
		return 0
	var value = node.get(property_name)
	return Array(value).size() if value is Array else 0


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _wait_physics_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await physics_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
