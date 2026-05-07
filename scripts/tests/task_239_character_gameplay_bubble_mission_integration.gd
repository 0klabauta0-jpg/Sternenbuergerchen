extends SceneTree

const CHARACTER_GAMEPLAY_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/character_gameplay_resolver.gd")
const ROSTER_RELATIONSHIP_MODEL_SCRIPT: GDScript = preload("res://scripts/meta/roster_relationship_model.gd")
const FTL_RESOLVER_SCRIPT: GDScript = preload("res://scripts/ui/fireteamleader_feedback_bubble_resolver.gd")
const NPC_THOUGHT_RESOLVER_SCRIPT: GDScript = preload("res://scripts/ui/npc_thought_bubble_resolver.gd")
const MULTIPLAYER_SNAPSHOT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_snapshot_contract.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const MISSION_COMBAT_LOOP_DRIVER_SCRIPT: GDScript = preload("res://scripts/tests/mission_combat_loop_driver.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_239 Character Gameplay Bubble Mission Integration ===")
	_test_central_resolver_builds_small_modifiers()
	_test_ftl_bubbles_react_to_leadership_and_character_context()
	_test_frustration_changes_npc_thought_without_command_effect()
	_test_multiplayer_snapshot_strips_private_character_data()
	_test_mission_driver_exposes_public_character_gameplay_snapshot()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_central_resolver_builds_small_modifiers() -> void:
	var units: Array = _build_relationship_units(0.34, 0.84, 0.14)
	var context: Dictionary = Dictionary(CHARACTER_GAMEPLAY_RESOLVER_SCRIPT.call("build_fireteam_character_context", "blue", units))
	var modifiers: Dictionary = Dictionary(context.get("gameplay_modifiers", {}))
	_assert(String(context.get("source", "")) == "character_gameplay_resolver", "CharacterGameplayResolver exposes central source ID")
	_assert(String(context.get("scan_policy", "")) == "summarized_context_not_per_frame", "Resolver documents no per-frame relationship scan policy")
	_assert(int(context.get("relationship_pair_scan_count", 0)) <= 1, "Two-person fireteam scans one relationship pair in summary")
	_assert(_modifiers_are_small(modifiers), "Character gameplay modifiers stay small and bounded")
	_assert(Array(context.get("member_states", [])).size() == 2, "Resolver produces per-member character summaries")


func _test_ftl_bubbles_react_to_leadership_and_character_context() -> void:
	var high_leader: Node2D = _make_unit("task239_high_lead", "blue", true, "rifleman", Vector2(120.0, 120.0), 0.90, 0.82)
	var low_leader: Node2D = _make_unit("task239_low_lead", "blue", true, "rifleman", Vector2(160.0, 120.0), 0.20, 0.22)
	var high_payload: Dictionary = Dictionary(FTL_RESOLVER_SCRIPT.call(
		"build_command_feedback",
		"move",
		"accepted",
		high_leader,
		high_leader.global_position,
		{},
		{"fireteam_id": "blue", "fireteam_units": [high_leader]}
	))
	var low_payload: Dictionary = Dictionary(FTL_RESOLVER_SCRIPT.call(
		"build_command_feedback",
		"move",
		"accepted",
		low_leader,
		low_leader.global_position,
		{},
		{"fireteam_id": "blue", "fireteam_units": [low_leader]}
	))
	_assert(bool(high_payload.get("ok", false)) and bool(low_payload.get("ok", false)), "FTL bubbles build with character context")
	_assert(String(high_payload.get("skill_tier", "")) == "high", "High leadership resolves to high FTL tier")
	_assert(String(low_payload.get("skill_tier", "")) == "low", "Low leadership resolves to low FTL tier")
	_assert(String(high_payload.get("text", "")) != String(low_payload.get("text", "")), "Same command has different FTL bubble text by leadership")
	_assert(String(high_payload.get("character_gameplay_source", "")) == "character_gameplay_resolver", "FTL bubble keeps character gameplay source metadata")
	_assert(_is_visual_only_payload(high_payload) and _is_visual_only_payload(low_payload), "FTL character bubble does not create command effects")
	high_leader.free()
	low_leader.free()


func _test_frustration_changes_npc_thought_without_command_effect() -> void:
	var unit: Node2D = _make_unit("task239_frustrated", "blue", false, "rifleman", Vector2(96.0, 160.0), 0.55, 0.55)
	var context: Dictionary = {
		"selected": true,
		"unit_character_state_by_id": {
			"task239_frustrated": {
				"unit_id": "task239_frustrated",
				"fireteam_id": "blue",
				"progression": {"morale": 0.22, "frustration": 0.88},
				"skill_values": {"leadership": 0.55, "accuracy": 0.55, "speed": 0.55, "toughness": 0.55, "awareness": 0.55, "discipline": 0.55},
			}
		},
	}
	var payload: Dictionary = Dictionary(NPC_THOUGHT_RESOLVER_SCRIPT.call("build_unit_thought", unit, {}, context))
	_assert(bool(payload.get("ok", false)), "NPC thought payload builds for frustrated unit")
	_assert(String(payload.get("text_source", "")) == "character_gameplay_resolver", "Frustration thought comes from character gameplay resolver")
	_assert(String(payload.get("thought_kind", "")) == "character:frustration", "High frustration changes thought kind")
	_assert(String(payload.get("character_frustration_state", "")) == "high", "Thought payload exposes safe frustration state")
	_assert(_is_visual_only_payload(payload), "Frustration thought has no illegal command effect")
	unit.free()


