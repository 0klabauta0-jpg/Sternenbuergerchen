extends "res://scripts/tests/campaign_legacy_satellite_boarding_verifier.gd"
## Actual unmodified satellite journey followed by detached receipt owner restore.
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
 _test_receipts()
 print("ROOT_RECEIPT_TRUE_JOURNEY_PASS" if _failed == 0 else "ROOT_RECEIPT_TRUE_JOURNEY_FAIL")
 await _finish()

func _test_receipts() -> void:
 var helper = load("res://scripts/mission/root_receipt_checkpoint.gd")
 var source: Node = _runtime.get("_simulation")
 var bindings := {"fleet":_runtime.get("_travel"),"supply":_runtime.get("_supply"),"campaign":_runtime.get("_campaign"),"equipment":_runtime.get("_ship_equipment"),"adapter":_runtime}
 print("ROOT_RECEIPT_COUNTS launch=",source._launch_receipts.size()," departure=",source._departure_group_receipts.size())
 if not _check(source._launch_receipts.size()==1 and source._departure_group_receipts.size()==1,"actual journey produced one launch and departure receipt"): return
 var captured: Dictionary = helper.capture(source,bindings)
 print("ROOT_RECEIPT_CAPTURE ",captured.get("schema",captured.get("reason","unknown")))
 if not _check(captured.get("schema")=="root_receipt_checkpoint.v1","actual finalized Root receipts export"): return
 var wire: Dictionary = JSON.parse_string(JSON.stringify(captured,"",true,true))
 var fleet_state: Dictionary = bindings.fleet.export_checkpoint_state()
 if not _check(fleet_state.get("schema")=="space_fleet_checkpoint.v1","actual landed Fleet checkpoint exports"): return
 var rebuilt: Dictionary = bindings.fleet.prepare_checkpoint_restore(fleet_state,fleet_state.crafts.keys())
 if not _check(rebuilt.get("ok",false),"actual Fleet checkpoint restores detached owners"): return
 var sim: Node = load("res://scripts/core/simulation_root.gd").new()
 root.add_child(sim); sim.set_physics_process(false)
 var supply = load("res://scripts/core/singleplayer_supply_state.gd").new()
 var campaign = load("res://scripts/core/singleplayer_campaign_state.gd").new()
 var equipment = load("res://scripts/core/singleplayer_ship_equipment_state.gd").new()
 var supply_data: Dictionary = bindings.supply.export_state()
 if not _check(supply.restore_state(supply_data).ok,"legitimate fresh Supply restores real request receipts"): sim.free(); return
 if not _check(campaign.restore_state(bindings.campaign.export_state()).ok,"legitimate fresh Campaign restores real departure and requests"): sim.free(); return
 if not _check(equipment.restore_state(bindings.equipment.export_state(),Array(_flow.get("_homebase_aircraft_definitions")),supply_data.requests,supply_data.inventory).ok,"legitimate fresh Equipment restores canonical loadouts"): sim.free(); return
 var target := {"fleet":rebuilt.candidate,"supply":supply,"campaign":campaign,"equipment":equipment,"adapter":_runtime}
 _check(target.fleet.configure_space_area_transition_authority(sim).ok,"restored Fleet authority binds target Root")
 _check(supply.bind_route_fuel_preparation_authority(sim),"restored Supply authority binds target Root")
 _check(campaign.configure_departure_preparation_authority(sim).ok,"restored Campaign authority binds target Root")
 var before := _owner_values(target)
 var wrong_owner := target.duplicate(); wrong_owner.fleet=RefCounted.new()
 _check(not helper.prepare(sim,wire,wrong_owner).ok,"unrelated fake owner rejects without dynamic call")
 var prepared: Dictionary = helper.prepare(sim,wire,target)
 print("ROOT_RECEIPT_PREPARE ",prepared.get("reason","ok"))
 if not _check(prepared.get("ok",false),"JSON Root receipt candidate prepares before owner publication"): sim.free(); return
 _check(before==_owner_values(target) and sim._launch_receipts.is_empty() and sim._departure_group_receipts.is_empty(),"preparation changes no owner or Root receipts")
 _check(not helper.validate(sim,prepared.candidate,target).ok,"validation rejects unpublished Root owner bindings")
 sim.configure_singleplayer_owners(campaign,supply,null,target.fleet)
 sim.configure_ship_equipment(equipment)
 _check(sim.configure_departure_adapter(_runtime).ok,"actual adapter binds target Root")
 _check(helper.validate(sim,prepared.candidate,target).ok,"final owner bindings and fresh replay candidates validate")
 var wrong := target.duplicate(); wrong.equipment=bindings.equipment
 _check(not helper.validate(sim,prepared.candidate,wrong).ok,"changed owner pointer rejects stale candidate")
 var data: Dictionary = load("res://scripts/mission/checkpoint_value_codec.gd").decode_value(wire.value).value
 var launch_id: String = data.launch.keys()[0]
 var departure_id: String = data.departure.keys()[0]
 var modified := data.duplicate(true); modified.launch[launch_id].event_published=false
 _check(not helper.prepare(sim,_wire_data(modified),target).ok,"unpublished launch rejects checkpoint")
 modified=data.duplicate(true); modified.departure[departure_id].events_published=false
 _check(not helper.prepare(sim,_wire_data(modified),target).ok,"unpublished departure rejects checkpoint")
 modified=data.duplicate(true); modified.launch[launch_id].result.travel_result["ok"]=false
 _check(not helper.prepare(sim,_wire_data(modified),target).ok,"forged Fleet result rejects checkpoint")
 modified=data.duplicate(true); modified.departure[departure_id].events[0].command.request_id="fake"
 _check(not helper.prepare(sim,_wire_data(modified),target).ok,"unmatched fuel request rejects checkpoint")
 modified=data.duplicate(true); modified.departure[departure_id].approach_request_id="fake"
 _check(not helper.prepare(sim,_wire_data(modified),target).ok,"unmatched approach rejects checkpoint")
 var fuel_id: String = data.departure[departure_id].events[0].command.request_id
 var fuel_receipt: Dictionary = supply._requests[fuel_id].duplicate(true)
 supply._requests[fuel_id].signature="fake"
 _check(not helper.validate(sim,prepared.candidate,target).ok,"changed underlying fuel signature rejects stale candidate")
 supply._requests[fuel_id]=fuel_receipt
 _check(helper.validate(sim,prepared.candidate,target).ok,"restored legitimate request validates again")
 var original_credits: int = supply._credits
 supply._credits+=1
 _check(not helper.validate(sim,prepared.candidate,target).ok,"unrelated owner mutation rejects prepared global candidate")
 supply._credits=original_credits
 _check(helper.validate(sim,prepared.candidate,target).ok,"exact legitimate owner baseline validates before nofail tail")
 helper.publish(sim,prepared.candidate)
 _check(not helper.validate(sim,prepared.candidate,target).ok,"published candidate cannot be reused")
 _check(not helper.prepare(sim,wire,target).ok,"committed target receipts cannot be silently overwritten")
 var events: Array=[]
 sim.singleplayer_command_committed.connect(func(command: Dictionary,result: Dictionary): events.append([command,result]))
 var departure: Dictionary = data.departure[departure_id]
 var launch_replay: Dictionary=sim.commit_singleplayer_space_launch(_runtime,data.launch[launch_id].craft_id,launch_id)
 var departure_replay: Dictionary=sim.commit_singleplayer_departure(_runtime,departure.craft_id,departure_id,departure.approach_request_id,departure.station_dock)
 print("ROOT_RECEIPT_REPLAY launch=",launch_replay.get("replayed",false)," departure=",departure_replay.get("replayed",false))
 _check(launch_replay.get("ok",false) and launch_replay.get("replayed",false),"same real launch request replays after fresh-owner restoration")
 _check(departure_replay.get("ok",false) and departure_replay.get("replayed",false),"same real departure request replays after fresh-owner restoration")
 sim.publish_singleplayer_space_launch_event(_runtime,launch_id)
 sim.publish_singleplayer_departure_events(_runtime,departure_id)
 _check(before==_owner_values(target),"replays repeat no fuel, Campaign or Flight mutation")
 _check(events.is_empty(),"finalized events are not published twice")
 _check(not sim.commit_singleplayer_space_launch(_runtime,"foreign",launch_id).ok,"same launch with foreign craft rejects")
 _check(not sim.commit_singleplayer_departure(_runtime,departure.craft_id,departure_id,departure.approach_request_id,not departure.station_dock).ok,"changed station flags reject")
 var recapture: Dictionary=helper.capture(sim,target)
 _check(recapture==captured,"restored Root semantic checkpoint exactly matches actual source")
 var held: Dictionary=sim._launch_receipts[launch_id]
 held.event_published=false
 _check(not helper.capture(sim,target).get("schema","")=="root_receipt_checkpoint.v1","capture rejects unfinished event publication")
 held.event_published=true
 sim._warp_completion_intents["pending"]={}
 _check(not helper.capture(sim,target).has("schema"),"pending warp intent rejects capture")
 sim._warp_completion_intents.clear()
 sim._space_fire_receipts["unsupported"]={"result":{"ok":true}}
 _check(not helper.capture(sim,target).has("schema"),"capture fails closed on unsupported committed receipts")
 sim.free()

func _wire_data(data: Dictionary) -> Dictionary:
 return {"schema":"root_receipt_checkpoint.v1","value":load("res://scripts/mission/checkpoint_value_codec.gd").encode_value(data).value}
func _owner_values(bindings: Dictionary) -> Dictionary:
 return {"fleet":bindings.fleet.export_checkpoint_state(),"supply":bindings.supply.export_state(),"campaign":bindings.campaign.export_state(),"equipment":bindings.equipment.export_state()}
func _finish() -> void:
 if is_instance_valid(_flow): _flow.queue_free()
 await process_frame
 print("ROOT_RECEIPT_CHECKPOINT passed=%d failed=%d" % [_passed,_failed])
 quit(1 if _failed else 0)
