extends SceneTree

const SETTINGS_SCRIPT: GDScript = preload("res://scripts/ui/comic_bubble_settings.gd")
const GATE_SCRIPT: GDScript = preload("res://scripts/ui/comic_bubble_runtime_gate.gd")
const RESOLVER_SCRIPT: GDScript = preload("res://scripts/ui/fireteamleader_feedback_bubble_resolver.gd")
const COMIC_BUBBLE_VISUAL_CONTRACT_SCRIPT: GDScript = preload("res://scripts/ui/comic_bubble_visual_contract.gd")
const TACTICAL_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/ui/main_menu.tscn")

const TEMP_SETTINGS_PATH: String = "user://task_211_comic_bubble_settings.cfg"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_211 Comic Bubble Toggles Cooldowns and Settings ===")
	_remove_user_file(TEMP_SETTINGS_PATH)
	_test_settings_defaults_input_map_and_persistence()
	_test_runtime_gate_modes_cooldowns_limits_and_hold()
	await _test_controller_off_mode_and_renderer_empty_payload()
	await _test_main_menu_settings_mode_control()
	_remove_user_file(TEMP_SETTINGS_PATH)
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_settings_defaults_input_map_and_persistence() -> void:
	var defaults: Dictionary = Dictionary(SETTINGS_SCRIPT.call("load_settings", TEMP_SETTINGS_PATH))
	_assert(String(defaults.get("mode", "")) == "normal", "Missing settings file loads safe normal bubble defaults")
	_assert(bool(defaults.get("ftl_command_feedback_enabled", false)), "Default settings enable FTL command feedback")
	_assert(bool(defaults.get("npc_thought_peek_enabled", false)), "Default settings prepare NPC thought hold-to-peek")
	_assert(InputMap.has_action("show_npc_thoughts"), "InputMap has show_npc_thoughts action")
	_assert(InputMap.action_get_events("show_npc_thoughts").size() >= 1, "show_npc_thoughts has a default key event")
	defaults["mode"] = "minimal"
	defaults["max_active_bubbles_total"] = 2
	defaults["command_feedback_cooldown_msec"] = 321
	var save_error: int = int(SETTINGS_SCRIPT.call("save_settings", defaults, TEMP_SETTINGS_PATH))
	var loaded: Dictionary = Dictionary(SETTINGS_SCRIPT.call("load_settings", TEMP_SETTINGS_PATH))
	_assert(save_error == OK, "Comic bubble settings save to ConfigFile path")
	_assert(String(loaded.get("mode", "")) == "minimal", "Comic bubble mode persists across load")
	_assert(int(loaded.get("max_active_bubbles_total", 0)) == 2, "Comic bubble max-active limit persists")
	_assert(int(loaded.get("command_feedback_cooldown_msec", 0)) == 321, "Comic bubble cooldown persists")


func _test_runtime_gate_modes_cooldowns_limits_and_hold() -> void:
	var leader: Node2D = _make_unit("gate_lead", "blue", true, Vector2(80.0, 128.0), 0.85)
	var accepted_payload: Dictionary = _build_ftl_payload("move", "accepted", leader)
	var blocked_payload: Dictionary = _build_ftl_payload("move", "blocked", leader)
	var contact_payload: Dictionary = _build_ftl_payload("engage", "contact", leader)
	var running_payload: Dictionary = _build_ftl_payload("take", "running", leader)
	var thought_payload: Dictionary = Dictionary(COMIC_BUBBLE_VISUAL_CONTRACT_SCRIPT.call("build_display_payload", "bubble_npc_thought_quiet", "Ich warte.", leader.global_position, "gate_lead"))

	var gate: RefCounted = GATE_SCRIPT.new()
	gate.call("set_settings", {"mode": "off", "command_feedback_cooldown_msec": 0})
	_assert(not bool(gate.call("should_emit_payload", accepted_payload, SETTINGS_SCRIPT.CATEGORY_FTL_COMMAND_FEEDBACK, 1000)), "Off mode blocks FTL command bubbles")

	gate.call("reset_runtime_state")
	gate.call("set_settings", {"mode": "minimal", "command_feedback_cooldown_msec": 0})
	_assert(not bool(gate.call("should_emit_payload", accepted_payload, SETTINGS_SCRIPT.CATEGORY_FTL_COMMAND_FEEDBACK, 1000)), "Minimal mode suppresses routine accepted feedback")
	_assert(bool(gate.call("should_emit_payload", blocked_payload, SETTINGS_SCRIPT.CATEGORY_FTL_COMMAND_FEEDBACK, 1000)), "Minimal mode allows important blocked feedback")

	gate.call("reset_runtime_state")
	gate.call("set_settings", {"mode": "normal", "command_feedback_cooldown_msec": 1000})
	_assert(bool(gate.call("should_emit_payload", accepted_payload, SETTINGS_SCRIPT.CATEGORY_FTL_COMMAND_FEEDBACK, 1000)), "Normal mode allows first accepted feedback")
	_assert(not bool(gate.call("should_emit_payload", accepted_payload, SETTINGS_SCRIPT.CATEGORY_FTL_COMMAND_FEEDBACK, 1200)), "Cooldown blocks immediate repeated FTL feedback")
	_assert(bool(gate.call("should_emit_payload", accepted_payload, SETTINGS_SCRIPT.CATEGORY_FTL_COMMAND_FEEDBACK, 2100)), "Cooldown allows feedback after interval")

	gate.call("reset_runtime_state")
	gate.call("set_settings", {"mode": "normal", "max_active_bubbles_total": 2, "command_feedback_cooldown_msec": 0})
	var filtered: Array = Array(gate.call("filter_payloads", [accepted_payload, running_payload, blocked_payload, contact_payload], SETTINGS_SCRIPT.CATEGORY_FTL_COMMAND_FEEDBACK, 3000))
	_assert(filtered.size() == 2, "Runtime gate enforces max-active bubble limit")
	_assert(_states(filtered).has("blocked") and _states(filtered).has("contact"), "Runtime gate prioritizes warning/contact over flavor feedback")

	gate.call("reset_runtime_state")
	gate.call("set_settings", {"mode": "normal", "thought_feedback_cooldown_msec": 0})
	gate.call("set_thought_peek_override", false)
	_assert(not bool(gate.call("should_emit_payload", thought_payload, SETTINGS_SCRIPT.CATEGORY_NPC_THOUGHT_PEEK, 4000)), "NPC thoughts stay hidden without hold input")
	gate.call("set_thought_peek_override", true)
	_assert(bool(gate.call("should_emit_payload", thought_payload, SETTINGS_SCRIPT.CATEGORY_NPC_THOUGHT_PEEK, 4000)), "NPC thoughts show while hold input is active")
	leader.free()


