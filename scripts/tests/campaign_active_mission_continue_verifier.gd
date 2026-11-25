extends "res://scripts/tests/campaign_legacy_satellite_boarding_verifier.gd"
## Actual deployed campaign, checkpoint, scene destruction and continue.
func _run() -> void:
 if OS.get_environment("POLISA_TEST_PROFILE").is_empty():
  printerr("isolated test profile required")
  quit(1)
  return
 if OS.get_environment("RUN_JOINED_ORBIT_TEST")=="1":
  OS.set_environment("CAMPAIGN_ACTIVE_TEST_ONLY","1")
  OS.set_environment("CAMPAIGN_ACTIVE_TEST_ORBIT","1")
 _configure_entry()
 _flow = FLOW.instantiate(); root.add_child(_flow)
 current_scene = _flow
 await process_frame
 _screen = _flow.get_node("HomebaseScreen")
 _runtime = _flow.get("_singleplayer_runtime")
 _identity_before = _identity(_screen.call("get_operations_snapshot"))
 if not await _prepare_initial_base(): await _finish(); return
 var craft: Dictionary = _screen.call("get_operations_snapshot").get("selected_craft", {})
 _craft_id = String(craft.get("id", "")); _pilot_id = String(craft.get("pilot_id", ""))
 var payload: Array = craft.get("payload_fireteam_ids", [])
 if not _check(not _craft_id.is_empty() and not payload.is_empty(), "real craft and team exist"): await _finish(); return
 _team_id = String(payload[0])
 for team: Dictionary in Array(_screen.call("get_operations_snapshot").get("fireteams", [])):
  if String(team.get("id", "")) == _team_id:
   for member: Dictionary in Array(team.get("members", [])): _crew_ids.append(String(member.id))
 if not _check(_screen.call("request_operation", "accept_job", {"job_id":"satellite_recovery", "request_id":"save-test:accept"}).get("ok", false), "real job accepted"): await _finish(); return
 if not _check(_screen.call("request_operation", "select_destination", {"location_id":"satellite_crash", "job_id":"satellite_recovery", "request_id":"save-test:dest"}).get("ok", false), "real destination selected"): await _finish(); return
 if not await _launch_and_land("satellite_recovery", "res://maps/satellite_crash_site.json"): await _finish(); return
 var mission: Node = _flow.get("_active_mission")
 var units: Node = mission.get_node("UnitRegistry")
 var before := {}
 for person in units.get_all_units():
  if person != null and person.get("unit_id") in ["campaign_leader","campaign_pilot"]:
   before[String(person.unit_id)] = {"position":person.global_position,"health":person.get_health(),"vital":person.get_vital_state()}
 if not _check(before.size() == 2, "both actual people present at destination"): await _finish(); return
 var original_driver: Node = mission.get_node("CombatLoopDriver")
 var before_elapsed: float = original_driver.call("_get_duration_seconds")
 var before_limit: float = original_driver.get("mission_time_limit_seconds")
 var before_condition: String = original_driver.get("win_condition")
 var before_campaign: Dictionary = _flow.call("get_singleplayer_snapshot")
 var capture = load("res://scripts/mission/campaign_active_mission_capture.gd")
 if capture == null:
  _check(false,"active mission owner capture exists")
  await _finish(); return
 var captured: Dictionary = capture.capture_components(_flow,_runtime)
 if not captured.get("ok",false):
  var mission_root: Node = mission.get_node("SimulationRoot")
  var home_root: Node = _runtime.get("_simulation")
  print("CAPTURE_INITIAL_WAIT ",captured," home_guard=",home_root.get_hex_checkpoint_guard()," mission_guard=",mission_root.get_hex_checkpoint_guard()," commands=",mission_root.command_queue," effects=",mission_root.effects_queue," facing=",mission_root._hex_facing_pending)
  var stable_deadline := Time.get_ticks_msec()+30000
  while not captured.get("ok",false) and Time.get_ticks_msec()<stable_deadline and String(captured.get("reason","")) in ["checkpoint_pending_work","checkpoint_clock_unsynced","checkpoint_pending_setup","mission_lifecycle_busy","mission_movement_pending","transport_transition_pending"]:
   await create_timer(0.1).timeout
   captured = capture.capture_components(_flow,_runtime)
 if not _check(captured.get("ok",false),"actual mission owners capture together"): print("CAPTURE_FAILURE ",captured); await _finish(); return
 for id in before:
  var person: Node2D = units.get_unit(id)
  before[id] = {"position":person.global_position,"health":person.get_health(),"vital":person.get_vital_state()}
 var preflight = load("res://scripts/mission/campaign_active_restore_preflight.gd")
 if preflight == null:
  _check(false,"detached world restore preflight exists")
  await _finish(); return
 var wire: Dictionary = JSON.parse_string(JSON.stringify(captured.components,"",true,true))
 var before_supply: Dictionary = _runtime.get("_supply").export_state()
 var candidate: Dictionary = preflight.prepare(wire,_runtime)
 if not _check(candidate.get("ok",false),"actual campaign owners prepare in a detached world"): print("PREFLIGHT_FAILURE ",candidate); await _finish(); return
 _check(_runtime.get("_supply").export_state() == before_supply,"world preflight leaves actual supply unchanged")
 candidate.root.free()
 var live_root: Node = _runtime.get("_simulation")
 var before_root_campaign = live_root.get("_singleplayer_campaign_owner")
 var actual_candidate: Dictionary = preflight.prepare(wire,_runtime,live_root)
 if not _check(actual_candidate.get("ok",false),"active world prepares against the existing root without replacing it"): print("LIVE_PREFLIGHT_FAILURE ",actual_candidate); await _finish(); return
 _check(actual_candidate.root == live_root and not actual_candidate.owned_root,"live preflight retains home root identity")
 _check(live_root.get("_singleplayer_campaign_owner") == before_root_campaign and _runtime.get("_supply").export_state() == before_supply,"prebinding does not publish new owners or mutate live supply")
 var forged: Dictionary = wire.duplicate(true)
 forged.route_bindings.departure_token = "forged"
 _check(not preflight.prepare(forged,_runtime,live_root).get("ok",false),"mismatched departure token is rejected before publication")
 forged = wire.duplicate(true)
 forged.base_personnel.units[_pilot_id].status = "outside"
 _check(not preflight.prepare(forged,_runtime,live_root).get("ok",false),"inconsistent home personnel state is rejected before publication")
 # Abschnitt SB: Ein Basisstand darf einen Ort mit neuer Karte frisch beginnen, ein laufender Einsatz nicht (seine Welt gehoert zur alten Karte).
 forged = wire.duplicate(true)
 forged.campaign.locations.satellite_crash.map_file_path = "res://maps/satellite_crash_site_alt.json"
 var relocated_world: Dictionary = preflight.prepare(forged,_runtime,live_root)
 _check(not relocated_world.get("ok",false) and String(relocated_world.get("reason","")) == "stale_campaign_definitions","active world whose place got another map path is rejected with stale_campaign_definitions")
 # Gegenprobe: nur der Anzeigename des Einsatzortes weicht ab, das ist kein Kartenwechsel und wird nicht abgelehnt.
 forged = wire.duplicate(true)
 forged.campaign.locations.satellite_crash.name = "Anderer Name der Absturzstelle"
 var renamed_world: Dictionary = preflight.prepare(forged,_runtime,live_root)
 _check(renamed_world.get("ok",false),"active world whose place only has another display name still prepares (%s)" % [renamed_world.get("reason","")])
 _check(live_root.get("_singleplayer_campaign_owner") == before_root_campaign and _runtime.get("_supply").export_state() == before_supply,"rejected world candidates leave live owners untouched")
 var campaign = _flow.get("_campaign_start")
 var scene_factory = load("res://scripts/mission/campaign_active_scene_preflight.gd")
 var current_home: Dictionary = load("res://scripts/meta/campaign_checkpoint_store.gd").load_checkpoint()
 var staged: Dictionary = scene_factory.instantiate_scene(wire,current_home.get("payload",{}))
 if not _check(staged.get("ok",false),"fresh unpublished mission scene can be instantiated"): print("SCENE_FACTORY_FAILURE ",staged); await _finish(); return
 var staged_scene: Node = staged.scene
 staged_scene.hide()
 staged_scene.get_node("SimulationRoot").process_mode = Node.PROCESS_MODE_ALWAYS
 staged_scene.get_node("CombatLoopDriver").process_mode = Node.PROCESS_MODE_ALWAYS
 root.add_child(staged_scene)
 for i in range(5):
  await physics_frame
 staged_scene.get_node("SimulationRoot").process_mode = Node.PROCESS_MODE_DISABLED
 staged_scene.get_node("CombatLoopDriver").process_mode = Node.PROCESS_MODE_DISABLED
 var staged_candidate: Dictionary = scene_factory.prepare(staged_scene,wire)
 if not _check(staged_candidate.get("ok",false),"fresh mission actors, ground, lifecycle and ship prepare together"):
  print("SCENE_PREFLIGHT_FAILURE ",staged_candidate)
  staged_scene.queue_free(); await _finish(); return
 _check(scene_factory.validate(staged_candidate).get("ok",false),"unpublished scene candidates remain valid")
 var transaction = load("res://scripts/mission/campaign_active_world_transaction.gd")
 var joined: Dictionary = transaction.prepare(wire,_runtime,staged_scene)
 if not _check(joined.get("ok",false),"real mission and strategic world preflight against the existing root"):
  print("JOIN_PREFLIGHT_FAILURE ",joined)
  staged_scene.queue_free(); await _finish(); return
 _check(transaction.validate(joined).get("ok",false),"joined owners and root bindings remain fresh")
 staged_scene.queue_free()
 var envelope := {"schema":"campaign_active_checkpoint.v1", "components":wire}
 var validator = load("res://scripts/mission/campaign_active_checkpoint_validation.gd")
 var domain_check: Dictionary = validator.validate_live(envelope,_flow,_runtime)
 _check(domain_check.get("ok",false),"actual live world and scene pass private checkpoint validation")
 if not domain_check.get("ok",false): print("DOMAIN_VALIDATION_FAILURE ",domain_check)
 if not campaign.has_method("save_active_checkpoint"):
  _check(false,"active mission checkpoint path exists")
  await _finish(); return
 print("JSON_NATIVE_ISSUE ",_json_issue(captured.components,"components"))
 var normalized_debug: Dictionary = load("res://scripts/mission/campaign_active_json_normalizer.gd").normalize(captured.components)
 if normalized_debug.get("ok",false):
  var evidence := FileAccess.open("user://active_components_debug.json",FileAccess.WRITE)
  if evidence != null:
   evidence.store_string(JSON.stringify(normalized_debug.value,"",true,true))
   evidence.close()
 var menu: Node = root.get_node("GlobalEscapeMenu")
 var saved: Dictionary = menu.call("save_current_mission_slot")
 if not _check(saved.get("ok",false), "actual active mission checkpoint saved"): print("SAVE_FAILURE ",saved); await _finish(); return
 var active_saved_file: String = load("res://scripts/meta/campaign_active_checkpoint_store.gd").DEFAULT_PATH
 var saved_wire: Variant = JSON.parse_string(FileAccess.get_file_as_string(active_saved_file))
 if not _check(saved_wire is Dictionary and saved_wire.get("components") is Dictionary,"actual saved file contains mission lifecycle"): await _finish(); return
 var saved_elapsed := float(saved_wire.components.lifecycle.elapsed_msec) / 1000.0
 _check(saved_elapsed >= before_elapsed - 0.1,"saved time reflects the actual save rather than earlier preflight")
 _flow.queue_free()
 await process_frame
 START.request_start(self,"campaign","continue")
 _flow = FLOW.instantiate(); root.add_child(_flow)
 current_scene = _flow
 await process_frame
 _screen = _flow.get_node("HomebaseScreen")
 _runtime = _flow.get("_singleplayer_runtime")
 if not await _wait(func(): return bool(_flow.get_meta("campaign_active_restore_complete",false)) or _flow.has_meta("campaign_active_restore_error"), 60000, "actual mission reconstruction reaches a decision"): await _finish(); return
 if not _check(bool(_flow.get_meta("campaign_active_restore_complete",false)) and is_instance_valid(_flow.get("_active_mission")),"actual mission is reconstructed on continue"):
  print("RESTORE_FAILURE ",_flow.get_meta("campaign_active_restore_error",{}))
  await _finish(); return
 # M4d P1: nach dem Fortsetzen MITTEN im Einsatz zaehlt der Magazinvorrat der Kampagne (Schalter an der lebenden Versorgung).
 _check(bool(_runtime.get("_supply").get("_campaign_magazine_mode")) and bool(_runtime.get("_supply").call("person_has_magazine_store","campaign_leader")),"M4d: Kampagnen-Schalter des Magazinvorrats nach Fortsetzen mitten im Einsatz wahr")
 var restored: Node = _flow.get("_active_mission")
 # M4e: auch am Root der wiederhergestellten Einsatzszene zaehlt der Magazinvorrat der Person (schmale Bindung), nicht nur am Heim-Adapter.
 var restored_root: Node = restored.get_node("SimulationRoot")
 _check(bool(restored_root.call("person_has_magazine_store","campaign_leader")) and int(restored_root.call("get_person_magazine_count","campaign_leader","ammo_light")) == int(_runtime.get("_supply").call("person_magazine_count","campaign_leader","ammo_light")),"M4e: Einsatz-Root nach Fortsetzen mitten im Einsatz: Magazinvorrat der Person ist dort wahr und gleich der Kampagnen-Versorgung")
 var restored_units: Node = restored.get_node("UnitRegistry")
 for id in before:
  var person = restored_units.get_unit(id)
  _check(is_instance_valid(person) and person.global_position.distance_to(before[id].position) < 0.1 and person.get_health()==before[id].health and person.get_vital_state()==before[id].vital, "same person, location and health restored: " + id)
 _check(String(_flow.call("get_singleplayer_snapshot").space_travel.phase) == "surface", "craft remains at actual mission surface")
 var after_campaign: Dictionary = _flow.call("get_singleplayer_snapshot")
 _check(after_campaign.supply.credits == before_campaign.supply.credits and after_campaign.supply.fuel_by_craft_id == before_campaign.supply.fuel_by_craft_id, "credits and craft fuel survive continue")
 _check(String(after_campaign.campaign.jobs.satellite_recovery.status) == "active", "accepted mission remains active without paying twice")
 var after_elapsed: float = restored.get_node("CombatLoopDriver").call("_get_duration_seconds")
 _check(after_elapsed >= saved_elapsed - 0.1 and after_elapsed < saved_elapsed + 10.0, "mission clock survives process reconstruction")
 _check(restored.get_node("CombatLoopDriver").get("mission_time_limit_seconds")==before_limit and restored.get_node("CombatLoopDriver").get("win_condition")==before_condition,"mission time limit and victory rule survive continue")
 var controller: Node = restored.get_node("TacticalController")
 controller.call("_set_selected_fireteams",PackedStringArray([_team_id]),false)
 if not await _move_and_use(restored,"satellite_data","secure_satellite","res://maps/satellite_crash_site.json"): await _finish(); return
 var access:Dictionary=controller.get_campaign_ground_ship_access(_craft_id)
 var real_actor:Node=restored_units.get_unit(_crew_ids[0])
 var claimed:Dictionary={"interaction_id":"ship_return","unit_id":_crew_ids[0],"team_id":real_actor.get_team_id(),"fireteam_id":real_actor.get_fireteam_id(),"target_position":Vector2(-9999,-9999),"interaction_radius_world":99999.0,"duration_seconds":0.0}
 var host_resolution:Dictionary=restored.get_node("CombatLoopDriver")._resolve_host_network_interaction(claimed)
 _check(host_resolution.get("accepted",false) and host_resolution.command.target_position==access.get("position") and host_resolution.command.interaction_radius_world==96.0 and host_resolution.command.duration_seconds>0.0,"actual host Return resolver ignores forged target radius and duration and shares physical access")
 claimed.unit_id="foreign_missing_actor"
 _check(not restored.get_node("CombatLoopDriver")._resolve_host_network_interaction(claimed).get("accepted",false),"actual host Return resolver rejects foreign actor after access projection")
 if not await _move_and_use(restored,"ship_return","return_to_ship","res://maps/satellite_crash_site.json"): await _finish(); return
 if not await _wait(func(): return String(Dictionary(_campaign().get("jobs",{})).get("satellite_recovery",{}).get("status","")) in ["pending_upload","completed"],45000,"restored mission reaches verified return or upload state"):
  var finished_driver: Node = restored.get_node("CombatLoopDriver")
  print("FINISH_DIAG driver_finished=",finished_driver.get("_combat_finished")," result=",finished_driver.call("get_mission_result")," gates=",finished_driver.call("get_mission_scenario_runtime_gate_snapshot")," pending=",_flow.get("_pending_campaign_mission_result")," contexts=",_flow.get("_location_contexts")," crew=",controller.call("get_campaign_air_support_pilot_guard",_craft_id)," departure_error=",_screen.get_meta("singleplayer_departure_error",{}))
  await _finish(); return
 if not await _return_home_after_continue(): await _finish(); return
 _flow.call("_show_homebase")
 var uploaded: Dictionary = _runtime.call("request_operation","campaign_upload",{"job_id":"satellite_recovery"})
 _check(uploaded.get("ok",false) and String(_campaign().jobs.satellite_recovery.status)=="completed","actual recovered chip uploads at home after continue")
 var active_path: String = load("res://scripts/meta/campaign_active_checkpoint_store.gd").DEFAULT_PATH
 var active_bytes: PackedByteArray = FileAccess.get_file_as_bytes(active_path)
 var home_saved: Dictionary = _flow.get("_campaign_start").save_home_checkpoint(_flow,_runtime,true)
 if not _check(home_saved.get("ok",false),"new home checkpoint saves after real upload"): print("HOME_SAVE_FAILURE ",home_saved); await _finish(); return
 _check(not active_bytes.is_empty() and FileAccess.get_file_as_bytes(active_path)==active_bytes,"successful home save preserves the previous active file")
 _flow.queue_free()
 await process_frame
 START.request_start(self,"campaign","continue")
 _flow = FLOW.instantiate(); root.add_child(_flow); current_scene = _flow
 await process_frame
 _screen = _flow.get_node("HomebaseScreen"); _runtime = _flow.get("_singleplayer_runtime")
 _check(not bool(_flow.get("_campaign_start").get("active_restore_in_progress")) and _flow.get("_active_mission")==null and String(_campaign().jobs.satellite_recovery.status)=="completed","normal continue chooses the newer home checkpoint over the stale active file")
 _check(FileAccess.get_file_as_bytes(active_path)==active_bytes,"stale active file remains untouched")
 await _finish()

