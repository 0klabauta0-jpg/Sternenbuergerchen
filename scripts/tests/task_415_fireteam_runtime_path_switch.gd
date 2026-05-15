extends SceneTree

const FIRETEAM_RUNTIME_EXECUTION_PATH_CONTRACT_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_runtime_execution_path_contract.gd")
const MISSION_TACTICAL_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")
const CONTRACT_DOC_PATH: String = "res://docs/dev/fireteam_runtime_execution_path_contract.md"
const TASK_PATH: String = "res://docs/tasks/TASK_415_fireteam_runtime_execution_path_switch.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const OVERVIEW_PATH: String = "res://docs/reports/fireteam_overview.html"
const ARCHITECTURE_PATH: String = "res://docs/ARCHITECTURE.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_415 Fireteam Runtime Execution Path Switch ===")
	_test_contract_snapshot_marks_mission_tactical_as_active_path()
	_test_mission_controller_exposes_runtime_path_snapshot()
	_test_docs_capture_path_decision()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_contract_snapshot_marks_mission_tactical_as_active_path() -> void:
	var snapshot: Dictionary = Dictionary(FIRETEAM_RUNTIME_EXECUTION_PATH_CONTRACT_SCRIPT.call("build_snapshot"))
	var validation: Dictionary = Dictionary(FIRETEAM_RUNTIME_EXECUTION_PATH_CONTRACT_SCRIPT.call("validate_snapshot", snapshot))
	_assert(bool(validation.get("valid", false)), "Contract snapshot validates")
	_assert(String(snapshot.get("active_path_id", "")) == FIRETEAM_RUNTIME_EXECUTION_PATH_CONTRACT_SCRIPT.ACTIVE_PATH_ID, "Mission-Tactical is the active visible fireteam path")
	_assert(String(snapshot.get("legacy_policy", "")) == FIRETEAM_RUNTIME_EXECUTION_PATH_CONTRACT_SCRIPT.LEGACY_POLICY, "RuntimeLeader/FTLTask is compatibility-adapter only")
	_assert(String(snapshot.get("runtime_authority", "")) == "SimulationRoot", "SimulationRoot remains runtime authority")
	_assert(String(snapshot.get("simulation_enqueue_method", "")) == "SimulationRoot.enqueue_command", "Commands still enter SimulationRoot queue")
	_assert(not bool(snapshot.get("ui_sets_unit_truth", true)), "UI does not set unit truth")
	_assert(not bool(snapshot.get("snapshots_are_truth", true)), "Snapshots are read-only, not truth")


func _test_mission_controller_exposes_runtime_path_snapshot() -> void:
	var controller = MISSION_TACTICAL_CONTROLLER_SCRIPT.new()
	var snapshot: Dictionary = Dictionary(controller.call("get_fireteam_runtime_execution_path_snapshot"))
	var validation: Dictionary = Dictionary(FIRETEAM_RUNTIME_EXECUTION_PATH_CONTRACT_SCRIPT.call("validate_snapshot", snapshot))
	_assert(bool(validation.get("valid", false)), "Mission controller runtime path snapshot validates")
	_assert(String(snapshot.get("command_entry_script", "")) == FIRETEAM_RUNTIME_EXECUTION_PATH_CONTRACT_SCRIPT.CONTROLLER_SCRIPT_PATH, "Mission controller reports its current script path")
	_assert(int(snapshot.get("selected_fireteam_count", -1)) == 0, "Runtime path snapshot includes selection count")
	_assert(int(snapshot.get("order_plan_count", -1)) == 0, "Runtime path snapshot includes order plan count")
	controller.free()


func _test_docs_capture_path_decision() -> void:
	var contract_doc: String = _read_text(CONTRACT_DOC_PATH)
	var task_doc: String = _read_text(TASK_PATH)
	var status_doc: String = _read_text(STATUS_PATH)
	var overview_doc: String = _read_text(OVERVIEW_PATH)
	var architecture_doc: String = _read_text(ARCHITECTURE_PATH)
	_assert(contract_doc.contains("Mission-Tactical-Pfad"), "Runtime path contract documents Mission-Tactical path")
	_assert(contract_doc.contains("compatibility_adapter_only"), "Runtime path contract documents legacy policy")
	_assert(task_doc.contains("TASK_415 - Fireteam Runtime Execution Path Switch"), "TASK_415 task file exists")
	_assert(status_doc.contains("TASK_415 - Fireteam Runtime Execution Path Switch"), "Implementation status documents TASK_415")
	_assert(overview_doc.contains("Entscheidung TASK_415"), "HTML overview names TASK_415 decision")
	_assert(overview_doc.contains("Offizieller Mission-Tactical-Pfad"), "HTML overview marks path B as official")
	_assert(architecture_doc.contains("TASK_415"), "Architecture notes the runtime path decision")


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
