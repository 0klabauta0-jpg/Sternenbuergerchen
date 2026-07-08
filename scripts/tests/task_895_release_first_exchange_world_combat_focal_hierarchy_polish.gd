extends SceneTree

const Polish := preload("res://scripts/mission/release_first_exchange_world_combat_focal_hierarchy_polish.gd")

const TASK_PATH := "res://docs/tasks/TASK_895_release_first_exchange_world_combat_focal_hierarchy_polish.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH := "res://docs/reports/spielstand_zwischenbericht_2026_07_09.html"
const SERVICE_PATH := "res://scripts/mission/release_first_exchange_world_combat_focal_hierarchy_polish.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const TERRAIN_VIEW_PATH := "res://scripts/terrain/terrain_map_3d_view.gd"
const META_LAYER_SCENE_PATH := "res://scenes/meta/meta_layer_test.tscn"
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const FIRST_GO_FIREFIGHT_ARG := "--release-singleplayer-first-go-firefight"
const SCHEMA := "sternenbuergerchen.release_first_exchange_world_combat_focal_hierarchy_polish.v1"
const STYLE_ID := "task_895_release_first_exchange_world_combat_focal_hierarchy_v1"
const SOURCE_DIRECTION_STYLE_ID := "task_892_release_first_exchange_fire_direction_impact_clarity_v1"
const NEXT_TASK := "TASK_896 - Release First Exchange World Combat Focal Real Window Recapture"
const DENSITY_MODE := "release_firefight_declutter"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_895 Release First Exchange World Combat Focal Hierarchy Polish ===")
	_test_docs_and_static_hooks()
	_test_helper_snapshot_passes()
	await _test_terrain_focal_hierarchy_parameters()
	await _test_meta_layer_task_895_runtime_snapshot()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_895_release_first_exchange_world_combat_focal_hierarchy_polish: FAILED")
		quit(1)
		return
	print("TASK_895_release_first_exchange_world_combat_focal_hierarchy_polish: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	var terrain_text: String = _read_text(TERRAIN_VIEW_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_895 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_895 helper exists")
	_assert(task_text.contains("Release First Exchange World Combat Focal Hierarchy Polish"), "Task names TASK_895")
	_assert(task_text.contains(NEXT_TASK), "Task names TASK_896 follow-up")
	_assert(status_text.contains("TASK_895 - Release First Exchange World Combat Focal Hierarchy Polish"), "Implementation status tracks TASK_895")
	_assert(roadmap_text.contains("TASK_895 - Release First Exchange World Combat Focal Hierarchy Polish (implementiert)"), "Roadmap marks TASK_895 implemented")
	_assert(roadmap_text.contains(NEXT_TASK), "Roadmap names TASK_896 follow-up")
	_assert(contract_text.contains("Release-First-Exchange-World-Combat-Focal-Hierarchy-Polish (TASK_895)"), "Contract documents TASK_895")
	_assert(report_text.contains("TASK_895") and report_text.contains("TASK_896"), "HTML report tracks TASK_895 and TASK_896")
	_assert(service_text.contains(SCHEMA), "Helper exposes stable TASK_895 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_895\""), "Helper writes TASK_895 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_894\""), "Helper links TASK_894")
	_assert(service_text.contains("SOURCE_DIRECTION_TASK_ID: String = \"TASK_892\""), "Helper links TASK_892")
	_assert(service_text.contains("\"creates_command\": false"), "Helper creates no commands")
	_assert(service_text.contains("\"creates_fire_event\": false"), "Helper creates no fire events")
	_assert(service_text.contains("\"creates_damage_event\": false"), "Helper creates no damage events")
	_assert(service_text.contains("\"creates_movement\": false"), "Helper creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Helper sets no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_EXCHANGE_WORLD_COMBAT_FOCAL_HIERARCHY_POLISH_SCRIPT"), "Controller preloads TASK_895 helper")
	_assert(controller_text.contains("get_release_first_exchange_world_combat_focal_hierarchy_polish_snapshot"), "Controller exposes TASK_895 snapshot")
	_assert(controller_text.contains("release_first_exchange_world_combat_focal_hierarchy"), "Controller sends TASK_895 payload")
	_assert(terrain_text.contains("RELEASE_FIRST_EXCHANGE_WORLD_COMBAT_FOCAL_HIERARCHY_STYLE_ID"), "Terrain declares TASK_895 style")
	_assert(terrain_text.contains("_is_release_first_exchange_world_combat_focal_hierarchy_active"), "Terrain detects TASK_895 payload")
	_assert(terrain_text.contains("WeaponFireWorldCombatFocalLane"), "Terrain renders TASK_895 focal lane")
	_assert(terrain_text.contains("WeaponFireWorldCombatSourceGlow"), "Terrain renders TASK_895 source glow")
	_assert(terrain_text.contains("WeaponFireWorldCombatTargetHalo"), "Terrain renders TASK_895 target halo")


