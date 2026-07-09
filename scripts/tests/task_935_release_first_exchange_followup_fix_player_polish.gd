extends SceneTree

const PlayerPolish := preload("res://scripts/mission/release_first_exchange_followup_fix_player_polish.gd")

const TASK_PATH := "res://docs/tasks/TASK_935_release_first_exchange_followup_fix_player_polish.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH := "res://docs/reports/spielstand_zwischenbericht_task932_ausblick_2026_07_09.html"
const SERVICE_PATH := "res://scripts/mission/release_first_exchange_followup_fix_player_polish.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const TERRAIN_VIEW_PATH := "res://scripts/terrain/terrain_map_3d_view.gd"
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const SCHEMA := "sternenbuergerchen.release_first_exchange_followup_fix_player_polish.v1"
const STYLE_ID := "task_935_release_first_exchange_followup_fix_player_polish_v1"
const FINDINGS_SCHEMA := "sternenbuergerchen.release_first_exchange_followup_fix_visual_findings.v1"
const FOLLOWUP_FIX_SCHEMA := "sternenbuergerchen.release_first_exchange_final_readability_followup_fix.v1"
const FOLLOWUP_FIX_STYLE_ID := "task_932_release_first_exchange_final_readability_followup_v1"
const NEXT_TASK := "TASK_936 - Release First Exchange Followup Fix Player Polish Recapture"
const DENSITY_MODE := "release_firefight_declutter"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_935 Release First Exchange Followup Fix Player Polish ===")
	_test_docs_and_static_hooks()
	_test_helper_snapshot_passes()
	await _test_terrain_player_polish_parameters()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_935_release_first_exchange_followup_fix_player_polish: FAILED")
		quit(1)
		return
	print("TASK_935_release_first_exchange_followup_fix_player_polish: ALL PASSED")
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
	var controller_resource: Resource = load(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_935 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_935 service exists")
	_assert(FileAccess.file_exists(REPORT_PATH), "TASK_935 progress report exists")
	_assert(controller_resource != null, "Controller script parses with TASK_935 hook")
	_assert(task_text.contains("Release First Exchange Followup Fix Player Polish"), "Task names TASK_935")
	_assert(task_text.contains(NEXT_TASK), "Task names TASK_936 recapture")
	_assert(status_text.contains("TASK_935 - Release First Exchange Followup Fix Player Polish"), "Implementation status tracks TASK_935")
	_assert(roadmap_text.contains("TASK_935 - Release First Exchange Followup Fix Player Polish (implementiert"), "Roadmap marks TASK_935 implemented")
	_assert(roadmap_text.contains(NEXT_TASK), "Roadmap names TASK_936")
	_assert(contract_text.contains("Release-First-Exchange-Followup-Fix-Player-Polish (TASK_935)"), "Contract documents TASK_935")
	_assert(report_text.contains("TASK_935") and report_text.contains("TASK_936"), "HTML report tracks TASK_935 and TASK_936")
	_assert(service_text.contains(SCHEMA), "Service exposes stable TASK_935 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_935\""), "Service writes TASK_935 id")
	_assert(service_text.contains("SOURCE_FINDINGS_TASK_ID: String = \"TASK_934\""), "Service links TASK_934")
	_assert(service_text.contains("SOURCE_FOLLOWUP_FIX_TASK_ID: String = \"TASK_932\""), "Service links TASK_932")
	_assert(service_text.contains("lane_reads_before_text_halo"), "Service checks lane before text/halo")
	_assert(service_text.contains("world_noise_player_polish_retreat"), "Service checks quieter world noise")
	_assert(controller_text.contains("RELEASE_FIRST_EXCHANGE_FOLLOWUP_FIX_PLAYER_POLISH_SCRIPT"), "Controller preloads TASK_935 service")
	_assert(controller_text.contains("get_release_first_exchange_followup_fix_player_polish_snapshot"), "Controller exposes TASK_935 snapshot")
	_assert(controller_text.contains("release_first_exchange_followup_fix_player_polish"), "Controller sends TASK_935 payload")
	_assert(terrain_text.contains("RELEASE_FIRST_EXCHANGE_FOLLOWUP_FIX_PLAYER_POLISH_STYLE_ID"), "Terrain declares TASK_935 style")
	_assert(terrain_text.contains("_is_release_first_exchange_followup_fix_player_polish_active"), "Terrain detects TASK_935 payload")
	_assert(terrain_text.contains("followup_fix_player_polish_active"), "Terrain reports TASK_935 fire VFX flag")


