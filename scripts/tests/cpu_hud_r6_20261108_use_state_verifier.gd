extends SceneTree
const MISSION: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
class Probe extends "res://scripts/tests/mission_tactical_sandbox_controller.gd":
	var observe := false
	var context_reads := 0
	var context_usec := 0
	var context_epoch := 0
	var invalidate_during_context := false
	var request_stack: Array[bool] = []
	var root_builds_by_generation: Dictionary = {}
	var root_requests := 0
	var oracle_mode := false
	func _ready() -> void:
		super._ready()
		set_process(false)
		set_physics_process(false)
	func model() -> Node:
		return _mission_hud_read_model
	func reset_counts() -> void:
		context_reads = 0
		context_usec = 0
		root_requests = 0
		root_builds_by_generation.clear()
	func get_mission_interaction_runtime_use_state_snapshot() -> Dictionary:
		if oracle_mode:
			return original_use_state_oracle()
		var nested := _mission_hud_read_model != null and int(_mission_hud_read_model.get("_projection_producer_depth")) > 0
		request_stack.append(nested)
		if observe and not nested:
			root_requests += 1
		var result := super.get_mission_interaction_runtime_use_state_snapshot()
		request_stack.pop_back()
		return result
	func _build_mission_interaction_runtime_use_context_for_readability() -> Dictionary:
		var started := Time.get_ticks_usec()
		var result := super._build_mission_interaction_runtime_use_context_for_readability()
		# Test-only data-source variation; never writes actors, clocks or commands.
		for marker in range(context_epoch):
			result.fireteam_positions.append({"fireteam_id": "r6_source_%d" % marker, "team_id": result.current_team_id, "position": Vector2(marker, 0), "active": true})
		if observe:
			context_reads += 1
			context_usec += Time.get_ticks_usec() - started
			if not request_stack.is_empty() and not request_stack.back():
				var gen := int(_mission_hud_read_model.get("_projection_generation"))
				root_builds_by_generation[gen] = int(root_builds_by_generation.get(gen, 0)) + 1
		if invalidate_during_context:
			invalidate_during_context = false
			_mission_hud_read_model.call("mark_heavy_state_changed")
		return result
	func original_use_state_oracle() -> Dictionary:
		var terrain_map_data = _get_active_mission_terrain_map_data_for_readability()
		var binding_snapshot: Dictionary = get_mission_interaction_point_binding_snapshot()
		var runtime_context: Dictionary = _build_mission_interaction_runtime_use_context_for_readability()
		return Dictionary(MISSION_INTERACTION_RUNTIME_USE_STATE_SCRIPT.call("build_snapshot", binding_snapshot, terrain_map_data, runtime_context)).duplicate(true)
