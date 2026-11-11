extends SceneTree
const FLEET=preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const GRID=preload("res://scripts/core/strategic_hex_grid.gd")
var count:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	count+=1
	if not ok: failures+=1
	print("PASS " if ok else "FAIL ",label)
func cmd(f,op: String,payload: Dictionary,id: String="") -> Dictionary:
	return f.apply_command({"contract_category":"singleplayer_space_travel","operation":op,"payload":payload,"request_id":id},{"runtime_authorized":true})
func setup(authority: Object,orbit: String="planet_orbit",local_mode: bool=true):
	var f=FLEET.new(); assert(f.configure().ok); f.register_craft("ship"); f.configure_space_area_transition_authority(authority)
	assert(cmd(f,"launch_to_orbit",{"craft_id":"ship"},"launch").ok)
	if orbit!="moon_orbit":
		assert(cmd(f,"start_quantum",{"craft_id":"ship","target_orbit_id":orbit},"warp").ok)
		assert(cmd(f,"advance",{"craft_id":"ship","delta_seconds":3.0}).ok)
	if local_mode:
		var body: String=f.get_snapshot("ship").orbits[orbit].body_id
		var flight=f.get_flight_state("ship")
		assert(flight.commit_area_transition({"expected_revision":flight.get_snapshot().revision,"coordinate_frame":"local","space_area_id":"orbit_approach:"+body,"motion_mode":"tactical","position_plane":GRID.HEX.axial_to_plane(Vector2(GRID.from_offset(Vector2i(220,225))))},1).ok)
	return f
func context(f,id: String,location: String="fortified_outpost",area: String="orbit_approach:planet",operation: String="begin_approach") -> Dictionary:
	var payload: Dictionary={"craft_id":"ship","location_id":location} if operation=="begin_approach" else {"craft_id":"ship"}
	return {"request_id":id,"request_signature":JSON.stringify({"operation":operation,"payload":payload},"",true),"operation":operation,"payload":payload,"source_area_id":area,"target_area_id":area,"expected_travel_revision":int(f.get_snapshot("ship").revision),"expected_phase":String(f.get_snapshot("ship").phase),"context_id":"ctx:"+id}
func prepare(f,c: Dictionary) -> Dictionary: return f.prepare_space_area_transition("ship",c.expected_travel_revision,c.source_area_id,c.target_area_id,c)
func bound(f,c: Dictionary,authority: Object) -> Dictionary:
	assert(f.bind_space_area_transition_context(c,authority).ok)
	return prepare(f,c)