func _test_controller_off_mode_and_renderer_empty_payload() -> void:
	var leader: Node2D = _make_unit("controller_lead", "blue", true, Vector2(96.0, 144.0), 0.8)
	var controller: Node = TACTICAL_CONTROLLER_SCRIPT.new()
	controller.call("set_comic_bubble_settings", {"mode": "off"})
	var payload: Dictionary = Dictionary(controller.call("record_fireteamleader_feedback_bubble_for_unit", "move", "accepted", leader, "blue", "test"))
	_assert(payload.is_empty(), "Controller off mode blocks new FTL feedback payloads")
	_assert(Array(controller.call("get_fireteamleader_feedback_bubble_snapshot")).is_empty(), "Controller off mode keeps feedback snapshot empty")

	var map_data: RefCounted = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task211_empty_bubbles", Vector2i(5, 5), Vector2.ZERO, 64.0, 32.0, 3)
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	primary_view.call("set_order_visual_payload", {
		"phase_index": 1,
		"feedback_bubble_dicts": Array(controller.call("get_fireteamleader_feedback_bubble_snapshot")),
	})
	await _wait_frames(6)
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(snapshot.get("feedback_bubble_visual_count", 0)) == 0, "Disabled bubbles create no primary-map visual nodes")
	primary_view.queue_free()
	controller.free()
	leader.free()
	await _wait_frames(2)


func _test_main_menu_settings_mode_control() -> void:
	var screen: Node = MAIN_MENU_SCENE.instantiate()
	root.add_child(screen)
	await _wait_frames(2)
	screen.call("set_settings_path_for_tests", TEMP_SETTINGS_PATH)
	var save_error: int = int(screen.call("set_comic_bubble_mode", "minimal"))
	var snapshot: Dictionary = Dictionary(screen.call("get_settings_snapshot"))
	var comic_snapshot: Dictionary = Dictionary(snapshot.get("comic_bubbles", {}))
	var loaded: Dictionary = Dictionary(SETTINGS_SCRIPT.call("load_settings", TEMP_SETTINGS_PATH))
	_assert(save_error == OK, "Main menu settings panel saves comic bubble mode")
	_assert(String(comic_snapshot.get("mode", "")) == "minimal", "Main menu settings snapshot exposes selected bubble mode")
	_assert(String(loaded.get("mode", "")) == "minimal", "Main menu comic bubble mode persists through settings path")
	screen.queue_free()
	await _wait_frames(2)


func _build_ftl_payload(action: String, state: String, leader: Node2D) -> Dictionary:
	return Dictionary(RESOLVER_SCRIPT.call("build_command_feedback", action, state, leader, leader.global_position, {"command_feedback_cooldown_msec": 0}, {"fireteam_id": "blue"}))


func _make_unit(unit_id: String, fireteam_id: String, is_lead: bool, world_position: Vector2, leadership: float) -> Node2D:
	var unit = TEST_UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.display_name = unit_id
	unit.team_id = "team_alpha"
	unit.fireteam_id = fireteam_id
	unit.is_fireteam_lead = is_lead
	unit.skill_leadership = leadership
	unit.discipline = leadership
	unit.awareness = leadership
	unit.speech_quality = leadership
	unit.position = world_position
	unit._ready()
	return unit


func _states(payloads: Array) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for payload_variant in payloads:
		if typeof(payload_variant) == TYPE_DICTIONARY:
			result.append(String(Dictionary(payload_variant).get("feedback_state", "")))
	return result


func _remove_user_file(path: String) -> void:
	var absolute_path: String = ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(absolute_path)


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
