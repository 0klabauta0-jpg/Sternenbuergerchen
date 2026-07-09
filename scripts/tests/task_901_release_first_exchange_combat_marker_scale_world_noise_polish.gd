extends SceneTree

const Polish := preload("res://scripts/mission/release_first_exchange_combat_marker_scale_world_noise_polish.gd")

const TASK_PATH := "res://docs/tasks/TASK_901_release_first_exchange_combat_marker_scale_world_noise_polish.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH := "res://docs/reports/spielstand_zwischenbericht_2026_07_09_aktuell.html"
const SERVICE_PATH := "res://scripts/mission/release_first_exchange_combat_marker_scale_world_noise_polish.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const TERRAIN_VIEW_PATH := "res://scripts/terrain/terrain_map_3d_view.gd"
const META_LAYER_SCENE_PATH := "res://scenes/meta/meta_layer_test.tscn"
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const FIRST_GO_FIREFIGHT_ARG := "--release-singleplayer-first-go-firefight"
const SCHEMA := "sternenbuergerchen.release_first_exchange_combat_marker_scale_world_noise_polish.v1"
const STYLE_ID := "task_901_release_first_exchange_combat_marker_scale_world_noise_v1"
const ELEGANCE_SCHEMA := "sternenbuergerchen.release_first_exchange_combat_focal_elegance_polish.v1"
const ELEGANCE_STYLE_ID := "task_898_release_first_exchange_combat_focal_elegance_v1"
const NEXT_TASK := "TASK_902 - Release First Exchange Combat Marker Scale Real Window Recapture"
const DENSITY_MODE := "release_firefight_declutter"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_901 Release First Exchange Combat Marker Scale And World Noise Polish ===")
	_test_docs_and_static_hooks()
	_test_helper_snapshot_passes()
	await _test_terrain_marker_scale_parameters()
	await _test_meta_layer_task_901_runtime_snapshot()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_901_release_first_exchange_combat_marker_scale_world_noise_polish: FAILED")
		quit(1)
		return
	print("TASK_901_release_first_exchange_combat_marker_scale_world_noise_polish: ALL PASSED")
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
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_901 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_901 helper exists")
	_assert(task_text.contains("Release First Exchange Combat Marker Scale And World Noise Polish"), "Task names TASK_901")
	_assert(task_text.contains(NEXT_TASK), "Task names TASK_902 follow-up")
	_assert(status_text.contains("TASK_901 - Release First Exchange Combat Marker Scale And World Noise Polish"), "Implementation status tracks TASK_901")
	_assert(roadmap_text.contains("TASK_901 - Release First Exchange Combat Marker Scale And World Noise Polish (implementiert)"), "Roadmap marks TASK_901 implemented")
	_assert(roadmap_text.contains(NEXT_TASK), "Roadmap names TASK_902 follow-up")
	_assert(contract_text.contains("Release-First-Exchange-Combat-Marker-Scale-World-Noise-Polish (TASK_901)"), "Contract documents TASK_901")
	_assert(report_text.contains("TASK_901") and report_text.contains("TASK_902"), "HTML report tracks TASK_901 and TASK_902")
	_assert(service_text.contains(SCHEMA), "Helper exposes stable TASK_901 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_901\""), "Helper writes TASK_901 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_900\""), "Helper links TASK_900")
	_assert(service_text.contains("SOURCE_ELEGANCE_TASK_ID: String = \"TASK_898\""), "Helper links TASK_898")
	_assert(service_text.contains("\"creates_command\": false"), "Helper creates no commands")
	_assert(service_text.contains("\"creates_fire_event\": false"), "Helper creates no fire events")
	_assert(service_text.contains("\"creates_damage_event\": false"), "Helper creates no damage events")
	_assert(service_text.contains("\"creates_movement\": false"), "Helper creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Helper sets no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_EXCHANGE_COMBAT_MARKER_SCALE_WORLD_NOISE_POLISH_SCRIPT"), "Controller preloads TASK_901 helper")
	_assert(controller_text.contains("get_release_first_exchange_combat_marker_scale_world_noise_polish_snapshot"), "Controller exposes TASK_901 snapshot")
	_assert(controller_text.contains("release_first_exchange_combat_marker_scale_world_noise_polish"), "Controller sends TASK_901 payload")
	_assert(terrain_text.contains("RELEASE_FIRST_EXCHANGE_COMBAT_MARKER_SCALE_WORLD_NOISE_STYLE_ID"), "Terrain declares TASK_901 style")
	_assert(terrain_text.contains("_is_release_first_exchange_combat_marker_scale_world_noise_active"), "Terrain detects TASK_901 payload")
	_assert(terrain_text.contains("WeaponFireWorldCombatMarkerScaleLane"), "Terrain renders TASK_901 lane")
	_assert(terrain_text.contains("WeaponFireWorldCombatMarkerScaleSourceGlow"), "Terrain renders TASK_901 source glow")
	_assert(terrain_text.contains("WeaponFireWorldCombatMarkerScaleTargetHalo"), "Terrain renders TASK_901 target halo")


