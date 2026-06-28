extends SceneTree

const MISSION_TEAM_CHIP_PRESENTER_SCRIPT: GDScript = preload("res://scripts/mission/mission_team_chip_presenter.gd")
const BRIEFING_MINIMAP_OVERLAY_PRESENTER_SCRIPT: GDScript = preload("res://scripts/mission/mission_briefing_minimap_overlay_presenter.gd")
const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const TASK_PATH: String = "res://docs/tasks/TASK_529_mission_hud_team_icon_polish.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const MISSION_TEAM_PRESENTER_PATH: String = "res://scripts/mission/mission_team_chip_presenter.gd"
const BRIEFING_PRESENTER_PATH: String = "res://scripts/mission/mission_briefing_minimap_overlay_presenter.gd"
const MISSION_CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_529 Mission HUD Team Icon Polish ===")
	_test_docs_and_wiring()
	_test_team_chip_presenter_exposes_compact_icons()
	_test_briefing_overlay_exposes_matching_icons()
	await _test_mission_hud_uses_compact_team_text()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_529: FAILED")
		quit(1)
		return
	print("TASK_529: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_529 task file exists")
	_assert(_read_text(TASK_PATH).contains("## Status: IMPLEMENTIERT"), "TASK_529 task file marks implementation")
	_assert(_read_text(STATUS_PATH).contains("TASK_529 - Mission HUD Team Icon Polish"), "Implementation status tracks TASK_529")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_529 - Mission HUD Team Icon Polish (implementiert)"), "Roadmap marks TASK_529 implemented")
	_assert(_read_text(REPORT_PATH).contains("TASK_529 - Mission HUD Team Icon Polish"), "Review workbench tracks TASK_529")
	_assert(_read_text(MISSION_TEAM_PRESENTER_PATH).contains("compact_status_text"), "Mission team presenter exposes compact status")
	_assert(_read_text(BRIEFING_PRESENTER_PATH).contains("compact_label"), "Briefing overlay presenter exposes compact labels")
	_assert(_read_text(MISSION_CONTROLLER_PATH).contains("compact_status_text"), "Mission HUD label reads compact status")


func _test_team_chip_presenter_exposes_compact_icons() -> void:
	var presenter = MISSION_TEAM_CHIP_PRESENTER_SCRIPT.new()
	var snapshot: Dictionary = Dictionary(presenter.call("build_snapshot", {
		"peer_teams": {
			1: "team_alpha",
			2: "team_bravo",
		},
	}))
	var chips: Array = Array(snapshot.get("chips", []))
	var alpha: Dictionary = _find_chip(chips, "team_alpha")
	var bravo: Dictionary = _find_chip(chips, "team_bravo")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Team chip snapshot remains read-only")
	_assert(String(snapshot.get("status_text", "")).contains("spawn_alpha"), "Legacy status text keeps full spawn marker")
	_assert(String(snapshot.get("compact_status_text", "")).contains("[A]"), "Compact status has Alpha icon")
	_assert(String(snapshot.get("compact_status_text", "")).contains("[B]"), "Compact status has Bravo icon")
	_assert(String(snapshot.get("compact_status_text", "")).length() < String(snapshot.get("status_text", "")).length(), "Compact status is shorter than legacy status")
	_assert(String(alpha.get("icon_text", "")) == "[A]", "Alpha chip exposes icon text")
	_assert(String(bravo.get("icon_text", "")) == "[B]", "Bravo chip exposes icon text")
	_assert(String(alpha.get("spawn_icon_text", "")) == "A-LZ", "Alpha chip exposes compact spawn icon")
	_assert(String(bravo.get("spawn_icon_text", "")) == "B-LZ", "Bravo chip exposes compact spawn icon")
	_assert(String(alpha.get("compact_text", "")).contains("Host Peer 1"), "Alpha compact text keeps owner readability")
	_assert(String(bravo.get("compact_text", "")).contains("Peer 2"), "Bravo compact text keeps owner readability")
	_assert(String(alpha.get("icon_tooltip", "")).contains("spawn_alpha"), "Alpha tooltip keeps full marker")
	_assert(String(bravo.get("icon_tooltip", "")).contains("spawn_bravo"), "Bravo tooltip keeps full marker")
	_assert(int(alpha.get("visual_priority", 0)) < int(bravo.get("visual_priority", 0)), "Alpha sorts before Bravo visually")


