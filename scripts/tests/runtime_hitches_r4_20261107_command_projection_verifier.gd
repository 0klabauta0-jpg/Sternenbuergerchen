extends SceneTree
## Test-only trace of real virtual super calls in the authored mission scene.
## Synthetic component/scheduling proof, not native cadence/physical play proof.
## No actors, HP, positions, timers, authority rules or runtime sources are patched.

const MISSION: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const SOURCE_KEYS: Array[String] = ["fireteam_anchors", "plan_dicts", "waypoint_intent_preview_entries", "area_order_dicts", "ad_hoc_order_dicts", "security_dicts", "movement_state_dicts"]
const COUNT_KEYS: Array[String] = ["anchors", "plans", "preview", "areas", "ad_hoc", "security", "movement"]

class PreviewProbe extends "res://scripts/tactical/waypoint_intent_preview_resolver.gd":
	var observer: Callable
	func build_preview_entries(plans: Array, anchors: Array, options: Dictionary = {}) -> Array:
		var started := Time.get_ticks_usec()
		var result: Array = super.build_preview_entries(plans, anchors, options)
		if observer.is_valid():
			observer.call("preview", started, get_stack())
		return result

class ControllerProbe extends "res://scripts/tests/mission_tactical_sandbox_controller.gd":
	var observe := false
	var source_calls: Dictionary = {}
	var caller_calls: Dictionary = {}
	var scopes: Array[Dictionary] = []
	var button_receipts: Array[Dictionary] = []
	func _ready() -> void:
		# The exact real resolver implementation still computes every result;
		# its test-only subtype observes calls without changing its inputs/output.
		var preview_probe := PreviewProbe.new()
		preview_probe.observer = _note_source
		_waypoint_intent_preview_resolver = preview_probe
		super._ready()
		set_process(false)
		set_physics_process(false)
	func reset_observations() -> void:
		source_calls.clear()
		caller_calls.clear()
		scopes.clear()
		button_receipts.clear()
	func _note_source(key: String, started: int, stack: Array) -> void:
		if not observe:
			return
		var caller: String = String(Dictionary(stack[1]).get("function", "")) if stack.size() > 1 else ""
		var call_key := key + ":" + caller
		caller_calls[call_key] = int(caller_calls.get(call_key, 0)) + 1
		# Count the visual-source call graph, not unrelated decision/HUD readers.
		if caller in ["_refresh_order_visuals", "_sync_primary_3d_order_visuals", "_build_waypoint_intent_preview_entries", "_build_order_visual_sources", "_build_waypoint_intent_preview_entries_from_sources", "_sync_primary_3d_order_visuals_from_sources"]:
			source_calls[key] = int(source_calls.get(key, 0)) + 1
		_note_scope(key, started, caller)
	func _note_scope(label: String, started: int, caller: String = "") -> void:
		if observe:
			scopes.append({"label": label, "caller": caller, "elapsed_usec": Time.get_ticks_usec() - started})
	func _serialize_order_plans() -> Array:
		var started := Time.get_ticks_usec()
		var result: Array = super._serialize_order_plans()
		_note_source("plans", started, get_stack())
		return result
	func _build_fireteam_anchor_visualization_entries() -> Array:
		var started := Time.get_ticks_usec()
		var result: Array = super._build_fireteam_anchor_visualization_entries()
		_note_source("anchors", started, get_stack())
		return result
	func _serialize_area_orders() -> Array:
		var started := Time.get_ticks_usec()
		var result: Array = super._serialize_area_orders()
		_note_source("areas", started, get_stack())
		return result
	func _build_ad_hoc_visualization_entries() -> Array:
		var started := Time.get_ticks_usec()
		var result: Array = super._build_ad_hoc_visualization_entries()
		_note_source("ad_hoc", started, get_stack())
		return result
	func get_fireteam_security_snapshot() -> Array:
		var started := Time.get_ticks_usec()
		var result: Array = super.get_fireteam_security_snapshot()
		_note_source("security", started, get_stack())
		return result
	func get_fireteam_movement_snapshot() -> Array:
		var started := Time.get_ticks_usec()
		var result: Array = super.get_fireteam_movement_snapshot()
		_note_source("movement", started, get_stack())
		return result
	func _refresh_order_visuals() -> void:
		var started := Time.get_ticks_usec()
		super._refresh_order_visuals()
		_note_scope("order_visuals", started)
	func _refresh_order_command_feedback() -> void:
		var started := Time.get_ticks_usec()
		super._refresh_order_command_feedback()
		_note_scope("command_feedback", started)
	func _refresh_button_state() -> void:
		var started := Time.get_ticks_usec()
		super._refresh_button_state()
		if observe:
			var stack := get_stack()
			var caller: String = String(Dictionary(stack[1]).get("function", "")) if stack.size() > 1 else ""
			var go := get_node(COMMAND_GRID_PATH + "/GoCommandMatrixButton") as Button
			button_receipts.append({"caller": caller, "disabled": go.disabled, "selected": get_selected_fireteam_ids(), "plans": get_order_plans_snapshot(), "callbacks": go.pressed.get_connections()})
			_note_scope("buttons", started, caller)
	func _activate_next_waypoint_for_plan(plan, fireteam_id: String, waypoint_index: int) -> bool:
		var started := Time.get_ticks_usec()
		var result: bool = super._activate_next_waypoint_for_plan(plan, fireteam_id, waypoint_index)
		_note_scope("activate_waypoint", started)
		return result
	func _apply_fireteam_coordination_for_phase(phase_index: int) -> void:
		var started := Time.get_ticks_usec()
		super._apply_fireteam_coordination_for_phase(phase_index)
		_note_scope("coordination", started)
	func _build_go_result_decision_summary(issued: PackedStringArray, continued: PackedStringArray, active: PackedStringArray) -> String:
		var started := Time.get_ticks_usec()
		var result: String = super._build_go_result_decision_summary(issued, continued, active)
		_note_scope("go_summary", started)
		return result

