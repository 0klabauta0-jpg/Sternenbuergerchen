extends SceneTree

const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const TRACKER = preload("res://scripts/tactical/contact_tracker.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	if not GUARD.require_isolated_user_data():
		return
	call_deferred("_run")


func _run() -> void:
	print("=== Review 2 P2 contact relay deadlines ===")
	_test_continuous_los_delivers_at_the_first_deadline_with_the_latest_payload()
	_test_pending_relay_survives_source_los_loss()
	_test_relay_does_not_overwrite_fresh_receiver_los()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_continuous_los_delivers_at_the_first_deadline_with_the_latest_payload() -> void:
	# Literal existing 60 Hz delays; 0.8 leadership retains the current ceil
	# rounding to 21 ticks. This task does not change leadership balance.
	_assert(Engine.physics_ticks_per_second == 60, "Relay deadline fixtures use the project's 60 Hz physics rate")
	for fixture in [{"leadership": 0.0, "delay": 180}, {"leadership": 0.4, "delay": 100}, {"leadership": 0.8, "delay": 21}, {"leadership": 1.0, "delay": 0}]:
		var tracker = TRACKER.new()
		var expected_delivery_tick: int = 2 + int(fixture["delay"])
		var first_delivery_tick: int = -1
		for tick in range(1, expected_delivery_tick + 1):
			tracker.update(tick, [_observation("blue", tick)], ["blue", "gold"], {"blue": fixture["leadership"]})
			if first_delivery_tick < 0 and not tracker.get_contact_state("gold", "enemy", tick).is_empty():
				first_delivery_tick = tick
		var contact: Dictionary = tracker.get_contact_state("gold", "enemy", expected_delivery_tick)
		_assert(first_delivery_tick == expected_delivery_tick, "Leadership %.1f relay delivers at first confirmation plus %d ticks during continuous LOS" % [fixture["leadership"], fixture["delay"]])
		_assert(String(contact.get("detection_state", "")) == "suspected", "Relay receiver receives suspected knowledge without inventing direct LOS")
		_assert(Vector2(contact.get("last_known_position", Vector2.ZERO)) == Vector2(expected_delivery_tick, 8.0), "Pending relay refreshes position through its original deadline")
		_assert(int(contact.get("last_seen_tick", -1)) == expected_delivery_tick, "Delivered relay reports the latest source observation tick")
		_assert(Array(contact.get("detected_by", [])) == ["blue", "gold"], "Relay retains source and receiver provenance")


func _test_pending_relay_survives_source_los_loss() -> void:
	var tracker = TRACKER.new()
	for tick in range(1, 4):
		tracker.update(tick, [_observation("blue", tick)], ["blue", "gold"], {"blue": 0.8})
	tracker.update(4, [], ["blue", "gold"], {"blue": 0.8})
	tracker.update(22, [], ["blue", "gold"], {"blue": 0.8})
	_assert(tracker.get_contact_state("gold", "enemy", 22).is_empty(), "Loss of source LOS does not bypass leadership delay")
	tracker.update(23, [], ["blue", "gold"], {"blue": 0.8})
	var contact: Dictionary = tracker.get_contact_state("gold", "enemy", 23)
	_assert(String(contact.get("detection_state", "")) == "suspected", "Already queued report still arrives at its original deadline after LOS loss")
	_assert(Vector2(contact.get("last_known_position", Vector2.ZERO)) == Vector2(3.0, 8.0) and int(contact.get("last_seen_tick", -1)) == 3, "Relay after LOS loss keeps the last actual source observation and its age")
	_assert(String(tracker.get_contact_state("blue", "enemy", 23).get("detection_state", "")) == "lost", "Delayed knowledge does not restore the source's lost visual contact")


func _test_relay_does_not_overwrite_fresh_receiver_los() -> void:
	var tracker = TRACKER.new()
	for tick in range(1, 24):
		var source: Dictionary = _observation("blue", tick)
		var receiver: Dictionary = _observation("gold", tick)
		receiver["last_known_position"] = Vector2(900.0 + tick, 0.0)
		tracker.update(tick, [source, receiver], ["blue", "gold"], {"blue": 0.8, "gold": 0.0})
	var contact: Dictionary = tracker.get_contact_state("gold", "enemy", 23)
	_assert(String(contact.get("detection_state", "")) == "confirmed", "Incoming relay cannot downgrade a receiver with continuous direct LOS on the following tick")
	_assert(Vector2(contact.get("last_known_position", Vector2.ZERO)) == Vector2(923.0, 0.0), "Fresh direct receiver observation wins over relayed position")
	_assert(int(Dictionary(tracker.get("_entries_by_key")).get("gold:enemy", {}).get("los_ticks", 0)) == 23, "Relay delivery preserves the receiver's own continuous LOS count")


func _observation(fireteam_id: String, tick: int) -> Dictionary:
	return {"fireteam_id": fireteam_id, "unit_id": "enemy", "team_id": "team_bravo", "enemy_type": "rifle", "last_known_position": Vector2(tick, 8.0), "detection_complete": true}


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: ", message)
	else:
		_failed += 1
		print("FAIL: ", message)
