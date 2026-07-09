extends SceneTree

const Polish := preload("res://scripts/mission/release_first_exchange_fire_lane_readability_polish.gd")

const TASK_PATH := "res://docs/tasks/TASK_904_release_first_exchange_fire_lane_readability_polish.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH := "res://docs/reports/spielstand_zwischenbericht_2026_07_09_aktuell.html"
const SERVICE_PATH := "res://scripts/mission/release_first_exchange_fire_lane_readability_polish.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const TERRAIN_VIEW_PATH := "res://scripts/terrain/terrain_map_3d_view.gd"
const META_LAYER_SCENE_PATH := "res://scenes/meta/meta_layer_test.tscn"
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const FIRST_GO_FIREFIGHT_ARG := "--release-singleplayer-first-go-firefight"
const SCHEMA := "sternenbuergerchen.release_first_exchange_fire_lane_readability_polish.v1"
const STYLE_ID := "task_904_release_first_exchange_fire_lane_readability_v1"
const MARKER_SCALE_SCHEMA := "sternenbuergerchen.release_first_exchange_combat_marker_scale_world_noise_polish.v1"
const MARKER_SCALE_STYLE_ID := "task_901_release_first_exchange_combat_marker_scale_world_noise_v1"
const NEXT_TASK := "TASK_905 - Release First Exchange Fire Lane Real Window Recapture"
const DENSITY_MODE := "release_firefight_declutter"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_904 Release First Exchange Fire Lane Readability Polish ===")
	_test_docs_and_static_hooks()
	_test_helper_snapshot_passes()
	await _test_terrain_fire_lane_readability_parameters()
	await _test_meta_layer_task_904_runtime_snapshot()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_904_release_first_exchange_fire_lane_readability_polish: FAILED")
		quit(1)
		return
	print("TASK_904_release_first_exchange_fire_lane_readability_polish: ALL PASSED")
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
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_904 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_904 helper exists")
	_assert(task_text.contains("Release First Exchange Fire Lane Readability Polish"), "Task names TASK_904")
	_assert(task_text.contains(NEXT_TASK), "Task names TASK_905 follow-up")
	_assert(status_text.contains("TASK_904 - Release First Exchange Fire Lane Readability Polish"), "Implementation status tracks TASK_904")
	_assert(roadmap_text.contains("TASK_904 - Release First Exchange Fire Lane Readability Polish (implementiert)"), "Roadmap marks TASK_904 implemented")
	_assert(roadmap_text.contains(NEXT_TASK), "Roadmap names TASK_905 follow-up")
	_assert(contract_text.contains("Release-First-Exchange-Fire-Lane-Readability-Polish (TASK_904)"), "Contract documents TASK_904")
	_assert(report_text.contains("TASK_904") and report_text.contains("TASK_905"), "HTML report tracks TASK_904 and TASK_905")
	_assert(service_text.contains(SCHEMA), "Helper exposes stable TASK_904 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_904\""), "Helper writes TASK_904 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_903\""), "Helper links TASK_903")
	_assert(service_text.contains("SOURCE_MARKER_SCALE_TASK_ID: String = \"TASK_901\""), "Helper links TASK_901")
	_assert(service_text.contains("\"creates_command\": false"), "Helper creates no commands")
	_assert(service_text.contains("\"creates_fire_event\": false"), "Helper creates no fire events")
	_assert(service_text.contains("\"creates_damage_event\": false"), "Helper creates no damage events")
	_assert(service_text.contains("\"creates_movement\": false"), "Helper creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Helper sets no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_EXCHANGE_FIRE_LANE_READABILITY_POLISH_SCRIPT"), "Controller preloads TASK_904 helper")
	_assert(controller_text.contains("get_release_first_exchange_fire_lane_readability_polish_snapshot"), "Controller exposes TASK_904 snapshot")
	_assert(controller_text.contains("release_first_exchange_fire_lane_readability_polish"), "Controller sends TASK_904 payload")
	_assert(terrain_text.contains("RELEASE_FIRST_EXCHANGE_FIRE_LANE_READABILITY_STYLE_ID"), "Terrain declares TASK_904 style")
	_assert(terrain_text.contains("_is_release_first_exchange_fire_lane_readability_active"), "Terrain detects TASK_904 payload")
	_assert(terrain_text.contains("WeaponFireWorldCombatFireLaneReadabilityLane"), "Terrain renders TASK_904 soft lane")
	_assert(terrain_text.contains("WeaponFireWorldCombatFireLaneReadabilityCore"), "Terrain renders TASK_904 lane core")
	_assert(terrain_text.contains("WeaponFireWorldCombatFireLaneReadabilityTargetAnchor"), "Terrain renders TASK_904 target anchor")


