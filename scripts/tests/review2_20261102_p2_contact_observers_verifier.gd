extends SceneTree

const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const TRACKER = preload("res://scripts/tactical/contact_tracker.gd")
const FIRE = preload("res://scripts/tactical/combat_fire_decision_resolver.gd")

class ObserverUnit extends Node2D:
	var unit_id: String = ""
	var fireteam_id: String = "blue"
	var team_id: String = "team_alpha"
	func get_unit_id() -> String:
		return unit_id
	func get_fireteam_id() -> String:
		return fireteam_id
	func get_team_id() -> String:
		return team_id
	func get_active_weapon_id() -> String:
		return "rifle"

class ObserverDriver extends "res://scripts/tests/mission_combat_loop_driver.gd":
	var observer_units: Array = []
	var target_units: Array = []
	func _get_friendly_combat_units() -> Array:
		return observer_units
	func _get_enemy_combat_units() -> Array:
		return target_units
	func _has_valid_los(_attacker, _target) -> bool:
		return true
	func _is_detection_complete(_attacker_id: String, _target_id: String) -> bool:
		return true
	func _start_or_continue_detection(_attacker, _attacker_id: String, _target_id: String) -> void:
		pass
	func _get_known_friendly_fireteam_ids() -> Array:
		return ["blue"]
	func _get_fireteam_leadership_snapshot() -> Dictionary:
		return {"blue": 1.0}
	func _get_tactical_controller():
		return null
	func _get_combat_visibility_cache_audit() -> Dictionary:
		return {"cache_hit_count": 0}

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	if not GUARD.require_isolated_user_data():
		return
	call_deferred("_run")


func _run() -> void:
	print("=== Review 2 P2 contact observer aggregation ===")
	_test_multiple_real_driver_observers_preserve_confirmation_and_fire_chance()
	_test_complete_observer_is_not_downgraded_by_incomplete_observer()
	_test_same_tick_updates_and_los_gap()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_multiple_real_driver_observers_preserve_confirmation_and_fire_chance() -> void:
	for member_count in [1, 2, 4]:
		var driver := ObserverDriver.new()
		var enemy := ObserverUnit.new()
		enemy.unit_id = "enemy"
		enemy.team_id = "team_bravo"
		enemy.fireteam_id = ""
		driver.target_units = [enemy]
		for index in range(member_count):
			var observer := ObserverUnit.new()
			observer.unit_id = "friendly_%d" % index
			driver.observer_units.append(observer)
		for tick in range(1, 61):
			driver.set("_current_tick", tick)
			driver.call("_update_contact_tracking")
		var tracker = driver.get("_contact_tracker")
		var contact: Dictionary = tracker.get_contact_state("blue", "enemy", 60)
		var effect: Dictionary = FIRE.build_damage_effect({"attacker": driver.observer_units[0], "target": enemy, "attacker_id": "friendly_0", "target_id": "enemy", "contact_state": contact.get("detection_state", "")}, {"friendly_team_id": "team_alpha", "spotted_contact_hit_chance_malus": -0.15})
		var hit_chance: float = float(Dictionary(effect.get("effect", {})).get("hit_chance", -1.0))
		_assert(String(contact.get("detection_state", "")) == "confirmed", "%d real driver observers retain a confirmed contact after stable LOS" % member_count)
		_assert(is_equal_approx(hit_chance, 0.45), "%d observers retain the confirmed rifle hit chance of 0.45" % member_count)
		_assert(int(Dictionary(tracker.get("_entries_by_key")).get("blue:enemy", {}).get("los_ticks", 0)) == 60, "%d observers count one LOS tick per simulation tick" % member_count)
		for unit in driver.observer_units + driver.target_units:
			unit.free()
		driver.free()


func _test_complete_observer_is_not_downgraded_by_incomplete_observer() -> void:
	for reverse_order in [false, true]:
		var tracker = TRACKER.new()
		var complete: Dictionary = _observation(true)
		complete["confidence"] = 0.9
		var incomplete: Dictionary = _observation(false)
		incomplete["confidence"] = 0.2
		var observations: Array = [complete, incomplete]
		if reverse_order:
			observations.reverse()
		tracker.update(1, observations, ["blue"])
		_assert(String(tracker.get_contact_state("blue", "enemy", 1).get("detection_state", "")) == "spotted", "Multiple observations cannot confirm on the first LOS tick")
		tracker.update(2, observations, ["blue"])
		var contact: Dictionary = tracker.get_contact_state("blue", "enemy", 2)
		_assert(String(contact.get("detection_state", "")) == "confirmed", "Any complete observer confirms stable LOS regardless of incomplete-observer order")
		_assert(is_equal_approx(float(contact.get("confidence", 0.0)), 0.9), "Aggregation retains the strongest confidence hint")
		_assert(int(Dictionary(tracker.get("_entries_by_key")).get("blue:enemy", {}).get("los_ticks", 0)) == 2, "Observer aggregation applies LOS progression once in a tick")


func _test_same_tick_updates_and_los_gap() -> void:
	var tracker = TRACKER.new()
	tracker.update(1, [_observation(true)], ["blue"])
	tracker.update(2, [_observation(true)], ["blue"])
	tracker.update(2, [_observation(false)], ["blue"])
	_assert(String(tracker.get_contact_state("blue", "enemy", 2).get("detection_state", "")) == "confirmed", "A repeated same-tick incomplete update cannot reset confirmed LOS")
	_assert(int(Dictionary(tracker.get("_entries_by_key")).get("blue:enemy", {}).get("los_ticks", 0)) == 2, "Repeated update in the same tick does not increment or reset LOS duration")
	tracker.update(3, [], ["blue"])
	_assert(String(tracker.get_contact_state("blue", "enemy", 3).get("detection_state", "")) == "lost", "A genuinely missing LOS tick still marks the contact lost")
	tracker.update(4, [_observation(true), _observation(true)], ["blue"])
	_assert(String(tracker.get_contact_state("blue", "enemy", 4).get("detection_state", "")) == "spotted", "Reacquisition after a gap restarts at spotted despite multiple observers")
	tracker.update(5, [_observation(true), _observation(false)], ["blue"])
	_assert(String(tracker.get_contact_state("blue", "enemy", 5).get("detection_state", "")) == "confirmed", "The next consecutive complete LOS tick confirms the reacquired contact")


func _observation(complete: bool) -> Dictionary:
	return {"fireteam_id": " Blue ", "unit_id": "enemy", "team_id": "team_bravo", "last_known_position": Vector2(100.0, 0.0), "detection_complete": complete}


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: ", message)
	else:
		_failed += 1
		print("FAIL: ", message)
