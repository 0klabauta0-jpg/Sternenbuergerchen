extends SceneTree
const START = preload("res://scripts/meta/game_start_contract.gd")
var passed := 0
var failed := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failed += 1
	print(("PASS " if value else "FAIL ") + label)
func frames(count: int) -> void:
	for index in count: await process_frame
func run() -> void:
	if OS.get_environment("SB_REVIEW2_USER_DIR").is_empty(): quit(2); return
	START.request_start(self, "campaign", "new")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	current_scene = flow
	await frames(24)
	var runtime: Node = flow.get("_singleplayer_runtime")
	var owner: Node = runtime.call("get_base_personnel_runtime")
	var full: Dictionary = owner.call("get_snapshot")
	var projection: Array = owner.call("get_visual_personnel_states")
	check(projection.size() == full.units.size() and projection.size() >= 2, "actual campaign roster projection complete")
	for index in projection.size():
		var row: Dictionary = projection[index]
		check(row.size() == 4 and not row.has("action") and not row.has("last_result") and not row.has("world_position"), "pose read excludes histories and duplicated positions")
		for key in ["unit_id", "name", "status", "bed_id"]:
			check(row[key] == full.units[index][key], "actual owner field " + key)
	var first_id := String(projection[0].unit_id)
	projection[0].name = "local read-model mutation"
	check(owner.call("get_snapshot").units[0].name == full.units[0].name, "projection cannot mutate canonical personnel")
	var full_started := Time.get_ticks_usec()
	for index in 1000: owner.call("get_snapshot")
	var full_usec := Time.get_ticks_usec() - full_started
	var narrow_started := Time.get_ticks_usec()
	for index in 1000: owner.call("get_visual_personnel_states")
	var narrow_usec := Time.get_ticks_usec() - narrow_started
	print("BASE_READ_SAMPLE ", JSON.stringify({"reads": 1000, "people": projection.size(), "full_usec": full_usec, "narrow_usec": narrow_usec, "full_json_bytes": JSON.stringify(full).length(), "narrow_json_bytes": JSON.stringify(owner.call("get_visual_personnel_states")).length(), "not_a_frame_rate_gate": true}))
	var screen: Node = flow.get_node("HomebaseScreen")
	var presenter: Node = screen.get("_operations_presenter")
	presenter.call("_act", "navigate", {"mode": "base"})
	await frames(8)
	var base: Node = presenter.get("_base")
	var view: Node = base.get("_view")
	var actor: Node2D = owner.call("get_actor", first_id)
	var simulation: Node = owner.call("get_simulation_root")
	simulation.set_physics_process(false)
	base.set_process(false)
	base.set("_manual_camera", true)
	var original_position := actor.position
	# Private pose fixture verifies that narrowing state does not throttle or
	# cache authoritative actor positions. No user input or profile is touched.
	actor.position += Vector2(16, 8)
	base.call("_update_personnel_visuals")
	var model: Node3D = base.get("_person_visuals")[first_id].model
	var expected: Vector3 = view.call("_world_to_3d_position", actor.position, 0.0)
	check(is_equal_approx(model.position.x, expected.x) and is_equal_approx(model.position.z, expected.z), "same visual update reads current actor position without lag")
	actor.position = original_position
	var state: Dictionary = owner.get("_states")[first_id]
	var status := String(state.status)
	state.status = "aboard"
	base.call("_update_personnel_visuals")
	check(not model.visible, "aboard lifecycle hides model immediately")
	state.status = status
	base.call("_update_personnel_visuals")
	check(model.visible, "returning lifecycle restores model immediately")
	check(not String(model.get_meta("portrait_appearance", "")).is_empty(), "actual base profile supplies portrait appearance")
	flow.queue_free()
	current_scene = null
	await frames(8)
	print("REVIEW_BASE_VISUAL_PROJECTION passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)
