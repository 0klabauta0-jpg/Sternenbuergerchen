extends "res://scripts/tests/hex_movement_verifier.gd"
const PROFILE=preload("res://scripts/npc/unit_profile_math.gd")
const TEST_UNIT=preload("res://scripts/npc/test_unit.gd")

class CombatActor extends Actor:
	var accuracy:=0.2
	var legacy_accuracy:=0.99
	var profile_reads:=0
	var legacy_reads:=0
	func get_accuracy_skill():
		legacy_reads+=1
		return legacy_accuracy
	func get_combat_effects():
		profile_reads+=1
		return PROFILE.build_character_bundle({"accuracy":accuracy}).combat_effects
	func get_damage_profile_snapshot():return get_combat_effects()
	func get_combat_hit_chance_multiplier():return get_combat_effects().hit_chance_multiplier
	func get_combat_hit_modifier():return get_combat_effects().hit_modifier
	func get_combat_evasion_modifier():return get_combat_effects().evasion_modifier
	func get_combat_damage_taken_multiplier():return get_combat_effects().damage_taken_multiplier

class LegacyCombatActor extends Actor:
	var reads:Dictionary={"bulk":0,"accuracy":0,"hit":0,"evasion":0,"damage":0,"skill":0}
	func get_combat_effects():
		reads.bulk+=1
		return {"hit_chance_multiplier":0.7,"hit_modifier":0.0,"evasion_modifier":0.0,"damage_taken_multiplier":1.0}
	func get_combat_hit_chance_multiplier():reads.accuracy+=1;return 1.0
	func get_combat_hit_modifier():reads.hit+=1;return 0.2
	func get_combat_evasion_modifier():reads.evasion+=1;return 0.1
	func get_combat_damage_taken_multiplier():reads.damage+=1;return 0.8
	func get_accuracy_skill():reads.skill+=1;return 0.9

func _finish()->void:
	if failed==0:_test_moving_shot()
	print("RESULTS: %d passed, %d failed"%[passed,failed])
	if failed==0:print("HEX_MOVING_SHOT_PASS")
	quit(0 if failed==0 else 1)

