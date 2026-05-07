extends SceneTree

const DEV_DOC_PATH: String = "res://docs/dev/tactical_command_doctrine_game_abstraction.md"
const MATRIX_PATH: String = "res://docs/research/tactical_doctrine_source_matrix.md"
const TASK_PATH: String = "res://docs/tasks/TASK_269_tactical_doctrine_source_review_game_abstraction.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"

const REQUIRED_DEV_SECTIONS: PackedStringArray = [
	"Safety Note",
	"Design Purpose",
	"Command Levels",
	"Commander Intent Vocabulary",
	"Tactical Rule Vocabulary",
	"FTL Execution Styles",
	"Breakout Contract",
	"UI Feedback Vocabulary",
	"Status Response Vocabulary",
	"Game-Safe Abstraction Rules",
	"Follow-Up Contracts",
]

const REQUIRED_MATRIX_SECTIONS: PackedStringArray = [
	"Purpose",
	"Source Matrix",
	"Neutralization Rules",
	"Useful Design Signals",
	"Not Used As Source",
	"Follow-Up Links",
]

const REQUIRED_SOURCE_TOKENS: PackedStringArray = [
	"US Army ATP 3-21.8",
	"Bundeswehr",
	"Armee de Terre",
	"Bohemia Interactive Arma 3",
]

const REQUIRED_COMMAND_LEVEL_TOKENS: PackedStringArray = [
	"Commander",
	"Fireteam Leader",
	"Unit",
	"Commander intent -> FTL execution plan -> Unit actions -> Visible feedback",
]

const REQUIRED_VOCAB_TOKENS: PackedStringArray = [
	"`move`",
	"`take`",
	"`defend`",
	"`engage`",
	"`secure`",
	"`recon`",
	"`withdraw`",
	"`support`",
	"`bypass`",
	"`hold`",
]

const REQUIRED_BREAKOUT_TOKENS: PackedStringArray = [
	"`contact`",
	"`suppressed`",
	"`casualty`",
	"`blocked_path`",
	"`low_ammo`",
	"`leader_down`",
	"`lz_threatened`",
	"`air_asset_threatened`",
	"`auto_adapt`",
	"`hold_and_report`",
	"`request_orders`",
	"`abort_to_safe`",
]

const REQUIRED_FOLLOW_UP_TASKS: PackedStringArray = [
	"TASK_270",
	"TASK_271",
	"TASK_272",
	"TASK_273",
	"TASK_274",
	"TASK_276",
	"TASK_277",
	"TASK_278",
	"TASK_279",
	"TASK_280",
	"TASK_281",
	"TASK_282",
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_269 Tactical Doctrine Source Review Game Abstraction ===")
	var dev_doc: String = _read_text(DEV_DOC_PATH)
	var matrix_doc: String = _read_text(MATRIX_PATH)
	var task_doc: String = _read_text(TASK_PATH)
	var status_doc: String = _read_text(STATUS_PATH)
	_test_dev_doc(dev_doc)
	_test_source_matrix(matrix_doc)
	_test_safety_and_neutralization(dev_doc, matrix_doc)
	_test_task_and_status(task_doc, status_doc)
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_dev_doc(text: String) -> void:
	_assert(not text.is_empty(), "Dev abstraction document exists")
	for section in REQUIRED_DEV_SECTIONS:
		_assert(text.contains("## %s" % section), "Dev doc has %s section" % section)
	for token in REQUIRED_COMMAND_LEVEL_TOKENS:
		_assert(text.contains(token), "Dev doc separates command level token %s" % token)
	for token in REQUIRED_VOCAB_TOKENS:
		_assert(text.contains(token), "Dev doc documents command verb %s" % token)
	for token in REQUIRED_BREAKOUT_TOKENS:
		_assert(text.contains(token), "Dev doc documents breakout token %s" % token)
	for token in ["#16 Command Matrix", "#17 Selected Fireteam", "#18 Mission Control", "Mission Map", "Bubbles/Radio", "Help Popups"]:
		_assert(text.contains(token), "Dev doc documents UI feedback surface %s" % token)
	for task_id in REQUIRED_FOLLOW_UP_TASKS:
		_assert(text.contains(task_id), "Dev doc references follow-up %s" % task_id)
	_assert(text.contains("UI is never the source of gameplay truth"), "Dev doc protects gameplay truth from UI")
	_assert(text.contains("SimulationRoot"), "Dev doc names SimulationRoot authority")


func _test_source_matrix(text: String) -> void:
	_assert(not text.is_empty(), "Source matrix exists")
	for section in REQUIRED_MATRIX_SECTIONS:
		_assert(text.contains("## %s" % section), "Source matrix has %s section" % section)
	for token in REQUIRED_SOURCE_TOKENS:
		_assert(text.contains(token), "Source matrix includes %s" % token)
	for url in [
		"https://armypubs.army.mil/",
		"https://www.bundeswehr.de/",
		"https://www.terre.defense.gouv.fr/",
		"https://www.defense.gouv.fr/",
		"https://community.bohemia.net/wiki/Arma_3:_Field_Manual_-_Commanding",
	]:
		_assert(text.contains(url), "Source matrix stores link %s" % url)
	_assert(text.contains("Game Abstraction"), "Source matrix contains game abstraction column")
	_assert(text.contains("Do Not Adopt"), "Source matrix contains do-not-adopt column")
	_assert(text.contains("Not Used As Source"), "Source matrix excludes unsafe source types")


func _test_safety_and_neutralization(dev_doc: String, matrix_doc: String) -> void:
	var combined: String = "%s\n%s" % [dev_doc, matrix_doc]
	for token in [
		"not a real tactical handbook",
		"no real step-by-step combat procedures",
		"Do not use national force names",
		"not real ROE",
		"no battle drills",
		"no formation recipes",
		"no tactical method reproduction",
	]:
		_assert(combined.to_lower().contains(token.to_lower()), "Safety/neutralization text covers '%s'" % token)
	_assert(not combined.contains("C:\\Users\\"), "Docs contain no local user paths")


func _test_task_and_status(task_doc: String, status_doc: String) -> void:
	_assert(task_doc.contains("## Status: IMPLEMENTIERT"), "TASK_269 is marked implemented")
	_assert(not task_doc.contains("- [ ]"), "TASK_269 checklist is complete")
	_assert(status_doc.contains("### TASK_269 - Tactical Doctrine Source Review Game Abstraction"), "Implementation status has TASK_269 section")
	_assert(status_doc.contains("- Status: implementiert"), "Implementation status marks some task implemented")
	_assert(status_doc.contains("tactical_command_doctrine_game_abstraction.md"), "Implementation status references abstraction doc")
	_assert(status_doc.contains("tactical_doctrine_source_matrix.md"), "Implementation status references source matrix")


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
