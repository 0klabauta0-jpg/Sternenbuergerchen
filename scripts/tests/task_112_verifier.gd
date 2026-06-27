extends SceneTree

const CONTACT_TRACKER_SCRIPT: GDScript = preload("res://scripts/tactical/contact_tracker.gd")
const CONTACT_MAP_OVERLAY_SCRIPT: GDScript = preload("res://scripts/tactical/visuals/contact_map_overlay.gd")
const FIRETEAM_SECURITY_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_security_controller.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_112 Contact Tracker + Contact Overlay Verifier ===")
	_test_contact_tracker_progresses_spotted_to_confirmed()
	_test_contact_tracker_relays_confirmed_contacts_with_delay()
	_test_security_controller_consumes_suspected_contact_entries()
	_test_contact_overlay_aggregates_selected_fireteam_contacts()
	await _test_scene_exposes_contact_snapshot_and_overlay()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_contact_tracker_progresses_spotted_to_confirmed() -> void:
	var tracker = CONTACT_TRACKER_SCRIPT.new()
	var fireteams: Array = ["blue", "gold"]
	var leaderships: Dictionary = {"blue": 0.8, "gold": 0.4}
	var changed_a: bool = bool(tracker.update(1, [_build_observation("blue", "enemy_a", Vector2(48.0, 0.0), false)], fireteams, leaderships))
	var first_state: Dictionary = tracker.get_contact_state("blue", "enemy_a")
	var changed_b: bool = bool(tracker.update(2, [_build_observation("blue", "enemy_a", Vector2(52.0, 0.0), true)], fireteams, leaderships))
	var second_state: Dictionary = tracker.get_contact_state("blue", "enemy_a")
	_assert(changed_a and changed_b, "Tracker reports changes when LOS observations update a contact")
	_assert(String(first_state.get("detection_state", "")) == "spotted", "Fresh LOS contact starts as spotted")
	_assert(String(second_state.get("detection_state", "")) == "confirmed", "Stable LOS contact upgrades to confirmed")


func _test_contact_tracker_relays_confirmed_contacts_with_delay() -> void:
	var tracker = CONTACT_TRACKER_SCRIPT.new()
	var fireteams: Array = ["blue", "gold"]
	var leaderships: Dictionary = {"blue": 0.0, "gold": 0.7}
	tracker.update(1, [_build_observation("blue", "enemy_relay", Vector2(80.0, 8.0), false)], fireteams, leaderships)
	tracker.update(2, [_build_observation("blue", "enemy_relay", Vector2(86.0, 8.0), true)], fireteams, leaderships)
	var relay_delay_ticks: int = int(ceil(3.0 * float(Engine.physics_ticks_per_second)))
	var before_relay: Dictionary = tracker.get_contact_state("gold", "enemy_relay")
	tracker.update(2 + relay_delay_ticks, [], fireteams, leaderships)
	var after_relay: Dictionary = tracker.get_contact_state("gold", "enemy_relay")
	_assert(before_relay.is_empty(), "Other fireteams do not receive a delayed relay before the scheduled tick")
	_assert(String(after_relay.get("detection_state", "")) == "suspected", "Delayed contact sharing promotes receivers to at least suspected")
	_assert(Vector2(after_relay.get("last_known_position", Vector2.ZERO)).distance_to(Vector2(86.0, 8.0)) < 0.01, "Relayed contacts keep the last known confirmed position")


func _test_security_controller_consumes_suspected_contact_entries() -> void:
	var controller = FIRETEAM_SECURITY_CONTROLLER_SCRIPT.new()
	var leader = _make_unit("contact_lead", "blue", true, Vector2(0.0, 0.0), 0.42, 0.62, 0.35, ["aggressive"])
	var wing = _make_unit("contact_wing", "blue", false, Vector2(10.0, 10.0), 0.48, 0.55, 0.28, [])
	var state: Dictionary = controller.update_fireteam_state(
		"blue",
		[leader, wing],
		leader,
		_build_behavior_profile("hold_position"),
		{},
		{},
		{},
		[{
			"fireteam_id": "blue",
			"unit_id": "enemy_hint",
			"team_id": "team_bravo",
			"last_known_position": Vector2(120.0, 0.0),
			"detection_state": "suspected",
			"detected_by": ["blue"],
			"last_updated_tick": 5,
		}]
	)
	_assert(String(state.get("security_mode", "")) == "directional", "Suspected contacts are sufficient to orient directional security")
	_assert(Vector2(state.get("main_threat_position", Vector2.ZERO)).distance_to(Vector2(120.0, 0.0)) < 0.01, "Security state exposes the contact tracker's last known threat position")
	_cleanup_units([leader, wing])


func _test_contact_overlay_aggregates_selected_fireteam_contacts() -> void:
	var overlay = CONTACT_MAP_OVERLAY_SCRIPT.new()
	root.add_child(overlay)
	overlay.set_selected_fireteam_ids(PackedStringArray(["blue"]))
	overlay.set_contact_entries([
		{
			"fireteam_id": "blue",
			"unit_id": "enemy_overlay",
			"last_known_position": Vector2(12.0, 18.0),
			"detection_state": "suspected",
			"last_updated_tick": 3,
		},
		{
			"fireteam_id": "blue",
			"unit_id": "enemy_overlay",
			"last_known_position": Vector2(12.0, 18.0),
			"detection_state": "confirmed",
			"last_updated_tick": 4,
		},
		{
			"fireteam_id": "gold",
			"unit_id": "enemy_other",
			"last_known_position": Vector2(32.0, 18.0),
			"detection_state": "confirmed",
			"last_updated_tick": 4,
		},
	])
	var visible_contacts: Array = overlay.get_visible_contacts()
	_assert(visible_contacts.size() == 1, "Overlay filters contacts to the selected fireteam set")
	if visible_contacts.size() == 1:
		_assert(String(Dictionary(visible_contacts[0]).get("detection_state", "")) == "confirmed", "Overlay keeps the highest-confidence state per visible enemy contact")
	overlay.queue_free()


