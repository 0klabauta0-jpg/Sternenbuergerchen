extends SceneTree
## Synthetic scheduler/component proof with real presentation super calls.
## Only UI cadence/feedback/dirty fixtures change. Never physical/FPS evidence.
const MISSION: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const KEYS := ["primary_secondary", "craft", "world_status", "cards"]
const GETTER := "get_periodic_hud_projection_queue_debug_snapshot"
const REQUEST := "_request_periodic_hud_projection"

class Peer extends Node:
	var calls := 0
	func refresh_hud() -> void:
		calls += 1

class Probe extends "res://scripts/tests/mission_tactical_sandbox_controller.gd":
	var observe := false
	var driving_periodic := false
	var api_depth := 0
	var rows: Array[Dictionary] = []
	var matrices: Array[Dictionary] = []
	var after_craft_request := false
	var after_craft_full := false
	var injection_active := false
	func _ready() -> void:
		super._ready()
		set_process(false)
		set_physics_process(false)
	func _update_ui(heavy: bool = true, force: bool = true) -> void:
		api_depth += 1
		super._update_ui(heavy, force)
		api_depth -= 1
	func note(key: String) -> void:
		if observe:
			rows.append({"key": key, "frame": Engine.get_process_frames(), "periodic": driving_periodic or api_depth == 0, "pass_active": _mission_hud_read_model != null and bool(_mission_hud_read_model.call("is_projection_pass_active"))})
	func _refresh_mission_control_craft_summary() -> void:
		super._refresh_mission_control_craft_summary()
		note("craft")
		if observe and not injection_active and (after_craft_request or after_craft_full):
			injection_active = true
			if after_craft_request:
				after_craft_request = false
				call(REQUEST, true)
			if after_craft_full:
				after_craft_full = false
				_update_ui(true, true)
			injection_active = false
	func _refresh_world_overlays() -> void:
		super._refresh_world_overlays()
		note("world_status")
	func _refresh_fireteam_mini_cards() -> void:
		super._refresh_fireteam_mini_cards()
		note("cards")
	func _apply_release_firefight_command_matrix_visual_polish(selected_raw: String = "", strategic_raw: String = "") -> void:
		super._apply_release_firefight_command_matrix_visual_polish(selected_raw, strategic_raw)
		note("primary_secondary")
		if observe:
			matrices.append({"frame": Engine.get_process_frames(), "pass_active": _mission_hud_read_model != null and bool(_mission_hud_read_model.call("is_projection_pass_active")), "selected": selected_raw, "strategic": strategic_raw, "command": _get_label_text(command_feedback_label_path), "fixture_feedback": _last_command_text})
	func reset_observations() -> void:
		rows.clear()
		matrices.clear()
	func periodic_due() -> void:
		# These are presentation cadence/dirty fields, not gameplay timers.
		_card_refresh_time_remaining = 0.0
		_runtime_hud_heavy_refresh_time_remaining = 0.0
		_runtime_hud_command_refresh_pending = true
		driving_periodic = true
		_process(0.0)
		driving_periodic = false

