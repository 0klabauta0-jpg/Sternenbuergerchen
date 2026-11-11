extends SceneTree

var _checks := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var start = load("res://scripts/meta/game_start_contract.gd")
	start.request_start(self, "skirmish", "new", "", {"budget": 1000, "base_setup": true, "people": [], "ships": []})
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	await process_frame
	var screen: Control = flow.get_node("HomebaseScreen")
	for item: String in ["habitat", "workshop", "pad"]:
		_check(screen.request_operation("skirmish_build", {"item_id": item}).ok, "Buy " + item)
	var ship: Dictionary = screen.request_operation("skirmish_ship", {"item_id": "cutlass"})
	var operator: Dictionary = screen.request_operation("skirmish_person", {"role": "operator", "experience": "junior", "armor": "light", "weapon": "rifle", "candidate_index": 0})
	var pilot: Dictionary = screen.request_operation("skirmish_person", {"role": "pilot", "experience": "junior", "armor": "light", "weapon": "pistol", "candidate_index": 2})
	_check(ship.ok and operator.ok and pilot.ok, "1000 point setup purchased")
	if not ship.ok or not operator.ok or not pilot.ok:
		quit(1)
		return
	var craft_id := String(ship.craft_id)
	var unit_id := String(operator.unit_id)
	_check(screen.get_operations_snapshot().singleplayer.skirmish_economy.remaining == 5, "Full starter deck costs 995")
	_check(not screen.request_operation("skirmish_equipment", {"item_id": "rifle"}).ok, "Excess purchase rejected")
	_check(screen.request_operation("assign", {"unit_id": unit_id, "fireteam_id": "ft1"}).ok, "Assign bought operator to real fireteam")
	_check(screen.request_operation("pilot", {"unit_id": pilot.unit_id, "craft_id": craft_id}).ok, "Assign bought pilot")
	_check(screen.request_operation("board", {"fireteam_id": "ft1", "craft_id": craft_id}).ok, "Board actual fireteam")
	_check(screen.request_operation("base_board", {"unit_id": pilot.unit_id, "craft_id": craft_id}).ok, "Pilot walks to actual ship")
	var runtime: Node = flow.get("_singleplayer_runtime")
	var ready := false
	var deadline := Time.get_ticks_msec() + 60000
	while Time.get_ticks_msec() < deadline:
		if bool(runtime.validate_space_launch(craft_id, false).get("ok", false)):
			ready = true
			break
		await create_timer(0.1).timeout
	_check(ready, "Purchased crew physically reaches ship and completes boarding")
	if not ready:
		print(runtime.validate_space_launch(craft_id, false))
		print(screen.get_base_personnel_runtime().get_snapshot().units)
	else:
		_check(screen.request_operation("space_prepare_launch", {"craft_id": craft_id}).ok, "Prepare launch through normal command")
		_check(screen.request_operation("start", {"craft_id": craft_id}).ok, "Normal launch button accepts purchased deck")
		deadline = Time.get_ticks_msec() + 15000
		while Time.get_ticks_msec() < deadline and String(runtime.get_space_travel_snapshot(craft_id).phase) != "orbit":
			await create_timer(0.1).timeout
		_check(String(runtime.get_space_travel_snapshot(craft_id).phase) == "orbit", "Purchased ship reaches moon orbit")
	flow.queue_free()
	await process_frame
	print("SKIRMISH_POINTS_LAUNCH %d checks, %d failures" % [_checks, _failed])
	quit(0 if _failed == 0 else 1)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed += 1
		push_error(message)
