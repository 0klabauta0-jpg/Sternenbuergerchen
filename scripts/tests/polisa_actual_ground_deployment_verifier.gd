extends "res://scripts/tests/hex_ground_lifecycle_verifier.gd"

func _run() -> void:
	var rig: Dictionary = _admission_rig([])
	var actual_map = MAP.load_from_file("res://maps/polisa_station.json")
	for tile in actual_map.get_tiles(): rig.terrain.register_tile(tile)
	var configured: Dictionary = rig.sim.configure_hex_ground_runtime(actual_map, rig.terrain)
	_check(configured.get("ok",false), "actual station map activates real ground owner")
	var view = load("res://scripts/terrain/terrain_map_3d_view.gd").new()
	var ship := {"craft_id":"real-shuttle","model_id":"cutlass","craft_type":"dropship","crew_capacity":8}
	var projection: Dictionary = view.get_station_craft_body_projection(ship)
	var bound: Dictionary = load("res://scripts/mission/polisa_ground_body_profile.gd").from_projection(ship,projection)
	var pads: Array = load("res://scripts/mission/polisa_station_craft_runtime.gd").station_pads(actual_map)
	# Place an exclusion at the intended landing anchor to exercise avoidance,
	# independently of the admission gate that forbids two ships on one pad.
	var other: Dictionary = load("res://scripts/mission/hex_ground_ship_footprint.gd").new().cells_for_body(rig.terrain,ship,pads[0].position,bound.profile)
	var actor_a = _add_admission_actor(rig,"pilot")
	var actor_b = _add_admission_actor(rig,"recruit")
	actor_a.set_meta("dropship_embarked",true); actor_b.set_meta("dropship_embarked",true)
	var sequence := {"craft_id":"arriving-shuttle","units":[actor_a,actor_b],"unit_index":0}
	var adapter = load("res://scripts/mission/hex_ground_deployment_adapter.gd").new()
	var mask = func(_id: String): return {"ok":true,"registry_id":rig.terrain.get_instance_id(),"blocked_cells":other.blocked_cells}
	var occupied_result: Dictionary = adapter.advance_phase(rig.sim,sequence,pads[0].position,mask)
	_check(occupied_result.get("phase")=="waiting" and rig.sim.get_hex_unit_state("pilot").is_empty(), "blocked landing anchor waits instead of placing a passenger inside hull")
	other = load("res://scripts/mission/hex_ground_ship_footprint.gd").new().cells_for_body(rig.terrain,ship,pads[1].position,bound.profile)
	var own: Dictionary = load("res://scripts/mission/hex_ground_ship_footprint.gd").new().cells_for_body(rig.terrain,ship,pads[0].position,bound.profile)
	var query := {"all":false,"foreign":false}
	mask = func(id: String):
		if not id.is_empty():
			query.foreign=true
			return {"ok":true,"registry_id":rig.terrain.get_instance_id(),"blocked_cells":other.blocked_cells}
		query.all=true
		var cells: Array = own.blocked_cells.duplicate()
		for cell in other.blocked_cells:
			if not cells.has(cell):cells.append(cell)
		return {"ok":true,"registry_id":rig.terrain.get_instance_id(),"blocked_cells":cells}
	for index in range(2):
		sequence.unit_index=index
		var outcome := {}
		for attempt in range(8):
			outcome = adapter.advance_phase(rig.sim,sequence,pads[0].position,mask)
			if outcome.get("phase","")=="committed": break
			rig.sim._physics_process(0.1)
		_check(outcome.get("phase","")=="committed", "actual station deploys passenger %d with other Cutlass mask" % index)
		if outcome.get("phase","")!="committed": print("DEPLOY:",outcome)
		var state: Dictionary = rig.sim.get_hex_unit_state("pilot" if index==0 else "recruit")
		_check(not state.is_empty() and not other.blocked_cells.has(state.get("grid")), "passenger %d avoids other Cutlass" % index)
		_check(not state.is_empty() and not own.blocked_cells.has(state.get("grid")), "passenger %d exits outside own Cutlass" % index)
	_check(query.all and query.foreign, "deployment requests own hull and distinguishes foreign hulls")
	var boarded: Dictionary = rig.sim.embark_hex_ground_actor_group(PackedStringArray(["pilot","recruit"]))
	_check(boarded.get("ok",false) and rig.sim.get_hex_unit_state("pilot").is_empty() and rig.sim.get_hex_unit_state("recruit").is_empty(), "real station actors reboard without duplicate ground occupancy")
	view.free(); rig.scene.free()
	print("RESULTS: %d passed, %d failed" % [passed,failed])
	if failed==0: print("POLISA_ACTUAL_GROUND_DEPLOYMENT_PASS")
	quit(0 if failed==0 else 1)
