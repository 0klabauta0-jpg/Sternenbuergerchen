extends SceneTree

const SETTINGS_SCRIPT: GDScript = preload("res://scripts/ui/comic_bubble_settings.gd")
const NPC_THOUGHT_RESOLVER_SCRIPT: GDScript = preload("res://scripts/ui/npc_thought_bubble_resolver.gd")
const TACTICAL_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_212 NPC Thought Bubble Hold to Peek Overlay ===")
	_test_resolver_status_role_text_and_spoiler_boundary()
	await _test_controller_hold_release_off_mode_and_limits()
	await _test_primary_map_renders_only_active_thought_payloads()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_resolver_status_role_text_and_spoiler_boundary() -> void:
	var medic: Node2D = _make_unit("thought_medic", "blue", false, "medic", Vector2(64.0, 128.0), 0.45)
	var leader: Node2D = _make_unit("thought_lead", "blue", true, "rifleman", Vector2(96.0, 128.0), 0.86)
	var wounded: Node2D = _make_unit("thought_wounded", "blue", false, "rifleman", Vector2(128.0, 128.0), 0.4)
	wounded.call("apply_damage", 60, {"source": "test"})
	var medic_payload: Dictionary = Dictionary(NPC_THOUGHT_RESOLVER_SCRIPT.call("build_unit_thought", medic, {}, {"selected": true}))
	var leader_payload: Dictionary = Dictionary(NPC_THOUGHT_RESOLVER_SCRIPT.call("build_unit_thought", leader, {}, {"selected": true}))
	var wounded_payload: Dictionary = Dictionary(NPC_THOUGHT_RESOLVER_SCRIPT.call("build_unit_thought", wounded, {}, {"selected": true}))
	_assert(bool(medic_payload.get("ok", false)), "Resolver builds a medic thought bubble")
	_assert(String(medic_payload.get("bubble_id", "")).begins_with("bubble_npc_"), "Thought bubbles use NPC bubble IDs, not FTL IDs")
	_assert(String(medic_payload.get("thought_kind", "")).begins_with("role:"), "Role data drives at least one thought kind")
	_assert(String(leader_payload.get("thought_kind", "")) == "leader", "Fireteam lead data drives leader thought kind")
	_assert(String(wounded_payload.get("thought_kind", "")) == "health", "Health/vital data drives health thought kind")
	_assert(_text_within_limits(String(wounded_payload.get("text", "")), 2, 22), "Thought text stays within compact NPC bubble bounds")
	_assert(_is_spoiler_safe(medic_payload) and _is_spoiler_safe(leader_payload) and _is_spoiler_safe(wounded_payload), "Thought payloads do not reveal hidden enemy data")
	medic.free()
	leader.free()
	wounded.free()


func _test_controller_hold_release_off_mode_and_limits() -> void:
	var context: Dictionary = _make_controller_context()
	var controller: Node = context["controller"] as Node
	controller.call("set_comic_bubble_settings", {
		"mode": "normal",
		"max_active_bubbles_total": 4,
		"max_thought_bubbles_total": 3,
		"thought_feedback_cooldown_msec": 0,
	})
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("set_npc_thought_peek_override", false)
	var hidden_snapshot: Array = Array(controller.call("get_npc_thought_bubble_snapshot"))
	_assert(hidden_snapshot.is_empty(), "Thought snapshot is empty while hold input is not active")

	controller.call("set_npc_thought_peek_override", true)
	var active_snapshot: Array = Array(controller.call("get_npc_thought_bubble_snapshot"))
	_assert(active_snapshot.size() > 0, "Thought snapshot appears while hold input is active")
	_assert(active_snapshot.size() <= 3, "Thought snapshot respects max thought bubble limit")
	_assert(_all_fireteam(active_snapshot, "blue"), "Thought snapshot stays on selected fireteam by default")
	_assert(_any_thought_kind(active_snapshot, "health"), "Relevant wounded/down NPC thought is prioritized")
	_assert(_payloads_are_spoiler_safe(active_snapshot), "Controller thought snapshot stays spoiler-safe")

	controller.call("set_npc_thought_peek_override", false)
	var released_snapshot: Array = Array(controller.call("get_npc_thought_bubble_snapshot"))
	_assert(released_snapshot.is_empty(), "Thought snapshot clears immediately after hold input is released")

	controller.call("set_comic_bubble_settings", {"mode": "off", "thought_feedback_cooldown_msec": 0})
	controller.call("set_npc_thought_peek_override", true)
	var off_snapshot: Array = Array(controller.call("get_npc_thought_bubble_snapshot"))
	_assert(off_snapshot.is_empty(), "Off mode blocks NPC thought bubbles")
	_cleanup_context(context)
	await _wait_frames(2)


