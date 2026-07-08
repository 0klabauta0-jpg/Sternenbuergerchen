extends SceneTree

const TASK_PATH := "res://docs/tasks/TASK_842_release_firefight_insertion_residue_declutter.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const TERRAIN_VIEW_PATH := "res://scripts/terrain/terrain_map_3d_view.gd"
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const DENSITY_MODE := "release_firefight_declutter"
const STYLE_ID := "task_842_release_firefight_insertion_residue_declutter_v1"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_842 Release Firefight Insertion Residue Declutter ===")
	_test_docs_and_static_hooks()
	await _test_pre_go_dropship_visuals_remain_readable()
	await _test_firefight_declutter_suppresses_insertion_residue()
	await _test_cargo_touchdown_visuals_survive_firefight_declutter()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_842_release_firefight_insertion_residue_declutter: FAILED")
		quit(1)
		return
	print("TASK_842_release_firefight_insertion_residue_declutter: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var terrain_text: String = _read_text(TERRAIN_VIEW_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_842 task file exists")
	_assert(task_text.contains("Release Firefight Insertion Residue Declutter"), "Task names insertion residue declutter")
	_assert(status_text.contains("TASK_842 - Release Firefight Insertion Residue Declutter"), "Implementation status tracks TASK_842")
	_assert(roadmap_text.contains("TASK_842 - Release Firefight Insertion Residue Declutter (implementiert)"), "Roadmap marks TASK_842 implemented")
	_assert(roadmap_text.contains("TASK_843 - Release First Firefight Contact Framing"), "Roadmap keeps TASK_843 follow-up")
	_assert(contract_text.contains("Release-Firefight-Insertion-Residue-Declutter"), "Contract documents TASK_842")
	_assert(terrain_text.contains("RELEASE_FIREFIGHT_INSERTION_RESIDUE_DECLUTTER_STYLE_ID"), "TerrainMap3DView declares TASK_842 style id")
	_assert(terrain_text.contains("release_firefight_insertion_residue_declutter"), "TerrainMap3DView requires explicit insertion-residue flag")
	_assert(terrain_text.contains("_should_suppress_release_firefight_dropship_lz_label"), "TerrainMap3DView suppresses non-cargo LZ labels")
	_assert(terrain_text.contains("_should_suppress_release_firefight_dropship_approach_line"), "TerrainMap3DView suppresses non-cargo approach vectors")


func _test_pre_go_dropship_visuals_remain_readable() -> void:
	var primary_view: Node = _build_primary_view()
	primary_view.call("set_mission_drop_visual_state", _build_standard_drop_payload())
	await _wait_frames(10)
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(not bool(snapshot.get("release_firefight_insertion_residue_declutter_active", true)), "Default drop visuals are not in insertion-residue declutter")
	_assert(int(snapshot.get("dropship_lz_label_count", 0)) >= 1, "Default drop visuals keep LZ label")
	_assert(int(snapshot.get("dropship_approach_line_count", 0)) >= 1, "Default drop visuals keep approach line")
	_assert(int(snapshot.get("dropship_approach_arrow_count", 0)) >= 1, "Default drop visuals keep wide approach arrow")
	_assert(int(snapshot.get("requested_lz_marker_count", 0)) >= 1, "Default drop visuals keep LZ marker")
	_assert(int(snapshot.get("release_firefight_insertion_residue_suppressed_count", -1)) == 0, "Default drop visuals suppress no insertion residue")
	primary_view.queue_free()
	await _wait_frames(2)


