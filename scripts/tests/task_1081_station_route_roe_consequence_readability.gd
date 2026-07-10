extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const RESOLVER_PATH: String = "res://scripts/tactical/fire_rule_consequence_readability.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1081 Station Route ROE Consequence Readability ===")
	_test_resolver_matrix()
	await _test_mission_hud_consequence_wiring()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_resolver_matrix() -> void:
	_assert(FileAccess.file_exists(RESOLVER_PATH), "ROE consequence resolver exists")
	if not FileAccess.file_exists(RESOLVER_PATH):
		return
	var resolver = load(RESOLVER_PATH)
	_assert(resolver != null and resolver.has_method("build_snapshot"), "ROE consequence resolver exposes build_snapshot")
	if resolver == null or not resolver.has_method("build_snapshot"):
		return

	var hold: Dictionary = Dictionary(resolver.call("build_snapshot", {
		"fire_rule": "hold",
		"runtime_entries": [_runtime_entry("hold", "hold_fire")],
	}))
	_assert(String(hold.get("consequence_state", "")) == "hold_blocked", "Hold resolves to blocked consequence")
	_assert(String(hold.get("compact_token", "")) == "HF HOLD", "Hold exposes compact HF HOLD token")
	_assert(bool(hold.get("runtime_consistent", false)), "Hold runtime entry is consistent")

	var return_wait: Dictionary = Dictionary(resolver.call("build_snapshot", {
		"fire_rule": "return",
		"selected_fireteam_ids": ["blue"],
		"runtime_entries": [_runtime_entry("return", "hold_fire")],
		"return_fire_window_by_fireteam": {},
	}))
	_assert(String(return_wait.get("consequence_state", "")) == "return_waiting", "Return waits without incoming-fire window")
	_assert(String(return_wait.get("compact_token", "")) == "RF WAIT", "Return waiting exposes compact token")

	var return_ready: Dictionary = Dictionary(resolver.call("build_snapshot", {
		"fire_rule": "return",
		"selected_fireteam_ids": ["blue"],
		"runtime_entries": [_runtime_entry("return", "hold_fire")],
		"return_fire_window_by_fireteam": {"blue": 42},
	}))
	_assert(String(return_ready.get("consequence_state", "")) == "return_ready", "Return distinguishes active incoming-fire window")
	_assert(String(return_ready.get("compact_token", "")) == "RF RETURN", "Return-ready exposes compact token")

	var free_ready: Dictionary = Dictionary(resolver.call("build_snapshot", {
		"fire_rule": "free",
		"runtime_entries": [_runtime_entry("free", "fire_at_will")],
	}))
	_assert(String(free_ready.get("consequence_state", "")) == "free_ready", "Free defaults to ready without contact decision")
	_assert(String(free_ready.get("compact_token", "")) == "FW READY", "Free-ready exposes compact token")

	var free_engage: Dictionary = Dictionary(resolver.call("build_snapshot", {
		"fire_rule": "free",
		"runtime_entries": [_runtime_entry("free", "fire_at_will")],
		"contact_decision_diagnostics": {
			"status": "fired",
			"reason": "fired",
			"los_state": "clear",
			"range_state": "in_range",
			"cover_state": "partial",
			"is_friendly_fire": true,
		},
	}))
	_assert(String(free_engage.get("consequence_state", "")) == "free_engaging", "Free distinguishes an active engagement")
	_assert(String(free_engage.get("compact_token", "")) == "FW ENGAGE", "Free engagement exposes compact token")
	_assert(String(free_engage.get("context_token", "")).contains("FF"), "Friendly-fire context is visible when runtime reports it")
	_assert(String(free_engage.get("context_token", "")).contains("LOS"), "LOS context is visible when runtime reports it")

	var free_blocked: Dictionary = Dictionary(resolver.call("build_snapshot", {
		"fire_rule": "free",
		"runtime_entries": [_runtime_entry("free", "fire_at_will")],
		"contact_decision_diagnostics": {
			"status": "blocked",
			"reason": "no_damage_effect",
			"los_state": "blocked",
			"range_state": "out_of_range",
			"cover_state": "full",
		},
	}))
	_assert(String(free_blocked.get("consequence_state", "")) == "free_blocked", "Free distinguishes blocked combat decision")
	_assert(String(free_blocked.get("compact_token", "")) == "FW BLOCK", "Free blocked exposes compact token")

	var mismatch: Dictionary = Dictionary(resolver.call("build_snapshot", {
		"fire_rule": "hold",
		"runtime_entries": [_runtime_entry("free", "fire_at_will")],
	}))
	_assert(not bool(mismatch.get("runtime_consistent", true)), "Runtime mismatch remains diagnostically visible")
	_assert(bool(hold.get("read_only", false)) and not bool(hold.get("ui_sets_gameplay_truth", true)), "ROE consequence snapshot remains read-only")


