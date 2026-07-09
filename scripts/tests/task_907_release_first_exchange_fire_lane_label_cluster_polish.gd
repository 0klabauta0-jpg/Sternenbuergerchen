extends SceneTree

const Polish := preload("res://scripts/mission/release_first_exchange_fire_lane_label_cluster_polish.gd")

const TASK_PATH := "res://docs/tasks/TASK_907_release_first_exchange_fire_lane_label_cluster_polish.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH := "res://docs/reports/spielstand_zwischenbericht_2026_07_09_aktuell.html"
const SERVICE_PATH := "res://scripts/mission/release_first_exchange_fire_lane_label_cluster_polish.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const TERRAIN_VIEW_PATH := "res://scripts/terrain/terrain_map_3d_view.gd"
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const SCHEMA := "sternenbuergerchen.release_first_exchange_fire_lane_label_cluster_polish.v1"
const STYLE_ID := "task_907_release_first_exchange_fire_lane_label_cluster_v1"
const FIRE_LANE_SCHEMA := "sternenbuergerchen.release_first_exchange_fire_lane_readability_polish.v1"
const FIRE_LANE_STYLE_ID := "task_904_release_first_exchange_fire_lane_readability_v1"
const NEXT_TASK := "TASK_908 - Release First Exchange Fire Lane Label Cluster Real Window Recapture"
const DENSITY_MODE := "release_firefight_declutter"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_907 Release First Exchange Fire Lane Label Cluster Polish ===")
	_test_docs_and_static_hooks()
	_test_helper_snapshot_passes()
	await _test_terrain_label_cluster_parameters()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_907_release_first_exchange_fire_lane_label_cluster_polish: FAILED")
		quit(1)
		return
	print("TASK_907_release_first_exchange_fire_lane_label_cluster_polish: ALL PASSED")
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
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_907 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_907 helper exists")
	_assert(task_text.contains("Release First Exchange Fire Lane Label Cluster Polish"), "Task names TASK_907")
	_assert(task_text.contains(NEXT_TASK), "Task names TASK_908 follow-up")
	_assert(status_text.contains("TASK_907 - Release First Exchange Fire Lane Label Cluster Polish"), "Implementation status tracks TASK_907")
	_assert(roadmap_text.contains("TASK_907 - Release First Exchange Fire Lane Label Cluster Polish (implementiert"), "Roadmap marks TASK_907 implemented")
	_assert(roadmap_text.contains(NEXT_TASK), "Roadmap names TASK_908 follow-up")
	_assert(contract_text.contains("Release-First-Exchange-Fire-Lane-Label-Cluster-Polish (TASK_907)"), "Contract documents TASK_907")
	_assert(report_text.contains("TASK_907") and report_text.contains("TASK_908"), "HTML report tracks TASK_907 and TASK_908")
	_assert(service_text.contains(SCHEMA), "Helper exposes stable TASK_907 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_907\""), "Helper writes TASK_907 id")
	_assert(service_text.contains("SOURCE_FINDINGS_TASK_ID: String = \"TASK_906\""), "Helper links TASK_906")
	_assert(service_text.contains("SOURCE_FIRE_LANE_TASK_ID: String = \"TASK_904\""), "Helper links TASK_904")
	_assert(service_text.contains("label_cluster_deemphasized"), "Helper checks label deemphasis")
	_assert(service_text.contains("target_halo_quieter_than_task_904"), "Helper checks quieter halo")
	_assert(service_text.contains("\"creates_command\": false"), "Helper creates no commands")
	_assert(service_text.contains("\"creates_fire_event\": false"), "Helper creates no fire events")
	_assert(service_text.contains("\"creates_damage_event\": false"), "Helper creates no damage events")
	_assert(service_text.contains("\"creates_movement\": false"), "Helper creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Helper sets no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_EXCHANGE_FIRE_LANE_LABEL_CLUSTER_POLISH_SCRIPT"), "Controller preloads TASK_907 helper")
	_assert(controller_text.contains("get_release_first_exchange_fire_lane_label_cluster_polish_snapshot"), "Controller exposes TASK_907 snapshot")
	_assert(controller_text.contains("release_first_exchange_fire_lane_label_cluster_polish"), "Controller sends TASK_907 payload")
	_assert(terrain_text.contains("RELEASE_FIRST_EXCHANGE_FIRE_LANE_LABEL_CLUSTER_STYLE_ID"), "Terrain declares TASK_907 style")
	_assert(terrain_text.contains("_is_release_first_exchange_fire_lane_label_cluster_active"), "Terrain detects TASK_907 payload")
	_assert(terrain_text.contains("RELEASE_FIRST_EXCHANGE_FIRE_LANE_LABEL_CLUSTER_STATUS_LABEL_OFFSET"), "Terrain offsets TASK_907 status label")
	_assert(terrain_text.contains("fire_lane_label_cluster_polish_active"), "Terrain reports TASK_907 fire VFX flag")


