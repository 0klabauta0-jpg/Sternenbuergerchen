extends SceneTree

const PlayerPolish := preload("res://scripts/mission/release_first_exchange_followup_world_read_player_polish.gd")

const TASK_PATH := "res://docs/tasks/TASK_923_release_first_exchange_followup_world_read_player_polish.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH := "res://docs/reports/spielstand_zwischenbericht_task910_in_progress_2026_07_09.html"
const SERVICE_PATH := "res://scripts/mission/release_first_exchange_followup_world_read_player_polish.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const TERRAIN_VIEW_PATH := "res://scripts/terrain/terrain_map_3d_view.gd"
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const SCHEMA := "sternenbuergerchen.release_first_exchange_followup_world_read_player_polish.v1"
const STYLE_ID := "task_923_release_first_exchange_followup_world_read_player_v1"
const FINDINGS_SCHEMA := "sternenbuergerchen.release_first_exchange_followup_world_read_visual_findings.v1"
const FOLLOWUP_SCHEMA := "sternenbuergerchen.release_first_exchange_final_world_read_followup_fix.v1"
const FOLLOWUP_STYLE_ID := "task_920_release_first_exchange_final_world_read_followup_v1"
const NEXT_TASK := "TASK_924 - Release First Exchange Followup Player Polish Recapture"
const DENSITY_MODE := "release_firefight_declutter"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_923 Release First Exchange Followup World Read Player Polish ===")
	_test_docs_and_static_hooks()
	_test_helper_snapshot_passes()
	await _test_terrain_player_polish_parameters()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_923_release_first_exchange_followup_world_read_player_polish: FAILED")
		quit(1)
		return
	print("TASK_923_release_first_exchange_followup_world_read_player_polish: ALL PASSED")
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
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_923 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_923 helper exists")
	_assert(controller_resource != null, "Controller script parses with TASK_923 hook")
	_assert(task_text.contains("Release First Exchange Followup World Read Player Polish"), "Task names TASK_923")
	_assert(task_text.contains(NEXT_TASK), "Task names TASK_924 recapture")
	_assert(status_text.contains("TASK_923 - Release First Exchange Followup World Read Player Polish"), "Implementation status tracks TASK_923")
	_assert(roadmap_text.contains("TASK_923 - Release First Exchange Followup World Read Player Polish (implementiert"), "Roadmap marks TASK_923 implemented")
	_assert(roadmap_text.contains(NEXT_TASK), "Roadmap names TASK_924")
	_assert(contract_text.contains("Release-First-Exchange-Followup-World-Read-Player-Polish (TASK_923)"), "Contract documents TASK_923")
	_assert(report_text.contains("TASK_923") and report_text.contains("Player-Polish"), "HTML report tracks TASK_923")
	_assert(service_text.contains(SCHEMA), "Helper exposes stable TASK_923 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_923\""), "Helper writes TASK_923 id")
	_assert(service_text.contains("SOURCE_FINDINGS_TASK_ID: String = \"TASK_922\""), "Helper links TASK_922")
	_assert(service_text.contains("SOURCE_FOLLOWUP_TASK_ID: String = \"TASK_920\""), "Helper links TASK_920")
	_assert(service_text.contains("fire_lane_player_read_strengthened"), "Helper checks player-polish lane")
	_assert(service_text.contains("label_halo_player_retreat"), "Helper checks player-polish label/halo")
	_assert(service_text.contains("direction_anchors_player_weight"), "Helper checks player-polish anchors")
	_assert(controller_text.contains("RELEASE_FIRST_EXCHANGE_FOLLOWUP_WORLD_READ_PLAYER_POLISH_SCRIPT"), "Controller preloads TASK_923 helper")
	_assert(controller_text.contains("get_release_first_exchange_followup_world_read_player_polish_snapshot"), "Controller exposes TASK_923 snapshot")
	_assert(controller_text.contains("release_first_exchange_followup_world_read_player_polish"), "Controller sends TASK_923 payload")
	_assert(terrain_text.contains("RELEASE_FIRST_EXCHANGE_FOLLOWUP_WORLD_READ_PLAYER_STYLE_ID"), "Terrain declares TASK_923 style")
	_assert(terrain_text.contains("_is_release_first_exchange_followup_world_read_player_active"), "Terrain detects TASK_923 payload")
	_assert(terrain_text.contains("followup_world_read_player_polish_active"), "Terrain reports TASK_923 fire VFX flag")


