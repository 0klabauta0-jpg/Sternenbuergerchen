extends SceneTree
func _init() -> void: call_deferred("_run")
func _run() -> void:
	load("res://scripts/meta/game_start_contract.gd").request_start(self,"skirmish","new","early")
	var flow: Node=load("res://scenes/meta/meta_layer_test.tscn").instantiate();root.add_child(flow);await process_frame
	var screen: Node=flow.get_node("HomebaseScreen")
	screen.request_operation("navigate",{"mode":"base"})
	for i in 6: await process_frame
	var base: Node=screen.get("_operations_presenter").get("_base")
	var ships: Array=flow.get("_homebase_aircraft_definitions")
	base.select_world_craft(String(ships[0].craft_id))
	screen.request_operation("navigate",{"mode":"services"})
	flow.call("_refresh_singleplayer_services")
	var service: Node=screen.get("_operations_presenter").get("_services_view")
	var selector: OptionButton=service.get("_craft_selector")
	var target_index: int=-1
	for i in selector.item_count:
		if String(selector.get_item_metadata(i))==String(ships[1].craft_id): target_index=i
	if target_index<0: printerr("FAIL: second actual preset craft missing from service selector");quit(1);return
	selector.select(target_index);selector.item_selected.emit(target_index)
	flow.call("_refresh_singleplayer_services");flow.call("_refresh_singleplayer_services")
	var okay: bool=String(service.get("_selected_craft_id"))==String(ships[1].craft_id)
	print("SERVICE_WORLD_SELECTION failures=",0 if okay else 1)
	if not okay: printerr("FAIL: stale base world selection overwrote explicit service craft")
	flow.queue_free();await process_frame;quit(0 if okay else 1)
