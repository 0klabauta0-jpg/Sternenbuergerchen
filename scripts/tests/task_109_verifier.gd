extends SceneTree

const FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_behavior_resolver.gd")
const TACTICAL_STANCE_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_stance_controller.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_109 Tactical Stance Verifier ===")
	_test_stance_controller_snapshot_roundtrip()
	_test_unit_badge_and_remote_snapshot_sync()
	_test_aggressive_stance_shifts_behavior_profile()
	_test_reckless_leader_mostly_ignores_cautious_request()
	await _test_scene_panel_and_multiselect_application()
	await _test_scene_stance_sync_bridge()
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
	var sync_state: Dictionary = Dictionary(controller.call("get_sync_state"))
	var restored = TACTICAL_STANCE_CONTROLLER_SCRIPT.new()
	restored.call("load_sync_state", sync_state, PackedStringArray(["blue", "gold"]))
	_assert(String(restored.call("get_requested_stance", "blue")) == "aggressive", "Stance controller roundtrips aggressive stance per fireteam")
	_assert(String(restored.call("get_requested_stance", "gold")) == "cautious", "Stance controller roundtrips cautious stance per fireteam")
	_assert(int(sync_state.get("revision", 0)) == 2, "Stance controller sync state increments revision for each real stance change")
	_assert(int(restored.call("get_sync_revision")) == 2, "Restored stance controller preserves sync revision from sync state")
	var legacy_restored = TACTICAL_STANCE_CONTROLLER_SCRIPT.new()
	legacy_restored.call("load_stance_snapshot", snapshot, PackedStringArray(["blue", "gold"]))
	_assert(String(legacy_restored.call("get_requested_stance", "blue")) == "aggressive", "Legacy stance snapshot loading still accepts aggressive fireteam state")
	restored.call("reset_fireteams")
	_assert(String(restored.call("get_requested_stance", "blue")) == "normal", "Reset returns fireteam stance to normal")
	_assert(int(restored.call("get_sync_revision")) == 3, "Reset advances sync revision once for the cleared stance state")


func _test_unit_badge_and_remote_snapshot_sync() -> void:
	var unit = _make_unit("badge_unit", "blue", false, 0.55, 0.55, [])
	unit.call("set_tactical_stance_indicator", "aggressive", 4)
	_assert(String(unit.call("get_tactical_stance_badge_text")) == "A", "TestUnit renders aggressive stance as in-world badge A")
	var badge_snapshot: Dictionary = Dictionary(unit.call("get_tactical_stance_badge_snapshot"))
	_assert(String(badge_snapshot.get("tactical_stance", "")) == "aggressive", "TestUnit exposes tactical stance in its snapshot fragment")
	_assert(int(badge_snapshot.get("tactical_stance_revision", -1)) == 4, "TestUnit carries the stance sync revision in its snapshot fragment")
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	var unit_snapshot: Dictionary = Dictionary(simulation_root.call("_build_unit_snapshot", unit))
	_assert(String(unit_snapshot.get("tactical_stance", "")) == "aggressive", "SimulationRoot includes tactical stance badge data in unit snapshots")
	_assert(int(unit_snapshot.get("tactical_stance_revision", -1)) == 4, "SimulationRoot includes stance revision in unit snapshots")
	unit.call("apply_remote_snapshot", {"tactical_stance": "cautious", "tactical_stance_revision": 3})
	_assert(String(unit.call("get_tactical_stance_badge_text")) == "A", "Older remote stance revisions do not overwrite newer local badge state")
	unit.call("apply_remote_snapshot", {"tactical_stance": "cautious", "tactical_stance_revision": 5})
	_assert(String(unit.call("get_tactical_stance_badge_text")) == "C", "Newer remote stance revisions update the in-world badge")
	simulation_root.free()
	unit.free()


func _test_aggressive_stance_shifts_behavior_profile() -> void:
	var leader = _make_unit("leader_aggressive", "blue", true, 0.65, 0.75, [])
	var profile = FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT.call("resolve_profile", "blue", [leader], leader, "move", Vector2.ZERO, null, "aggressive")
	_assert(String(profile.tactical_stance) == "aggressive", "Behavior profile stores the requested aggressive stance")
	_assert(String(profile.advance_style) == "rush", "Aggressive stance shifts neutral bounding profile to rush")
	_assert(absf(float(profile.cover_priority) - 0.1) < 0.001, "Aggressive stance lowers cover priority with clamp")
	_assert(int(profile.suppression_threshold) == 4, "Aggressive stance raises suppression threshold against the current toughness formula")
	leader.free()


