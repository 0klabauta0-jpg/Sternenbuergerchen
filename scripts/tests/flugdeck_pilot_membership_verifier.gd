extends SceneTree
var checks:=0
var failures:=0
func _init() -> void: call_deferred("_run")
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures+=1; printerr("FAIL: ",label)
	else: print("PASS: ",label)
func _run() -> void:
	root.size=Vector2i(1920,1080)
	load("res://scripts/meta/game_start_contract.gd").request_start(self,"campaign","new")
	var flow: Node=load("res://scenes/meta/meta_layer_test.tscn").instantiate();root.add_child(flow);await process_frame
	var screen: Node=flow.get_node("HomebaseScreen")
	var snapshot: Dictionary=screen.get_operations_snapshot()
	var craft: String=String(snapshot.selected_craft.id)
	var pilot: String=String(snapshot.selected_craft.pilot_id)
	var team: String=String(snapshot.fireteams[0].id)
	var runtime: Node=flow.get("_singleplayer_runtime").get_base_personnel_runtime()
	var sim: Node=runtime.get_simulation_root();sim.set_physics_process(false)
	# Actual arrival and boarding, without altering roster/presence fixtures.
	var result: Dictionary=screen.request_operation("board",{"craft_id":craft,"fireteam_id":team})
	check(result.get("ok",false),"real initial team and pilot boarding accepted")
	await advance_until(runtime,sim,pilot,"aboard")
	check(runtime.is_pilot_aboard(craft),"pilot really reaches ship")
	snapshot=screen.get_operations_snapshot()
	check(bool(snapshot.selected_craft.pilot_aboard),"flightdeck snapshot exposes actual pilot aboard")
	screen.request_operation("navigate",{"mode":"mission"})
	screen.get("_operations_presenter").refresh()
	check(screen.get("_operations_presenter").get("_pilot_status").text=="An Bord","pilot selector visibly confirms An Bord")
	var row: Dictionary={}
	for person: Dictionary in snapshot.roster:
		if String(person.id)==pilot: row=person
	check(String(row.status).contains("An Bord"),"pilot card says An Bord")
	result=runtime.request_operation("base_unboard",{"unit_id":pilot,"craft_id":craft})
	check(result.get("ok",false),"pilot can leave real ship")
	check(not runtime.is_pilot_aboard(craft),"pilot no longer aboard")
	var other: String=String(snapshot.focused_fireteam.members[0].id)
	check(runtime.get_snapshot().units.any(func(p:Dictionary):return String(p.unit_id)==other and String(p.status)=="aboard"),"Anja stays aboard")
	result=screen.request_operation("assign",{"unit_id":pilot,"fireteam_id":team})
	print("ASSIGN_RESULT ",result)
	check(result.get("ok",false),"outside assigned pilot may join already boarded same-craft FT1")
	check(String(screen.call("_get_fireteam_id_for_unit",pilot))==team,"pilot is a real FT1 member")
	check(String(screen.call("_get_assigned_pilot_id",craft))==pilot,"FT1 membership retains pilot assignment")
	flow.call("_refresh_homebase_screen")
	check(String(screen.call("_get_fireteam_id_for_unit",pilot))==team,"owner refresh retains dual role")
	check(not bool(screen.get_operations_snapshot().selected_craft.can_start),"outside pilot keeps launch blocked")
	result=screen.request_operation("board",{"craft_id":craft,"fireteam_id":team})
	check(result.get("ok",false),"remaining pilot can board without unloading Anja")
	await advance_until(runtime,sim,pilot,"aboard")
	check(runtime.is_pilot_aboard(craft),"dual-role pilot really boards")
	check(String(screen.call("_get_fireteam_id_for_unit",pilot))==team,"pilot remains FT1 after boarding")
	var ids: PackedStringArray=screen.call("_get_member_unit_ids_for_fireteam",team)
	check(ids.count(pilot)==1,"pilot exists once in actual team")
	check(bool(screen.get_operations_snapshot().selected_craft.can_start),"same-craft dual-role crew can launch after real boarding")
	result=runtime.request_operation("base_unboard",{"unit_id":pilot,"craft_id":craft})
	check(result.get("ok",false) and not runtime.is_pilot_aboard(craft),"dual-role pilot exits without dissolving FT1 payload")
	check(runtime.get_snapshot().units.any(func(p:Dictionary):return String(p.unit_id)==other and String(p.status)=="aboard"),"Anja stays aboard when FT1 pilot alone exits")
	check(String(screen.call("_get_fireteam_id_for_unit",pilot))==team,"individual pilot exit preserves FT1 membership")
	var save: Dictionary=flow.get("_campaign_start").save_home_checkpoint(flow,flow.get("_singleplayer_runtime"))
	check(save.get("ok",false),"dual-role grounded crew supports real checkpoint")
	flow.queue_free();await process_frame
	load("res://scripts/meta/game_start_contract.gd").request_start(self,"campaign","continue")
	flow=load("res://scenes/meta/meta_layer_test.tscn").instantiate();root.add_child(flow);await process_frame
	screen=flow.get_node("HomebaseScreen")
	check(String(screen.call("_get_fireteam_id_for_unit",pilot))==team and String(screen.call("_get_assigned_pilot_id",craft))==pilot,"Continue retains membership plus pilot function")
	runtime=flow.get("_singleplayer_runtime").get_base_personnel_runtime();sim=runtime.get_simulation_root();sim.set_physics_process(false)
	result=screen.request_operation("pilot",{"unit_id":other,"craft_id":craft})
	check(result.get("ok",false) and String(screen.call("_get_fireteam_id_for_unit",other))==team,"aboard Anja may take pilot role while retaining FT1")
	check(not bool(screen.get_operations_snapshot().selected_craft.can_start),"new aboard pilot cannot conceal an outside FT1 member")
	var gate:Dictionary=flow.get("_singleplayer_runtime").validate_space_launch(craft,false)
	check(not gate.get("ok",false) and String(gate.get("reason",""))=="crew_not_aboard","authoritative launch rejects outside former pilot after role swap")
	result=screen.request_operation("board",{"craft_id":craft,"fireteam_id":team})
	check(result.get("ok",false),"former pilot can reboard as FT1 passenger")
	await advance_until(runtime,sim,pilot,"aboard")
	check(runtime.get_payload_presence(craft).aboard_count==2 and bool(screen.get_operations_snapshot().selected_craft.can_start),"both unique physical FT1 members agree with ready launch after role swap")
	flow.queue_free();await process_frame
	print("FLUGDECK_PILOT checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)
func advance_until(runtime: Node, sim: Node, id: String, status: String) -> void:
	for i in range(6000):
		sim.call("_physics_process",0.05)
		runtime.get("_screen").call("_debug_advance_homebase_direct_boarding",0.05)
		if runtime.get_snapshot().units.any(func(p:Dictionary):return String(p.unit_id)==id and String(p.status)==status):return
		if i%100==0:await process_frame
	check(false,"person reaches "+status)
