extends SceneTree

const TEXT_RESOLVER_SCRIPT: GDScript = preload("res://scripts/ui/comic_bubble_text_resolver.gd")
const FTL_RESOLVER_SCRIPT: GDScript = preload("res://scripts/ui/fireteamleader_feedback_bubble_resolver.gd")
const NPC_THOUGHT_RESOLVER_SCRIPT: GDScript = preload("res://scripts/ui/npc_thought_bubble_resolver.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0


class FakeCommand:
	var command_type: String = "move_to_position"
	var priority: int = 5
	var fire_status: String = "fire_at_will"
	var source_command_type: String = "move"
	var move_speed_factor: float = 1.0
	var cover_score: float = 0.0
	var attack_bonus: float = 0.0
	var phase: int = 1
	var target_position: Vector2 = Vector2(320.0, 160.0)

	func is_valid() -> bool:
		return true


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_213 Skill Based Bubble Text Resolver and Content Pass ===")
	_test_catalog_contract_and_length_limits()
	_test_ftl_texts_use_central_skill_resolver()
	_test_neutral_fallback_for_missing_skill_data()
	_test_npc_role_and_skill_variants()
	_test_npc_health_and_order_situations()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_catalog_contract_and_length_limits() -> void:
	var snapshot: Dictionary = Dictionary(TEXT_RESOLVER_SCRIPT.call("get_catalog_snapshot"))
	var loaded: Dictionary = Dictionary(TEXT_RESOLVER_SCRIPT.call("load_catalog"))
	var catalog: Dictionary = Dictionary(loaded.get("catalog", {}))
	var diagnostics: PackedStringArray = PackedStringArray(snapshot.get("diagnostics", PackedStringArray()))
	_assert(String(snapshot.get("text_source", "")) == "comic_bubble_text_catalog", "Resolver exposes the central text source ID")
	_assert(String(snapshot.get("runtime_contract", "")) == "visual_only_no_gameplay_truth", "Text catalog declares the visual-only contract")
	_assert(diagnostics.is_empty(), "Text catalog validates without diagnostics")
	_assert(_all_catalog_text_within_limits(catalog, 2, 22), "Every catalog text fits the compact TASK_209 bubble limits")


func _test_ftl_texts_use_central_skill_resolver() -> void:
	var high_leader: Node2D = _make_unit("task213_high_lead", "blue", true, "rifleman", Vector2(128.0, 192.0), 0.9, 0.9)
	var low_leader: Node2D = _make_unit("task213_low_lead", "blue", true, "rifleman", Vector2(160.0, 192.0), 0.2, 0.2)
	var high_payload: Dictionary = Dictionary(FTL_RESOLVER_SCRIPT.call("build_command_feedback", "move", "accepted", high_leader, high_leader.global_position, {}, {"fireteam_id": "blue"}))
	var low_payload: Dictionary = Dictionary(FTL_RESOLVER_SCRIPT.call("build_command_feedback", "move", "accepted", low_leader, low_leader.global_position, {}, {"fireteam_id": "blue"}))
	_assert(bool(high_payload.get("ok", false)) and bool(low_payload.get("ok", false)), "FTL feedback resolver builds high- and low-skill payloads")
	_assert(String(high_payload.get("text_source", "")) == "comms_lines", "FTL feedback text comes from the comms line catalog")
	_assert(String(high_payload.get("text_key", "")).begins_with("comms_lines.order_confirmed"), "FTL payload keeps a deterministic comms line key")
	_assert(String(high_payload.get("skill_tier", "")) == "high", "High leadership resolves to high text tier")
	_assert(String(low_payload.get("skill_tier", "")) == "low", "Low leadership resolves to low text tier")
	_assert(String(high_payload.get("text", "")) != String(low_payload.get("text", "")), "High and low FTL tiers produce distinct text")
	_assert(String(high_payload.get("feedback_state", "")) == String(low_payload.get("feedback_state", "")), "Low skill does not change the accepted command result")
	_assert(_is_visual_only_payload(high_payload) and _is_visual_only_payload(low_payload), "Skill-based FTL text remains visual-only")
	high_leader.free()
	low_leader.free()


func _test_neutral_fallback_for_missing_skill_data() -> void:
	var blank_subject := Node2D.new()
	var neutral_payload: Dictionary = Dictionary(TEXT_RESOLVER_SCRIPT.call("resolve_ftl_text_payload", "move", "accepted", blank_subject, {}))
	var null_payload: Dictionary = Dictionary(TEXT_RESOLVER_SCRIPT.call("resolve_npc_thought_text_payload", null, {}))
	_assert(String(neutral_payload.get("skill_tier", "")) == "neutral", "Missing FTL skill data resolves to the neutral tier")
	_assert(not String(neutral_payload.get("text", "")).strip_edges().is_empty(), "Neutral FTL fallback still produces short text")
	_assert(_text_within_limits(String(neutral_payload.get("text", "")), 2, 22), "Neutral FTL fallback fits the bubble text limits")
	_assert(String(null_payload.get("skill_tier", "")) == "neutral", "Missing NPC skill data resolves to the neutral tier")
	_assert(not String(null_payload.get("text", "")).strip_edges().is_empty(), "Neutral NPC fallback still produces short text")
	blank_subject.free()


func _test_npc_role_and_skill_variants() -> void:
	var medic_high: Node2D = _make_unit("task213_medic_high", "blue", false, "medic", Vector2(64.0, 128.0), 0.85, 0.85)
	var medic_low: Node2D = _make_unit("task213_medic_low", "blue", false, "medic", Vector2(96.0, 128.0), 0.15, 0.15)
	var pilot: Node2D = _make_unit("task213_pilot", "blue", false, "dropship_pilot", Vector2(128.0, 128.0), 0.78, 0.78)
	var engineer: Node2D = _make_unit("task213_engineer", "blue", false, "engineer", Vector2(160.0, 128.0), 0.78, 0.78)
	var heavy: Node2D = _make_unit("task213_heavy", "blue", false, "heavy", Vector2(192.0, 128.0), 0.78, 0.78)
	var shooter: Node2D = _make_unit("task213_shooter", "blue", false, "rifleman", Vector2(224.0, 128.0), 0.78, 0.78)
	var leader: Node2D = _make_unit("task213_leader", "blue", true, "rifleman", Vector2(256.0, 128.0), 0.78, 0.78)
	pilot.set("dropship_piloting", 0.9)
	var medic_high_payload: Dictionary = Dictionary(NPC_THOUGHT_RESOLVER_SCRIPT.call("build_unit_thought", medic_high, {}, {"selected": true}))
	var medic_low_payload: Dictionary = Dictionary(NPC_THOUGHT_RESOLVER_SCRIPT.call("build_unit_thought", medic_low, {}, {"selected": true}))
	var pilot_payload: Dictionary = Dictionary(NPC_THOUGHT_RESOLVER_SCRIPT.call("build_unit_thought", pilot, {}, {"selected": true}))
	var engineer_payload: Dictionary = Dictionary(NPC_THOUGHT_RESOLVER_SCRIPT.call("build_unit_thought", engineer, {}, {"selected": true}))
	var heavy_payload: Dictionary = Dictionary(NPC_THOUGHT_RESOLVER_SCRIPT.call("build_unit_thought", heavy, {}, {"selected": true}))
	var shooter_payload: Dictionary = Dictionary(NPC_THOUGHT_RESOLVER_SCRIPT.call("build_unit_thought", shooter, {}, {"selected": true}))
	var leader_payload: Dictionary = Dictionary(NPC_THOUGHT_RESOLVER_SCRIPT.call("build_unit_thought", leader, {}, {"selected": true}))
	_assert(String(medic_high_payload.get("text_source", "")) == "comic_bubble_text_catalog", "NPC thought text comes from the central text catalog")
	_assert(String(medic_high_payload.get("role_text_key", "")) == "medic", "Medic role data selects the medic text category")
	_assert(String(pilot_payload.get("role_text_key", "")) == "pilot", "Pilot role data selects the pilot text category")
	_assert(String(engineer_payload.get("role_text_key", "")) == "engineer", "Engineer role data selects the engineer text category")
	_assert(String(heavy_payload.get("role_text_key", "")) == "heavy", "Heavy/support role data selects the heavy text category")
	_assert(String(shooter_payload.get("role_text_key", "")) == "shooter", "Shooter role data selects the shooter text category")
	_assert(String(leader_payload.get("role_text_key", "")) == "leader", "Fireteam lead flag selects the leader text category")
	_assert(String(medic_high_payload.get("text", "")) != String(medic_low_payload.get("text", "")), "Medic skill tier changes text without changing role")
	_assert(_payload_texts_are_short([medic_high_payload, medic_low_payload, pilot_payload, engineer_payload, heavy_payload, shooter_payload, leader_payload]), "Role thought payloads stay within bubble text limits")
	medic_high.free()
	medic_low.free()
	pilot.free()
	engineer.free()
	heavy.free()
	shooter.free()
	leader.free()


func _test_npc_health_and_order_situations() -> void:
	var wounded: Node2D = _make_unit("task213_wounded", "blue", false, "rifleman", Vector2(64.0, 180.0), 0.75, 0.75)
	var ordered: Node2D = _make_unit("task213_ordered", "blue", false, "rifleman", Vector2(96.0, 180.0), 0.75, 0.75)
	wounded.call("apply_damage", 60, {"source": "test"})
	ordered.call("assign_unit_command", FakeCommand.new())
	var wounded_payload: Dictionary = Dictionary(NPC_THOUGHT_RESOLVER_SCRIPT.call("build_unit_thought", wounded, {}, {"selected": true}))
	var ordered_payload: Dictionary = Dictionary(NPC_THOUGHT_RESOLVER_SCRIPT.call("build_unit_thought", ordered, {}, {"selected": true}))
	_assert(String(wounded_payload.get("situation_key", "")) == "wounded", "Health state overrides role text with wounded situation text")
	_assert(String(wounded_payload.get("thought_kind", "")) == "health", "Wounded situation keeps health thought kind")
	_assert(String(ordered_payload.get("situation_key", "")) == "default", "Current command selects the order situation")
	_assert(String(ordered_payload.get("text_key", "")).begins_with("npc.order"), "Order situation keeps a deterministic order text key")
	_assert(_is_spoiler_safe(wounded_payload) and _is_spoiler_safe(ordered_payload), "Situation text remains spoiler-safe")
	wounded.free()
	ordered.free()


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


func _all_catalog_text_within_limits(catalog: Dictionary, max_lines: int, max_chars_per_line: int) -> bool:
	return _text_tree_within_limits(Dictionary(catalog.get("ftl", {})), max_lines, max_chars_per_line) and _text_tree_within_limits(Dictionary(catalog.get("npc", {})), max_lines, max_chars_per_line)


func _text_tree_within_limits(value: Variant, max_lines: int, max_chars_per_line: int) -> bool:
	if typeof(value) == TYPE_DICTIONARY:
		var dictionary: Dictionary = Dictionary(value)
		for key_variant in dictionary.keys():
			if not _text_tree_within_limits(dictionary.get(key_variant), max_lines, max_chars_per_line):
				return false
		return true
	if typeof(value) != TYPE_STRING:
		return false
	return _text_within_limits(String(value), max_lines, max_chars_per_line)


func _payload_texts_are_short(payloads: Array) -> bool:
	for payload_variant in payloads:
		var payload: Dictionary = Dictionary(payload_variant)
		if not _text_within_limits(String(payload.get("text", "")), 2, 22):
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


func _is_visual_only_payload(payload: Dictionary) -> bool:
	if not bool(payload.get("visual_only", false)):
		return false
	for forbidden_key in ["command_type", "effect_type", "unit_command", "simulation_effect", "damage", "heal"]:
		if payload.has(forbidden_key):
			return false
	return true


func _is_spoiler_safe(payload: Dictionary) -> bool:
	var text: String = String(payload.get("text", "")).to_lower()
	for forbidden in ["hidden", "enemy", "feind", "kontakt links", "target"]:
		if text.contains(forbidden):
			return false
	return bool(payload.get("spoiler_safe", true))


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
