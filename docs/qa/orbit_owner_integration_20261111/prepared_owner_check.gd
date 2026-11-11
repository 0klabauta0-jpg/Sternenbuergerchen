extends SceneTree
const FLEET=preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
var count:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	count+=1
	if not ok: failures+=1
	print("PASS " if ok else "FAIL ",label)
func cmd(f,op: String,payload: Dictionary,id: String="") -> Dictionary:
	return f.apply_command({"contract_category":"singleplayer_space_travel","operation":op,"payload":payload,"request_id":id},{"runtime_authorized":true})
func quantum(authority: Object):
	var f=FLEET.new(); assert(f.configure().ok); f.register_craft("ship")
	assert(cmd(f,"launch_to_orbit",{"craft_id":"ship"},"launch").ok)
	assert(cmd(f,"start_quantum",{"craft_id":"ship","target_orbit_id":"planet_orbit"},"warp").ok)
	if authority!=null: assert(f.configure_space_area_transition_authority(authority).ok)
	return f
func ctx(f,id: String,operation: String="advance",delta: float=3.0,target: String="orbit_approach:planet") -> Dictionary:
	var payload: Dictionary={"craft_id":"ship","delta_seconds":delta} if operation=="advance" else {"craft_id":"ship"}
	return {"request_id":id,"request_signature":JSON.stringify({"operation":operation,"payload":payload},"",true),"operation":operation,"payload":payload,"source_area_id":"","target_area_id":target,"expected_travel_revision":int(f.get_snapshot("ship").revision),"expected_phase":String(f.get_snapshot("ship").phase),"context_id":"ctx:"+id}
func prepare(f,c: Dictionary) -> Dictionary:
	return f.prepare_space_area_transition("ship",c.expected_travel_revision,c.source_area_id,c.target_area_id,c)
func fingerprint(f) -> String:
	return JSON.stringify([f.get_snapshot("ship"),f._space_area_contexts,f._space_area_bindings,f._space_area_receipts],"",true)
func pose(f) -> String:
	var s: Dictionary=f.get_snapshot("ship")
	return JSON.stringify([s.position,s.origin_position,s.route_control,s.route_destination,s.heading],"",true)
