extends SceneTree

const TASK_PATH := "res://docs/tasks/TASK_839_release_firefight_world_label_declutter.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const TERRAIN_VIEW_PATH := "res://scripts/terrain/terrain_map_3d_view.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const META_LAYER_PATH := "res://scripts/meta/meta_layer_flow.gd"
const META_LAYER_SCENE_PATH := "res://scenes/meta/meta_layer_test.tscn"
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const FIRST_GO_FIREFIGHT_ARG := "--release-singleplayer-first-go-firefight"
const STYLE_ID := "task_839_release_firefight_world_label_declutter_v1"
const DENSITY_MODE := "release_firefight_declutter"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_839 Release Firefight World Label Declutter ===")
	_test_docs_and_static_hooks()
	await _test_primary3d_declutters_redundant_world_labels()
	await _test_release_firefight_declutter_snapshot()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_839_release_firefight_world_label_declutter: FAILED")
		quit(1)
		return
	print("TASK_839_release_firefight_world_label_declutter: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var terrain_text: String = _read_text(TERRAIN_VIEW_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	var meta_text: String = _read_text(META_LAYER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_839 task file exists")
	_assert(task_text.contains("Release Firefight World Label Declutter"), "Task names world-label declutter")
	_assert(status_text.contains("TASK_839 - Release Firefight World Label Declutter"), "Implementation status tracks TASK_839")
	_assert(roadmap_text.contains("TASK_839 - Release Firefight World Label Declutter (implementiert)"), "Roadmap marks TASK_839 implemented")
	_assert(contract_text.contains("Release-Firefight-World-Label-Declutter"), "Contract documents TASK_839")
	_assert(terrain_text.contains("WORLD_LABEL_DENSITY_MODE_RELEASE_FIREFIGHT_DECLUTTER"), "TerrainMap3DView declares density mode")
	_assert(terrain_text.contains("_should_suppress_release_firefight_world_bubble"), "TerrainMap3DView suppresses redundant world bubbles")
	_assert(terrain_text.contains("_should_suppress_release_firefight_fire_status_label"), "TerrainMap3DView suppresses redundant fire labels")
	_assert(controller_text.contains("get_release_firefight_world_label_declutter_snapshot"), "TacticalController exposes TASK_839 snapshot")
	_assert(meta_text.contains("get_release_firefight_world_label_declutter_snapshot"), "MetaLayer exposes TASK_839 snapshot")


func _test_primary3d_declutters_redundant_world_labels() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_839_declutter", Vector2i(6, 6), Vector2.ZERO, 64.0, 32.0, 3)
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	primary_view.call("set_order_visual_payload", {
		"phase_index": 1,
		"world_label_density_mode": DENSITY_MODE,
		"fire_event_dicts": [
			_build_fire_event("fire_hit", false, "hit", Vector2(96.0, 96.0), Vector2(160.0, 96.0)),
			_build_fire_event("fire_ff", true, "hit", Vector2(96.0, 128.0), Vector2(160.0, 128.0)),
		],
		"feedback_bubble_dicts": [
			_build_world_bubble("world_bubble", "Hold angle"),
			_build_hud_bubble("hud_bubble", "GO"),
		],
	})
	await _wait_frames(10)

	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var fire_entries: Array = Array(snapshot.get("weapon_fire_vfx_entries", []))
	_assert(String(snapshot.get("world_label_density_mode", "")) == DENSITY_MODE, "Primary3D reports declutter density mode")
	_assert(bool(snapshot.get("world_label_declutter_active", false)), "Primary3D reports declutter active")
	_assert(String(snapshot.get("world_label_declutter_style_id", "")) == STYLE_ID, "Primary3D reports TASK_839 style id")
	_assert(int(snapshot.get("world_label_declutter_suppressed_count", 0)) >= 2, "Primary3D suppresses redundant fire/world labels")
	_assert(int(snapshot.get("world_label_declutter_rendered_count", 0)) >= 1, "Primary3D preserves critical rendered label path")
	_assert(int(snapshot.get("feedback_bubble_visual_count", 0)) == 1, "World bubble is suppressed while HUD bubble remains")
	_assert(_has_fire_entry_with_flag(fire_entries, "fire_hit", "fire_status_label_suppressed_by_declutter"), "Normal HIT label is suppressed")
	_assert(_has_fire_entry_without_flag(fire_entries, "fire_ff", "fire_status_label_suppressed_by_declutter"), "Friendly-fire status label is not suppressed")
	_assert(_snapshot_is_read_only(snapshot), "Primary3D declutter snapshot stays read-only")

	primary_view.queue_free()
	await _wait_frames(2)