func _test_helper_snapshot_passes() -> void:
	var snapshot: Dictionary = Polish.build_snapshot(_helper_source(), {})
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Helper snapshot schema matches TASK_895")
	_assert(String(snapshot.get("task_id", "")) == "TASK_895", "Helper snapshot task id is TASK_895")
	_assert(String(snapshot.get("style_id", "")) == STYLE_ID, "Helper snapshot style id is stable")
	_assert(String(snapshot.get("source_direction_style_id", "")) == SOURCE_DIRECTION_STYLE_ID, "Helper links TASK_892 style")
	_assert(String(snapshot.get("gate", "")) == "pass", "Helper snapshot passes")
	_assert(bool(snapshot.get("active", false)), "Helper snapshot active")
	_assert(bool(snapshot.get("findings_ready", false)), "Helper accepts TASK_894 ready finding")
	_assert(bool(snapshot.get("direction_ready", false)), "Helper accepts TASK_892 direction path")
	_assert(bool(snapshot.get("world_combat_focal_lane_visible", false)), "Helper sees focal lane")
	_assert(float(snapshot.get("world_combat_focal_lane_width", 0.0)) > 0.095, "Focal lane beats TASK_892 arrow width")
	_assert(bool(snapshot.get("world_combat_focal_target_halo_visible", false)), "Helper sees target halo")
	_assert(float(snapshot.get("world_combat_focal_target_halo_radius", 0.0)) > 0.78, "Target halo beats TASK_892 focus")
	_assert(bool(snapshot.get("world_combat_focal_source_glow_visible", false)), "Helper sees source glow")
	_assert(float(snapshot.get("world_combat_focal_source_glow_radius", 0.0)) > 0.24, "Source glow beats TASK_892 anchor")
	_assert(bool(snapshot.get("world_combat_focal_grid_noise_dimming_active", false)), "Helper sees grid/noise dimming")
	_assert(bool(snapshot.get("world_combat_focal_world_line_dimming_active", false)), "Helper sees world-line dimming")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Helper recommends TASK_896")
	_assert(bool(snapshot.get("read_only", false)), "Helper snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Helper sets no gameplay truth")
	_assert(not bool(snapshot.get("creates_command", true)), "Helper creates no commands")
	_assert(not bool(snapshot.get("creates_fire_event", true)), "Helper creates no fire events")
	_assert(not bool(snapshot.get("creates_damage_event", true)), "Helper creates no damage events")
	_assert(not bool(snapshot.get("creates_movement", true)), "Helper creates no movement")
	_assert(not bool(snapshot.get("sets_multiplayer_truth", true)), "Helper sets no multiplayer truth")


