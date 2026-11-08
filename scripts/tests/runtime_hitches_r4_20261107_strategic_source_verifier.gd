extends SceneTree
## Real controller builders and owner reads. Pure UI input fixtures cover four
## progression states; no actor/clock/command or runtime source is patched.
const MISSION: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const ORACLE_PATH := "res://scripts/tests/runtime_hitches_r4_20261107_strategic_source_oracle.json"

class ControllerProbe extends "res://scripts/tests/mission_tactical_sandbox_controller.gd":
	var fixture_inputs := false
	var fixture_stage := 0
	var next_calls := 0
	var gate_reads := 0
	var cargo_reads := 0
	var reenter_once := false
	var inside_reentry := false
	var nested_readout: Dictionary = {}
	var reference_readout_enabled := false
	var reference_readout: Dictionary = {}
	func _ready() -> void:
		super._ready()
		set_process(false)
		set_physics_process(false)
	func reset_counts() -> void:
		next_calls = 0
		gate_reads = 0
		cargo_reads = 0
	func _should_sync_frontier_probe_route_callouts() -> bool:
		return true if fixture_inputs else super._should_sync_frontier_probe_route_callouts()
	func _get_mission_scenario_runtime_gate_snapshot_for_readability() -> Dictionary:
		gate_reads += 1
		if not fixture_inputs:
			return super._get_mission_scenario_runtime_gate_snapshot_for_readability()
		return {"gates": [{"objective_type": "air_defense_shutdown", "complete": fixture_stage >= 1}, {"objective_type": "computer_hold", "complete": fixture_stage >= 2, "hold_required_seconds": 18.0}, {"objective_type": "cargo_touchdown_extract", "complete": fixture_stage >= 3}], "all_gates_complete": fixture_stage >= 3}
	func _get_mission_cargo_touchdown_snapshot_for_readability() -> Dictionary:
		cargo_reads += 1
		if not fixture_inputs:
			return super._get_mission_cargo_touchdown_snapshot_for_readability()
		return {"cargo_state": "departed" if fixture_stage >= 3 else "landed"}
	func _build_frontier_probe_playfeel_next_interaction_snapshot() -> Dictionary:
		next_calls += 1
		var result := super._build_frontier_probe_playfeel_next_interaction_snapshot()
		if reenter_once and not inside_reentry:
			reenter_once = false
			inside_reentry = true
			var original_stage := fixture_stage
			fixture_stage = 1
			nested_readout = _build_frontier_probe_one_screen_playability_readout()
			fixture_stage = original_stage
			inside_reentry = false
		return result
	func _build_frontier_probe_one_screen_playability_readout() -> Dictionary:
		return reference_readout.duplicate(true) if reference_readout_enabled else super._build_frontier_probe_one_screen_playability_readout()
	func _build_mission_time_limit_text() -> String:
		# Freeze only this display string for the pure UI parity fixture. The
		# actual simulation clock is neither readjusted nor advanced here.
		return "Time fixture" if fixture_inputs else super._build_mission_time_limit_text()