func _test_release_firefight_declutter_snapshot() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := _instantiate_scene(META_LAYER_SCENE_PATH)
	_assert(scene != null, "MetaLayer scene instantiates")
	if scene == null:
		return
	await _wait_frames(10)
	_assert(scene.has_method("_apply_release_first_go_firefight_deeplink"), "MetaLayer exposes first GO/firefight deep-link hook")
	_assert(scene.has_method("get_release_firefight_world_label_declutter_snapshot"), "MetaLayer exposes TASK_839 callable")
	if not scene.has_method("_apply_release_first_go_firefight_deeplink") or not scene.has_method("get_release_firefight_world_label_declutter_snapshot"):
		scene.queue_free()
		await _wait_frames(2)
		return

	scene.call("_apply_release_first_go_firefight_deeplink", PackedStringArray([FIRST_GO_FIREFIGHT_ARG]))
	await _wait_frames(130)

	var snapshot: Dictionary = Dictionary(scene.call("get_release_firefight_world_label_declutter_snapshot", {}, {}, {}))
	var tactical: Dictionary = Dictionary(snapshot.get("tactical_declutter", {}))
	if String(snapshot.get("status", "")) != "pass" or String(tactical.get("gate", "")) != "pass":
		print("TASK_839 snapshot issues: %s" % [str(snapshot.get("issues", []))])
		print("TASK_839 tactical failed checks: %s" % [str(tactical.get("failed_checks", []))])
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.release_firefight_world_label_declutter.v1", "Meta TASK_839 schema is stable")
	_assert(String(snapshot.get("task_id", "")) == "TASK_839", "Meta TASK_839 id is stable")
	_assert(String(snapshot.get("status", "")) == "pass", "Meta TASK_839 gate passes")
	_assert(String(tactical.get("gate", "")) == "pass", "Tactical TASK_839 gate passes")
	_assert(String(tactical.get("style_id", "")) == STYLE_ID, "Tactical snapshot reports TASK_839 style id")
	_assert(String(tactical.get("density_mode", "")) == DENSITY_MODE, "Tactical snapshot reports declutter density mode")
	_assert(int(tactical.get("suppressed_count", 0)) > 0, "Tactical snapshot records suppressed labels")
	_assert(_snapshot_is_read_only(snapshot), "Meta TASK_839 snapshot is read-only")
	_assert(_snapshot_is_read_only(tactical), "Tactical TASK_839 snapshot is read-only")

	scene.queue_free()
	await _wait_frames(2)


func _build_fire_event(event_id: String, friendly_fire: bool, outcome: String, attacker_position: Vector2, target_position: Vector2) -> Dictionary:
	return {
		"event_id": event_id,
		"attacker_unit_id": "alpha_1",
		"target_unit_id": "enemy_1",
		"weapon_id": "rifle",
		"combat_outcome": outcome,
		"damage_resolved": 10 if outcome == "hit" else 0,
		"hit_chance_resolved": 0.65,
		"attacker_position": attacker_position,
		"target_position": target_position,
		"is_friendly_fire": friendly_fire,
	}


func _build_world_bubble(bubble_id: String, text: String) -> Dictionary:
	return {
		"display_type": "comic_bubble",
		"bubble_id": bubble_id,
		"text": text,
		"anchor_position": Vector2(128.0, 128.0),
		"anchor_space": "world",
		"visual_only": true,
		"source": "fireteamleader_command_feedback",
		"purpose": "command_feedback",
		"category": "ftl_command_feedback",
		"fireteam_id": "ft1",
		"unit_id": "alpha_1",
	}


func _build_hud_bubble(bubble_id: String, text: String) -> Dictionary:
	var bubble: Dictionary = _build_world_bubble(bubble_id, text)
	bubble["anchor_space"] = "hud"
	bubble["hud_anchor_source"] = "fireteam_mini_card"
	bubble["hud_anchor_position"] = Vector2(280.0, 180.0)
	bubble["max_size"] = Vector2i(148, 52)
	return bubble


func _has_fire_entry_with_flag(entries: Array, event_id: String, flag: String) -> bool:
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("event_id", "")) == event_id and bool(entry.get(flag, false)):
			return true
	return false


func _has_fire_entry_without_flag(entries: Array, event_id: String, flag: String) -> bool:
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("event_id", "")) == event_id and not bool(entry.get(flag, true)):
			return true
	return false


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return not bool(snapshot.get("ui_sets_gameplay_truth", false)) \
		and not bool(snapshot.get("creates_navigation", false)) \
		and not bool(snapshot.get("creates_command", false)) \
		and not bool(snapshot.get("creates_fire_event", false)) \
		and not bool(snapshot.get("creates_damage_event", false)) \
		and not bool(snapshot.get("sets_multiplayer_truth", false))


func _instantiate_scene(path: String) -> Node:
	var packed_scene := ResourceLoader.load(path) as PackedScene
	if packed_scene == null:
		return null
	var node := packed_scene.instantiate()
	root.add_child(node)
	return node


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] %s" % message)
	else:
		_failed += 1
		push_error("[FAIL] %s" % message)
