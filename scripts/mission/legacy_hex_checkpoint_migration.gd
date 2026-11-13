extends RefCounted
## Bounded migration of a stable pre-activation campaign save on an already Hex
## map. Frame/fingerprint/overrides must still match exactly. Square8 remains a
## separate import contract; a changed map is never guessed into compatibility.
const CODEC = preload("res://scripts/mission/checkpoint_value_codec.gd")
const ADMISSION = preload("res://scripts/mission/hex_ground_admission.gd")
const RNG = preload("res://scripts/core/gameplay_rng_state.gd")

static func prepare(sim: Node, terrain: Node, legacy: Dictionary, actors: Dictionary, ids: Array, lifecycle: Dictionary) -> Dictionary:
	if legacy.size()!=6 or not legacy.has_all(["ok","schema","frame","map_fingerprint","overrides","positions"]) or legacy.get("ok")!=true or legacy.get("schema")!="legacy_ground_positions.v1": return _bad()
	if legacy.frame!=terrain.get_checkpoint_grid_frame() or legacy.map_fingerprint!=terrain.get_checkpoint_map_fingerprint() or JSON.stringify(legacy.overrides,"",true)!=JSON.stringify(terrain.export_checkpoint_overrides(),"",true): return _bad()
	if not lifecycle.get("rng") is String or typeof(lifecycle.get("tick")) not in [TYPE_INT,TYPE_FLOAT]: return _bad()
	if not is_finite(float(lifecycle.tick)) or lifecycle.tick < 0 or lifecycle.tick > 1000000000000 or float(lifecycle.tick) != floorf(float(lifecycle.tick)): return _bad()
	var streams: Variant = lifecycle.get("rng_streams",RNG.from_legacy(lifecycle.rng))
	if not RNG.validate(streams) or streams.combat != lifecycle.rng: return _bad()
	var decoded: Dictionary = CODEC.decode_value(legacy.positions)
	if not decoded.get("ok",false) or not decoded.value is Dictionary or decoded.value.size()!=ids.size() or ids.is_empty() or ids.size()>64: return _bad()
	var candidates: Array[Dictionary] = []
	var seen := {}
	for id in ids:
		var position: Variant = decoded.value.get(id)
		if not id is String or seen.has(id) or not position is Vector2 or not position.is_finite(): return _bad()
		seen[id] = true
		candidates.append({"unit_id":id,"grid":terrain.world_to_grid(position)})
	var snapshot: Dictionary = sim.get_hex_ground_planning_snapshot()
	snapshot.units_by_id = {}
	snapshot.occupant_by_grid = {}
	snapshot.committed_segments = []
	snapshot.committed_corridor_grants = []
	snapshot.admission_slots_by_grid = {}
	var mask: Dictionary = sim._get_hex_respawn_ship_mask()
	if not mask.get("ok",false): return mask
	var blocked := {}
	for cell in mask.blocked_cells: blocked[cell] = true
	snapshot["external_admission_blocked_grids"] = blocked
	var placement: Dictionary = ADMISSION.new().plan_anchored_group(candidates,terrain,snapshot)
	if not placement.get("ok",false): return placement
	var current: Dictionary = sim.export_hex_checkpoint_state()
	if not current.get("ok",false): return current
	var state: Dictionary = current.state
	state.tick = lifecycle.tick
	state.rng_state = lifecycle.rng
	state.rng_streams = streams.duplicate(true)
	state.ground.tick = lifecycle.tick
	state.ground.units = []
	state.ground.active_segments = []
	state.ground.centering = []
	state.ground.passage_commitments = []
	state.movement.tick = lifecycle.tick
	state.movement.accepted_intents = []
	var migrated_actors: Dictionary = actors.duplicate(true)
	if not migrated_actors.get("actors") is Dictionary or migrated_actors.actors.size()!=ids.size(): return _bad()
	for entry: Dictionary in placement.placements:
		var record: Variant = migrated_actors.actors.get(entry.unit_id)
		if not record is Dictionary: return _bad()
		var model: Dictionary = CODEC.decode_value(record.get("payload"))
		if not model.get("ok",false) or not model.value is Dictionary or model.value.get("position") != decoded.value[entry.unit_id]: return _bad()
		var command: Variant = model.value.get("command")
		if not command is Dictionary or (not command.is_empty() and command.get("command_type")!="hold_position"): return _bad()
		model.value.position = terrain.grid_to_world(entry.grid)
		var encoded: Dictionary = CODEC.encode_value(model.value)
		if not encoded.get("ok",false): return encoded
		record.payload = encoded.value
		state.ground.units.append({"unit_id":entry.unit_id,"grid":[entry.grid.x,entry.grid.y],"facing_dir":0,"posture_key":"standing"})
	return {"ok":true,"ground":{"ok":true,"schema":"hex_mission_ground.v1","checkpoint":state},"actors":migrated_actors}

static func _bad() -> Dictionary:
	return {"ok":false,"reason":"legacy_hex_migration_mismatch"}
