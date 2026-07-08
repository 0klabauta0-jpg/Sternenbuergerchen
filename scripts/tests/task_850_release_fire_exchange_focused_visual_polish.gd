extends SceneTree

const TASK_PATH := "res://docs/tasks/TASK_850_release_fire_exchange_focused_visual_polish.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH := "res://docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const TERRAIN_VIEW_PATH := "res://scripts/terrain/terrain_map_3d_view.gd"
const META_LAYER_SCRIPT_PATH := "res://scripts/meta/meta_layer_flow.gd"
const META_LAYER_SCENE_PATH := "res://scenes/meta/meta_layer_test.tscn"
const FIRST_GO_FIREFIGHT_ARG := "--release-singleplayer-first-go-firefight"
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const SCHEMA := "sternenbuergerchen.release_fire_exchange_focused_visual_polish.v1"
const STYLE_ID := "task_850_release_fire_exchange_focused_visual_polish_v1"
const DENSITY_MODE := "release_firefight_declutter"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_850 Release Fire Exchange Focused Visual Polish ===")
	_test_docs_and_static_hooks()
	await _test_terrain_focus_visual_parameters()
	await _test_meta_layer_focused_visual_polish()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_850_release_fire_exchange_focused_visual_polish: FAILED")
		quit(1)
		return
	print("TASK_850_release_fire_exchange_focused_visual_polish: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	var terrain_text: String = _read_text(TERRAIN_VIEW_PATH)
	var meta_text: String = _read_text(META_LAYER_SCRIPT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_850 task file exists")
	_assert(task_text.contains("Release Fire Exchange Focused Visual Polish"), "Task names focused visual polish")
	_assert(status_text.contains("TASK_850 - Release Fire Exchange Focused Visual Polish"), "Implementation status tracks TASK_850")
	_assert(roadmap_text.contains("TASK_850 - Release Fire Exchange Focused Visual Polish (implementiert)"), "Roadmap marks TASK_850 implemented")
	_assert(roadmap_text.contains("TASK_851 - Release Fire Exchange Focused Visual Recapture"), "Roadmap names TASK_851 follow-up")
	_assert(contract_text.contains("Release-Fire-Exchange-Focused-Visual-Polish"), "Contract documents TASK_850")
	_assert(report_text.contains("TASK_850") and report_text.contains("Focus-Visual"), "HTML report tracks TASK_850")
	_assert(controller_text.contains("get_release_fire_exchange_focused_visual_polish_snapshot"), "Tactical controller exposes TASK_850 snapshot")
	_assert(controller_text.contains("release_fire_exchange_focused_visual_polish"), "Tactical controller sends TASK_850 payload flag")
	_assert(terrain_text.contains("RELEASE_FIRE_EXCHANGE_FOCUSED_VISUAL_POLISH_STYLE_ID"), "TerrainMap3DView declares TASK_850 style id")
	_assert(terrain_text.contains("release_fire_exchange_focused_visual_polish_active"), "TerrainMap3DView reports active focus polish")
	_assert(terrain_text.contains("release_fire_exchange_world_line_dimming_active"), "TerrainMap3DView reports world-line dimming")
	_assert(terrain_text.contains("RELEASE_FIRE_EXCHANGE_FOCUSED_TRACE_WIDTH"), "TerrainMap3DView has focused trace width")
	_assert(meta_text.contains("get_release_fire_exchange_focused_visual_polish_snapshot"), "MetaLayer exposes TASK_850 wrapper")
	_assert(controller_text.contains("\"creates_fire_event\": false"), "TASK_850 declares no fire-event creation")
	_assert(controller_text.contains("\"creates_damage_event\": false"), "TASK_850 declares no damage-event creation")
	_assert(controller_text.contains("\"sets_multiplayer_truth\": false"), "TASK_850 declares no multiplayer truth mutation")


func _test_terrain_focus_visual_parameters() -> void:
	var primary_view: Node = _build_primary_view()
	primary_view.call("set_order_visual_payload", {
		"phase_index": 2,
		"world_label_density_mode": DENSITY_MODE,
		"release_fire_exchange_focused_visual_polish": true,
		"fire_event_dicts": [_build_fire_event()],
	})
	await _wait_frames(10)
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var entries: Array = Array(snapshot.get("weapon_fire_vfx_entries", []))
	var first_entry: Dictionary = Dictionary(entries[0]) if not entries.is_empty() else {}
	_assert(bool(snapshot.get("release_fire_exchange_focused_visual_polish_active", false)), "Terrain focus polish is active")
	_assert(String(snapshot.get("release_fire_exchange_focused_visual_polish_style_id", "")) == STYLE_ID, "Terrain snapshot reports TASK_850 style id")
	_assert(bool(snapshot.get("release_fire_exchange_fire_vfx_focus_active", false)), "Terrain snapshot reports fire VFX focus")
	_assert(bool(snapshot.get("release_fire_exchange_world_line_dimming_active", false)), "Terrain snapshot reports world line dimming")
	_assert(float(snapshot.get("release_fire_exchange_world_line_alpha_factor", 1.0)) < 1.0, "World line alpha factor dims auxiliary lines")
	_assert(int(snapshot.get("weapon_fire_vfx_visual_count", 0)) >= 1, "Focused terrain renders fire VFX")
	_assert(bool(first_entry.get("focused_visual_polish_active", false)), "Fire VFX entry is tagged as focused")
	_assert(String(first_entry.get("focused_visual_polish_style_id", "")) == STYLE_ID, "Fire VFX entry carries TASK_850 style id")
	_assert(float(first_entry.get("trace_width", 0.0)) > 0.012, "Focused trace is wider than base")
	_assert(float(first_entry.get("impact_radius", 0.0)) > 0.09, "Focused impact radius is larger than base")
	_assert(float(first_entry.get("target_focus_radius", 0.0)) > 0.16, "Focused target radius is larger than base")
	_assert(_snapshot_is_read_only(snapshot), "Terrain focused visual snapshot stays read-only")
	primary_view.queue_free()
	await _wait_frames(2)


func _test_meta_layer_focused_visual_polish() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := _instantiate_scene(META_LAYER_SCENE_PATH)
	_assert(scene != null, "MetaLayer scene instantiates")
	if scene == null:
		return
	await _wait_frames(10)
	_assert(scene.has_method("_apply_release_first_go_firefight_deeplink"), "MetaLayer exposes first GO/firefight apply hook")
	_assert(scene.has_method("get_release_fire_exchange_focused_visual_polish_snapshot"), "MetaLayer exposes TASK_850 callable")
	if not scene.has_method("_apply_release_first_go_firefight_deeplink") or not scene.has_method("get_release_fire_exchange_focused_visual_polish_snapshot"):
		scene.queue_free()
		await _wait_frames(1)
		return

	scene.call("_apply_release_first_go_firefight_deeplink", PackedStringArray([FIRST_GO_FIREFIGHT_ARG]))
	await _wait_frames(155)

	var snapshot: Dictionary = Dictionary(scene.call("get_release_fire_exchange_focused_visual_polish_snapshot"))
	var tactical: Dictionary = Dictionary(snapshot.get("tactical_focus", {}))
	var primary: Dictionary = Dictionary(tactical.get("primary_render_snapshot", {}))
	if String(snapshot.get("status", "")) != "pass" or String(tactical.get("gate", "")) != "pass":
		print("TASK_850_DIAGNOSTIC %s" % JSON.stringify({
			"meta_issues": snapshot.get("issues", []),
			"tactical_failed_checks": tactical.get("failed_checks", []),
			"style_id": tactical.get("style_id", ""),
			"focused_visual_polish_active": tactical.get("focused_visual_polish_active", false),
			"primary_focus_active": primary.get("release_fire_exchange_focused_visual_polish_active", false),
			"fire_vfx_count": tactical.get("weapon_fire_vfx_visual_count", 0),
		}))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Meta TASK_850 schema is stable")
	_assert(String(snapshot.get("task_id", "")) == "TASK_850", "Meta snapshot task id is TASK_850")
	_assert(String(snapshot.get("status", "")) == "pass", "Meta TASK_850 gate passes: %s" % JSON.stringify(snapshot.get("issues", [])))
	_assert(String(tactical.get("schema", "")) == SCHEMA, "Tactical TASK_850 schema is stable")
	_assert(String(tactical.get("style_id", "")) == STYLE_ID, "Tactical snapshot exposes TASK_850 style id")
	_assert(String(tactical.get("gate", "")) == "pass", "Tactical TASK_850 gate passes: %s" % JSON.stringify(tactical.get("failed_checks", [])))
	_assert(bool(tactical.get("focused_visual_polish_active", false)), "Focused visual polish is active")
	_assert(bool(tactical.get("world_line_dimming_active", false)), "World line dimming is active")
	_assert(bool(tactical.get("fire_vfx_focus_active", false)), "Fire VFX focus is active")
	_assert(float(tactical.get("trace_width", 0.0)) > 0.012, "Tactical snapshot reports wider trace")
	_assert(float(tactical.get("impact_radius", 0.0)) > 0.09, "Tactical snapshot reports larger impact")
	_assert(float(tactical.get("target_focus_radius", 0.0)) > 0.16, "Tactical snapshot reports larger target focus")
	_assert(bool(snapshot.get("read_only", false)), "Meta snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Meta snapshot does not set gameplay truth")
	_assert(not bool(tactical.get("creates_command", true)), "Tactical snapshot creates no commands")
	_assert(not bool(tactical.get("creates_fire_event", true)), "Tactical snapshot creates no fire events")
	_assert(not bool(tactical.get("creates_damage_event", true)), "Tactical snapshot creates no damage events")
	_assert(not bool(tactical.get("sets_multiplayer_truth", true)), "Tactical snapshot sets no multiplayer truth")

	scene.queue_free()
	await _wait_frames(2)


func _build_primary_view() -> Node:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_850_focus_visual", Vector2i(8, 8), Vector2.ZERO, 64.0, 32.0, 3)
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	return primary_view


func _build_fire_event() -> Dictionary:
	return {
		"event_id": "task_850_fire_001",
		"attacker_unit_id": "alpha_1",
		"target_unit_id": "enemy_1",
		"weapon_id": "rifle",
		"attacker_position": Vector2(96.0, 96.0),
		"target_position": Vector2(256.0, 192.0),
		"combat_outcome": "hit",
		"damage_resolved": 1,
		"hit_chance_resolved": 0.72,
		"source": "task_850_test_fixture",
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
