extends SceneTree

const TASK_PATH := "res://docs/tasks/TASK_942_release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH := "res://docs/reports/spielstand_zwischenbericht_task939_ausblick_2026_07_09.html"
const SERVICE_PATH := "res://scripts/mission/release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const TERRAIN_VIEW_PATH := "res://scripts/terrain/terrain_map_3d_view.gd"
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const SCHEMA := "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix.v1"
const STYLE_ID := "task_942_release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix_v1"
const SOURCE_GATE_SCHEMA := "sternenbuergerchen.release_first_exchange_final_tuning_playability_smoke_gate.v1"
const SOURCE_FINDINGS_SCHEMA := "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_visual_findings.v1"
const BASE_STYLE_ID := "task_938_release_first_exchange_followup_fix_player_polish_final_tuning_v1"
const NEXT_TASK := "TASK_943 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Recapture"
const DENSITY_MODE := "release_firefight_declutter"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_942 Release First Exchange Followup Fix Player Polish Final Tuning Followup Fix ===")
	_test_docs_and_static_hooks()
	_test_helper_snapshot_passes()
	await _test_terrain_followup_fix_parameters()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_942_release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix: FAILED")
		quit(1)
		return
	print("TASK_942_release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix: ALL PASSED")
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
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_942 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_942 service exists")
	_assert(controller_resource != null, "Controller script parses with TASK_942 hook")
	_assert(task_text.contains("Release First Exchange Followup Fix Player Polish Final Tuning Followup Fix"), "Task names TASK_942")
	_assert(task_text.contains(NEXT_TASK), "Task names TASK_943 recapture")
	_assert(status_text.contains("TASK_942 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Fix"), "Implementation status tracks TASK_942")
	_assert(roadmap_text.contains("TASK_942 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Fix (implementiert"), "Roadmap marks TASK_942 implemented")
	_assert(roadmap_text.contains(NEXT_TASK), "Roadmap names TASK_943")
	_assert(contract_text.contains("Release-First-Exchange-Followup-Fix-Player-Polish-Final-Tuning-Followup-Fix (TASK_942)"), "Contract documents TASK_942")
	_assert(report_text.contains("TASK_942") and report_text.contains("TASK_943"), "HTML report tracks TASK_942 and TASK_943")
	_assert(service_text.contains(SCHEMA), "Service exposes stable TASK_942 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_942\""), "Service writes TASK_942 id")
	_assert(service_text.contains("SOURCE_GATE_TASK_ID: String = \"TASK_941\""), "Service links TASK_941")
	_assert(service_text.contains("SOURCE_FINDINGS_TASK_ID: String = \"TASK_940\""), "Service links TASK_940")
	_assert(service_text.contains("BASE_FINAL_TUNING_TASK_ID: String = \"TASK_938\""), "Service links TASK_938")
	_assert(service_text.contains("final_tuning_fire_lane_not_first_world_movement"), "Service requires primary issue")
	_assert(service_text.contains("followup_fix_player_polish_final_tuning_followup_lane_first"), "Service checks lane-first policy")
	_assert(controller_text.contains("RELEASE_FIRST_EXCHANGE_FOLLOWUP_FIX_PLAYER_POLISH_FINAL_TUNING_FOLLOWUP_FIX_SCRIPT"), "Controller preloads TASK_942 service")
	_assert(controller_text.contains("get_release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix_snapshot"), "Controller exposes TASK_942 snapshot")
	_assert(controller_text.contains("release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix"), "Controller sends TASK_942 payload")
	_assert(terrain_text.contains("RELEASE_FIRST_EXCHANGE_FOLLOWUP_FIX_PLAYER_POLISH_FINAL_TUNING_FOLLOWUP_FIX_STYLE_ID"), "Terrain declares TASK_942 style")
	_assert(terrain_text.contains("_is_release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix_active"), "Terrain detects TASK_942 payload")
	_assert(terrain_text.contains("followup_fix_player_polish_final_tuning_followup_fix_active"), "Terrain reports TASK_942 fire VFX flag")