var passed := 0
var failed := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene := MISSION.instantiate()
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
	for _frame in range(12):
		await process_frame
	var manager := scene.get_node("UpdateManager")
	# Invoke its real HUD batch explicitly; the test does not drain/alter AI.
	manager.set_process(false)
	var simulation := scene.get_node("SimulationRoot")
	probe.call("set_mission_visible_frame_timing_debug_enabled", true)
	probe.observe = true
	probe.reset_observations()
	probe.periodic_due()
	check(probe.rows.is_empty(), "Periodic heavy due only enqueues and does not execute its former four-group burst")
	print("R4_HUD_QUEUE_BASELINE_BOUNDARIES ", JSON.stringify(probe.rows))
	check(probe.has_method(GETTER) and probe.has_method(REQUEST) and probe.has_method("refresh_hud"), "Controller exposes bounded periodic request/Manager/drain telemetry APIs")
	if not probe.has_method(GETTER) or not probe.has_method(REQUEST) or not probe.has_method("refresh_hud"):
		scene.queue_free()
		await process_frame
		finish()
		return
	probe.call("_update_ui", true, true)
	probe.reset_observations()
	var before := owner_state(probe, simulation)
	probe.call(REQUEST, true)
	var first := snapshot(probe)
	probe.call(REQUEST, true)
	var merged := snapshot(probe)
	check(pending(first).size() == 4 and pending(merged).size() == 4 and int(merged.get("max_pending_keys", 99)) <= 4, "Repeated requests coalesce to exactly four fixed pending keys")
	check(sum_counts(merged, "coalesced_counts") > sum_counts(first, "coalesced_counts") and probe.rows.is_empty(), "Coalescing records demand without executing hidden extra work")
	check(owner_state(probe, simulation) == before, "Request/coalescing changes no real runtime owner")
	var peer := Peer.new()
	scene.add_child(peer)
	manager.call("mark_hud_dirty", peer)
	var cycle_start := snapshot(probe)
	var frames_used: int = await drain_until_idle(probe, manager, simulation, 4)
	var completed := snapshot(probe)
	check(pending(completed).is_empty() and frames_used <= 4, "Normal uncontended cycle completes all four pending jobs within four renderframes")
	check(all_advanced(completed, cycle_start), "Every requested phase really completes instead of dropping a hidden surface")
	check(peer.calls == 1, "Other dirty HUD peers retain UpdateManager service")
	check(all_periodic_passes_active(probe), "Every actual periodic phase has its own active synchronous ReadModel pass")
	check(read_model_closed(probe), "No projection pass or cached source survives the completed cycle")
	check(not probe.matrices.is_empty() and matrices_fresh(probe), "Primary and Secondary/Matrix consume current sources together in the same pass")
	var defensive := snapshot(probe)
	defensive["pending_keys"] = ["forged"]
	defensive["completed_counts"] = {"craft": -999}
	check(not pending(snapshot(probe)).has("forged") and int(Dictionary(snapshot(probe).get("completed_counts", {})).get("craft", 0)) >= 0, "Telemetry getter returns defensive scheduling data")
	# Command-Light is immediate but cannot acknowledge unfinished heavy work.
	probe.call(REQUEST, true)
	var pending_before_light := pending(snapshot(probe))
	var original_feedback: String = probe.get("_last_command_text")
	probe.set("_last_command_text", "R4_LIGHT_IMMEDIATE_FIXTURE")
	probe.reset_observations()
	before = owner_state(probe, simulation)
	probe.call("_update_ui", false, false)
	check(String(probe.call("_get_label_text", probe.get("command_feedback_label_path"))).contains("R4_LIGHT_IMMEDIATE_FIXTURE"), "Existing command-Light API presents current feedback before returning")
	check(pending(snapshot(probe)) == pending_before_light and probe.rows.is_empty(), "Command-Light preserves unfinished heavy jobs and does no hidden heavy phase")
	check(owner_state(probe, simulation) == before and read_model_closed(probe), "Light API remains owner-pure and closes its projection pass")
	probe.set("_last_command_text", original_feedback)
	# Prime actual guards synchronously with stable owners, then put Force only
	# in the accepted queue tickets. An explicit Full(false) must inherit it
	# before cancel, otherwise the unchanged craft/card signatures skip work.
	probe.call("_update_ui", true, true)
	probe.call(REQUEST, true)
	probe.reset_observations()
	before = owner_state(probe, simulation)
	check(not bool(probe.get("_runtime_hud_command_refresh_pending")) and pending(snapshot(probe)).size() == 4, "Queued Force is retained in tickets after the command pending flag is transferred")
	probe.call("_update_ui", true, false)
	var inherited_force_keys: Array = []
	for row in probe.rows:
		inherited_force_keys.append(String(row.key))
	print("R4_HUD_QUEUE_EXPLICIT_FORCE_BOUNDARIES ", JSON.stringify(inherited_force_keys))
	check(inherited_force_keys.has("craft") and inherited_force_keys.has("cards"), "Explicit Full(false) inherits queued Force and really invokes unchanged craft/card groups")
	check(pending(snapshot(probe)).is_empty() and owner_state(probe, simulation) == before and read_model_closed(probe), "Inherited-Force Full completes synchronously and supersedes only fulfilled work without owner changes")
	# Explicit Full remains the synchronous compatibility oracle and cancels old
	# keys/tokens only after doing the complete work it supersedes.
	probe.reset_observations()
	before = owner_state(probe, simulation)
	probe.call("_update_ui", true, true)
	check(all_keys_seen(probe.rows) and pending(snapshot(probe)).is_empty(), "Existing Full API synchronously projects all groups and supersedes older jobs")
	check(owner_state(probe, simulation) == before and read_model_closed(probe), "Explicit Full preserves owners and leaves no open projection pass")
	probe.reset_observations()
	for _frame in range(2):
		await process_frame
		drain_batch(manager)
	check(probe.rows.is_empty(), "Old deferred tokens cannot resurrect phases after explicit Full")
	# A real Manager entry has no epoch of its own. After a heavy explicit Full,
	# a fresh same-frame request must wait instead of adding another heavy job
	# when that old/publicly reinserted node entry is serviced.
	probe.call(REQUEST, true)
	manager.call("mark_hud_dirty", probe)
	probe.call("_update_ui", true, true)
	probe.reset_observations()
	probe.call(REQUEST, true)
	var after_full_request := snapshot(probe)
	manager.call("mark_hud_dirty", probe)
	drain_batch(manager)
	check(probe.rows.is_empty() and sum_counts(snapshot(probe), "completed_counts") == sum_counts(after_full_request, "completed_counts") and pending(snapshot(probe)).size() == 4, "Old Manager entry cannot run a fresh heavy generation in the same frame as explicit Full")
	await drain_until_idle(probe, manager, simulation, 4)
	check(pending(snapshot(probe)).is_empty(), "Fresh generation after same-frame Full is deferred rather than lost")
	# Request after a real completed craft projection must remain pending, not
	# be cleared by that outer job's stale completion/force token.
	probe.after_craft_request = true
	probe.call(REQUEST, true)
	var reentry_start := snapshot(probe)
	await drain_until_idle(probe, manager, simulation, 12)
	var reentry_end := snapshot(probe)
	check(pending(reentry_end).is_empty() and all_advanced(reentry_end, reentry_start), "Reentrant force demand converges with no missing phase")
	check(count_delta(reentry_end, reentry_start, "craft") >= 2, "New request after craft output is not consumed by its old completion")
	# The opposite reentry is a complete explicit replacement of remaining work.
	probe.after_craft_full = true
	probe.call(REQUEST, true)
	await drain_until_idle(probe, manager, simulation, 8)
	check(pending(snapshot(probe)).is_empty() and read_model_closed(probe), "Fullsync inside a phase safely supersedes the outer generation")
	probe.reset_observations()
	for _frame in range(2):
		await process_frame
		drain_batch(manager)
	check(probe.rows.is_empty(), "Reentrant Full leaves no stale deferred work alive")
	print("R4_HUD_QUEUE_FINAL ", JSON.stringify(snapshot(probe)))
	scene.queue_free()
	await process_frame
	await process_frame
	finish()