func _test_helper_snapshot_passes() -> void:
	var snapshot: Dictionary = Polish.build_snapshot(_helper_source(), {})
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Helper snapshot schema matches TASK_907")
	_assert(String(snapshot.get("task_id", "")) == "TASK_907", "Helper snapshot task id is TASK_907")
	_assert(String(snapshot.get("style_id", "")) == STYLE_ID, "Helper snapshot style id is stable")
	_assert(String(snapshot.get("source_fire_lane_schema", "")) == FIRE_LANE_SCHEMA, "Helper links TASK_904 schema")
	_assert(String(snapshot.get("source_fire_lane_style_id", "")) == FIRE_LANE_STYLE_ID, "Helper links TASK_904 style")
	_assert(String(snapshot.get("gate", "")) == "pass", "Helper snapshot passes")
	_assert(bool(snapshot.get("active", false)), "Helper snapshot active")
	_assert(bool(snapshot.get("findings_ready", false)), "Helper accepts TASK_906 finding")
	_assert(bool(snapshot.get("fire_lane_ready", false)), "Helper accepts TASK_904 source path")
	_assert(float(snapshot.get("world_combat_fire_lane_label_cluster_status_label_alpha", 1.0)) <= 0.62, "Helper sees quieter world label")
	_assert(int(snapshot.get("world_combat_fire_lane_label_cluster_status_label_font_size", 99)) <= 14, "Helper sees smaller world label")
	_assert(float(snapshot.get("world_combat_fire_lane_label_cluster_status_label_offset_y", 0.0)) <= -40.0, "Helper sees label offset out of target cluster")
	_assert(float(snapshot.get("world_combat_fire_lane_label_cluster_core_width", 0.0)) >= 0.038, "Helper sees stronger core width")
	_assert(float(snapshot.get("world_combat_fire_lane_label_cluster_core_alpha", 0.0)) >= 0.90, "Helper sees stronger core alpha")
	_assert(float(snapshot.get("world_combat_fire_lane_label_cluster_target_halo_radius", 1.0)) < 0.38, "Helper sees smaller halo")
	_assert(float(snapshot.get("world_combat_fire_lane_label_cluster_target_halo_alpha", 1.0)) < 0.10, "Helper sees quieter halo")
	_assert(float(snapshot.get("world_combat_fire_lane_label_cluster_source_anchor_radius", 0.0)) > 0.07, "Helper sees stronger source anchor")
	_assert(float(snapshot.get("world_combat_fire_lane_label_cluster_target_anchor_radius", 0.0)) > 0.08, "Helper sees stronger target anchor")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Helper recommends TASK_908")
	_assert(bool(snapshot.get("read_only", false)), "Helper snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Helper sets no gameplay truth")
	_assert(not bool(snapshot.get("creates_command", true)), "Helper creates no commands")
	_assert(not bool(snapshot.get("creates_fire_event", true)), "Helper creates no fire events")
	_assert(not bool(snapshot.get("creates_damage_event", true)), "Helper creates no damage events")
	_assert(not bool(snapshot.get("creates_movement", true)), "Helper creates no movement")
	_assert(not bool(snapshot.get("sets_multiplayer_truth", true)), "Helper sets no multiplayer truth")


