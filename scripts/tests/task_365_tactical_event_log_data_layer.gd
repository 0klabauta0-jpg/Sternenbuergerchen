extends SceneTree

const EVENT_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_communication_event.gd")
const RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_communication_resolver.gd")
const EVENT_LOG_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_event_log.gd")
const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_365 Tactical Event Log Data Layer ===")
	_test_log_normalization_dedupe_and_sorting()
	_test_history_bound_and_immutable_input()
	await _test_mission_controller_event_log_snapshot()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_log_normalization_dedupe_and_sorting() -> void:
	var log = EVENT_LOG_SCRIPT.new()
	var contact_event: Dictionary = _build_event(EVENT_SCRIPT.EVENT_CONTACT_REPORT, "blue", 1000)
	var cannot_execute_event: Dictionary = _build_event(EVENT_SCRIPT.EVENT_CANNOT_EXECUTE, "gold", 1100)
	var air_threat_event: Dictionary = _build_event(EVENT_SCRIPT.EVENT_AIR_ASSET_THREATENED, "blue", 1200)
	var added: Array = Array(log.call("ingest_tactical_communication_events", [
		contact_event,
		cannot_execute_event,
		air_threat_event,
		contact_event.duplicate(true),
	]))
	var entries: Array = Array(log.call("get_snapshot"))
	_assert(added.size() == 3, "Event log accepts three unique communication events and dedupes duplicate event_id")
	_assert(entries.size() == 3, "Event log snapshot keeps unique entries")
	_assert(_has_log_type(entries, EVENT_SCRIPT.EVENT_CONTACT_REPORT), "Event log contains Contact")
	_assert(_has_log_type(entries, EVENT_SCRIPT.EVENT_CANNOT_EXECUTE), "Event log contains Cannot Execute")
	_assert(_has_log_type(entries, EVENT_SCRIPT.EVENT_AIR_ASSET_THREATENED), "Event log contains Air Asset Threat")
	_assert(String(_find_log_type(entries, EVENT_SCRIPT.EVENT_CANNOT_EXECUTE).get("severity", "")) == "critical", "Cannot Execute maps to critical severity")
	_assert(String(_find_log_type(entries, EVENT_SCRIPT.EVENT_CONTACT_REPORT).get("severity", "")) == "warning", "Contact maps to warning severity")
	_assert(String(_find_log_type(entries, EVENT_SCRIPT.EVENT_AIR_ASSET_THREATENED).get("category", "")) == "air_asset", "Air threat maps to air_asset category")
	_assert(int(Dictionary(entries[0]).get("created_msec", 0)) >= int(Dictionary(entries[1]).get("created_msec", 0)), "Default snapshot is newest-first sortable")
	var ascending: Array = Array(log.call("get_snapshot", {"newest_first": false}))
	_assert(int(Dictionary(ascending[0]).get("created_msec", 0)) <= int(Dictionary(ascending[1]).get("created_msec", 0)), "Snapshot can be sorted oldest-first")


func _test_history_bound_and_immutable_input() -> void:
	var log = EVENT_LOG_SCRIPT.new()
	log.call("configure", {"max_entries": 2})
	var first_event: Dictionary = _build_event(EVENT_SCRIPT.EVENT_CONTACT_REPORT, "blue", 1000)
	var before_keys: PackedStringArray = PackedStringArray(first_event.keys())
	log.call("ingest_tactical_communication_events", [
		first_event,
		_build_event(EVENT_SCRIPT.EVENT_CANNOT_EXECUTE, "blue", 2000),
		_build_event(EVENT_SCRIPT.EVENT_AIR_ASSET_THREATENED, "gold", 3000),
	])
	var entries: Array = Array(log.call("get_snapshot", {"newest_first": false}))
	_assert(entries.size() == 2, "Event log trims to configured max_entries")
	_assert(not _has_log_type(entries, EVENT_SCRIPT.EVENT_CONTACT_REPORT), "Oldest entry is trimmed when history exceeds bound")
	_assert(PackedStringArray(first_event.keys()) == before_keys, "Input event payload keys are not mutated by ingestion")
	_assert(not first_event.has("severity") and not first_event.has("category"), "Input event payload does not receive log-only fields")
	var contract: Dictionary = Dictionary(log.call("get_contract_snapshot"))
	_assert(bool(contract.get("read_only_adapter", false)), "Contract snapshot marks event log as read-only adapter")
	_assert(int(contract.get("max_entries", 0)) == 2, "Contract snapshot exposes configured max_entries")


func _test_mission_controller_event_log_snapshot() -> void:
	var scene = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var controller: Node = scene.get_node_or_null("TacticalController")
	var simulation_root: Node = scene.get_node_or_null("SimulationRoot")
	_assert(controller != null and simulation_root != null, "Mission scene exposes TacticalController and SimulationRoot")
	if controller == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	var command_count_before: int = simulation_root.command_queue.size()
	var effect_count_before: int = simulation_root.effects_queue.size()
	var events: Array = [
		_build_event(EVENT_SCRIPT.EVENT_CONTACT_REPORT, "blue", 4000),
		_build_event(EVENT_SCRIPT.EVENT_CANNOT_EXECUTE, "gold", 4100),
		_build_event(EVENT_SCRIPT.EVENT_AIR_ASSET_THREATENED, "blue", 4200),
	]
	var emitted: Array = Array(controller.call("record_tactical_communication_events", events, {"now_msec": 4300, "cooldown_msec": 0}))
	await _wait_frames(6)
	var feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var log_entries: Array = Array(feedback.get("tactical_event_log", []))
	_assert(emitted.size() == 3, "Mission controller accepts three tactical communication events")
	_assert(int(feedback.get("tactical_event_log_count", 0)) >= 3, "Command feedback exposes tactical event log count")
	_assert(_has_log_type(log_entries, EVENT_SCRIPT.EVENT_CONTACT_REPORT), "Mission event log contains Contact")
	_assert(_has_log_type(log_entries, EVENT_SCRIPT.EVENT_CANNOT_EXECUTE), "Mission event log contains Cannot Execute")
	_assert(_has_log_type(log_entries, EVENT_SCRIPT.EVENT_AIR_ASSET_THREATENED), "Mission event log contains Air Asset Threat")
	_assert(simulation_root.command_queue.size() == command_count_before, "Event log snapshot enqueues no SimulationRoot commands")
	_assert(simulation_root.effects_queue.size() == effect_count_before, "Event log snapshot enqueues no SimulationRoot effects")
	scene.queue_free()
	await _wait_frames(2)


func _build_event(event_type: String, fireteam_id: String, now_msec: int) -> Dictionary:
	return Dictionary(RESOLVER_SCRIPT.call("build_event", event_type, {
		"event_id": "task365_%s_%s_%d" % [event_type, fireteam_id, now_msec],
		"fireteam_id": fireteam_id,
		"display_label": fireteam_id.to_upper(),
		"phase": 1,
		"planned_position": Vector2(320.0 + float(now_msec % 300), 420.0),
		"target_position": Vector2(480.0, 480.0),
		"short_text": "%s %s" % [fireteam_id.to_upper(), event_type.to_upper()],
		"detail_text": "Task 365 %s detail" % event_type,
		"communication_clarity": 0.82,
	}, {"now_msec": now_msec}))


func _find_log_type(entries: Array, event_type: String) -> Dictionary:
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("event_type", "")) == event_type:
			return entry
	return {}


func _has_log_type(entries: Array, event_type: String) -> bool:
	return not _find_log_type(entries, event_type).is_empty()


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
