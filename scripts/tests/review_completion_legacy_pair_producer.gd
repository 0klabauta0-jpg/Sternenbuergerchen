extends "res://scripts/tests/campaign_active_mission_continue_verifier.gd"
## Produces an authentic private old-format pair and stops before return/new game.
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
 var menu: Node = root.get_node("GlobalEscapeMenu")
 var saved: Dictionary = menu.call("save_current_mission_slot")
 if not _check(saved.get("ok",false), "actual active mission checkpoint saved"): print("SAVE_FAILURE ",saved); await _finish(); return
 print("LEGACY_SOURCE_SAVE_PAIR passed=%d failed=%d" % [_passed,_failed])
 await _finish()