func _test_multiplayer_snapshot_strips_private_character_data() -> void:
	var contract = MULTIPLAYER_SNAPSHOT_CONTRACT_SCRIPT.new()
	var snapshot: Dictionary = Dictionary(contract.call("build_state_snapshot", {
		"tick": 4,
		"character_gameplay": [
			{
				"source": "character_gameplay_resolver",
				"fireteam_id": "blue",
				"cohesion_label": "strong",
				"cohesion_percent": 78,
				"morale_state": "steady",
				"frustration_state": "managed",
				"communication_label": "clear",
				"member_count": 2,
				"display_name": "Private Name",
				"progression": {"morale": 0.42, "frustration": 0.2},
				"relationship_links": [{"target_unit_id": "secret"}],
			}
		],
	}))
	var entries: Array = Array(snapshot.get("character_gameplay", []))
	_assert(entries.size() == 1, "Multiplayer snapshot keeps public character gameplay entry")
	var entry: Dictionary = Dictionary(entries[0])
	_assert(String(entry.get("fireteam_id", "")) == "blue", "Public character gameplay snapshot keeps fireteam id")
	_assert(not entry.has("display_name") and not entry.has("progression") and not entry.has("relationship_links"), "Snapshot strips private roster details")
	_assert(not bool(CHARACTER_GAMEPLAY_RESOLVER_SCRIPT.call("snapshot_has_private_fields", entries)), "CharacterGameplayResolver privacy audit accepts snapshot")
	var metrics: Dictionary = Dictionary(contract.call("build_serialization_metrics", snapshot))
	_assert(int(Dictionary(metrics.get("field_counts", {})).get("character_gameplay_count", 0)) == 1, "Serialization metrics count character gameplay entries")


func _test_mission_driver_exposes_public_character_gameplay_snapshot() -> void:
	var driver: Node = MISSION_COMBAT_LOOP_DRIVER_SCRIPT.new()
	driver.name = "Driver"
	var first: Node2D = _make_unit("task239_driver_a", "blue", true, "rifleman", Vector2(120.0, 180.0), 0.82, 0.72)
	first.name = "DriverA"
	var second: Node2D = _make_unit("task239_driver_b", "blue", false, "medic", Vector2(150.0, 180.0), 0.42, 0.58)
	second.name = "DriverB"
	driver.add_child(first)
	driver.add_child(second)
	var friendly_paths: Array[NodePath] = [NodePath("DriverA"), NodePath("DriverB")]
	driver.set("friendly_unit_paths", friendly_paths)
	var snapshot: Array = Array(driver.call("get_character_gameplay_snapshot"))
	_assert(snapshot.size() == 1, "Mission combat driver exposes one public fireteam character snapshot")
	if snapshot.is_empty():
		driver.free()
		return
	var entry: Dictionary = Dictionary(snapshot[0])
	_assert(String(entry.get("fireteam_id", "")) == "blue", "Mission driver snapshot is keyed by fireteam")
	_assert(not entry.has("relationship_links") and not entry.has("progression"), "Mission driver snapshot does not expose private character data")
	driver.free()


func _build_relationship_units(affinity: float, morale: float, frustration: float) -> Array:
	var first: Dictionary = {
		"unit_id": "task239_a",
		"display_name": "A",
		"fireteam_id": "blue",
		"role_id": "leader",
		"skill_values": {"leadership": 0.82, "accuracy": 0.58, "speed": 0.55, "toughness": 0.55, "awareness": 0.65, "discipline": 0.68},
		"communication_values": {"speech_quality": 0.78, "discipline": 0.68},
		"progression": {"morale": morale, "frustration": frustration},
	}
	var second: Dictionary = {
		"unit_id": "task239_b",
		"display_name": "B",
		"fireteam_id": "blue",
		"role_id": "medic",
		"skill_values": {"leadership": 0.42, "accuracy": 0.48, "speed": 0.62, "toughness": 0.60, "awareness": 0.58, "discipline": 0.64},
		"communication_values": {"speech_quality": 0.62, "discipline": 0.64},
		"progression": {"morale": morale, "frustration": frustration},
	}
	var pair: Dictionary = Dictionary(ROSTER_RELATIONSHIP_MODEL_SCRIPT.call("make_pair", "task239_a", "task239_b", affinity, ["trusts"] if affinity >= 0.0 else ["tension"], "task239", true))
	return ROSTER_RELATIONSHIP_MODEL_SCRIPT.call("apply_relationships_to_units", [first, second], [pair], true)


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
	unit.skill_speed = skill_value
	unit.skill_toughness = skill_value
	unit.discipline = skill_value
	unit.awareness = skill_value
	unit.speech_quality = leadership
	unit.position = world_position
	unit._ready()
	return unit


func _modifiers_are_small(modifiers: Dictionary) -> bool:
	for key in ["communication_modifier", "coordination_modifier", "advance_readability_modifier", "ftl_clarity_modifier"]:
		if absf(float(modifiers.get(key, 0.0))) > 0.051:
			return false
	return true


func _is_visual_only_payload(payload: Dictionary) -> bool:
	if not bool(payload.get("visual_only", false)):
		return false
	for forbidden_key in ["command_type", "effect_type", "unit_command", "simulation_effect", "damage", "heal", "relationship_links", "progression"]:
		if payload.has(forbidden_key):
			return false
	return true


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