func _return_home_after_continue() -> bool:
 var orbit: String = String(Dictionary(_space().get("location_orbits",{})).get("satellite_crash",""))
 if not await _wait(func(): return String(_space().get("phase",""))=="orbit" and String(_space().get("orbit_id",""))==orbit,60000,"restored crew actually reaches departure orbit"): return false
 var jump: Dictionary = _screen.call("request_operation","space_start_quantum",{"craft_id":_craft_id,"target_orbit_id":"moon_orbit"})
 if not _check(jump.get("ok",false),"restored ship accepts homeward warp"): print("HOME_WARP_FAILURE ",jump); return false
 if not await _wait(func(): return String(_space().get("phase",""))=="orbit" and String(_space().get("orbit_id",""))=="moon_orbit",180000,"restored ship reaches home orbit"): return false
 var land: Dictionary = _screen.call("request_operation","space_land_homebase",{"craft_id":_craft_id})
 if not _check(land.get("ok",false),"restored ship accepts home landing"): print("HOME_LANDING_FAILURE ",land); return false
 return await _wait(func():
  var state: Dictionary = _flow.call("get_singleplayer_snapshot")
  var ship: Dictionary = _craft(state)
  return String(ship.get("location_id",""))=="homebase" and not bool(ship.get("busy",true)),60000,"restored crew actually returns and lands at home")

