extends SceneTree

const MISSION_SCENARIO_DATA_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_data.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const VERTICAL_SLICE_CONTRACT_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_vertical_slice_contract.gd")
const BRIEFING_MINIMAP_OVERLAY_PRESENTER_SCRIPT: GDScript = preload("res://scripts/mission/mission_briefing_minimap_overlay_presenter.gd")

const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const TASK_PATH: String = "res://docs/tasks/TASK_527_briefing_minimap_team_spawn_overlay.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_briefing_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const PRESENTER_PATH: String = "res://scripts/mission/mission_briefing_minimap_overlay_presenter.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_527 Briefing Minimap Team Spawn Overlay ===")
	_test_docs_and_wiring()
	_test_presenter_builds_team_spawn_overlays()
	_test_briefing_contract_stays_read_only()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_527: FAILED")
		quit(1)
		return
	print("TASK_527: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_527 task file exists")
	_assert(_read_text(TASK_PATH).contains("## Status: IMPLEMENTIERT"), "TASK_527 task file marks implementation")
	_assert(_read_text(STATUS_PATH).contains("TASK_527 - Briefing Minimap Team Spawn Overlay"), "Implementation status tracks TASK_527")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_527 - Briefing Minimap Team Spawn Overlay (implementiert)"), "Roadmap marks TASK_527 implemented")
	_assert(_read_text(CONTRACT_PATH).contains("Team-Spawn-Overlays"), "Briefing contract documents generated team spawn overlays")
	_assert(_read_text(REPORT_PATH).contains("TASK_527 - Briefing Minimap Team Spawn Overlay"), "Review workbench tracks TASK_527")
	_assert(FileAccess.file_exists(PRESENTER_PATH), "Briefing minimap overlay presenter exists")
	_assert(_read_text(PRESENTER_PATH).contains("team_spawn"), "Presenter emits team_spawn overlay entries")


func _test_presenter_builds_team_spawn_overlays() -> void:
	var presenter = BRIEFING_MINIMAP_OVERLAY_PRESENTER_SCRIPT.new()
	var snapshot: Dictionary = Dictionary(presenter.call("build_snapshot_from_files", SCENARIO_PATH, MAP_PATH, "multiplayer_pvp"))
	_assert(bool(snapshot.get("configured", false)), "Briefing minimap overlay snapshot is configured")
	_assert(bool(snapshot.get("valid", false)), "Briefing minimap overlay snapshot is valid")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Briefing minimap overlay remains read-only")
	_assert(String(snapshot.get("minimap_mode", "")) == "terrain_only", "Briefing minimap uses terrain-only mode")
	_assert(String(snapshot.get("terrain_source", "")) == "TerrainMapData", "Presenter reads marker positions from TerrainMapData")
	_assert(String(snapshot.get("team_source", "")) == "vertical_slice.team_slots", "Presenter derives team overlays from vertical slice")
	_assert(int(snapshot.get("briefing_annotation_count", 0)) >= 3, "Existing briefing annotations are preserved")
	_assert(int(snapshot.get("team_spawn_overlay_count", 0)) == 2, "Presenter emits Alpha and Bravo spawn overlays")
	var team_spawns: Array = Array(snapshot.get("team_spawn_overlays", []))
	var alpha: Dictionary = _find_entry(team_spawns, "team_alpha")
	var bravo: Dictionary = _find_entry(team_spawns, "team_bravo")
	_assert(String(alpha.get("target_id", "")) == "spawn_alpha", "Alpha overlay targets spawn_alpha")
	_assert(String(bravo.get("target_id", "")) == "spawn_bravo", "Bravo overlay targets spawn_bravo")
	_assert(String(alpha.get("team_color_hex", "")) == "#5fb7ff", "Alpha overlay keeps blue team color")
	_assert(String(bravo.get("team_color_hex", "")) == "#ff9b5e", "Bravo overlay keeps orange team color")
	_assert(String(alpha.get("text", "")).contains("ALPHA"), "Alpha overlay label is readable")
	_assert(String(bravo.get("text", "")).contains("BRAVO"), "Bravo overlay label is readable")
	_assert(bool(alpha.get("has_position", false)) and bool(bravo.get("has_position", false)), "Both team overlays resolve marker positions")
	_assert(_uv_in_bounds(Dictionary(alpha.get("minimap_position_uv", {}))), "Alpha minimap UV is normalized")
	_assert(_uv_in_bounds(Dictionary(bravo.get("minimap_position_uv", {}))), "Bravo minimap UV is normalized")
	_assert(Dictionary(alpha.get("world_position", {})).has("x"), "Alpha overlay exposes world position")
	_assert(Dictionary(bravo.get("world_position", {})).has("y"), "Bravo overlay exposes world position")
	_assert(Array(snapshot.get("entries", [])).size() >= int(snapshot.get("briefing_annotation_count", 0)) + int(snapshot.get("team_spawn_overlay_count", 0)), "Combined entries include annotations and team spawns")


func _test_briefing_contract_stays_read_only() -> void:
	var scenario = MISSION_SCENARIO_DATA_SCRIPT.call("load_from_file", SCENARIO_PATH)
	var terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", MAP_PATH)
	var vertical_slice: Dictionary = Dictionary(VERTICAL_SLICE_CONTRACT_SCRIPT.call("load_slice_from_file", SCENARIO_PATH))
	_assert(scenario != null, "Scenario loads for direct presenter call")
	_assert(terrain_map_data != null and not bool(terrain_map_data.call("has_load_issue")), "Terrain map loads for direct presenter call")
	_assert(not vertical_slice.is_empty(), "Vertical slice loads for direct presenter call")
	var presenter = BRIEFING_MINIMAP_OVERLAY_PRESENTER_SCRIPT.new()
	var snapshot: Dictionary = Dictionary(presenter.call("build_snapshot", scenario, terrain_map_data, vertical_slice, "multiplayer_pvp"))
	_assert(int(snapshot.get("team_spawn_overlay_count", 0)) == 2, "Direct presenter call also emits two team spawns")
	var briefing: Dictionary = Dictionary(scenario.call("get_briefing"))
	_assert(not _has_key_recursive(briefing, "tiles"), "Briefing still does not duplicate terrain tiles")
	_assert(not _has_key_recursive(briefing, "markers"), "Briefing still does not duplicate map markers")
	_assert(not _has_key_recursive(briefing, "patrol_paths"), "Briefing still does not duplicate patrol paths")
	_assert(not JSON.stringify(briefing).contains("team_spawn"), "Generated team_spawn entries are not stored as briefing truth")


func _find_entry(entries: Array, team_id: String) -> Dictionary:
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("team_id", "")) == team_id:
			return entry
	return {}


func _uv_in_bounds(uv: Dictionary) -> bool:
	if not uv.has("x") or not uv.has("y"):
		return false
	var x: float = float(uv.get("x", -1.0))
	var y: float = float(uv.get("y", -1.0))
	return x >= 0.0 and x <= 1.0 and y >= 0.0 and y <= 1.0


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