func drain_until_idle(probe: Probe, manager: Node, simulation: Node, limit: int) -> int:
	var used := 0
	while not pending(snapshot(probe)).is_empty() and used < limit:
		await process_frame
		used += 1
		# A pure current feedback input changes after enqueue, before execution.
		probe.set("_last_command_text", "R4_PHASE_FRESH_%d" % Engine.get_process_frames())
		var before := owner_state(probe, simulation)
		var a := snapshot(probe)
		drain_batch(manager)
		var b := snapshot(probe)
		var rows_after_first := probe.rows.size()
		# Deferred reregistration normally leaves this batch empty. Reinsert via
		# the real public manager API to exercise the controller's frame guard.
		manager.call("mark_hud_dirty", probe)
		drain_batch(manager)
		var c := snapshot(probe)
		# Explicit Full injected by the fixture is intentionally synchronous; it
		# is not periodic queue work and does not increment periodic completions.
		check(sum_counts(b, "completed_counts") - sum_counts(a, "completed_counts") <= 1 and sum_counts(c, "completed_counts") == sum_counts(b, "completed_counts") and probe.rows.size() == rows_after_first, "A repeated actual Manager batch cannot execute a second periodic phase in one renderframe")
		check(owner_state(probe, simulation) == before and read_model_closed(probe), "Actual phase drain preserves runtime owners and closes its read pass")
	return used

