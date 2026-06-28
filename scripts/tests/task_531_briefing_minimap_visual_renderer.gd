extends SceneTree

const BRIEFING_PANEL_PRESENTER_SCRIPT: GDScript = preload("res://scripts/mission/mission_briefing_panel_presenter.gd")
const BRIEFING_MINIMAP_VISUAL_PRESENTER_SCRIPT: GDScript = preload("res://scripts/mission/mission_briefing_minimap_visual_presenter.gd")
const BRIEFING_MINIMAP_OVERLAY_PRESENTER_SCRIPT: GDScript = preload("res://scripts/mission/mission_briefing_minimap_overlay_presenter.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const HOMEBASE_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")

const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const TASK_PATH: String = "res://docs/tasks/TASK_531_briefing_minimap_visual_renderer.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_briefing_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const HOMEBASE_PATH: String = "res://scripts/meta/homebase_screen.gd"
const VISUAL_PRESENTER_PATH: String = "res://scripts/mission/mission_briefing_minimap_visual_presenter.gd"
const VISUAL_CONTROL_PATH: String = "res://scripts/ui/mission_briefing_minimap_visual.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_531 Briefing Minimap Visual Renderer ===")
	_test_docs_and_wiring()
	_test_visual_presenter_builds_read_only_minimap_snapshot()
	_test_panel_presenter_embeds_visual_snapshot()
	await _test_homebase_renders_minimap_visual()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_531: FAILED")
		quit(1)
		return
	print("TASK_531: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_531 task file exists")
	_assert(_read_text(TASK_PATH).contains("## Status: IMPLEMENTIERT"), "TASK_531 task file marks implementation")
	_assert(_read_text(STATUS_PATH).contains("TASK_531 - Briefing Minimap Visual Renderer"), "Implementation status tracks TASK_531")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_531 - Briefing Minimap Visual Renderer (implementiert)"), "Roadmap marks TASK_531 implemented")
	_assert(_read_text(CONTRACT_PATH).contains("Briefing-Minimap-Visuals"), "Briefing contract documents minimap visuals")
	_assert(_read_text(REPORT_PATH).contains("TASK_531 - Briefing Minimap Visual Renderer"), "Review workbench tracks TASK_531")
	_assert(FileAccess.file_exists(VISUAL_PRESENTER_PATH), "Briefing minimap visual presenter exists")
	_assert(FileAccess.file_exists(VISUAL_CONTROL_PATH), "Briefing minimap visual control exists")
	_assert(_read_text(HOMEBASE_PATH).contains("BriefingMinimapVisual"), "Homebase screen creates minimap visual control")


func _test_visual_presenter_builds_read_only_minimap_snapshot() -> void:
	var terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", MAP_PATH)
	var overlay_snapshot: Dictionary = Dictionary(BRIEFING_MINIMAP_OVERLAY_PRESENTER_SCRIPT.new().call("build_snapshot_from_files", SCENARIO_PATH, MAP_PATH, "multiplayer_pvp"))
	var visual_snapshot: Dictionary = Dictionary(BRIEFING_MINIMAP_VISUAL_PRESENTER_SCRIPT.new().call("build_snapshot", terrain_map_data, overlay_snapshot))
	_assert(bool(visual_snapshot.get("configured", false)), "Visual minimap snapshot is configured")
	_assert(bool(visual_snapshot.get("valid", false)), "Visual minimap snapshot is valid")
	_assert(not bool(visual_snapshot.get("ui_sets_gameplay_truth", true)), "Visual minimap snapshot remains read-only")
	_assert(String(visual_snapshot.get("draw_mode", "")) == "coarse_terrain_samples", "Visual minimap uses coarse samples")
	_assert(int(visual_snapshot.get("sample_stride", 0)) >= 1, "Visual minimap exposes sample stride")
	_assert(int(visual_snapshot.get("sample_count", 0)) > 0, "Visual minimap exposes terrain samples")
	_assert(int(visual_snapshot.get("sample_count", 0)) < 36864, "Visual minimap does not duplicate every 192x192 tile")
	_assert(int(visual_snapshot.get("entry_count", 0)) >= 5, "Visual minimap includes briefing annotations and team spawns")
	_assert(_has_entry_kind(Array(visual_snapshot.get("overlay_entries", [])), "team_spawn"), "Visual minimap includes team spawn markers")
	_assert(_has_entry_kind(Array(visual_snapshot.get("overlay_entries", [])), "danger"), "Visual minimap includes danger marker")
	_assert(_has_entry_kind(Array(visual_snapshot.get("overlay_entries", [])), "objective"), "Visual minimap includes objective marker")
	_assert(not _has_key_recursive(visual_snapshot, "tiles"), "Visual minimap snapshot does not expose tiles key")
	_assert(not _has_key_recursive(visual_snapshot, "markers"), "Visual minimap snapshot does not expose markers key")