func _wait(predicate: Callable, milliseconds: int, label: String) -> bool:
 if label.ends_with("actual timed Use commits required runtime step") or label.ends_with("becomes usable after real simulated approach"):
  var deadline := Time.get_ticks_msec() + (maxi(milliseconds,180000) if label.ends_with("becomes usable after real simulated approach") else milliseconds)
  var next_trace := 0
  while Time.get_ticks_msec() < deadline:
   if bool(predicate.call()): return _check(true,label)
   if Time.get_ticks_msec() >= next_trace:
    _trace_active_interaction(label)
    next_trace = Time.get_ticks_msec() + 5000
   await physics_frame
  _trace_active_interaction("TIMEOUT " + label)
  return _check(false,"TIMEOUT " + label)
 # Resume can place the real crew farther from the interaction than the
 # original fixture; allow the actual walk to finish without moving actors.
 var allowed := maxi(milliseconds,180000) if label.ends_with("becomes usable after real simulated approach") or label.ends_with("actual mission instance exists") else milliseconds
 return await super._wait(predicate,allowed,label)

func _trace_active_interaction(label: String) -> void:
 var mission: Node = _flow.get("_active_mission")
 if not is_instance_valid(mission): return
 var controller: Node = mission.get_node("TacticalController")
 var simulation: Node = mission.get_node("SimulationRoot")
 var driver: Node = mission.get_node("CombatLoopDriver")
 var units: Array = []
 for id: String in _crew_ids:
  var actor: Node = mission.get_node("UnitRegistry").get_unit(id)
  if not is_instance_valid(actor): continue
  var command = actor.call("get_current_unit_command")
  units.append({"id":id,"position":actor.global_position,"ground":simulation.call("get_hex_unit_state",id),"vital":actor.call("get_vital_state"),"command":command.to_dict() if command != null and command.has_method("to_dict") else str(command)})
 print("ACTIVE_USE_TRACE ",var_to_str({"label":label,"execution":controller.get("_phase_execution_by_fireteam"),"plans":controller.call("_serialize_order_plans"),"movement":controller.call("get_fireteam_movement_snapshot"),"use":controller.call("get_mission_interaction_runtime_use_state_snapshot"),"feedback":controller.call("get_mission_interaction_use_feedback_snapshot"),"runtime":driver.call("get_mission_interaction_runtime_states"),"units":units}))