func _test_terrain_focal_hierarchy_parameters() -> void:
	var primary_view: Node = _build_primary_view()
	primary_view.call("set_order_visual_payload", {
		"phase_index": 2,
		"world_label_density_mode": DENSITY_MODE,
		"release_fire_exchange_focused_visual_polish": true,
		"release_first_exchange_fire_visual_polish": true,
		"release_first_exchange_hud_density_fire_visual_polish": true,
		"release_first_exchange_fire_direction_impact_clarity_polish": true,
		"release_first_exchange_world_combat_focal_hierarchy": true,
		"fire_event_dicts": [_build_fire_event()],
	})
	await _wait_frames(10)
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var entries: Array = Array(snapshot.get("weapon_fire_vfx_entries", []))
	var first_entry: Dictionary = Dictionary(entries[0]) if not entries.is_empty() else {}
	_assert(bool(snapshot.get("release_first_exchange_world_combat_focal_hierarchy_active", false)), "Terrain TASK_895 focal hierarchy is active")
	_assert(String(snapshot.get("release_first_exchange_world_combat_focal_hierarchy_style_id", "")) == STYLE_ID, "Terrain reports TASK_895 style")
	_assert(bool(snapshot.get("world_combat_focal_lane_visible", false)), "Terrain reports focal lane")
	_assert(float(snapshot.get("world_combat_focal_lane_width", 0.0)) > 0.095, "Terrain focal lane is strong")
	_assert(bool(snapshot.get("world_combat_focal_target_halo_visible", false)), "Terrain reports target halo")
	_assert(float(snapshot.get("world_combat_focal_target_halo_radius", 0.0)) > 0.78, "Terrain target halo is strong")
	_assert(bool(snapshot.get("world_combat_focal_source_glow_visible", false)), "Terrain reports source glow")
	_assert(float(snapshot.get("world_combat_focal_source_glow_radius", 0.0)) > 0.24, "Terrain source glow is strong")
	_assert(bool(snapshot.get("world_combat_focal_grid_noise_dimming_active", false)), "Terrain reports grid/noise dimming")
	_assert(float(snapshot.get("world_combat_focal_grid_noise_alpha", 1.0)) < 1.0, "Terrain grid/noise alpha is dimmed")
	_assert(bool(snapshot.get("world_combat_focal_world_line_dimming_active", false)), "Terrain reports world-line dimming")
	_assert(bool(first_entry.get("world_combat_focal_hierarchy_active", false)), "Fire VFX entry carries TASK_895 flag")
	_assert(bool(first_entry.get("world_combat_focal_lane_visible", false)), "Fire VFX entry carries focal lane")
	_assert(bool(first_entry.get("world_combat_focal_source_glow_visible", false)), "Fire VFX entry carries source glow")
	_assert(bool(first_entry.get("world_combat_focal_target_halo_visible", false)), "Fire VFX entry carries target halo")
	_assert(_snapshot_is_read_only(snapshot), "Terrain TASK_895 snapshot stays read-only")
	primary_view.queue_free()
	await _wait_frames(2)


func _test_meta_layer_task_895_runtime_snapshot() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := _instantiate_scene(META_LAYER_SCENE_PATH)
	_assert(scene != null, "MetaLayer scene instantiates")
	if scene == null:
		return
	await _wait_frames(10)
	_assert(scene.has_method("_apply_release_first_go_firefight_deeplink"), "MetaLayer exposes first GO/firefight apply hook")
	if not scene.has_method("_apply_release_first_go_firefight_deeplink"):
		scene.queue_free()
		await _wait_frames(1)
		return
	scene.call("_apply_release_first_go_firefight_deeplink", PackedStringArray([FIRST_GO_FIREFIGHT_ARG]))
	await _wait_frames(190)
	var active_mission = scene.call("get_active_mission") if scene.has_method("get_active_mission") else null
	_assert(active_mission != null, "Deep-link keeps active mission alive")
	if active_mission == null:
		scene.queue_free()
		await _wait_frames(1)
		return
	var controller: Node = active_mission.get_node_or_null("TacticalController")
	_assert(controller != null, "Active mission exposes TacticalController")
	if controller == null:
		scene.queue_free()
		await _wait_frames(1)
		return
	_assert(controller.has_method("get_release_first_exchange_world_combat_focal_hierarchy_polish_snapshot"), "Controller exposes TASK_895 runtime snapshot")
	if not controller.has_method("get_release_first_exchange_world_combat_focal_hierarchy_polish_snapshot"):
		scene.queue_free()
		await _wait_frames(1)
		return
	var snapshot: Dictionary = Dictionary(controller.call("get_release_first_exchange_world_combat_focal_hierarchy_polish_snapshot"))
	if String(snapshot.get("gate", "")) != "pass":
		print("TASK_895_DIAGNOSTIC %s" % JSON.stringify({
			"failed_checks": snapshot.get("failed_checks", []),
			"lane": snapshot.get("world_combat_focal_lane_visible", false),
			"lane_width": snapshot.get("world_combat_focal_lane_width", 0.0),
			"source_glow": snapshot.get("world_combat_focal_source_glow_visible", false),
			"target_halo": snapshot.get("world_combat_focal_target_halo_visible", false),
			"entries": snapshot.get("weapon_fire_vfx_entries", []),
		}))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Runtime snapshot schema is stable")
	_assert(String(snapshot.get("task_id", "")) == "TASK_895", "Runtime snapshot task id is TASK_895")
	_assert(String(snapshot.get("style_id", "")) == STYLE_ID, "Runtime snapshot style id is TASK_895")
	_assert(String(snapshot.get("gate", "")) == "pass", "TASK_895 runtime snapshot passes")
	_assert(bool(snapshot.get("active", false)), "TASK_895 runtime polish is active")
	_assert(bool(snapshot.get("world_combat_focal_lane_visible", false)), "Runtime focal lane visible")
	_assert(float(snapshot.get("world_combat_focal_lane_width", 0.0)) > 0.095, "Runtime focal lane is strong")
	_assert(bool(snapshot.get("world_combat_focal_target_halo_visible", false)), "Runtime target halo visible")
	_assert(bool(snapshot.get("world_combat_focal_source_glow_visible", false)), "Runtime source glow visible")
	_assert(bool(snapshot.get("world_combat_focal_grid_noise_dimming_active", false)), "Runtime grid/noise dimming active")
	_assert(bool(snapshot.get("world_combat_focal_world_line_dimming_active", false)), "Runtime world-line dimming active")
	_assert(bool(snapshot.get("read_only", false)), "Runtime snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Runtime snapshot sets no gameplay truth")
	_assert(not bool(snapshot.get("creates_command", true)), "Runtime snapshot creates no commands")
	_assert(not bool(snapshot.get("creates_fire_event", true)), "Runtime snapshot creates no fire events")
	_assert(not bool(snapshot.get("creates_damage_event", true)), "Runtime snapshot creates no damage events")
	_assert(not bool(snapshot.get("creates_movement", true)), "Runtime snapshot creates no movement")
	_assert(not bool(snapshot.get("sets_multiplayer_truth", true)), "Runtime snapshot sets no multiplayer truth")
	scene.queue_free()
	await _wait_frames(2)


