extends SceneTree

const CONTRACT_PATH: String = "res://docs/dev/runtime_script_layout_contract.md"
const ARCHITECTURE_PATH: String = "res://docs/ARCHITECTURE.md"
const CODEX_RULES_PATH: String = "res://docs/CODEX_RULES.md"
const TASK_PATH: String = "res://docs/tasks/TASK_498_runtime_script_layout_alignment.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const SIMULATION_README_PATH: String = "res://scripts/simulation/README.md"
const SIMULATION_GITKEEP_PATH: String = "res://scripts/simulation/.gitkeep"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_498 Runtime Script Layout Alignment ===")
	_test_contract_documents_current_layout()
	_test_architecture_and_rules_point_to_contract()
	_test_simulation_folder_is_explained_but_inactive()
	_test_runtime_script_inventory_matches_decision()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_contract_documents_current_layout() -> void:
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(contract_text.contains("Runtime Script Layout Contract"), "Runtime script layout contract exists")
	_assert(contract_text.contains("`scripts/core/` bleibt") and contract_text.contains("Runtime-Kernpfad"), "Contract keeps scripts/core as the Runtime core path")
	_assert(contract_text.contains("`scripts/mission/`") and contract_text.contains("Contracts, Adapter und Bridges"), "Contract names scripts/mission for mission contracts and adapters")
	_assert(contract_text.contains("`scripts/tactical/`") and contract_text.contains("Resolver"), "Contract names scripts/tactical for tactical resolvers")
	_assert(contract_text.contains("`scripts/tests/`") and contract_text.contains("Verifier"), "Contract names scripts/tests for verifiers and harnesses")
	_assert(contract_text.contains("`scripts/simulation/`") and contract_text.contains("inaktiver, reservierter Pfad"), "Contract marks scripts/simulation as inactive/reserved")


func _test_architecture_and_rules_point_to_contract() -> void:
	var architecture_text: String = _read_text(ARCHITECTURE_PATH)
	var rules_text: String = _read_text(CODEX_RULES_PATH)
	_assert(architecture_text.contains("## Script-Layout"), "Architecture has a Script-Layout section")
	_assert(architecture_text.contains("runtime_script_layout_contract.md"), "Architecture points to the runtime script layout contract")
	_assert(rules_text.contains("runtime_script_layout_contract.md"), "CODEX rules point to the runtime script layout contract")
	_assert(rules_text.contains("Runtime-Kern nach `scripts/core/`"), "CODEX rules route new Runtime work to scripts/core")
	_assert(rules_text.contains("Neue produktive Skripte nicht unter `scripts/simulation/`"), "CODEX rules block productive scripts in scripts/simulation")


func _test_simulation_folder_is_explained_but_inactive() -> void:
	var readme_text: String = _read_text(SIMULATION_README_PATH)
	_assert(readme_text.contains("kein aktiver Produktionspfad"), "scripts/simulation README explains the inactive folder")
	_assert(readme_text.contains("`res://scripts/core/`"), "scripts/simulation README points to scripts/core")
	_assert(readme_text.contains("Neue produktive Skripte nicht hier ablegen"), "scripts/simulation README blocks new productive scripts")
	_assert(not FileAccess.file_exists(SIMULATION_GITKEEP_PATH), "scripts/simulation no longer uses a vague .gitkeep placeholder")
	_assert(_count_gd_files("res://scripts/simulation") == 0, "scripts/simulation contains no productive GDScript files")


func _test_runtime_script_inventory_matches_decision() -> void:
	var core_count: int = _count_gd_files("res://scripts/core")
	var mission_count: int = _count_gd_files("res://scripts/mission")
	var tactical_count: int = _count_gd_files("res://scripts/tactical")
	var simulation_count: int = _count_gd_files("res://scripts/simulation")

	_assert(core_count >= 6, "scripts/core contains the current Runtime core inventory")
	_assert(mission_count >= 4, "scripts/mission contains mission contracts/adapters")
	_assert(tactical_count >= 10, "scripts/tactical contains tactical resolver/controller inventory")
	_assert(simulation_count == 0, "scripts/simulation remains free of productive .gd scripts")


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	_assert(task_text.contains("TASK_498 - Runtime Script Layout Alignment"), "TASK_498 task file exists")
	_assert(task_text.contains("docs/dev/runtime_script_layout_contract.md"), "TASK_498 task references the new layout contract")
	_assert(status_text.contains("TASK_498 - Runtime Script Layout Alignment"), "Implementation status documents TASK_498")
	_assert(status_text.contains("scripts/simulation/"), "Implementation status records the scripts/simulation decision")


func _count_gd_files(path: String) -> int:
	var dir := DirAccess.open(path)
	if dir == null:
		return 0

	var count: int = 0
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name != "." and file_name != "..":
			var child_path: String = "%s/%s" % [path, file_name]
			if dir.current_is_dir():
				count += _count_gd_files(child_path)
			elif file_name.ends_with(".gd"):
				count += 1
		file_name = dir.get_next()
	dir.list_dir_end()
	return count


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
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
