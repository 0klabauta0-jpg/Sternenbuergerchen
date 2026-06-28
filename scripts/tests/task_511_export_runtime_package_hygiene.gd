extends SceneTree

const CONTRACT_PATH: String = "res://data/export_runtime_package_contract.json"
const DEV_CONTRACT_PATH: String = "res://docs/dev/export_runtime_package_contract.md"
const TASK_DOC_PATH: String = "res://docs/tasks/TASK_511_export_runtime_package_hygiene.md"
const EXPORT_SCRIPT_PATH: String = "res://scripts/tools/export_runtime_release.ps1"
const REVIEW_REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"

const REQUIRED_EXCLUDES: PackedStringArray = [
	"addons/asset_placer/**",
	"addons/godot_mcp/**",
	"addons/godot_open_rts_reference/**",
	"addons/map_builder_workbench/**",
	"docs/**",
	"scripts/tests/**",
	"scripts/tools/**",
]

const RUNTIME_ADDON_ALLOWLIST: PackedStringArray = [
	"addons/limboai",
	"addons/terrain_3d",
	"addons/netfox",
	"addons/netfox.internals",
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_511 Export Runtime Package Hygiene ===")
	var contract: Dictionary = _load_json(CONTRACT_PATH)
	_test_contract_shape(contract)
	_test_contract_excludes(contract)
	_test_export_script_uses_contract(contract)
	_test_docs_reference_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_contract_shape(contract: Dictionary) -> void:
	_assert(not contract.is_empty(), "Runtime export package contract is valid JSON")
	_assert(String(contract.get("preset_name", "")) == "Windows Desktop", "Contract targets the Windows Desktop preset")
	_assert(String(contract.get("export_preset_path", "")) == "export_presets.cfg", "Contract documents local ignored export preset path")
	_assert(String(contract.get("runtime_export_path", "")).ends_with("Sternenbuergerchen_rel.exe"), "Contract keeps the runtime export executable target")
	_assert(bool(contract.get("restore_local_export_preset_after_run", false)), "Contract requires restoring the local export preset after the run")


func _test_contract_excludes(contract: Dictionary) -> void:
	var excludes: PackedStringArray = PackedStringArray(Array(contract.get("exclude_filter_patterns", [])))
	for required in REQUIRED_EXCLUDES:
		_assert(excludes.has(required), "Contract excludes %s from runtime package" % required)
	for addon_path in RUNTIME_ADDON_ALLOWLIST:
		_assert(not _patterns_exclude_path(excludes, addon_path), "Contract does not exclude runtime addon %s" % addon_path)


func _test_export_script_uses_contract(contract: Dictionary) -> void:
	var script_text: String = _read_text(EXPORT_SCRIPT_PATH)
	_assert(script_text.contains("export_runtime_package_contract.json"), "Export script loads the runtime package contract")
	_assert(script_text.contains("exclude_filter"), "Export script patches the Godot exclude_filter")
	_assert(script_text.contains("runtime_backup"), "Export script backs up and restores the local export preset")
	_assert(script_text.contains("godot_console.exe") and script_text.contains("--export-release"), "Export script uses Godot headless release export")
	_assert(script_text.contains("RedirectStandardError") and script_text.contains(".ExitCode"), "Export script treats Godot stderr warnings as log output and gates failure on the native exit code")
	for required in PackedStringArray(Array(contract.get("exclude_filter_patterns", []))):
		_assert(script_text.contains("exclude_filter_patterns") or script_text.contains(required), "Export script consumes contract exclude patterns")
		break


func _test_docs_reference_task() -> void:
	var task_doc: String = _read_text(TASK_DOC_PATH)
	var dev_contract: String = _read_text(DEV_CONTRACT_PATH)
	var review_report: String = _read_text(REVIEW_REPORT_PATH)
	var roadmap: String = _read_text(ROADMAP_PATH)
	var status: String = _read_text(STATUS_PATH)
	_assert(task_doc.contains("TASK_511 - Export Runtime Package Hygiene"), "TASK_511 task file exists")
	_assert(dev_contract.contains("Export Runtime Package Contract"), "Runtime package contract doc exists")
	_assert(review_report.contains("SternenBuergerchen Gesamt-Review") and review_report.contains("JSON exportieren"), "Review report workbench exists and supports JSON export")
	_assert(roadmap.contains("TASK_511 - Export Runtime Package Hygiene"), "Roadmap lists TASK_511")
	_assert(status.contains("TASK_511 - Export Runtime Package Hygiene"), "Implementation status lists TASK_511")


func _patterns_exclude_path(patterns: PackedStringArray, path: String) -> bool:
	var normalized_path: String = path.strip_edges().trim_suffix("/")
	for pattern in patterns:
		var normalized_pattern: String = String(pattern).strip_edges().trim_suffix("/")
		if normalized_pattern.is_empty():
			continue
		if normalized_pattern == normalized_path or normalized_pattern.begins_with(normalized_path + "/"):
			return true
		if normalized_pattern.trim_suffix("/**") == normalized_path:
			return true
	return false


func _load_json(path: String) -> Dictionary:
	var text: String = _read_text(path)
	if text.is_empty():
		return {}
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return Dictionary(parsed)


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
	print("  FAIL: %s" % message)
