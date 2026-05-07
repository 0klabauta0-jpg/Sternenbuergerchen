extends SceneTree

const SETTINGS_SCRIPT: GDScript = preload("res://scripts/ui/comic_bubble_settings.gd")
const RUNTIME_GATE_SCRIPT: GDScript = preload("res://scripts/ui/comic_bubble_runtime_gate.gd")
const FTL_RESOLVER_SCRIPT: GDScript = preload("res://scripts/ui/fireteamleader_feedback_bubble_resolver.gd")
const TACTICAL_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0


class UnitRegistryStub:
	extends Node
	var active_unit_ids: Dictionary = {}

	func has_unit(unit_id: String) -> bool:
		return active_unit_ids.has(unit_id)

	func get_unit(unit_id: String):
		return active_unit_ids.get(unit_id, null)


class FlowDriverStub:
	extends Node
	var unit_id: String = ""
	var accept_next: bool = true
	var issued_commands: Array = []

	func issue_command(command_type: String, phase_index: int) -> bool:
		issued_commands.append({
			"command_type": command_type,
			"phase": phase_index,
			"accepted": accept_next,
		})
		return accept_next


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_214 Comic Bubble Feedback Playability Smoke ===")
	await _test_mission_command_feedback_modes_and_blocked_path()
	_test_runtime_gate_cooldown_and_maximum()
	await _test_npc_thought_hold_roles_and_release()
	await _test_2_5d_render_snapshot_and_visual_only_boundary()
	await _test_multiplayer_snapshot_apply_boundary()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_mission_command_feedback_modes_and_blocked_path() -> void:
	var context: Dictionary = await _make_controller_context()
	var controller: Node = context["controller"] as Node
	var driver: Node = context["driver"] as Node
	controller.call("set_comic_bubble_settings", {
		"mode": "normal",
		"max_active_bubbles_total": 4,
		"command_feedback_cooldown_msec": 0,
		"thought_feedback_cooldown_msec": 0,
	})
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	driver.set("accept_next", true)
	var accepted: bool = bool(controller.call("issue_move"))
	var normal_bubbles: Array = Array(Dictionary(controller.call("get_command_feedback_snapshot")).get("fireteamleader_feedback_bubbles", []))
	_assert(accepted, "Normal mode keeps an accepted move command accepted")
	_assert(normal_bubbles.size() == 1, "Normal mode emits one FTL command bubble")
	_assert(String(Dictionary(normal_bubbles[0]).get("feedback_state", "")) == "accepted", "Normal command bubble stores accepted feedback state")
	_assert(String(Dictionary(normal_bubbles[0]).get("text_source", "")) == "comic_bubble_text_catalog", "Normal command bubble uses skill-based catalog text")

	controller.call("set_comic_bubble_mode", "off")
	var issued_before_off: int = Array(driver.get("issued_commands")).size()
	var accepted_off: bool = bool(controller.call("issue_take"))
	var off_bubbles: Array = Array(Dictionary(controller.call("get_command_feedback_snapshot")).get("fireteamleader_feedback_bubbles", []))
	_assert(accepted_off, "Off mode does not block gameplay command flow")
	_assert(Array(driver.get("issued_commands")).size() == issued_before_off + 1, "Off mode still sends commands to the flow driver")
	_assert(off_bubbles.is_empty(), "Off mode produces no visible FTL bubbles")

	controller.call("set_comic_bubble_settings", {
		"mode": "minimal",
		"max_active_bubbles_total": 4,
		"command_feedback_cooldown_msec": 0,
	})
	driver.set("accept_next", true)
	var accepted_minimal: bool = bool(controller.call("issue_move"))
	var minimal_accepted_bubbles: Array = Array(Dictionary(controller.call("get_command_feedback_snapshot")).get("fireteamleader_feedback_bubbles", []))
	_assert(accepted_minimal, "Minimal mode keeps accepted commands playable")
	_assert(minimal_accepted_bubbles.is_empty(), "Minimal mode suppresses non-important accepted command bubbles")
	driver.set("accept_next", false)
	var blocked: bool = bool(controller.call("issue_defend"))
	var minimal_blocked_bubbles: Array = Array(Dictionary(controller.call("get_command_feedback_snapshot")).get("fireteamleader_feedback_bubbles", []))
	_assert(not blocked, "Rejected command still returns the rejected command result")
	_assert(minimal_blocked_bubbles.size() == 1, "Minimal mode still emits important blocked feedback")
	_assert(String(Dictionary(minimal_blocked_bubbles[0]).get("bubble_id", "")) == "bubble_ftl_warning", "Blocked feedback uses the warning bubble")
	_assert(_is_visual_only_payload(Dictionary(minimal_blocked_bubbles[0])), "Blocked command feedback remains visual-only")
	_cleanup_controller_context(context)
	await _wait_frames(2)


