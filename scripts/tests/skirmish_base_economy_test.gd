extends SceneTree

const START = preload("res://scripts/meta/game_start_contract.gd")
var _checks := 0
var _failed := 0
var _screen: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var draft := {"budget": 1500, "base_setup": true, "people": [], "ships": []}
	_check(START.request_start(self, "skirmish", "new", "", draft).ok, "Empty paid base accepted")
	var menu: Control = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	menu.get("_singleplayer_button").pressed.emit()
	_check(menu.find_child("SkirmishPointsStart", true, false).is_visible_in_tree(), "Normal Skirmish menu exposes points start")
	menu.find_child("SkirmishPointsStart", true, false).pressed.emit()
	var dialog: AcceptDialog = menu.get("_skirmish_points_dialog")
	_check(dialog.find_child("StartBudget1500", true, false).is_visible_in_tree(), "Budget is selectable in visible dialog")
	dialog.find_child("StartBudget1500", true, false).pressed.emit()
	for index in range(300):
		await process_frame
		if current_scene != null and not is_instance_valid(menu): break
	var flow: Node = current_scene
	_check(flow != null and flow.has_node("HomebaseScreen"), "Normal menu button enters actual base scene")
	if flow == null or not flow.has_node("HomebaseScreen"):
		quit(1)
		return
	_screen = flow.get_node("HomebaseScreen")
	await process_frame
	var snapshot := _snapshot()
	_check(flow.get("_all_team_units").is_empty() and flow.get("_homebase_aircraft_definitions").is_empty(), "No free roster or craft bootstrap")
	_check(snapshot.skirmish_economy.remaining == 1500, "Initial wallet intact")
	_check(snapshot.base_personnel.layout.beds.is_empty() and snapshot.base_personnel.layout.landing_pads.is_empty(), "Infrastructure begins empty")
	_check(snapshot.supply.inventory["base:homebase"].items.is_empty(), "No free supply stock")
	_check(_screen.get_operations_snapshot().mode == "base", "Normal entry shows walkable base")
	var base: Control = _screen.get("_operations_presenter").get("_base")
	var base_state: Dictionary = base.get_exploration_snapshot()
	_check(base_state.registered_unit_count == 0 and not base_state.ephemeral_commander, "Empty view has camera anchor and no free actor")
	var personnel: Node = _screen.get_base_personnel_runtime()
	_check(not personnel.get_simulation_root().request_skirmish_command({"operation": "build", "request_id": "bad-payload", "payload": []}).ok, "Malformed command rejected without runtime mutation")
	var blockers: Array = personnel.get("_building_blockers").habitat
	var blocker = blockers[0].tile
	_check(blocker.walkable and not blocker.blocks_los, "Unbuilt site has open navigation and sight")
	await _capture("empty")
	_check(not _op("ship", {"item_id": "cutlass"}).ok, "Ship requires a real pad")
	_check(_snapshot().skirmish_economy.remaining == 1500, "Failed buy does not debit")
	var pad_request := {"item_id": "pad", "request_id": "test:pad"}
	_check(_op("build", pad_request).ok, "Build actual landing pad")
	_check(_op("build", pad_request).get("replayed", false), "Repeated command returns receipt")
	_check(_snapshot().skirmish_economy.remaining == 1350 and _snapshot().base_personnel.layout.landing_pads.size() == 1, "Exactly one pad and one debit")
	_check(not _op("build", {"item_id": "habitat", "request_id": "test:pad"}).ok, "Conflicting retry rejected")
	_check(_op("build", {"item_id": "habitat"}).ok, "Build habitat")
	_check(not blocker.walkable and blocker.blocks_los == bool(blockers[0].blocks_los), "Building restores authored collision and sight")
	_check(_op("build", {"item_id": "workshop"}).ok, "Build workshop")
	_check(not _op("build", {"item_id": "habitat"}).ok, "Second habitat cannot double charge")
	_check(_snapshot().base_personnel.layout.beds.size() == 2, "Habitat includes two usable beds")
	var ship := _op("ship", {"item_id": "cutlass"})
	_check(ship.ok and _snapshot().crafts.size() == 1, "Purchase actual craft")
	_check(not _op("ship", {"item_id": "buccaneer"}).ok, "Occupied pad cannot host another ship")
	var preview: Dictionary = _snapshot().skirmish_economy.recruits[0].profile
	var operator := {"role": "operator", "experience": "junior", "armor": "light", "weapon": "rifle", "candidate_index": 0, "request_id": "test:person"}
	var recruit := _op("person", operator)
	_check(recruit.ok and _snapshot().base_personnel.units.size() == 1, "Recruit actual base person")
	var unit_id := String(recruit.get("unit_id", ""))
	var unit: Dictionary = flow.get("_all_team_units")[0]
	_check(unit.display_name == preview.display_name and unit.portrait_id == preview.portrait_id, "Purchased identity matches visible offer")
	_check(_op("person", operator).get("replayed", false) and _snapshot().base_personnel.units.size() == 1, "Recruitment retry cannot duplicate actor")
	var pilot := _op("person", {"role": "pilot", "experience": "junior", "armor": "light", "weapon": "pistol", "candidate_index": 2})
	_check(pilot.ok and _snapshot().base_personnel.units.size() == 2, "Recruit pilot")
	_check(_snapshot().skirmish_economy.remaining == 505, "Full base, ship and packages share budget")
	_check(int(_snapshot().supply.inventory["unit:" + unit_id + ":backpack"].capacity) == 0, "Suit slot does not grant free backpack")
	_check(_op("equipment", {"item_id": "armor_heavy"}).ok, "Buy stock through point wallet")
	var equipped: Dictionary = _screen.request_operation("inventory_equip", {"unit_id": unit_id, "source_container_id": "base:homebase", "slot": "armor", "item_id": "armor_heavy"})
	_check(equipped.ok, "Normal equipment transaction consumes purchased stock")
	_check(_snapshot().supply.inventory["base:homebase"].items.get("armor_heavy", 0) == 0, "Equipped item is not duplicate stock")
	_screen.request_operation("assign", {"unit_id": unit_id, "fireteam_id": "ft1"})
	await _capture("built")
	var dismissed := _op("dismiss", {"unit_id": unit_id, "request_id": "test:dismiss"})
	_check(dismissed.ok and _snapshot().base_personnel.units.size() == 1, "Dismiss removes physical actor")
	_check(_snapshot().skirmish_economy.remaining == 530, "Dismiss refunds personnel without refunding gear twice")
	_check(_snapshot().supply.inventory["base:homebase"].items.get("armor_heavy", 0) == 1, "Dismiss returns currently worn armor")
	_check(not _snapshot().supply.inventory.has("unit:" + unit_id + ":backpack"), "Dismiss removes personal container")
	_check(_op("dismiss", {"unit_id": unit_id, "request_id": "test:dismiss"}).get("replayed", false) and _snapshot().skirmish_economy.remaining == 530, "Dismiss retry cannot repeat refund")
	_check(personnel.get_actor(unit_id) == null and not personnel.get_simulation_root().get_personnel_loadout_state().has_unit(unit_id), "Registry and equipment release dismissed person")
	_check(not Array(_screen.call("_get_member_unit_ids_for_fireteam", "ft1")).has(unit_id), "Dismiss clears fireteam membership")
	_check(_op("dismiss", {"unit_id": pilot.unit_id}).ok, "Dismiss final person")
	await process_frame
	_check(base.get_exploration_snapshot().registered_unit_count == 0, "Returning to empty base releases every actor")
	await _capture("dismissed")
	var shop: Control = _screen.get("_operations_presenter").get("_skirmish_shop")
	shop.refresh()
	shop.get("_buy_person").pressed.emit()
	_check(flow.get("_all_team_units").size() == 1, "Actual recruit button buys a person")
	shop.get("_crew").select(0)
	shop.call("_update_actions")
	shop.get("_equip").pressed.emit()
	_check(_screen.get_operations_snapshot().mode == "squad", "Actual equipment button opens shared equipment view")
	await _capture("equipment")
	_screen.request_operation("navigate", {"mode": "base"})
	var returned_ship := _op("return_ship", {"craft_id": ship.craft_id, "request_id": "test:return-ship"})
	_check(returned_ship.ok and _snapshot().crafts.is_empty(), "Empty landed ship can be returned")
	_check(not _snapshot().space_travel.routes.has(ship.craft_id) and not _snapshot().supply.inventory.has("craft:" + String(ship.craft_id)), "Return removes travel and supply owners")
	var remaining: int = _snapshot().skirmish_economy.remaining
	_check(_op("return_ship", {"craft_id": ship.craft_id, "request_id": "test:return-ship"}).get("replayed", false) and _snapshot().skirmish_economy.remaining == remaining, "Ship refund is idempotent")
	var medic := _op("person", {"role": "medic", "experience": "junior", "armor": "light", "weapon": "pistol", "candidate_index": 1})
	_check(medic.ok and _snapshot().skirmish_economy.remaining == remaining - 125, "Medic package includes medical equipment price")
	_check(_op("dismiss", {"unit_id": medic.unit_id}).ok and _snapshot().skirmish_economy.remaining == remaining - 35, "Medic refund retains the full cost of returned equipment")
	flow.queue_free()
	await process_frame
	print("SKIRMISH_BASE_ECONOMY %d checks, %d failures" % [_checks, _failed])
	quit(0 if _failed == 0 else 1)


func _snapshot() -> Dictionary:
	return _screen.get_operations_snapshot().singleplayer


func _op(operation: String, payload: Dictionary) -> Dictionary:
	return _screen.request_operation("skirmish_" + operation, payload)


func _capture(suffix: String) -> void:
	if DisplayServer.get_name() == "headless": return
	for size: Vector2i in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		root.size = size
		for index in range(8): await process_frame
		var presenter: Control = _screen.get("_operations_presenter")
		var shop: Control = presenter.get("_skirmish_shop")
		if shop.visible:
			var base: Control = presenter.get("_base")
			_check(shop.get_global_rect().end.x + 1 <= base.get_global_rect().position.x, "Shop and base controls remain disjoint at %d" % size.x)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://output/native_glut_maps/points_base_%s_%d.png" % [suffix, size.x])


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed += 1
		push_error(message)
