extends SceneTree
var checks := 0
var failures := 0
func _init() -> void: call_deferred("_run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _run() -> void:
	var start = load("res://scripts/meta/game_start_contract.gd")
	start.request_start(self,"skirmish","new","early")
	var flow = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	await process_frame
	var runtime: Node = flow.get("_singleplayer_runtime")
	var personnel: Node = runtime.call("get_base_personnel_runtime")
	if personnel == null:
		check(false,"Prepared Skirmish has authoritative base personnel")
		flow.queue_free(); await process_frame; quit(1); return
	var state: Dictionary = personnel.get_snapshot()
	check(state.units.size() == 8,"Eight real runtime people")
	check(state.layout.beds.size() == 8,"Eight real beds")
	check(state.layout.landing_pads.size() == 3,"Three real pads")
	var terrain: Node = personnel.get_terrain_registry()
	var nav = personnel.get("_navigation_graph")
	var origin: Vector2 = personnel.get_actor(state.units[0].unit_id).position
	var occupied := {}
	for bed: Dictionary in state.layout.beds:
		check(not occupied.has(bed.id),"Distinct bed identities")
		occupied[bed.id] = true
		var p: Vector2 = personnel.call("_world",bed.grid)
		check(terrain.is_walkable(terrain.world_to_grid(p)),"Bed is reachable walkable tile")
		check(not nav.find_world_path(origin,p).is_empty(),"Real navigation connects each bed")
	var first_id := String(state.units[0].unit_id)
	var position_before: Vector2 = personnel.get_actor(first_id).position
	check(personnel.request_operation("base_rename",{"unit_id":first_id,"display_name":"Neue Pilotin"}).get("ok",false),"Actual personnel rename commits through SimulationRoot")
	check(String(personnel.get("_states")[first_id].name)=="Neue Pilotin","Runtime displays renamed person")
	check(String(flow.get("_all_team_units")[0].display_name)=="Neue Pilotin","Saved roster identity receives new name")
	check(not personnel.request_operation("base_rename",{"unit_id":first_id,"display_name":""}).get("ok",false),"Empty rename rejected")

	var roster: Array = Array(flow.get("_all_team_units")).duplicate(true)
	var added: Dictionary = roster[0].duplicate(true)
	added.unit_id = "expansion_recruit"
	added.display_name = "Neuer Rekrut"
	roster.append(added)
	flow.set("_all_team_units",roster)
	personnel.call("sync_roster")
	check(personnel.get_actor("expansion_recruit") != null,"Recruit gets real actor")
	check(personnel.get_actor(first_id).position == position_before,"Recruit synchronization preserves existing positions")
	check(personnel.get_snapshot().layout.beds.size() >= 9,"Recruit gets enough sleep capacity")
	var craft_id := String(Array(flow.get("_homebase_aircraft_definitions"))[0].craft_id)
	check(personnel.call("mark_recruit_remote","expansion_recruit",craft_id).ok,"Verified remote recruit is represented aboard real transport")
	check(String(personnel.get("_states").expansion_recruit.status) == "aboard","Remote recruit does not appear at home")
	check(not personnel.call("mark_recruit_remote","expansion_recruit","missing_craft").ok,"Unknown recruitment transport rejected")
	personnel.call("sync_roster")
	check(personnel.get_snapshot().units.size() == 9,"Roster synchronization is idempotent")
	check(String(personnel.get("_states").expansion_recruit.craft_id) == craft_id,"Synchronization keeps remote recruitment presence")
	var bed_id := String(state.layout.beds[0].id)
	check(personnel.request_operation("base_sleep",{"unit_id":first_id,"bed_id":bed_id}).ok,"Actual actor can reserve reachable bed")
	check(not personnel.request_operation("base_sleep",{"unit_id":String(state.units[1].unit_id),"bed_id":bed_id}).ok,"Same bed cannot serve two people")
	flow.queue_free()
	await process_frame
	print("Base expansion: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
