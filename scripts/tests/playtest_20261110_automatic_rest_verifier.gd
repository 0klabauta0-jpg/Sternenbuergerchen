extends SceneTree
var failed:=0
func _init() -> void: call_deferred("_run")
func check(ok: bool,label: String) -> void:
	if not ok: failed+=1
	print("PASS: " if ok else "FAIL: ",label)
func _run() -> void:
	load("res://scripts/meta/game_start_contract.gd").request_start(self,"campaign","new")
	var flow: Node=load("res://scenes/meta/meta_layer_test.tscn").instantiate(); root.add_child(flow)
	await process_frame
	var screen: Node=flow.get_node("HomebaseScreen")
	var runtime: Node=flow.get("_singleplayer_runtime")
	var people: Node=runtime.call("get_base_personnel_runtime")
	if not people.has_method("advance_automatic_rest"):
		check(false,"base owner provides automatic rest policy")
		flow.queue_free(); await process_frame; quit(1); return
	var before: Vector2=people.get_actor("campaign_leader").position
	people.advance_automatic_rest(21.0)
	var units: Array=people.get_snapshot().units
	check(units.size()==2 and units.all(func(person:Dictionary):return String(person.status)=="moving" and String(person.action.type)=="sleep"),"both idle actual people receive real bed walks")
	check(people.get_actor("campaign_leader").position==before,"automatic rest does not teleport")
	check(people.get_snapshot().bed_occupants.size()==2,"different beds reserved without double occupancy")
	var deadline:=Time.get_ticks_msec()+60000
	while Time.get_ticks_msec()<deadline and not people.get_snapshot().units.all(func(person:Dictionary):return person.status=="sleeping"):
		await process_frame
	check(people.get_snapshot().units.all(func(person:Dictionary):return person.status=="sleeping"),"both people physically reach beds and sleep")
	var actual_craft:=String(screen.call("get_operations_snapshot").selected_craft.id)
	# Seit 21.11.2026 (Auftrag P1) liegt keine leichte Ruestung im Startlager. Dieser Test prueft das Wecken durch eine
	# erfolgreiche Ausruestung, nicht die Startausruestung; er ruestet deshalb ueber die oeffentliche Operation eine Pistole aus.
	var outfit: Dictionary=screen.call("request_operation","inventory_equip",{"unit_id":"campaign_pilot","craft_id":actual_craft,"source_container_id":"base:homebase","item_id":"pistol","slot":"weapon_1"})
	check(outfit.get("ok",false) and people._states.campaign_pilot.status=="outside","successful finite equipment wakes sleeping person")
	people.request_operation("base_sleep",{"unit_id":"campaign_pilot"})
	deadline=Time.get_ticks_msec()+15000
	while Time.get_ticks_msec()<deadline and people._states.campaign_pilot.status!="sleeping": await process_frame
	var moved: Dictionary=screen.call("request_operation","base_move",{"unit_id":"campaign_pilot","target_position":before})
	check(moved.get("ok",false) and people._states.campaign_pilot.status=="moving","manual walk wakes sleeper through original command path")
	screen.call("request_operation","navigate",{"mode":"base"})
	await process_frame
	var presenter: Node=screen.get("_operations_presenter")
	var base_view: Node=presenter.get("_base")
	base_view.call("_select_person","campaign_leader")
	var toggle: CheckButton=base_view.get("_person_buttons").get("auto_rest")
	toggle.button_pressed=false
	check(not people._states.campaign_leader.auto_rest_enabled,"actual selected NPC checkbox disables automatic rest")
	screen.call("request_operation","focus_unit",{"unit_id":"campaign_leader"})
	presenter.call("refresh")
	var menu_toggle: CheckButton=presenter.get("_inventory_panel").get("_rest")
	check(not menu_toggle.button_pressed,"personal inventory reads same selected NPC setting")
	menu_toggle.button_pressed=true
	check(people._states.campaign_leader.auto_rest_enabled,"personal menu checkbox enables automatic rest")
	menu_toggle.button_pressed=false
	check(people._states.campaign_leader.status=="outside","disabling automatic sleep frees selected person")
	var standing: Vector2=people.get_actor("campaign_leader").position
	people.advance_automatic_rest(120.0)
	check(people._states.campaign_leader.status=="outside" and people.get_actor("campaign_leader").position==standing,"disabled person stays where player left them")
	var gear: Dictionary=screen.call("request_operation","loadout",{"unit_id":"campaign_leader","key":"weapon_1","value":"pistol"})
	check(gear.get("ok",false),"manual equipment remains usable")
	var saved: Dictionary=flow.get("_campaign_start").call("save_home_checkpoint",flow,runtime)
	check(saved.get("ok",false),"safe campaign save includes new personal setting")
	var checkpoint: Dictionary=load("res://scripts/meta/campaign_checkpoint_store.gd").load_checkpoint()
	check(checkpoint.get("ok",false) and checkpoint.payload.base_personnel.units.campaign_leader.auto_rest_enabled==false,"serialized checkbox survives checkpoint validation")
	flow.queue_free(); await process_frame
	load("res://scripts/meta/game_start_contract.gd").request_start(self,"campaign","continue")
	var resumed: Node=load("res://scenes/meta/meta_layer_test.tscn").instantiate(); root.add_child(resumed); await process_frame
	var restored: Node=resumed.get("_singleplayer_runtime").call("get_base_personnel_runtime")
	check(restored._states.campaign_leader.auto_rest_enabled==false,"actual Continue restores personal auto-rest switch")
	var resumed_screen: Node=resumed.get_node("HomebaseScreen")
	for id in ["campaign_leader","campaign_pilot"]: restored.request_operation("base_sleep",{"unit_id":id})
	deadline=Time.get_ticks_msec()+60000
	while Time.get_ticks_msec()<deadline and not restored.get_snapshot().units.all(func(person:Dictionary):return person.status=="sleeping"): await process_frame
	check(restored.get_snapshot().units.all(func(person:Dictionary):return person.status=="sleeping"),"both people can sleep explicitly with automation disabled")
	var ship:=String(resumed_screen.call("get_operations_snapshot").selected_craft.id)
	var boarded: Dictionary=resumed_screen.call("request_operation","base_board",{"craft_id":ship,"fireteam_id":"ft1","whole_fireteam":true})
	check(boarded.get("ok",false) and restored.get_snapshot().bed_occupants.is_empty(),"boarding wakes both sleepers and releases their actual beds")
	deadline=Time.get_ticks_msec()+60000
	while Time.get_ticks_msec()<deadline and not restored.get_snapshot().units.all(func(person:Dictionary):return person.status=="aboard"): await process_frame
	check(restored.get_snapshot().units.all(func(person:Dictionary):return person.status=="aboard"),"both sleepers physically walk and commit boarding")
	check(restored.is_pilot_aboard(ship) and resumed_screen.call("_has_homebase_direct_launch_payload_for_craft",ship),"sleeping crew reaches existing flight-ready transport payload")
	resumed.queue_free(); await process_frame
	print("AUTOMATIC_REST failed=",failed); quit(1 if failed else 0)
