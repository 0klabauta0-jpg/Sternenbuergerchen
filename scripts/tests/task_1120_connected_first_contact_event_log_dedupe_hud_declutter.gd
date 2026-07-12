extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_1120 Connected First Contact Event Log Dedupe and HUD Declutter ===")
	var mission: Node = MISSION_SCENE.instantiate()
	root.add_child(mission)
	await process_frame
	var controller: Node = mission.get_node("TacticalController")
	var panel: Node = mission.get_node("TacticalUI/TacticalEventLogPanel")
	var raw_entries: Array = _raw_entries()
	var display: Dictionary = Dictionary(controller.call("_build_release_firefight_event_log_display_snapshot", raw_entries, {}, {}))
	var display_entries: Array = Array(display.get("entries", []))
	_assert(raw_entries.size() == 4, "Verifier keeps four raw event records")
	_assert(display_entries.size() == 2, "Three repeated Contact Reports collapse to one display row")
	var contact_report: Dictionary = _find_entry(display_entries, "contact_report")
	_assert(int(contact_report.get("repeat_count", 0)) == 3 and Array(contact_report.get("collapsed_event_ids", [])).size() == 3, "Collapsed Contact row exposes repeat count without losing source IDs")
	_assert(not display_entries.is_empty() and String(Dictionary(display_entries[0]).get("short_text", "")).contains("CONTACT FIRE"), "Contact Fire is visually prioritized before routine reports")
	_assert(int(display.get("raw_count", 0)) == 4 and int(display.get("collapsed_repeat_count", 0)) == 2, "Display snapshot reports raw and collapsed counts")

	panel.call("set_feedback_snapshot", {
		"selected_fireteam_ids": ["gold"],
		"event_log_selected_only_default": true,
		"tactical_event_log": display_entries,
	})
	var default_panel: Dictionary = Dictionary(panel.call("get_panel_snapshot"))
	_assert(bool(default_panel.get("selected_only", false)), "Connected product Event Log starts selected-only")
	panel.call("set_selected_only", false)
	panel.call("set_feedback_snapshot", {
		"selected_fireteam_ids": ["gold"],
		"event_log_selected_only_default": true,
		"tactical_event_log": display_entries,
	})
	_assert(not bool(Dictionary(panel.call("get_panel_snapshot")).get("selected_only", true)), "Manual Event Log toggle survives later feedback refreshes")

	_assert(controller.has_method("_build_contact_focused_mission_dropship_card_entries"), "Controller exposes read-only Contact-focused Dropship filtering")
	if controller.has_method("_build_contact_focused_mission_dropship_card_entries"):
		var inactive_cards: Array = [
			_card("dropship_blue", "to_fob", 0, []),
			_card("dropship_gold", "to_fob", 0, []),
		]
		var active_cards: Array = inactive_cards + [_card("dropship_ready", "waiting", 0, ["unit_alpha"])]
		_assert(Array(controller.call("_build_contact_focused_mission_dropship_card_entries", inactive_cards, true)).is_empty(), "First Contact hides only completed empty return cards")
		_assert(Array(controller.call("_build_contact_focused_mission_dropship_card_entries", inactive_cards, false)).is_empty(), "Completed empty return cards retire even without Contact focus")
		_assert(Array(controller.call("_build_contact_focused_mission_dropship_card_entries", active_cards, true)).size() == 1, "Loaded or actionable Dropship remains visible during Contact")

	mission.queue_free()
	await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _raw_entries() -> Array:
	return [
		_entry("gold_contact_3", "contact_report", "contact", "gold", "enemy_delta", "GOLD 1 Kontakt, security guard", 3000),
		_entry("gold_fire", "release_firefight_status", "engagement_feedback", "gold", "enemy_delta", "GOLD CONTACT FIRE: Feuerwechsel lesen", 2900),
		_entry("gold_contact_2", "contact_report", "contact", "gold", "enemy_delta", "GOLD 1 Kontakt, security guard", 2000),
		_entry("gold_contact_1", "contact_report", "contact", "gold", "enemy_delta", "GOLD 1 Kontakt, security guard", 1000),
	]


func _entry(event_id: String, event_type: String, category: String, fireteam_id: String, unit_id: String, short_text: String, created_msec: int) -> Dictionary:
	return {"event_id": event_id, "event_type": event_type, "category": category, "fireteam_id": fireteam_id, "unit_id": unit_id, "short_text": short_text, "created_msec": created_msec, "severity": "info", "priority": 2}


func _find_entry(entries: Array, event_type: String) -> Dictionary:
	for entry_variant in entries:
		if typeof(entry_variant) == TYPE_DICTIONARY and String(Dictionary(entry_variant).get("event_type", "")) == event_type:
			return Dictionary(entry_variant)
	return {}


func _card(craft_id: String, state: String, eta_seconds: int, payload_ids: Array) -> Dictionary:
	return {"craft_id": craft_id, "state": state, "eta_seconds": eta_seconds, "embarked_unit_ids": payload_ids, "passenger_count": payload_ids.size(), "pilot_unit_id": ""}


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
