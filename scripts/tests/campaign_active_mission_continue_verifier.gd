extends "res://scripts/tests/campaign_legacy_satellite_boarding_verifier.gd"
## Actual deployed campaign, checkpoint, scene destruction and continue.
func _run() -> void:
 if OS.get_environment("POLISA_TEST_PROFILE").is_empty():
  printerr("isolated test profile required")
  quit(1)
  return
 OS.set_environment("CAMPAIGN_ACTIVE_TEST_ONLY","1")
 _configure_entry()
 _flow = FLOW.instantiate(); root.add_child(_flow)
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
 if not _check(captured.get("ok",false),"actual mission owners capture together"): print("CAPTURE_FAILURE ",captured); await _finish(); return
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
 var saved: Dictionary = campaign.save_active_checkpoint(_flow,_runtime,true)
 if not _check(saved.get("ok",false), "actual active mission checkpoint saved"): print("SAVE_FAILURE ",saved); await _finish(); return
 _flow.queue_free()
 await process_frame
 START.request_start(self,"campaign","continue")
 _flow = FLOW.instantiate(); root.add_child(_flow)
 await process_frame
 _screen = _flow.get_node("HomebaseScreen")
 _runtime = _flow.get("_singleplayer_runtime")
 if not await _wait(func(): return bool(_flow.get_meta("campaign_active_restore_complete",false)) or _flow.has_meta("campaign_active_restore_error"), 60000, "actual mission reconstruction reaches a decision"): await _finish(); return
 if not _check(bool(_flow.get_meta("campaign_active_restore_complete",false)) and is_instance_valid(_flow.get("_active_mission")),"actual mission is reconstructed on continue"):
  print("RESTORE_FAILURE ",_flow.get_meta("campaign_active_restore_error",{}))
  await _finish(); return
 var restored: Node = _flow.get("_active_mission")
 var restored_units: Node = restored.get_node("UnitRegistry")
 for id in before:
  var person = restored_units.get_unit(id)
  _check(is_instance_valid(person) and person.global_position.distance_to(before[id].position) < 0.1 and person.get_health()==before[id].health and person.get_vital_state()==before[id].vital, "same person, location and health restored: " + id)
 _check(String(_flow.call("get_singleplayer_snapshot").space_travel.phase) == "surface", "craft remains at actual mission surface")
 var after_campaign: Dictionary = _flow.call("get_singleplayer_snapshot")
 _check(after_campaign.supply.credits == before_campaign.supply.credits and after_campaign.supply.fuel_by_craft_id == before_campaign.supply.fuel_by_craft_id, "credits and craft fuel survive continue")
 _check(String(after_campaign.campaign.jobs.satellite_recovery.status) == "active", "accepted mission remains active without paying twice")
 var after_elapsed: float = restored.get_node("CombatLoopDriver").call("_get_duration_seconds")
 _check(after_elapsed >= before_elapsed - 0.1 and after_elapsed < before_elapsed + 10.0, "mission clock survives process reconstruction")
 _check(restored.get_node("CombatLoopDriver").get("mission_time_limit_seconds")==before_limit and restored.get_node("CombatLoopDriver").get("win_condition")==before_condition,"mission time limit and victory rule survive continue")
 var controller: Node = restored.get_node("TacticalController")
 controller.call("_set_selected_fireteams",PackedStringArray([_team_id]),false)
 if not await _move_and_use(restored,"satellite_data","secure_satellite","res://maps/satellite_crash_site.json"): await _finish(); return
 if not await _move_and_use(restored,"ship_return","return_to_ship","res://maps/satellite_crash_site.json"): await _finish(); return
 if not await _wait(func(): return String(Dictionary(_campaign().get("jobs",{})).get("satellite_recovery",{}).get("status","")) in ["pending_upload","completed"],45000,"restored mission reaches verified return or upload state"):
  var finished_driver: Node = restored.get_node("CombatLoopDriver")
  print("FINISH_DIAG driver_finished=",finished_driver.get("_combat_finished")," result=",finished_driver.call("get_mission_result")," gates=",finished_driver.call("get_mission_scenario_runtime_gate_snapshot")," pending=",_flow.get("_pending_campaign_mission_result")," contexts=",_flow.get("_location_contexts")," crew=",controller.call("get_campaign_air_support_pilot_guard",_craft_id)," departure_error=",_screen.get_meta("singleplayer_departure_error",{}))
  await _finish(); return
 if not await _return_home_after_continue(): await _finish(); return
 _flow.call("_show_homebase")
 var uploaded: Dictionary = _runtime.call("request_operation","campaign_upload",{"job_id":"satellite_recovery"})
 _check(uploaded.get("ok",false) and String(_campaign().jobs.satellite_recovery.status)=="completed","actual recovered chip uploads at home after continue")
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
 # Resume can place the real crew farther from the interaction than the
 # original fixture; allow the actual walk to finish without moving actors.
 var allowed := maxi(milliseconds,120000) if label.ends_with("becomes usable after real simulated approach") else milliseconds
 return await super._wait(predicate,allowed,label)

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