func _test_helper_snapshot_passes() -> void:
	var service_resource: Resource = load(SERVICE_PATH)
	if service_resource == null:
		_assert(false, "TASK_942 service can be loaded")
		return
	var snapshot: Dictionary = Dictionary(service_resource.call("build_snapshot", _helper_source(), {}))
	var base: Dictionary = Dictionary(snapshot.get("base_final_tuning", {}))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Helper snapshot schema matches TASK_942")
	_assert(String(snapshot.get("task_id", "")) == "TASK_942", "Helper snapshot task id is TASK_942")
	_assert(String(snapshot.get("style_id", "")) == STYLE_ID, "Helper snapshot style id is stable")
	_assert(String(snapshot.get("source_gate_task_id", "")) == "TASK_941", "Helper links TASK_941")
	_assert(String(snapshot.get("source_findings_task_id", "")) == "TASK_940", "Helper links TASK_940")
	_assert(String(snapshot.get("base_final_tuning_task_id", "")) == "TASK_938", "Helper links TASK_938")
	_assert(String(snapshot.get("gate", "")) == "pass", "Helper snapshot passes")
	_assert(bool(snapshot.get("active", false)), "Helper snapshot active")
	_assert(bool(snapshot.get("source_gate_ready", false)), "Helper accepts TASK_941 follow-up gate")
	_assert(bool(snapshot.get("source_findings_ready", false)), "Helper accepts TASK_940 findings")
	_assert(bool(snapshot.get("base_final_tuning_ready", false)), "Helper accepts TASK_938 base")
	_assert(float(snapshot.get("world_combat_followup_fix_player_polish_final_tuning_followup_lane_width", 0.0)) > float(base.get("world_combat_followup_fix_player_polish_final_tuning_lane_width", 1.0)), "Helper sees wider TASK_942 lane")
	_assert(float(snapshot.get("world_combat_followup_fix_player_polish_final_tuning_followup_lane_alpha", 1.0)) < float(base.get("world_combat_followup_fix_player_polish_final_tuning_lane_alpha", 0.0)), "Helper sees quieter broad lane")
	_assert(float(snapshot.get("world_combat_followup_fix_player_polish_final_tuning_followup_core_width", 0.0)) > float(base.get("world_combat_followup_fix_player_polish_final_tuning_core_width", 1.0)), "Helper sees stronger TASK_942 core")
	_assert(float(snapshot.get("world_combat_followup_fix_player_polish_final_tuning_followup_target_halo_radius", 1.0)) < float(base.get("world_combat_followup_fix_player_polish_final_tuning_target_halo_radius", 0.0)), "Helper sees smaller TASK_942 halo")
	_assert(float(snapshot.get("world_combat_followup_fix_player_polish_final_tuning_followup_status_label_alpha", 1.0)) < float(base.get("world_combat_followup_fix_player_polish_final_tuning_status_label_alpha", 0.0)), "Helper sees quieter TASK_942 label")
	_assert(float(snapshot.get("world_combat_followup_fix_player_polish_final_tuning_followup_source_anchor_radius", 1.0)) <= 0.225, "Helper source anchor stays below disc threshold")
	_assert(float(snapshot.get("world_combat_followup_fix_player_polish_final_tuning_followup_target_anchor_radius", 1.0)) <= 0.225, "Helper target anchor stays below disc threshold")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Helper recommends TASK_943")
	_assert(_snapshot_is_read_only(snapshot), "Helper snapshot is read-only")