var passed := 0
var failed := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene := MISSION.instantiate()
	var original := scene.get_node("TacticalController")
	var probe := ControllerProbe.new()
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
	var simulation := scene.get_node("SimulationRoot")
	var observed: Dictionary = {}
	var expected_ids := ["disable_air_defense", "hold_station_computer", "secure_cargo_touchdown", "open_debrief"]
	for stage in range(-1, 4):
		probe.fixture_inputs = stage >= 0
		probe.fixture_stage = maxi(stage, 0)
		var label := "actual_runtime" if stage < 0 else "fixture_%d" % stage
		var before := owner_state(probe, simulation)
		# The real NextInteraction also asks _should_sync..., which legitimately
		# reads the gate again. OneScreen has its own scenario-context read too.
		# Measure these direct dependencies rather than assume one gate read.
		probe.reset_counts()
		probe.call("_build_frontier_probe_playfeel_next_interaction_snapshot")
		var source_gate_reads: int = probe.gate_reads
		var source_cargo_reads: int = probe.cargo_reads
		probe.reset_counts()
		probe.call("_should_sync_frontier_probe_route_callouts")
		var context_gate_reads: int = probe.gate_reads
		var context_cargo_reads: int = probe.cargo_reads
		probe.reset_counts()
		var readout: Dictionary = probe.call("_build_frontier_probe_one_screen_playability_readout")
		check(probe.next_calls == 1 and probe.gate_reads == source_gate_reads + context_gate_reads and probe.cargo_reads == source_cargo_reads + context_cargo_reads, "%s OneScreen reads NextInteraction once and preserves exact direct-source/context owner reads" % label)
		print("R4_STRATEGIC_SOURCE_COUNTS ", JSON.stringify({"case": label, "next": probe.next_calls, "gates": probe.gate_reads, "cargo": probe.cargo_reads, "direct_source_gate_reads": source_gate_reads, "direct_source_cargo_reads": source_cargo_reads, "direct_context_gate_reads": context_gate_reads, "direct_context_cargo_reads": context_cargo_reads}))
		probe.reset_counts()
		var handoff: Dictionary = probe.call("_build_frontier_probe_debrief_handoff_feel_snapshot")
		check(probe.next_calls == 1 and probe.gate_reads == source_gate_reads and probe.cargo_reads == source_cargo_reads, "%s standalone Handoff always reads exactly one fresh direct source" % label)
		if stage >= 0:
			check(String(readout.get("next_interaction_id", "")) == expected_ids[stage] and bool(readout.get("active", false)), "%s preserves its current explicit progression state" % label)
			var actual_raw: String = probe.call("_build_strategic_status_text")
			probe.reference_readout = readout.duplicate(true)
			probe.reference_readout_enabled = true
			var reference_raw: String = probe.call("_build_strategic_status_text")
			probe.reference_readout_enabled = false
			check(actual_raw == reference_raw, "%s complete RAW is byte-identical with its independent readout oracle input" % label)
		observed[label] = {"readout": readout, "handoff": handoff}
		check(owner_state(probe, simulation) == before, "%s presentation preserves actors, tick, plans and command/effect owners" % label)
	# A nested invocation deliberately sees a different pure source. Neither
	# caller may inherit a globally remembered projection from the other one.
	probe.fixture_inputs = true
	probe.fixture_stage = 0
	probe.reenter_once = true
	probe.reset_counts()
	var before := owner_state(probe, simulation)
	var outer: Dictionary = probe.call("_build_frontier_probe_one_screen_playability_readout")
	check(probe.next_calls == 2 and probe.gate_reads == 2 and probe.cargo_reads == 2, "Reentrant OneScreen invocations each own one fresh local source")
	check(outer == observed["fixture_0"]["readout"] and probe.nested_readout == observed["fixture_1"]["readout"], "Nested fresh state cannot replace the outer frozen source or inherit its projection")
	check(owner_state(probe, simulation) == before, "Reentrant projection preserves all real runtime owners")
	probe.fixture_stage = 3
	probe.reset_counts()
	var fresh: Dictionary = probe.call("_build_frontier_probe_one_screen_playability_readout")
	check(fresh == observed["fixture_3"]["readout"], "A later standalone invocation reads current input after reentry")
	var explicit_helper := "_build_frontier_probe_debrief_handoff_feel_snapshot_from_next_interaction"
	check(probe.has_method(explicit_helper), "Explicit Handoff helper accepts a source independently of standalone owner reads")
	if probe.has_method(explicit_helper):
		probe.reset_counts()
		var empty: Dictionary = probe.call(explicit_helper, {})
		check(probe.next_calls == 0 and not bool(empty.get("active", true)) and not bool(empty.get("handoff_ready", true)), "Explicit empty source remains empty without a hidden owner fallback")
		var supplied: Dictionary = probe.call("_build_frontier_probe_playfeel_next_interaction_snapshot")
		var supplied_before := var_to_bytes(supplied)
		probe.reset_counts()
		var explicit: Dictionary = probe.call(explicit_helper, supplied)
		check(explicit == observed["fixture_3"]["handoff"] and probe.next_calls == 0 and var_to_bytes(supplied) == supplied_before, "Explicit current source gives exact Handoff output without mutation or another owner read")
	# Capture only immutable builder values, never the real-time/scene diagnostics.
	# Root pins this exact prepatch output after real RED, before product changes.
	print("R4_STRATEGIC_SOURCE_ORACLE ", JSON.stringify(observed))
	if FileAccess.file_exists(ORACLE_PATH):
		var expected: Variant = JSON.parse_string(FileAccess.get_file_as_string(ORACLE_PATH))
		check(expected is Dictionary and JSON.parse_string(JSON.stringify(observed)) == expected, "All complete readout/Handoff outputs equal the pinned real prepatch oracle")
	else:
		print("R4_STRATEGIC_SOURCE_ORACLE_PENDING: Root must pin this actual RED output before GREEN")
	scene.queue_free()
	await process_frame
	await process_frame
	print("R4_STRATEGIC_SOURCE: %d passed, %d failed" % [passed, failed])
	if failed == 0 and FileAccess.file_exists(ORACLE_PATH):
		print("R4_STRATEGIC_SOURCE_PASS")
	quit(1 if failed > 0 or not FileAccess.file_exists(ORACLE_PATH) else 0)

func owner_state(probe: Node, simulation: Node) -> Dictionary:
	var actors: Dictionary = {}
	for id in probe.call("_get_displayable_fireteam_ids"):
		for unit in probe.call("_get_fireteam_units", String(id), true):
			actors[String(unit.get_path())] = {"position": unit.global_position, "health": unit.call("get_health") if unit.has_method("get_health") else null, "vital": unit.call("get_vital_state") if unit.has_method("get_vital_state") else ""}
	return {"commands": Array(simulation.get("command_queue")).duplicate(true), "effects": Array(simulation.get("effects_queue")).duplicate(true), "plans": probe.call("get_order_plans_snapshot"), "areas": probe.call("get_area_orders_snapshot"), "tick": simulation.call("get_tick"), "actors": actors}

func check(ok: bool, message: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
	print("PASS: " if ok else "FAIL: ", message)