func _test_scene_exposes_contact_snapshot_and_overlay() -> void:
	var scene = await _load_scene()
	var tactical_controller = scene.get_node("TacticalController")
	var combat_driver = scene.get_node("CombatLoopDriver")
	var started: bool = tactical_controller.call("advance_to_next_phase")
	for _index in range(6):
		await process_frame
	var friendly_units: Array = Array(tactical_controller.call("_get_all_friendly_units", false))
	var enemy_units: Array = Array(tactical_controller.call("_get_all_enemy_units", false))
	if not friendly_units.is_empty() and not enemy_units.is_empty():
		var friendly = friendly_units[0]
		var enemy = enemy_units[0]
		if friendly is Node2D and enemy is Node2D:
			(enemy as Node2D).global_position = (friendly as Node2D).global_position + Vector2(58.0, 0.0)
	combat_driver.call("_update_contact_tracking")
	combat_driver.call("_advance_detection_timers")
	combat_driver.call("_update_contact_tracking")
	tactical_controller.call("refresh_contact_overlay")
	for _index in range(10):
		await process_frame
	var tactical_snapshot: Array = Array(tactical_controller.call("get_contact_snapshot"))
	var combat_snapshot: Array = Array(combat_driver.call("get_contact_snapshot"))
	var overlay = scene.get_node_or_null("ContactMapOverlay")
	_assert(started, "Mission scene starts successfully for contact integration")
	_assert(overlay != null, "Mission scene attaches a ContactMapOverlay node")
	_assert(not tactical_snapshot.is_empty(), "Tactical controller exposes live contact tracker snapshots")
	_assert(_contact_snapshots_share_core_fields(tactical_snapshot, combat_snapshot), "Tactical controller preserves combat contact core fields while allowing UI/report enrichment")
	scene.queue_free()
	await process_frame


func _build_observation(fireteam_id: String, enemy_unit_id: String, position_value: Vector2, detection_complete: bool) -> Dictionary:
	return {
		"fireteam_id": fireteam_id,
		"unit_id": enemy_unit_id,
		"team_id": "team_bravo",
		"last_known_position": position_value,
		"detection_complete": detection_complete,
	}


func _contact_snapshots_share_core_fields(tactical_snapshot: Array, combat_snapshot: Array) -> bool:
	if tactical_snapshot.size() != combat_snapshot.size():
		return false
	var tactical_by_key: Dictionary = _index_contacts_by_key(tactical_snapshot)
	var combat_by_key: Dictionary = _index_contacts_by_key(combat_snapshot)
	if tactical_by_key.keys().size() != combat_by_key.keys().size():
		return false
	for key_variant in combat_by_key.keys():
		var key: String = String(key_variant)
		if not tactical_by_key.has(key):
			return false
		var tactical: Dictionary = Dictionary(tactical_by_key.get(key, {}))
		var combat: Dictionary = Dictionary(combat_by_key.get(key, {}))
		for field in ["fireteam_id", "unit_id", "team_id", "detection_state", "last_known_position", "last_updated_tick"]:
			if tactical.get(String(field), null) != combat.get(String(field), null):
				return false
	return true


func _index_contacts_by_key(snapshot: Array) -> Dictionary:
	var result: Dictionary = {}
	for contact_variant in snapshot:
		if typeof(contact_variant) != TYPE_DICTIONARY:
			continue
		var contact: Dictionary = Dictionary(contact_variant)
		var key: String = "%s:%s" % [
			String(contact.get("fireteam_id", "")).strip_edges().to_lower(),
			String(contact.get("unit_id", contact.get("target_id", ""))).strip_edges(),
		]
		if key.strip_edges() == ":":
			continue
		result[key] = contact
	return result


func _build_behavior_profile(command_type: String) -> Dictionary:
	return {
		"fireteam_id": "blue",
		"metadata": {
			"origin_command_type": command_type,
			"origin": "standard_behavior",
		},
	}


func _make_unit(unit_id: String, fireteam_id: String, is_lead: bool, position_value: Vector2, speed: float, accuracy: float, leadership: float, traits: Array) -> Node2D:
	var unit = TEST_UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.display_name = unit_id
	unit.team_id = "team_alpha"
	unit.fireteam_id = fireteam_id
	unit.is_fireteam_lead = is_lead
	unit.skill_speed = speed
	unit.skill_accuracy = accuracy
	unit.skill_leadership = leadership
	unit.skill_toughness = 0.55
	unit.trait_ids = PackedStringArray(traits)
	unit.position = position_value
	unit._ready()
	root.add_child(unit)
	return unit


func _cleanup_units(units: Array) -> void:
	for unit in units:
		if unit != null:
			unit.queue_free()


func _load_scene() -> Node:
	var scene = load("res://scenes/tests/mission_reactivity_test.tscn").instantiate()
	root.add_child(scene)
	for _index in range(10):
		await process_frame
	return scene


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
