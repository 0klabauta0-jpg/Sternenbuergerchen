extends SceneTree

const Fix := preload("res://scripts/mission/release_first_exchange_final_world_read_followup_fix.gd")

const TASK_PATH := "res://docs/tasks/TASK_920_release_first_exchange_final_world_read_followup_fix.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH := "res://docs/reports/spielstand_zwischenbericht_task910_in_progress_2026_07_09.html"
const SERVICE_PATH := "res://scripts/mission/release_first_exchange_final_world_read_followup_fix.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const TERRAIN_VIEW_PATH := "res://scripts/terrain/terrain_map_3d_view.gd"
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const SCHEMA := "sternenbuergerchen.release_first_exchange_final_world_read_followup_fix.v1"
const STYLE_ID := "task_920_release_first_exchange_final_world_read_followup_v1"
const FINDINGS_SCHEMA := "sternenbuergerchen.release_first_exchange_final_world_read_visual_findings.v1"
const FINAL_SCHEMA := "sternenbuergerchen.release_first_exchange_fire_lane_world_read_final_polish.v1"
const FINAL_STYLE_ID := "task_916_release_first_exchange_fire_lane_world_read_final_v1"
const NEXT_TASK := "TASK_921 - Release First Exchange Followup World Read Recapture"
const DENSITY_MODE := "release_firefight_declutter"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_920 Release First Exchange Final World Read Followup Fix ===")
	_test_docs_and_static_hooks()
	_test_helper_snapshot_passes()
	await _test_terrain_followup_parameters()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_920_release_first_exchange_final_world_read_followup_fix: FAILED")
		quit(1)
		return
	print("TASK_920_release_first_exchange_final_world_read_followup_fix: ALL PASSED")
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
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_920 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_920 helper exists")
	_assert(controller_resource != null, "Controller script parses with TASK_920 hook")
	_assert(task_text.contains("Release First Exchange Final World Read Followup Fix"), "Task names TASK_920")
	_assert(task_text.contains(NEXT_TASK), "Task names TASK_921 follow-up")
	_assert(status_text.contains("TASK_920 - Release First Exchange Final World Read Followup Fix"), "Implementation status tracks TASK_920")
	_assert(roadmap_text.contains("TASK_920 - Release First Exchange Final World Read Followup Fix (implementiert"), "Roadmap marks TASK_920 implemented")
	_assert(roadmap_text.contains(NEXT_TASK), "Roadmap names TASK_921 follow-up")
	_assert(contract_text.contains("Release-First-Exchange-Final-World-Read-Followup-Fix (TASK_920)"), "Contract documents TASK_920")
	_assert(report_text.contains("TASK_920") and report_text.contains("Follow-up-Fix"), "HTML report tracks TASK_920")
	_assert(service_text.contains(SCHEMA), "Helper exposes stable TASK_920 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_920\""), "Helper writes TASK_920 id")
	_assert(service_text.contains("SOURCE_FINDINGS_TASK_ID: String = \"TASK_918\""), "Helper links TASK_918")
	_assert(service_text.contains("SOURCE_FINAL_TASK_ID: String = \"TASK_916\""), "Helper links TASK_916")
	_assert(service_text.contains("fire_lane_followup_first_read_strengthened"), "Helper checks follow-up lane")
	_assert(service_text.contains("label_halo_followup_retreat"), "Helper checks follow-up label/halo")
	_assert(service_text.contains("direction_anchors_followup_weight"), "Helper checks follow-up anchors")
	_assert(service_text.contains("\"creates_command\": false"), "Helper creates no commands")
	_assert(service_text.contains("\"creates_fire_event\": false"), "Helper creates no fire events")
	_assert(service_text.contains("\"creates_damage_event\": false"), "Helper creates no damage events")
	_assert(service_text.contains("\"creates_movement\": false"), "Helper creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Helper sets no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_EXCHANGE_FINAL_WORLD_READ_FOLLOWUP_FIX_SCRIPT"), "Controller preloads TASK_920 helper")
	_assert(controller_text.contains("get_release_first_exchange_final_world_read_followup_fix_snapshot"), "Controller exposes TASK_920 snapshot")
	_assert(controller_text.contains("release_first_exchange_final_world_read_followup_fix"), "Controller sends TASK_920 payload")
	_assert(terrain_text.contains("RELEASE_FIRST_EXCHANGE_FINAL_WORLD_READ_FOLLOWUP_STYLE_ID"), "Terrain declares TASK_920 style")
	_assert(terrain_text.contains("_is_release_first_exchange_final_world_read_followup_active"), "Terrain detects TASK_920 payload")
	_assert(terrain_text.contains("final_world_read_followup_fix_active"), "Terrain reports TASK_920 fire VFX flag")


