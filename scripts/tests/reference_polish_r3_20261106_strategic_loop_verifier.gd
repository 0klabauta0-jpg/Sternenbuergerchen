extends SceneTree
## Actual mission/readout components. Combat flags below are display fixtures,
## not contact/fire evidence. Actors, commands and simulation are never patched.
const MISSION: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

class LoopProbe extends "res://scripts/tests/mission_tactical_sandbox_controller.gd":
	var legacy_fallback_oracle := false
	var fixture_combat := -1
	var probe_guard_reentry := false
	var source_calls := 0
	var source_depth := 0
	var max_source_depth := 0
	var source_guard_receipts: Array[Dictionary] = []
	func _ready() -> void:
		super._ready()
		set_process(false)
		set_physics_process(false)
	func _build_mission_combat_hud_density_snapshot() -> Dictionary:
		var result := super._build_mission_combat_hud_density_snapshot()
		if fixture_combat >= 0:
			result = result.duplicate(true)
			result["active"] = fixture_combat > 0
			result["mission_control_line"] = "UI BRANCH FIXTURE" if fixture_combat > 0 else ""
		return result
	func _build_release_fire_exchange_contact_fire_primary_hud_line(density: Dictionary) -> String:
		if fixture_combat >= 0:
			return "CONTACT FIRE | UI BRANCH FIXTURE" if fixture_combat == 2 else ""
		return super._build_release_fire_exchange_contact_fire_primary_hud_line(density)
	func _build_release_first_decision_loop_two_hud_line(next_loop_override: Dictionary = {}) -> String:
		return super._build_release_first_decision_loop_two_hud_line({} if legacy_fallback_oracle else next_loop_override)
	func _build_release_first_decision_loop_two_polish_hud_line(next_loop_override: Dictionary = {}) -> String:
		return super._build_release_first_decision_loop_two_polish_hud_line({} if legacy_fallback_oracle else next_loop_override)
	func get_release_first_decision_next_playable_loop_snapshot(findings: Dictionary = {}, first_decision: Dictionary = {}, firefight: Dictionary = {}) -> Dictionary:
		source_calls += 1
		source_depth += 1
		max_source_depth = maxi(max_source_depth, source_depth)
		var receipt: Dictionary = {"hud_depth": _release_first_decision_loop_two_hud_build_depth, "polish_depth": _release_first_decision_loop_two_polish_hud_build_depth, "normal_reentry_blocked": true, "polish_reentry_blocked": true}
		if probe_guard_reentry:
			var fixture: Dictionary = {"active": true, "visible_loop_line": "SYNTHETIC REENTRY", "primary_line": "SYNTHETIC REENTRY", "status": "fixture_only"}
			# Non-empty explicit inputs isolate the existing guard itself without
			# causing another source read or pretending to confirm a live loop.
			if _release_first_decision_loop_two_hud_build_depth > 0:
				receipt.normal_reentry_blocked = _build_release_first_decision_loop_two_hud_line(fixture).is_empty()
			if _release_first_decision_loop_two_polish_hud_build_depth > 0:
				receipt.polish_reentry_blocked = _build_release_first_decision_loop_two_polish_hud_line(fixture).is_empty()
		var result := super.get_release_first_decision_next_playable_loop_snapshot(findings, first_decision, firefight)
		source_guard_receipts.append(receipt)
		source_depth -= 1
		return result
	func configure_case(spec: Dictionary) -> void:
		fixture_combat = int(spec.combat)
		_release_first_decision_loop_two_hud_build_depth = int(spec.hud_depth)
		_release_first_decision_loop_two_polish_hud_build_depth = int(spec.polish_depth)
	func guard_depths() -> Vector2i:
		return Vector2i(_release_first_decision_loop_two_hud_build_depth, _release_first_decision_loop_two_polish_hud_build_depth)
	func reset_reads() -> void:
		source_calls = 0
		source_depth = 0
		max_source_depth = 0
		source_guard_receipts.clear()