func _test_helper_snapshot_passes() -> void:
	var snapshot: Dictionary = Polish.build_snapshot(_helper_source(), {})
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Helper snapshot schema matches TASK_904")
	_assert(String(snapshot.get("task_id", "")) == "TASK_904", "Helper snapshot task id is TASK_904")
	_assert(String(snapshot.get("style_id", "")) == STYLE_ID, "Helper snapshot style id is stable")
	_assert(String(snapshot.get("source_marker_scale_schema", "")) == MARKER_SCALE_SCHEMA, "Helper links TASK_901 schema")
	_assert(String(snapshot.get("source_marker_scale_style_id", "")) == MARKER_SCALE_STYLE_ID, "Helper links TASK_901 style")
	_assert(String(snapshot.get("gate", "")) == "pass", "Helper snapshot passes")
	_assert(bool(snapshot.get("active", false)), "Helper snapshot active")
	_assert(bool(snapshot.get("findings_ready", false)), "Helper accepts TASK_903 ready finding")
	_assert(bool(snapshot.get("marker_scale_ready", false)), "Helper accepts TASK_901 source path")
	_assert(bool(snapshot.get("world_combat_fire_lane_readability_lane_visible", false)), "Helper sees soft fire lane")
	_assert(float(snapshot.get("world_combat_fire_lane_readability_lane_width", 0.0)) > 0.066, "Fire lane is stronger than TASK_901 lane")
	_assert(bool(snapshot.get("world_combat_fire_lane_readability_core_visible", false)), "Helper sees bright lane core")
	_assert(float(snapshot.get("world_combat_fire_lane_readability_core_alpha", 0.0)) >= 0.82, "Lane core is high contrast")
	_assert(bool(snapshot.get("world_combat_fire_lane_readability_target_halo_visible", false)), "Helper sees quiet target halo")
	_assert(float(snapshot.get("world_combat_fire_lane_readability_target_halo_radius", 1.0)) <= 0.42, "Target halo remains no larger than TASK_901")
	_assert(float(snapshot.get("world_combat_fire_lane_readability_target_halo_alpha", 1.0)) <= 0.14, "Target halo alpha remains no louder than TASK_901")
	_assert(bool(snapshot.get("world_combat_fire_lane_readability_source_anchor_visible", false)), "Helper sees small source anchor")
	_assert(bool(snapshot.get("world_combat_fire_lane_readability_target_anchor_visible", false)), "Helper sees small target anchor")
	_assert(float(snapshot.get("world_combat_fire_lane_readability_grid_noise_alpha", 1.0)) <= 0.28, "Grid noise remains below TASK_901")
	_assert(float(snapshot.get("world_combat_fire_lane_readability_world_line_alpha_factor", 1.0)) <= 0.22, "World-line alpha remains below TASK_901")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Helper recommends TASK_905")
	_assert(bool(snapshot.get("read_only", false)), "Helper snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Helper sets no gameplay truth")
	_assert(not bool(snapshot.get("creates_command", true)), "Helper creates no commands")
	_assert(not bool(snapshot.get("creates_fire_event", true)), "Helper creates no fire events")
	_assert(not bool(snapshot.get("creates_damage_event", true)), "Helper creates no damage events")
	_assert(not bool(snapshot.get("creates_movement", true)), "Helper creates no movement")
	_assert(not bool(snapshot.get("sets_multiplayer_truth", true)), "Helper sets no multiplayer truth")


