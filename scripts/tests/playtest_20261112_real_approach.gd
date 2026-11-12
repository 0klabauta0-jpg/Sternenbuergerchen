extends "res://scripts/tests/campaign_air_support_real_mission_verifier.gd"
## Isolated APPDATA only: actual campaign takeoff, jump, approach and landing.
func _run() -> void:
 _configure_entry()
 _flow = FLOW.instantiate(); root.add_child(_flow)
 await process_frame
 _screen = _flow.get_node("HomebaseScreen"); _runtime = _flow.get("_singleplayer_runtime")
 if not await _prepare_initial_base(): await _finish(); return
 var operations: Dictionary = _screen.call("get_operations_snapshot")
 var craft: Dictionary = operations.get("selected_craft", {})
 _craft_id = String(craft.get("id", "")); _pilot_id = String(craft.get("pilot_id", ""))
 var payload: Array = craft.get("payload_fireteam_ids", [])
 if not _check(not _craft_id.is_empty() and not payload.is_empty(), "actual ship and team available"): await _finish(); return
 _team_id = String(payload[0])
 for team: Dictionary in Array(operations.get("fireteams", [])):
  if String(team.id) == _team_id:
   for member: Dictionary in Array(team.members): _crew_ids.append(String(member.id))
 if not _check(_screen.call("request_operation", "accept_job", {"job_id":"satellite_recovery"}).get("ok", false), "accept satellite job"): await _finish(); return
 if not _check(_screen.call("request_operation", "select_destination", {"location_id":"satellite_crash", "job_id":"satellite_recovery"}).get("ok", false), "select satellite destination"): await _finish(); return
 await _launch_and_land("satellite_recovery", "res://maps/satellite_crash_site.json")
 await _finish()