func fingerprint(f) -> String: return JSON.stringify([f.get_snapshot("ship"),f.get_flight_state("ship").get_snapshot(),f._owners.ship._requests],"",true)
func _initialize() -> void:
	var authority:=RefCounted.new()
	var f=setup(authority); var c:=context(f,"begin"); assert(f.bind_space_area_transition_context(c,authority).ok)
	var before:=fingerprint(f); var candidate:=prepare(f,c)
	check(candidate.ok and fingerprint(f)==before and candidate.state.next.phase=="approach" and candidate.state.next.location_id=="fortified_outpost" and not candidate.has("gate_token"),"read-only local tactical prepare builds phase/location only; geometry gate remains Root-owned")
	var extra:=context(f,"extra"); extra.payload.gate_authorized=true
	var wrong_type:=context(f,"type"); wrong_type.payload.location_id=123
	check(not f.bind_space_area_transition_context(extra,authority).ok and not f.bind_space_area_transition_context(wrong_type,authority).ok,"typed begin payload permits exactly craft and string location")
	var strategic=setup(authority,"planet_orbit",false)
	var inactive=setup(authority); var sleeping=inactive.get_flight_state("ship"); assert(sleeping.commit_space_activity_transition({"expected_revision":sleeping.get_snapshot().revision,"motion_mode":"inactive"},2).ok)
	check(not bound(strategic,context(strategic,"strategic"),authority).ok and not bound(inactive,context(inactive,"inactive"),authority).ok,"real strategic or inactive Flight cannot begin local surface approach")
	check(not bound(f,context(f,"wrong-orbit","trade_outpost"),authority).ok and not bound(f,context(f,"not-surface","distress_orbit"),authority).ok and not bound(f,context(f,"wrong-area","fortified_outpost","orbit_approach:moon"),authority).ok,"actual location orbit, explicit body surface link and canonical area must all match")
	var station=setup(authority,"polisa_orbit"); var home=setup(authority,"moon_orbit")
	check(not bound(station,context(station,"station","polisa","orbit_approach:glut_2"),authority).ok and not bound(home,context(home,"home","homebase","orbit_approach:moon"),authority).ok,"actual station and home landing remain separate paths")
	var race=setup(authority); var rc:=context(race,"race"); var raced:=bound(race,rc,authority); var flight=race.get_flight_state("ship")
	assert(flight.commit_motion({"expected_revision":flight.get_snapshot().revision,"position_plane":flight.get_snapshot().position_plane+Vector2(0.25,0)},2).ok)
	before=fingerprint(race)
	check(not race.commit_prepared_space_area_transition(raced,rc).ok and fingerprint(race)==before,"real intervening Flight motion invalidates candidate without Travel mutation")
	var validation: Dictionary=f.validate_prepared_space_area_transition(candidate,c); assert(validation.ok)
	var actual=f.get_flight_state("ship"); var pose: Dictionary=actual.get_snapshot()
	assert(actual.commit_space_activity_transition({"expected_revision":pose.revision,"motion_mode":"inactive"},2).ok)
	var sleeping_pose: Dictionary=actual.get_snapshot(); before=fingerprint(f)
	check(not f.commit_prepared_space_area_transition(candidate,c).ok and fingerprint(f)==before,"public commit is stale after actual Activitydeactivation")
	var published: Dictionary=f._publish_prepared_space_area_transition(candidate,validation)
	var approach_ok: bool=published.ok and f.get_snapshot("ship").phase=="approach" and f.get_snapshot("ship").location_id=="fortified_outpost" and actual.get_snapshot()==sleeping_pose
	var finish:=cmd(f,"finish_approach",{"craft_id":"ship"},"finish")
	check(approach_ok and finish.ok and f.get_snapshot("ship").phase=="surface" and actual.get_snapshot()==sleeping_pose,"prevalidated private tail publishes after deactivation and trusted finish stays phase-only")
	before=fingerprint(f); var replay: Dictionary=f.commit_prepared_space_area_transition(prepare(f,c),c)
	var conflicting:=c.duplicate(true); conflicting.payload.location_id="distress_orbit"
	check(replay.get("replayed",false) and fingerprint(f)==before and not f.bind_space_area_transition_context(conflicting,authority).ok,"successful begin replays read-only after finish; changed target under same request rejects")
	var warp=FLEET.new(); warp.configure(); warp.register_craft("ship"); warp.configure_space_area_transition_authority(authority)
	assert(cmd(warp,"launch_to_orbit",{"craft_id":"ship"},"launch").ok); assert(cmd(warp,"start_quantum",{"craft_id":"ship","target_orbit_id":"planet_orbit"},"warp").ok)
	var wc:=context(warp,"warp-arrival","","","advance"); wc.target_area_id="orbit_approach:planet"; wc.payload={"craft_id":"ship","delta_seconds":3.0}; wc.request_signature=JSON.stringify({"operation":"advance","payload":wc.payload},"",true)
	var warp_pose: Dictionary=warp.get_flight_state("ship").get_snapshot(); var warp_result: Dictionary=warp.commit_prepared_space_area_transition(bound(warp,wc,authority),wc)
	var exit_context:=context(f,"exit","","orbit_approach:planet","enter_orbit"); var exit_candidate:=bound(f,exit_context,authority); var exit_validation: Dictionary=f.validate_prepared_space_area_transition(exit_candidate,exit_context); assert(exit_validation.ok)
	assert(actual.commit_space_activity_transition({"expected_revision":actual.get_snapshot().revision,"motion_mode":"tactical","position_plane":actual.get_snapshot().position_plane},3).ok)
	var reactivated_pose: Dictionary=actual.get_snapshot(); var exit_result: Dictionary=f._publish_prepared_space_area_transition(exit_candidate,exit_validation)
	check(warp_result.ok and warp.get_snapshot("ship").phase=="orbit" and warp.get_flight_state("ship").get_snapshot()==warp_pose and exit_result.ok and f.get_snapshot("ship").phase=="orbit" and actual.get_snapshot()==reactivated_pose,"strategic Warp arrival and inactive local exit remain pose-free through actual Activity API")
	print("PREPARED_LOCAL_BEGIN_RESULT checks=",count," failures=",failures," runtime_wired=false")
	quit(1 if failures else 0)