func drain_batch(manager: Node) -> void:
	manager.call("_process_batch", manager.get("_hud_dirty"), manager.get("_hud_dirty_order"), "refresh_hud")

func snapshot(probe: Node) -> Dictionary:
	return Dictionary(probe.call(GETTER))

func pending(value: Dictionary) -> Array:
	return Array(value.get("pending_keys", []))

func sum_counts(value: Dictionary, field: String) -> int:
	var result := 0
	for item in Dictionary(value.get(field, {})).values():
		result += int(item)
	return result

func count_delta(after: Dictionary, before: Dictionary, key: String) -> int:
	return int(Dictionary(after.get("completed_counts", {})).get(key, 0)) - int(Dictionary(before.get("completed_counts", {})).get(key, 0))

func all_advanced(after: Dictionary, before: Dictionary) -> bool:
	for key in KEYS:
		if count_delta(after, before, key) < 1:
			return false
	return true

func all_keys_seen(rows: Array[Dictionary]) -> bool:
	var seen: Dictionary = {}
	for row in rows:
		seen[String(row.key)] = true
	return seen.size() == 4

func all_periodic_passes_active(probe: Probe) -> bool:
	for row in probe.rows:
		if bool(row.periodic) and not bool(row.pass_active):
			return false
	return not probe.rows.is_empty()

func matrices_fresh(probe: Probe) -> bool:
	for row in probe.matrices:
		if not bool(row.pass_active) or String(row.selected).is_empty() or String(row.strategic).is_empty() or not String(row.command).contains(String(row.fixture_feedback)):
			return false
	return true

func read_model_closed(probe: Probe) -> bool:
	var model: Node = probe.get("_mission_hud_read_model")
	return model != null and not bool(model.call("is_projection_pass_active")) and int(Dictionary(model.call("get_diagnostics_snapshot")).get("projection_scope_depth", -1)) == 0

func owner_state(probe: Node, simulation: Node) -> Dictionary:
	var actors: Dictionary = {}
	for id in probe.call("_get_displayable_fireteam_ids"):
		for unit in probe.call("_get_fireteam_units", String(id), true):
			actors[String(unit.get_path())] = {"position": unit.global_position, "health": unit.call("get_health") if unit.has_method("get_health") else null, "runtime": unit.call("get_runtime_status").call("to_dict") if unit.has_method("get_runtime_status") else {}}
	return {"commands": Array(simulation.get("command_queue")).duplicate(true), "effects": Array(simulation.get("effects_queue")).duplicate(true), "plans": probe.call("get_order_plans_snapshot"), "tick": simulation.call("get_tick"), "actors": actors}

func check(ok: bool, message: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
	print("PASS: " if ok else "FAIL: ", message)

func finish() -> void:
	print("R4_PERIODIC_HUD_QUEUE: %d passed, %d failed" % [passed, failed])
	if failed == 0:
		print("R4_PERIODIC_HUD_QUEUE_PASS")
	quit(1 if failed else 0)
