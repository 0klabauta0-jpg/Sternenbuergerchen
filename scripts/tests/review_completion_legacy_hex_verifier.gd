extends "res://scripts/tests/hex_ground_lifecycle_verifier.gd"
const REAL_ACTOR = preload("res://scripts/npc/test_unit.gd")
const LEGACY = preload("res://scripts/mission/legacy_ground_checkpoint.gd")
const BATCH = preload("res://scripts/mission/mission_actor_checkpoint_batch.gd")
const JOINED = preload("res://scripts/mission/mission_ground_actor_transaction.gd")
const LIFECYCLE = preload("res://scripts/mission/stable_mission_lifecycle_checkpoint.gd")
const RNG = preload("res://scripts/core/gameplay_rng_state.gd")
const CODEC = preload("res://scripts/mission/checkpoint_value_codec.gd")
const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
class QuietDriver extends "res://scripts/tests/mission_combat_loop_driver.gd":
	func _ready() -> void:
		set_process(false)
		set_physics_process(false)

func _run() -> void:
	if not GUARD.require_isolated_user_data(): return
	_test_legacy_owner_migration()
	await process_frame
	print("REVIEW_COMPLETION_LEGACY_HEX passed=%d failed=%d" % [passed,failed])
	quit(1 if failed else 0)

