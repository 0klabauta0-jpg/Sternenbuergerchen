extends SceneTree

const TEAM_OWNERSHIP_CONTRACT_SCRIPT: GDScript = preload("res://scripts/mission/mission_multiplayer_team_ownership_contract.gd")
const MISSION_TEAM_CHIP_PRESENTER_SCRIPT: GDScript = preload("res://scripts/mission/mission_team_chip_presenter.gd")
const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_526_mission_hud_team_chip_polish.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const TEAM_OWNERSHIP_PATH: String = "res://scripts/mission/mission_multiplayer_team_ownership_contract.gd"
const MULTIPLAYER_SESSION_PATH: String = "res://scripts/multiplayer/multiplayer_session.gd"
const PRESENTER_PATH: String = "res://scripts/mission/mission_team_chip_presenter.gd"
const MISSION_CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_526 Mission HUD Team Chip Polish ===")
	_test_docs_and_wiring()
	_test_default_slice_is_shared()
	_test_presenter_builds_read_only_team_chips()
	await _test_mission_hud_renders_team_chip_label()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_526: FAILED")
		quit(1)
		return
	print("TASK_526: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_526 task file exists")
	_assert(_read_text(TASK_PATH).contains("## Status: IMPLEMENTIERT"), "TASK_526 task file marks implementation")
	_assert(_read_text(STATUS_PATH).contains("TASK_526 - Mission HUD Team Chip Polish"), "Implementation status tracks TASK_526")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_526 - Mission HUD Team Chip Polish (implementiert)"), "Roadmap marks TASK_526 implemented")
	_assert(_read_text(REPORT_PATH).contains("TASK_526 - Mission HUD Team Chip Polish"), "Review workbench tracks TASK_526")
	_assert(_read_text(TEAM_OWNERSHIP_PATH).contains("build_default_team_readability_slice"), "Ownership contract exposes shared default team slice")
	_assert(_read_text(MULTIPLAYER_SESSION_PATH).contains("build_default_team_readability_slice"), "MultiplayerSession uses shared team slice")
	_assert(FileAccess.file_exists(PRESENTER_PATH), "Mission team chip presenter exists")
	_assert(_read_text(MISSION_CONTROLLER_PATH).contains("MISSION_TEAM_CHIP_LABEL_PATH"), "Mission controller defines team chip label path")
	_assert(_read_text(MISSION_CONTROLLER_PATH).contains("get_mission_team_chip_snapshot"), "Mission controller exposes team chip snapshot")


func _test_default_slice_is_shared() -> void:
	var slice: Dictionary = Dictionary(TEAM_OWNERSHIP_CONTRACT_SCRIPT.call("build_default_team_readability_slice"))
	var team_slots: Array = Array(slice.get("team_slots", []))
	_assert(PackedStringArray(slice.get("play_modes", PackedStringArray())).has("multiplayer_pvp"), "Default team slice includes PvP play mode")
	_assert(team_slots.size() == 2, "Default team slice has Alpha and Bravo slots")
	var alpha: Dictionary = Dictionary(team_slots[0])
	var bravo: Dictionary = Dictionary(team_slots[1])
	_assert(String(alpha.get("team_id", "")) == "team_alpha", "Default team slice starts with Alpha")
	_assert(String(alpha.get("spawn_marker_id", "")) == "spawn_alpha", "Default team slice keeps Alpha spawn")
	_assert(String(bravo.get("team_id", "")) == "team_bravo", "Default team slice contains Bravo")
	_assert(String(bravo.get("spawn_marker_id", "")) == "spawn_bravo", "Default team slice keeps Bravo spawn")
	_assert(bool(bravo.get("npc_owned", false)), "Default team slice keeps Bravo NPC-owned outside PvP")


func _test_presenter_builds_read_only_team_chips() -> void:
	var presenter = MISSION_TEAM_CHIP_PRESENTER_SCRIPT.new()
	var snapshot: Dictionary = Dictionary(presenter.call("build_snapshot", {
		"peer_teams": {
			1: "team_alpha",
			2: "team_bravo",
		},
	}))
	var chips: Array = Array(snapshot.get("chips", []))
	_assert(bool(snapshot.get("configured", false)), "Presenter snapshot is configured")
	_assert(bool(snapshot.get("valid", false)), "Presenter snapshot is valid")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Presenter snapshot remains read-only")
	_assert(String(snapshot.get("play_mode", "")) == "multiplayer_pvp", "Presenter infers PvP from Peer2 Bravo")
	_assert(int(snapshot.get("chip_count", 0)) >= 2, "Presenter exposes at least two chips")
	var alpha: Dictionary = _find_chip(chips, "team_alpha")
	var bravo: Dictionary = _find_chip(chips, "team_bravo")
	_assert(String(alpha.get("chip_text", "")).contains("Host Peer 1"), "Alpha chip names host owner")
	_assert(String(alpha.get("spawn_marker_id", "")) == "spawn_alpha", "Alpha chip exposes spawn marker")
	_assert(String(bravo.get("chip_text", "")).contains("Peer 2"), "Bravo chip names peer owner")
	_assert(String(bravo.get("spawn_marker_id", "")) == "spawn_bravo", "Bravo chip exposes spawn marker")
	_assert(String(snapshot.get("status_text", "")).contains("Alpha") and String(snapshot.get("status_text", "")).contains("Bravo"), "Status text names both teams")


func _test_mission_hud_renders_team_chip_label() -> void:
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
		_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Mission HUD team chip snapshot remains read-only")
		_assert(int(snapshot.get("chip_count", 0)) >= 2, "Mission HUD exposes both team chips")
		_assert(String(snapshot.get("status_text", "")).contains("Host Peer 1"), "Mission HUD status names host owner")
		_assert(String(snapshot.get("status_text", "")).contains("Peer 2"), "Mission HUD status names peer owner")
		_assert(String(snapshot.get("status_text", "")).contains("spawn_alpha"), "Mission HUD status names Alpha spawn")
		_assert(String(snapshot.get("status_text", "")).contains("spawn_bravo"), "Mission HUD status names Bravo spawn")
	if controller != null and controller.has_method("get_command_feedback_snapshot"):
		var command_snapshot: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
		_assert(String(command_snapshot.get("mission_team_chip_text", "")).contains("P2"), "Command snapshot exposes compact mission team chip label text")
		_assert(Dictionary(command_snapshot.get("mission_team_chip", {})).has("chips"), "Command snapshot exposes mission team chip data")
	if label != null:
		_assert(label.text.contains("Alpha") and label.text.contains("Bravo"), "Mission HUD label text names both teams")
		_assert(label.text.contains("Host") and label.text.contains("P2"), "Mission HUD label text names compact owners")
		_assert(not label.text.contains("Host Peer 1"), "Mission HUD label keeps the long owner text in tooltip/status")
	mission.queue_free()
	await process_frame


func _find_chip(chips: Array, team_id: String) -> Dictionary:
	for chip_variant in chips:
		var chip: Dictionary = Dictionary(chip_variant)
		if String(chip.get("team_id", "")) == team_id:
			return chip
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