func _test_helper_snapshot_passes() -> void:
	var snapshot: Dictionary = PlayerPolish.build_snapshot(_helper_source(), {})
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Helper snapshot schema matches TASK_923")
	_assert(String(snapshot.get("task_id", "")) == "TASK_923", "Helper snapshot task id is TASK_923")
	_assert(String(snapshot.get("style_id", "")) == STYLE_ID, "Helper snapshot style id is stable")
	_assert(String(snapshot.get("source_findings_schema", "")) == FINDINGS_SCHEMA, "Helper links TASK_922 schema")
	_assert(String(snapshot.get("source_followup_schema", "")) == FOLLOWUP_SCHEMA, "Helper links TASK_920 schema")
	_assert(String(snapshot.get("source_followup_style_id", "")) == FOLLOWUP_STYLE_ID, "Helper links TASK_920 style")
	_assert(String(snapshot.get("gate", "")) == "pass", "Helper snapshot passes")
	_assert(bool(snapshot.get("active", false)), "Helper snapshot active")
	_assert(bool(snapshot.get("findings_ready", false)), "Helper accepts TASK_922 finding")
	_assert(bool(snapshot.get("followup_fix_ready", false)), "Helper accepts TASK_920 source path")
	_assert(float(snapshot.get("world_combat_followup_player_lane_width", 0.0)) > float(snapshot.get("followup_fix", {}).get("world_combat_final_world_read_followup_lane_width", 1.0)), "Helper sees wider player lane")
	_assert(float(snapshot.get("world_combat_followup_player_lane_alpha", 1.0)) <= float(snapshot.get("followup_fix", {}).get("world_combat_final_world_read_followup_lane_alpha", 0.0)), "Helper keeps player lane soft")
	_assert(float(snapshot.get("world_combat_followup_player_core_width", 0.0)) > float(snapshot.get("followup_fix", {}).get("world_combat_final_world_read_followup_core_width", 1.0)), "Helper sees stronger player core")
	_assert(float(snapshot.get("world_combat_followup_player_target_halo_radius", 1.0)) < float(snapshot.get("followup_fix", {}).get("world_combat_final_world_read_followup_target_halo_radius", 0.0)), "Helper sees smaller player halo")
	_assert(float(snapshot.get("world_combat_followup_player_status_label_alpha", 1.0)) < float(snapshot.get("followup_fix", {}).get("world_combat_final_world_read_followup_status_label_alpha", 0.0)), "Helper sees quieter player label")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Helper recommends TASK_924")
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
		"fire_event_dicts": [_build_fire_event()],
	})
	await _wait_frames(10)
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var entries: Array = Array(snapshot.get("weapon_fire_vfx_entries", []))
	var first_entry: Dictionary = Dictionary(entries[0]) if not entries.is_empty() else {}
	_assert(bool(snapshot.get("release_first_exchange_final_world_read_followup_fix_active", false)), "Terrain keeps TASK_920 active")
	_assert(bool(snapshot.get("release_first_exchange_followup_world_read_player_polish_active", false)), "Terrain TASK_923 player polish is active")
	_assert(String(snapshot.get("release_first_exchange_followup_world_read_player_polish_style_id", "")) == STYLE_ID, "Terrain reports TASK_923 style")
	_assert(float(snapshot.get("world_combat_followup_player_lane_width", 0.0)) > float(snapshot.get("world_combat_final_world_read_followup_lane_width", 1.0)), "TASK_923 lane is wider than TASK_920")
	_assert(float(snapshot.get("world_combat_followup_player_lane_alpha", 1.0)) <= float(snapshot.get("world_combat_final_world_read_followup_lane_alpha", 0.0)), "TASK_923 lane stays soft")
	_assert(float(snapshot.get("world_combat_followup_player_core_width", 0.0)) > float(snapshot.get("world_combat_final_world_read_followup_core_width", 1.0)), "TASK_923 core is wider than TASK_920")
	_assert(float(snapshot.get("world_combat_followup_player_core_alpha", 0.0)) >= float(snapshot.get("world_combat_final_world_read_followup_core_alpha", 1.0)), "TASK_923 core is at least as bright as TASK_920")
	_assert(float(snapshot.get("world_combat_followup_player_target_halo_radius", 1.0)) < float(snapshot.get("world_combat_final_world_read_followup_target_halo_radius", 0.0)), "TASK_923 target halo is smaller")
	_assert(float(snapshot.get("world_combat_followup_player_target_halo_alpha", 1.0)) < float(snapshot.get("world_combat_final_world_read_followup_target_halo_alpha", 0.0)), "TASK_923 target halo is quieter")
	_assert(float(snapshot.get("world_combat_followup_player_status_label_alpha", 1.0)) < float(snapshot.get("world_combat_final_world_read_followup_status_label_alpha", 0.0)), "TASK_923 world label alpha is quieter")
	_assert(float(snapshot.get("world_combat_followup_player_status_label_offset_y", 0.0)) < float(snapshot.get("world_combat_final_world_read_followup_status_label_offset_y", 0.0)), "TASK_923 world label moves farther from target")
	_assert(float(snapshot.get("tile_grid_line_effective_alpha", 1.0)) <= float(snapshot.get("world_combat_followup_player_grid_noise_alpha", 1.0)) + 0.001, "Terrain grid material alpha follows TASK_923 dimming")
	_assert(bool(first_entry.get("final_world_read_followup_fix_active", false)), "Fire VFX entry keeps TASK_920 flag")
	_assert(bool(first_entry.get("followup_world_read_player_polish_active", false)), "Fire VFX entry carries TASK_923 flag")
	_assert(String(first_entry.get("followup_world_read_player_polish_style_id", "")) == STYLE_ID, "Fire VFX entry carries TASK_923 style")
	_assert(float(first_entry.get("trace_width", 0.0)) == float(first_entry.get("world_combat_followup_player_core_width", -1.0)), "Fire VFX effective trace uses TASK_923 core")
	_assert(float(first_entry.get("fire_status_label_alpha", 1.0)) == float(snapshot.get("world_combat_followup_player_status_label_alpha", -1.0)), "Fire VFX entry carries TASK_923 label alpha")
	_assert(_snapshot_is_read_only(snapshot), "Terrain TASK_923 snapshot stays read-only")
	primary_view.queue_free()
	await _wait_frames(2)