func _test_helper_snapshot_passes() -> void:
	var snapshot: Dictionary = Polish.build_snapshot(_helper_source(), {})
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Helper snapshot schema matches TASK_901")
	_assert(String(snapshot.get("task_id", "")) == "TASK_901", "Helper snapshot task id is TASK_901")
	_assert(String(snapshot.get("style_id", "")) == STYLE_ID, "Helper snapshot style id is stable")
	_assert(String(snapshot.get("source_elegance_schema", "")) == ELEGANCE_SCHEMA, "Helper links TASK_898 schema")
	_assert(String(snapshot.get("source_elegance_style_id", "")) == ELEGANCE_STYLE_ID, "Helper links TASK_898 style")
	_assert(String(snapshot.get("gate", "")) == "pass", "Helper snapshot passes")
	_assert(bool(snapshot.get("active", false)), "Helper snapshot active")
	_assert(bool(snapshot.get("findings_ready", false)), "Helper accepts TASK_900 ready finding")
	_assert(bool(snapshot.get("elegance_ready", false)), "Helper accepts TASK_898 elegance path")
	_assert(bool(snapshot.get("world_combat_marker_scale_lane_visible", false)), "Helper sees marker-scale lane")
	_assert(float(snapshot.get("world_combat_marker_scale_lane_width", 0.0)) < 0.082, "Marker-scale lane is narrower than TASK_898")
	_assert(float(snapshot.get("world_combat_marker_scale_lane_alpha", 0.0)) >= 0.58, "Marker-scale lane stays readable")
	_assert(bool(snapshot.get("world_combat_marker_scale_target_halo_visible", false)), "Helper sees smaller target halo")
	_assert(float(snapshot.get("world_combat_marker_scale_target_halo_radius", 1.0)) < 0.64, "Target halo is smaller than TASK_898")
	_assert(float(snapshot.get("world_combat_marker_scale_target_halo_alpha", 1.0)) < 0.24, "Target halo alpha is quieter than TASK_898")
	_assert(float(snapshot.get("world_combat_marker_scale_target_focus_radius", 1.0)) < 0.72, "Target focus is smaller than TASK_898")
	_assert(bool(snapshot.get("world_combat_marker_scale_source_glow_visible", false)), "Helper sees quieter source glow")
	_assert(float(snapshot.get("world_combat_marker_scale_source_glow_radius", 1.0)) < 0.23, "Source glow is smaller than TASK_898")
	_assert(float(snapshot.get("world_combat_marker_scale_source_glow_alpha", 1.0)) < 0.36, "Source glow alpha is quieter than TASK_898")
	_assert(float(snapshot.get("world_combat_marker_scale_grid_noise_alpha", 1.0)) < 0.42, "Grid noise alpha is quieter than TASK_895")
	_assert(float(snapshot.get("world_combat_marker_scale_world_line_alpha_factor", 1.0)) < 0.34, "World-line alpha is quieter than TASK_898")
	_assert(float(snapshot.get("world_combat_marker_scale_world_line_width_factor", 1.0)) < 0.42, "World-line width is quieter than TASK_898")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Helper recommends TASK_902")
	_assert(bool(snapshot.get("read_only", false)), "Helper snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Helper sets no gameplay truth")
	_assert(not bool(snapshot.get("creates_command", true)), "Helper creates no commands")
	_assert(not bool(snapshot.get("creates_fire_event", true)), "Helper creates no fire events")
	_assert(not bool(snapshot.get("creates_damage_event", true)), "Helper creates no damage events")
	_assert(not bool(snapshot.get("creates_movement", true)), "Helper creates no movement")
	_assert(not bool(snapshot.get("sets_multiplayer_truth", true)), "Helper sets no multiplayer truth")