func _finish() -> void:
 if is_instance_valid(_flow): _flow.queue_free()
 await process_frame
 print("CAMPAIGN_ACTIVE_CONTINUE passed=%d failed=%d" % [_passed,_failed])
 if _failed == 0: print("CAMPAIGN_ACTIVE_CONTINUE_PASS")
 quit(1 if _failed else 0)

func _json_issue(value: Variant,path: String,depth: int = 0) -> String:
 if depth > 32: return path + ":depth"
 match typeof(value):
  TYPE_NIL,TYPE_BOOL,TYPE_STRING,TYPE_STRING_NAME,TYPE_INT: return ""
  TYPE_FLOAT: return "" if is_finite(value) else path + ":nonfinite"
  TYPE_ARRAY:
   for index in range(value.size()):
    var issue := _json_issue(value[index],path + "[" + str(index) + "]",depth+1)
    if not issue.is_empty(): return issue
   return ""
  TYPE_DICTIONARY:
   for key in value:
    if typeof(key) not in [TYPE_STRING,TYPE_STRING_NAME]: return path + ":keytype=" + type_string(typeof(key))
    var issue := _json_issue(value[key],path + "." + str(key),depth+1)
    if not issue.is_empty(): return issue
   return ""
 return path + ":" + type_string(typeof(value))