func _test_helper_snapshot_passes() -> void:
	var snapshot: Dictionary = Fix.build_snapshot(_helper_source(), {})
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Helper snapshot schema matches TASK_920")
	_assert(String(snapshot.get("task_id", "")) == "TASK_920", "Helper snapshot task id is TASK_920")
	_assert(String(snapshot.get("style_id", "")) == STYLE_ID, "Helper snapshot style id is stable")
	_assert(String(snapshot.get("source_findings_schema", "")) == FINDINGS_SCHEMA, "Helper links TASK_918 schema")
	_assert(String(snapshot.get("source_final_schema", "")) == FINAL_SCHEMA, "Helper links TASK_916 schema")
	_assert(String(snapshot.get("source_final_style_id", "")) == FINAL_STYLE_ID, "Helper links TASK_916 style")
	_assert(String(snapshot.get("gate", "")) == "pass", "Helper snapshot passes")
	_assert(bool(snapshot.get("active", false)), "Helper snapshot active")
	_assert(bool(snapshot.get("findings_ready", false)), "Helper accepts TASK_918 finding")
	_assert(bool(snapshot.get("final_polish_ready", false)), "Helper accepts TASK_916 source path")
	_assert(int(snapshot.get("world_combat_final_world_read_followup_status_label_font_size", 99)) <= 8, "Helper sees smaller follow-up label")
	_assert(float(snapshot.get("world_combat_final_world_read_followup_status_label_alpha", 1.0)) < 0.18, "Helper sees quieter follow-up label")
	_assert(float(snapshot.get("world_combat_final_world_read_followup_status_label_offset_y", 0.0)) < -80.0, "Helper sees follow-up label farther from target")
	_assert(float(snapshot.get("world_combat_final_world_read_followup_lane_width", 0.0)) > 0.14, "Helper sees wider follow-up guide lane")
	_assert(float(snapshot.get("world_combat_final_world_read_followup_lane_alpha", 1.0)) <= 0.34, "Helper keeps follow-up guide lane soft")
	_assert(float(snapshot.get("world_combat_final_world_read_followup_core_width", 0.0)) > 0.085, "Helper sees stronger follow-up core width")
	_assert(float(snapshot.get("world_combat_final_world_read_followup_core_alpha", 0.0)) >= 1.0, "Helper sees follow-up core alpha")
	_assert(float(snapshot.get("world_combat_final_world_read_followup_target_halo_radius", 1.0)) < 0.13, "Helper sees smaller follow-up halo")
	_assert(float(snapshot.get("world_combat_final_world_read_followup_target_halo_alpha", 1.0)) < 0.02, "Helper sees quieter follow-up halo")
	_assert(float(snapshot.get("world_combat_final_world_read_followup_source_anchor_radius", 0.0)) > 0.168, "Helper sees stronger follow-up source anchor")
	_assert(float(snapshot.get("world_combat_final_world_read_followup_target_anchor_radius", 0.0)) > 0.17, "Helper sees stronger follow-up target anchor")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Helper recommends TASK_921")
	_assert(_snapshot_is_read_only(snapshot), "Helper snapshot is read-only")


