extends "res://scripts/tests/playtest_20261109_singleplayer_loop_smoke.gd"
## Skirmish mit Voreinstellung "early" (nur sie hat seit a4d5948c5 eine Basis-Personal-Laufzeit), zwei echte Schiffe, echte Route-/Landebefehle.
## Einsteigen laeuft echt zu Fuss (base_board); nur der bestehende Boarding-Takt wird in kleinen Schritten vorgespult.
const PRESET := "early"
var same_place := false
var native_probe := false
func _run() -> void:
	same_place=OS.get_cmdline_user_args().has("same_place")
	native_probe=OS.get_cmdline_user_args().has("native_probe") or OS.get_cmdline_user_args().has("capture_only")
	# Skirmish hat seit a4d5948c5 nur mit Voreinstellung eine Basis-Personal-Laufzeit (ohne sie gibt es keinen Piloten an Bord, Start = pilot_not_aboard).
	load("res://scripts/meta/game_start_contract.gd").request_start(self,"skirmish","new",PRESET)
	_flow=FLOW.instantiate(); root.add_child(_flow); await process_frame
	_screen=_flow.get_node("HomebaseScreen"); _runtime=_flow.get("_singleplayer_runtime")
	if native_probe:
		_screen.call("request_operation","navigate",{"mode":"base"})
		await _profile_world("one_base",null)
	var operations: Dictionary=_screen.call("get_operations_snapshot")
	var first: Dictionary=operations.selected_craft
	var craft_a:=String(first.id)
	var team_a:=String(Array(first.payload_fireteam_ids)[0])
	_check(_screen.call("request_operation","accept_job",{"job_id":"satellite_recovery"}).get("ok",false),"A accepts normal satellite job")
	_check(_screen.call("request_operation","select_destination",{"location_id":"satellite_crash"}).get("ok",false),"A chooses satellite")
	if not await _route(craft_a,team_a,"satellite_crash"):
		await _finish(); return
	var a: Node=_flow.call("get_mission_for_craft",craft_a)
	_check(a!=null,"A has real location instance")
	if native_probe: await _profile_world("two_base_satellite",a)
	if a==null: await _finish(); return
	var tick_a: int=int(a.get_node("SimulationRoot").call("get_tick"))
	var ids_a:=PackedStringArray(a.get_node("MissionSetup").get("selected_team_unit_ids"))
	var positions: Dictionary={}
	for id in ids_a:
		var actor: Node2D=a.get_node("TacticalController").call("_find_friendly_unit_by_id",id)
		if actor!=null: positions[id]=actor.position
	_flow.call("_show_homebase",true)
	# Die Voreinstellung liefert das zweite echte Schiff samt Landeplatz, eigenem Piloten und zweitem Trupp schon mit. Ein nachtraeglich
	# per _on_homebase_aircraft_add_requested hinzugefuegtes Schiff hat keinen Landeplatz und laesst sich nicht zu Fuss einschiffen
	# (respawn_ship_mask_unavailable).
	operations=_screen.call("get_operations_snapshot")
	var craft_b:=""; var pilot_b:=""
	for craft: Dictionary in operations.crafts:
		if String(craft.id)!=craft_a and craft_b.is_empty(): craft_b=String(craft.id); pilot_b=String(craft.get("pilot_id",""))
	_check(not craft_b.is_empty(),"preset provides a second real ship")
	var team_b:=""
	for team: Dictionary in operations.fireteams:
		if String(team.id)!=team_a and not Array(team.members).is_empty() and not bool(team.get("busy",false)): team_b=String(team.id); break
	var members_b: Array=[]
	for team: Dictionary in operations.fireteams:
		if String(team.id)==team_b:
			for member: Dictionary in team.members: members_b.append(String(member.id))
	var pilot_a:=String(first.get("pilot_id",""))
	_check(not team_b.is_empty() and not members_b.is_empty(),"preset provides an independent second troop")
	_check(not pilot_b.is_empty() and pilot_b!=pilot_a and not members_b.has(pilot_b) and not PackedStringArray(ids_a).has(pilot_b),"B has its own pilot, independent of A's pilot and both troops")
	if team_b.is_empty() or pilot_b.is_empty(): await _finish(); return
	_screen.call("request_operation","craft",{"craft_id":craft_b})
	_check(_screen.call("request_operation","select_destination",{"location_id":"satellite_crash" if same_place else "trade_outpost","craft_id":craft_b}).get("ok",false),"B chooses trade while A remains deployed")
	if not await _route(craft_b,team_b,"satellite_crash" if same_place else "trade_outpost"):
		await _finish(); return
	var b: Node=_flow.call("get_mission_for_craft",craft_b)
	_check(b==a if same_place else (b!=null and b!=a),"same location uses shared scene" if same_place else "A and B have distinct actual location instances")
	if native_probe: await _profile_world("three_base_satellite_trade",b)
	_check(int(a.get_node("SimulationRoot").call("get_tick"))>tick_a,"hidden A continues authoritative physics while B travels")
	_check(_flow.call("get_location_runtime_snapshot").size()==(1 if same_place else 2),"both places remain in registry")
	_check(not _runtime.call("get_world_checkpoint_guard").get("ok",true),"checkpoint visibly blocked while either craft remains remote")
	# Landing security may legitimately move A during B's journey. Sample now,
	# immediately before the view changes, rather than freezing ongoing orders.
	for id in positions:
		positions[id]=a.get_node("TacticalController").call("_find_friendly_unit_by_id",id).position
	var a_id:=a.get_instance_id(); var b_id:=b.get_instance_id()
	for id in (["satellite_crash","satellite_crash"] if same_place else ["satellite_crash","trade_outpost","satellite_crash"]):
		_check(_screen.call("request_operation","focus_location",{"location_id":id}).get("ok",false),"explicit view focus "+id)
		await process_frame
	_check(is_instance_valid(a) and is_instance_valid(b) and a.get_instance_id()==a_id and b.get_instance_id()==b_id,"A-B-A never reconstructs or frees either scene")
	for id in positions:
		var actor: Node2D=a.get_node("TacticalController").call("_find_friendly_unit_by_id",id)
		_check(actor!=null and actor.position.distance_to(positions[id])<2,"view switch preserves actual position "+String(id))
	var before_b:=int(b.get_node("SimulationRoot").call("get_tick"))
	_flow.call("_show_homebase",true)
	await create_timer(0.5).timeout
	_check(int(b.get_node("SimulationRoot").call("get_tick"))>before_b,"base view also leaves B simulation running")
	var response: Dictionary=_screen.call("request_operation","return_homebase",{"craft_id":craft_a})
	_check(response.get("ok",false),"A return uses its own controller while B is in another place")
	if response.get("ok",false):
		await _wait(func(): return String(_runtime.call("get_space_travel_snapshot",craft_a).phase)=="orbit",30000,"A reaches orbit independently")
		_check(is_instance_valid(b) and String(_runtime.call("get_space_travel_snapshot",craft_b).phase)=="surface","B remains at its original place while A leaves")
		_screen.call("request_operation","space_start_quantum",{"craft_id":craft_a,"target_orbit_id":"moon_orbit"})
		await _wait(func(): return String(_runtime.call("get_space_travel_snapshot",craft_a).orbit_id)=="moon_orbit",10000,"A independently reaches moon")
		_check(_screen.call("request_operation","space_land_homebase",{"craft_id":craft_a}).get("ok",false),"A independently lands home")
		_check(is_instance_valid(b) and String(_flow.get("_aircraft_location_by_craft").get(craft_b,""))=="mission","home arrival cannot remove B")
	if OS.get_cmdline_user_args().has("revisit"):
		_screen.call("request_operation","craft",{"craft_id":craft_a})
		if Array(_screen.call("get_operations_snapshot").selected_craft.get("payload_fireteam_ids",[])).has(team_a):
			_check(_screen.call("request_operation","unboard",{"craft_id":craft_a,"fireteam_id":team_a}).get("ok",false),"returning crew leaves payload before changing gear")
		else: _check(true,"returned crew is already outside its home payload")
		var unit_id:=String(positions.keys()[0])
		var equipped: Dictionary=_screen.call("request_operation","inventory_equip",{"craft_id":craft_a,"unit_id":unit_id,"source_container_id":"base:homebase","slot":"armor","item_id":"armor_heavy"})
		_check(equipped.get("ok",false),"home owner equips a different finite armor before revisit")
		_check(_screen.call("request_operation","accept_job",{"job_id":"satellite_recovery"}).get("ok",false),"failed satellite departure can be accepted anew")
		_check(_screen.call("request_operation","select_destination",{"craft_id":craft_a,"location_id":"satellite_crash","job_id":"satellite_recovery"}).get("ok",false),"returner selects retained location for fresh job visit")
		if await _route(craft_a,team_a,"satellite_crash"):
			var revisited: Node=_flow.call("get_mission_for_craft",craft_a)
			_check(revisited==a,"revisit keeps same world instance and its other visitor")
			_check(revisited.get_node("MissionSetup").get("member_loadouts")[unit_id].armor=="heavy","retained setup reads new authoritative armor")
			var actor: Node=revisited.get_node("TacticalController").call("_find_friendly_unit_by_id",unit_id)
			_check(String(actor.get("armor_id"))=="heavy" if actor.get("armor_id")!=null else String(actor.call("get_armor_id"))=="heavy","actual returning actor uses newly equipped armor")
			_check(String(revisited.get_meta("singleplayer_mission_identity").craft_id)==craft_a,"fresh job checks bind its actual returning craft")
			_check(String(_runtime.call("get_space_travel_snapshot",craft_b).phase)=="surface","fresh job admission keeps B at original place")
	print("TWO_LOCATION_RUNTIME completed=",_failed==0)
	await _finish()

