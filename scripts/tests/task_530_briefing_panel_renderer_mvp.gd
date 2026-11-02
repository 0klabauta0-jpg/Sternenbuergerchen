extends SceneTree

const BRIEFING_PANEL_PRESENTER_SCRIPT: GDScript = preload("res://scripts/mission/mission_briefing_panel_presenter.gd")
const HOMEBASE_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")

const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const TASK_PATH: String = "res://docs/tasks/TASK_530_briefing_panel_renderer_mvp.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_briefing_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const HOMEBASE_PATH: String = "res://scripts/meta/homebase_screen.gd"
const PRESENTER_PATH: String = "res://scripts/mission/mission_briefing_panel_presenter.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_530 Briefing Panel Renderer MVP ===")
	_test_docs_and_wiring()
	_test_presenter_builds_read_only_panel_snapshot()
	await _test_homebase_renders_briefing_panel()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_530: FAILED")
		quit(1)
		return
	print("TASK_530: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_530 task file exists")
	_assert(_read_text(TASK_PATH).contains("## Status: IMPLEMENTIERT"), "TASK_530 task file marks implementation")
	_assert(_read_text(STATUS_PATH).contains("TASK_530 - Briefing Panel Renderer MVP"), "Implementation status tracks TASK_530")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_530 - Briefing Panel Renderer MVP (implementiert)"), "Roadmap marks TASK_530 implemented")
	_assert(_read_text(CONTRACT_PATH).contains("Briefing-Panel-Renderer"), "Briefing contract documents panel renderer")
	_assert(_read_text(REPORT_PATH).contains("TASK_530 - Briefing Panel Renderer MVP"), "Review workbench tracks TASK_530")
	_assert(FileAccess.file_exists(PRESENTER_PATH), "Briefing panel presenter exists")
	_assert(_read_text(HOMEBASE_PATH).contains("MissionBriefingPanel"), "Homebase screen creates briefing panel")


func _test_presenter_builds_read_only_panel_snapshot() -> void:
	var presenter = BRIEFING_PANEL_PRESENTER_SCRIPT.new()
	var snapshot: Dictionary = Dictionary(presenter.call("build_snapshot_from_files", SCENARIO_PATH, MAP_PATH, "multiplayer_pvp"))
	_assert(bool(snapshot.get("configured", false)), "Briefing panel snapshot is configured")
	_assert(bool(snapshot.get("valid", false)), "Briefing panel snapshot is valid")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Briefing panel snapshot remains read-only")
	_assert(String(snapshot.get("runtime_authority", "")) == "MissionBriefingPanelPresenter", "Presenter declares runtime authority")
	_assert(String(snapshot.get("title", "")) == "Operation Frontier Probe", "Snapshot exposes briefing title")
	_assert(String(snapshot.get("summary", "")).contains("Luftabwehr"), "Snapshot exposes briefing summary")
	_assert(int(snapshot.get("objective_count", 0)) == 3, "Snapshot exposes all briefing objectives")
	_assert(int(snapshot.get("threat_count", 0)) == 3, "Snapshot exposes all briefing threats")
	_assert(int(snapshot.get("recommended_loadout_count", 0)) == 2, "Snapshot exposes loadout recommendations")
	_assert(int(snapshot.get("team_spawn_overlay_count", 0)) == 2, "Snapshot exposes Alpha and Bravo team spawns")
	_assert(String(snapshot.get("objective_text", "")).contains("factory_danger_zone"), "Objectives retain target ids for readability")
	_assert(String(snapshot.get("team_spawn_text", "")).contains("[A] Alpha @ A-LZ"), "Team text includes Alpha compact spawn")
	_assert(String(snapshot.get("team_spawn_text", "")).contains("[B] Bravo @ B-LZ"), "Team text includes Bravo compact spawn")
	_assert(String(snapshot.get("loadout_text", "")).contains("rail_gun"), "Loadout text keeps canonical weapon ids")
	_assert(not _has_key_recursive(snapshot, "tiles"), "Panel snapshot does not duplicate terrain tiles")


func _test_homebase_renders_briefing_panel() -> void:
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
	_assert(homebase.has_method("get_mission_briefing_panel_snapshot"), "Homebase exposes briefing panel snapshot")
	var snapshot: Dictionary = Dictionary(homebase.call("get_mission_briefing_panel_snapshot"))
	_assert(not bool(snapshot.get("panel_visible", true)), "R4 initially folds the briefing details")
	var details_button := homebase.get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/R2BriefingDetailsButton") as Button
	_assert(details_button != null and details_button.text == "Briefingdetails", "Homebase exposes the real briefing-details action")
	if details_button != null:
		details_button.pressed.emit()
	await process_frame
	await process_frame
	snapshot = Dictionary(homebase.call("get_mission_briefing_panel_snapshot"))
	_assert(bool(snapshot.get("panel_visible", false)), "Homebase briefing panel is visible for scenario mission")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Homebase briefing panel remains read-only")
	_assert(String(snapshot.get("rendered_title_text", "")).contains("Operation Frontier Probe"), "Homebase renders briefing title")
	_assert(String(snapshot.get("rendered_objective_text", "")).contains("Luftabwehr ausschalten"), "Homebase renders objective text")
	_assert(String(snapshot.get("rendered_team_text", "")).contains("[A] Alpha"), "Homebase renders Alpha team spawn")
	_assert(String(snapshot.get("rendered_team_text", "")).contains("[B] Bravo"), "Homebase renders Bravo team spawn")
	homebase.queue_free()
	await process_frame


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
