extends SceneTree

const FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tests/fireteam_behavior_resolver.gd")
const TACTICAL_STANCE_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tests/tactical_stance_controller.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_109 Tactical Stance Verifier ===")
	_test_stance_controller_snapshot_roundtrip()
	_test_aggressive_stance_shifts_behavior_profile()
	_test_reckless_leader_mostly_ignores_cautious_request()
	await _test_scene_panel_and_multiselect_application()
	await _test_phase_transition_resets_stances_to_normal()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_stance_controller_snapshot_roundtrip() -> void:
	var controller = TACTICAL_STANCE_CONTROLLER_SCRIPT.new()
	controller.call("set_requested_stance", "blue", "aggressive")
	controller.call("set_requested_stance", "gold", "cautious")
	var snapshot: Dictionary = Dictionary(controller.call("get_stance_snapshot"))
	var restored = TACTICAL_STANCE_CONTROLLER_SCRIPT.new()
	restored.call("load_stance_snapshot", snapshot, PackedStringArray(["blue", "gold"]))
	_assert(String(restored.call("get_requested_stance", "blue")) == "aggressive", "Stance controller roundtrips aggressive stance per fireteam")
	_assert(String(restored.call("get_requested_stance", "gold")) == "cautious", "Stance controller roundtrips cautious stance per fireteam")
	restored.call("reset_fireteams")
	_assert(String(restored.call("get_requested_stance", "blue")) == "normal", "Reset returns fireteam stance to normal")


func _test_aggressive_stance_shifts_behavior_profile() -> void:
	var leader = _make_unit("leader_aggressive", "blue", true, 0.65, 0.75, [])
	var profile = FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT.call("resolve_profile", "blue", [leader], leader, "move", Vector2.ZERO, null, "aggressive")
	_assert(String(profile.tactical_stance) == "aggressive", "Behavior profile stores the requested aggressive stance")
	_assert(String(profile.advance_style) == "rush", "Aggressive stance shifts neutral bounding profile to rush")
	_assert(absf(float(profile.cover_priority) - 0.1) < 0.001, "Aggressive stance lowers cover priority with clamp")
	_assert(int(profile.suppression_threshold) == 5, "Aggressive stance raises suppression threshold")


func _test_reckless_leader_mostly_ignores_cautious_request() -> void:
	var leader = _make_unit("leader_reckless", "gold", true, 0.25, 0.4, ["reckless"])
	var profile = FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT.call("resolve_profile", "gold", [leader], leader, "move", Vector2.ZERO, null, "cautious")
	_assert(String(profile.advance_style) == "rush", "Reckless leader keeps rush style despite cautious request")
	_assert(absf(float(profile.cover_priority) - 0.65) < 0.001, "Reckless leader only gets a minimal cover priority increase from cautious stance")
	_assert(int(profile.suppression_threshold) == 6, "Reckless leader keeps the original suppression threshold under cautious request")


func _test_scene_panel_and_multiselect_application() -> void:
	var scene = await _load_scene()
	var tactical_controller = scene.get_node("TacticalController")
	var panel = tactical_controller.call("_ensure_tactical_stance_panel")
	_assert(panel != null, "Mission scene builds the tactical stance panel")
	tactical_controller.call("_set_selected_fireteams", PackedStringArray(["blue", "gold"]), false)
	var applied: bool = bool(tactical_controller.call("set_selected_fireteams_tactical_stance", "aggressive"))
	var snapshot: Dictionary = Dictionary(tactical_controller.call("get_tactical_stances_snapshot"))
	_assert(applied, "Selected fireteams accept a shared stance request")
	_assert(String(snapshot.get("blue", "")) == "aggressive", "Blue fireteam stores aggressive stance from multiselect")
	_assert(String(snapshot.get("gold", "")) == "aggressive", "Gold fireteam stores aggressive stance from multiselect")
	scene.queue_free()
	await process_frame


func _test_phase_transition_resets_stances_to_normal() -> void:
	var scene = await _load_scene()
	var tactical_controller = scene.get_node("TacticalController")
	tactical_controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	tactical_controller.call("set_selected_fireteams_tactical_stance", "cautious")
	var started: bool = bool(tactical_controller.call("advance_to_next_phase"))
	var snapshot: Dictionary = Dictionary(tactical_controller.call("get_tactical_stances_snapshot"))
	var profiles: Array = Array(tactical_controller.call("get_active_behavior_profiles_snapshot"))
	var blue_profile: Dictionary = {}
	for profile_variant in profiles:
		if typeof(profile_variant) != TYPE_DICTIONARY:
			continue
		var profile_dict: Dictionary = Dictionary(profile_variant)
		if String(profile_dict.get("fireteam_id", "")) == "blue":
			blue_profile = profile_dict
			break
	_assert(started, "Next phase still starts after a stance request")
	_assert(snapshot.is_empty(), "Phase transition resets mission stances back to normal")
	_assert(String(blue_profile.get("tactical_stance", "")) == "normal", "Freshly activated behavior profiles use normal stance after a phase change")
	scene.queue_free()
	await process_frame


func _load_scene() -> Node:
	var scene = load("res://scenes/tests/mission_reactivity_test.tscn").instantiate()
	root.add_child(scene)
	for _index in range(10):
		await process_frame
	return scene


func _make_unit(uid: String, fireteam_id: String, is_lead: bool, leadership: float, toughness: float, traits: Array) -> Node2D:
	var unit = TEST_UNIT_SCRIPT.new()
	unit.unit_id = uid
	unit.team_id = "team_alpha"
	unit.fireteam_id = fireteam_id
	unit.is_fireteam_lead = is_lead
	unit.skill_leadership = leadership
	unit.skill_toughness = toughness
	unit.trait_ids = PackedStringArray(traits)
	unit.position = Vector2.ZERO
	unit._ready()
	return unit


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