## Fall b) Handflug (Vorgabe im Spiel, ohne Wahl): das Schiff steht nach dem Sprung im Eintrittsband unten, der Anflug wird abgelehnt (not_at_approach_gate);
## dann fliegt der Pruefer es mit dem Bewegungsbefehl der Orbit-Karte (space_move) zu einer Torzelle am Planetenrand und nimmt den Anflug erst bei der Ankunft an.
## Fall a) Automatisch steht im Elternablauf (ausdruecklich eingestellt); mit ORBIT_TEST_AUTOMATIC=1 faehrt auch dieser Pruefer so.
func _begin_orbit_approach(scenario_id: String, destination: String) -> Dictionary:
 if not bool(_runtime.get("_surface_orbit_path_enabled")) or OS.get_environment("ORBIT_TEST_AUTOMATIC") == "1":
  return await super._begin_orbit_approach(scenario_id, destination)
 _check(not bool(_space().get("orbit_transit_automatic", true)), scenario_id + " Handflug ist ohne Wahl die Vorgabe")
 var early: Dictionary = _screen.call("request_operation", "space_begin_approach", {"craft_id": _craft_id, "location_id": destination, "request_id": "hand:early:" + scenario_id + _launch_tag})
 _check(not bool(early.get("ok", false)) and String(early.get("reason", "")) == "not_at_approach_gate", scenario_id + " Handflug: Anflug im Eintrittsband unten wird abgelehnt (%s)" % str(early))
 var orbit_id := String(_space().get("orbit_id", ""))
 var body_id := String(Dictionary(Dictionary(_space().get("orbits", {})).get(orbit_id, {})).get("body_id", ""))
 var gates: Array = preload("res://scripts/mission/orbit_approach_layout.gd").gate_cells(body_id)
 if gates.is_empty(): _check(false, scenario_id + " Handflug: Torzellen vorhanden"); return {"ok": false, "reason": "no_gate_cells"}
 var target: Vector2i = preload("res://scripts/core/strategic_hex_grid.gd").from_offset(gates[gates.size() / 2])
 var move: Dictionary = _runtime.call("request_operation", "space_move", {"craft_id": _craft_id, "target_hex": target, "request_id": "hand:move:" + scenario_id + _launch_tag})
 _check(bool(move.get("ok", false)), scenario_id + " Handflug: Bewegung zur Torzelle angenommen (%s)" % str(move))
 var state := {"frames": 0, "result": {}}
 var predicate := func() -> bool:
  state.frames += 1
  if state.frames % 30 != 0: return false
  var attempt: Dictionary = _screen.call("request_operation", "space_begin_approach", {"craft_id": _craft_id, "location_id": destination, "request_id": "hand:try:%d:%s%s" % [state.frames, scenario_id, _launch_tag]})
  state.result = attempt
  return bool(attempt.get("ok", false))
 var arrived: bool = await _wait(predicate, 120000, scenario_id + " Handflug: Schiff erreicht die Torzelle, danach wird der Anflug angenommen")
 return state.result if arrived else {"ok": false, "reason": "gate_not_reached", "last": state.result}