func _test_terrain_followup_parameters() -> void:
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
		"fire_event_dicts": [_build_fire_event()],
	})
	await _wait_frames(10)
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var entries: Array = Array(snapshot.get("weapon_fire_vfx_entries", []))
	var first_entry: Dictionary = Dictionary(entries[0]) if not entries.is_empty() else {}
	_assert(bool(snapshot.get("release_first_exchange_fire_lane_world_read_final_polish_active", false)), "Terrain keeps TASK_916 final active")
	_assert(bool(snapshot.get("release_first_exchange_final_world_read_followup_fix_active", false)), "Terrain TASK_920 follow-up is active")
	_assert(String(snapshot.get("release_first_exchange_final_world_read_followup_fix_style_id", "")) == STYLE_ID, "Terrain reports TASK_920 style")
	_assert(float(snapshot.get("world_combat_final_world_read_followup_lane_width", 0.0)) > float(snapshot.get("world_combat_fire_lane_world_read_final_lane_width", 1.0)), "TASK_920 lane is wider than TASK_916")
	_assert(float(snapshot.get("world_combat_final_world_read_followup_lane_alpha", 1.0)) < float(snapshot.get("world_combat_fire_lane_world_read_final_lane_alpha", 0.0)), "TASK_920 lane stays softer than TASK_916")
	_assert(float(snapshot.get("world_combat_final_world_read_followup_core_width", 0.0)) > float(snapshot.get("world_combat_fire_lane_world_read_final_core_width", 1.0)), "TASK_920 core is wider than TASK_916")
	_assert(float(snapshot.get("world_combat_final_world_read_followup_core_alpha", 0.0)) >= float(snapshot.get("world_combat_fire_lane_world_read_final_core_alpha", 1.0)), "TASK_920 core is at least as bright as TASK_916")
	_assert(float(snapshot.get("world_combat_final_world_read_followup_target_halo_radius", 1.0)) < float(snapshot.get("world_combat_fire_lane_world_read_final_target_halo_radius", 0.0)), "TASK_920 target halo is smaller")
	_assert(float(snapshot.get("world_combat_final_world_read_followup_target_halo_alpha", 1.0)) < float(snapshot.get("world_combat_fire_lane_world_read_final_target_halo_alpha", 0.0)), "TASK_920 target halo is quieter")
	_assert(int(snapshot.get("world_combat_final_world_read_followup_status_label_font_size", 99)) < int(snapshot.get("world_combat_fire_lane_world_read_final_status_label_font_size", 0)), "TASK_920 world label font is smaller")
	_assert(float(snapshot.get("world_combat_final_world_read_followup_status_label_alpha", 1.0)) < float(snapshot.get("world_combat_fire_lane_world_read_final_status_label_alpha", 0.0)), "TASK_920 world label alpha is quieter")
	_assert(float(snapshot.get("world_combat_final_world_read_followup_status_label_offset_y", 0.0)) < float(snapshot.get("world_combat_fire_lane_world_read_final_status_label_offset_y", 0.0)), "TASK_920 world label moves farther from target")
	_assert(float(snapshot.get("tile_grid_line_effective_alpha", 1.0)) <= float(snapshot.get("world_combat_final_world_read_followup_grid_noise_alpha", 1.0)) + 0.001, "Terrain grid material alpha follows TASK_920 dimming")
	_assert(bool(first_entry.get("fire_lane_world_read_final_polish_active", false)), "Fire VFX entry keeps TASK_916 flag")
	_assert(bool(first_entry.get("final_world_read_followup_fix_active", false)), "Fire VFX entry carries TASK_920 flag")
	_assert(String(first_entry.get("final_world_read_followup_fix_style_id", "")) == STYLE_ID, "Fire VFX entry carries TASK_920 style")
	_assert(float(first_entry.get("trace_width", 0.0)) == float(first_entry.get("world_combat_final_world_read_followup_core_width", -1.0)), "Fire VFX effective trace uses TASK_920 core")
	_assert(float(first_entry.get("fire_status_label_alpha", 1.0)) < float(snapshot.get("world_combat_fire_lane_world_read_final_status_label_alpha", 0.0)), "Fire VFX entry carries quieter TASK_920 label alpha")
	_assert(int(first_entry.get("fire_status_label_font_size", 99)) < int(snapshot.get("world_combat_fire_lane_world_read_final_status_label_font_size", 0)), "Fire VFX entry carries smaller TASK_920 label font")
	_assert(_snapshot_is_read_only(snapshot), "Terrain TASK_920 snapshot stays read-only")
	primary_view.queue_free()
	await _wait_frames(2)


