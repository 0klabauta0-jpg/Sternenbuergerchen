extends "res://scripts/tests/campaign_legacy_satellite_boarding_verifier.gd"
## Actual deployed campaign, checkpoint, scene destruction and continue.
func _run() -> void:
 if OS.get_environment("POLISA_TEST_PROFILE").is_empty():
  printerr("isolated test profile required")
  quit(1)
  return
 _configure_entry()
 _flow = FLOW.instantiate(); root.add_child(_flow)
 await process_frame
 _screen = _flow.get_node("HomebaseScreen")
 _runtime = _flow.get("_singleplayer_runtime")
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
 var campaign = _flow.get("_campaign_start")
 if not campaign.has_method("save_active_checkpoint"):
  _check(false,"active mission checkpoint path exists")
  await _finish(); return
 var saved: Dictionary = campaign.save_active_checkpoint(_flow,_runtime,true)
 if not _check(saved.get("ok",false), "actual active mission checkpoint saved"): print("SAVE_FAILURE ",saved); await _finish(); return
 _flow.queue_free()
 await process_frame
 START.request_start(self,"campaign","continue")
 _flow = FLOW.instantiate(); root.add_child(_flow)
 await process_frame
 if not await _wait(func(): return is_instance_valid(_flow.get("_active_mission")), 60000, "actual mission is reconstructed on continue"): await _finish(); return
 var restored: Node = _flow.get("_active_mission")
 var restored_units: Node = restored.get_node("UnitRegistry")
 for id in before:
  var person = restored_units.get_unit(id)
  _check(is_instance_valid(person) and person.global_position.distance_to(before[id].position) < 0.1 and person.get_health()==before[id].health and person.get_vital_state()==before[id].vital, "same person, location and health restored: " + id)
 _check(String(_flow.call("get_singleplayer_snapshot").space_travel.phase) == "surface", "craft remains at actual mission surface")
 await _finish()

func _finish() -> void:
 if is_instance_valid(_flow): _flow.queue_free()
 await process_frame
 print("CAMPAIGN_ACTIVE_CONTINUE passed=%d failed=%d" % [_passed,_failed])
 if _failed == 0: print("CAMPAIGN_ACTIVE_CONTINUE_PASS")
 quit(1 if _failed else 0)
