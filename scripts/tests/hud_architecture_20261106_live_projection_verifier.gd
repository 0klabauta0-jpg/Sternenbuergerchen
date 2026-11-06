extends SceneTree
## Synthetic source/trace fixtures exercise the real legacy contracts inside a
## real mission scene. They are not normal-game, native-fire or acceptance proof.

const MISSION_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const NEXT_LOOP: GDScript = preload("res://scripts/mission/release_first_decision_next_playable_loop.gd")
const API: String = "_build_live_hud_legacy_action_projection"
const SECTIONS: Array[String] = ["runtime_button", "runtime_visual", "choice_buttons", "choice_visual", "execution_hook"]

var _passed := 0
var _failed := 0


class ProjectionProbe extends "res://scripts/tests/mission_tactical_sandbox_controller.gd":
	var fixture_next_loop: Dictionary = {}
	var raw_selected := ""
	var raw_strategic := ""
	var raw_command := "SECURE PUSH FLANK RESET"
	var fixture_passed_smoke := false
	var next_loop_reads := 0
	var selected_builds := 0
	var strategic_builds := 0
	var selected_label_reads := 0
	var strategic_label_reads := 0
	var playtest_selected_overrides: Array = []
	var playtest_strategic_overrides: Array = []
	func _ready() -> void:
		set_process(false)
		set_physics_process(false)
	func _release_fire_exchange_visibility_clock_msec() -> int:
		return 42000
	func get_release_first_decision_next_playable_loop_snapshot(_source_findings_override: Dictionary = {}, _first_decision_override: Dictionary = {}, _firefight_decision_override: Dictionary = {}) -> Dictionary:
		next_loop_reads += 1
		return fixture_next_loop.duplicate(true)
	func _build_fireteam_status_text() -> String:
		selected_builds += 1
		return raw_selected
	func _build_strategic_status_text() -> String:
		strategic_builds += 1
		return raw_strategic
	func _get_label_text(label_path: Variant) -> String:
		if String(label_path) == FIRETEAM_STATUS_LABEL_PATH:
			selected_label_reads += 1
			return raw_selected
		if String(label_path) == STRATEGIC_STATUS_LABEL_PATH:
			strategic_label_reads += 1
			return raw_strategic
		if String(label_path) == String(command_feedback_label_path):
			return raw_command
		return super._get_label_text(label_path)
	func get_release_first_decision_loop_two_playtest_snapshot(next_loop_override: Dictionary = {}, selected_fireteam_status_override: String = "", mission_control_status_override: String = "", command_feedback_override: Dictionary = {}) -> Dictionary:
		playtest_selected_overrides.append(selected_fireteam_status_override)
		playtest_strategic_overrides.append(mission_control_status_override)
		return super.get_release_first_decision_loop_two_playtest_snapshot(next_loop_override, selected_fireteam_status_override, mission_control_status_override, command_feedback_override)
	func _build_release_first_decision_loop_two_playability_smoke_trace(visual_polish: Dictionary) -> Dictionary:
		if not fixture_passed_smoke:
			return super._build_release_first_decision_loop_two_playability_smoke_trace(visual_polish)
		# This explicit synthetic trace reaches the active four-choice branch. It
		# does not claim a button press, GO or fire happened in the running scene.
		return {"trace_available": true, "completed_checks": ["second_decision_button_visible", "second_decision_confirmed", "go_button_still_separate", "go_executed_after_confirm", "post_go_feedback_visible", "no_go_before_second_confirm", "no_new_hud_gameplay_truth", "multiplayer_boundary_preserved"], "second_decision_button_visible": true, "second_decision_confirmed": true, "go_button_still_separate": true, "go_executed_after_confirm": true, "post_go_feedback_visible": true, "post_go_feedback_line": "2ND HOLD -> GO | synthetic fixture", "no_go_before_second_confirm": true, "no_new_hud_gameplay_truth": true, "multiplayer_boundary_preserved": true, "ui_sets_gameplay_truth": false, "creates_command": false, "creates_movement": false, "sets_multiplayer_truth": false}
	func set_fixture(next_loop: Dictionary, selected_text: String, strategic_text: String, passed_smoke: bool) -> void:
		fixture_next_loop = next_loop.duplicate(true)
		raw_selected = selected_text
		raw_strategic = strategic_text
		fixture_passed_smoke = passed_smoke
		_selected_fireteam_ids = PackedStringArray(["blue"])
		reset_reads()
	func reset_reads() -> void:
		next_loop_reads = 0
		selected_builds = 0
		strategic_builds = 0
		selected_label_reads = 0
		strategic_label_reads = 0
		playtest_selected_overrides.clear()
		playtest_strategic_overrides.clear()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var api_probe := ProjectionProbe.new()
	var has_api: bool = api_probe.has_method(API)
	_check(has_api, "Controller exposes the bounded live legacy-action projection")
	api_probe.free()
	if not has_api:
		_finish()
		return
	var scene := MISSION_SCENE.instantiate()
	root.add_child(scene)
	for _frame in range(12):
		await process_frame
	var owner := scene.get_node_or_null("TacticalController")
	var simulation := scene.get_node_or_null("SimulationRoot")
	_check(owner != null and simulation != null, "Real mission scene exposes plan and simulation owners")
	if owner == null or simulation == null:
		scene.queue_free()
		await process_frame
		_finish()
		return
	var probe := ProjectionProbe.new()
	probe.name = "LegacyProjectionProbe"
	scene.add_child(probe)
	var active_loop := _next_loop_fixture(true)
	var loop_line := String(active_loop.get("visible_loop_line", ""))
	_check(bool(active_loop.get("active", false)), "Existing next-loop contract accepts the controlled first-decision source")
	var cases: Array[Dictionary] = [
		{"id": "active_with_synthetic_smoke", "source": active_loop, "selected": "RAW TEAM\n" + loop_line, "strategic": "RAW CONTROL\n" + loop_line, "smoke": true, "runtime_active": true, "choices_active": true},
		{"id": "normal_unobserved_smoke", "source": active_loop, "selected": "RAW TEAM\n" + loop_line, "strategic": "RAW CONTROL\n" + loop_line, "smoke": false, "runtime_active": true, "choices_active": false},
		{"id": "selected_raw_missing", "source": active_loop, "selected": "", "strategic": "RAW CONTROL\n" + loop_line, "smoke": true, "runtime_active": false, "choices_active": false},
		{"id": "strategic_raw_missing", "source": active_loop, "selected": "RAW TEAM\n" + loop_line, "strategic": "", "smoke": true, "runtime_active": false, "choices_active": false},
		{"id": "changed_raw_does_not_confirm_visibility", "source": active_loop, "selected": "RAW TEAM changed: no second-loop line", "strategic": "RAW CONTROL changed: no second-loop line", "smoke": true, "runtime_active": false, "choices_active": false},
		{"id": "blocked_first_decision", "source": _next_loop_fixture(false), "selected": "RAW TEAM", "strategic": "RAW CONTROL", "smoke": true, "runtime_active": false, "choices_active": false},
	]
	for spec in cases:
		probe.set_fixture(Dictionary(spec.source), String(spec.selected), String(spec.strategic), bool(spec.smoke))
		var before := _owner_state(scene, owner, simulation, probe)
		var reference := _old_getter_sections(probe)
		_check(probe.selected_builds > 0 and probe.strategic_builds > 0, "%s reference actually exercises the old backward reads" % spec.id)
		probe.reset_reads()
		var projection: Dictionary = Dictionary(probe.call(API, String(spec.selected), String(spec.strategic)))
		_check(probe.next_loop_reads == 1, "%s local DAG reads the next-loop source exactly once" % spec.id)
		_check(probe.selected_builds == 0 and probe.strategic_builds == 0, "%s current RAW texts prevent repeated panel construction" % spec.id)
		_check(probe.selected_label_reads == 0 and probe.strategic_label_reads == 0, "%s local DAG does not read trimmed text back from other panels" % spec.id)
		for section in SECTIONS:
			_check(projection.has(section), "%s projection includes %s" % [spec.id, section])
			var actual_section: Dictionary = Dictionary(projection.get(section, {}))
			_check(actual_section == Dictionary(reference.get(section, {})), "%s %s matches unchanged getters with identical source/RAW inputs" % [spec.id, section])
			_check(_read_only(actual_section), "%s %s remains a read-only contract" % [spec.id, section])
		var runtime: Dictionary = Dictionary(projection.get("runtime_button", {}))
		var choices: Dictionary = Dictionary(projection.get("choice_buttons", {}))
		var execution: Dictionary = Dictionary(projection.get("execution_hook", {}))
		var draft: Dictionary = Dictionary(execution.get("command_draft", {}))
		_check(bool(runtime.get("button_enabled", false)) == bool(spec.runtime_active), "%s runtime gate follows the current RAW visibility evidence" % spec.id)
		_check(bool(choices.get("active", false)) == bool(spec.choices_active), "%s four-choice gate requires its existing smoke source" % spec.id)
		_check(bool(runtime.get("separate_go_required", false)) and not bool(runtime.get("auto_executes_go", true)), "%s runtime projection keeps GO separate" % spec.id)
		_check(not bool(draft.get("auto_execute", false)), "%s command draft never auto-executes" % spec.id)
		if bool(spec.runtime_active):
			_check(String(draft.get("command_type", "")) == "defend" and String(draft.get("fireteam_id", "")) == "blue", "%s draft preserves the selected fireteam and HOLD intent" % spec.id)
			_check(bool(draft.get("requires_go", false)) and String(draft.get("execute_action", "")) == "execute_selected_fireteam_orders", "%s draft preserves the existing GO owner" % spec.id)
		if bool(spec.choices_active):
			var choice_ids: Array = []
			var command_types: Array = []
			for button_variant in Array(choices.get("button_specs", [])):
				var button := Dictionary(button_variant)
				choice_ids.append(String(button.get("choice_id", "")))
				command_types.append(String(button.get("command_type", "")))
				_check(bool(button.get("separate_go_required", false)) and not bool(button.get("auto_executes_go", true)), "%s %s retains manual confirm then GO" % [spec.id, button.get("choice_id", "")])
			_check(choice_ids == ["secure_area", "push_objective", "flank_pressure", "reset_spacing"], "%s preserves all four ordered choices" % spec.id)
			_check(command_types == ["defend", "move", "flank", "move"], "%s preserves existing choice command types" % spec.id)
		probe.reset_reads()
		probe.call("_apply_release_first_decision_loop_two_runtime_button_polish", true, projection)
		probe.call("_apply_release_first_decision_loop_two_player_loop_runtime_choice_buttons", true, projection)
		_check(probe.next_loop_reads == 0 and probe.selected_builds == 0 and probe.strategic_builds == 0, "%s both apply paths consume the supplied projection" % spec.id)
		_check(_owner_state(scene, owner, simulation, probe) == before, "%s pure projection/apply leaves commands, effects, plans, ROE and units unchanged" % spec.id)
	probe.free()
	scene.queue_free()
	for _frame in range(3):
		await process_frame
	_finish()