## Echtes Einschiffen: Basis-Personal-Laufzeit und der bestehende Boarding-Takt laufen in kleinen Schritten, bis der Pilot
## tatsaechlich an Bord ist und der Nutzlast-Besitzer den Start freigibt (Muster orbit_quantum_flow_verifier._board_real_crew).
## Niemand wird versetzt oder als an Bord markiert.
func _board_real_crew(craft: String, team: String) -> bool:
	var personnel: Node=_runtime.call("get_base_personnel_runtime")
	if not _check(personnel!=null,"preset Skirmish has a base personnel runtime for "+craft): return false
	# Der Screen setzt ohne unit_id die zuletzt fokussierte Person ein (hier womoeglich schon an Bord eines anderen Schiffs): eine Person des Trupps nennen.
	var members: PackedStringArray=_screen.call("_get_member_unit_ids_for_fireteam",team)
	var walk: Dictionary=_screen.call("request_operation","base_board",{"craft_id":craft,"fireteam_id":team,"unit_id":String(members[0]) if not members.is_empty() else "","whole_fireteam":true})
	if not _check(walk.get("ok",false),"public base command starts the real crew walk and boarding "+craft):
		print(walk); return false
	var sim: Node=personnel.call("get_simulation_root")
	for tick in range(6000):
		if personnel.call("is_pilot_aboard",craft) and bool(_screen.call("_has_homebase_direct_launch_payload_for_craft",craft)): break
		sim.call("_physics_process",0.05)
		_screen.call("_debug_advance_homebase_direct_boarding",0.05)
	var boarded:=bool(personnel.call("is_pilot_aboard",craft)) and bool(_screen.call("_has_homebase_direct_launch_payload_for_craft",craft))
	if not boarded:
		print("BOARDING_DIAG pilot_aboard=",personnel.call("is_pilot_aboard",craft)," payload=",_screen.call("_has_homebase_direct_launch_payload_for_craft",craft)," walking_groups=",personnel.get("_board_groups").keys())
	return _check(boarded,"real pilot arrival and payload owner confirm boarding "+craft)