func _helper_source() -> Dictionary:
	return {
		"findings": {
			"schema": FINDINGS_SCHEMA,
			"task_id": "TASK_922",
			"source_task_id": "TASK_921",
			"source_followup_task_id": "TASK_920",
			"status": "ready_for_followup_world_read_player_polish",
			"primary_issue_id": "followup_fire_lane_not_first_world_movement",
			"recommended_next_task": "TASK_923 - Release First Exchange Followup World Read Player Polish",
			"read_only": true,
		},
		"followup_fix": {
			"schema": FOLLOWUP_SCHEMA,
			"task_id": "TASK_920",
			"style_id": FOLLOWUP_STYLE_ID,
			"gate": "pass",
			"world_combat_final_world_read_followup_lane_width": 0.146,
			"world_combat_final_world_read_followup_lane_alpha": 0.34,
			"world_combat_final_world_read_followup_core_width": 0.09,
			"world_combat_final_world_read_followup_core_alpha": 1.0,
			"world_combat_final_world_read_followup_target_halo_radius": 0.112,
			"world_combat_final_world_read_followup_target_halo_alpha": 0.016,
			"world_combat_final_world_read_followup_source_anchor_radius": 0.172,
			"world_combat_final_world_read_followup_target_anchor_radius": 0.176,
			"world_combat_final_world_read_followup_status_label_font_size": 8,
			"world_combat_final_world_read_followup_status_label_alpha": 0.15,
			"world_combat_final_world_read_followup_status_label_offset_y": -86.0,
			"read_only": true,
		},
		"primary_render_snapshot": {
			"release_first_exchange_followup_world_read_player_polish_active": true,
			"release_first_exchange_followup_world_read_player_polish_style_id": STYLE_ID,
			"world_combat_followup_player_lane_width": 0.154,
			"world_combat_followup_player_lane_alpha": 0.30,
			"world_combat_followup_player_core_width": 0.102,
			"world_combat_followup_player_core_alpha": 1.0,
			"world_combat_followup_player_target_halo_radius": 0.096,
			"world_combat_followup_player_target_halo_alpha": 0.010,
			"world_combat_followup_player_source_anchor_radius": 0.186,
			"world_combat_followup_player_target_anchor_radius": 0.190,
			"world_combat_followup_player_status_label_font_size": 7,
			"world_combat_followup_player_status_label_alpha": 0.10,
			"world_combat_followup_player_status_label_offset_y": -96.0,
			"weapon_fire_vfx_visual_count": 1,
			"weapon_fire_vfx_entries": [
				{
					"followup_world_read_player_polish_active": true,
					"followup_world_read_player_polish_style_id": STYLE_ID,
					"world_combat_followup_player_lane_width": 0.154,
					"world_combat_followup_player_lane_alpha": 0.30,
					"world_combat_followup_player_core_width": 0.102,
					"world_combat_followup_player_core_alpha": 1.0,
					"world_combat_followup_player_target_halo_radius": 0.096,
					"world_combat_followup_player_target_halo_alpha": 0.010,
					"world_combat_followup_player_source_anchor_radius": 0.186,
					"world_combat_followup_player_target_anchor_radius": 0.190,
					"fire_status_label_font_size": 7,
					"fire_status_label_alpha": 0.10,
					"fire_status_label_offset_y": -96.0,
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
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_923_followup_world_read_player", Vector2i(8, 8), Vector2.ZERO, 64.0, 32.0, 3)
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	return primary_view


func _build_fire_event() -> Dictionary:
	return {
		"event_id": "task_923_fire_001",
		"attacker_unit_id": "alpha_1",
		"target_unit_id": "enemy_1",
		"weapon_id": "rifle",
		"attacker_position": Vector2(96.0, 96.0),
		"target_position": Vector2(256.0, 192.0),
		"combat_outcome": "hit",
		"damage_resolved": 1,
		"hit_chance_resolved": 0.72,
		"source": "task_923_test_fixture",
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