func _old_getter_sections(probe: Node) -> Dictionary:
	var runtime: Dictionary = Dictionary(probe.call("get_release_first_decision_loop_two_runtime_button_snapshot"))
	var runtime_visual: Dictionary = Dictionary(probe.call("get_release_first_decision_loop_two_visual_polish_snapshot", {}, runtime))
	var choices: Dictionary = Dictionary(probe.call("get_release_first_decision_loop_two_player_loop_runtime_choice_buttons_snapshot"))
	var choice_visual: Dictionary = Dictionary(probe.call("get_release_first_decision_loop_two_player_loop_visual_polish_snapshot", {}, choices))
	return {"runtime_button": runtime, "runtime_visual": runtime_visual, "choice_buttons": choices, "choice_visual": choice_visual, "execution_hook": Dictionary(probe.call("get_release_first_decision_loop_two_execution_hook_snapshot"))}


func _next_loop_fixture(first_decision_ready: bool) -> Dictionary:
	var findings := _readonly()
	findings.merge({"schema": "sternenbuergerchen.release_first_decision_playtest_findings.v1", "task_id": "TASK_962", "status": "accepted_for_release_first_decision_next_loop", "accepted": true, "manual_review_done": true})
	var first := _readonly()
	first.merge({"schema": "sternenbuergerchen.first_decision_micro_scenario_polish.v1", "task_id": "TASK_956", "gate": "pass" if first_decision_ready else "review", "primary_cue_line": "NEXT Deckung pruefen -> GO"})
	var firefight := _readonly()
	firefight.merge({"active": true, "decision_line": "NEXT HIT LESEN / DEFEND | WHY FEUER", "next_token": "HIT LESEN / DEFEND", "why_token": "FEUER"})
	return NEXT_LOOP.build_snapshot(findings, first, firefight)


