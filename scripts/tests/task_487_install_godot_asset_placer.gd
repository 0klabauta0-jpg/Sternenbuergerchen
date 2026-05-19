extends SceneTree

const PLUGIN_CFG_PATH: String = "res://addons/asset_placer/plugin.cfg"
const PLUGIN_SCRIPT_PATH: String = "res://addons/asset_placer/asset_placer_plugin.gd"
const LICENSE_PATH: String = "res://addons/asset_placer/LICENSE"
const ASSET_LIBRARY_PANEL_PATH: String = "res://addons/asset_placer/ui/asset_library_panel.tscn"
const TERRAIN3D_STRATEGY_PATH: String = "res://addons/asset_placer/placement/terrain_3d_placement_strategy.gd"
const TASK_DOC_PATH: String = "res://docs/tasks/TASK_487_install_godot_asset_placer.md"
const TOOLING_CONTRACT_PATH: String = "res://docs/dev/map_builder_tooling_spike_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const PROJECT_PATH: String = "res://project.godot"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_487 Install Godot Asset Placer ===")
	_test_plugin_files()
	_test_plugin_enabled()
	_test_docs()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_plugin_files() -> void:
	_assert(FileAccess.file_exists(PLUGIN_CFG_PATH), "Asset Placer plugin.cfg exists")
	_assert(FileAccess.file_exists(PLUGIN_SCRIPT_PATH), "Asset Placer editor plugin script exists")
	_assert(FileAccess.file_exists(LICENSE_PATH), "Asset Placer MIT license is vendored")
	_assert(FileAccess.file_exists(ASSET_LIBRARY_PANEL_PATH), "Asset Placer dock scene is present")
	_assert(FileAccess.file_exists(TERRAIN3D_STRATEGY_PATH), "Asset Placer Terrain3D placement strategy is present")
	var plugin_cfg := _read_text(PLUGIN_CFG_PATH)
	var plugin_script := _read_text(PLUGIN_SCRIPT_PATH)
	_assert(plugin_cfg.contains('name="Godot Asset Placer"'), "plugin.cfg keeps official plugin name")
	_assert(plugin_cfg.contains('version="1.4.0"'), "plugin.cfg pins stable version 1.4.0")
	_assert(plugin_cfg.contains('script="asset_placer_plugin.gd"'), "plugin.cfg points to editor plugin script")
	_assert(plugin_script.contains("_should_use_editor_dock"), "Local headless EditorDock guard is present")
	_assert(plugin_script.contains('DisplayServer.get_name() == "headless"'), "Headless editor mode is detected explicitly")
	_assert(plugin_script.contains("skip UI setup entirely"), "Headless import skips editor dock UI setup")
	var license_text := _read_text(LICENSE_PATH)
	_assert(license_text.contains("MIT License"), "Vendored license declares MIT")


func _test_plugin_enabled() -> void:
	var project_text := _read_text(PROJECT_PATH)
	_assert(project_text.contains(PLUGIN_CFG_PATH.trim_prefix("res://")), "project.godot contains Asset Placer plugin path")
	var enabled = ProjectSettings.get_setting("editor_plugins/enabled", PackedStringArray())
	_assert(_packed_or_array_contains(enabled, PLUGIN_CFG_PATH), "ProjectSettings enables Asset Placer plugin")


func _test_docs() -> void:
	_assert(FileAccess.file_exists(TASK_DOC_PATH), "TASK_487 task file exists")
	var task_doc := _read_text(TASK_DOC_PATH)
	var tooling_contract := _read_text(TOOLING_CONTRACT_PATH)
	var status := _read_text(STATUS_PATH)
	var roadmap := _read_text(ROADMAP_PATH)
	_assert(task_doc.contains("Godot Asset Placer 1.4.0"), "Task documents installed Asset Placer version")
	_assert(task_doc.contains("headless EditorDock"), "Task documents the local headless EditorDock guard")
	_assert(task_doc.contains("https://github.com/levinzonr/godot-asset-placer"), "Task documents upstream source")
	_assert(tooling_contract.contains("TASK_487"), "Tooling contract records the install decision")
	_assert(tooling_contract.contains("user://asset_library.json"), "Tooling contract documents the user-local library default")
	_assert(status.contains("TASK_487 - Install Godot Asset Placer"), "Implementation status tracks TASK_487")
	_assert(roadmap.contains("TASK_487 - Install Godot Asset Placer"), "Roadmap lists TASK_487")


func _packed_or_array_contains(values, expected: String) -> bool:
	for value in values:
		if String(value) == expected:
			return true
	return false


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