func _test_reckless_leader_mostly_ignores_cautious_request() -> void:
	var leader = _make_unit("leader_reckless", "gold", true, 0.25, 0.4, ["reckless"])
	var profile = FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT.call("resolve_profile", "gold", [leader], leader, "move", Vector2.ZERO, null, "cautious")
	_assert(String(profile.advance_style) == "rush", "Reckless leader keeps rush style despite cautious request")
	_assert(absf(float(profile.cover_priority) - 0.8) < 0.001, "Reckless leader only gets a minimal cover priority increase from cautious stance")
	_assert(int(profile.suppression_threshold) == 3, "Reckless leader keeps the original suppression threshold under cautious request")
	leader.free()


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
	var blue_unit = _find_friendly_unit(scene, "blue")
	_assert(blue_unit != null and String(blue_unit.call("get_tactical_stance_badge_text")) == "A", "Blue operators show the shared aggressive stance directly on the unit badge")
	await process_frame
	var blue_mini_card := tactical_controller.get_node_or_null("../TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox/FireteamMiniCard_Blue")
	var cautious_button := blue_mini_card.get_node_or_null("Margin/VBox/HeaderRow/StanceToggle/StanceCButton") if blue_mini_card != null else null
	_assert(cautious_button != null and bool(cautious_button.get_meta("mission_fireteam_stance_button", false)), "Fireteam mini card exposes a direct tactical stance toggle")
	tactical_controller.call("_on_fireteam_mini_stance_button_pressed", "blue", "cautious")
	var direct_snapshot: Dictionary = Dictionary(tactical_controller.call("get_tactical_stances_snapshot"))
	_assert(String(direct_snapshot.get("blue", "")) == "cautious", "Mini-card stance toggle can update one fireteam directly")
	var hierarchy: Dictionary = Dictionary(tactical_controller.call("get_command_hierarchy_snapshot"))
	var stance_action: Dictionary = Dictionary(Dictionary(hierarchy.get("actions_by_id", {})).get("tactical_stance", {}))
	_assert(bool(stance_action.get("implemented", false)) and not bool(stance_action.get("status_only", true)), "Command hierarchy exposes tactical stance as a direct rule control")
	scene.queue_free()
	await process_frame


func _test_scene_stance_sync_bridge() -> void:
	var scene = await _load_scene()
	var tactical_controller = scene.get_node("TacticalController")
	tactical_controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	tactical_controller.call("set_selected_fireteams_tactical_stance", "cautious")
	var sync_state: Dictionary = Dictionary(tactical_controller.call("get_tactical_stance_sync_state"))
	var planning_state: Dictionary = Dictionary(tactical_controller.call("get_planning_state"))
	var mirrored_scene = await _load_scene()
	var mirrored_controller = mirrored_scene.get_node("TacticalController")
	mirrored_controller.call("set_planning_state", planning_state)
	var mirrored_sync_state: Dictionary = Dictionary(mirrored_controller.call("get_tactical_stance_sync_state"))
	var mirrored_blue_unit = _find_friendly_unit(mirrored_scene, "blue")
	_assert(int(sync_state.get("revision", 0)) > 0, "Mission controller exposes a revisioned stance sync state for future multiplayer transport")
	_assert(String(Dictionary(sync_state.get("stances", {})).get("blue", "")) == "cautious", "Mission stance sync state carries the normalized fireteam stance dictionary")
	_assert(planning_state.has("tactical_stance_sync"), "Planning state includes the dedicated tactical stance sync fragment")
	_assert(int(mirrored_sync_state.get("revision", -1)) == int(sync_state.get("revision", -2)), "Planning state bridge preserves stance sync revisions between mission instances")
	_assert(mirrored_blue_unit != null and String(mirrored_blue_unit.call("get_tactical_stance_badge_text")) == "C", "Mirrored mission instances rebuild the same in-world unit badge from the sync fragment")
	scene.queue_free()
	mirrored_scene.queue_free()
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


func _find_friendly_unit(scene: Node, fireteam_id: String) -> Node:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	for child in scene.get_children():
		if child == null or not child.has_method("get_team_id") or not child.has_method("get_fireteam_id"):
			continue
		if String(child.call("get_team_id")).strip_edges() != "team_alpha":
			continue
		if String(child.call("get_fireteam_id")).strip_edges().to_lower() != normalized_fireteam_id:
			continue
		return child
	return null


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