func _helper_source() -> Dictionary:
	return {
		"findings": {
			"task_id": "TASK_894",
			"status": "ready_for_world_combat_focal_polish",
			"read_only": true,
		},
		"direction": {
			"task_id": "TASK_892",
			"style_id": SOURCE_DIRECTION_STYLE_ID,
			"active": true,
			"read_only": true,
		},
		"primary_render_snapshot": {
			"release_first_exchange_world_combat_focal_hierarchy_active": true,
			"release_first_exchange_world_combat_focal_hierarchy_style_id": STYLE_ID,
			"world_combat_focal_lane_visible": true,
			"world_combat_focal_lane_width": 0.135,
			"world_combat_focal_target_halo_visible": true,
			"world_combat_focal_target_halo_radius": 0.98,
			"world_combat_focal_source_glow_visible": true,
			"world_combat_focal_source_glow_radius": 0.34,
			"world_combat_focal_grid_noise_dimming_active": true,
			"world_combat_focal_grid_noise_alpha": 0.42,
			"world_combat_focal_world_line_dimming_active": true,
			"world_combat_focal_world_line_alpha_factor": 0.26,
			"weapon_fire_vfx_visual_count": 1,
			"weapon_fire_vfx_entries": [
				{
					"world_combat_focal_hierarchy_active": true,
					"world_combat_focal_hierarchy_style_id": STYLE_ID,
					"world_combat_focal_lane_visible": true,
					"world_combat_focal_lane_width": 0.135,
					"world_combat_focal_target_halo_visible": true,
					"world_combat_focal_target_halo_radius": 0.98,
					"world_combat_focal_source_glow_visible": true,
					"world_combat_focal_source_glow_radius": 0.34,
				}
			],
		},
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
	}


func _build_primary_view() -> Node:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_895_world_combat_focal", Vector2i(8, 8), Vector2.ZERO, 64.0, 32.0, 3)
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	return primary_view


func _build_fire_event() -> Dictionary:
	return {
		"event_id": "task_895_fire_001",
		"attacker_unit_id": "alpha_1",
		"target_unit_id": "enemy_1",
		"weapon_id": "rifle",
		"attacker_position": Vector2(96.0, 96.0),
		"target_position": Vector2(256.0, 192.0),
		"combat_outcome": "hit",
		"damage_resolved": 1,
		"hit_chance_resolved": 0.72,
		"source": "task_895_test_fixture",
	}


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return not bool(snapshot.get("ui_sets_gameplay_truth", false)) \
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
