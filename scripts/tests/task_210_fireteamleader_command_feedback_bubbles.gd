extends SceneTree

const RESOLVER_SCRIPT: GDScript = preload("res://scripts/ui/fireteamleader_feedback_bubble_resolver.gd")
const COMIC_BUBBLE_VISUAL_CONTRACT_SCRIPT: GDScript = preload("res://scripts/ui/comic_bubble_visual_contract.gd")
const TACTICAL_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0


class UnitRegistryStub:
	extends Node
	var active_unit_ids: Dictionary = {}

	func has_unit(unit_id: String) -> bool:
		return active_unit_ids.has(unit_id)


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
	print("=== TASK_210 Fireteamleader Command Feedback Bubbles ===")
	_test_resolver_uses_catalog_and_skill_variants()
	await _test_controller_command_binding_and_toggle()
	await _test_primary_map_renders_feedback_bubbles()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_resolver_uses_catalog_and_skill_variants() -> void:
	var high_leader: Node2D = _make_unit("leader_high", "blue", true, Vector2(128.0, 192.0), 0.88)
	var low_leader: Node2D = _make_unit("leader_low", "blue", true, Vector2(128.0, 192.0), 0.22)
	var high_payload: Dictionary = Dictionary(RESOLVER_SCRIPT.call("build_command_feedback", "move", "accepted", high_leader, high_leader.global_position, {}, {"fireteam_id": "blue"}))
	var low_payload: Dictionary = Dictionary(RESOLVER_SCRIPT.call("build_command_feedback", "move", "accepted", low_leader, low_leader.global_position, {}, {"fireteam_id": "blue"}))
	var disabled_payload: Dictionary = Dictionary(RESOLVER_SCRIPT.call("build_command_feedback", "move", "accepted", high_leader, high_leader.global_position, {"enabled": false}, {"fireteam_id": "blue"}))
	var runtime_ids: PackedStringArray = PackedStringArray(COMIC_BUBBLE_VISUAL_CONTRACT_SCRIPT.call("get_runtime_bubble_ids"))
	_assert(bool(high_payload.get("ok", false)), "Resolver builds an accepted-command bubble")
	_assert(bool(low_payload.get("ok", false)), "Resolver builds a low-skill accepted-command bubble")
	_assert(runtime_ids.has(String(high_payload.get("bubble_id", ""))), "Accepted-command bubble uses a TASK_209 runtime catalog ID")
	_assert(String(high_payload.get("skill_tier", "")) == "high", "High leadership resolves to high feedback tier")
	_assert(String(low_payload.get("skill_tier", "")) == "low", "Low leadership resolves to low feedback tier")
	_assert(String(high_payload.get("text", "")) != String(low_payload.get("text", "")), "Skill tiers produce distinct command text")
	_assert(String(high_payload.get("text", "")).split(" ", false).size() <= 9, "High-skill text is a short sentence (at most 9 words)")
	_assert(String(low_payload.get("text", "")).split(" ", false).size() <= 9, "Low-skill text is a short sentence (at most 9 words)")
	_assert(disabled_payload.is_empty(), "Disabled feedback settings return no bubble payload")
	_assert(_is_visual_only_payload(high_payload), "Resolver payload remains visual-only and has no gameplay command keys")
	high_leader.free()
	low_leader.free()


