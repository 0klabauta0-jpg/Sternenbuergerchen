extends "res://scripts/tests/combat_cadence_verifier.gd"
## Kapitel 2 / 1d: Ein Gegner mit Patrouillenweg laeuft ihn vor dem ersten Feindkontakt, statt von der Gruppentaktik ("probe") bewegt zu werden.
## (1) mit Weg, ohne Kontakt: der erste Befehl kommt von der Patrouille, die Einheit nimmt Kurs auf den ersten Wegpunkt (Abstand sinkt);
## (2) mit Weg, aber Feindkontakt (Halten): die Patrouille bleibt aus, es gilt die Gruppentaktik; (3) Weg schon "kontaktgesperrt": wieder die
## Gruppentaktik; (4) ohne Weg: Gruppentaktik wie bisher. Echter Treiber, Test-Attrappe geht dem letzten Bewegungsbefehl nach.
## Schlusszeile: ENEMY_PATROL_BEFORE_TACTICS passed=N failed=M

const WALK_STEP := 1.5  # Welt-Einheiten je Tick, mit denen die Attrappe einem laufenden Bewegungsbefehl folgt


## Treiber, der die Befehle an Gegner mitschreibt; `live` = zuletzt eingereihter Befehl je Einheit.
class PatrolDriver extends QuietDriver:
	var commands: Array = []
	var live: Dictionary = {}

	func _enqueue_enemy_behavior_command(simulation_root: Node, command: Dictionary) -> bool:
		commands.append(command.duplicate(true))
		live[String(command.get("unit_id", ""))] = command.duplicate(true)
		return super(simulation_root, command)


func _make_driver():
	return PatrolDriver.new()


func _run() -> void:
	CADENCE.override_config_for_test({"cadence_scale": 1.0, "reaction_initiative_ticks": 20})
	_test_patrol_before_tactics()
	_test_contact_uses_group_tactics()
	_test_locked_path_uses_group_tactics()
	_test_without_path_uses_group_tactics()
	await process_frame
	print("ENEMY_PATROL_BEFORE_TACTICS passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)


## Gegner "enemy" (Taktik probe) weit weg von "own" (kein Kontakt) oder, mit `contact`, zwei Felder neben ihm.
## `path`: zwei Wegpunkte (Spiegel der Karte: Querweg, nicht Richtung "own"); `locked`: Weg schon kontaktgesperrt.
func _patrol_rig(contact: bool, with_path: bool, locked: bool = false) -> Dictionary:
	var far_own := Vector2i(CENTER.x - 7, CENTER.y - 7)
	var far_enemy := Vector2i(CENTER.x + 7, CENTER.y + 7)
	var own_grid: Vector2i = far_enemy + HEX.DIRECTIONS[3] * 2 if contact else far_own
	var specs := _line(own_grid, far_enemy, "pistol", "pistol")
	var f := _rig(specs)
	f.units["enemy"].set_meta("enemy_tactics_config", {"group_id": "wreck_probe", "advance_style": "probe"})
	var terrain = f.scope.get_node("TerrainRegistry")
	var waypoints: Array = [Vector2(terrain.grid_to_world(Vector2i(CENTER.x + 7, CENTER.y + 1))), Vector2(terrain.grid_to_world(Vector2i(CENTER.x + 7, CENTER.y - 4)))]
	f["waypoints"] = waypoints
	if with_path:
		f.driver._enemy_patrol_paths_by_unit_id["enemy"] = waypoints.duplicate(true)
		f.driver._enemy_patrol_waypoint_index_by_unit_id["enemy"] = 0
		f.driver._enemy_patrol_contact_locked["enemy"] = locked
	return f


func _walk_enemy(f: Dictionary) -> void:
	var command: Dictionary = f.driver.live.get("enemy", {})
	if String(command.get("command_type", "")) != "move_to_position":
		return
	var unit: Node2D = f.units["enemy"]
	var offset: Vector2 = Vector2(command.get("target_position", unit.position)) - unit.position
	if offset.length() <= WALK_STEP:
		unit.position += offset
		f.driver.live.erase("enemy")
	else:
		unit.position += offset.normalized() * WALK_STEP


## `ticks` Ticks; alle 3 Ticks entscheidet der Treiber ueber die Gegner (Gruppentaktik neu rechnen, dann vorruecken/patrouillieren).
func _run_decisions(f: Dictionary, ticks: int) -> void:
	for i in range(ticks):
		_tick(f)
		_walk_enemy(f)
		if f.sim.tick_counter % 3 == 0:
			f.driver._update_enemy_team_tactics_state()
			f.driver._advance_enemy_units(f.sim)


func _sources(f: Dictionary) -> Array:
	var kinds := {}
	for command in f.driver.commands:
		kinds[String(command.get("source_command_type", ""))] = true
	var result: Array = kinds.keys()
	result.sort()
	return result


func _hold(f: Dictionary) -> bool:
	return bool(f.driver._enemy_should_hold_position(f.units["enemy"]))


func _test_patrol_before_tactics() -> void:
	var f := _patrol_rig(false, true)
	_check(not _hold(f), "1: Vorbedingung: kein Feindkontakt")
	var start: float = f.units["enemy"].position.distance_to(f.waypoints[0])
	_run_decisions(f, 3)
	_check(not f.driver.commands.is_empty() and String(f.driver.commands[0].get("source_command_type", "")) == "enemy_patrol", "1: der erste Befehl kommt von der Patrouille (Quellen %s)" % str(_sources(f)))
	_check(not f.driver.commands.is_empty() and Vector2(f.driver.commands[0].get("target_position", Vector2.ZERO)).is_equal_approx(f.waypoints[0]), "1: Ziel ist der erste Wegpunkt")
	_run_decisions(f, 90)
	var after: float = f.units["enemy"].position.distance_to(f.waypoints[0])
	_check(after < start - 50.0, "1: der Abstand zum ersten Wegpunkt sinkt (%.0f -> %.0f)" % [start, after])
	_check(not _sources(f).has("enemy_team_tactics"), "1: die Gruppentaktik bewegt die Einheit nicht (Quellen %s)" % str(_sources(f)))
	f.scope.free()


func _test_contact_uses_group_tactics() -> void:
	var f := _patrol_rig(true, true)
	_check(_hold(f), "2: Vorbedingung: Feindkontakt (Halten)")
	_run_decisions(f, 30)
	_check(not _sources(f).has("enemy_patrol"), "2: bei Feindkontakt keine Patrouille (Quellen %s)" % str(_sources(f)))
	f.scope.free()


func _test_locked_path_uses_group_tactics() -> void:
	var f := _patrol_rig(false, true, true)
	_run_decisions(f, 30)
	_check(not f.driver.commands.is_empty() and not _sources(f).has("enemy_patrol"), "3: kontaktgesperrter Weg: wieder die Gruppentaktik (Quellen %s)" % str(_sources(f)))
	f.scope.free()


func _test_without_path_uses_group_tactics() -> void:
	var f := _patrol_rig(false, false)
	_run_decisions(f, 30)
	_check(not f.driver.commands.is_empty() and _sources(f) == ["enemy_team_tactics"], "4: ohne Weg bewegt die Gruppentaktik wie bisher (Quellen %s)" % str(_sources(f)))
	f.scope.free()
