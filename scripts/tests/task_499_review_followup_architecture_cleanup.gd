extends SceneTree

const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")

var _failures: Array[String] = []


class MockAudioEventBus:
	extends Node

	func emit_weapon_fire(_weapon_id: String, _context: Dictionary = {}) -> Dictionary:
		return {"played": true}


func _init() -> void:
	_test_dead_main_scene_removed()
	_test_project_input_binding()
	_test_mission_catalog_scenario_contract()
	_test_simulation_root_audio_lookup()
	_finish()


func _test_dead_main_scene_removed() -> void:
	_assert(not FileAccess.file_exists("res://scenes/main.tscn"), "Dead skeleton scenes/main.tscn was removed")
	var project_text: String = FileAccess.get_file_as_string("res://project.godot")
	_assert(project_text.contains('run/main_scene="res://scenes/ui/main_menu.tscn"'), "Project still starts at the main menu scene")


func _test_project_input_binding() -> void:
	var project_text: String = FileAccess.get_file_as_string("res://project.godot")
	_assert(project_text.contains("show_npc_thoughts={"), "Project keeps show_npc_thoughts InputMap action")
	_assert(not project_text.contains('"events": []'), "show_npc_thoughts is not serialized with an empty event list")
	_assert(project_text.contains("Object(InputEventKey") and project_text.contains('"keycode":84'), "show_npc_thoughts has T as default project key")


func _test_mission_catalog_scenario_contract() -> void:
	var source_text: String = FileAccess.get_file_as_string("res://scripts/meta/meta_layer_flow.gd")
	_assert(source_text.contains('const NO_SCENARIO_FILE_PATH: String = ""'), "Meta flow defines explicit map-only scenario marker")
	_assert(_mission_entry_contains(source_text, "frontier_probe", '"scenario_file_path": NO_SCENARIO_FILE_PATH'), "frontier_probe explicitly marks missing scenario")
	_assert(_mission_entry_contains(source_text, "wall_breach", '"scenario_file_path": NO_SCENARIO_FILE_PATH'), "wall_breach explicitly marks missing scenario")


func _test_simulation_root_audio_lookup() -> void:
	var source_text: String = FileAccess.get_file_as_string("res://scripts/core/simulation_root.gd")
	_assert(not source_text.contains('find_child("AudioEventBus", true, false)'), "SimulationRoot no longer deep-scans for AudioEventBus")
	_assert(source_text.contains('get_node_or_null("AudioEventBus")'), "SimulationRoot still resolves direct AudioEventBus nodes cheaply")

	var root := Node.new()
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "SimulationRoot"
	var bus := MockAudioEventBus.new()
	bus.name = "AudioEventBus"
	root.add_child(simulation_root)
	root.add_child(bus)
	_assert(simulation_root.call("_resolve_audio_event_bus") == bus, "SimulationRoot resolves a sibling AudioEventBus without scanning")
	root.free()


func _mission_entry_contains(source_text: String, mission_id: String, needle: String) -> bool:
	var mission_index: int = source_text.find('"mission_id": "%s"' % mission_id)
	if mission_index < 0:
		return false
	var next_mission_index: int = source_text.find('"mission_id":', mission_index + 1)
	var entry_text: String = source_text.substr(mission_index) if next_mission_index < 0 else source_text.substr(mission_index, next_mission_index - mission_index)
	return entry_text.contains(needle)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failures.append(message)
	push_error(message)


func _finish() -> void:
	if _failures.is_empty():
		print("TASK_499 review followup architecture cleanup verifier passed.")
		quit(0)
		return
	print("TASK_499 verifier failed:")
	for failure in _failures:
		print("- %s" % failure)
	quit(1)
