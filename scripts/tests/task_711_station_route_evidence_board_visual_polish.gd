extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_711_station_route_evidence_board_visual_polish.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_refresh_2026_06_30.html"
const TASK_708_SCRIPT_PATH: String = "res://scripts/tests/task_708_station_route_visual_evidence.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_711 Station Route Evidence Board Visual Polish ===")
	_test_docs()
	_test_labeled_board_script_contract()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_711: FAILED")
		quit(1)
		return
	print("TASK_711: ALL PASSED")
	quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_711 task file exists")
	_assert(task_text.contains("Station Route Evidence Board Visual Polish"), "Task documents evidence board visual polish")
	_assert(contract_text.contains("Station Route Evidence Board Visual Polish"), "Interaction contract documents TASK_711")
	_assert(status_text.contains("TASK_711 - Station Route Evidence Board Visual Polish"), "Implementation status tracks TASK_711")
	_assert(roadmap_text.contains("TASK_711 - Station Route Evidence Board Visual Polish (implementiert)"), "Roadmap marks TASK_711 implemented")
	_assert(report_text.contains("TASK_711 - Station Route Evidence Board Visual Polish"), "Current report references TASK_711")
	_assert(report_text.contains('data-export-key="station_route_evidence_board_visual_polish.style_id"'), "Current report exports board style id")


func _test_labeled_board_script_contract() -> void:
	var script_text: String = _read_text(TASK_708_SCRIPT_PATH)
	_assert(script_text.contains("station_route_labeled_v1"), "TASK_708 exports labeled board style")
	_assert(script_text.contains("evidence_board_label_count"), "TASK_708 exports label count")
	_assert(script_text.contains("_draw_pixel_text"), "TASK_708 has pixel text renderer")
	_assert(script_text.contains("TASK 708 STATION ROUTE EVIDENCE"), "TASK_708 board has title label")
	_assert(script_text.contains("DOOR OPEN"), "TASK_708 board labels Door")
	_assert(script_text.contains("COMPUTER"), "TASK_708 board labels Computer")
	_assert(script_text.contains("CARGO"), "TASK_708 board labels Cargo")
	_assert(script_text.contains("MANUAL WINDOW REVIEW OPEN"), "TASK_708 board keeps manual review status visible")
	_assert(script_text.contains("read_only"), "TASK_708 still carries read-only manifest fields")
	_assert(script_text.contains("ui_sets_gameplay_truth"), "TASK_708 still carries UI truth guard")


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
