extends SceneTree
const FLEET=preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const GRID=preload("res://scripts/core/strategic_hex_grid.gd")
var count:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	count+=1
	if not ok: failures+=1
	print("PASS " if ok else "FAIL ",label)
func cmd(f,op: String,payload: Dictionary,id: String="",trusted: bool=true) -> Dictionary:
	return f.apply_command({"contract_category":"singleplayer_space_travel","operation":op,"payload":payload,"request_id":id},{"runtime_authorized":trusted})
func setup(authority: Object=null,local_mode: String=""):
	var f=FLEET.new(); assert(f.configure().ok); f.register_craft("ship")
	assert(cmd(f,"launch_to_orbit",{"craft_id":"ship"},"launch").ok)
	assert(cmd(f,"start_quantum",{"craft_id":"ship","target_orbit_id":"planet_orbit"},"warp").ok)
	assert(cmd(f,"advance",{"craft_id":"ship","delta_seconds":3.0}).ok)
	assert(cmd(f,"begin_approach",{"craft_id":"ship","location_id":"fortified_outpost"},"approach").ok)
	if authority!=null: assert(f.configure_space_area_transition_authority(authority).ok)
	if not local_mode.is_empty():
		var flight=f.get_flight_state("ship")
		assert(flight.commit_area_transition({"expected_revision":flight.get_snapshot().revision,"coordinate_frame":"local","space_area_id":"orbit_approach:planet","position_plane":GRID.HEX.axial_to_plane(Vector2(GRID.from_offset(Vector2i(220,225)))),"motion_mode":local_mode},1).ok)
	return f
func fingerprint(f) -> String:
	return JSON.stringify([f.get_snapshot("ship"),f.get_flight_state("ship").get_snapshot(),f._owners.ship._requests],"",true)
func context(f,id: String,source: String="orbit_approach:planet",target: String="orbit_approach:planet",operation: String="enter_orbit") -> Dictionary:
	return {"request_id":id,"request_signature":"root:"+id,"operation":operation,"payload":{"craft_id":"ship"} if operation=="enter_orbit" else {"craft_id":"ship","delta_seconds":3.0},"source_area_id":source,"target_area_id":target,"expected_travel_revision":int(f.get_snapshot("ship").revision),"expected_phase":String(f.get_snapshot("ship").phase),"context_id":"ctx:"+id}
