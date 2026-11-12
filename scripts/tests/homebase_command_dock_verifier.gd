extends SceneTree
var passed := 0
var failed := 0
func _init() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failed += 1
	print(("PASS: " if value else "FAIL: ") + label)
func run() -> void:
	load("res://scripts/meta/game_start_contract.gd").request_start(self, "campaign", "new")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	await process_frame
	var screen: Control = flow.get_node("HomebaseScreen")
	var owner: Node = screen.call("get_base_personnel_runtime")
	screen.call("request_operation", "navigate", {"mode":"base"})
	await process_frame
	var base: Control = screen.get("_operations_presenter").get("_base")
	var dock: Control = base.find_child("BaseCommandDock", true, false)
	var buttons: Dictionary = base.get("_person_buttons")
	check(dock != null and dock.is_visible_in_tree(), "visible command dock in actual base")
	check(dock.find_child("SelectedPersonCard", true, false) != null, "selection card is part of dock")
	check(buttons.has("move") and buttons.has("base_board") and buttons.has("base_sleep") and buttons.has("equipment"), "actual base commands available")
	var pilot_card: Button = dock.find_child("SelectPerson_campaign_pilot", true, false)
	check(pilot_card != null, "another person has an individual selection card")
	if pilot_card != null: pilot_card.pressed.emit()
	check(base.get("_selected_person_id") == "campaign_pilot", "selection preserves canonical unit id")
	var actor: Node2D = owner.call("get_actor", "campaign_pilot")
	var terrain: Node = owner.call("get_terrain_registry")
	var start := actor.position
	var target: Vector2 = terrain.call("grid_to_world", terrain.call("world_to_grid", start) + Vector2i(1, 0))
	var host: Control = base.get("_host")
	var viewport: SubViewport = base.get("_viewport")
	var view: Node = base.get("_view")
	(buttons.move as Button).pressed.emit()
	check(base.get("_move_armed"), "move button requests target")
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = Vector2(view.call("world_to_screen_position", target)) * host.size / Vector2(viewport.size)
	base.call("_on_world_gui_input", event)
	check(not base.get("_move_armed"), "target click completes move selection")
	var sim: Node = owner.call("get_simulation_root")
	sim.set_physics_process(false)
	for index in 100: sim.call("_physics_process", 0.05)
	check(actor.position.distance_to(start) > 0.1, "move command reaches actual simulation owner")
	(buttons.move as Button).pressed.emit()
	base.call("set_active", false)
	check(not base.get("_move_armed"), "leaving base clears pending target selection")
	flow.queue_free()
	await process_frame
	print("HOMEBASE_COMMAND_DOCK: %d passed, %d failed" % [passed, failed])
	if failed == 0: print("HOMEBASE_COMMAND_DOCK_PASS")
	quit(0 if failed == 0 else 1)