func _test_terrain_marker_scale_parameters() -> void:
	var primary_view: Node = _build_primary_view()
	primary_view.call("set_order_visual_payload", {
		"phase_index": 2,
		"world_label_density_mode": DENSITY_MODE,
		"release_fire_exchange_focused_visual_polish": true,
		"release_first_exchange_fire_visual_polish": true,
		"release_first_exchange_hud_density_fire_visual_polish": true,
		"release_first_exchange_fire_direction_impact_clarity_polish": true,
		"release_first_exchange_world_combat_focal_hierarchy": true,
		"release_first_exchange_combat_focal_elegance_polish": true,
		"release_first_exchange_combat_marker_scale_world_noise_polish": true,
		"fire_event_dicts": [_build_fire_event()],
	})
	await _wait_frames(10)
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var entries: Array = Array(snapshot.get("weapon_fire_vfx_entries", []))
	var first_entry: Dictionary = Dictionary(entries[0]) if not entries.is_empty() else {}
	_assert(bool(snapshot.get("release_first_exchange_combat_focal_elegance_polish_active", false)), "Terrain keeps TASK_898 focal elegance active")
	_assert(bool(snapshot.get("release_first_exchange_combat_marker_scale_world_noise_polish_active", false)), "Terrain TASK_901 marker/world-noise polish is active")
	_assert(String(snapshot.get("release_first_exchange_combat_marker_scale_world_noise_polish_style_id", "")) == STYLE_ID, "Terrain reports TASK_901 style")
	_assert(bool(snapshot.get("world_combat_marker_scale_lane_visible", false)), "Terrain reports marker-scale lane")
	_assert(float(snapshot.get("world_combat_marker_scale_lane_width", 1.0)) < float(snapshot.get("world_combat_focal_elegance_lane_width", 0.0)), "Terrain marker-scale lane is narrower than TASK_898")
	_assert(bool(snapshot.get("world_combat_marker_scale_target_halo_visible", false)), "Terrain reports marker-scale target halo")
	_assert(float(snapshot.get("world_combat_marker_scale_target_halo_radius", 1.0)) < float(snapshot.get("world_combat_focal_elegance_target_halo_radius", 0.0)), "Terrain marker-scale halo is smaller than TASK_898 halo")
	_assert(float(snapshot.get("world_combat_marker_scale_target_halo_alpha", 1.0)) < float(snapshot.get("world_combat_focal_elegance_target_halo_alpha", 0.0)), "Terrain marker-scale halo alpha is quieter")
	_assert(float(snapshot.get("world_combat_marker_scale_target_focus_radius", 1.0)) < 0.72, "Terrain marker-scale target focus is smaller")
	_assert(bool(snapshot.get("world_combat_marker_scale_source_glow_visible", false)), "Terrain reports marker-scale source glow")
	_assert(float(snapshot.get("world_combat_marker_scale_source_glow_radius", 1.0)) < float(snapshot.get("world_combat_focal_elegance_source_glow_radius", 0.0)), "Terrain marker-scale source glow is smaller")
	_assert(float(snapshot.get("world_combat_marker_scale_grid_noise_alpha", 1.0)) < float(snapshot.get("world_combat_focal_grid_noise_alpha", 1.0)), "Terrain marker-scale grid alpha is quieter than TASK_895")
	_assert(float(snapshot.get("tile_grid_line_effective_alpha", 1.0)) <= float(snapshot.get("world_combat_marker_scale_grid_noise_alpha", 1.0)) + 0.001, "Terrain grid material alpha follows TASK_901 dimming")
	_assert(float(snapshot.get("world_combat_marker_scale_world_line_alpha_factor", 1.0)) < float(snapshot.get("world_combat_focal_elegance_world_line_alpha_factor", 0.34)), "Terrain world-line alpha factor is quieter than TASK_898")
	_assert(bool(first_entry.get("combat_marker_scale_world_noise_polish_active", false)), "Fire VFX entry carries TASK_901 flag")
	_assert(bool(first_entry.get("world_combat_marker_scale_lane_visible", false)), "Fire VFX entry carries marker-scale lane")
	_assert(bool(first_entry.get("world_combat_marker_scale_source_glow_visible", false)), "Fire VFX entry carries marker-scale source glow")
	_assert(bool(first_entry.get("world_combat_marker_scale_target_halo_visible", false)), "Fire VFX entry carries marker-scale target halo")
	_assert(float(first_entry.get("target_focus_radius", 1.0)) < 0.72, "Fire VFX entry effective target focus is smaller")
	_assert(_snapshot_is_read_only(snapshot), "Terrain TASK_901 snapshot stays read-only")
	primary_view.queue_free()
	await _wait_frames(2)


