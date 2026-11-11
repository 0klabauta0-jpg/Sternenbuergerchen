extends SceneTree
var failed := 0
func _init() -> void: call_deferred("_run")
func check(ok: bool,label: String) -> void:
	if not ok: failed+=1
	print("PASS: " if ok else "FAIL: ",label)
func _run() -> void:
	var path:="res://scripts/core/singleplayer_fleet_travel_state.gd"
	if not ResourceLoader.exists(path): check(false,"independent travel owner facade exists"); quit(1); return
	var fleet=load(path).new(); fleet.configure(); fleet.register_craft("a"); fleet.register_craft("b")
	var destination := {"a": "glut_1a_orbit", "b": "glut_1b_orbit"}
	for id in ["a","b"]:
		check(fleet.apply_command({"contract_category":"singleplayer_space_travel","operation":"launch_to_orbit","payload":{"craft_id":id},"request_id":"launch"},{"runtime_authorized":true}).get("ok",false),"independent craft launch "+id)
		check(fleet.apply_command({"contract_category":"singleplayer_space_travel","operation":"start_quantum","payload":{"craft_id":id,"target_orbit_id":destination[id]},"request_id":"jump"}).get("ok",false),"independent quantum "+id)
	fleet.focus_craft("a")
	fleet.apply_command({"contract_category":"singleplayer_space_travel","operation":"advance","payload":{"delta_seconds":60.0},"request_id":""},{"runtime_authorized":true})
	check(fleet.get_snapshot("a").orbit_id==destination.a and fleet.get_snapshot("b").orbit_id==destination.b,"one authoritative tick advances hidden and focused routes")
	fleet.apply_command({"contract_category":"singleplayer_space_travel","operation":"begin_approach","payload":{"craft_id":"a","location_id":"satellite_crash"},"request_id":"approach"},{"runtime_authorized":true})
	check(fleet.get_snapshot("a").phase=="approach" and fleet.get_snapshot("b").phase=="orbit","approach does not replace other route")
	check(not fleet.all_grounded(),"checkpoint gate sees all routes")
	check(fleet.get_snapshot().routes.size()==2,"snapshot projects both route identities")
	print("FLEET_TRAVEL failed=",failed); quit(1 if failed else 0)
