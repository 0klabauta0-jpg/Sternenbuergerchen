extends SceneTree
## Characterization of the complete explicit debug/report API, not a playtest.
## Only presentation sources are synthetic; real simulation owners are observed.
const MISSION = preload("res://scenes/tests/mission_reactivity_test.tscn")
const NEXT_LOOP = preload("res://scripts/mission/release_first_decision_next_playable_loop.gd")
var passed := 0
var failed := 0

class FeedbackProbe extends "res://scripts/tests/fixtures/legacy_command_feedback_oracle.gd":
	var fixture_loop: Dictionary = {}
	var fixture_selected := ""
	var fixture_strategic := ""
	var fixture_smoke := false
	var source_reads: Array = []
	func _ready() -> void:
		set_process(false)
		set_physics_process(false)
	func _release_fire_exchange_visibility_clock_msec() -> int:
		return 42000
	func _build_mission_time_limit_text() -> String:
		return "Time fixture"
	func get_release_first_decision_next_playable_loop_snapshot(_findings: Dictionary = {}, _decision: Dictionary = {}, _firefight: Dictionary = {}) -> Dictionary:
		source_reads.append("next_loop")
		return fixture_loop.duplicate(true)
	func _build_fireteam_status_text() -> String:
		source_reads.append("selected_text")
		return fixture_selected
	func _build_strategic_status_text() -> String:
		source_reads.append("strategic_text")
		return fixture_strategic
	func _build_target_text() -> String:
		source_reads.append("target_override")
		return "CALLER OVERRIDE: " + ",".join(_selected_fireteam_ids)
	func _get_label_text(label_path: Variant) -> String:
		if String(label_path) == FIRETEAM_STATUS_LABEL_PATH:
			source_reads.append("selected_label")
			return fixture_selected
		if String(label_path) == STRATEGIC_STATUS_LABEL_PATH:
			source_reads.append("strategic_label")
			return fixture_strategic
		if String(label_path) == String(command_feedback_label_path):
			return "SECURE PUSH FLANK RESET"
		return super._get_label_text(label_path)
	func _build_release_first_decision_loop_two_playability_smoke_trace(polish: Dictionary) -> Dictionary:
		if not fixture_smoke:
			return super._build_release_first_decision_loop_two_playability_smoke_trace(polish)
		return {"trace_available": true, "completed_checks": ["second_decision_button_visible", "second_decision_confirmed", "go_button_still_separate", "go_executed_after_confirm", "post_go_feedback_visible", "no_go_before_second_confirm", "no_new_hud_gameplay_truth", "multiplayer_boundary_preserved"], "second_decision_button_visible": true, "second_decision_confirmed": true, "go_button_still_separate": true, "go_executed_after_confirm": true, "post_go_feedback_visible": true, "post_go_feedback_line": "2ND HOLD -> GO | synthetic fixture", "no_go_before_second_confirm": true, "no_new_hud_gameplay_truth": true, "multiplayer_boundary_preserved": true, "ui_sets_gameplay_truth": false, "creates_command": false, "creates_movement": false, "sets_multiplayer_truth": false}
	func configure_fixture(spec: Dictionary) -> void:
		fixture_loop = Dictionary(spec.source).duplicate(true)
		fixture_selected = String(spec.selected)
		fixture_strategic = String(spec.strategic)
		fixture_smoke = bool(spec.smoke)
		_selected_fireteam_ids = PackedStringArray(spec.teams)
		_last_command_text = "fixture command " + String(spec.id)
		source_reads.clear()

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := MISSION.instantiate()
	root.add_child(scene)
	for _frame in range(12):
		await process_frame
	var owner := scene.get_node_or_null("TacticalController")
	var simulation := scene.get_node_or_null("SimulationRoot")
	check(owner != null and simulation != null, "real scene exposes original runtime owners")
	if owner == null or simulation == null:
		scene.queue_free()
		await process_frame
		_finish()
		return
	var probe := FeedbackProbe.new()
	probe.name = "DiagnosticsParityProbe"
	scene.add_child(probe)
	var active := _next_loop(true)
	var line := String(active.get("visible_loop_line", ""))
	var cases: Array[Dictionary] = [
		{"id": "active_synthetic_smoke", "source": active, "selected": "RAW TEAM\n" + line, "strategic": "RAW CONTROL\n" + line, "smoke": true, "teams": ["blue"]},
		{"id": "unobserved_smoke", "source": active, "selected": "RAW TEAM\n" + line, "strategic": "RAW CONTROL\n" + line, "smoke": false, "teams": ["blue"]},
		{"id": "missing_selected_text", "source": active, "selected": "", "strategic": "RAW CONTROL\n" + line, "smoke": true, "teams": ["blue"]},
		{"id": "multiple_selection_blocked", "source": _next_loop(false), "selected": "RAW BLUE GOLD", "strategic": "RAW BLOCKED", "smoke": true, "teams": ["blue", "gold"]},
		{"id": "empty_selection", "source": _next_loop(false), "selected": "", "strategic": "", "smoke": false, "teams": []},
	]
	var signatures: Array = []
	for spec in cases:
		probe.configure_fixture(spec)
		# Warm only derived/lazy presentation helpers; no simulation frames pass
		# between the reference and production calls below.
		probe.get_pre_extraction_feedback_snapshot()
		var before := _owner_state(scene, owner, simulation, probe)
		probe.source_reads.clear()
		var expected: Dictionary = probe.get_pre_extraction_feedback_snapshot()
		var expected_reads := probe.source_reads.duplicate()
		probe.source_reads.clear()
		var actual: Dictionary = probe.get_command_feedback_snapshot()
		var actual_reads := probe.source_reads.duplicate()
		var difference := _first_difference(expected, actual)
		check(difference.is_empty(), "%s full typed snapshot parity%s" % [spec.id, "" if difference.is_empty() else ": " + difference])
		check(var_to_bytes(expected) == var_to_bytes(actual), "%s exact Variant binary parity including container types" % spec.id)
		probe.source_reads.clear()
		var repeated: Dictionary = probe.get_command_feedback_snapshot()
		var repeated_difference := _first_difference(actual, repeated)
		check(repeated_difference.is_empty(), "%s stable repeated read%s" % [spec.id, "" if repeated_difference.is_empty() else ": " + repeated_difference])
		check(actual.keys().size() >= 439, "%s retains all pre-extraction snapshot fields" % spec.id)
		check(expected_reads == actual_reads and actual_reads.has("target_override") and actual_reads.has("next_loop"), "%s preserves source override dispatch and observed read order" % spec.id)
		check(String(actual.get("target_text", "")) == "CALLER OVERRIDE: " + ",".join(PackedStringArray(spec.teams)), "%s caller target override reaches public report" % spec.id)
		check(actual.get("selected_fireteam_ids", null) == Array(spec.teams), "%s selected source reaches report" % spec.id)
		check(_owner_state(scene, owner, simulation, probe) == before, "%s keeps plans, queues, tick, rules and actors unchanged" % spec.id)
		signatures.append(_snapshot_sha256(actual))
		print("DIAGNOSTICS_PARITY_CASE ", JSON.stringify({"id": spec.id, "fields": actual.size(), "read_calls": actual_reads.size(), "sha256": signatures[-1]}))
	check(signatures.size() == cases.size() and signatures[0] != signatures[1] and signatures[0] != signatures[2] and signatures[3] != signatures[4], "fixtures exercise distinct report and selection states")
	probe.free()
	scene.queue_free()
	for _frame in range(3):
		await process_frame
	_finish()