var _passed := 0
var _failed := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1920, 1080)
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
	for _frame in range(16):
		await process_frame
	probe.set_process(false)
	probe.set_physics_process(false)
	var simulation := scene.get_node("SimulationRoot")
	var primary: Node = probe.call("_get_primary_3d_view")
	var legacy := scene.get_node_or_null("FireteamOrderVisualizer")
	var selected: PackedStringArray = probe.get_selected_fireteam_ids()
	_check(primary != null and legacy != null and not selected.is_empty(), "Authored mission exposes actual 3D/2D consumers and initialized selection")
	if primary == null or legacy == null or selected.is_empty():
		scene.queue_free()
		await process_frame
		_finish()
		return
	var fireteam_id: String = selected[0]
	probe.call("_set_selected_fireteams", PackedStringArray([fireteam_id]), false)
	var go := probe.get_node(probe.COMMAND_GRID_PATH + "/GoCommandMatrixButton") as Button
	var callbacks := go.pressed.get_connections()
	var publications: Array[Dictionary] = []
	probe.planning_state_changed.connect(func(state: Dictionary) -> void: publications.append(state.duplicate(true)))
	var marker := scene.get_node("TargetMarker") as Node2D
	var target := marker.global_position + Vector2(128.0, 0.0)
	var actor_before := _actor_state(probe)
	var tick_before: int = simulation.call("get_tick")
	_check(probe.issue_right_click_command_for_test(target, "move", false), "Real public Move creates a pending plan")
	_check(_has_waypoint(_plan(probe, fireteam_id), "move", "pending") and not publications.is_empty() and not go.disabled, "Move publishes the actual pending plan and immediate GO affordance")
	_check(_actor_state(probe) == actor_before and int(simulation.call("get_tick")) == tick_before, "Planning does not advance actors or simulation synchronously")
	_test_visual_projection(probe, simulation, primary, legacy, "first")
	_test_visual_projection(probe, simulation, primary, legacy, "repeat")
	_test_explicit_empty(probe, simulation, primary)
	var frame_before := Engine.get_process_frames()
	var publication_count := publications.size()
	var queue_count := Array(simulation.get("command_queue")).size()
	probe.reset_observations()
	probe.observe = true
	var go_started := Time.get_ticks_usec()
	var accepted := probe.execute_selected_fireteam_orders()
	var go_elapsed := Time.get_ticks_usec() - go_started
	probe.observe = false
	var go_receipts: Array[Dictionary] = []
	for receipt in probe.button_receipts:
		if String(receipt.caller) in ["execute_selected_fireteam_orders", "_refresh_order_command_feedback"]:
			go_receipts.append(receipt)
	_check(accepted, "Real public GO accepts the actual pending plan")
	_check(go_receipts.size() == 1, "Successful GO projects its final button state exactly once")
	_check(String(_plan(probe, fireteam_id).get("status", "")) == "active" and _has_waypoint(_plan(probe, fireteam_id), "move", "active"), "GO immediately activates the actual Move plan and waypoint")
	_check(Array(simulation.get("command_queue")).size() > queue_count and _has_queued_move(simulation, probe, fireteam_id), "GO enqueues real tokenized Move commands in SimulationRoot")
	_check(publications.size() == publication_count + 1 and Engine.get_process_frames() == frame_before, "GO publishes exactly one current planning snapshot in the same input frame")
	_check(not publications.is_empty() and _published_plan_matches(publications.back(), probe), "GO planning signal reads the committed owner plan")
	_check(_go_matches_owner(probe, go) and go.pressed.get_connections() == callbacks, "GO preserves final owner policy and original callback identity")
	_check(_actor_state(probe) == actor_before and int(simulation.call("get_tick")) == tick_before, "GO enqueues commands without patching or synchronously advancing actors")
	print("R4_COMMAND_GO_TRACE " + JSON.stringify({"elapsed_usec": go_elapsed, "scopes_nested_not_additive": probe.scopes, "source_calls": probe.source_calls, "source_calls_by_caller": probe.caller_calls, "button_receipts": go_receipts, "synthetic_component": true}))
	_check(probe.issue_right_click_command_for_test(target + Vector2(48.0, 0.0), "take", false), "Interleaved public Take replaces current planning")
	_check(_has_waypoint(_plan(probe, fireteam_id), "take", "pending"), "Interleaved source is a real new Take plan")
	_test_visual_projection(probe, simulation, primary, legacy, "interleaved_take")
	scene.queue_free()
	await process_frame
	await process_frame
	_finish()


