extends SceneTree

const NPC_VISUAL_MAPPING_PATH: String = "res://data/npc_unit_visual_mapping.json"
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const ENEMY_TEAM_TACTICS_PROFILE_SCRIPT: GDScript = preload("res://scripts/tactical/enemy_team_tactics_profile.gd")

const FRIENDLY_ARCHETYPE_ID: String = "friendly_space_suit_white"
const ENEMY_ARCHETYPE_ID: String = "enemy_space_suit_orange"
const ASTRO_MALE_A_SKIN: String = "res://Assets/used/npc/animated_characters/skins/astroMaleA.png"
const ASTRO_FEMALE_B_SKIN: String = "res://Assets/used/npc/animated_characters/skins/astroFemaleB.png"
const ASTRO_MALE_B_SKIN: String = "res://Assets/used/npc/animated_characters/skins/astroMaleB.png"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_206 Enemy Visual Faction Archetypes Orange Suit Verifier ===")
	_test_mapping_archetype_contract()
	_test_enemy_tactics_profiles_reference_stable_archetype()
	await _test_runtime_friendly_enemy_archetype_resolution()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_mapping_archetype_contract() -> void:
	var mapping: Dictionary = _load_json(NPC_VISUAL_MAPPING_PATH)
	_assert(not mapping.is_empty(), "NPC visual mapping is loadable")
	_assert(not _contains_local_path(mapping), "NPC visual mapping contains only project-local runtime paths")

	var defaults: Dictionary = Dictionary(mapping.get("defaults", {}))
	_assert(String(defaults.get("friendly_visual_archetype_id", "")) == FRIENDLY_ARCHETYPE_ID, "Defaults declare the friendly white archetype")
	_assert(String(defaults.get("enemy_visual_archetype_id", "")) == ENEMY_ARCHETYPE_ID, "Defaults declare the orange enemy archetype")

	var visual_entries: Dictionary = Dictionary(mapping.get("unit_visuals", {}))
	var friendly_default: Dictionary = Dictionary(visual_entries.get("team_alpha", {}))
	var enemy_default: Dictionary = Dictionary(visual_entries.get("team_bravo", {}))
	_assert(String(friendly_default.get("visual_archetype_id", "")) == FRIENDLY_ARCHETYPE_ID, "Team alpha uses the white friendly archetype")
	_assert(String(enemy_default.get("visual_archetype_id", "")) == ENEMY_ARCHETYPE_ID, "Team bravo uses the orange enemy archetype")
	_assert(String(friendly_default.get("skin_path", "")) != String(enemy_default.get("skin_path", "")), "Friendly and enemy defaults use different skins")
	_assert(String(enemy_default.get("skin_path", "")) == ASTRO_FEMALE_B_SKIN, "Enemy default uses the orange B skin")

	var unit_entries: Dictionary = Dictionary(mapping.get("unit_ids", {}))
	for enemy_id in ["enemy_delta", "enemy_echo"]:
		var enemy_entry: Dictionary = Dictionary(unit_entries.get(enemy_id, {}))
		_assert(String(enemy_entry.get("visual_archetype_id", "")) == ENEMY_ARCHETYPE_ID, "%s maps to the orange enemy archetype" % enemy_id)
		_assert(String(enemy_entry.get("skin_path", "")).ends_with("B.png"), "%s uses an orange B skin" % enemy_id)

	var archetypes: Dictionary = Dictionary(mapping.get("visual_archetypes", {}))
	_assert(archetypes.has(FRIENDLY_ARCHETYPE_ID), "Friendly archetype exists")
	_assert(archetypes.has(ENEMY_ARCHETYPE_ID), "Enemy orange archetype exists")
	for archetype_id in [FRIENDLY_ARCHETYPE_ID, ENEMY_ARCHETYPE_ID]:
		var archetype: Dictionary = Dictionary(archetypes.get(archetype_id, {}))
		_assert(ResourceLoader.exists(String(archetype.get("model_path", ""))), "%s model is loadable" % archetype_id)
		_assert(ResourceLoader.exists(String(archetype.get("skin_path", ""))), "%s skin is loadable" % archetype_id)
		_assert(float(archetype.get("scale", 0.0)) >= 0.20 and float(archetype.get("scale", 0.0)) <= 0.23, "%s scale stays within NPC bounds" % archetype_id)
		var sockets: Dictionary = Dictionary(archetype.get("socket_compatibility", {}))
		_assert(String(sockets.get("helmet_socket", "")) == "HeadSocket", "%s keeps HeadSocket helmet compatibility" % archetype_id)
		_assert(Array(sockets.get("weapon_sockets", [])).has("RightHandSocket"), "%s keeps hand weapon socket compatibility" % archetype_id)

	_assert(ResourceLoader.exists(ASTRO_FEMALE_B_SKIN), "Orange female B skin is imported and loadable")
	_assert(ResourceLoader.exists(ASTRO_MALE_B_SKIN), "Orange male B skin is imported and loadable")
	_assert(ResourceLoader.exists(ASTRO_MALE_A_SKIN), "White friendly A skin remains loadable")

	for planned_id in ["enemy_robot", "enemy_alien", "enemy_zombie", "enemy_soldier"]:
		var planned: Dictionary = Dictionary(archetypes.get(planned_id, {}))
		_assert(String(planned.get("status", "")) == "planned", "%s is prepared as a planned archetype" % planned_id)
		_assert(String(planned.get("fallback_archetype_id", "")) == ENEMY_ARCHETYPE_ID, "%s falls back to the orange enemy archetype" % planned_id)