func _test_runtime_gate_cooldown_and_maximum() -> void:
	var gate = RUNTIME_GATE_SCRIPT.new()
	gate.call("set_settings", {
		"mode": "normal",
		"max_active_bubbles_total": 2,
		"command_feedback_cooldown_msec": 0,
	})
	var leader: Node2D = _make_unit("task214_gate_lead", "blue", true, "rifleman", Vector2(64.0, 64.0), 0.9, 0.9)
	var move_payload: Dictionary = Dictionary(FTL_RESOLVER_SCRIPT.call("build_command_feedback", "move", "accepted", leader, leader.global_position, {}, {"fireteam_id": "blue"}))
	var blocked_payload: Dictionary = Dictionary(FTL_RESOLVER_SCRIPT.call("build_command_feedback", "move", "blocked", leader, leader.global_position, {}, {"fireteam_id": "blue"}))
	var contact_payload: Dictionary = Dictionary(FTL_RESOLVER_SCRIPT.call("build_command_feedback", "engage", "contact", leader, leader.global_position, {}, {"fireteam_id": "blue"}))
	var filtered: Array = Array(gate.call("filter_payloads", [move_payload, blocked_payload, contact_payload], SETTINGS_SCRIPT.CATEGORY_FTL_COMMAND_FEEDBACK, 1000))
	_assert(filtered.size() == 2, "Runtime gate caps emitted bubbles to the configured maximum")
	_assert(_all_payloads_important(filtered), "Runtime gate keeps higher-priority warning/contact bubbles under max pressure")

	gate.call("reset_runtime_state")
	gate.call("set_settings", {
		"mode": "normal",
		"max_active_bubbles_total": 4,
		"command_feedback_cooldown_msec": 650,
	})
	var first_emit: bool = bool(gate.call("should_emit_payload", move_payload, SETTINGS_SCRIPT.CATEGORY_FTL_COMMAND_FEEDBACK, 2000))
	var second_emit: bool = bool(gate.call("should_emit_payload", move_payload, SETTINGS_SCRIPT.CATEGORY_FTL_COMMAND_FEEDBACK, 2200))
	var third_emit: bool = bool(gate.call("should_emit_payload", move_payload, SETTINGS_SCRIPT.CATEGORY_FTL_COMMAND_FEEDBACK, 2700))
	_assert(first_emit, "Runtime gate emits the first command bubble")
	_assert(not second_emit, "Runtime gate blocks repeated command bubble within cooldown")
	_assert(third_emit, "Runtime gate emits again after cooldown")
	leader.free()


func _test_npc_thought_hold_roles_and_release() -> void:
	var context: Dictionary = await _make_controller_context()
	var controller: Node = context["controller"] as Node
	controller.call("set_comic_bubble_settings", {
		"mode": "normal",
		"max_active_bubbles_total": 4,
		"max_thought_bubbles_total": 4,
		"thought_feedback_cooldown_msec": 0,
	})
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	var hidden_thoughts: Array = Array(controller.call("get_npc_thought_bubble_snapshot"))
	_assert(hidden_thoughts.is_empty(), "NPC thoughts are hidden while hold input is not active")
	controller.call("set_npc_thought_peek_override", true)
	var active_thoughts: Array = Array(controller.call("get_npc_thought_bubble_snapshot"))
	_assert(active_thoughts.size() > 0 and active_thoughts.size() <= 4, "NPC thoughts appear during hold and respect max count")
	_assert(_all_from_selected_fireteam(active_thoughts, "blue"), "NPC thought smoke stays on the selected fireteam")
	_assert(_has_role_text_key(active_thoughts, "leader"), "Hold thought smoke includes leader text")
	_assert(_has_role_text_key(active_thoughts, "medic"), "Hold thought smoke includes medic text")
	_assert(_has_role_text_key(active_thoughts, "pilot"), "Hold thought smoke includes pilot text")
	_assert(_has_role_text_key(active_thoughts, "engineer"), "Hold thought smoke includes engineer text")
	_assert(_payload_texts_are_short(active_thoughts), "NPC thought texts stay short in integrated smoke")
	_assert(_payloads_are_spoiler_safe(active_thoughts), "NPC thought texts stay spoiler-safe")
	controller.call("set_npc_thought_peek_override", false)
	var released_thoughts: Array = Array(controller.call("get_npc_thought_bubble_snapshot"))
	_assert(released_thoughts.is_empty(), "NPC thoughts clear immediately after hold release")
	_cleanup_controller_context(context)
	await _wait_frames(2)