func _test_terrain_followup_fix_parameters() -> void:
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
		"release_first_exchange_followup_fix_player_polish_final_tuning": true,
		"release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix": true,
		"fire_event_dicts": [_build_fire_event()],
	})
	await _wait_frames(10)
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var entries: Array = Array(snapshot.get("weapon_fire_vfx_entries", []))
	var first_entry: Dictionary = Dictionary(entries[0]) if not entries.is_empty() else {}
	_assert(bool(snapshot.get("release_first_exchange_followup_fix_player_polish_final_tuning_active", false)), "Terrain keeps TASK_938 active")
	_assert(bool(snapshot.get("release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix_active", false)), "Terrain TASK_942 follow-up is active")
	_assert(String(snapshot.get("release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix_style_id", "")) == STYLE_ID, "Terrain reports TASK_942 style")
	_assert(float(snapshot.get("world_combat_followup_fix_player_polish_final_tuning_followup_lane_width", 0.0)) > float(snapshot.get("world_combat_followup_fix_player_polish_final_tuning_lane_width", 1.0)), "TASK_942 lane is wider than TASK_938")
	_assert(float(snapshot.get("world_combat_followup_fix_player_polish_final_tuning_followup_lane_alpha", 1.0)) < float(snapshot.get("world_combat_followup_fix_player_polish_final_tuning_lane_alpha", 0.0)), "TASK_942 broad lane is quieter than TASK_938")
	_assert(float(snapshot.get("world_combat_followup_fix_player_polish_final_tuning_followup_core_width", 0.0)) > float(snapshot.get("world_combat_followup_fix_player_polish_final_tuning_core_width", 1.0)), "TASK_942 core is wider than TASK_938")
	_assert(float(snapshot.get("world_combat_followup_fix_player_polish_final_tuning_followup_target_halo_radius", 1.0)) < float(snapshot.get("world_combat_followup_fix_player_polish_final_tuning_target_halo_radius", 0.0)), "TASK_942 target halo is smaller")
	_assert(float(snapshot.get("world_combat_followup_fix_player_polish_final_tuning_followup_status_label_alpha", 1.0)) < float(snapshot.get("world_combat_followup_fix_player_polish_final_tuning_status_label_alpha", 0.0)), "TASK_942 world label alpha is quieter")
	_assert(float(snapshot.get("world_combat_followup_fix_player_polish_final_tuning_followup_grid_noise_alpha", 1.0)) < float(snapshot.get("world_combat_followup_fix_player_polish_final_tuning_grid_noise_alpha", 0.0)), "TASK_942 grid noise is quieter")
	_assert(float(snapshot.get("world_combat_followup_fix_player_polish_final_tuning_followup_source_anchor_radius", 1.0)) <= 0.225, "TASK_942 source anchor stays below disc threshold")
	_assert(float(snapshot.get("world_combat_followup_fix_player_polish_final_tuning_followup_target_anchor_radius", 1.0)) <= 0.225, "TASK_942 target anchor stays below disc threshold")
	_assert(bool(first_entry.get("followup_fix_player_polish_final_tuning_active", false)), "Fire VFX entry keeps TASK_938 flag")
	_assert(bool(first_entry.get("followup_fix_player_polish_final_tuning_followup_fix_active", false)), "Fire VFX entry carries TASK_942 flag")
	_assert(String(first_entry.get("followup_fix_player_polish_final_tuning_followup_fix_style_id", "")) == STYLE_ID, "Fire VFX entry carries TASK_942 style")
	_assert(float(first_entry.get("trace_width", 0.0)) == float(first_entry.get("world_combat_followup_fix_player_polish_final_tuning_followup_core_width", -1.0)), "Fire VFX effective trace uses TASK_942 core")
	_assert(float(first_entry.get("fire_status_label_alpha", 1.0)) == float(snapshot.get("world_combat_followup_fix_player_polish_final_tuning_followup_status_label_alpha", -1.0)), "Fire VFX entry carries TASK_942 label alpha")
	_assert(_snapshot_is_read_only(snapshot), "Terrain TASK_942 snapshot stays read-only")
	primary_view.queue_free()
	await _wait_frames(2)