func _test_primary_map_renders_only_active_thought_payloads() -> void:
	var context: Dictionary = _make_controller_context()
	var controller: Node = context["controller"] as Node
	controller.call("set_comic_bubble_settings", {
		"mode": "normal",
		"max_active_bubbles_total": 4,
		"max_thought_bubbles_total": 2,
		"thought_feedback_cooldown_msec": 0,
	})
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("set_npc_thought_peek_override", true)
	var thought_payloads: Array = Array(controller.call("get_npc_thought_bubble_snapshot"))
	var map_data: RefCounted = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task212_thought_bubbles", Vector2i(7, 7), Vector2.ZERO, 64.0, 32.0, 3)
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	primary_view.call("set_order_visual_payload", {
		"phase_index": 1,
		"feedback_bubble_dicts": thought_payloads,
	})
	await _wait_frames(8)
	var active_render_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var active_entries: Array = Array(active_render_snapshot.get("feedback_bubble_entries", []))
	_assert(int(active_render_snapshot.get("feedback_bubble_visual_count", 0)) == thought_payloads.size(), "Primary map renders active thought bubbles")
	_assert(_all_entries_from_source(active_entries, "npc_thought_peek"), "Primary map entries identify NPC thought source")
	_assert(_all_entries_use_npc_bubbles(active_entries), "Primary map thought entries remain visually distinct from FTL bubbles")

	controller.call("set_npc_thought_peek_override", false)
	primary_view.call("set_order_visual_payload", {
		"phase_index": 1,
		"feedback_bubble_dicts": Array(controller.call("get_npc_thought_bubble_snapshot")),
	})
	await _wait_frames(4)
	var released_render_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(released_render_snapshot.get("feedback_bubble_visual_count", 0)) == 0, "Primary map clears thought bubbles after hold release")

	primary_view.queue_free()
	_cleanup_context(context)
	await _wait_frames(2)


func _make_controller_context() -> Dictionary:
	var mission_root := Node.new()
	mission_root.name = "MissionRoot"
	root.add_child(mission_root)
	var units: Array = [
		_make_unit("blue_lead", "blue", true, "rifleman", Vector2(64.0, 128.0), 0.82),
		_make_unit("blue_medic", "blue", false, "medic", Vector2(96.0, 128.0), 0.5),
		_make_unit("blue_wounded", "blue", false, "rifleman", Vector2(128.0, 128.0), 0.42),
		_make_unit("blue_support", "blue", false, "heavy", Vector2(160.0, 128.0), 0.5),
		_make_unit("gold_lead", "gold", true, "rifleman", Vector2(64.0, 192.0), 0.72),
		_make_unit("gold_medic", "gold", false, "medic", Vector2(96.0, 192.0), 0.5),
	]
	for unit in units:
		mission_root.add_child(unit)
	units[2].call("apply_damage", 65, {"source": "test"})
	var controller: Node = TACTICAL_CONTROLLER_SCRIPT.new()
	controller.name = "TacticalController"
	mission_root.add_child(controller)
	return {
		"root": mission_root,
		"controller": controller,
		"units": units,
	}


func _cleanup_context(context: Dictionary) -> void:
	var mission_root: Node = context.get("root", null) as Node
	if mission_root != null and mission_root.is_inside_tree():
		mission_root.queue_free()
	elif mission_root != null:
		mission_root.free()


func _make_unit(unit_id: String, fireteam_id: String, is_lead: bool, role_id: String, world_position: Vector2, leadership: float) -> Node2D:
	var unit = TEST_UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.display_name = unit_id
	unit.team_id = "team_alpha"
	unit.fireteam_id = fireteam_id
	unit.is_fireteam_lead = is_lead
	unit.role_id = role_id
	unit.skill_leadership = leadership
	unit.discipline = leadership
	unit.awareness = leadership
	unit.position = world_position
	unit._ready()
	return unit


func _all_fireteam(payloads: Array, fireteam_id: String) -> bool:
	for payload_variant in payloads:
		if String(Dictionary(payload_variant).get("fireteam_id", "")) != fireteam_id:
			return false
	return true


func _any_thought_kind(payloads: Array, thought_kind: String) -> bool:
	for payload_variant in payloads:
		if String(Dictionary(payload_variant).get("thought_kind", "")) == thought_kind:
			return true
	return false


func _payloads_are_spoiler_safe(payloads: Array) -> bool:
	for payload_variant in payloads:
		if not _is_spoiler_safe(Dictionary(payload_variant)):
			return false
	return true


func _is_spoiler_safe(payload: Dictionary) -> bool:
	var text: String = String(payload.get("text", "")).to_lower()
	for forbidden in ["hidden", "enemy", "feind", "kontakt links", "target"]:
		if text.contains(forbidden):
			return false
	return bool(payload.get("spoiler_safe", true))


func _all_entries_from_source(entries: Array, source_id: String) -> bool:
	if entries.is_empty():
		return false
	for entry_variant in entries:
		if String(Dictionary(entry_variant).get("source", "")) != source_id:
			return false
	return true


func _all_entries_use_npc_bubbles(entries: Array) -> bool:
	if entries.is_empty():
		return false
	for entry_variant in entries:
		if not String(Dictionary(entry_variant).get("bubble_id", "")).begins_with("bubble_npc_"):
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