func _snapshot_sha256(snapshot: Dictionary) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(var_to_bytes(snapshot))
	return context.finish().hex_encode()

func _first_difference(expected: Variant, actual: Variant, path: String = "$") -> String:
	if typeof(expected) != typeof(actual):
		return "%s type %d != %d" % [path, typeof(expected), typeof(actual)]
	if expected is Dictionary:
		if expected.size() != actual.size():
			return "%s dictionary size %d != %d" % [path, expected.size(), actual.size()]
		for key in expected:
			if not actual.has(key):
				return "%s missing key %s" % [path, str(key)]
			var difference := _first_difference(expected[key], actual[key], path + "." + str(key))
			if not difference.is_empty():
				return difference
	elif expected is Array:
		if expected.size() != actual.size():
			return "%s array size %d != %d" % [path, expected.size(), actual.size()]
		for index in range(expected.size()):
			var difference := _first_difference(expected[index], actual[index], "%s[%d]" % [path, index])
			if not difference.is_empty():
				return difference
	elif expected != actual:
		return "%s value %s != %s" % [path, str(expected), str(actual)]
	return ""

func _owner_state(scene: Node, owner: Node, simulation: Node, probe: Node) -> Dictionary:
	var units: Array = []
	for child in scene.get_children():
		if child is Node2D and child.has_method("get_unit_id") and child.has_method("get_health"):
			units.append({"id": child.call("get_unit_id"), "health": child.call("get_health"), "vital": child.call("get_vital_state"), "position": child.position, "command": str(child.call("get_current_unit_command"))})
	return {"commands": Array(simulation.get("command_queue")).duplicate(true), "effects": Array(simulation.get("effects_queue")).duplicate(true), "tick": simulation.call("get_tick"), "rules": Array(simulation.call("get_authoritative_fire_rule_snapshot")).duplicate(true), "plans": Array(owner.call("get_order_plans_snapshot")).duplicate(true), "areas": Array(owner.call("get_area_orders_snapshot")).duplicate(true), "multi_plans": Array(owner.call("get_multi_fireteam_plan_snapshot")).duplicate(true), "probe_plans": Array(probe.call("get_order_plans_snapshot")).duplicate(true), "probe_areas": Array(probe.call("get_area_orders_snapshot")).duplicate(true), "units": units}

func _next_loop(ready: bool) -> Dictionary:
	var findings := _readonly()
	findings.merge({"schema": "sternenbuergerchen.release_first_decision_playtest_findings.v1", "task_id": "TASK_962", "status": "accepted_for_release_first_decision_next_loop", "accepted": true, "manual_review_done": true})
	var decision := _readonly()
	decision.merge({"schema": "sternenbuergerchen.first_decision_micro_scenario_polish.v1", "task_id": "TASK_956", "gate": "pass" if ready else "review", "primary_cue_line": "NEXT Deckung pruefen -> GO"})
	var firefight := _readonly()
	firefight.merge({"active": true, "decision_line": "NEXT HIT LESEN / DEFEND | WHY FEUER", "next_token": "HIT LESEN / DEFEND", "why_token": "FEUER"})
	return NEXT_LOOP.build_snapshot(findings, decision, firefight)

func _readonly() -> Dictionary:
	return {"read_only": true, "ui_sets_gameplay_truth": false, "creates_command": false, "creates_movement": false, "creates_fire_event": false, "creates_damage_event": false, "sets_multiplayer_truth": false}

func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
	print("PASS: " if ok else "FAIL: ", label)

func _finish() -> void:
	print("ALTLASTEN_DIAGNOSTICS_PARITY passed=%d failed=%d" % [passed, failed])
	if failed == 0:
		print("ALTLASTEN_DIAGNOSTICS_PARITY_PASS")
	quit(1 if failed else 0)