func _test_helper_snapshot_passes() -> void:
	var snapshot: Dictionary = PlayerPolish.build_snapshot(_helper_source(), {})
	var followup: Dictionary = Dictionary(snapshot.get("followup_fix", {}))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Helper snapshot schema matches TASK_935")
	_assert(String(snapshot.get("task_id", "")) == "TASK_935", "Helper snapshot task id is TASK_935")
	_assert(String(snapshot.get("style_id", "")) == STYLE_ID, "Helper snapshot style id is stable")
	_assert(String(snapshot.get("source_findings_schema", "")) == FINDINGS_SCHEMA, "Helper links TASK_934 schema")
	_assert(String(snapshot.get("source_followup_fix_schema", "")) == FOLLOWUP_FIX_SCHEMA, "Helper links TASK_932 schema")
	_assert(String(snapshot.get("source_followup_fix_style_id", "")) == FOLLOWUP_FIX_STYLE_ID, "Helper links TASK_932 style")
	_assert(String(snapshot.get("gate", "")) == "pass", "Helper snapshot passes")
	_assert(bool(snapshot.get("active", false)), "Helper snapshot active")
	_assert(bool(snapshot.get("findings_ready", false)), "Helper accepts TASK_934 findings")
	_assert(bool(snapshot.get("followup_fix_ready", false)), "Helper accepts TASK_932 follow-up fix")
	_assert(float(snapshot.get("world_combat_followup_fix_player_polish_lane_width", 0.0)) > float(followup.get("world_combat_final_readability_followup_lane_width", 1.0)), "Helper sees wider TASK_935 lane")
	_assert(float(snapshot.get("world_combat_followup_fix_player_polish_lane_alpha", 1.0)) < float(followup.get("world_combat_final_readability_followup_lane_alpha", 0.0)), "Helper sees softer TASK_935 lane")
	_assert(float(snapshot.get("world_combat_followup_fix_player_polish_core_width", 0.0)) > float(followup.get("world_combat_final_readability_followup_core_width", 1.0)), "Helper sees stronger TASK_935 core")
	_assert(float(snapshot.get("world_combat_followup_fix_player_polish_target_halo_radius", 1.0)) < float(followup.get("world_combat_final_readability_followup_target_halo_radius", 0.0)), "Helper sees smaller TASK_935 halo")
	_assert(float(snapshot.get("world_combat_followup_fix_player_polish_status_label_alpha", 1.0)) < float(followup.get("world_combat_final_readability_followup_status_label_alpha", 0.0)), "Helper sees quieter TASK_935 label")
	_assert(float(snapshot.get("world_combat_followup_fix_player_polish_source_anchor_radius", 1.0)) <= 0.22, "Helper source anchor stays below disc threshold")
	_assert(float(snapshot.get("world_combat_followup_fix_player_polish_target_anchor_radius", 1.0)) <= 0.22, "Helper target anchor stays below disc threshold")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Helper recommends TASK_936")
	_assert(_snapshot_is_read_only(snapshot), "Helper snapshot is read-only")