func _test_firefight_declutter_suppresses_insertion_residue() -> void:
	var primary_view: Node = _build_primary_view()
	primary_view.call("set_mission_drop_visual_state", _build_standard_drop_payload())
	await _wait_frames(4)
	primary_view.call("set_order_visual_payload", {
		"phase_index": 2,
		"world_label_density_mode": DENSITY_MODE,
		"release_firefight_insertion_residue_declutter": true,
	})
	await _wait_frames(10)
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(bool(snapshot.get("release_firefight_insertion_residue_declutter_active", false)), "Firefight mode activates insertion-residue declutter")
	_assert(String(snapshot.get("release_firefight_insertion_residue_declutter_style_id", "")) == STYLE_ID, "Snapshot reports TASK_842 style id")
	_assert(int(snapshot.get("dropship_lz_label_count", -1)) == 0, "Firefight mode hides non-cargo LZ label")
	_assert(int(snapshot.get("dropship_approach_line_count", -1)) == 0, "Firefight mode hides non-cargo approach line")
	_assert(int(snapshot.get("dropship_approach_arrow_count", -1)) == 0, "Firefight mode hides non-cargo approach arrow")
	_assert(int(snapshot.get("release_firefight_insertion_residue_lz_label_suppressed_count", 0)) >= 1, "Snapshot counts suppressed LZ label")
	_assert(int(snapshot.get("release_firefight_insertion_residue_approach_line_suppressed_count", 0)) >= 1, "Snapshot counts suppressed approach line")
	_assert(int(snapshot.get("release_firefight_insertion_residue_suppressed_count", 0)) >= 2, "Snapshot counts insertion residue suppression")
	_assert(int(snapshot.get("requested_lz_marker_count", 0)) >= 1, "Firefight mode preserves LZ marker")
	_assert(int(snapshot.get("dropship_visual_count", 0)) >= 1, "Firefight mode preserves Dropship visual")
	_assert(_snapshot_is_read_only(snapshot), "Firefight insertion-residue snapshot stays read-only")
	primary_view.queue_free()
	await _wait_frames(2)


func _test_cargo_touchdown_visuals_survive_firefight_declutter() -> void:
	var primary_view: Node = _build_primary_view()
	primary_view.call("set_order_visual_payload", {
		"phase_index": 2,
		"world_label_density_mode": DENSITY_MODE,
		"release_firefight_insertion_residue_declutter": true,
	})
	primary_view.call("set_mission_drop_visual_state", _build_cargo_drop_payload())
	await _wait_frames(10)
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(bool(snapshot.get("release_firefight_insertion_residue_declutter_active", false)), "Cargo test runs in firefight insertion-residue declutter")
	_assert(int(snapshot.get("cargo_touchdown_approach_line_count", 0)) >= 1, "Cargo approach line survives declutter")
	_assert(int(snapshot.get("cargo_touchdown_label_count", 0)) >= 1, "Cargo status label survives declutter")
	_assert(int(snapshot.get("dropship_lz_label_count", 0)) >= 1, "Cargo LZ label survives declutter")
	_assert(int(snapshot.get("release_firefight_insertion_residue_suppressed_count", -1)) == 0, "Cargo visual is not counted as insertion residue")
	_assert(_snapshot_is_read_only(snapshot), "Cargo declutter snapshot stays read-only")
	primary_view.queue_free()
	await _wait_frames(2)


func _build_primary_view() -> Node:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_842_drop_declutter", Vector2i(8, 8), Vector2.ZERO, 64.0, 32.0, 3)
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	return primary_view


func _build_standard_drop_payload() -> Dictionary:
	var lz_position := Vector2(192.0, 160.0)
	var ship_position := Vector2(96.0, 64.0)
	return {
		"has_lz_position": true,
		"show_lz_marker": true,
		"lz_position": lz_position,
		"dropship_visible": true,
		"dropship_position": ship_position,
		"dropship_target_position": lz_position,
		"dropship_visuals": [{
			"craft_id": "dropship_alpha",
			"display_name": "Dropship Alpha",
			"state": "approach",
			"dropship_visible": true,
			"dropship_position": ship_position,
			"dropship_target_position": lz_position,
			"approach_vector_origin_position": ship_position,
			"approach_vector_target_position": lz_position,
			"approach_vector_shape": "wide_arrow",
			"show_approach_vector": true,
			"has_lz_position": true,
			"show_lz_marker": true,
			"lz_position": lz_position,
			"lz_label": "LZ1 Dropship Alpha",
		}],
	}


func _build_cargo_drop_payload() -> Dictionary:
	var lz_position := Vector2(224.0, 192.0)
	var ship_position := Vector2(96.0, 96.0)
	return {
		"has_lz_position": true,
		"show_lz_marker": true,
		"lz_position": lz_position,
		"dropship_visuals": [{
			"craft_id": "cargo_freighter",
			"display_name": "Cargo Freighter",
			"cargo_visual": true,
			"cargo_state": "inbound",
			"state": "inbound",
			"dropship_visible": true,
			"dropship_position": ship_position,
			"dropship_target_position": lz_position,
			"approach_vector_origin_position": ship_position,
			"approach_vector_target_position": lz_position,
			"approach_vector_shape": "wide_arrow",
			"show_approach_vector": true,
			"has_lz_position": true,
			"show_lz_marker": true,
			"lz_position": lz_position,
			"lz_label": "Cargo LZ",
		}],
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


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] %s" % message)
	else:
		_failed += 1
		push_error("[FAIL] %s" % message)
