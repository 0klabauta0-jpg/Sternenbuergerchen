extends SceneTree
## Exercises real Controls/commands in a private headless scene; no desktop input.
var failed: int = 0
var passed: int = 0

func _init() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		printerr("FAIL: ", label)

func _run() -> void:
	load("res://scripts/meta/game_start_contract.gd").request_start(self, "campaign", "new")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	await process_frame
	var screen: Control = flow.get_node("HomebaseScreen")
	var owner: Node = screen.call("get_base_personnel_runtime")
	screen.call("request_operation", "navigate", {"mode": "base"})
	await process_frame
	var base: Control = screen.get("_operations_presenter").get("_base")
	var state: Dictionary = base.call("get_exploration_snapshot")
	_check(not bool(state.ephemeral_commander) and state.registered_unit_count == 2, "World displays real two-person registry without extra commander")
	var models: Dictionary = base.get("_person_visuals")
	_check(models.has("campaign_leader") and models.has("campaign_pilot"), "Both selectable visuals carry canonical roster IDs")
	var pilot_card: Button = base.find_child("SelectPerson_campaign_pilot", true, false)
	_check(pilot_card != null and pilot_card.is_visible_in_tree(), "Other-person card includes actual pilot")
	if pilot_card != null:
		pilot_card.pressed.emit()
	_check(String(base.get("_selected_person_id")) == "campaign_pilot", "World selection targets pilot identity")
	var buttons: Dictionary = base.get("_person_buttons")
	(buttons.equipment as Button).pressed.emit()
	var operations: Dictionary = screen.call("get_operations_snapshot")
	_check(operations.mode == "personnel" and operations.focused_unit.id == "campaign_pilot", "World equipment button opens existing view focused on same pilot")
	var equipment: Dictionary = screen.call("request_operation", "loadout", {"unit_id":"campaign_pilot", "key":"weapon_1", "value":"smg"})
	if not bool(equipment.get("ok", false)):
		print("EQUIPMENT_REJECTION: ", equipment)
	_check(bool(equipment.get("ok", false)) and String(screen.call("_get_member_loadout", "campaign_pilot").weapon_1) == "smg", "Outside pilot equipment mutates existing loadout owner")
	screen.call("request_operation", "navigate", {"mode":"base"})
	base.call("_select_person", "campaign_leader")
	var actor: Node2D = owner.call("get_actor", "campaign_leader")
	var terrain: Node = owner.call("get_terrain_registry")
	var start: Vector2 = actor.position
	var grid: Vector2i = terrain.call("world_to_grid", start)
	var target: Vector2 = terrain.call("grid_to_world", grid + Vector2i(1, 0))
	_check(bool(base.call("request_walk_to", target)), "World right-click API sends real movement command")
	screen.call("request_operation", "navigate", {"mode":"personnel"})
	var simulation: Node = owner.call("get_simulation_root")
	simulation.set_physics_process(false)
	for index in 100:
		simulation.call("_physics_process", 0.05)
	_check(actor.position.distance_to(start) > 0.1, "Changing UI views does not stop commanded person movement")
	_check(owner.call("get_unit_registry").call("get_unit", "homebase_commander_avatar") == null, "No hidden commander registered after view changes")
	flow.queue_free()
	await process_frame
	print("BASE_PERSONNEL_WORLD_UI passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)