var _passed := 0
var _failed := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := MISSION.instantiate()
	var original := scene.get_node("TacticalController")
	var probe := LoopProbe.new()
	for property in original.get_property_list():
		var usage := int(property.usage)
		if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0 and (usage & PROPERTY_USAGE_EDITOR) != 0:
			probe.set(String(property.name), original.get(String(property.name)))
	scene.remove_child(original)
	original.free()
	probe.name = "TacticalController"
	scene.add_child(probe)
	root.add_child(scene)
	for _frame in range(12):
		await process_frame
	probe.set_process(false)
	probe.set_physics_process(false)
	var simulation := scene.get_node("SimulationRoot")
	var cases: Array[Dictionary] = [
		{"id": "real_current_state", "combat": -1, "hud_depth": 0, "polish_depth": 0},
		{"id": "display_no_combat", "combat": 0, "hud_depth": 0, "polish_depth": 0},
		{"id": "display_combat_no_contact", "combat": 1, "hud_depth": 0, "polish_depth": 0},
		{"id": "display_contact_fire_early_return", "combat": 2, "hud_depth": 0, "polish_depth": 0},
		{"id": "hud_guard_active", "combat": 1, "hud_depth": 1, "polish_depth": 0},
		{"id": "polish_guard_active", "combat": 1, "hud_depth": 0, "polish_depth": 1},
		{"id": "both_existing_guards_active", "combat": 1, "hud_depth": 1, "polish_depth": 1},
	]
	for spec in cases:
		probe.configure_case(spec)
		probe.probe_guard_reentry = false
		probe.legacy_fallback_oracle = true
		probe.reset_reads()
		var reference: String = probe.call("_build_strategic_status_text")
		var reference_source_calls := probe.source_calls
		var owner_before := _owner_state(probe, simulation)
		var expected_depths := Vector2i(int(spec.hud_depth), int(spec.polish_depth))
		probe.legacy_fallback_oracle = false
		probe.probe_guard_reentry = true
		probe.reset_reads()
		var actual: String = probe.call("_build_strategic_status_text")
		var expected_reads := 0 if expected_depths.x > 0 and expected_depths.y > 0 else 1
		_check(probe.source_calls == expected_reads, "%s strategic RAW builds one local next-loop source, or none when both guards block" % spec.id)
		_check(actual == reference, "%s RAW remains byte-identical to the actual old helper fallback route" % spec.id)
		_check(probe.guard_depths() == expected_depths and probe.source_depth == 0, "%s restores the exact prior guard depths" % spec.id)
		_check(probe.max_source_depth <= 1, "%s causes no recursive source build" % spec.id)
		for receipt in probe.source_guard_receipts:
			_check(int(receipt.hud_depth) > 0 or int(receipt.polish_depth) > 0, "%s source construction retains an existing helper recursion guard" % spec.id)
			_check(bool(receipt.normal_reentry_blocked) and bool(receipt.polish_reentry_blocked), "%s explicit nested helper probes retain guard behavior" % spec.id)
		_check(_owner_state(probe, simulation) == owner_before, "%s leaves actor, command, effect, plan and simulation owners unchanged" % spec.id)
		print("R3_STRATEGIC_LOOP_FACTS " + JSON.stringify({"case": spec.id, "legacy_source_calls": reference_source_calls, "actual_source_calls": probe.source_calls, "expected_source_calls": expected_reads, "raw_equal": actual == reference, "guard_depths": str(probe.guard_depths()), "source_guards": probe.source_guard_receipts}))
		var first_calls := probe.source_calls
		probe.call("_build_strategic_status_text")
		_check(probe.source_calls - first_calls == expected_reads, "%s the next independent RAW assembly reads fresh instead of retaining a display cache" % spec.id)
	probe.configure_case({"combat": -1, "hud_depth": 0, "polish_depth": 0})
	probe.probe_guard_reentry = false
	var explicit: Dictionary = {"active": true, "visible_loop_line": "EXPLICIT FIXTURE LINE", "primary_line": "EXPLICIT FIXTURE LINE", "status": "fixture_only"}
	probe.reset_reads()
	var line: String = probe.call("_build_release_first_decision_loop_two_hud_line", explicit)
	probe.call("_build_release_first_decision_loop_two_polish_hud_line", explicit)
	_check(line == "EXPLICIT FIXTURE LINE" and probe.source_calls == 0, "Existing explicit helper overrides still bypass the runtime source")
	scene.queue_free()
	await process_frame
	await process_frame
	print("R3_STRATEGIC_LOOP: %d passed, %d failed" % [_passed, _failed])
	if _failed == 0:
		print("R3_STRATEGIC_LOOP_PASS")
	quit(1 if _failed > 0 else 0)


func _owner_state(owner: Node, simulation: Node) -> Dictionary:
	var actors: Dictionary = {}
	for id in owner.call("_get_displayable_fireteam_ids"):
		for unit in owner.call("_get_fireteam_units", String(id), true):
			actors[String(unit.get_path())] = {"position": unit.global_position, "health": unit.call("get_health") if unit.has_method("get_health") else null, "vital": unit.call("get_vital_state") if unit.has_method("get_vital_state") else ""}
	return {"commands": Array(simulation.get("command_queue")).duplicate(true), "effects": Array(simulation.get("effects_queue")).duplicate(true), "plans": owner.call("get_order_plans_snapshot"), "areas": owner.call("get_area_orders_snapshot"), "tick": simulation.call("get_tick"), "actors": actors}


func _check(ok: bool, message: String) -> void:
	if ok:
		_passed += 1
		print("PASS: ", message)
	else:
		_failed += 1
		print("FAIL: ", message)