func _route(craft: String, team: String, location: String) -> bool:
	_screen.call("request_operation","craft",{"craft_id":craft})
	_screen.call("request_operation","focus_fireteam",{"fireteam_id":team})
	# Einsteigen geht nur noch den echten Weg: base_board schickt Truppmitglieder und Pilot zu Fuss zum Schiff (kein Sofort-Staging).
	if not _board_real_crew(craft,team):
		print("REVISIT_BOARD members=",_screen.call("_get_member_unit_ids_for_fireteam",team)," payload=",_screen.call("_operations_payload_craft_for_team",team)," gate=",_screen.call("_build_homebase_direct_staging_craft_gate_for_craft",craft)); return false
	var started: Dictionary=_screen.call("request_operation","start",{"craft_id":craft})
	if not _check(started.get("ok",false),"independent normal launch "+craft): print(started); return false
	# start meldet auch dann ok, wenn der Abflug scheitert (Fehler nur im Screen-Meta): auf die Phase warten, nicht auf das Ergebnis.
	if not await _wait(func(): return String(_runtime.call("get_space_travel_snapshot",craft).phase)=="orbit",60000,"craft lifts off into orbit "+craft):
		print("DEPARTURE_ERROR ",_screen.get_meta("singleplayer_departure_error",{})); return false
	var target_orbit:=String(Dictionary(Dictionary(_runtime.call("get_space_travel_snapshot",craft)).get("location_orbits",{})).get(location,""))
	if not _check(not target_orbit.is_empty(),"travel snapshot names the orbit of "+location): return false
	var jump: Dictionary=_screen.call("request_operation","space_start_quantum",{"craft_id":craft,"target_orbit_id":target_orbit})
	if not _check(jump.get("ok",false),"independent quantum "+craft): print(jump); return false
	if not await _wait(func(): return String(_runtime.call("get_space_travel_snapshot",craft).orbit_id)==target_orbit,60000,"craft reaches orbit "+target_orbit+" "+craft): return false
	var approach: Dictionary=_screen.call("request_operation","space_begin_approach",{"craft_id":craft,"location_id":location})
	if not _check(approach.get("ok",false),"independent approach "+craft): print(approach); return false
	if not await _wait(func(): return _flow.call("get_mission_for_craft",craft)!=null,20000,"real place loaded "+location): return false
	var instance: Node=_flow.call("get_mission_for_craft",craft)
	var controller: Node=instance.get_node("TacticalController")
	if not await _wait(func(): return String(controller.call("_find_mission_dropship_card_entry",craft).get("state",""))=="waiting",30000,"craft waits at its own place "+craft):
		print("LOCATION_TRANSPORT_DUMP ",JSON.stringify({"card":controller.call("_find_mission_dropship_card_entry",craft),"pending":_flow.get("_pending_mission_craft_transfers"),"locations":_flow.get("_aircraft_location_by_craft"),"flow_cards":_flow.get("_mission_planning_state").get("mission_drop_cards",[]),"instances":_flow.call("get_location_runtime_snapshot")}))
		return false
	_flow.call("focus_location",location)
	var map=MAP.load_from_file("res://maps/satellite_crash_site.json" if location=="satellite_crash" else "res://maps/trade_outpost.json")
	var view: Node=instance.get_node("Primary3DView")
	var lz: Vector2=map.get_marker_position("spawn_alpha")
	view.call("focus_world_position",lz)
	controller.call("_on_mission_dropship_card_set_lz_pressed",craft)
	if same_place and _flow.call("get_location_runtime_snapshot").size()==1 and craft.ends_with("_2"):
		_check(not controller.call("_place_lz_from_screen_position",view.call("world_to_screen_position",lz)),"second visitor waits instead of landing on occupied craft")
		lz=map.grid_to_world(Vector2i(-10,-10)) if map.has_method("grid_to_world") else Vector2(-960,-480)
		var registry: Node=instance.get_node("TerrainRegistry")
		lz=registry.call("grid_to_world",Vector2i(-10,-10))
		view.call("focus_world_position",lz)
	if not _check(controller.call("_place_lz_from_screen_position",view.call("world_to_screen_position",lz)),"local landing pick "+craft): return false
	controller.call("_on_mission_dropship_card_drop_pressed",craft)
	return await _wait(func(): return String(controller.call("_find_mission_dropship_card_entry",craft).get("state","")) in ["complete","landed"] and not Dictionary(controller.get("_deployed_unit_ids")).is_empty(),30000,"real crew lands "+craft)