var passed := 0
var failed := 0
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		print("FAIL: ", label)
func _run() -> void:
	var scene := MISSION.instantiate()
	var frontier_fixture := "--r6-frontier-fixture" in OS.get_cmdline_user_args()
	scene.get_node("MissionSetup").set("scenario_file_path", "res://data/mission_scenarios/frontier_probe_vertical_slice.json" if frontier_fixture else "res://data/mission_scenarios/ground_mission01_default.json")
	var original := scene.get_node("TacticalController")
	var probe := Probe.new()
	for property in original.get_property_list():
		var usage := int(property.usage)
		if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0 and (usage & PROPERTY_USAGE_EDITOR) != 0:
			probe.set(String(property.name), original.get(String(property.name)))
	scene.remove_child(original)
	original.free()
	probe.name = "TacticalController"
	scene.add_child(probe)
	root.add_child(scene)
	for frame in range(16):
		await process_frame
	var rm := probe.model()
	var sim := scene.get_node("SimulationRoot")
	check(rm != null, "Authored scene exposes the existing read model")
	var before := owner_state(sim)
	var expected := probe.original_use_state_oracle()
	check(int(expected.interaction_count) > 0 if frontier_fixture else int(expected.interaction_count) == 0, "Fixture exercises actual authored nonempty or empty interaction set")
	rm.call("begin_projection_pass")
	probe.reset_counts()
	probe.observe = true
	for iteration in range(3):
		check(probe.get_mission_interaction_runtime_use_state_snapshot() == expected, "Scoped complete payload matches frozen original %d" % iteration)
	check(probe.context_reads == 1, "Same synchronous pass builds source context only once")
	var returned := probe.get_mission_interaction_runtime_use_state_snapshot()
	returned["fireteam_position_count"] = -900
	if not Array(returned.interactions).is_empty():
		returned.interactions[0]["runtime_use_status"] = "external-write"
	check(probe.get_mission_interaction_runtime_use_state_snapshot() == expected, "Defensive output cannot poison the pass")
	probe.observe = false
	rm.call("end_projection_pass")
	check(int(rm.call("get_diagnostics_snapshot").projection_cached_entries) == 0, "End of outer pass discards every projected value")
	probe.context_epoch = 1
	expected = probe.original_use_state_oracle()
	probe.reset_counts()
	probe.observe = true
	for iteration in range(2):
		check(probe.get_mission_interaction_runtime_use_state_snapshot() == expected, "Outside-pass read remains live")
	check(probe.context_reads == 2, "Outside pass performs each real read")
	probe.observe = false
	rm.call("begin_projection_pass")
	probe.get_mission_interaction_runtime_use_state_snapshot()
	probe.context_epoch = 2
	rm.call("mark_heavy_state_changed")
	check(probe.get_mission_interaction_runtime_use_state_snapshot() == probe.original_use_state_oracle(), "Revision invalidation reads the changed full source in the same frame")
	var nested: Array[Dictionary] = []
	rm.call("project", "r6_outer_probe", func() -> Dictionary:
		nested.append(probe.get_mission_interaction_runtime_use_state_snapshot())
		probe.context_epoch = 3
		nested.append(probe.get_mission_interaction_runtime_use_state_snapshot())
		return {})
	check(int(nested[1].fireteam_position_count) == int(nested[0].fireteam_position_count) + 1, "Recursive producers bypass even an existing top-level cached entry")
	rm.call("end_projection_pass")
	rm.call("begin_projection_pass")
	probe.invalidate_during_context = true
	probe.reset_counts()
	probe.observe = true
	probe.get_mission_interaction_runtime_use_state_snapshot()
	probe.get_mission_interaction_runtime_use_state_snapshot()
	check(probe.context_reads == 2, "Producer invalidation cannot refill a superseded generation")
	probe.observe = false
	rm.call("end_projection_pass")
	probe.context_epoch = 0
	for heavy in [false, true]:
		probe.reset_counts()
		probe.observe = true
		probe.call("_update_ui", heavy, true)
		probe.observe = false
		var max_builds := 0
		for count in probe.root_builds_by_generation.values():
			max_builds = maxi(max_builds, int(count))
		check(probe.root_requests > 1, "Actual Full/Light requests repeated source projections")
		check(max_builds == 1, "Real Full/Light builds once per top-level read generation")
		print("R6_CONTEXT_TRACE ", JSON.stringify({"heavy": heavy, "root_requests": probe.root_requests, "context_reads": probe.context_reads, "context_usec": probe.context_usec, "builds_by_generation": probe.root_builds_by_generation}))
	check(owner_state(sim) == before, "All synchronous read projections preserve actors/tick/queues")
	for heavy in [false, true]:
		probe.oracle_mode = true
		probe.call("_update_ui", heavy, true)
		var original_ui := ui_state(probe)
		check(Dictionary(original_ui.labels).size() == 4, "UI oracle reads all four actual authored label sinks")
		probe.oracle_mode = false
		probe.call("_update_ui", heavy, true)
		check(ui_state(probe) == original_ui, "Full/Light RAWs, tooltips, native sources and GO policy match old source chain")
	check(owner_state(sim) == before, "UI oracle comparison preserves synchronous runtime owners")
	rm.call("begin_projection_pass")
	probe.get_mission_interaction_runtime_use_state_snapshot()
	await process_frame
	probe.context_epoch = 4
	check(probe.get_mission_interaction_runtime_use_state_snapshot() == probe.original_use_state_oracle(), "Engine frame expiry rejects a leaked prior scope")
	check(int(rm.call("get_diagnostics_snapshot").projection_scope_depth) == 0, "Expired scope is closed")
	rm.call("end_projection_pass")
	scene.queue_free()
	await process_frame
	print("R6_USE_STATE_DONE ", JSON.stringify({"passed": passed, "failed": failed}))
	quit(0 if failed == 0 else 1)

func ui_state(probe: Node) -> Dictionary:
	var labels: Dictionary = {}
	for path in [probe.get("command_feedback_label_path"), probe.get("FIRETEAM_STATUS_LABEL_PATH"), probe.get("STRATEGIC_STATUS_LABEL_PATH"), probe.get("MISSION_IDENTITY_BODY_LABEL_PATH")]:
		var label := probe.get_node_or_null(NodePath(str(path))) as Label
		if label != null:
			labels[str(path)] = {"text": label.text, "tooltip": label.tooltip_text, "raw": label.get_meta("mission_hud_raw_status_text", ""), "visible": label.visible}
	var go := probe.get_node(str(probe.get("COMMAND_GRID_PATH")) + "/GoCommandMatrixButton") as Button
	return {"labels": labels, "go_disabled": go.disabled, "decision": probe.get("_selected_fireteam_player_decision_snapshot").duplicate(true)}

func owner_state(sim: Node) -> Dictionary:
	var actors: Array = []
	for child in sim.get_parent().get_children():
		if child.has_method("get_unit_id") and child.has_method("get_health"):
			actors.append([child.call("get_unit_id"), child.call("get_health"), str(child.position), str(child.call("get_current_unit_command"))])
	return {"tick": sim.call("get_tick"), "commands": str(sim.get("command_queue")), "effects": str(sim.get("effect_queue")), "actors": actors}