func _initialize() -> void:
	var authority:=RefCounted.new(); var foreign:=RefCounted.new()
	var f=quantum(null); var c:=ctx(f,"complete")
	check(not prepare(f,c).ok and not f.bind_space_area_transition_context(c,authority).ok,"bool/unknown context cannot replace explicit in-process authority wiring")
	check(f.configure_space_area_transition_authority(authority).ok and not f.configure_space_area_transition_authority(foreign).ok and not f.bind_space_area_transition_context(c,foreign).ok,"authority cannot be taken over by second caller")
	assert(f.bind_space_area_transition_context(c,authority).ok)
	var before:=fingerprint(f); var candidate:=prepare(f,c)
	check(candidate.ok and fingerprint(f)==before,"actual prepare is mutation-free")
	var short:=ctx(f,"short","advance",0.5); assert(f.bind_space_area_transition_context(short,authority).ok)
	check(not prepare(f,short).ok,"only delta which actually completes current quantum can prepare")
	var wrong:=ctx(f,"wrongbody","advance",3.0,"orbit_approach:moon"); assert(f.bind_space_area_transition_context(wrong,authority).ok)
	var wrong_source:=ctx(f,"wrongsource"); wrong_source.source_area_id="surface:planet"; assert(f.bind_space_area_transition_context(wrong_source,authority).ok)
	check(not prepare(f,wrong).ok and not prepare(f,wrong_source).ok,"real target body and canonical empty source area bind candidates")
	var forged: Dictionary=candidate.duplicate(true); forged.state.next.phase="surface"
	var changed: Dictionary=c.duplicate(true); changed.payload.delta_seconds=4.0
	var changed_signature: Dictionary=c.duplicate(true); changed_signature.request_signature="changed"
	check(not f.commit_prepared_space_area_transition(forged,c).ok and not f.validate_prepared_space_area_transition(candidate,changed).ok and not f.bind_space_area_transition_context(changed_signature,authority).ok,"tampered state/payload and changed signature under same request reject")
	assert(cmd(f,"advance",{"craft_id":"ship","delta_seconds":0.25}).ok)
	check(not f.validate_prepared_space_area_transition(candidate,c).ok,"actual intervening travel advance invalidates old revision")
	var g=quantum(authority); var gc:=ctx(g,"ownerchange"); assert(g.bind_space_area_transition_context(gc,authority).ok); var old:=prepare(g,gc)
	g.unregister_craft("ship"); g.register_craft("ship")
	check(not g.commit_prepared_space_area_transition(old,gc).ok,"replacement craft owner cannot consume old candidate")
	var h=quantum(authority); var hc:=ctx(h,"noop-collision"); assert(h.bind_space_area_transition_context(hc,authority).ok); var pending:=prepare(h,hc)
	var revision: int=h.get_snapshot("ship").revision
	assert(cmd(h,"advance",{"craft_id":"ship","delta_seconds":0.0},hc.request_id).ok)
	check(h.get_snapshot("ship").revision==revision and not h.commit_prepared_space_area_transition(pending,hc).ok,"real no-op request-key consumption invalidates candidate even without revision change")
	var valid:=ctx(f,"final"); assert(f.bind_space_area_transition_context(valid,authority).ok); var staged:=prepare(f,valid)
	var old_pose:=pose(f); var committed: Dictionary=f.commit_prepared_space_area_transition(staged,valid)
	check(committed.ok and f.get_snapshot("ship").phase=="orbit" and f.get_snapshot("ship").orbit_id=="planet_orbit" and pose(f)==old_pose and not f._space_area_contexts.has(valid.context_id),"silent publish commits real phase/orbit, preserves pose and retires successful pending context")
	assert(cmd(f,"start_quantum",{"craft_id":"ship","target_orbit_id":"moon_orbit"},"next-flight").ok)
	assert(f.release_space_area_transition_context(valid.context_id,authority).ok)
	before=fingerprint(f); var retry:=prepare(f,valid); var replay: Dictionary=f.commit_prepared_space_area_transition(retry,valid)
	check(replay.get("replayed",false) and replay.revision==committed.revision and fingerprint(f)==before,"successful receipt retries after phase change and context release without new writes")
	var canceled:=ctx(f,"cancel","advance",3.0,"orbit_approach:moon"); assert(f.bind_space_area_transition_context(canceled,authority).ok); var canceled_candidate:=prepare(f,canceled)
	assert(f.release_space_area_transition_context(canceled.context_id,authority).ok)
	var released: bool=not f._space_area_contexts.has(canceled.context_id) and not f._space_area_bindings.has(canceled.request_id) and not f.validate_prepared_space_area_transition(canceled_candidate,canceled).ok
	assert(f.bind_space_area_transition_context(canceled,authority).ok)
	var rebound:=prepare(f,canceled)
	check(not f.validate_prepared_space_area_transition(canceled_candidate,canceled).ok and f.validate_prepared_space_area_transition(rebound,canceled).ok,"release/rebind never resurrects an older candidate with identical context content")
	f.configure()
	check(released and not f.validate_prepared_space_area_transition(staged,valid).ok and not f.bind_space_area_transition_context(valid,authority).ok,"cancel releases pending bindings and lifecycle reset invalidates contexts/candidates")
	var surface=FLEET.new(); surface.configure(); surface.configure_space_area_transition_authority(authority)
	assert(surface.commit_surface_registration(surface.prepare_surface_registration("ship","polisa","surface-init")).ok)
	var sc:=ctx(surface,"enter","enter_orbit",0.0,"orbit_approach:glut_2"); assert(surface.bind_space_area_transition_context(sc,authority).ok)
	var surface_pose:=pose(surface); var surface_result: Dictionary=surface.commit_prepared_space_area_transition(prepare(surface,sc),sc)
	var approach=quantum(authority); assert(cmd(approach,"advance",{"craft_id":"ship","delta_seconds":3.0}).ok); assert(cmd(approach,"begin_approach",{"craft_id":"ship","location_id":"fortified_outpost"},"approach").ok)
	var ac:=ctx(approach,"enter-approach","enter_orbit"); assert(approach.bind_space_area_transition_context(ac,authority).ok)
	check(surface_result.ok and surface.get_snapshot("ship").orbit_id=="polisa_orbit" and pose(surface)==surface_pose and approach.commit_prepared_space_area_transition(prepare(approach,ac),ac).ok,"surface and approach use their genuine location-bound orbit without pose writes")
	var rng=FLEET.new(); seed(123456); var expected:=randf(); seed(123456); rng.configure(); var observed:=randf()
	check(expected==observed,"new configure/context integrity consumes no global combat RNG")
	print("PREPARED_AREA_RESULT checks=",count," failures=",failures," runtime_wired=false")
	quit(1 if failures else 0)