func _test_mission_hud_consequence_wiring() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var controller: Node = scene.get_node_or_null("TacticalController")
	var simulation_root: Node = scene.get_node_or_null("SimulationRoot")
	_assert(controller != null and simulation_root != null, "Mission fixture exposes controller and SimulationRoot")
	if controller == null or simulation_root == null:
		await _cleanup(scene)
		return
	_assert(controller.has_method("get_fire_rule_consequence_readability_snapshot"), "Mission controller exposes ROE consequence snapshot")
	if not controller.has_method("get_fire_rule_consequence_readability_snapshot"):
		await _cleanup(scene)
		return
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	var command_count_before: int = _get_command_queue_count(simulation_root)

	controller.call("set_selected_fireteams_fire_rule", "hold")
	var hold: Dictionary = Dictionary(controller.call("get_fire_rule_consequence_readability_snapshot"))
	var hold_density: Dictionary = Dictionary(controller.call("_build_mission_hud_interaction_density_snapshot"))
	_assert(String(hold.get("compact_token", "")) == "HF HOLD", "Mission controller exposes Hold consequence")
	_assert(String(hold_density.get("mission_control_line", "")).contains("ROE HF HOLD"), "Mission ACT line shows Hold consequence")

	controller.call("set_selected_fireteams_fire_rule", "return")
	var return_wait: Dictionary = Dictionary(controller.call("get_fire_rule_consequence_readability_snapshot"))
	var return_density: Dictionary = Dictionary(controller.call("_build_mission_hud_interaction_density_snapshot"))
	_assert(String(return_wait.get("compact_token", "")) == "RF WAIT", "Mission controller exposes Return waiting consequence")
	_assert(String(return_density.get("mission_control_line", "")).contains("ROE RF WAIT"), "Mission ACT line shows Return waiting consequence")

	controller.call("set_selected_fireteams_fire_rule", "free")
	var free: Dictionary = Dictionary(controller.call("get_fire_rule_consequence_readability_snapshot"))
	var free_density: Dictionary = Dictionary(controller.call("_build_mission_hud_interaction_density_snapshot"))
	_assert(String(free.get("compact_token", "")) == "FW READY", "Mission controller exposes Free-ready consequence")
	_assert(String(free_density.get("mission_control_line", "")).contains("ROE FW READY"), "Mission ACT line shows Free-ready consequence")
	_assert(bool(free_density.get("line_within_limit", false)), "ROE consequence keeps ACT line within density budget")

	var compact_combat_line: String = "FIRE unit_alpha>guard RIFLE HIT | COV OPEN RNG IN LOS CLR"
	var firefight_focus: Dictionary = Dictionary(controller.call("get_mission_combat_feedback_hud_density_snapshot", {
		"combat_hud_density": {
			"active": true,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
			"compact_line": compact_combat_line,
			"mission_control_line": compact_combat_line,
			"selected_fireteam_line": "Kampf %s" % compact_combat_line,
			"line_within_limit": true,
			"contains_fire_state": true,
			"contains_cover_context": true,
			"contains_los_context": true,
			"contains_range_context": true,
		},
		"mission_control_status_text": "CONTACT FIRE | FIRE unit_alpha>guard RIFLE HIT\nNEXT DEFEND | WHY FEUER",
		"selected_fireteam_status_label_text": "CONTACT FIRE | FIRE unit_alpha>guard RIFLE HIT\nNEXT DEFEND | WHY FEUER",
		"selected_status_text": "CONTACT FIRE | FIRE unit_alpha>guard RIFLE HIT",
	}))
	_assert(String(firefight_focus.get("gate", "")) == "pass", "Combat density gate accepts the current CONTACT FIRE focus presenter")
	_assert(_check_passed(firefight_focus, "mission_control_uses_compact_line"), "Mission Control firefight focus satisfies combat visibility")
	_assert(_check_passed(firefight_focus, "selected_fireteam_uses_compact_line"), "Selected Fireteam firefight focus satisfies combat visibility")

	var command_count_after: int = _get_command_queue_count(simulation_root)
	_assert(command_count_after == command_count_before, "Reading ROE consequence snapshots does not enqueue commands")
	_assert(bool(free.get("read_only", false)) and not bool(free.get("ui_sets_gameplay_truth", true)), "Mission ROE consequence remains read-only")
	await _cleanup(scene)


func _runtime_entry(rule: String, status: String) -> Dictionary:
	return {
		"fireteam_id": "blue",
		"unit_id": "unit_1",
		"fire_rule": rule,
		"fire_status": status,
	}


func _get_command_queue_count(simulation_root: Node) -> int:
	if simulation_root == null:
		return 0
	var queue_variant: Variant = simulation_root.get("command_queue")
	return Array(queue_variant).size() if typeof(queue_variant) == TYPE_ARRAY else 0


func _check_passed(snapshot: Dictionary, check_id: String) -> bool:
	for check_variant in Array(snapshot.get("checks", [])):
		var check: Dictionary = Dictionary(check_variant)
		if String(check.get("id", "")) == check_id:
			return bool(check.get("passed", false))
	return false


func _cleanup(scene: Node) -> void:
	if is_instance_valid(scene):
		scene.queue_free()
	await _wait_frames(2)


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