func _test_visual_projection(probe: Node, simulation: Node, primary: Node, legacy: Node, label: String) -> void:
	var expected := _reference_sources(probe)
	var before := _owner_state(probe, simulation)
	probe.call("reset_observations")
	probe.set("observe", true)
	probe.call("_refresh_order_visuals")
	probe.set("observe", false)
	_check(_all_sources_once(Dictionary(probe.get("source_calls"))), "%s projection reads each source once within its local call" % label)
	_check(_payload_matches(Dictionary(primary.get("_order_payload")), expected), "%s actual 3D consumer receives fresh complete source payload" % label)
	_check(_legacy_matches(legacy, expected), "%s compatibility 2D consumer retains the same real preview and sources" % label)
	_check(_owner_state(probe, simulation) == before, "%s presentation leaves plan, queue, tick and actors unchanged" % label)
	print("R4_COMMAND_PROJECTION_TRACE " + JSON.stringify({"case": label, "source_calls": probe.get("source_calls"), "source_calls_by_caller": probe.get("caller_calls"), "scopes_nested_not_additive": probe.get("scopes")}))


func _test_explicit_empty(probe: Node, simulation: Node, primary: Node) -> void:
	var method := "_sync_primary_3d_order_visuals_from_sources"
	_check(probe.has_method(method), "Explicit source helper supports an empty payload independently of nonempty owner state")
	if not probe.has_method(method):
		return
	var empty: Dictionary = {}
	for key in SOURCE_KEYS:
		empty[key] = []
	var before := _owner_state(probe, simulation)
	probe.call("reset_observations")
	probe.set("observe", true)
	probe.call(method, empty)
	probe.set("observe", false)
	_check(_payload_matches(Dictionary(primary.get("_order_payload")), empty), "Explicit empty source arrays clear 3D fields without fallback to existing plans")
	_check(Dictionary(probe.get("source_calls")).is_empty(), "Explicit empty helper does not rebuild owner source arrays")
	_check(_owner_state(probe, simulation) == before, "Explicit empty presentation leaves actual nonempty owner state intact")
	var expected := _reference_sources(probe)
	probe.call("reset_observations")
	probe.set("observe", true)
	probe.call("_sync_primary_3d_order_visuals")
	probe.set("observe", false)
	_check(_all_sources_once(Dictionary(probe.get("source_calls"))) and _payload_matches(Dictionary(primary.get("_order_payload")), expected), "Standalone existing wrapper rebuilds fresh current sources once after explicit empty")


