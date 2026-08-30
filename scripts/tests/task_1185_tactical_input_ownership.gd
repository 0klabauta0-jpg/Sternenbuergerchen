extends SceneTree

const CAMERA_SCRIPT_PATH: String = "res://scripts/tests/mission_map_camera_controller.gd"
const CONTROLLER_SCRIPT_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const BUBBLE_SETTINGS_PATH: String = "res://scripts/ui/comic_bubble_settings.gd"
const GAME_SETTINGS_SCRIPT: GDScript = preload("res://scripts/ui/game_settings_contract.gd")

const REQUIRED_ACTIONS: PackedStringArray = [
	"tactical_camera_pan_up",
	"tactical_camera_pan_down",
	"tactical_camera_pan_left",
	"tactical_camera_pan_right",
	"tactical_camera_rotate_left",
	"tactical_camera_rotate_right",
	"tactical_camera_rotate_drag",
	"tactical_camera_zoom_in",
	"tactical_camera_zoom_out",
	"tactical_select",
	"tactical_select_additive",
	"tactical_order",
	"tactical_order_append",
	"tactical_cycle_fireteam_next",
	"tactical_cycle_fireteam_previous",
	"tactical_execute_orders",
	"tactical_delete_order",
	"tactical_issue_move",
	"tactical_issue_defend",
	"tactical_issue_flank",
	"tactical_issue_take",
	"tactical_issue_breach",
	"tactical_toggle_fire_sector",
	"tactical_toggle_los",
	"tactical_sort_fireteam",
	"tactical_phase_previous",
	"tactical_phase_next",
	"show_npc_thoughts",
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1185 Tactical Input Ownership ===")
	_test_input_map_declares_each_owner_action()
	_test_owner_actions_route_the_reviewed_keys_and_mouse_buttons()
	_test_camera_uses_actions_and_never_claims_right_mouse_button()
	_test_tactical_controller_uses_actions_instead_of_physical_keycodes()
	_test_settings_expose_rebindable_action_descriptors()
	_test_thought_hold_does_not_restore_the_t_alias()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_input_map_declares_each_owner_action() -> void:
	for action_name in REQUIRED_ACTIONS:
		_assert(InputMap.has_action(action_name), "%s is registered in the InputMap" % action_name)
		if InputMap.has_action(action_name):
			_assert(not InputMap.action_get_events(action_name).is_empty(), "%s has at least one default binding" % action_name)


func _test_owner_actions_route_the_reviewed_keys_and_mouse_buttons() -> void:
	var q_event := _key_event(KEY_Q)
	_assert(q_event.is_action_pressed("tactical_camera_rotate_left"), "Q belongs to camera rotation")
	_assert(not q_event.is_action_pressed("tactical_cycle_fireteam_previous"), "Q does not cycle fireteams")
	var e_event := _key_event(KEY_E)
	_assert(e_event.is_action_pressed("tactical_camera_rotate_right"), "E belongs to camera rotation")
	_assert(not e_event.is_action_pressed("tactical_execute_orders"), "E does not execute orders")
	var t_event := _key_event(KEY_T)
	_assert(t_event.is_action_pressed("tactical_sort_fireteam"), "T sorts the focused fireteam")
	_assert(not t_event.is_action_pressed("show_npc_thoughts"), "T does not show NPC thoughts")
	var v_event := _key_event(KEY_V)
	_assert(v_event.is_action_pressed("show_npc_thoughts"), "V holds NPC thoughts")
	_assert(not v_event.is_action_pressed("tactical_sort_fireteam"), "V does not sort fireteams")
	var g_event := _key_event(KEY_G)
	_assert(g_event.is_action_pressed("tactical_execute_orders"), "G executes planned orders")
	_assert(not g_event.is_action_pressed("tactical_cycle_fireteam_next"), "G does not change the selected fireteam")
	var tab_event := _key_event(KEY_TAB)
	_assert(tab_event.is_action_pressed("tactical_cycle_fireteam_next", false, true), "Tab selects the next fireteam outside UI focus")
	var shift_tab_event := _key_event(KEY_TAB, true)
	_assert(shift_tab_event.is_action_pressed("tactical_cycle_fireteam_previous", false, true), "Shift+Tab selects the previous fireteam outside UI focus")
	var enter_event := _key_event(KEY_ENTER)
	_assert(not enter_event.is_action_pressed("tactical_execute_orders"), "Enter never maps to GO")
	var right_click := _mouse_button_event(MOUSE_BUTTON_RIGHT)
	_assert(right_click.is_action_pressed("tactical_order"), "Right mouse button belongs to tactical orders")
	_assert(not right_click.is_action_pressed("tactical_camera_rotate_drag"), "Right mouse button never rotates the camera")
	var middle_click := _mouse_button_event(MOUSE_BUTTON_MIDDLE)
	_assert(middle_click.is_action_pressed("tactical_camera_rotate_drag"), "Middle mouse drag belongs to camera rotation")
	_assert(not middle_click.is_action_pressed("tactical_order"), "Middle mouse drag never starts an order")


func _test_camera_uses_actions_and_never_claims_right_mouse_button() -> void:
	var source: String = _read_text(CAMERA_SCRIPT_PATH)
	_assert(not source.contains("Input.is_key_pressed"), "Camera polling uses InputMap actions instead of direct keys")
	_assert(not source.contains("MOUSE_BUTTON_RIGHT"), "Camera never claims the tactical right mouse button")
	_assert(source.contains("tactical_camera_rotate_drag"), "Camera owns only the dedicated middle-drag rotate action")


func _test_tactical_controller_uses_actions_instead_of_physical_keycodes() -> void:
	var source: String = _read_text(CONTROLLER_SCRIPT_PATH)
	_assert(not source.contains("physical_keycode"), "Tactical controller has no direct physical-keycode owner")
	for action_name in [
		"tactical_execute_orders",
		"tactical_cycle_fireteam_next",
		"tactical_cycle_fireteam_previous",
		"tactical_sort_fireteam",
		"tactical_order",
		"tactical_order_append",
	]:
		_assert(source.contains(action_name), "%s is consumed through the tactical owner" % action_name)
	_assert(not source.contains("KEY_Q"), "Q is not a fireteam-cycle alias")
	_assert(not source.contains("KEY_E:"), "E is not a GO alias")


func _test_settings_expose_rebindable_action_descriptors() -> void:
	var snapshot: Dictionary = Dictionary(GAME_SETTINGS_SCRIPT.call("build_snapshot"))
	var input_snapshot: Dictionary = Dictionary(snapshot.get("input", {}))
	_assert(bool(input_snapshot.get("rebindable", false)), "Settings mark tactical actions as rebindable")
	var described_actions: PackedStringArray = PackedStringArray()
	for descriptor_variant in Array(input_snapshot.get("actions", [])):
		described_actions.append(String(Dictionary(descriptor_variant).get("action", "")))
	for action_name in REQUIRED_ACTIONS:
		_assert(described_actions.has(action_name), "Settings expose %s" % action_name)


func _test_thought_hold_does_not_restore_the_t_alias() -> void:
	var source: String = _read_text(BUBBLE_SETTINGS_PATH)
	_assert(source.contains("KEY_V"), "Thought-hold fallback uses V")
	_assert(not source.contains("KEY_T"), "Thought-hold fallback no longer restores T")


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _key_event(physical_keycode: int, shift_pressed: bool = false) -> InputEventKey:
	var event := InputEventKey.new()
	event.pressed = true
	event.physical_keycode = physical_keycode
	event.shift_pressed = shift_pressed
	return event


func _mouse_button_event(button_index: int) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.pressed = true
	event.button_index = button_index
	return event


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