func _test_terrain_label_cluster_parameters() -> void:
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
		"release_first_exchange_fire_lane_label_cluster_polish": true,
		"fire_event_dicts": [_build_fire_event()],
	})
	await _wait_frames(10)
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var entries: Array = Array(snapshot.get("weapon_fire_vfx_entries", []))
	var first_entry: Dictionary = Dictionary(entries[0]) if not entries.is_empty() else {}
	_assert(bool(snapshot.get("release_first_exchange_fire_lane_readability_polish_active", false)), "Terrain keeps TASK_904 fire lane active")
	_assert(bool(snapshot.get("release_first_exchange_fire_lane_label_cluster_polish_active", false)), "Terrain TASK_907 label-cluster polish is active")
	_assert(String(snapshot.get("release_first_exchange_fire_lane_label_cluster_polish_style_id", "")) == STYLE_ID, "Terrain reports TASK_907 style")
	_assert(float(snapshot.get("world_combat_fire_lane_label_cluster_lane_width", 0.0)) >= float(snapshot.get("world_combat_fire_lane_readability_lane_width", 0.0)), "TASK_907 lane stays at least as strong as TASK_904")
	_assert(float(snapshot.get("world_combat_fire_lane_label_cluster_core_width", 0.0)) > float(snapshot.get("world_combat_fire_lane_readability_core_width", 1.0)), "TASK_907 core is wider than TASK_904")
	_assert(float(snapshot.get("world_combat_fire_lane_label_cluster_core_alpha", 0.0)) > float(snapshot.get("world_combat_fire_lane_readability_core_alpha", 1.0)), "TASK_907 core is brighter than TASK_904")
	_assert(float(snapshot.get("world_combat_fire_lane_label_cluster_target_halo_radius", 1.0)) < float(snapshot.get("world_combat_fire_lane_readability_target_halo_radius", 0.0)), "TASK_907 target halo is smaller")
	_assert(float(snapshot.get("world_combat_fire_lane_label_cluster_target_halo_alpha", 1.0)) < float(snapshot.get("world_combat_fire_lane_readability_target_halo_alpha", 0.0)), "TASK_907 target halo is quieter")
	_assert(float(snapshot.get("world_combat_fire_lane_label_cluster_status_label_alpha", 1.0)) <= 0.62, "TASK_907 world label alpha is subdued")
	_assert(int(snapshot.get("world_combat_fire_lane_label_cluster_status_label_font_size", 99)) <= 14, "TASK_907 world label font is smaller")
	_assert(float(snapshot.get("world_combat_fire_lane_label_cluster_status_label_offset_y", 0.0)) <= -40.0, "TASK_907 world label is offset from cluster")
	_assert(float(snapshot.get("tile_grid_line_effective_alpha", 1.0)) <= float(snapshot.get("world_combat_fire_lane_label_cluster_grid_noise_alpha", 1.0)) + 0.001, "Terrain grid material alpha follows TASK_907 dimming")
	_assert(bool(first_entry.get("fire_lane_label_cluster_polish_active", false)), "Fire VFX entry carries TASK_907 flag")
	_assert(String(first_entry.get("fire_lane_label_cluster_polish_style_id", "")) == STYLE_ID, "Fire VFX entry carries TASK_907 style")
	_assert(float(first_entry.get("trace_width", 0.0)) == float(first_entry.get("world_combat_fire_lane_label_cluster_core_width", -1.0)), "Fire VFX effective trace uses TASK_907 core")
	_assert(float(first_entry.get("fire_status_label_alpha", 1.0)) <= 0.62, "Fire VFX entry carries quieter label alpha")
	_assert(int(first_entry.get("fire_status_label_font_size", 99)) <= 14, "Fire VFX entry carries smaller label font")
	_assert(_snapshot_is_read_only(snapshot), "Terrain TASK_907 snapshot stays read-only")
	primary_view.queue_free()
	await _wait_frames(2)


