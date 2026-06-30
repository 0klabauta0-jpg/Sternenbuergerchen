extends SceneTree

const MARKER_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_marker_catalog.gd")

const TASK_DOC_PATH: String = "res://docs/tasks/TASK_673_mission_interaction_point_contract.md"
const INTERACTION_CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const WORKFLOW_CONTRACT_PATH: String = "res://docs/dev/map_editor_asset_workflow_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_673 Mission Interaction Point Contract ===")
	_test_docs()
	_test_marker_catalog()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_DOC_PATH)
	var contract_text: String = _read_text(INTERACTION_CONTRACT_PATH)
	_assert(FileAccess.file_exists(TASK_DOC_PATH), "TASK_673 task file exists")
	_assert(task_text.contains("Mission Interaction Point Contract"), "Task documents mission interaction point contract")
	_assert(FileAccess.file_exists(INTERACTION_CONTRACT_PATH), "Interaction point contract exists")
	_assert(contract_text.contains("interaction_door"), "Contract documents door interaction markers")
	_assert(contract_text.contains("interaction_computer"), "Contract documents computer interaction markers")
	_assert(contract_text.contains("interaction_hold_zone"), "Contract documents hold zone interaction markers")
	_assert(contract_text.contains("SimulationRoot"), "Contract keeps SimulationRoot authoritative")
	_assert(_read_text(WORKFLOW_CONTRACT_PATH).contains("Mission Interaction Points"), "Workflow contract links interaction point follow-up")
	_assert(_read_text(STATUS_PATH).contains("TASK_673 - Mission Interaction Point Contract"), "Implementation status tracks TASK_673")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_673 - Mission Interaction Point Contract"), "Roadmap lists TASK_673")
	_assert(_read_text(HANDBOOK_PATH).contains("TASK_673 - Mission Interaction Point Contract"), "Current handbook references TASK_673")


func _test_marker_catalog() -> void:
	_assert(MARKER_CATALOG_SCRIPT.has_type("interaction_door"), "Marker catalog exposes door interaction marker")
	_assert(MARKER_CATALOG_SCRIPT.has_type("interaction_computer"), "Marker catalog exposes computer interaction marker")
	_assert(MARKER_CATALOG_SCRIPT.has_type("interaction_hold_zone"), "Marker catalog exposes hold zone interaction marker")
	for marker_type_id in PackedStringArray(["interaction_door", "interaction_computer", "interaction_hold_zone"]):
		var definition: Dictionary = MARKER_CATALOG_SCRIPT.get_type_definition(marker_type_id)
		_assert(String(definition.get("placement_context", "")) == MARKER_CATALOG_SCRIPT.CONTEXT_EDITOR_ONLY, "%s remains editor-only" % marker_type_id)
		_assert(not bool(definition.get("single_instance", true)), "%s allows multiple authored instances" % marker_type_id)
		_assert(not String(definition.get("tooltip", "")).strip_edges().is_empty(), "%s has authoring tooltip" % marker_type_id)
		_assert(String(definition.get("display_name", "")).strip_edges().contains("Interaction") or marker_type_id == "interaction_hold_zone", "%s has readable display name" % marker_type_id)
	var editor_marker_ids: PackedStringArray = MARKER_CATALOG_SCRIPT.get_type_ids_for_context(MARKER_CATALOG_SCRIPT.CONTEXT_EDITOR_ONLY)
	_assert(editor_marker_ids.has("interaction_door"), "Door interaction marker appears in editor context")
	_assert(editor_marker_ids.has("interaction_computer"), "Computer interaction marker appears in editor context")
	_assert(editor_marker_ids.has("interaction_hold_zone"), "Hold zone interaction marker appears in editor context")


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
