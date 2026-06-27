extends SceneTree

const CONTACT_TRACKER_SCRIPT: GDScript = preload("res://scripts/tactical/contact_tracker.gd")
const CONTACT_MAP_OVERLAY_SCRIPT: GDScript = preload("res://scripts/tactical/visuals/contact_map_overlay.gd")
const TACTICAL_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const EVENT_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_communication_event.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_510 Contact Report Upgrade Verifier ===")
	_test_contact_tracker_builds_report_fields()
	_test_contact_tracker_preserves_report_fields_through_relay()
	_test_contact_map_overlay_keeps_report_fields()
	await _test_controller_emits_contact_report_log_entries()
	await _test_primary_view_exposes_contact_report_visual_snapshot()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_contact_tracker_builds_report_fields() -> void:
	var tracker = CONTACT_TRACKER_SCRIPT.new()
	tracker.update(10, [_build_observation("blue", "enemy_a", Vector2(94.0, 130.0), false, "rifleman")], ["blue"], {"blue": 0.5})
	var fresh: Dictionary = tracker.get_contact_state("blue", "enemy_a", 10)
	_assert(String(fresh.get("enemy_type", "")) == "rifleman", "Contact report carries an enemy type")
	_assert(String(fresh.get("report_state", "")) == "current", "Fresh contact reports as current")
	_assert(float(fresh.get("confidence", 0.0)) > 0.5, "Fresh contact exposes a confidence value")
	_assert(String(fresh.get("confidence_level", "")).strip_edges() != "", "Fresh contact exposes a confidence bucket")
	_assert(String(fresh.get("report_text", "")).find("Kontakt") >= 0 or String(fresh.get("report_text", "")).find("contact") >= 0, "Fresh contact exposes a short report text")
	_assert(bool(fresh.get("read_only", false)) and not bool(fresh.get("ui_sets_gameplay_truth", true)), "Contact report snapshot is explicitly read-only UI data")

	tracker.update(11, [], ["blue"], {"blue": 0.5})
	var stale: Dictionary = tracker.get_contact_state("blue", "enemy_a", 11 + int(ceil(9.0 * float(Engine.physics_ticks_per_second))))
	_assert(String(stale.get("detection_state", "")) == "lost", "Unobserved visual contact transitions to lost")
	_assert(String(stale.get("report_state", "")) == "stale", "Old lost contact reports as stale")
	_assert(bool(stale.get("fow_last_known", false)), "Lost/stale contacts are marked as last-known for FoW-safe visuals")
	_assert(Vector2(stale.get("approximate_position", Vector2.ZERO)) != Vector2(stale.get("last_known_position", Vector2.ZERO)), "Stale medium-confidence contact exposes an approximate position")


func _test_contact_tracker_preserves_report_fields_through_relay() -> void:
	var tracker = CONTACT_TRACKER_SCRIPT.new()
	var fireteams: Array = ["blue", "gold"]
	var leaderships: Dictionary = {"blue": 0.0, "gold": 0.4}
	tracker.update(1, [_build_observation("blue", "enemy_relay", Vector2(86.0, 8.0), false, "rocket_launcher")], fireteams, leaderships)
	tracker.update(2, [_build_observation("blue", "enemy_relay", Vector2(92.0, 12.0), true, "rocket_launcher")], fireteams, leaderships)
	var relay_delay_ticks: int = int(ceil(3.0 * float(Engine.physics_ticks_per_second)))
	tracker.update(2 + relay_delay_ticks, [], fireteams, leaderships)
	var relayed: Dictionary = tracker.get_contact_state("gold", "enemy_relay", 2 + relay_delay_ticks)
	_assert(String(relayed.get("detection_state", "")) == "suspected", "Relayed contact remains suspected for receiving fireteam")
	_assert(String(relayed.get("enemy_type", "")) == "rocket launcher", "Relayed contact preserves the enemy type hint")
	_assert(int(relayed.get("last_seen_tick", -1)) == 2, "Relayed contact preserves original last-seen tick")
	_assert(float(relayed.get("last_seen_age_seconds", 0.0)) > 0.0, "Relayed contact reports age from original sighting")


