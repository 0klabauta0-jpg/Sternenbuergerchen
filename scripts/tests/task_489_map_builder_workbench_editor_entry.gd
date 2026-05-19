extends SceneTree

const PLUGIN_CFG_PATH: String = "res://addons/map_builder_workbench/plugin.cfg"
const PLUGIN_SCRIPT_PATH: String = "res://addons/map_builder_workbench/map_builder_workbench_plugin.gd"
const WORKBENCH_SCRIPT_PATH: String = "res://scripts/editor/map_builder_workbench.gd"
const TASK_DOC_PATH: String = "res://docs/tasks/TASK_489_map_builder_workbench_editor_entry.md"
const TOOLING_CONTRACT_PATH: String = "res://docs/dev/map_builder_tooling_spike_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const PROJECT_PATH: String = "res://project.godot"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_489 Map Builder Workbench Editor Entry ===")
	_test_docs()
	_test_plugin_registration()
	_test_editor_dock_contract()
	_test_runtime_f6_hint()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_docs() -> void:
	_assert(FileAccess.file_exists(TASK_DOC_PATH), "TASK_489 task file exists")
	_assert(_read_text(TASK_DOC_PATH).contains("linke Icon-Leiste"), "Task documents left icon toolbar")
	_assert(_read_text(TOOLING_CONTRACT_PATH).contains("TASK_489"), "Tooling contract tracks TASK_489")
	_assert(_read_text(STATUS_PATH).contains("TASK_489 - Map Builder Workbench Editor Entry"), "Implementation status tracks TASK_489")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_489 - Map Builder Workbench Editor Entry"), "Roadmap lists TASK_489")


func _test_plugin_registration() -> void:
	var plugin_cfg := _read_text(PLUGIN_CFG_PATH)
	var project := _read_text(PROJECT_PATH)
	_assert(FileAccess.file_exists(PLUGIN_CFG_PATH), "Map Builder plugin.cfg exists")
	_assert(FileAccess.file_exists(PLUGIN_SCRIPT_PATH), "Map Builder plugin script exists")
	_assert(plugin_cfg.contains("name=\"Map Builder Workbench\""), "Plugin has visible editor name")
	_assert(plugin_cfg.contains("script=\"map_builder_workbench_plugin.gd\""), "Plugin config points to script")
	_assert(project.contains("res://addons/map_builder_workbench/plugin.cfg"), "project.godot enables Map Builder plugin")


func _test_editor_dock_contract() -> void:
	var script := _read_text(PLUGIN_SCRIPT_PATH)
	_assert(script.contains("DisplayServer.get_name() == \"headless\""), "Editor plugin skips dock UI in headless mode")
	_assert(script.contains("add_control_to_dock(DOCK_SLOT_LEFT_UL"), "Editor plugin docks on the left side")
	_assert(script.contains("_make_tool_button"), "Editor plugin uses icon tool buttons")
	_assert(script.contains("get_theme_icon"), "Editor plugin uses Godot editor icons")
	_assert(script.contains("tooltip_text"), "Editor plugin gives icon buttons tooltips")
	_assert(script.contains("GridMap auswaehlen"), "Editor plugin exposes GridMap selection")
	_assert(script.contains("AssetPlacerProps auswaehlen"), "Editor plugin exposes prop root selection")
	_assert(script.contains("save_compiled_map"), "Editor plugin compiles through Workbench save_compiled_map")


func _test_runtime_f6_hint() -> void:
	var script := _read_text(WORKBENCH_SCRIPT_PATH)
	_assert(script.contains("show_runtime_f6_hint"), "Workbench exposes runtime F6 hint toggle")
	_assert(script.contains("F6 ist nur Vorschau"), "Workbench runtime hint explains F6 is preview only")
	_assert(script.contains("Dock 'Map Builder'"), "Workbench runtime hint points to Map Builder dock")


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