func _test_legacy_owner_migration() -> void:
	var rig := _admission_rig([Vector2i.ZERO,Vector2i(1,0),Vector2i(2,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,1)])
	rig.sim.set_physics_process(false)
	rig.map.set_tactical_grid_rules("")
	rig.sim.configure_hex_ground_runtime(rig.map,rig.terrain)
	var ids: Array = ["legacy_a","legacy_b"]
	for index in range(ids.size()):
		var actor := REAL_ACTOR.new()
		actor.unit_id = ids[index]
		actor.team_id = "blue"
		rig.scene.add_child(actor)
		rig.units.register_unit(actor.unit_id,actor)
		rig.sim.register_known_unit(actor.unit_id,actor)
		actor.global_position = rig.terrain.grid_to_world(Vector2i(index,0))+Vector2(0.25,0.125)
		rig.actors[actor.unit_id] = actor
	var driver := QuietDriver.new()
	driver.friendly_team_id = "blue"
	rig.scene.add_child(driver)
	driver._current_tick = rig.sim.tick_counter
	rig.sim.set_combat_rng_seed(841)
	var life_owner := LIFECYCLE.new()
	var lifecycle: Dictionary = life_owner.export_state(rig.sim,driver)
	var legacy: Dictionary = LEGACY.new().export_positions(rig.sim,rig.terrain,ids)
	var actors: Dictionary = BATCH.new().export_actors(rig.sim)
	_check(legacy.get("ok",false) and actors.get("ok",false) and lifecycle.get("ok",false),"real pre-activation Legacy owner exports actual actors on Hex geometry")
	if not legacy.get("ok",false) or not actors.get("ok",false) or not lifecycle.get("ok",false):
		rig.scene.free()
		return
	# The old owner schema truly has no extra domain state. Keep serialized bytes
	# as an immutable artifact; migration must never rewrite the input in-place.
	lifecycle.erase("rng_streams")
	var old_fields: Dictionary = CODEC.decode_value(lifecycle.payload)
	old_fields.value.erase("combat_cooldowns")
	lifecycle.payload = CODEC.encode_value(old_fields.value).value
	var original := JSON.stringify({"ground":legacy,"actors":actors,"lifecycle":lifecycle},"",true,true)
	var capacity_owner := JOINED.new()
	var keepalive: Array[RefCounted] = []
	for index in range(16):
		var legacy_slot: Dictionary = capacity_owner.prepare_restore(rig.sim,rig.terrain,legacy,actors,ids,lifecycle)
		if legacy_slot.get("ok",false): keepalive.append(legacy_slot.prepared)
		else: print("LEGACY_CAPACITY_PREPARE ",index," ",legacy_slot)
		legacy_slot.clear()
	_check(keepalive.size()==16,"actual Legacy branch reserves live preparation handles")
	rig.map.set_tactical_grid_rules("hex_tactical_v1")
	_check(rig.sim.configure_hex_ground_runtime(rig.map,rig.terrain).get("ok",false),"same physical map activates canonical Hex owner")
	var joined := JOINED.new()
	var streams: Dictionary = RNG.from_legacy(lifecycle.rng)
	var missing: Dictionary = streams.duplicate(); missing.erase("space_fire")
	var overflow: Dictionary = streams.duplicate(); overflow.air_ground = 2147483648
	var noncanonical: Dictionary = streams.duplicate(); noncanonical.combat = "9223372036854775808"
	for invalid in [7,missing,overflow,noncanonical]:
		var candidate: Dictionary = lifecycle.duplicate(true)
		candidate.rng_streams = invalid
		var ground_before: Dictionary = rig.sim.get_hex_ground_planning_snapshot()
		var rng_before: Dictionary = rig.sim.export_gameplay_rng_state()
		var actor_before: Dictionary = BATCH.new().export_actors(rig.sim)
		_check(joined.prepare_restore(rig.sim,rig.terrain,legacy,actors,ids,candidate).get("reason")=="legacy_hex_migration_mismatch","legacy migration rejects malformed RNG domains before publication")
		_check(life_owner.prepare_restore(rig.sim,driver,candidate).get("reason")=="invalid_mission_lifecycle_rng","actual lifecycle rejects malformed RNG domains without type errors")
		_check(rig.sim.get_hex_ground_planning_snapshot()==ground_before and rig.sim.export_gameplay_rng_state()==rng_before and BATCH.new().export_actors(rig.sim)==actor_before,"invalid save leaves Ground, RNG and actual actor owners unchanged")
	var prepared: Dictionary = joined.prepare_restore(rig.sim,rig.terrain,legacy,actors,ids,lifecycle)
	_check(prepared.get("ok",false),"legacy free poses prepare through canonical Hex admission: "+str(prepared.get("reason","")))
	if prepared.get("ok",false):
		_check(joined.validate_restore(prepared.prepared).get("ok",false),"migration validates complete actor and Ground owners")
		joined._publish_restore(prepared.prepared)
		_check(joined.finalize_restore(prepared.prepared).get("ok",false),"validated legacy migration publishes actual actor and Ground state")
		for id in ids:
			_check(rig.sim.get_hex_unit_state(id).grid == Vector2i(ids.find(id),0) and rig.actors[id].global_position==rig.terrain.grid_to_world(Vector2i(ids.find(id),0)),"legacy actor is projected once onto its admitted logical cell: "+id)
		_check(rig.sim.export_gameplay_rng_state()==streams,"legacy continuation preserves combat RNG and documented secondary defaults")
		var fresh: Dictionary = rig.sim.export_hex_checkpoint_state()
		_check(fresh.get("ok",false) and rig.sim.restore_hex_checkpoint_state(JSON.parse_string(JSON.stringify(fresh.state))).get("ok",false),"migrated save can be saved and restored in native Hex format")
		var current_actors: Dictionary = BATCH.new().export_actors(rig.sim)
		var wrapper := {"ok":true,"schema":"hex_mission_ground.v1","checkpoint":fresh.state}
		for index in range(16):
			var hex_slot: Dictionary = capacity_owner.prepare_restore(rig.sim,rig.terrain,wrapper,current_actors,ids)
			if hex_slot.get("ok",false): keepalive.append(hex_slot.prepared)
			else: print("HEX_CAPACITY_PREPARE ",index," ",hex_slot)
			hex_slot.clear()
		_check(keepalive.size()==32,"Legacy and Hex branches share one preparation budget")
		_check(capacity_owner.prepare_restore(rig.sim,rig.terrain,wrapper,current_actors,ids).get("reason")=="ground_actor_capacity" and capacity_owner.prepare_restore(rig.sim,rig.terrain,legacy,actors,ids,lifecycle).get("reason")=="ground_actor_capacity","both schemas reject capacity overflow before preparing additional owners")
		keepalive.clear()
		var reclaimed: Dictionary = capacity_owner.prepare_restore(rig.sim,rig.terrain,wrapper,current_actors,ids)
		if not reclaimed.get("ok",false) or capacity_owner._preparations.size()!=1: print("HEX_CAPACITY_RECLAIM ",reclaimed," handles=",capacity_owner._preparations.size())
		_check(reclaimed.get("ok",false) and capacity_owner._preparations.size()==1,"released outer handles reclaim nested preparations before either branch")
	_check(JSON.stringify({"ground":legacy,"actors":actors,"lifecycle":lifecycle},"",true,true)==original,"migration preserves original legacy artifact byte representation")
	rig.scene.free()