func _helper_source() -> Dictionary:
	var fire_lane_snapshot: Dictionary = {
		"schema": FIRE_LANE_SCHEMA,
		"task_id": "TASK_904",
		"style_id": FIRE_LANE_STYLE_ID,
		"gate": "pass",
		"world_combat_fire_lane_readability_lane_width": 0.092,
		"world_combat_fire_lane_readability_core_width": 0.038,
		"world_combat_fire_lane_readability_core_alpha": 0.88,
		"world_combat_fire_lane_readability_target_halo_radius": 0.38,
		"world_combat_fire_lane_readability_target_halo_alpha": 0.10,
		"world_combat_fire_lane_readability_source_anchor_radius": 0.07,
		"world_combat_fire_lane_readability_target_anchor_radius": 0.08,
		"read_only": true,
	}
	return {
		"findings": {
			"schema": "sternenbuergerchen.release_first_exchange_fire_lane_visual_findings.v1",
			"task_id": "TASK_906",
			"status": "ready_for_fire_lane_label_cluster_polish",
			"primary_issue_id": "fire_lane_not_first_world_read",
			"read_only": true,
		},
		"fire_lane": fire_lane_snapshot,
		"primary_render_snapshot": {
			"release_first_exchange_fire_lane_label_cluster_polish_active": true,
			"release_first_exchange_fire_lane_label_cluster_polish_style_id": STYLE_ID,
			"world_combat_fire_lane_label_cluster_lane_width": 0.098,
			"world_combat_fire_lane_label_cluster_lane_alpha": 0.50,
			"world_combat_fire_lane_label_cluster_core_width": 0.044,
			"world_combat_fire_lane_label_cluster_core_alpha": 0.92,
			"world_combat_fire_lane_label_cluster_target_halo_radius": 0.30,
			"world_combat_fire_lane_label_cluster_target_halo_alpha": 0.07,
			"world_combat_fire_lane_label_cluster_source_anchor_radius": 0.088,
			"world_combat_fire_lane_label_cluster_target_anchor_radius": 0.10,
			"world_combat_fire_lane_label_cluster_status_label_font_size": 13,
			"world_combat_fire_lane_label_cluster_status_label_alpha": 0.58,
			"world_combat_fire_lane_label_cluster_status_label_offset_y": -44.0,
			"weapon_fire_vfx_visual_count": 1,
			"weapon_fire_vfx_entries": [
				{
					"fire_lane_label_cluster_polish_active": true,
					"fire_lane_label_cluster_polish_style_id": STYLE_ID,
					"world_combat_fire_lane_label_cluster_lane_width": 0.098,
					"world_combat_fire_lane_label_cluster_lane_alpha": 0.50,
					"world_combat_fire_lane_label_cluster_core_width": 0.044,
					"world_combat_fire_lane_label_cluster_core_alpha": 0.92,
					"world_combat_fire_lane_label_cluster_target_halo_radius": 0.30,
					"world_combat_fire_lane_label_cluster_target_halo_alpha": 0.07,
					"world_combat_fire_lane_label_cluster_source_anchor_radius": 0.088,
					"world_combat_fire_lane_label_cluster_target_anchor_radius": 0.10,
					"fire_status_label_font_size": 13,
					"fire_status_label_alpha": 0.58,
					"fire_status_label_offset_y": -44.0,
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
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_907_fire_lane_label_cluster", Vector2i(8, 8), Vector2.ZERO, 64.0, 32.0, 3)
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	return primary_view


func _build_fire_event() -> Dictionary:
	return {
		"event_id": "task_907_fire_001",
		"attacker_unit_id": "alpha_1",
		"target_unit_id": "enemy_1",
		"weapon_id": "rifle",
		"attacker_position": Vector2(96.0, 96.0),
		"target_position": Vector2(256.0, 192.0),
		"combat_outcome": "hit",
		"damage_resolved": 1,
		"hit_chance_resolved": 0.72,
		"source": "task_907_test_fixture",
	}


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return not bool(snapshot.get("ui_sets_gameplay_truth", false)) \
		and not bool(snapshot.get("creates_command", false)) \
		and not bool(snapshot.get("creates_fire_event", false)) \
		and not bool(snapshot.get("creates_damage_event", false)) \
		and not bool(snapshot.get("sets_multiplayer_truth", false))


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] %s" % message)
	else:
		_failed += 1
		push_error("[FAIL] %s" % message)