func _helper_source() -> Dictionary:
	return {
		"findings": {
			"schema": FINDINGS_SCHEMA,
			"task_id": "TASK_918",
			"source_task_id": "TASK_917",
			"source_final_task_id": "TASK_916",
			"status": "ready_for_final_world_read_followup_fix",
			"primary_issue_id": "fire_lane_not_first_world_movement_after_final_polish",
			"recommended_next_task": "TASK_920 - Release First Exchange Final World Read Followup Fix",
			"read_only": true,
		},
		"final_polish": {
			"schema": FINAL_SCHEMA,
			"task_id": "TASK_916",
			"style_id": FINAL_STYLE_ID,
			"gate": "pass",
			"world_combat_fire_lane_world_read_final_lane_width": 0.134,
			"world_combat_fire_lane_world_read_final_lane_alpha": 0.38,
			"world_combat_fire_lane_world_read_final_core_width": 0.078,
			"world_combat_fire_lane_world_read_final_core_alpha": 1.0,
			"world_combat_fire_lane_world_read_final_target_halo_radius": 0.13,
			"world_combat_fire_lane_world_read_final_target_halo_alpha": 0.022,
			"world_combat_fire_lane_world_read_final_source_anchor_radius": 0.158,
			"world_combat_fire_lane_world_read_final_target_anchor_radius": 0.164,
			"world_combat_fire_lane_world_read_final_status_label_font_size": 9,
			"world_combat_fire_lane_world_read_final_status_label_alpha": 0.22,
			"world_combat_fire_lane_world_read_final_status_label_offset_y": -72.0,
			"read_only": true,
		},
		"primary_render_snapshot": {
			"release_first_exchange_final_world_read_followup_fix_active": true,
			"release_first_exchange_final_world_read_followup_fix_style_id": STYLE_ID,
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
			"weapon_fire_vfx_visual_count": 1,
			"weapon_fire_vfx_entries": [
				{
					"final_world_read_followup_fix_active": true,
					"final_world_read_followup_fix_style_id": STYLE_ID,
					"world_combat_final_world_read_followup_lane_width": 0.146,
					"world_combat_final_world_read_followup_lane_alpha": 0.34,
					"world_combat_final_world_read_followup_core_width": 0.09,
					"world_combat_final_world_read_followup_core_alpha": 1.0,
					"world_combat_final_world_read_followup_target_halo_radius": 0.112,
					"world_combat_final_world_read_followup_target_halo_alpha": 0.016,
					"world_combat_final_world_read_followup_source_anchor_radius": 0.172,
					"world_combat_final_world_read_followup_target_anchor_radius": 0.176,
					"fire_status_label_font_size": 8,
					"fire_status_label_alpha": 0.15,
					"fire_status_label_offset_y": -86.0,
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
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_920_final_world_read_followup", Vector2i(8, 8), Vector2.ZERO, 64.0, 32.0, 3)
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	return primary_view


func _build_fire_event() -> Dictionary:
	return {
		"event_id": "task_920_fire_001",
		"attacker_unit_id": "alpha_1",
		"target_unit_id": "enemy_1",
		"weapon_id": "rifle",
		"attacker_position": Vector2(96.0, 96.0),
		"target_position": Vector2(256.0, 192.0),
		"combat_outcome": "hit",
		"damage_resolved": 1,
		"hit_chance_resolved": 0.72,
		"source": "task_920_test_fixture",
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
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