func _test_briefing_overlay_exposes_matching_icons() -> void:
	var presenter = BRIEFING_MINIMAP_OVERLAY_PRESENTER_SCRIPT.new()
	var snapshot: Dictionary = Dictionary(presenter.call("build_snapshot_from_files", SCENARIO_PATH, MAP_PATH, "multiplayer_pvp"))
	var team_spawns: Array = Array(snapshot.get("team_spawn_overlays", []))
	var alpha: Dictionary = _find_entry(team_spawns, "team_alpha")
	var bravo: Dictionary = _find_entry(team_spawns, "team_bravo")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Briefing overlay snapshot remains read-only")
	_assert(String(alpha.get("icon_text", "")) == "[A]", "Alpha briefing overlay exposes icon")
	_assert(String(bravo.get("icon_text", "")) == "[B]", "Bravo briefing overlay exposes icon")
	_assert(String(alpha.get("compact_label", "")) == "[A] Alpha", "Alpha briefing overlay exposes compact label")
	_assert(String(bravo.get("compact_label", "")) == "[B] Bravo", "Bravo briefing overlay exposes compact label")
	_assert(String(alpha.get("compact_text", "")).contains("A-LZ"), "Alpha briefing overlay exposes compact spawn text")
	_assert(String(bravo.get("compact_text", "")).contains("B-LZ"), "Bravo briefing overlay exposes compact spawn text")
	_assert(String(alpha.get("icon_tooltip", "")).contains("spawn_alpha"), "Alpha briefing tooltip keeps full marker")
	_assert(String(bravo.get("icon_tooltip", "")).contains("spawn_bravo"), "Bravo briefing tooltip keeps full marker")
	_assert(int(alpha.get("visual_priority", 0)) < int(bravo.get("visual_priority", 0)), "Briefing visual priority keeps Alpha before Bravo")


func _test_mission_hud_uses_compact_team_text() -> void:
	var mission: Node = MISSION_TEST_SCENE.instantiate()
	var simulation_root: Node = mission.get_node_or_null("SimulationRoot")
	_assert(simulation_root != null, "Mission scene contains SimulationRoot")
	if simulation_root != null and simulation_root.has_method("set_peer_team_assignments"):
		simulation_root.call("set_peer_team_assignments", {
			1: "team_alpha",
			2: "team_bravo",
		})
	root.add_child(mission)
	await process_frame
	await process_frame
	var controller: Node = mission.get_node_or_null("TacticalController")
	_assert(controller != null, "Mission scene contains TacticalController")
	var label := mission.get_node_or_null("TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/MissionTeamChipLabel") as Label
	_assert(label != null, "Mission HUD creates team chip label")
	if controller != null and controller.has_method("get_mission_team_chip_snapshot"):
		var snapshot: Dictionary = Dictionary(controller.call("get_mission_team_chip_snapshot"))
		_assert(String(snapshot.get("compact_status_text", "")).contains("[A]"), "Mission snapshot exposes compact Alpha status")
		_assert(String(snapshot.get("compact_status_text", "")).contains("[B]"), "Mission snapshot exposes compact Bravo status")
		_assert(String(snapshot.get("compact_status_text", "")).length() < String(snapshot.get("status_text", "")).length(), "Mission compact status is shorter than full status")
	if label != null:
		_assert(label.text.contains("[A]") and label.text.contains("[B]"), "Mission HUD label uses compact team icons")
		_assert(label.text.contains("Host Peer 1") and label.text.contains("Peer 2"), "Mission HUD compact label keeps owner labels")
		_assert(label.text.contains("A-LZ") and label.text.contains("B-LZ"), "Mission HUD compact label uses compact spawn labels")
		_assert(not label.text.contains("spawn_alpha") and not label.text.contains("spawn_bravo"), "Mission HUD compact label hides verbose spawn marker ids")
	mission.queue_free()
	await process_frame


func _find_chip(chips: Array, team_id: String) -> Dictionary:
	for chip_variant in chips:
		var chip: Dictionary = Dictionary(chip_variant)
		if String(chip.get("team_id", "")) == team_id:
			return chip
	return {}


func _find_entry(entries: Array, team_id: String) -> Dictionary:
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("team_id", "")) == team_id:
			return entry
	return {}


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