func prepare(f,c: Dictionary) -> Dictionary: return f.prepare_space_area_transition("ship",c.expected_travel_revision,c.source_area_id,c.target_area_id,c)
func _initialize() -> void:
	var authority:=RefCounted.new()
	var f=setup(null,"travel"); var before:=fingerprint(f); var all_closed:=true
	for operation in ["initialize_surface","launch_to_orbit","start_quantum","advance","abort_quantum","begin_approach","finish_approach","enter_orbit","land_homebase"]:
		var result:=cmd(f,operation,{"craft_id":"ship","delta_seconds":0.0},"blocked:"+operation)
		all_closed=all_closed and not bool(result.ok) and result.reason=="local_area_transition_required"
	check(all_closed and fingerprint(f)==before,"actual Local travel rejects legacy actions before phase/pose/receipt mutations")
	var tactical=setup(null,"tactical"); before=fingerprint(tactical)
	var denied:=cmd(tactical,"launch_to_orbit",{"craft_id":"ship"},"launch")
	check(not denied.ok and denied.reason=="combat_active" and fingerprint(tactical)==before,"existing tactical guard retains precedence including old receipt replay")
	var strategic=FLEET.new(); strategic.configure(); strategic.register_craft("ship"); assert(cmd(strategic,"launch_to_orbit",{"craft_id":"ship"},"launch").ok); before=fingerprint(strategic)
	check(cmd(strategic,"launch_to_orbit",{"craft_id":"ship"},"launch").get("replayed",false) and fingerprint(strategic)==before,"strategic legacy replay semantics remain unchanged")
	var local=setup(authority,"tactical"); var flight=local.get_flight_state("ship"); var last: Dictionary=flight.get_snapshot()
	assert(flight.has_method("validate_space_activity_transition") and flight.has_method("commit_space_activity_transition"))
	var inactive: Dictionary=flight.commit_space_activity_transition({"expected_revision":last.revision,"motion_mode":"inactive"},2)
	before=fingerprint(local)
	check(inactive.ok and flight.get_snapshot().space_area_id==last.space_area_id and flight.get_snapshot().position_plane==last.position_plane and not cmd(local,"finish_approach",{"craft_id":"ship"},"untrusted-finish",false).ok and fingerprint(local)==before,"actual Source activity deactivation retains last pose/area and does not authorize untrusted finish")
	var inactive_snapshot: Dictionary=flight.get_snapshot()
	var finished:=cmd(local,"finish_approach",{"craft_id":"ship"},"finish")
	check(finished.ok and local.get_snapshot("ship").phase=="surface" and flight.get_snapshot()==inactive_snapshot,"trusted inactive finish changes Travel phase only")
	before=fingerprint(local)
	check(not cmd(local,"finish_approach",{"craft_id":"ship"},"wrong-phase").ok and fingerprint(local)==before and cmd(local,"finish_approach",{"craft_id":"ship"},"finish").get("replayed",false),"inactive finish requires existing approach; successful identical replay stays read-only")
	var active=setup(authority,"tactical"); var active_context:=context(active,"active"); assert(active.bind_space_area_transition_context(active_context,authority).ok)
	check(not prepare(active,active_context).ok,"prepared local return rejects still-active tactical Flight")
	var c:=context(local,"return"); assert(local.bind_space_area_transition_context(c,authority).ok); before=fingerprint(local); var candidate:=prepare(local,c)
	var bad_source:=context(local,"wrong-source","","orbit_approach:planet"); assert(local.bind_space_area_transition_context(bad_source,authority).ok)
	var bad_target:=context(local,"wrong-body","orbit_approach:planet","orbit_approach:moon"); assert(local.bind_space_area_transition_context(bad_target,authority).ok)
	check(candidate.ok and fingerprint(local)==before and not prepare(local,bad_source).ok and not prepare(local,bad_target).ok,"inactive local prepare is read-only and binds actual canonical source/body area")
	var validation: Dictionary=local.validate_prepared_space_area_transition(candidate,c)
	assert(validation.ok)
	var reactivated: Dictionary=flight.commit_space_activity_transition({"expected_revision":flight.get_snapshot().revision,"motion_mode":"tactical","position_plane":flight.get_snapshot().position_plane},3)
	var travel_before: Dictionary=local.get_snapshot("ship")
	check(reactivated.ok and not local.commit_prepared_space_area_transition(candidate,c).ok and local.get_snapshot("ship")==travel_before,"public commit rejects changed Flight revision/mode after actual reactivation")
	var flight_after_activity: Dictionary=flight.get_snapshot()
	var published: Dictionary=local._publish_prepared_space_area_transition(candidate,validation)
	check(published.ok and local.get_snapshot("ship").phase=="orbit" and flight.get_snapshot()==flight_after_activity,"Root-private Travel tail publishes after activity without Flight reread/write")
	var warp=FLEET.new(); warp.configure(); warp.register_craft("ship"); warp.configure_space_area_transition_authority(authority)
	assert(cmd(warp,"launch_to_orbit",{"craft_id":"ship"},"launch").ok); assert(cmd(warp,"start_quantum",{"craft_id":"ship","target_orbit_id":"planet_orbit"},"warp").ok)
	var wc:=context(warp,"warp-arrival","","orbit_approach:planet","advance"); assert(warp.bind_space_area_transition_context(wc,authority).ok)
	var pose_before: Dictionary=warp.get_flight_state("ship").get_snapshot()
	check(warp.commit_prepared_space_area_transition(prepare(warp,wc),wc).ok and warp.get_snapshot("ship").phase=="orbit" and warp.get_flight_state("ship").get_snapshot()==pose_before,"existing strategic prepared Warp completion remains pose-free")
	print("LOCAL_TRAVEL_LIFECYCLE_RESULT checks=",count," failures=",failures," runtime_reactivation_wired=false")
	quit(1 if failures else 0)