func _test_terrain_player_polish_parameters() -> void:
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
		"release_first_exchange_fire_lane_world_read_micro_polish": true,
		"release_first_exchange_fire_lane_world_read_acceptance_polish": true,
		"release_first_exchange_fire_lane_world_read_final_polish": true,
		"release_first_exchange_final_world_read_followup_fix": true,
		"release_first_exchange_followup_world_read_player_polish": true,
		"release_first_exchange_followup_player_polish_tuning": true,
		"release_first_exchange_followup_player_polish_tuning_final_readability": true,
		"release_first_exchange_final_readability_followup_fix": true,
		"release_first_exchange_followup_fix_player_polish": true,
		"fire_event_dicts": [_build_fire_event()],
	})
	await _wait_frames(10)
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var entries: Array = Array(snapshot.get("weapon_fire_vfx_entries", []))
	var first_entry: Dictionary = Dictionary(entries[0]) if not entries.is_empty() else {}
	_assert(bool(snapshot.get("release_first_exchange_final_readability_followup_fix_active", false)), "Terrain keeps TASK_932 active")
	_assert(bool(snapshot.get("release_first_exchange_followup_fix_player_polish_active", false)), "Terrain TASK_935 player polish is active")
	_assert(String(snapshot.get("release_first_exchange_followup_fix_player_polish_style_id", "")) == STYLE_ID, "Terrain reports TASK_935 style")
	_assert(float(snapshot.get("world_combat_followup_fix_player_polish_lane_width", 0.0)) > float(snapshot.get("world_combat_final_readability_followup_lane_width", 1.0)), "TASK_935 lane is wider than TASK_932")
	_assert(float(snapshot.get("world_combat_followup_fix_player_polish_lane_alpha", 1.0)) < float(snapshot.get("world_combat_final_readability_followup_lane_alpha", 0.0)), "TASK_935 lane stays softer than TASK_932")
	_assert(float(snapshot.get("world_combat_followup_fix_player_polish_core_width", 0.0)) > float(snapshot.get("world_combat_final_readability_followup_core_width", 1.0)), "TASK_935 core is wider than TASK_932")
	_assert(float(snapshot.get("world_combat_followup_fix_player_polish_target_halo_radius", 1.0)) < float(snapshot.get("world_combat_final_readability_followup_target_halo_radius", 0.0)), "TASK_935 target halo is smaller")
	_assert(float(snapshot.get("world_combat_followup_fix_player_polish_status_label_alpha", 1.0)) < float(snapshot.get("world_combat_final_readability_followup_status_label_alpha", 0.0)), "TASK_935 world label alpha is quieter")
	_assert(float(snapshot.get("world_combat_followup_fix_player_polish_grid_noise_alpha", 1.0)) < float(snapshot.get("world_combat_final_readability_followup_grid_noise_alpha", 0.0)), "TASK_935 grid noise is quieter")
	_assert(float(snapshot.get("world_combat_followup_fix_player_polish_source_anchor_radius", 1.0)) <= 0.22, "TASK_935 source anchor stays below disc threshold")
	_assert(float(snapshot.get("world_combat_followup_fix_player_polish_target_anchor_radius", 1.0)) <= 0.22, "TASK_935 target anchor stays below disc threshold")
	_assert(bool(first_entry.get("final_readability_followup_fix_active", false)), "Fire VFX entry keeps TASK_932 flag")
	_assert(bool(first_entry.get("followup_fix_player_polish_active", false)), "Fire VFX entry carries TASK_935 flag")
	_assert(String(first_entry.get("followup_fix_player_polish_style_id", "")) == STYLE_ID, "Fire VFX entry carries TASK_935 style")
	_assert(float(first_entry.get("trace_width", 0.0)) == float(first_entry.get("world_combat_followup_fix_player_polish_core_width", -1.0)), "Fire VFX effective trace uses TASK_935 core")
	_assert(float(first_entry.get("fire_status_label_alpha", 1.0)) == float(snapshot.get("world_combat_followup_fix_player_polish_status_label_alpha", -1.0)), "Fire VFX entry carries TASK_935 label alpha")
	_assert(_snapshot_is_read_only(snapshot), "Terrain TASK_935 snapshot stays read-only")
	primary_view.queue_free()
	await _wait_frames(2)