func _test_panel_presenter_embeds_visual_snapshot() -> void:
	var panel_snapshot: Dictionary = Dictionary(BRIEFING_PANEL_PRESENTER_SCRIPT.new().call("build_snapshot_from_files", SCENARIO_PATH, MAP_PATH, "multiplayer_pvp"))
	var visual_snapshot: Dictionary = Dictionary(panel_snapshot.get("minimap_visual_snapshot", {}))
	_assert(bool(visual_snapshot.get("configured", false)), "Panel presenter embeds configured visual snapshot")
	_assert(int(panel_snapshot.get("minimap_visual_sample_count", 0)) == int(visual_snapshot.get("sample_count", -1)), "Panel sample count mirrors visual snapshot")
	_assert(int(panel_snapshot.get("minimap_visual_entry_count", 0)) == int(visual_snapshot.get("entry_count", -1)), "Panel entry count mirrors visual snapshot")
	_assert(String(panel_snapshot.get("minimap_visual_source", "")) == "MissionBriefingMinimapVisualPresenter", "Panel declares visual presenter source")


func _test_homebase_renders_minimap_visual() -> void:
	var homebase: Node = HOMEBASE_SCENE.instantiate()
	root.add_child(homebase)
	await process_frame
	var catalog: Array = [
		{
			"mission_id": "frontier_probe_vertical_slice",
			"mission_name": "Operation: Frontier Probe Slice",
			"map_file_path": MAP_PATH,
			"scenario_file_path": SCENARIO_PATH,
			"slot_count": 8,
			"time_limit_seconds": 1500.0,
			"win_condition": "objective_capture",
		},
	]
	homebase.call("set_mission_context", catalog, MAP_PATH, "Operation: Frontier Probe Slice", 8, "frontier_probe_vertical_slice")
	await process_frame
	await process_frame
	var snapshot: Dictionary = Dictionary(homebase.call("get_mission_briefing_panel_snapshot"))
	_assert(bool(snapshot.get("rendered_minimap_visible", false)), "Homebase renders minimap visual control")
	_assert(int(snapshot.get("rendered_minimap_sample_count", 0)) > 0, "Homebase minimap visual has terrain samples")
	_assert(int(snapshot.get("rendered_minimap_entry_count", 0)) >= 5, "Homebase minimap visual has overlay entries")
	_assert(String(snapshot.get("rendered_minimap_draw_mode", "")) == "coarse_terrain_samples", "Homebase minimap visual keeps draw mode")
	homebase.queue_free()
	await process_frame


func _has_entry_kind(entries: Array, kind: String) -> bool:
	for entry_variant in entries:
		if String(Dictionary(entry_variant).get("kind", "")).strip_edges().to_lower() == kind:
			return true
	return false


func _has_key_recursive(value: Variant, key_needle: String) -> bool:
	var normalized_needle: String = key_needle.strip_edges().to_lower()
	if typeof(value) == TYPE_DICTIONARY:
		var value_dict: Dictionary = Dictionary(value)
		for key_variant in value_dict.keys():
			var key_text: String = String(key_variant).strip_edges().to_lower()
			if key_text == normalized_needle:
				return true
			if _has_key_recursive(value_dict.get(key_variant), normalized_needle):
				return true
	elif typeof(value) == TYPE_ARRAY:
		for item_variant in Array(value):
			if _has_key_recursive(item_variant, normalized_needle):
				return true
	return false


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