func _test_2_5d_render_snapshot_and_visual_only_boundary() -> void:
	var context: Dictionary = await _make_controller_context()
	var controller: Node = context["controller"] as Node
	controller.call("set_comic_bubble_settings", {
		"mode": "normal",
		"max_active_bubbles_total": 4,
		"max_thought_bubbles_total": 3,
		"command_feedback_cooldown_msec": 0,
		"thought_feedback_cooldown_msec": 0,
	})
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("issue_move")
	controller.call("set_npc_thought_peek_override", true)
	var payloads: Array = Array(controller.call("get_comic_bubble_visual_payload_snapshot"))
	var map_data: RefCounted = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task214_bubble_smoke", Vector2i(8, 8), Vector2.ZERO, 64.0, 32.0, 3)
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	primary_view.call("set_order_visual_payload", {
		"phase_index": 1,
		"feedback_bubble_dicts": payloads,
	})
	await _wait_frames(8)
	var render_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var entries: Array = Array(render_snapshot.get("feedback_bubble_entries", []))
	_assert(int(render_snapshot.get("feedback_bubble_visual_count", 0)) == payloads.size(), "2.5D map renders every active smoke bubble payload")
	_assert(payloads.size() <= 4, "Integrated visual payload snapshot respects the total bubble maximum")
	_assert(_entries_have_text_source(entries), "2.5D render snapshot keeps text-source diagnostics")
	_assert(_entries_are_visual_only(entries), "2.5D render entries remain visual-only")
	primary_view.queue_free()
	_cleanup_controller_context(context)
	await _wait_frames(2)


func _test_multiplayer_snapshot_apply_boundary() -> void:
	var root_node := Node.new()
	root_node.name = "Task214SnapshotBoundary"
	root.add_child(root_node)
	var unit_registry = UNIT_REGISTRY_SCRIPT.new()
	unit_registry.name = "UnitRegistry"
	root_node.add_child(unit_registry)
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "SimulationRoot"
	simulation_root.unit_registry_path = NodePath("../UnitRegistry")
	root_node.add_child(simulation_root)
	var unit: Node2D = _make_unit("task214_snapshot_unit", "blue", true, "rifleman", Vector2.ZERO, 0.8, 0.8)
	root_node.add_child(unit)
	unit_registry.call("register_unit", "task214_snapshot_unit", unit)
	simulation_root.call("register_known_unit", "task214_snapshot_unit", unit)
	var bubble_payload: Dictionary = Dictionary(FTL_RESOLVER_SCRIPT.call("build_command_feedback", "contact", "contact", unit, unit.global_position, {}, {"fireteam_id": "blue"}))
	simulation_root.call(
		"apply_multiplayer_snapshot",
		{
			"schema_version": 1,
			"tick": 14,
			"units": [
				{
					"unit_id": "task214_snapshot_unit",
					"team_id": "team_alpha",
					"fireteam_id": "blue",
					"position": Vector2(32.0, 0.0),
					"visible": true,
				},
			],
			"feedback_bubble_dicts": [bubble_payload],
		}
	)
	_assert(simulation_root.command_queue.is_empty(), "Applying a viewer snapshot with bubble data does not enqueue commands")
	_assert(simulation_root.effects_queue.is_empty(), "Applying a viewer snapshot with bubble data does not enqueue effects")
	root_node.queue_free()
	await _wait_frames(2)