func _test_contact_map_overlay_keeps_report_fields() -> void:
	var overlay = CONTACT_MAP_OVERLAY_SCRIPT.new()
	root.add_child(overlay)
	overlay.set_selected_fireteam_ids(PackedStringArray(["blue"]))
	overlay.set_contact_entries([
		{
			"fireteam_id": "blue",
			"unit_id": "enemy_report",
			"last_known_position": Vector2(96.0, 128.0),
			"approximate_position": Vector2(64.0, 128.0),
			"detection_state": "lost",
			"report_state": "stale",
			"confidence": 0.35,
			"position_uncertainty_world": 128.0,
			"report_text": "1 Kontakt, rifleman, zuletzt vor 9s",
		},
	])
	var visible: Array = overlay.get_visible_contacts()
	_assert(visible.size() == 1, "2D contact overlay keeps report contacts visible for selected fireteam")
	if visible.size() == 1:
		var contact: Dictionary = Dictionary(visible[0])
		_assert(String(contact.get("report_state", "")) == "stale", "2D overlay preserves stale report state")
		_assert(String(contact.get("report_text", "")).find("Kontakt") >= 0, "2D overlay preserves report text")
	overlay.queue_free()


func _test_controller_emits_contact_report_log_entries() -> void:
	var controller = TACTICAL_CONTROLLER_SCRIPT.new()
	controller.fireteamleader_feedback_bubbles_enabled = false
	root.add_child(controller)
	await _wait_frames(2)
	controller.call("_emit_contact_report_events_from_snapshot", [{
		"fireteam_id": "blue",
		"unit_id": "enemy_log",
		"last_known_position": Vector2(128.0, 192.0),
		"approximate_position": Vector2(128.0, 192.0),
		"detection_state": "confirmed",
		"report_state": "current",
		"enemy_type": "rifleman",
		"confidence": 0.82,
		"confidence_level": "high",
		"position_uncertainty_world": 24.0,
		"report_text": "1 Kontakt, rifleman, zuletzt jetzt, 82% sicher",
	}])
	var entries: Array = Array(controller.call("get_tactical_event_log_snapshot"))
	_assert(_has_event_type(entries, EVENT_SCRIPT.EVENT_CONTACT_REPORT), "Controller derives contact_report event-log entries from contact snapshots")
	var entry: Dictionary = _find_event_type(entries, EVENT_SCRIPT.EVENT_CONTACT_REPORT)
	_assert(String(entry.get("short_text", "")).find("rifleman") >= 0, "Contact event-log entry carries the report text")
	controller.queue_free()
	await _wait_frames(2)


func _test_primary_view_exposes_contact_report_visual_snapshot() -> void:
	var primary_view = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	await _wait_frames(4)
	primary_view.call("set_contact_entries", [{
		"fireteam_id": "blue",
		"unit_id": "enemy_3d",
		"last_known_position": Vector2(160.0, 220.0),
		"approximate_position": Vector2(128.0, 192.0),
		"detection_state": "lost",
		"report_state": "stale",
		"confidence": 0.32,
		"confidence_level": "low",
		"position_uncertainty_world": 144.0,
		"report_text": "1 Kontakt, unknown, zuletzt vor 10s",
	}], PackedStringArray(["blue"]))
	await _wait_frames(2)
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var contact_entries: Array = Array(snapshot.get("contact_entries", []))
	_assert(not contact_entries.is_empty(), "Primary 3D view exposes contact report visual entries")
	if not contact_entries.is_empty():
		var contact: Dictionary = Dictionary(contact_entries[0])
		_assert(String(contact.get("report_state", "")) == "stale", "Primary 3D view preserves report state")
		_assert(String(contact.get("confidence_level", "")) == "low", "Primary 3D view preserves confidence level")
		_assert(String(contact.get("report_text", "")).find("Kontakt") >= 0, "Primary 3D view preserves report text")
	primary_view.queue_free()
	await _wait_frames(2)


func _build_observation(fireteam_id: String, enemy_unit_id: String, position_value: Vector2, detection_complete: bool, enemy_type: String) -> Dictionary:
	return {
		"fireteam_id": fireteam_id,
		"unit_id": enemy_unit_id,
		"team_id": "team_bravo",
		"enemy_type": enemy_type,
		"last_known_position": position_value,
		"detection_complete": detection_complete,
	}


func _find_event_type(entries: Array, event_type: String) -> Dictionary:
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("event_type", "")) == event_type:
			return entry
	return {}


func _has_event_type(entries: Array, event_type: String) -> bool:
	return not _find_event_type(entries, event_type).is_empty()


func _wait_frames(count: int) -> void:
	for _index in range(maxi(count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
