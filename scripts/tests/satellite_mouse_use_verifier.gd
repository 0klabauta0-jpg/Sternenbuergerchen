extends SceneTree
var checks:=0
var failures:=0
func _init() -> void: call_deferred("_run")
func check(ok: bool,label:String) -> void:
	checks+=1
	if not ok: failures+=1;printerr("FAIL: ",label)
	else: print("PASS: ",label)
func _run() -> void:
	root.size=Vector2i(1920,1080)
	var contract=load("res://scripts/mission/world_context_action_contract.gd")
	check(contract.interaction_label({"interaction_id":"satellite_data"})=="Daten sichern","satellite semantic action")
	check(contract.interaction_label({"interaction_id":"recover_crate"})=="Einsammeln","loot/crate semantic action")
	check(contract.choose(Vector2.ZERO,[{"id":"b","screen_position":Vector2(1,0)},{"id":"a","screen_position":Vector2(-1,0)}]).id=="a","overlapping targets resolve deterministically")
	check(contract.choose(Vector2.ZERO,[{"id":"far","screen_position":Vector2(300,0)}]).is_empty(),"far geometry is not clickable")
	var mission: Node=load("res://scenes/tests/mission_reactivity_test.tscn").instantiate()
	var setup: Node=mission.get_node("MissionSetup")
	setup.set("map_file_path","res://maps/satellite_crash_site.json");setup.set("scenario_file_path","res://data/mission_scenarios/satellite_recovery.json")
	setup.set("defer_friendly_runtime_activation",false)
	setup.set("selected_team_unit_ids",PackedStringArray(["unit_alpha","unit_bravo","unit_charlie"]))
	setup.set("selected_team_fireteam_ids",PackedStringArray(["ft1","ft1","ft1"]))
	root.add_child(mission);await process_frame;await physics_frame
	var controller: Node=mission.get_node("TacticalController")
	var cursor: Node=controller.get_node("MissionContextCursor")
	var view: Node=mission.get_node("Primary3DView")
	var map=load("res://scripts/terrain/terrain_map_data.gd").load_from_file("res://maps/satellite_crash_site.json")
	var target: Vector2=map.get_marker_position("satellite_data")
	controller.call("_set_selected_fireteams",PackedStringArray(["ft1"]),false)
	var terrain:Node=mission.get_node("TerrainRegistry")
	var requested:Vector2=target+Vector2(180,0) if OS.get_environment("SATELLITE_APPROACH_TEST")=="1" else terrain.grid_to_world(terrain.world_to_grid(target)+Vector2i(1,0))
	var resolved:Dictionary=terrain.resolve_walkable_target(requested)
	print("SATELLITE_NEIGHBOR ",resolved," distance=",Vector2(resolved.replacement_position).distance_to(target))
	var i:=0
	for unit: Node2D in controller.call("_get_fireteam_units","ft1",true): unit.position=Vector2(resolved.replacement_position)+Vector2(i*4,0);i+=1
	view.focus_world_position(target)
	var pointer:Vector2=view.world_to_screen_position(target)
	var driver:Node=mission.get_node("CombatLoopDriver")
	var before: Dictionary=driver.get_mission_scenario_runtime_gate_snapshot()
	var hover:Dictionary=cursor.refresh_at(pointer)
	if hover.is_empty(): print("CONTEXT_DEBUG ",pointer," edit=",controller.call("_can_edit_planning")," ui=",controller.call("_is_pointer_over_control",pointer)," selection=",controller.get("_selected_fireteam_ids")," snapshot=",controller.call("get_mission_interaction_runtime_use_state_snapshot"))
	check(hover.get("id","")=="satellite_data","actual projected satellite hover identifies correct target")
	check(hover.get("label","")=="Daten sichern","actual cursor advertises the real data action")
	check(driver.get_mission_scenario_runtime_gate_snapshot()==before,"hover never completes objective or submits gameplay")
	var motion:=InputEventMouseMotion.new();motion.position=pointer;root.push_input(motion,true);await process_frame
	for pressed in [true,false]:
		var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_RIGHT;click.pressed=pressed;click.position=pointer;root.push_input(click,true)
		await process_frame
	var use:Dictionary=controller.get("_last_mission_interaction_use_intent_snapshot")
	print("MOUSE_USE ",use)
	var result:Dictionary={"handled":true,"ok":use.get("accepted",false)}
	check(result.get("handled",false) and result.get("ok",false),"context rightclick queues existing actual Use intent")
	check(driver.get_mission_scenario_runtime_gate_snapshot()==before,"queued Use still requires GO and real duration")
	cursor.update_objective_feedback()
	check(cursor.get("_objective_text").text.contains("GO"),"visible panel confirms prepared data action")
	check(bool(controller.call("execute_selected_fireteam_orders")),"real GO accepts actual mouse Use")
	var completed:=false
	for tick in range(1200):
		await physics_frame
		completed=Array(driver.get_mission_scenario_runtime_gate_snapshot().get("completed_step_ids",[])).has("secure_satellite")
		if completed:break
	if not completed:
		print("SATELLITE_FAILED ",controller.get("_phase_execution_by_fireteam")," feedback=",controller.get_mission_interaction_runtime_use_state_snapshot())
		for unit:Node2D in controller.call("_get_fireteam_units","ft1",true):print("CREW_POS ",unit.global_position)
	check(completed,"mouse-created action really secures satellite after timed hold")
	cursor.update_objective_feedback()
	check(cursor.get("_objective_text").text.contains("Daten gesichert"),"visible panel confirms actual success after the cursor leaves")
	check(cursor.get("_objective_text").text.contains("Heimatbasis"),"completed data explains required home upload")
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("C:/dev/SternenBuergerchen/output/flugdeck_20261110/satellite_complete.png")
	controller.call("set_tactical_ui_visible",false)
	check(cursor.refresh_at(pointer).is_empty(),"hidden live mission clears hints and cannot accept contextual rightclick")
	check(not cursor.activate_at(pointer).get("handled",false),"hidden mission cannot consume another view rightclick")
	controller.call("set_tactical_ui_visible",true)
	controller.call("_set_selected_fireteams",PackedStringArray(),false)
	check(cursor.refresh_at(pointer).is_empty(),"deselection clears intelligent cursor")
	mission.queue_free();await process_frame
	print("SATELLITE_MOUSE_USE checks=%d failures=%d" % [checks,failures]);quit(1 if failures else 0)