func _reference_sources(probe: Node) -> Dictionary:
	return {"fireteam_anchors": probe.call("_build_fireteam_anchor_visualization_entries"), "plan_dicts": probe.call("_serialize_order_plans"), "waypoint_intent_preview_entries": probe.call("_build_waypoint_intent_preview_entries"), "area_order_dicts": probe.call("_serialize_area_orders"), "ad_hoc_order_dicts": probe.call("_build_ad_hoc_visualization_entries"), "security_dicts": probe.call("get_fireteam_security_snapshot"), "movement_state_dicts": probe.call("get_fireteam_movement_snapshot")}


func _all_sources_once(counts: Dictionary) -> bool:
	for key in COUNT_KEYS:
		if int(counts.get(key, 0)) != 1:
			return false
	return true


func _payload_matches(actual: Dictionary, expected: Dictionary) -> bool:
	for key in SOURCE_KEYS:
		if not actual.has(key) or actual[key] != expected[key]:
			return false
	return true


func _legacy_matches(legacy: Node, expected: Dictionary) -> bool:
	for key in ["plan_dicts", "waypoint_intent_preview_entries", "area_order_dicts", "ad_hoc_order_dicts", "security_dicts", "movement_state_dicts"]:
		if legacy.get("_" + key) != expected[key]:
			return false
	var anchors: Dictionary = {}
	for entry in Array(expected.fireteam_anchors):
		anchors[String(entry.fireteam_id).strip_edges().to_lower()] = entry.position
	return Dictionary(legacy.get("_fireteam_anchor_positions")) == anchors


func _plan(probe: Node, id: String) -> Dictionary:
	for entry in Array(probe.call("get_order_plans_snapshot")):
		if String(Dictionary(entry).get("fireteam_id", "")) == id:
			return Dictionary(entry)
	return {}


func _has_waypoint(plan: Dictionary, command: String, status: String) -> bool:
	for entry in Array(plan.get("waypoints", [])):
		if String(Dictionary(entry).get("command_type", "")) == command and String(Dictionary(entry).get("status", "")) == status:
			return true
	return false


func _has_queued_move(simulation: Node, probe: Node, id: String) -> bool:
	var ids := PackedStringArray()
	for unit in Array(probe.call("_get_fireteam_units", id, true)):
		ids.append(String(unit.call("get_unit_id")))
	for entry in Array(simulation.get("command_queue")):
		var command := Dictionary(entry)
		if ids.has(String(command.get("unit_id", ""))) and String(command.get("command_type", "")) == "move_to_position" and String(command.get("source_command_type", "")) == "move" and not String(command.get("command_token", "")).is_empty():
			return true
	return false


func _published_plan_matches(state: Dictionary, probe: Node) -> bool:
	return state.get("order_plans", null) == probe.call("get_order_plans_snapshot")


func _go_matches_owner(probe: Node, go: Button) -> bool:
	return go.disabled == (bool(probe.get("preview_mode")) or not bool(probe.call("_can_issue_local_commands")) or not bool(probe.call("_has_selected_fireteam_orders_to_execute")))


func _actor_state(probe: Node) -> Dictionary:
	var actors: Dictionary = {}
	for id in probe.call("_get_displayable_fireteam_ids"):
		for unit in probe.call("_get_fireteam_units", String(id), true):
			actors[String(unit.get_path())] = {"position": unit.global_position, "health": unit.call("get_health") if unit.has_method("get_health") else null, "vital": unit.call("get_vital_state") if unit.has_method("get_vital_state") else ""}
	return actors


func _owner_state(probe: Node, simulation: Node) -> Dictionary:
	return {"commands": Array(simulation.get("command_queue")).duplicate(true), "effects": Array(simulation.get("effects_queue")).duplicate(true), "plans": probe.call("get_order_plans_snapshot"), "areas": probe.call("get_area_orders_snapshot"), "tick": simulation.call("get_tick"), "actors": _actor_state(probe)}


func _check(ok: bool, label: String) -> void:
	if ok:
		_passed += 1
		print("PASS: " + label)
	else:
		_failed += 1
		print("FAIL: " + label)


func _finish() -> void:
	print("R4_COMMAND_PROJECTION: %d passed, %d failed" % [_passed, _failed])
	if _failed == 0:
		print("R4_COMMAND_PROJECTION_PASS")
	quit(1 if _failed > 0 else 0)
