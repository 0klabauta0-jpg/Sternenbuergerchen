extends SceneTree

const META_SCENE_PATH := "res://scenes/meta/meta_layer_test.tscn"
const META_SCRIPT_PATH := "res://scripts/meta/meta_layer_flow.gd"
const TACTICAL_CONTROLLER_SCRIPT_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const DEEPLINK_ARG := "--release-singleplayer-first-go-firefight"

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1088 Release Contact/Fire Ready-Time Pass ===")
	_test_contact_fire_trace_contract()
	await _test_integrated_contact_fire_evidence()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_contact_fire_trace_contract() -> void:
	var meta_text := FileAccess.get_file_as_string(META_SCRIPT_PATH)
	var controller_text := FileAccess.get_file_as_string(TACTICAL_CONTROLLER_SCRIPT_PATH)
	_assert(
		controller_text.contains("func get_release_first_exchange_immediate_evidence_snapshot() -> Dictionary:"),
		"Tactical controller exposes compact immediate exchange evidence"
	)
	_assert(
		meta_text.contains("get_release_first_exchange_immediate_evidence_snapshot"),
		"Release deep-link uses compact immediate exchange evidence"
	)
	for stage in [
		"engagement_commands_ready",
		"engagement_authority_tick_ready",
		"engagement_contact_tracking_ready",
		"engagement_fire_event_ready",
		"engagement_visual_feedback_ready",
		"engagement_evidence_ready",
	]:
		_assert(meta_text.contains('"%s"' % stage), "Contact/fire trace contains %s" % stage)


func _test_integrated_contact_fire_evidence() -> void:
	root.size = Vector2i(1920, 1080)
	var packed := ResourceLoader.load(META_SCENE_PATH) as PackedScene
	var scene := packed.instantiate() if packed != null else null
	_assert(scene != null, "MetaLayer release scene instantiates")
	if scene == null:
		return
	root.add_child(scene)
	await _wait_frames(10)
	var trace_env_name := "STERNENBUERGERCHEN_RELEASE_FIRST_EXCHANGE_TRACE_PATH"
	var previous_trace_path := OS.get_environment(trace_env_name)
	OS.set_environment(trace_env_name, "user://task1088_contact_fire_trace.json")
	var started_msec := Time.get_ticks_msec()
	await scene.call("_apply_release_first_go_firefight_deeplink", PackedStringArray([DEEPLINK_ARG]))
	if previous_trace_path.is_empty():
		OS.unset_environment(trace_env_name)
	else:
		OS.set_environment(trace_env_name, previous_trace_path)
	var elapsed_msec := Time.get_ticks_msec() - started_msec
	var snapshot: Dictionary = Dictionary(scene.call("get_release_first_go_firefight_deeplink_snapshot", PackedStringArray([DEEPLINK_ARG])))
	var active_mission := scene.get("_active_mission") as Node
	var controller := active_mission.get_node_or_null("TacticalController") if active_mission != null else null
	var source: Dictionary = Dictionary(controller.call("get_release_first_exchange_visible_status_source_reconciliation_snapshot")) if controller != null else {}
	var status_source: Dictionary = Dictionary(source.get("status_source", {}))
	var trace_samples: Array = Array(scene.get("_release_first_exchange_exported_status_trace_samples"))
	var fire_stage: Dictionary = _find_stage(trace_samples, "engagement_fire_event_ready")
	var evidence_stage: Dictionary = _find_stage(trace_samples, "engagement_evidence_ready")
	var immediate_evidence: Dictionary = Dictionary(scene.get_meta("release_first_exchange_tension_tuning_evidence", {}))
	var tactical_exchange: Dictionary = Dictionary(immediate_evidence.get("tactical_exchange", {}))
	print("TASK_1088_FIRE elapsed_msec=%d status=%s fire_event=%s" % [
		elapsed_msec,
		String(snapshot.get("status", "")),
		String(status_source.get("fire_event_id", "")),
	])

	_assert(String(snapshot.get("status", "")) == "applied", "First-exchange deep-link remains applied")
	_assert(String(snapshot.get("firefight_status", "")) == "pass", "First firefight remains actionable")
	_assert(bool(source.get("active", false)), "Visible first-exchange source remains active")
	_assert(not String(status_source.get("fire_event_id", "")).is_empty(), "Visible source references a real FireEvent")
	_assert(int(Dictionary(fire_stage.get("extra", {})).get("fire_event_count", 0)) > 0, "FireEvent trace stage records authoritative event evidence")
	_assert(String(immediate_evidence.get("status", "")) == "pass", "Compact immediate evidence passes")
	_assert(String(tactical_exchange.get("gate", "")) == "pass", "Compact tactical exchange passes")
	_assert(not String(tactical_exchange.get("first_fire_event_id", "")).is_empty(), "Compact tactical exchange references a real FireEvent")
	_assert(not bool(tactical_exchange.get("creates_fire_event", true)), "Compact tactical exchange remains read-only")
	_assert(int(evidence_stage.get("delta_msec", 999999)) < 3000, "Immediate evidence stage stays below 3 seconds")
	_assert(not bool(source.get("ui_sets_gameplay_truth", true)), "Contact/fire evidence remains read-only")
	_assert(elapsed_msec < 45000, "Full first exchange stays below conservative headless guard")

	scene.queue_free()
	await _wait_frames(2)


func _find_stage(samples: Array, stage_name: String) -> Dictionary:
	for sample_variant in samples:
		var sample: Dictionary = Dictionary(sample_variant)
		if String(sample.get("stage", "")) == stage_name:
			return sample
	return {}


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] %s" % message)
	else:
		_failed += 1
		push_error("[FAIL] %s" % message)