func _test_enemy_tactics_profiles_reference_stable_archetype() -> void:
	var profile_ids: PackedStringArray = ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("get_profile_ids")
	for profile_id in profile_ids:
		var profile: Dictionary = Dictionary(ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("get_profile", profile_id))
		_assert(String(profile.get("visual_archetype", "")) == ENEMY_ARCHETYPE_ID, "%s references the stable orange archetype" % profile_id)


func _test_runtime_friendly_enemy_archetype_resolution() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_206_enemy_visuals", Vector2i(4, 2), Vector2.ZERO)
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)

	var friendly := _make_unit("task_206_friendly", "team_alpha", Vector2(0.0, 0.0))
	var enemy := _make_unit("task_206_enemy", "team_bravo", Vector2(64.0, 32.0))
	var planned_enemy := _make_unit("task_206_robot_fallback", "team_bravo", Vector2(128.0, 64.0))
	planned_enemy.set_meta("enemy_visual_archetype_id", "enemy_robot")
	root.add_child(friendly)
	root.add_child(enemy)
	root.add_child(planned_enemy)

	primary_view.call("set_unit_nodes", [friendly, enemy, planned_enemy])
	await _wait_frames(12)

	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(snapshot.get("unit_visual_error_count", 0)) == 0, "Runtime archetype visuals have no missing-asset errors")
	_assert(int(snapshot.get("unit_helmet_attachment_count", 0)) >= 3, "Runtime archetype visuals keep helmet attachments")
	_assert(int(snapshot.get("unit_blaster_attachment_count", 0)) >= 3, "Runtime archetype visuals keep weapon attachments")

	var states: Dictionary = Dictionary(snapshot.get("unit_proxy_state_by_id", {}))
	_assert(String(Dictionary(states.get("task_206_friendly", {})).get("unit_visual_archetype_id", "")) == FRIENDLY_ARCHETYPE_ID, "Runtime friendly proxy resolves the white archetype")
	_assert(String(Dictionary(states.get("task_206_enemy", {})).get("unit_visual_archetype_id", "")) == ENEMY_ARCHETYPE_ID, "Runtime enemy proxy resolves the orange archetype")
	_assert(String(Dictionary(states.get("task_206_robot_fallback", {})).get("unit_visual_archetype_id", "")) == ENEMY_ARCHETYPE_ID, "Planned enemy archetype falls back to orange at runtime")
	_assert(String(Dictionary(states.get("task_206_friendly", {})).get("unit_visual_faction_id", "")) == "friendly", "Runtime friendly proxy keeps faction metadata")
	_assert(String(Dictionary(states.get("task_206_enemy", {})).get("unit_visual_faction_id", "")) == "enemy", "Runtime enemy proxy keeps faction metadata")

	primary_view.queue_free()
	friendly.queue_free()
	enemy.queue_free()
	planned_enemy.queue_free()
	await process_frame


func _make_unit(unit_id: String, team_id: String, position: Vector2) -> Node2D:
	var unit := TEST_UNIT_SCRIPT.new() as Node2D
	unit.unit_id = unit_id
	unit.team_id = team_id
	unit.weapon_1_id = "rifle"
	unit.weapon_2_id = "rifle"
	unit.global_position = position
	return unit


func _contains_local_path(value: Variant) -> bool:
	if typeof(value) == TYPE_DICTIONARY:
		for nested_value in Dictionary(value).values():
			if _contains_local_path(nested_value):
				return true
	elif typeof(value) == TYPE_ARRAY:
		for nested_value in Array(value):
			if _contains_local_path(nested_value):
				return true
	elif typeof(value) == TYPE_STRING:
		var text: String = String(value)
		return text.find("C:\\") >= 0 or text.find("C:/") >= 0 or text.find("\\Users\\") >= 0
	return false


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