func _make_controller_context() -> Dictionary:
	var mission_root := Node.new()
	mission_root.name = "Task214MissionRoot"
	root.add_child(mission_root)
	var registry := UnitRegistryStub.new()
	registry.name = "UnitRegistry"
	var driver := FlowDriverStub.new()
	driver.name = "AlphaFlowDriver"
	driver.unit_id = "blue_lead"
	var units: Array = [
		_make_unit("blue_lead", "blue", true, "rifleman", Vector2(64.0, 128.0), 0.86, 0.86),
		_make_unit("blue_medic", "blue", false, "medic", Vector2(96.0, 128.0), 0.76, 0.76),
		_make_unit("blue_pilot", "blue", false, "dropship_pilot", Vector2(128.0, 128.0), 0.72, 0.72),
		_make_unit("blue_engineer", "blue", false, "engineer", Vector2(160.0, 128.0), 0.72, 0.72),
		_make_unit("gold_lead", "gold", true, "rifleman", Vector2(64.0, 192.0), 0.24, 0.24),
	]
	units[2].set("dropship_piloting", 0.9)
	mission_root.add_child(registry)
	for unit in units:
		mission_root.add_child(unit)
		registry.active_unit_ids[String(unit.call("get_unit_id"))] = unit
	mission_root.add_child(driver)
	var controller: Node = TACTICAL_CONTROLLER_SCRIPT.new()
	controller.name = "TacticalController"
	controller.alpha_flow_driver_path = NodePath("../AlphaFlowDriver")
	mission_root.add_child(controller)
	await _wait_frames(4)
	return {
		"root": mission_root,
		"controller": controller,
		"driver": driver,
		"units": units,
	}


func _cleanup_controller_context(context: Dictionary) -> void:
	var mission_root: Node = context.get("root", null) as Node
	if mission_root != null and mission_root.is_inside_tree():
		mission_root.queue_free()
	elif mission_root != null:
		mission_root.free()


func _make_unit(unit_id: String, fireteam_id: String, is_lead: bool, role_id: String, world_position: Vector2, leadership: float, skill_value: float) -> Node2D:
	var unit = TEST_UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.display_name = unit_id
	unit.team_id = "team_alpha"
	unit.fireteam_id = fireteam_id
	unit.is_fireteam_lead = is_lead
	unit.role_id = role_id
	unit.skill_leadership = leadership
	unit.skill_accuracy = skill_value
	unit.skill_toughness = skill_value
	unit.discipline = skill_value
	unit.awareness = skill_value
	unit.speech_quality = leadership
	unit.position = world_position
	unit._ready()
	return unit


func _all_payloads_important(payloads: Array) -> bool:
	if payloads.is_empty():
		return false
	for payload_variant in payloads:
		var payload: Dictionary = Dictionary(payload_variant)
		var state: String = String(payload.get("feedback_state", "")).strip_edges().to_lower()
		if not ["blocked", "contact", "done", "cover"].has(state):
			return false
	return true


func _all_from_selected_fireteam(payloads: Array, fireteam_id: String) -> bool:
	for payload_variant in payloads:
		if String(Dictionary(payload_variant).get("fireteam_id", "")) != fireteam_id:
			return false
	return true


func _has_role_text_key(payloads: Array, role_key: String) -> bool:
	for payload_variant in payloads:
		if String(Dictionary(payload_variant).get("role_text_key", "")) == role_key:
			return true
	return false


func _payload_texts_are_short(payloads: Array) -> bool:
	for payload_variant in payloads:
		var text: String = String(Dictionary(payload_variant).get("text", ""))
		if not _text_within_limits(text, 2, 22):
			return false
	return true


func _payloads_are_spoiler_safe(payloads: Array) -> bool:
	for payload_variant in payloads:
		var payload: Dictionary = Dictionary(payload_variant)
		var text: String = String(payload.get("text", "")).to_lower()
		for forbidden in ["hidden", "enemy", "feind", "kontakt links", "target"]:
			if text.contains(forbidden):
				return false
		if not bool(payload.get("spoiler_safe", true)):
			return false
	return true


func _entries_have_text_source(entries: Array) -> bool:
	if entries.is_empty():
		return false
	for entry_variant in entries:
		if String(Dictionary(entry_variant).get("text_source", "")) != "comic_bubble_text_catalog":
			return false
	return true


func _entries_are_visual_only(entries: Array) -> bool:
	if entries.is_empty():
		return false
	for entry_variant in entries:
		if not bool(Dictionary(entry_variant).get("visual_only", false)):
			return false
	return true


func _is_visual_only_payload(payload: Dictionary) -> bool:
	if not bool(payload.get("visual_only", false)):
		return false
	for forbidden_key in ["command_type", "effect_type", "unit_command", "simulation_effect", "damage", "heal"]:
		if payload.has(forbidden_key):
			return false
	return true


func _text_within_limits(text: String, max_lines: int, max_chars_per_line: int) -> bool:
	var lines: PackedStringArray = text.split("\n", false)
	if lines.size() > max_lines:
		return false
	for line in lines:
		if String(line).length() > max_chars_per_line:
			return false
	return true


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