func _test_moving_shot()->void:
	var bundle:Dictionary=PROFILE.build_character_bundle({"accuracy":0.9,"skill_accuracy":0.1})
	_check(bundle.combat_effects.has("moving_shot_accuracy_multiplier"),"canonical profile derives movement-shot factor from core accuracy")
	if not bundle.combat_effects.has("moving_shot_accuracy_multiplier"):return
	_check(is_equal_approx(bundle.combat_effects.moving_shot_accuracy_multiplier,0.92),"provisional high-skill factor derives from canonical0.9 rather than legacy0.1")
	var actual=TEST_UNIT.new()
	actual.get_skills().accuracy=0.1
	bundle.combat_effects.erase("moving_shot_accuracy_multiplier")
	actual._character_profile_bundle=bundle.duplicate(true)
	_check(is_equal_approx(actual.get_combat_effects().moving_shot_accuracy_multiplier,0.92) and actual.get_character_profile_bundle()==bundle,"actual TestUnit backfills old derived effects from core accuracy without rewriting profile")
	actual.free()
	var terrain=REGISTRY.new()
	root.add_child(terrain)
	terrain.configure_iso_grid(Vector2.ZERO,64,32,"hex_axial_v1")
	for x in range(4):terrain.register_tile(TILE.new({"tile_id":str(x),"grid_position":Vector2i(x,0)}))
	var registry=UNITS.new()
	root.add_child(registry)
	var sim=SIM.new()
	root.add_child(sim)
	sim.unit_registry_path=sim.get_path_to(registry)
	sim.terrain_registry_path=sim.get_path_to(terrain)
	var map=MAP.create_empty("moving_shot",Vector2i(4,1),Vector2.ZERO,64,32,3,"hex_axial_v1")
	map.set_tactical_grid_rules("hex_tactical_v1")
	sim.configure_hex_ground_runtime(map,terrain)
	var attacker=CombatActor.new()
	attacker.unit_id="attacker"
	var target=CombatActor.new()
	target.unit_id="target"
	for actor in [attacker,target]:
		root.add_child(actor)
		registry.register_unit(actor.unit_id,actor)
		sim.register_known_unit(actor.unit_id,actor)
	var batch:Array[Dictionary]=[{"unit_id":"attacker","grid":Vector2i.ZERO},{"unit_id":"target","grid":Vector2i(3,0)}]
	sim.admit_hex_ground_units(batch)
	var stationary:Dictionary=_shot(sim,attacker,target)
	_check(stationary.has("moving_shot_accuracy_multiplier"),"actual damage resolution reports the authoritative movement factor")
	if stationary.has("moving_shot_accuracy_multiplier"):
		_check(stationary.moving_shot_accuracy_multiplier==1.0 and not stationary.attacker_moving,"stationary logical unit has no moving-shot penalty")
		sim.enqueue_command(_command("attacker",terrain.grid_to_world(Vector2i.RIGHT)))
		var moving:Dictionary=_shot(sim,attacker,target)
		_check(moving.hit and moving.attacker_moving and is_equal_approx(moving.hit_chance_resolved,stationary.hit_chance_resolved*0.71),"actual moving shot remains possible with low-skill factor0.71")
		_check(attacker.profile_reads==1 and target.profile_reads==1 and attacker.legacy_reads==0,"one effect reads each canonical profile once and never the conflicting legacy skill")
		sim._physics_process(0.1)
		sim.enqueue_command({"type":"hold_position","unit_id":"attacker","team_id":"blue","command_token":"stop_shooting_move"})
		var centering:Dictionary=_shot(sim,attacker,target)
		_check(sim.get_hex_unit_state("attacker").movement_state.get("phase","")=="centering" and centering.attacker_moving and is_equal_approx(centering.moving_shot_accuracy_multiplier,0.71),"own-cell centering remains movement for shot accuracy")
		for i in range(32):sim._physics_process(0.1)
		attacker.accuracy=0.9
		var trained_stationary:Dictionary=_shot(sim,attacker,target)
		sim.enqueue_command(_command("attacker",terrain.grid_to_world(Vector2i.RIGHT)))
		var trained_moving:Dictionary=_shot(sim,attacker,target)
		_check(trained_moving.moving_shot_accuracy_multiplier>moving.moving_shot_accuracy_multiplier and is_equal_approx(trained_moving.hit_chance_resolved,trained_stationary.hit_chance_resolved*0.92),"later effect reads changed core skill freshly and gives smaller movement penalty")
		attacker.set_meta("hex_ground_moving",false)
		var render_lie:Dictionary=_shot(sim,attacker,target)
		_check(render_lie.attacker_moving and is_equal_approx(render_lie.moving_shot_accuracy_multiplier,0.92),"render moving flag cannot decide the authoritative shot modifier")
		map.set_tactical_grid_rules("")
		sim.configure_hex_ground_runtime(map,terrain)
		attacker.set_meta("hex_ground_moving",true)
		var legacy:Dictionary=_shot(sim,attacker,target)
		_check(legacy.moving_shot_accuracy_multiplier==1.0 and not legacy.attacker_moving,"legacy map retains the previous shot chance despite render moving flag")
		_shot(sim,attacker,attacker)
		_check(attacker.profile_reads==1,"same source and target share one canonical profile read within the effect")
	_test_legacy_getter_precedence(sim,registry)
	attacker.free()
	target.free()
	sim.free()
	registry.free()
	terrain.free()

func _test_legacy_getter_precedence(sim:Node,registry:Node)->void:
	var source=LegacyCombatActor.new()
	source.unit_id="legacy_source"
	var target=LegacyCombatActor.new()
	target.unit_id="legacy_target"
	for actor in [source,target]:
		root.add_child(actor)
		registry.register_unit(actor.unit_id,actor)
		sim.register_known_unit(actor.unit_id,actor)
	var next_rng=RandomNumberGenerator.new()
	next_rng.state=sim._combat_rng.state
	next_rng.randf()
	sim.enqueue_effect({"effect_type":"damage","unit_id":target.unit_id,"attacker_unit_id":source.unit_id,"damage":1,"hit_chance":0.5})
	sim._physics_process(0.1)
	_check(sim._combat_rng.state==next_rng.state,"actual unforced damage still consumes exactly one combat roll")
	_check(is_equal_approx(sim.get_last_damage_effect_resolution().hit_chance_resolved,0.6),"non-opted-in legacy actor retains explicit getter precedence over its differing effects dictionary")
	_check(source.reads=={"bulk":0,"accuracy":1,"hit":1,"evasion":0,"damage":0,"skill":0} and target.reads=={"bulk":0,"accuracy":0,"hit":0,"evasion":1,"damage":1,"skill":0},"stationary legacy shot reads only fields needed by each role and no unused movement skill")
	source.free()
	target.free()

func _shot(sim:Node,attacker:CombatActor,target:CombatActor)->Dictionary:
	attacker.profile_reads=0
	attacker.legacy_reads=0
	target.profile_reads=0
	var rng_before:int=sim._combat_rng.state
	sim.enqueue_effect({"effect_type":"damage","unit_id":target.unit_id,"attacker_unit_id":attacker.unit_id,"damage":1,"hit_chance":0.5,"roll_override":0.0})
	sim._physics_process(0.1)
	_check(sim._combat_rng.state==rng_before,"movement-shot calculation consumes no extra combat roll")
	return sim.get_last_damage_effect_resolution()
