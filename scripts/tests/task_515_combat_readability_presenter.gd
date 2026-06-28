extends SceneTree

const PRESENTER_SCRIPT: GDScript = preload("res://scripts/tactical/combat_readability_presenter.gd")

const PRESENTER_PATH: String = "res://scripts/tactical/combat_readability_presenter.gd"
const DRIVER_PATH: String = "res://scripts/tests/mission_combat_loop_driver.gd"
const TASK_PATH: String = "res://docs/tasks/TASK_515_combat_readability_presenter.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_515 Combat Readability Presenter ===")
	_test_presenter_creates_and_removes_readability_nodes()
	_test_status_event_and_winner_formatting()
	_test_contact_line_and_visibility()
	_test_source_boundaries()
	_test_docs_reference_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_presenter_creates_and_removes_readability_nodes() -> void:
	var scene_root := Node2D.new()
	get_root().add_child(scene_root)
	var presenter = PRESENTER_SCRIPT.new()

	presenter.call("ensure_nodes", scene_root, false)
	var snapshot: Dictionary = Dictionary(presenter.call("get_presenter_snapshot"))
	_assert(bool(snapshot.get("contact_line_ready", false)), "Presenter creates contact line")
	_assert(bool(snapshot.get("event_label_ready", false)), "Presenter creates event label")
	_assert(bool(snapshot.get("winner_label_ready", false)), "Presenter creates winner label")
	_assert(scene_root.get_node_or_null("CombatContactLine") is Line2D, "Contact line is a Line2D child")
	_assert(scene_root.get_node_or_null("CombatEventLabel") is Label, "Event label is a Label child")
	_assert(scene_root.get_node_or_null("CombatWinnerLabel") is Label, "Winner label is a Label child")

	presenter.call("remove_nodes")
	snapshot = Dictionary(presenter.call("get_presenter_snapshot"))
	_assert(not bool(snapshot.get("contact_line_ready", true)), "Presenter clears contact line reference")
	_assert(not bool(snapshot.get("event_label_ready", true)), "Presenter clears event label reference")
	_assert(not bool(snapshot.get("winner_label_ready", true)), "Presenter clears winner label reference")
	scene_root.free()


func _test_status_event_and_winner_formatting() -> void:
	var scene_root := Node2D.new()
	get_root().add_child(scene_root)
	var status_label := Label.new()
	scene_root.add_child(status_label)
	var presenter = PRESENTER_SCRIPT.new()
	presenter.call("ensure_nodes", scene_root, false)

	var context: Dictionary = {
		"win_condition": "objective_defense",
		"combat_finished": false,
		"winning_team_id": "",
		"enemy_fit_count": 3,
		"friendly_fit_count": 4,
		"duration_seconds": 12.25,
		"objective_status_text": "Objective: held",
		"wave_status_text": "Waves: none",
		"show_hold_timer": true,
		"objective_defense_elapsed_seconds": 8.0,
		"objective_defense_hold_seconds": 30.0,
		"attack_readiness_text": "ready",
		"last_event_text": "ENGAGE",
		"last_contact": {"attacker_id": "alpha", "target_id": "enemy_delta"},
	}

	presenter.call("update_status_label", status_label, "contact", context, true, false)
	_assert(status_label.visible, "Status label is visible outside preview")
	_assert(status_label.text.contains("Combat: contact"), "Status label includes state")
	_assert(status_label.text.contains("Hold timer: 8.0s / 30.0s"), "Status label includes defense hold timer")
	_assert(status_label.text.contains("Last contact: alpha -> enemy_delta"), "Status label includes last contact")

	presenter.call("update_event_label", "ENGAGE")
	var event_label := scene_root.get_node("CombatEventLabel") as Label
	_assert(event_label.text == "Event: ENGAGE", "Event label text is delegated")

	presenter.call("update_winner_label", {
		"combat_finished": true,
		"winning_team_id": "alpha",
		"result": "victory",
		"win_condition_type": "objective_defense",
	})
	var winner_label := scene_root.get_node("CombatWinnerLabel") as Label
	_assert(winner_label.text.contains("VICTORY"), "Winner label uppercases result")
	_assert(winner_label.text.contains("Winner: alpha"), "Winner label includes winning team")

	presenter.call("update_status_label", status_label, "preview", context, true, true)
	_assert(not status_label.visible, "Preview mode hides status label")
	scene_root.free()


func _test_contact_line_and_visibility() -> void:
	var scene_root := Node2D.new()
	get_root().add_child(scene_root)
	var status_label := Label.new()
	scene_root.add_child(status_label)
	var attacker := Node2D.new()
	var target := Node2D.new()
	attacker.position = Vector2(10, 20)
	target.position = Vector2(80, 100)
	scene_root.add_child(attacker)
	scene_root.add_child(target)
	var presenter = PRESENTER_SCRIPT.new()
	presenter.call("ensure_nodes", scene_root, false)

	presenter.call("set_contact_line", attacker, target)
	var contact_line := scene_root.get_node("CombatContactLine") as Line2D
	_assert(contact_line.get_point_count() == 2, "Contact line has attacker and target points")
	_assert(contact_line.get_point_position(0) == Vector2(10, 20), "Contact line starts at attacker")
	_assert(contact_line.get_point_position(1) == Vector2(80, 100), "Contact line ends at target")

	presenter.call("apply_overlay_visibility", status_label, false, false)
	_assert(not status_label.visible, "Overlay visibility hides status label")
	_assert(not contact_line.visible, "Overlay visibility hides contact line")

	presenter.call("apply_overlay_visibility", status_label, true, true)
	_assert(not status_label.visible, "Preview mode keeps status label hidden")
	_assert(not contact_line.visible, "Preview mode keeps contact line hidden")

	presenter.call("clear_contact_line")
	_assert(contact_line.get_point_count() == 0, "Contact line clears without touching gameplay state")
	scene_root.free()


func _test_source_boundaries() -> void:
	var presenter_source: String = _read_text(PRESENTER_PATH)
	var driver_source: String = _read_text(DRIVER_PATH)
	_assert(presenter_source.contains("class_name CombatReadabilityPresenter"), "Presenter exists under scripts/tactical")
	_assert(not presenter_source.contains("enqueue_command") and not presenter_source.contains("enqueue_effect"), "Presenter does not mutate command or effect queues")
	_assert(not presenter_source.contains("SimulationRoot"), "Presenter does not reference SimulationRoot authority")
	_assert(not presenter_source.contains("set_contact_state"), "Presenter does not own unit contact state")
	_assert(driver_source.contains("COMBAT_READABILITY_PRESENTER_SCRIPT"), "Combat driver preloads readability presenter")
	_assert(driver_source.contains("update_status_label"), "Combat driver delegates status label formatting")
	_assert(driver_source.contains("set_contact_line"), "Combat driver delegates contact line drawing")
	_assert(not driver_source.contains("Line2D.new()"), "Combat driver no longer creates contact Line2D")
	_assert(not driver_source.contains("Label.new()"), "Combat driver no longer creates readability labels")


func _test_docs_reference_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(task_text.contains("TASK_515 - Combat Readability Presenter"), "TASK_515 task file exists")
	_assert(roadmap_text.contains("TASK_515 - Combat Readability Presenter"), "Roadmap lists TASK_515")
	_assert(status_text.contains("TASK_515 - Combat Readability Presenter"), "Implementation status lists TASK_515")
	_assert(report_text.contains("TASK_515 - Combat Readability Presenter"), "Review report references TASK_515")


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