func _test_controller_command_binding_and_toggle() -> void:
	var mission_root := Node.new()
	mission_root.name = "MissionRoot"
	root.add_child(mission_root)

	var unit: Node2D = _make_unit("blue_lead", "blue", true, Vector2(96.0, 160.0), 0.82)
	var registry := UnitRegistryStub.new()
	registry.name = "UnitRegistry"
	registry.active_unit_ids["blue_lead"] = true
	var driver := FlowDriverStub.new()
	driver.name = "AlphaFlowDriver"
	driver.unit_id = "blue_lead"
	var controller: Node = TACTICAL_CONTROLLER_SCRIPT.new()
	controller.name = "TacticalController"
	controller.alpha_flow_driver_path = NodePath("../AlphaFlowDriver")

	mission_root.add_child(registry)
	mission_root.add_child(unit)
	mission_root.add_child(driver)
	mission_root.add_child(controller)
	await _wait_frames(4)
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)

	driver.accept_next = true
	var accepted: bool = bool(controller.call("issue_move"))
	var accepted_snapshot: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var accepted_bubbles: Array = Array(accepted_snapshot.get("fireteamleader_feedback_bubbles", []))
	_assert(accepted, "Accepted player command keeps the command flow accepted")
	_assert(driver.issued_commands.size() == 1, "Accepted command still reaches the flow driver")
	_assert(accepted_bubbles.size() == 1, "Accepted player command records one FTL feedback bubble")
	_assert(String(Dictionary(accepted_bubbles[0]).get("feedback_state", "")) == "accepted", "Accepted command bubble stores accepted feedback state")
	_assert(String(Dictionary(accepted_bubbles[0]).get("feedback_action", "")) == "move", "Accepted command bubble stores visual action context")
	_assert(_is_visual_only_payload(Dictionary(accepted_bubbles[0])), "Controller bubble payload stays visual-only")

	driver.accept_next = false
	var blocked: bool = bool(controller.call("issue_defend"))
	var blocked_snapshot: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var blocked_bubbles: Array = Array(blocked_snapshot.get("fireteamleader_feedback_bubbles", []))
	_assert(not blocked, "Rejected player command keeps the command flow rejected")
	_assert(String(Dictionary(blocked_bubbles[0]).get("feedback_state", "")) == "blocked", "Rejected command records a blocked FTL feedback bubble")
	_assert(String(Dictionary(blocked_bubbles[0]).get("bubble_id", "")) == "bubble_ftl_warning", "Rejected command uses the catalog warning bubble")

	driver.accept_next = true
	controller.call("set_fireteamleader_feedback_bubbles_enabled", false)
	var issued_count_before_toggle_command: int = driver.issued_commands.size()
	var accepted_with_disabled_bubbles: bool = bool(controller.call("issue_move"))
	var disabled_snapshot: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	_assert(accepted_with_disabled_bubbles, "Disabled bubbles do not block accepted command flow")
	_assert(driver.issued_commands.size() == issued_count_before_toggle_command + 1, "Disabled bubbles still let commands reach the flow driver")
	_assert(Array(disabled_snapshot.get("fireteamleader_feedback_bubbles", [])).is_empty(), "Disabled bubbles produce no visible feedback payload")

	mission_root.queue_free()
	await _wait_frames(2)


func _test_primary_map_renders_feedback_bubbles() -> void:
	var leader: Node2D = _make_unit("map_lead", "blue", true, Vector2(0.0, 256.0), 0.9)
	var payload: Dictionary = Dictionary(RESOLVER_SCRIPT.call("build_command_feedback", "take", "running", leader, leader.global_position, {}, {"fireteam_id": "blue"}))
	# Die Truppfuehrer-Blase wird nur noch an der Fireteam-Karte (HUD) gezeichnet, nie ueber der Figur.
	payload["anchor_space"] = "hud"
	payload["hud_anchor_position"] = Vector2(320.0, 200.0)
	var map_data: RefCounted = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task210_feedback_bubbles", Vector2i(7, 7), Vector2.ZERO, 64.0, 32.0, 3)
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	primary_view.call("set_order_visual_payload", {
		"phase_index": 1,
		"feedback_bubble_dicts": [payload],
	})
	await _wait_frames(8)

	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var entries: Array = Array(snapshot.get("feedback_bubble_entries", []))
	_assert(int(snapshot.get("feedback_bubble_visual_count", 0)) == 1, "Primary 3D map renders one feedback bubble visual")
	_assert(entries.size() == 1, "Primary 3D map exposes feedback bubble snapshot entries")
	_assert(String(Dictionary(entries[0]).get("bubble_id", "")) == String(payload.get("bubble_id", "")), "3D feedback entry mirrors the resolver bubble ID")
	_assert(String(Dictionary(entries[0]).get("feedback_state", "")) == "running", "3D feedback entry mirrors visual-only feedback state")
	_assert(bool(Dictionary(entries[0]).get("visual_only", false)), "3D feedback entry remains marked visual-only")

	primary_view.queue_free()
	leader.free()
	await _wait_frames(2)


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
