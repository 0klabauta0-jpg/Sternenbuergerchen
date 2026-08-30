extends SceneTree

const FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_behavior_resolver.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0
var _flank_events: Array = []


class TerrainStub:
	extends RefCounted
	var _tiles: Array = []

	func _init(tiles: Array) -> void:
		_tiles = tiles

	func get_walkable_cover_tiles_in_radius(_world_center: Vector2, _radius: float) -> Array:
		return _tiles


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_101 Fireteam Behavior Resolver Verifier ===")
	_test_cautious_profile_mapping()
	_test_reckless_profile_mapping()
	_test_move_profile_defaults_to_group_travel()
	_test_flank_target_uses_cover_tiles()
	await _test_default_behavior_without_orders()
	await _test_flank_event_is_emitted()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit(1 if _failed > 0 else 0)
func _test_cautious_profile_mapping() -> void:
	var leader = _make_unit("leader_cautious", "blue", true, 0.7, 0.8, ["cautious", "steady"])
	var profile = FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT.call("resolve_profile", "blue", [leader], leader, "flank", Vector2(240.0, 180.0), null)
	var expected_cover_priority: float = clampf(1.0 - float(leader.call("get_toughness_skill")), 0.1, 0.9)
	var expected_suppression: int = maxi(1, floori(float(maxi(1, floori(float(leader.call("get_toughness_skill")) * 5.0))) * 0.5))
	_assert(String(profile.advance_style) == "creep", "Cautious leaders resolve to creep advance style")
	_assert(absf(float(profile.cover_priority) - expected_cover_priority) < 0.001, "Cover priority is derived from 1.0 - toughness")
	_assert(String(profile.fire_discipline) == "semi_disciplined", "High-leadership flank resolves to semi-disciplined fire")
	_assert(absf(float(profile.cohesion_threshold) - 95.0) < 0.001, "Cohesion threshold uses leadership-scaled clamp formula")
	_assert(int(profile.suppression_threshold) == expected_suppression, "Cautious suppression threshold halves the toughness-based baseline")


func _test_reckless_profile_mapping() -> void:
	var leader = _make_unit("leader_reckless", "gold", true, 0.2, 0.4, ["reckless"])
	var profile = FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT.call("resolve_profile", "gold", [leader], leader, "move", Vector2(260.0, 200.0), null)
	var expected_suppression: int = maxi(1, floori(float(leader.call("get_toughness_skill")) * 5.0)) * 3
	_assert(String(profile.advance_style) == "rush", "Reckless leaders resolve to rush advance style")
	_assert(String(profile.fire_discipline) == "hold_fire", "Move orders always resolve to hold_fire discipline")
	_assert(int(profile.suppression_threshold) == expected_suppression, "Reckless suppression threshold triples the toughness-based baseline")


func _test_move_profile_defaults_to_group_travel() -> void:
	var leader = _make_unit("leader_cautious_move", "blue", true, 0.7, 0.8, ["cautious", "steady"])
	var profile = FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT.call("resolve_profile", "blue", [leader], leader, "move", Vector2(240.0, 180.0), null)
	_assert(String(profile.advance_style) == "rush", "Normal move orders use group travel instead of single-member creep")
	_assert(String(profile.fire_discipline) == "hold_fire", "Move group travel still keeps hold-fire discipline")


func _test_flank_target_uses_cover_tiles() -> void:
	var leader = _make_unit("leader_flank", "blue", true, 0.8, 0.55, ["cautious"])
	leader.global_position = Vector2(100.0, 100.0)
	var terrain_stub = TerrainStub.new([
		{"world_position": Vector2(240.0, 176.0), "cover_value": 25},
		{"world_position": Vector2(226.0, 164.0), "cover_value": 90},
	])
	var profile = FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT.call("resolve_profile", "blue", [leader], leader, "flank", Vector2(220.0, 160.0), terrain_stub)
	var metadata: Dictionary = Dictionary(profile.metadata)
	_assert(Vector2(metadata.get("resolved_target_position", Vector2.ZERO)) == Vector2(226.0, 164.0), "Flank resolution prefers high-cover terrain near the rough target")
	_assert(bool(metadata.get("terrain_cover_used", false)), "Resolved flank metadata marks terrain-assisted flank routing")


func _test_default_behavior_without_orders() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	var alpha_driver = scene.get_node("AlphaFlowDriver")
	var charlie_driver = scene.get_node("CharlieFlowDriver")
	var started: bool = controller.call("advance_to_next_phase")
	var behavior_profiles: Array = controller.call("get_active_behavior_profiles_snapshot")
	_assert(started, "Next Phase starts even when no explicit phase plans exist")
	_assert(String(Dictionary(alpha_driver.get("last_issued_order")).get("type", "")) == "defend", "Blue fireteam falls back to a defend/hold default order")
	_assert(String(Dictionary(charlie_driver.get("last_issued_order")).get("type", "")) == "defend", "Gold fireteam also falls back to default hold behavior")
	_assert(behavior_profiles.size() >= 2, "Active behavior profiles are tracked for fireteams without explicit plans")
	scene.queue_free()
	await process_frame


func _test_flank_event_is_emitted() -> void:
	_flank_events.clear()
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	var event_router = scene.get_node("EventRouter")
	if not event_router.flank_initiated.is_connected(_on_flank_initiated):
		event_router.flank_initiated.connect(_on_flank_initiated)
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	var refs: Array = controller.call("_create_waypoints_for_selected_fireteams", Vector2(220.0, 160.0))
	controller.call("_set_waypoint_command_for_targets", refs, "flank")
	var started: bool = controller.call("advance_to_next_phase")
	_assert(started, "Phase start with planned flank succeeds")
	_assert(_flank_events.size() == 1, "Planned flank emits flank_initiated over EventRouter")
	if _flank_events.size() == 1:
		_assert(String(Dictionary(_flank_events[0]).get("fireteam_id", "")) == "blue", "Flank event payload identifies the initiating fireteam")
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


func _on_flank_initiated(fireteam_id: String, _leader: Node, flank_data: Dictionary) -> void:
	var payload: Dictionary = flank_data.duplicate(true)
	payload["fireteam_id"] = fireteam_id
	_flank_events.append(payload)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
