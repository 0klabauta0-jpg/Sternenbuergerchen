extends SceneTree
const COMBAT = preload("res://scripts/core/space_combat_state.gd")
const FLIGHT = preload("res://scripts/core/space_flight_state.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const CODEC = preload("res://scripts/mission/checkpoint_value_codec.gd")
var checked := 0

func check(condition: bool, label: String) -> bool:
	checked += 1
	if not condition:
		printerr("FAIL: ", label)
		quit(1)
	return condition

func flight(id: String, cell: Vector2i) -> RefCounted:
	var result = FLIGHT.new()
	assert(result.configure(id, {"position_plane":HEX.axial_to_plane(Vector2(cell)), "motion_mode":"tactical"}).ok)
	return result

func _initialize() -> void:
	var source = COMBAT.new()
	if not check(source.has_method("export_navigation_checkpoint"), "navigation checkpoint API exists"): return
	var a = flight("a", Vector2i(4, 4))
	var b = flight("b", Vector2i(12, 4))
	for item in [["a",a,Vector2i(4,4)],["b",b,Vector2i(12,4)]]:
		assert(source.admit_actor({"craft_id":item[0], "start_hex":item[2], "faction_id":"blue", "control_domain":"player", "footprint_hexes":[Vector2i.ZERO]}, item[1]).ok)
	assert(source.record_navigation_claim("a", "", [Vector2i(6,4)]).ok)
	var hull := {"main_thrust":5.0,"reverse_thrust":5.0,"side_thrust":5.0,"turn_acceleration":1.0}
	assert(source.set_flight_control("a", {"goal":{"target_plane":HEX.axial_to_plane(Vector2(6,4))}, "hull":hull,"power":{"thrust_fraction":1.0}}))
	source.set_flight_status("a", {"ok":true,"reason":"moving"})
	var saved: Dictionary = JSON.parse_string(JSON.stringify(source.export_navigation_checkpoint()))
	var target_a = flight("a", Vector2i(4,4))
	var target_b = flight("b", Vector2i(12,4))
	var bindings := {"a":target_a,"b":target_b}
	var before: Dictionary = source.export_navigation_checkpoint()
	var restored: Dictionary = prepare(saved, bindings)
	if not check(restored.get("ok", false), "JSON roundtrip prepares detached owner"): return
	var target: RefCounted = restored.candidate
	if not check(target.get_actor("a") == target_a and target.get_actor("a") != a, "restored owner identity is bound"): return
	if not check(target.export_navigation_checkpoint() == before, "controls status revisions and claims survive"): return
	if not check(target.validate_navigation_checkpoint_candidate(saved).get("ok",false), "candidate freshness checked before publication"): return
	if not check(source.export_navigation_checkpoint() == before, "source is not mutated"): return
	var bad: Dictionary = saved.duplicate(true)
	var data: Dictionary = CODEC.decode_value(bad.payload).value
	data.claims.a.cells = [Vector2i(12,4)]
	bad.payload = CODEC.encode_value(data).value
	if not check(not prepare(bad, bindings).get("ok", false), "claim colliding with another craft rejected"): return
	bad = saved.duplicate(true)
	data = CODEC.decode_value(bad.payload).value
	data.indexed_revisions.a += 1
	bad.payload = CODEC.encode_value(data).value
	if not check(not prepare(bad, bindings).get("ok", false), "stale indexed revision rejected"): return
	if not check(not prepare(saved, {"a":target_a}).get("ok", false), "missing restored owner rejected"): return
	if not check(source.export_navigation_checkpoint() == before, "failed proposals leave source untouched"): return
	assert(target_a.configure("a", {"position_plane":HEX.axial_to_plane(Vector2(8,4)),"motion_mode":"tactical"}).ok)
	if not check(not target.validate_navigation_checkpoint_candidate(saved).get("ok",false), "changed candidate flight rejected before publication"): return
	if not test_control_rebind(): return
	print("SPACE_NAVIGATION_CHECKPOINT_PASS ", checked)
	quit(0)

func prepare(state: Dictionary, flights: Dictionary, contexts: Dictionary = {}) -> Dictionary:
	var api: Variant = COMBAT
	return api.prepare_navigation_checkpoint_candidate(state, flights, contexts)

func test_control_rebind() -> bool:
	var equipment_script = load("res://scripts/core/singleplayer_ship_equipment_state.gd")
	var equipment = equipment_script.new()
	var restored_equipment = equipment_script.new()
	var id := "space_fixture_saved"
	var definitions := [{"craft_id":id,"model_id":"buccaneer"}]
	assert(equipment.configure(definitions).ok and restored_equipment.configure(definitions).ok)
	var profile: Dictionary = equipment.get_space_flight_profile(id)
	assert(profile.ok)
	var actors := {}
	for key in ["source", "target"]:
		var actor = FLIGHT.new()
		assert(actor.configure(id, {"position_plane":HEX.axial_to_plane(Vector2(40,4)), "space_area_id":"orbit_approach:fixture", "coordinate_frame":"local", "motion_mode":"tactical", "mass":profile.mass}).ok)
		actors[key] = actor
	var source = COMBAT.new()
	assert(source.admit_actor({"craft_id":id,"start_hex":Vector2i(40,4),"faction_id":"blue","control_domain":"player","footprint_hexes":profile.footprint_hexes}, actors.source, true).ok)
	var goal := {"target_plane":HEX.axial_to_plane(Vector2(44,4))}
	var cells: Array[Vector2i] = source.preview_actor_cells(id, {"position_plane":goal.target_plane})
	assert(source.record_navigation_claim(id,"orbit_approach:fixture",cells).ok)
	assert(source.set_flight_control(id,{"goal":goal,"hull":profile.hull,"power":profile.power,"singleplayer_move":true,"equipment_snapshot":equipment.get_snapshot(id),"equipment_owner_id":equipment.get_instance_id(),"area_id":"orbit_approach:fixture"}))
	var saved: Dictionary = JSON.parse_string(JSON.stringify(source.export_navigation_checkpoint()))
	var bindings := {id:actors.target}
	if not check(not prepare(saved,bindings).get("ok",false), "missing runtime context rejected"): return false
	var restored: Dictionary = prepare(saved,bindings,{id:{"equipment_owner":restored_equipment}})
	if not check(restored.get("ok",false), "equipment owner context rebinds"): return false
	if not check(restored.candidate.get_flight_controls()[id].equipment_owner_id == restored_equipment.get_instance_id(), "saved process identity replaced"): return false
	var orbit_control: Dictionary = source.get_flight_controls()[id]
	orbit_control["orbit_auto_transit"] = true
	orbit_control["orbit_auto_location_id"] = "satellite_crash"
	orbit_control["orbit_auto_direction"] = "inbound"
	assert(source.set_flight_control(id,orbit_control))
	var orbit_saved: Dictionary = JSON.parse_string(JSON.stringify(source.export_navigation_checkpoint(),"",true,true))
	var orbit_restored: Dictionary = prepare(orbit_saved,bindings,{id:{"equipment_owner":restored_equipment}})
	if not check(orbit_restored.get("ok",false) and orbit_restored.candidate.get_flight_controls()[id].get("orbit_auto_transit")==true, "stable orbit transit control rebinds with its equipment"): return false
	var invalid_orbit: Dictionary = CODEC.decode_value(orbit_saved.payload).value
	invalid_orbit.controls[id]["orbit_auto_braking"] = true
	var forged_orbit := orbit_saved.duplicate(true)
	forged_orbit.payload = CODEC.encode_value(invalid_orbit).value
	if not check(not prepare(forged_orbit,bindings,{id:{"equipment_owner":restored_equipment}}).get("ok",false), "transient braking control is rejected"): return false
	invalid_orbit = CODEC.decode_value(orbit_saved.payload).value
	invalid_orbit.controls[id]["orbit_auto_transit"] = 1
	forged_orbit.payload = CODEC.encode_value(invalid_orbit).value
	if not check(not prepare(forged_orbit,bindings,{id:{"equipment_owner":restored_equipment}}).get("ok",false), "integer orbit flag is rejected"): return false
	orbit_control.erase("orbit_auto_transit")
	orbit_control.erase("orbit_auto_location_id")
	orbit_control.erase("orbit_auto_direction")
	assert(source.set_flight_control(id,orbit_control))
	var mutated: Dictionary = CODEC.decode_value(saved.payload).value
	mutated.controls[id].hull.main_thrust *= 2.0
	var bad := saved.duplicate(true)
	bad.payload = CODEC.encode_value(mutated).value
	if not check(not prepare(bad,bindings,{id:{"equipment_owner":restored_equipment}}).get("ok",false), "wrong equipment physics rejected"): return false
	var mission = load("res://scripts/core/simulation_root.gd").new()
	var restored_mission = load("res://scripts/core/simulation_root.gd").new()
	var air_control: Dictionary = source.get_flight_controls()[id]
	air_control.erase("singleplayer_move")
	air_control.erase("equipment_owner_id")
	air_control["air_support_move"] = true
	air_control["mission_root"] = weakref(mission)
	assert(source.set_flight_control(id,air_control))
	saved = JSON.parse_string(JSON.stringify(source.export_navigation_checkpoint()))
	var missing_mission: Dictionary = prepare(saved,bindings,{id:{"equipment_owner":restored_equipment}})
	var rebound_air: Dictionary = prepare(saved,bindings,{id:{"equipment_owner":restored_equipment,"mission_root":restored_mission}})
	var air_ok: bool = rebound_air.get("ok",false) and rebound_air.candidate.get_flight_controls()[id].mission_root.get_ref() == restored_mission
	if rebound_air.get("ok",false): air_ok = air_ok and rebound_air.candidate.validate_navigation_checkpoint_candidate(saved,{id:{"equipment_owner":restored_equipment,"mission_root":restored_mission}}).get("ok",false)
	mission.free()
	restored_mission.free()
	if not check(not missing_mission.get("ok",false) and air_ok, "air control explicitly rebinds actual mission owner"): return false
	air_control.erase("air_support_move")
	air_control.erase("mission_root")
	air_control["singleplayer_move"] = true
	air_control["equipment_owner_id"] = equipment.get_instance_id()
	assert(source.set_flight_control(id,air_control))
	var inactive = FLIGHT.new()
	var inactive_target = FLIGHT.new()
	var inactive_id := "space_fixture_inactive"
	var pose := {"position_plane":HEX.axial_to_plane(Vector2(48,4)),"space_area_id":"orbit_approach:fixture","coordinate_frame":"local","motion_mode":"inactive"}
	assert(inactive.configure(inactive_id,pose).ok and inactive_target.configure(inactive_id,pose).ok)
	assert(source.admit_actor({"craft_id":inactive_id,"start_hex":Vector2i(48,4),"faction_id":"blue","control_domain":"player","footprint_hexes":[Vector2i.ZERO]},inactive,true).ok)
	assert(source.deactivate_actor(inactive_id).ok)
	saved = JSON.parse_string(JSON.stringify(source.export_navigation_checkpoint()))
	bindings[inactive_id] = inactive_target
	restored = prepare(saved,bindings,{id:{"equipment_owner":restored_equipment}})
	if not check(restored.get("ok",false) and restored.candidate.get_inactive_actor(inactive_id) == inactive_target and restored.candidate.get_actor(inactive_id) == null, "inactive owner remains unindexed"): return false
	return true