func _helper_source() -> Dictionary:
	return {
		"gate": {
			"schema": SOURCE_GATE_SCHEMA,
			"task_id": "TASK_941",
			"source_task_id": "TASK_940",
			"source_recapture_task_id": "TASK_939",
			"source_final_tuning_task_id": "TASK_938",
			"gate": "followup_fix_required",
			"followup_fix_required": true,
			"source_primary_issue_id": "final_tuning_fire_lane_not_first_world_movement",
			"recommended_next_task": "TASK_942 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Fix",
			"read_only": true,
			"creates_command": false,
			"creates_fire_event": false,
			"creates_damage_event": false,
			"creates_movement": false,
			"sets_multiplayer_truth": false,
		},
		"findings": {
			"schema": SOURCE_FINDINGS_SCHEMA,
			"task_id": "TASK_940",
			"source_task_id": "TASK_939",
			"source_final_tuning_task_id": "TASK_938",
			"status": "ready_for_followup_fix_player_polish_final_tuning_followup_fix",
			"primary_issue_id": "final_tuning_fire_lane_not_first_world_movement",
			"read_only": true,
		},
		"base_final_tuning": {
			"schema": "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning.v1",
			"task_id": "TASK_938",
			"style_id": BASE_STYLE_ID,
			"gate": "pass",
			"world_combat_followup_fix_player_polish_final_tuning_lane_width": 0.192,
			"world_combat_followup_fix_player_polish_final_tuning_lane_alpha": 0.172,
			"world_combat_followup_fix_player_polish_final_tuning_core_width": 0.156,
			"world_combat_followup_fix_player_polish_final_tuning_core_alpha": 1.0,
			"world_combat_followup_fix_player_polish_final_tuning_target_halo_radius": 0.032,
			"world_combat_followup_fix_player_polish_final_tuning_target_halo_alpha": 0.001,
			"world_combat_followup_fix_player_polish_final_tuning_source_anchor_radius": 0.222,
			"world_combat_followup_fix_player_polish_final_tuning_target_anchor_radius": 0.224,
			"world_combat_followup_fix_player_polish_final_tuning_status_label_alpha": 0.018,
			"world_combat_followup_fix_player_polish_final_tuning_status_label_offset_y": -154.0,
			"world_combat_followup_fix_player_polish_final_tuning_grid_noise_alpha": 0.048,
			"world_combat_followup_fix_player_polish_final_tuning_world_line_alpha_factor": 0.017,
			"read_only": true,
		},
		"primary_render_snapshot": {
			"release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix_active": true,
			"release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix_style_id": STYLE_ID,
			"world_combat_followup_fix_player_polish_final_tuning_followup_lane_width": 0.204,
			"world_combat_followup_fix_player_polish_final_tuning_followup_lane_alpha": 0.158,
			"world_combat_followup_fix_player_polish_final_tuning_followup_core_width": 0.168,
			"world_combat_followup_fix_player_polish_final_tuning_followup_core_alpha": 1.0,
			"world_combat_followup_fix_player_polish_final_tuning_followup_target_halo_radius": 0.024,
			"world_combat_followup_fix_player_polish_final_tuning_followup_target_halo_alpha": 0.0005,
			"world_combat_followup_fix_player_polish_final_tuning_followup_source_anchor_radius": 0.224,
			"world_combat_followup_fix_player_polish_final_tuning_followup_target_anchor_radius": 0.225,
			"world_combat_followup_fix_player_polish_final_tuning_followup_status_label_alpha": 0.010,
			"world_combat_followup_fix_player_polish_final_tuning_followup_status_label_offset_y": -166.0,
			"world_combat_followup_fix_player_polish_final_tuning_followup_grid_noise_alpha": 0.040,
			"world_combat_followup_fix_player_polish_final_tuning_followup_world_line_alpha_factor": 0.013,
			"weapon_fire_vfx_visual_count": 1,
			"weapon_fire_vfx_entries": [
				{
					"followup_fix_player_polish_final_tuning_followup_fix_active": true,
					"followup_fix_player_polish_final_tuning_followup_fix_style_id": STYLE_ID,
					"world_combat_followup_fix_player_polish_final_tuning_followup_core_width": 0.168,
					"fire_status_label_alpha": 0.010,
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
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_942_followup_fix_player_polish_final_tuning_followup", Vector2i(8, 8), Vector2.ZERO, 64.0, 32.0, 3)
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	return primary_view


func _build_fire_event() -> Dictionary:
	return {
		"event_id": "task_942_fire_001",
		"attacker_unit_id": "alpha_1",
		"target_unit_id": "enemy_1",
		"weapon_id": "rifle",
		"attacker_position": Vector2(96.0, 96.0),
		"target_position": Vector2(256.0, 192.0),
		"combat_outcome": "hit",
		"damage_resolved": 1,
		"hit_chance_resolved": 0.72,
		"source": "task_942_test_fixture",
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
