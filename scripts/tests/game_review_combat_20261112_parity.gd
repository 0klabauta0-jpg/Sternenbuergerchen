extends SceneTree

const SIM = preload("res://scripts/core/simulation_root.gd")
const REGISTRY = preload("res://scripts/registries/unit_registry.gd")
const UNIT = preload("res://scripts/npc/test_unit.gd")
var passed: int = 0
var failed: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var single: Dictionary = _context("Single", false)
	var host: Dictionary = _context("Host", true)
	var mirror: Dictionary = _context("Mirror", true)
	var reference_rng := RandomNumberGenerator.new()
	reference_rng.seed = 1729
	for index in range(12):
		var effect: Dictionary = {
			"effect_type": "damage", "unit_id": "target",
			"attacker_unit_id": "attacker", "attacker_team_id": "team_alpha",
			"damage": 3, "hit_chance": 0.45, "weapon_id": "rifle",
			"fire_event_id": "review_%d" % index, "target_cover_override": 0.0,
		}
		for context in [single, host]:
			context.sim.call("enqueue_effect", effect.duplicate(true))
			context.sim.call("_physics_process", 0.016)
		var sp_result: Dictionary = single.sim.call("get_last_damage_effect_resolution")
		var host_result: Dictionary = host.sim.call("get_last_damage_effect_resolution")
		check(sp_result == host_result, "Queued singleplayer/host resolution %d has identical roll, hit, damage and vitals" % index)
		var applied: Dictionary = mirror.sim.call("apply_multiplayer_snapshot", host.sim.call("build_multiplayer_snapshot"))
		check(bool(applied.get("accepted", false)) and mirror.target.get_health() == host.target.get_health(), "Server snapshot %d mirrors committed health" % index)
		check(mirror.sim.command_queue.is_empty() and mirror.sim.effects_queue.is_empty(), "Snapshot %d creates no mirror commands or effects" % index)
	check(float(mirror.sim.call("get_next_combat_roll")) == reference_rng.randf(), "Twelve applied snapshots consumed no mirror combat RNG draws")
	for context in [single, host, mirror]:
		context.owner.free()
	await process_frame
	print("GAME_REVIEW_COMBAT_PARITY: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

func _context(label_text: String, authoritative: bool) -> Dictionary:
	var owner := Node.new()
	owner.name = label_text
	root.add_child(owner)
	var registry = REGISTRY.new()
	registry.name = "UnitRegistry"
	owner.add_child(registry)
	var simulation = SIM.new()
	simulation.name = "SimulationRoot"
	simulation.unit_registry_path = NodePath("../UnitRegistry")
	simulation.is_server_authoritative = authoritative
	owner.add_child(simulation)
	simulation.set_physics_process(false)
	simulation.call("set_combat_rng_seed", 1729)
	var target: Node2D
	for unit_id in ["attacker", "target"]:
		var unit = UNIT.new()
		unit.unit_id = unit_id
		unit.team_id = "team_alpha" if unit_id == "attacker" else "team_bravo"
		unit.fireteam_id = "blue" if unit_id == "attacker" else "red"
		unit.weapon_1_id = "rifle"
		unit.weapon_2_id = "rifle"
		unit.position = Vector2.ZERO if unit_id == "attacker" else Vector2(40.0, 0.0)
		owner.add_child(unit)
		registry.call("register_unit", unit_id, unit)
		if unit_id == "target":
			target = unit
	return {"owner": owner, "sim": simulation, "target": target}

func check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
		print("PASS: " + message)
	else:
		failed += 1
		push_error("FAIL: " + message)