func _test_terrain_fire_lane_readability_parameters() -> void:
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
		"release_first_exchange_fire_lane_readability_polish": true,
		"fire_event_dicts": [_build_fire_event()],
	})
	await _wait_frames(10)
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var entries: Array = Array(snapshot.get("weapon_fire_vfx_entries", []))
	var first_entry: Dictionary = Dictionary(entries[0]) if not entries.is_empty() else {}
	_assert(bool(snapshot.get("release_first_exchange_combat_marker_scale_world_noise_polish_active", false)), "Terrain keeps TASK_901 marker scale active")
	_assert(bool(snapshot.get("release_first_exchange_fire_lane_readability_polish_active", false)), "Terrain TASK_904 fire-lane polish is active")
	_assert(String(snapshot.get("release_first_exchange_fire_lane_readability_polish_style_id", "")) == STYLE_ID, "Terrain reports TASK_904 style")
	_assert(bool(snapshot.get("world_combat_fire_lane_readability_lane_visible", false)), "Terrain reports TASK_904 soft lane")
	_assert(bool(snapshot.get("world_combat_fire_lane_readability_core_visible", false)), "Terrain reports TASK_904 lane core")
	_assert(float(snapshot.get("world_combat_fire_lane_readability_lane_width", 0.0)) > float(snapshot.get("world_combat_marker_scale_lane_width", 1.0)), "TASK_904 lane is stronger than TASK_901 lane")
	_assert(float(snapshot.get("world_combat_fire_lane_readability_core_width", 1.0)) < float(snapshot.get("world_combat_fire_lane_readability_lane_width", 0.0)), "TASK_904 core stays narrower than soft lane")
	_assert(float(snapshot.get("world_combat_fire_lane_readability_target_halo_radius", 1.0)) <= float(snapshot.get("world_combat_marker_scale_target_halo_radius", 0.0)), "TASK_904 halo remains no larger than TASK_901")
	_assert(float(snapshot.get("world_combat_fire_lane_readability_target_halo_alpha", 1.0)) <= float(snapshot.get("world_combat_marker_scale_target_halo_alpha", 0.0)), "TASK_904 halo alpha remains quiet")
	_assert(bool(snapshot.get("world_combat_fire_lane_readability_source_anchor_visible", false)), "Terrain reports source anchor")
	_assert(bool(snapshot.get("world_combat_fire_lane_readability_target_anchor_visible", false)), "Terrain reports target anchor")
	_assert(float(snapshot.get("world_combat_fire_lane_readability_grid_noise_alpha", 1.0)) <= float(snapshot.get("world_combat_marker_scale_grid_noise_alpha", 1.0)), "TASK_904 grid alpha remains subdued")
	_assert(float(snapshot.get("tile_grid_line_effective_alpha", 1.0)) <= float(snapshot.get("world_combat_fire_lane_readability_grid_noise_alpha", 1.0)) + 0.001, "Terrain grid material alpha follows TASK_904 dimming")
	_assert(bool(first_entry.get("fire_lane_readability_polish_active", false)), "Fire VFX entry carries TASK_904 flag")
	_assert(bool(first_entry.get("world_combat_fire_lane_readability_core_visible", false)), "Fire VFX entry carries lane core")
	_assert(float(first_entry.get("trace_width", 1.0)) <= float(first_entry.get("world_combat_fire_lane_readability_core_width", 0.0)) + 0.001, "Fire VFX effective trace is the narrow TASK_904 core")
	_assert(_snapshot_is_read_only(snapshot), "Terrain TASK_904 snapshot stays read-only")
	primary_view.queue_free()
	await _wait_frames(2)


