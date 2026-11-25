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
	var i:=0
	for unit: Node2D in controller.call("_get_fireteam_units","ft1",true): unit.position=target+Vector2(i*8,0);i+=1
	view.focus_world_position(target)
	var pointer:Vector2=view.world_to_screen_position(target)
	var driver:Node=mission.get_node("CombatLoopDriver")
	var before: Dictionary=driver.get_mission_scenario_runtime_gate_snapshot()
	var hover:Dictionary=cursor.refresh_at(pointer)
	if hover.is_empty(): print("CONTEXT_DEBUG ",pointer," edit=",controller.call("_can_edit_planning")," ui=",controller.call("_is_pointer_over_control",pointer)," selection=",controller.get("_selected_fireteam_ids")," snapshot=",controller.call("get_mission_interaction_runtime_use_state_snapshot"))
	check(hover.get("id","")=="satellite_data","actual projected satellite hover identifies correct target")
	check(hover.get("label","")=="Daten sichern","actual cursor advertises the real data action")
	check(driver.get_mission_scenario_runtime_gate_snapshot()==before,"hover never completes objective or submits gameplay")
	var result:Dictionary=cursor.activate_at(pointer)
	check(result.get("handled",false) and result.get("ok",false),"context rightclick queues existing actual Use intent")
	check(driver.get_mission_scenario_runtime_gate_snapshot()==before,"queued Use still requires GO and real duration")
	# (a) Klickregeln: Einheit hat Vorrang, erledigte/gesperrte Marker verbrauchen keinen Klick, ohne Auswahl auch nicht.
	var active_marker:Dictionary={"kind":"interaction","complete":false,"blocked":false}
	check(cursor.marker_consumes_left_click(true,false,active_marker),"aktiver Marker mit Auswahl verbraucht den Linksklick")
	check(not cursor.marker_consumes_left_click(true,true,active_marker),"Linksklick auf eine eigene Einheit am Marker waehlt die Einheit")
	check(not cursor.marker_consumes_left_click(true,false,{"kind":"interaction","complete":true,"blocked":false}),"erledigter Marker verbraucht keinen Klick")
	check(not cursor.marker_consumes_left_click(true,false,{"kind":"interaction","complete":false,"blocked":true}),"gesperrter Marker verbraucht keinen Klick")
	check(not cursor.marker_consumes_left_click(false,false,active_marker),"ohne Auswahl verbraucht der Marker keinen Klick")
	# Einheit direkt am Marker: echter Linksklick waehlt, vormerken findet nicht statt.
	var unit_pos:Vector2=(controller.call("_get_fireteam_units","ft1",true)[0] as Node2D).global_position
	var unit_pointer:Vector2=view.world_to_screen_position(unit_pos)
	check(controller.call("_find_selectable_unit_at_screen_position",unit_pointer)!=null,"Einheit am Marker ist anwaehlbar")
	var intent_before:Variant=controller.get("_last_mission_interaction_use_intent_snapshot").duplicate(true)
	var press_unit:=InputEventMouseButton.new();press_unit.button_index=MOUSE_BUTTON_LEFT;press_unit.pressed=true;press_unit.position=unit_pointer;cursor._unhandled_input(press_unit)
	check(not bool(cursor.get("_marker_press_active")),"Klick auf Einheit am Marker startet keine Marker-Aktion")
	# (b) In Reichweite, keine Einheit unter dem Zeiger: Linksklick startet sofort ohne GO.
	var j:=0
	for unit: Node2D in controller.call("_get_fireteam_units","ft1",true): unit.position=target+Vector2(45+j*3,0);j+=1
	await process_frame
	var entry_now:Dictionary={}
	for e:Dictionary in controller.call("get_mission_interaction_runtime_use_state_snapshot").get("interactions",[]):
		if String(e.get("interaction_id",""))=="satellite_data": entry_now=e
	print("DIRECT_ENTRY can_use_now=",entry_now.get("can_use_now"), " status=",entry_now.get("runtime_use_status"))
	check(bool(entry_now.get("can_use_now",false)),"Einheiten in Reichweite: Marker ist sofort benutzbar")
	check(controller.call("_find_selectable_unit_at_screen_position",pointer)==null,"kein Truppmitglied unter dem Zeiger am Marker")
	for pressed in [true,false]:
		var direct:=InputEventMouseButton.new();direct.button_index=MOUSE_BUTTON_LEFT;direct.pressed=pressed;direct.position=pointer;root.push_input(direct,true)
		await process_frame
	var direct_use:Dictionary=controller.get("_last_mission_interaction_use_intent_snapshot")
	var direct_wp:Variant=controller.call("_get_waypoint_from_ref",direct_use) if direct_use.get("accepted",false) else null
	check(direct_use.get("accepted",false) and direct_wp!=null and String(direct_wp.status)=="active","Linksklick in Reichweite startet die Aktion ohne GO (Wegpunkt aktiv)")
	cursor.update_objective_feedback()
	check(not String(cursor.get("_objective_text").text).contains("GO drücken"),"kein Vormerk-Fenster mit GO bei direktem Start")
	controller.call("set_tactical_ui_visible",false)
	check(cursor.refresh_at(pointer).is_empty(),"hidden live mission clears hints and cannot accept contextual rightclick")
	check(not cursor.activate_at(pointer).get("handled",false),"hidden mission cannot consume another view rightclick")
	controller.call("set_tactical_ui_visible",true)
	controller.call("_set_selected_fireteams",PackedStringArray(),false)
	check(cursor.refresh_at(pointer).is_empty(),"deselection clears intelligent cursor")
	mission.queue_free();await process_frame
	print("MISSION_CONTEXT_CURSOR checks=%d failures=%d" % [checks,failures]);quit(1 if failures else 0)
