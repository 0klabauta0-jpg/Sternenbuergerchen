extends SceneTree
## FT-A: Einheiten drehen sich zum Gegner. Echte Klassen (SimulationRoot, Hex-Bodenlaufzeit, Kampftreiber).
## Wer schiesst, sieht sein Ziel an (R1); wer beschossen wird, dreht sich zum Schuetzen, je nach Koennen verzoegert
## (R2); Kameraden der Gruppe reagieren mit (R3); die Sperre gilt nur noch fuer Laufende und Sicherungsbogen (R4);
## hoechstens eine Drehung je 30 Ticks, kein Wegdrehen von einem sichtbaren Ziel (R5); beide Seiten gleich (R7).
const SIM = preload("res://scripts/core/simulation_root.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN = preload("res://scripts/terrain/terrain_registry.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const UNITS = preload("res://scripts/registries/unit_registry.gd")
const DRIVER = preload("res://scripts/tests/mission_combat_loop_driver.gd")
const CACHE = preload("res://scripts/mission/combat_visibility_cache.gd")
const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const COMMAND = preload("res://scripts/npc/unit_command.gd")
const ACTOR = preload("res://scripts/npc/test_unit.gd")

const HOLD := {"command_type": "hold_position", "source_command_type": "defend", "fire_status": "fire_at_will", "fire_rule": "free"}
var passed := 0
var failed := 0


class NPC extends Node2D:
	var unit_id: String
	var team_id: String
	var fireteam_id := ""
	var awareness := 1.0
	var initiative := -1.0
	var active_weapon_id := "pistol"
	var is_fireteam_lead := false
	var hp := 100
	var command: RefCounted
	func get_unit_id() -> String: return unit_id
	func get_team_id() -> String: return team_id
	func get_fireteam_id() -> String: return fireteam_id if not fireteam_id.is_empty() else team_id + "_ft"
	func get_vital_state() -> String: return "fit" if hp > 0 else "down"
	func get_health() -> int: return hp
	func get_awareness() -> float: return awareness
	func get_active_weapon_id() -> String: return active_weapon_id
	func get_current_unit_command(): return command
	func get_character_profile_bundle() -> Dictionary: return {"behavior_axes": {"initiative": initiative}} if initiative >= 0.0 else {}
	func get_stealth() -> float: return 0.0
	func get_discipline() -> float: return 0.0
	func get_fire_status() -> String: return String(command.get("fire_status")) if command != null else "fire_at_will"
	func show_event_text(_text: String, _color: Color, _duration: float) -> void: pass
	func apply_damage(amount: int, _context: Dictionary = {}) -> bool:
		hp -= amount
		return true


class QuietDriver extends DRIVER:
	func _ready() -> void:
		set_process(false)
		set_physics_process(false)
		var simulation_root = get_node_or_null(simulation_root_path)
		if simulation_root != null:
			simulation_root.damage_effect_resolved.connect(_on_damage_effect_resolved)


func _init() -> void:
	if GUARD.require_isolated_user_data(): call_deferred("_run")


func _check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		print("FAIL: ", label)


func _run() -> void:
	_test_f1_stalemate()
	_test_f2_shooter_faces_target()
	_test_f3_victim_turns_with_skill_delay()
	_test_f4_comrades()
	_test_f5_lock_rules()
	_test_f6_no_flicker()
	_test_f8_deterministic()
	_test_w1_crossfire()
	_test_w2_group_key()
	await process_frame
	print("combat_facing_verifier passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _terrain_patch(center: Vector2i, radius: int) -> Node:
	var terrain = TERRAIN.new()
	terrain.name = "TerrainRegistry"
	terrain.configure_iso_grid(Vector2.ZERO, 64.0, 32.0, "hex_axial_v1")
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			var grid := center + Vector2i(dx, dy)
			terrain.register_tile(TILE.new({"tile_id": str(grid), "grid_position": grid,
				"world_position": terrain.grid_to_world(grid), "explicit_hex_ramps": true}))
	return terrain


## specs: [{id, team, grid, facing, aw, ini, hp, ft, cmd(Dictionary or null), weapon}]
func _fixture(specs: Array) -> Dictionary:
	var scope := Node.new()
	scope.name = "CombatFacingFixture"
	root.add_child(scope)
	var terrain := _terrain_patch(Vector2i(20, 20), 9)
	scope.add_child(terrain)
	var registry = UNITS.new()
	registry.name = "UnitRegistry"
	scope.add_child(registry)
	var sim = SIM.new()
	sim.name = "SimulationRoot"
	sim.unit_registry_path = NodePath("../UnitRegistry")
	sim.terrain_registry_path = NodePath("../TerrainRegistry")
	scope.add_child(sim)
	sim.set_physics_process(false)
	sim.set_process(false)
	var map = MAP.create_empty("combat_facing_fixture", Vector2i(160, 80), Vector2.ZERO, 64, 32, 3, "hex_axial_v1")
	map.set_tactical_grid_rules("hex_tactical_v1")
	map._extension_metadata["terrain_height_rules"] = "explicit_hex_ramps_v1"
	_check(bool(sim.configure_hex_ground_runtime(map, terrain).get("ok", false)), "Fixture: Bodenlaufzeit konfiguriert")
	var cache = CACHE.new()
	cache.name = "VisibilityCache"
	scope.add_child(cache)
	cache.begin_tick(1)
	var driver := QuietDriver.new()
	driver.name = "CombatLoopDriver"
	driver.friendly_team_id = "blue"
	driver.contact_range = 1000.0
	driver.simulation_root_path = NodePath("../SimulationRoot")
	driver.terrain_registry_path = NodePath("../TerrainRegistry")
	driver.combat_visibility_cache_path = NodePath("../VisibilityCache")
	scope.add_child(driver)
	var units := {}
	var placements: Array[Dictionary] = []
	var friendly_paths: Array[NodePath] = []
	var enemy_paths: Array[NodePath] = []
	for spec in specs:
		var npc: Node2D
		if bool(spec.get("real", false)):
			# Echte Einheit (eigene Befehlsverwaltung), fuer den Laufweg.
			npc = ACTOR.new()
			npc.unit_id = String(spec.id)
			npc.team_id = String(spec.team)
			npc.fireteam_id = String(spec.get("ft", "")) if not String(spec.get("ft", "")).is_empty() else String(spec.team) + "_ft"
			npc.weapon_1_id = "none"
			npc.weapon_2_id = "none"
			npc.set_physics_process(false)
		else:
			var fake := NPC.new()
			fake.unit_id = String(spec.id)
			fake.team_id = String(spec.team)
			fake.fireteam_id = String(spec.get("ft", ""))
			fake.awareness = float(spec.get("aw", 1.0))
			fake.initiative = float(spec.get("ini", -1.0))
			fake.hp = int(spec.get("hp", 100))
			fake.active_weapon_id = String(spec.get("weapon", "pistol"))
			var cmd = spec.get("cmd", null)
			if cmd != null:
				fake.command = COMMAND.new(cmd)
			if spec.has("group_id"):
				fake.set_meta("enemy_tactics_config", {"group_id": String(spec.group_id)})
			npc = fake
		npc.name = String(spec.id)
		npc.position = terrain.grid_to_world(spec.grid)
		scope.add_child(npc)
		registry.register_unit(npc.unit_id, npc)
		sim.register_known_unit(npc.unit_id, npc)
		units[npc.unit_id] = npc
		if npc.team_id == "blue":
			friendly_paths.append(NodePath("../" + npc.name))
		else:
			enemy_paths.append(NodePath("../" + npc.name))
		placements.append({"unit_id": npc.unit_id, "grid": spec.grid, "facing_dir": int(spec.facing)})
	driver.friendly_unit_paths.assign(friendly_paths)
	driver.enemy_unit_paths.assign(enemy_paths)
	_check(bool(sim.admit_hex_ground_units(placements).get("ok", false)), "Fixture: Einheiten zugelassen")
	var f := {"scope": scope, "terrain": terrain, "sim": sim, "cache": cache, "driver": driver, "units": units, "hits": [], "results": []}
	sim.damage_effect_resolved.connect(func(result: Dictionary) -> void: f.results.append(result))
	return f


func _tick(f: Dictionary) -> void:
	f.sim._physics_process(0.1)
	f.cache.begin_tick(f.sim.tick_counter)
	f.driver._current_tick = f.sim.tick_counter
	f.driver._advance_return_fire_windows()


## Ein Tick wie im Treiber (ohne Takt-Entscheidung): Wandel der Fenster und Erkennung.
func _combat_tick(f: Dictionary) -> void:
	_tick(f)
	f.driver._advance_detection_timers()
	if f.driver._should_run_combat_decision_tick(f.sim.tick_counter):
		f.driver._attack_excluded_unit_ids = {}
		f.driver._try_enqueue_attacks(f.sim)


func _ticks(f: Dictionary, count: int) -> void:
	for i in range(count):
		_tick(f)


func _face(f: Dictionary, id: String) -> int:
	return int(f.sim.get_hex_unit_state(id).facing_dir)


## Ein Schuss ueber den echten Einreihungsweg des Treibers (eine Stelle ausserhalb des Taktes bringt ihn zum Schuss).
## Gibt den Wuerfel vor, damit Treffer und Fehlschuss prueffbar sind (roll < hit_chance).
func _shoot(f: Dictionary, shooter_id: String, victim_id: String, hit: bool = true) -> bool:
	var attacker = f.units[shooter_id]
	var target = f.units[victim_id]
	var before: int = f.sim.effects_queue.size()
	var pair := {"attacker": attacker, "target": target, "attacker_id": shooter_id, "target_id": victim_id, "contact_state": "visible"}
	f.driver._enqueue_attack_for_pair(pair, f.sim, false)
	var queued: bool = f.sim.effects_queue.size() > before
	for index in range(before, f.sim.effects_queue.size()):
		var effect: Dictionary = f.sim.effects_queue[index]
		effect["hit_chance"] = 0.5
		effect["roll_override"] = 0.0 if hit else 0.99
	if f.driver.has_method("_flush_combat_noise_facing"):
		f.driver.call("_flush_combat_noise_facing")
	return queued


## Zaehlt die Ticks (ab jetzt) bis sich die Blickrichtung der Einheit aendert; -1 wenn nicht binnen limit.
func _turn_delay(f: Dictionary, id: String, limit: int) -> int:
	var start := _face(f, id)
	for step in range(1, limit + 1):
		_tick(f)
		if _face(f, id) != start:
			return step
	return -1


func _line(a: Vector2i, direction: int, steps: int) -> Vector2i:
	return a + HEX.DIRECTIONS[direction] * steps


# A (links) und B zwei Felder rechts; beide mit dem Ruecken zueinander. A->B ist Richtung 0, B->A Richtung 3.
func _pair_specs(a_team: String, b_team: String, a_extra: Dictionary = {}, b_extra: Dictionary = {}) -> Array:
	var a_grid := Vector2i(20, 20)
	var a := {"id": "a", "team": a_team, "grid": a_grid, "facing": 3}
	var b := {"id": "b", "team": b_team, "grid": _line(a_grid, 0, 2), "facing": 0}
	a.merge(a_extra, true)
	b.merge(b_extra, true)
	return [a, b]


# F1: der belegte Stillstand.
func _test_f1_stalemate() -> void:
	var f := _fixture(_pair_specs("blue", "red", {"hp": 44, "cmd": HOLD}, {"hp": 44}))
	var a_start := _face(f, "a")
	_check(a_start == 3 and _face(f, "b") == 0, "F1: Ausgangslage Ruecken an Ruecken")
	_check(f.driver._query_current_visibility(f.units.a, f.units.b, 1000.0).get("visible", true) == false, "F1: sie sehen sich nicht")
	_ticks(f, 3)
	# Ein Schuss von aussen (Streuschuss/Ueberwachung): b schiesst auf a.
	_check(_shoot(f, "b", "a", true), "F1: Schuss eingereiht")
	var faced_each_other_tick := -1
	var shots := 0
	for step in range(1, 700):
		_combat_tick(f)
		if faced_each_other_tick < 0 and _face(f, "a") == 0 and _face(f, "b") == 3:
			faced_each_other_tick = step
		if f.units.a.hp <= 0 or f.units.b.hp <= 0:
			break
	for result in f.results:
		shots += 1
	_check(faced_each_other_tick >= 0, "F1: beide drehen sich zueinander (a=%d, b=%d)" % [_face(f, "a"), _face(f, "b")])
	_check(f.units.a.hp <= 0 or f.units.b.hp <= 0, "F1: das Gefecht laeuft weiter, bis eine Einheit ausfaellt (a=%d b=%d, %d Wuerfe)" % [f.units.a.hp, f.units.b.hp, shots])
	f.scope.free()


# F2: Regel 1 (und R4: auch mit Halten/Defend), beide Seiten (F7).
func _test_f2_shooter_faces_target() -> void:
	for side in [["blue", "red"], ["red", "blue"]]:
		for cmd in [null, HOLD]:
			var tag := "F2 %s->%s cmd=%s" % [side[0], side[1], "hold" if cmd != null else "frei"]
			var f := _fixture(_pair_specs(side[0], side[1], {"cmd": cmd}))
			_ticks(f, 2)
			_check(_shoot(f, "a", "b"), tag + ": Schuss eingereiht")
			_ticks(f, 3)
			_check(_face(f, "a") == 0, tag + ": Schuetze sieht zum Ziel (%d)" % _face(f, "a"))
			f.scope.free()


# F3: Regel 2, Verzug nach Koennen, Treffer und Fehlschuss, beide Seiten.
func _test_f3_victim_turns_with_skill_delay() -> void:
	for side in [["blue", "red"], ["red", "blue"]]:
		for hit in [true, false]:
			var tag := "F3 Opfer %s %s" % [side[1], "Treffer" if hit else "Fehlschuss"]
			var f := _fixture(_pair_specs(side[0], side[1], {}, {"aw": 1.0, "ini": 1.0}))
			_ticks(f, 2)
			_shoot(f, "a", "b", hit)
			var quick := _turn_delay(f, "b", 40)
			_check(quick >= 1 and quick <= 2, tag + ": gute Einheit dreht fast sofort (Ticks=%d)" % quick)
			_check(_face(f, "b") == 3, tag + ": Opfer sieht zum Schuetzen (%d)" % _face(f, "b"))
			var outcomes: Array = f.results.map(func(r): return bool(r.get("hit", false)))
			_check(outcomes.has(hit) if not f.results.is_empty() else true, tag + ": Wurf wie vorgegeben")
			f.scope.free()
			var g := _fixture(_pair_specs(side[0], side[1], {}, {"aw": 0.2, "ini": 0.2}))
			_ticks(g, 2)
			# Nachgerechnet: round((1-0,2) x 15) = 12 plus Reaktionszeit der Initiative 0,2 (27 Ticks laut Taktdaten) = 39 Ticks.
			var expected_delay := 39
			_check(g.driver._get_detection_delay_ticks(g.units.b) == expected_delay, tag + ": Erkennungsverzug der schwachen Einheit ist %d (%d)" % [expected_delay, g.driver._get_detection_delay_ticks(g.units.b)])
			_shoot(g, "a", "b", hit)
			var slow := _turn_delay(g, "b", 80)
			_check(slow >= expected_delay - 1 and slow <= expected_delay + 1, tag + ": schwache Einheit dreht nach rund %d Ticks (Ticks=%d)" % [expected_delay, slow])
			_check(_face(g, "b") == 3, tag + ": schwaches Opfer sieht am Ende zum Schuetzen")
			g.scope.free()


func _mate_specs(side: Array, mate_extra: Dictionary) -> Array:
	var specs := _pair_specs(side[0], side[1], {}, {"ft": "gruppe_b"})
	var mate := {"id": "m", "team": side[1], "grid": _line(Vector2i(20, 20), 0, 4), "facing": 0, "ft": "gruppe_b", "aw": 1.0, "ini": 1.0}
	mate.merge(mate_extra, true)
	specs.append(mate)
	return specs


# F4: Regel 3.
func _test_f4_comrades() -> void:
	for side in [["blue", "red"], ["red", "blue"]]:
		var tag := "F4 %s" % side[1]
		var f := _fixture(_mate_specs(side, {}))
		_ticks(f, 2)
		_shoot(f, "a", "b")
		_ticks(f, 24)
		_check(_face(f, "m") == 0, tag + ": Kamerad dreht vor Ablauf der 30 Ticks noch nicht")
		_ticks(f, 12)
		_check(_face(f, "m") == 3, tag + ": Kamerad ohne Ziel dreht sich zum Schuetzen (%d)" % _face(f, "m"))
		f.scope.free()
		var g := _fixture(_mate_specs(side, {"cmd": HOLD}))
		_ticks(g, 2)
		_shoot(g, "a", "b")
		_ticks(g, 80)
		# W2 (Nachbesserung 1, ersetzt "Kamerad mit Sicherungsauftrag dreht sich nicht"): ein stehender Kamerad mit hold/defend
		# und ohne sichtbares Ziel dreht sich mit.
		_check(_face(g, "m") == 3, tag + ": stehender Kamerad mit hold/defend ohne Ziel dreht sich mit (%d)" % _face(g, "m"))
		g.scope.free()
		# Kamerad mit eigenem sichtbaren Ziel: m steht bei c (gleiche Seite wie a, rechts von m) und schiesst darauf.
		var specs := _mate_specs(side, {})
		specs.append({"id": "c", "team": side[0], "grid": _line(Vector2i(20, 20), 0, 6), "facing": 3, "ft": "gruppe_c"})
		var h := _fixture(specs)
		_ticks(h, 2)
		_shoot(h, "m", "c")
		_check(_face(h, "m") == 0, tag + ": m sieht zu seinem Ziel c")
		_ticks(h, 40)
		var m_before := _face(h, "m")
		_shoot(h, "a", "b")
		_ticks(h, 80)
		_check(_face(h, "m") == m_before, tag + ": Kamerad mit eigenem sichtbaren Ziel dreht sich nicht weg (%d)" % _face(h, "m"))
		h.scope.free()


# F5: Regel 4 an der Sperre selbst.
func _test_f5_lock_rules() -> void:
	var f := _fixture(_pair_specs("blue", "red", {"cmd": HOLD}))
	_ticks(f, 2)
	var noise: Dictionary = f.sim.queue_hex_facing_intent("a", 1, "f5_noise", "noise_reaction")
	_check(bool(noise.get("ok", false)), "F5/W2: noise_reaction ist fuer stehende Einheit mit hold/defend erlaubt (%s)" % str(noise))
	var result: Dictionary = f.sim.queue_hex_facing_intent("a", 0, "f5_standing", "combat_reaction")
	_check(bool(result.get("ok", false)), "F5: stehende Einheit mit defend/hold darf combat_reaction (%s)" % str(result))
	f.scope.free()
	var g := _fixture(_pair_specs("blue", "red", {"real": true}))
	_ticks(g, 2)
	var target: Vector2 = g.terrain.grid_to_world(Vector2i(20, 14))
	g.sim.enqueue_command({"type": "move_to_position", "unit_id": "a", "team_id": "blue", "target_position": target,
		"move_speed_factor": 1.0, "command_token": "f5_walk", "requeue_until_target": true})
	var walks := false
	for step in range(30):
		_tick(g)
		var state: Dictionary = g.sim.get_hex_unit_state("a")
		if bool(state.movement_state.moving) or bool(state.route_state.has_commitments):
			walks = true
			break
	_check(walks, "F5: Einheit laeuft")
	var walking: Dictionary = g.sim.queue_hex_facing_intent("a", 0, "f5_walking", "combat_reaction")
	_check(not bool(walking.get("ok", false)) and String(walking.get("reason", "")) == "assignment_locks_facing", "F5: laufende Einheit dreht sich nicht (%s)" % str(walking))
	var walking_noise: Dictionary = g.sim.queue_hex_facing_intent("a", 0, "f5_walking_noise", "noise_reaction")
	_check(not bool(walking_noise.get("ok", false)) and String(walking_noise.get("reason", "")) == "assignment_locks_facing", "F5/W2: auch noise_reaction ist fuer Laufende gesperrt (%s)" % str(walking_noise))
	g.scope.free()
	# Treiberweg: stehende Einheit mit defend dreht sich bei Beschuss.
	var h := _fixture(_pair_specs("blue", "red", {}, {"cmd": HOLD, "aw": 1.0, "ini": 1.0}))
	_ticks(h, 2)
	_shoot(h, "a", "b")
	_ticks(h, 4)
	_check(_face(h, "b") == 3, "F5: stehendes Opfer mit defend/hold dreht sich bei Beschuss (%d)" % _face(h, "b"))
	h.scope.free()


# F6: Regel 5.
func _test_f6_no_flicker() -> void:
	# D steht schraeg hinter b (Richtung 1 von b aus), b schaut nach 3 zu a, nachdem a geschossen hat.
	var specs := _pair_specs("blue", "red", {}, {"aw": 1.0, "ini": 1.0})
	specs.append({"id": "d", "team": "blue", "grid": _line(_line(Vector2i(20, 20), 0, 2), 1, 2), "facing": 4, "ft": "gruppe_d"})
	var f := _fixture(specs)
	_ticks(f, 2)
	_shoot(f, "a", "b")
	var first := _turn_delay(f, "b", 20)
	_check(first >= 1 and _face(f, "b") == 3, "F6: erste Drehung zu a (%d)" % _face(f, "b"))
	_ticks(f, 8)
	_shoot(f, "d", "b")
	_ticks(f, 8)
	_check(_face(f, "b") == 3, "F6: innerhalb von 30 Ticks keine zweite Drehung (%d)" % _face(f, "b"))
	_ticks(f, 40)
	# W1 (Nachbesserung 1): b sieht a noch, also bleibt b bei a, auch wenn d nach 30 Ticks schiesst (alt: dreht zu d).
	_shoot(f, "d", "b")
	_ticks(f, 4)
	_check(_face(f, "b") == 3, "F6: nach 30 Ticks bleibt b bei seinem Bezugsgegner a, solange er ihn sieht (%d)" % _face(f, "b"))
	# Faellt a aus, ist der Bezugsgegner frei und der naechste Schuetze dreht b.
	f.units.a.hp = 0
	_ticks(f, 40)
	_shoot(f, "d", "b")
	_ticks(f, 4)
	_check(_face(f, "b") == 1, "F6: ist a ausgefallen, dreht ein neuer Schuetze (%d)" % _face(f, "b"))
	f.scope.free()
	# Wer ein sichtbares Ziel hat und darauf schiesst, dreht sich nicht weg.
	var g := _fixture(specs)
	_ticks(g, 2)
	_shoot(g, "a", "b")
	_turn_delay(g, "b", 20)
	_ticks(g, 40)
	_shoot(g, "b", "a")
	_check(_face(g, "b") == 3, "F6: b schiesst auf a und sieht zu a")
	_ticks(g, 40)
	_shoot(g, "d", "b")
	_ticks(g, 8)
	_check(_face(g, "b") == 3, "F6: b dreht sich nicht von seinem sichtbaren Ziel a weg (%d)" % _face(g, "b"))
	g.scope.free()


func _run_sequence() -> Array:
	var f := _fixture(_pair_specs("blue", "red", {"hp": 44, "cmd": HOLD}, {"hp": 44}))
	_ticks(f, 3)
	_shoot(f, "b", "a", true)
	var sequence: Array = []
	for step in range(300):
		_combat_tick(f)
		sequence.append([_face(f, "a"), _face(f, "b"), f.units.a.hp, f.units.b.hp])
	f.scope.free()
	return sequence


# W2: Gegnergruppe nur ueber group_id (Taktikprofil), verschiedene fireteam_id; Kamerad ausserhalb der Gruppe dreht nicht.
func _test_w2_group_key() -> void:
	for same_group in [true, false]:
		var specs := _pair_specs("blue", "red", {}, {"ft": "x1", "group_id": "wache"})
		specs.append({"id": "m", "team": "red", "grid": _line(Vector2i(20, 20), 0, 4), "facing": 0, "ft": "x2",
			"group_id": "wache" if same_group else "andere", "aw": 1.0, "ini": 1.0})
		var f := _fixture(specs)
		_ticks(f, 2)
		_shoot(f, "a", "b")
		_ticks(f, 40)
		if same_group:
			_check(_face(f, "m") == 3, "W2: Gegner-Kamerad nur ueber group_id dreht sich mit (%d)" % _face(f, "m"))
		else:
			_check(_face(f, "m") == 0, "W2: Gegner einer anderen group_id dreht sich nicht (%d)" % _face(f, "m"))
		f.scope.free()


# W1: Kreuzfeuer. v steht zwischen zwei Schuetzen aus entgegengesetzten Richtungen (a im Westen, d im Osten), schwach
# (39 Ticks Verzug). v dreht sich einmal zum ersten Schuetzen, bleibt bei ihm, solange er ihn sieht, und schiesst.
func _test_w1_crossfire() -> void:
	for variant in [[false, true], [true, true], [false, false], [true, false]]:
		var swap: bool = variant[0]
		var loop: bool = variant[1]
		var west := "blue" if not swap else "red"
		var east := "red" if not swap else "blue"
		var specs := [
			{"id": "a", "team": west, "grid": Vector2i(18, 20), "facing": 0, "ft": "ga", "hp": 5000},
			{"id": "d", "team": east, "grid": Vector2i(22, 20), "facing": 3, "ft": "gd", "hp": 5000},
			{"id": "v", "team": west if swap else east, "grid": Vector2i(20, 20), "facing": 1, "ft": "gv", "aw": 0.2, "ini": 0.2, "hp": 5000, "cmd": HOLD},
		]
		# v steht auf der Seite von d (gegen a), d und v sind Freunde: fuer das Kreuzfeuer muessen a und d beide Gegner von v sein.
		specs[2]["team"] = "red" if not swap else "blue"
		specs[1]["team"] = "blue" if not swap else "red"
		specs[0]["team"] = "blue" if not swap else "red"
		# v ist dann Gegner beider (Team der Gegenseite); a und d teilen das Team, schiessen aber aus entgegengesetzten Richtungen.
		var f := _fixture(specs)
		_ticks(f, 3)
		var changes := 0
		var last := _face(f, "v")
		var v_shots := 0
		var queued := 0
		var history := ""
		var shooters := ["a", "d"]
		for step in range(600):
			if step % 80 == 0:
				if _shoot(f, shooters[(step / 80) % 2], "v", true):
					queued += 1
			if loop:
				_combat_tick(f)
			else:
				_tick(f)
			var now_face := _face(f, "v")
			if now_face != last:
				changes += 1
				history += "%d:%d " % [step, now_face]
				last = now_face
		for result in f.results:
			if String(result.get("attacker_unit_id", "")) == "v":
				v_shots += 1
		_check(changes <= 1, "W1 swap=%s loop=%s: v dreht sich im Kreuzfeuer hoechstens einmal (%d Drehungen: %s, %d Schuesse eingereiht)" % [swap, loop, changes, history, queued])
		if loop:
			_check(v_shots >= 1, "W1 swap=%s: v gibt Schuesse ab (%d)" % [swap, v_shots])
		f.scope.free()


# F8: gleiche Tickfolge, gleiche Blickrichtungen.
func _test_f8_deterministic() -> void:
	var first := _run_sequence()
	var second := _run_sequence()
	_check(first == second, "F8: zwei Durchlaeufe ergeben dieselbe Folge von Blickrichtungen")
	var changed := false
	for entry in first:
		if entry[0] != 3 or entry[1] != 0:
			changed = true
	_check(changed, "F8: die Folge enthaelt tatsaechlich Drehungen")