func _test_meta_layer_task_904_runtime_snapshot() -> void:
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
	_assert(controller.has_method("get_release_first_exchange_fire_lane_readability_polish_snapshot"), "Controller exposes TASK_904 runtime snapshot")
	if not controller.has_method("get_release_first_exchange_fire_lane_readability_polish_snapshot"):
		scene.queue_free()
		await _wait_frames(1)
		return
	var snapshot: Dictionary = Dictionary(controller.call("get_release_first_exchange_fire_lane_readability_polish_snapshot"))
	if String(snapshot.get("gate", "")) != "pass":
		print("TASK_904_DIAGNOSTIC %s" % JSON.stringify({
			"failed_checks": snapshot.get("failed_checks", []),
			"lane": snapshot.get("world_combat_fire_lane_readability_lane_visible", false),
			"core": snapshot.get("world_combat_fire_lane_readability_core_visible", false),
			"halo_radius": snapshot.get("world_combat_fire_lane_readability_target_halo_radius", 0.0),
			"grid_alpha": snapshot.get("world_combat_fire_lane_readability_grid_noise_alpha", 1.0),
			"entries": snapshot.get("weapon_fire_vfx_entries", []),
		}))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Runtime snapshot schema is stable")
	_assert(String(snapshot.get("task_id", "")) == "TASK_904", "Runtime snapshot task id is TASK_904")
	_assert(String(snapshot.get("style_id", "")) == STYLE_ID, "Runtime snapshot style id is TASK_904")
	_assert(String(snapshot.get("gate", "")) == "pass", "TASK_904 runtime snapshot passes")
	_assert(bool(snapshot.get("active", false)), "TASK_904 runtime polish is active")
	_assert(bool(snapshot.get("marker_scale_ready", false)), "Runtime sees TASK_901 source path")
	_assert(bool(snapshot.get("world_combat_fire_lane_readability_lane_visible", false)), "Runtime fire-lane visible")
	_assert(bool(snapshot.get("world_combat_fire_lane_readability_core_visible", false)), "Runtime fire-lane core visible")
	_assert(float(snapshot.get("world_combat_fire_lane_readability_target_halo_radius", 1.0)) <= 0.42, "Runtime target halo stays small")
	_assert(bool(snapshot.get("world_combat_fire_lane_readability_source_anchor_visible", false)), "Runtime source anchor visible")
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
			"schema": "sternenbuergerchen.release_first_exchange_combat_marker_scale_visual_findings.v1",
			"task_id": "TASK_903",
			"status": "ready_for_fire_lane_readability_polish",
			"primary_issue_id": "fire_lane_still_too_subtle",
			"read_only": true,
		},
		"marker_scale": {
			"schema": MARKER_SCALE_SCHEMA,
			"task_id": "TASK_901",
			"style_id": MARKER_SCALE_STYLE_ID,
			"gate": "pass",
			"world_combat_marker_scale_lane_width": 0.066,
			"world_combat_marker_scale_lane_alpha": 0.64,
			"world_combat_marker_scale_target_halo_radius": 0.42,
			"world_combat_marker_scale_target_halo_alpha": 0.14,
			"world_combat_marker_scale_source_glow_radius": 0.17,
			"world_combat_marker_scale_grid_noise_alpha": 0.28,
			"world_combat_marker_scale_world_line_alpha_factor": 0.22,
			"read_only": true,
		},
		"primary_render_snapshot": {
			"release_first_exchange_fire_lane_readability_polish_active": true,
			"release_first_exchange_fire_lane_readability_polish_style_id": STYLE_ID,
			"world_combat_fire_lane_readability_lane_visible": true,
			"world_combat_fire_lane_readability_lane_width": 0.092,
			"world_combat_fire_lane_readability_lane_alpha": 0.54,
			"world_combat_fire_lane_readability_core_visible": true,
			"world_combat_fire_lane_readability_core_width": 0.038,
			"world_combat_fire_lane_readability_core_alpha": 0.88,
			"world_combat_fire_lane_readability_target_halo_visible": true,
			"world_combat_fire_lane_readability_target_halo_radius": 0.38,
			"world_combat_fire_lane_readability_target_halo_alpha": 0.10,
			"world_combat_fire_lane_readability_target_focus_radius": 0.48,
			"world_combat_fire_lane_readability_source_glow_visible": true,
			"world_combat_fire_lane_readability_source_glow_radius": 0.16,
			"world_combat_fire_lane_readability_source_glow_alpha": 0.30,
			"world_combat_fire_lane_readability_source_anchor_visible": true,
			"world_combat_fire_lane_readability_source_anchor_radius": 0.07,
			"world_combat_fire_lane_readability_target_anchor_visible": true,
			"world_combat_fire_lane_readability_target_anchor_radius": 0.08,
			"world_combat_fire_lane_readability_grid_noise_dimming_active": true,
			"world_combat_fire_lane_readability_grid_noise_alpha": 0.24,
			"world_combat_fire_lane_readability_world_line_dimming_active": true,
			"world_combat_fire_lane_readability_world_line_alpha_factor": 0.18,
			"world_combat_fire_lane_readability_world_line_width_factor": 0.30,
			"weapon_fire_vfx_visual_count": 1,
			"weapon_fire_vfx_entries": [
				{
					"fire_lane_readability_polish_active": true,
					"fire_lane_readability_polish_style_id": STYLE_ID,
					"world_combat_fire_lane_readability_lane_visible": true,
					"world_combat_fire_lane_readability_lane_width": 0.092,
					"world_combat_fire_lane_readability_lane_alpha": 0.54,
					"world_combat_fire_lane_readability_core_visible": true,
					"world_combat_fire_lane_readability_core_width": 0.038,
					"world_combat_fire_lane_readability_core_alpha": 0.88,
					"world_combat_fire_lane_readability_target_halo_visible": true,
					"world_combat_fire_lane_readability_target_halo_radius": 0.38,
					"world_combat_fire_lane_readability_target_halo_alpha": 0.10,
					"world_combat_fire_lane_readability_target_focus_radius": 0.48,
					"world_combat_fire_lane_readability_source_glow_visible": true,
					"world_combat_fire_lane_readability_source_glow_radius": 0.16,
					"world_combat_fire_lane_readability_source_glow_alpha": 0.30,
					"world_combat_fire_lane_readability_source_anchor_visible": true,
					"world_combat_fire_lane_readability_source_anchor_radius": 0.07,
					"world_combat_fire_lane_readability_target_anchor_visible": true,
					"world_combat_fire_lane_readability_target_anchor_radius": 0.08,
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
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_904_fire_lane_readability", Vector2i(8, 8), Vector2.ZERO, 64.0, 32.0, 3)
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	return primary_view


func _build_fire_event() -> Dictionary:
	return {
		"event_id": "task_904_fire_001",
		"attacker_unit_id": "alpha_1",
		"target_unit_id": "enemy_1",
		"weapon_id": "rifle",
		"attacker_position": Vector2(96.0, 96.0),
		"target_position": Vector2(256.0, 192.0),
		"combat_outcome": "hit",
		"damage_resolved": 1,
		"hit_chance_resolved": 0.72,
		"source": "task_904_test_fixture",
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