func _profile_world(label: String, instance: Node) -> void:
	if instance!=null: _flow.call("focus_location",String(instance.get_meta("location_id","")))
	var view: Node=instance.get_node("Primary3DView") if instance!=null else null
	var samples: Array[float]=[]
	var deadline:=Time.get_ticks_msec()+(1000 if OS.get_cmdline_user_args().has("capture_only") else 30000)
	var previous:=Time.get_ticks_usec()
	while Time.get_ticks_msec()<deadline:
		await process_frame
		var now:=Time.get_ticks_usec(); var elapsed: float=(now-previous)/1000000.0
		samples.append(elapsed*1000.0); previous=now
		if view!=null: view.call("pan_camera",Vector2(sin(now/1000000.0),cos(now/1000000.0))*0.07,elapsed)
	var path:=ProjectSettings.globalize_path("res://output/playtest_20261110/native-world")
	DirAccess.make_dir_recursive_absolute(path)
	root.get_texture().get_image().save_png(path+"/"+label+".png")
	samples.sort()
	print("WORLD_PROFILE ",label," count=",samples.size()," p95=",samples[int(samples.size()*.95)]," p99=",samples[int(samples.size()*.99)]," max=",samples.back()," memory=",Performance.get_monitor(Performance.MEMORY_STATIC))