func _helper_source() -> Dictionary:
	return {
		"findings": {
			"schema": FINDINGS_SCHEMA,
			"task_id": "TASK_934",
			"status": "ready_for_followup_fix_player_polish",
			"primary_issue_id": "followup_fix_fire_lane_not_first_world_movement",
			"read_only": true,
		},
		"followup_fix": {
			"schema": FOLLOWUP_FIX_SCHEMA,
			"task_id": "TASK_932",
			"style_id": FOLLOWUP_FIX_STYLE_ID,
			"gate": "pass",
			"world_combat_final_readability_followup_lane_width": 0.174,
			"world_combat_final_readability_followup_lane_alpha": 0.205,
			"world_combat_final_readability_followup_core_width": 0.134,
			"world_combat_final_readability_followup_core_alpha": 1.0,
			"world_combat_final_readability_followup_target_halo_radius": 0.052,
			"world_combat_final_readability_followup_target_halo_alpha": 0.003,
			"world_combat_final_readability_followup_source_anchor_radius": 0.214,
			"world_combat_final_readability_followup_target_anchor_radius": 0.218,
			"world_combat_final_readability_followup_status_label_alpha": 0.034,
			"world_combat_final_readability_followup_status_label_offset_y": -132.0,
			"world_combat_final_readability_followup_grid_noise_alpha": 0.066,
			"world_combat_final_readability_followup_world_line_alpha_factor": 0.024,
			"read_only": true,
		},
		"primary_render_snapshot": {
			"release_first_exchange_followup_fix_player_polish_active": true,
			"release_first_exchange_followup_fix_player_polish_style_id": STYLE_ID,
			"world_combat_followup_fix_player_polish_lane_width": 0.184,
			"world_combat_followup_fix_player_polish_lane_alpha": 0.188,
			"world_combat_followup_fix_player_polish_core_width": 0.146,
			"world_combat_followup_fix_player_polish_core_alpha": 1.0,
			"world_combat_followup_fix_player_polish_target_halo_radius": 0.040,
			"world_combat_followup_fix_player_polish_target_halo_alpha": 0.002,
			"world_combat_followup_fix_player_polish_source_anchor_radius": 0.218,
			"world_combat_followup_fix_player_polish_target_anchor_radius": 0.220,
			"world_combat_followup_fix_player_polish_status_label_alpha": 0.024,
			"world_combat_followup_fix_player_polish_status_label_offset_y": -144.0,
			"world_combat_followup_fix_player_polish_grid_noise_alpha": 0.056,
			"world_combat_followup_fix_player_polish_world_line_alpha_factor": 0.020,
			"weapon_fire_vfx_visual_count": 1,
			"weapon_fire_vfx_entries": [
				{
					"followup_fix_player_polish_active": true,
					"followup_fix_player_polish_style_id": STYLE_ID,
					"world_combat_followup_fix_player_polish_lane_width": 0.184,
					"world_combat_followup_fix_player_polish_lane_alpha": 0.188,
					"world_combat_followup_fix_player_polish_core_width": 0.146,
					"world_combat_followup_fix_player_polish_core_alpha": 1.0,
					"world_combat_followup_fix_player_polish_target_halo_radius": 0.040,
					"world_combat_followup_fix_player_polish_target_halo_alpha": 0.002,
					"world_combat_followup_fix_player_polish_source_anchor_radius": 0.218,
					"world_combat_followup_fix_player_polish_target_anchor_radius": 0.220,
					"fire_status_label_alpha": 0.024,
					"fire_status_label_offset_y": -144.0,
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
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_935_followup_fix_player_polish", Vector2i(8, 8), Vector2.ZERO, 64.0, 32.0, 3)
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	return primary_view


func _build_fire_event() -> Dictionary:
	return {
		"event_id": "task_935_fire_001",
		"attacker_unit_id": "alpha_1",
		"target_unit_id": "enemy_1",
		"weapon_id": "rifle",
		"attacker_position": Vector2(96.0, 96.0),
		"target_position": Vector2(256.0, 192.0),
		"combat_outcome": "hit",
		"damage_resolved": 1,
		"hit_chance_resolved": 0.72,
		"source": "task_935_test_fixture",
	}


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return not bool(snapshot.get("ui_sets_gameplay_truth", false)) \
		and not bool(snapshot.get("creates_command", false)) \
		and not bool(snapshot.get("creates_fire_event", false)) \
		and not bool(snapshot.get("creates_damage_event", false)) \
		and not bool(snapshot.get("creates_movement", false)) \
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
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