func _test_meta_layer_task_901_runtime_snapshot() -> void:
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
	_assert(controller.has_method("get_release_first_exchange_combat_marker_scale_world_noise_polish_snapshot"), "Controller exposes TASK_901 runtime snapshot")
	if not controller.has_method("get_release_first_exchange_combat_marker_scale_world_noise_polish_snapshot"):
		scene.queue_free()
		await _wait_frames(1)
		return
	var snapshot: Dictionary = Dictionary(controller.call("get_release_first_exchange_combat_marker_scale_world_noise_polish_snapshot"))
	if String(snapshot.get("gate", "")) != "pass":
		print("TASK_901_DIAGNOSTIC %s" % JSON.stringify({
			"failed_checks": snapshot.get("failed_checks", []),
			"lane": snapshot.get("world_combat_marker_scale_lane_visible", false),
			"halo_radius": snapshot.get("world_combat_marker_scale_target_halo_radius", 0.0),
			"source_glow": snapshot.get("world_combat_marker_scale_source_glow_visible", false),
			"grid_alpha": snapshot.get("world_combat_marker_scale_grid_noise_alpha", 1.0),
			"entries": snapshot.get("weapon_fire_vfx_entries", []),
		}))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Runtime snapshot schema is stable")
	_assert(String(snapshot.get("task_id", "")) == "TASK_901", "Runtime snapshot task id is TASK_901")
	_assert(String(snapshot.get("style_id", "")) == STYLE_ID, "Runtime snapshot style id is TASK_901")
	_assert(String(snapshot.get("gate", "")) == "pass", "TASK_901 runtime snapshot passes")
	_assert(bool(snapshot.get("active", false)), "TASK_901 runtime polish is active")
	_assert(bool(snapshot.get("elegance_ready", false)), "Runtime sees TASK_898 source elegance path")
	_assert(bool(snapshot.get("world_combat_marker_scale_lane_visible", false)), "Runtime marker-scale lane visible")
	_assert(float(snapshot.get("world_combat_marker_scale_target_halo_radius", 1.0)) < 0.64, "Runtime target halo is smaller than TASK_898")
	_assert(float(snapshot.get("world_combat_marker_scale_target_halo_alpha", 1.0)) < 0.24, "Runtime target halo alpha is quieter")
	_assert(bool(snapshot.get("world_combat_marker_scale_source_glow_visible", false)), "Runtime marker-scale source glow visible")
	_assert(float(snapshot.get("world_combat_marker_scale_grid_noise_alpha", 1.0)) < 0.42, "Runtime marker-scale grid/noise alpha is quieter")
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
			"task_id": "TASK_900",
			"status": "ready_for_marker_scale_world_noise_polish",
			"read_only": true,
		},
		"elegance": {
			"schema": ELEGANCE_SCHEMA,
			"task_id": "TASK_898",
			"style_id": ELEGANCE_STYLE_ID,
			"gate": "pass",
			"read_only": true,
		},
		"primary_render_snapshot": {
			"release_first_exchange_combat_marker_scale_world_noise_polish_active": true,
			"release_first_exchange_combat_marker_scale_world_noise_polish_style_id": STYLE_ID,
			"world_combat_marker_scale_lane_visible": true,
			"world_combat_marker_scale_lane_width": 0.066,
			"world_combat_marker_scale_lane_alpha": 0.64,
			"world_combat_marker_scale_target_halo_visible": true,
			"world_combat_marker_scale_target_halo_radius": 0.42,
			"world_combat_marker_scale_target_halo_alpha": 0.14,
			"world_combat_marker_scale_target_focus_radius": 0.52,
			"world_combat_marker_scale_source_glow_visible": true,
			"world_combat_marker_scale_source_glow_radius": 0.17,
			"world_combat_marker_scale_source_glow_alpha": 0.28,
			"world_combat_marker_scale_grid_noise_dimming_active": true,
			"world_combat_marker_scale_grid_noise_alpha": 0.28,
			"world_combat_marker_scale_world_line_dimming_active": true,
			"world_combat_marker_scale_world_line_alpha_factor": 0.22,
			"world_combat_marker_scale_world_line_width_factor": 0.34,
			"weapon_fire_vfx_visual_count": 1,
			"weapon_fire_vfx_entries": [
				{
					"combat_marker_scale_world_noise_polish_active": true,
					"combat_marker_scale_world_noise_polish_style_id": STYLE_ID,
					"world_combat_marker_scale_lane_visible": true,
					"world_combat_marker_scale_lane_width": 0.066,
					"world_combat_marker_scale_lane_alpha": 0.64,
					"world_combat_marker_scale_target_halo_visible": true,
					"world_combat_marker_scale_target_halo_radius": 0.42,
					"world_combat_marker_scale_target_halo_alpha": 0.14,
					"world_combat_marker_scale_target_focus_radius": 0.52,
					"world_combat_marker_scale_source_glow_visible": true,
					"world_combat_marker_scale_source_glow_radius": 0.17,
					"world_combat_marker_scale_source_glow_alpha": 0.28,
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
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_901_marker_scale_world_noise", Vector2i(8, 8), Vector2.ZERO, 64.0, 32.0, 3)
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	return primary_view


func _build_fire_event() -> Dictionary:
	return {
		"event_id": "task_901_fire_001",
		"attacker_unit_id": "alpha_1",
		"target_unit_id": "enemy_1",
		"weapon_id": "rifle",
		"attacker_position": Vector2(96.0, 96.0),
		"target_position": Vector2(256.0, 192.0),
		"combat_outcome": "hit",
		"damage_resolved": 1,
		"hit_chance_resolved": 0.72,
		"source": "task_901_test_fixture",
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