func _owner_state(scene: Node, owner: Node, simulation: Node, probe: Node) -> Dictionary:
	var units: Array = []
	for child in scene.get_children():
		if not child is Node2D or not child.has_method("get_unit_id") or not child.has_method("get_health"):
			continue
		units.append({"id": child.call("get_unit_id"), "health": child.call("get_health"), "vital": child.call("get_vital_state"), "position": (child as Node2D).position, "command": str(child.call("get_current_unit_command"))})
	return {"commands": Array(simulation.get("command_queue")).duplicate(true), "effects": Array(simulation.get("effects_queue")).duplicate(true), "tick": simulation.call("get_tick"), "roe": Array(simulation.call("get_authoritative_fire_rule_snapshot")).duplicate(true), "owner_plans": Array(owner.call("get_order_plans_snapshot")).duplicate(true), "owner_areas": Array(owner.call("get_area_orders_snapshot")).duplicate(true), "owner_multi_plans": Array(owner.call("get_multi_fireteam_plan_snapshot")).duplicate(true), "probe_plans": Array(probe.call("get_order_plans_snapshot")).duplicate(true), "probe_areas": Array(probe.call("get_area_orders_snapshot")).duplicate(true), "units": units}


func _readonly() -> Dictionary:
	return {"read_only": true, "ui_sets_gameplay_truth": false, "creates_command": false, "creates_movement": false, "creates_fire_event": false, "creates_damage_event": false, "sets_multiplayer_truth": false}


func _read_only(snapshot: Dictionary) -> bool:
	if not bool(snapshot.get("read_only", false)):
		return false
	for key in ["ui_sets_gameplay_truth", "creates_command", "creates_movement", "creates_fire_event", "creates_damage_event", "sets_multiplayer_truth"]:
		if bool(snapshot.get(key, false)):
			return false
	return true


func _check(ok: bool, label: String) -> void:
	if ok:
		_passed += 1
		print("PASS: ", label)
	else:
		_failed += 1
		print("FAIL: ", label)


func _finish() -> void:
	print("HUD_ARCHITECTURE_20261106_LIVE_PROJECTION: %d passed, %d failed" % [_passed, _failed])
	if _failed == 0:
		print("HUD_LIVE_PROJECTION_VERIFY_PASS")
	quit(1 if _failed > 0 else 0)
