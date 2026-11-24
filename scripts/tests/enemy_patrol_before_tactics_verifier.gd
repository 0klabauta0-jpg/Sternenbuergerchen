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
	## Wenn gesetzt, ersetzt es die Lage aus der Bewegungs-Laufzeit (die Attrappen dieses Aufbaus koennen nicht laufen).
	var fake_hex: Dictionary = {}

	func _patrol_hex_state(simulation_root: Node, unit_id: String) -> Dictionary:
		return fake_hex.duplicate() if not fake_hex.is_empty() else super(simulation_root, unit_id)

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
	_test_non_patrol_styles_use_group_tactics()
	_test_hit_patroller_stops_patrolling()
	_test_fallen_mate_in_sight_stops_patrolling()
	_test_redirected_waypoint_counts_as_reached()
	await process_frame
	print("ENEMY_PATROL_BEFORE_TACTICS passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)


## Gegner "enemy" (Taktik probe) weit weg von "own" (kein Kontakt) oder, mit `contact`, zwei Felder neben ihm.
## `path`: zwei Wegpunkte (Spiegel der Karte: Querweg, nicht Richtung "own"); `locked`: Weg schon kontaktgesperrt.
func _patrol_rig(contact: bool, with_path: bool, locked: bool = false, style: String = "probe") -> Dictionary:
	var far_own := Vector2i(CENTER.x - 7, CENTER.y - 7)
	var far_enemy := Vector2i(CENTER.x + 7, CENTER.y + 7)
	var own_grid: Vector2i = far_enemy + HEX.DIRECTIONS[3] * 2 if contact else far_own
	var specs := _line(own_grid, far_enemy, "pistol", "pistol")
	var f := _rig(specs)
	f.units["enemy"].set_meta("enemy_tactics_config", {"group_id": "wreck_probe", "advance_style": style})
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


## W3 (1g): Die Patrouille geht der Gruppentaktik nur bei Streifen-Gruppen voraus ("patrol"/"probe"/"creep"). Wach-/Flak-Gruppen ("hold"/"defend")
## und Angriffsgruppen ("rush"/"bound") verhalten sich mit Weg wie vorher: die Gruppentaktik zuerst, der Weg wird ohne Kontakt NICHT abgelaufen.
func _test_non_patrol_styles_use_group_tactics() -> void:
	for style in ["hold", "defend", "rush", "bound"]:
		var f := _patrol_rig(false, true, false, style)
		_check(not _hold(f), "8 (%s): Vorbedingung: kein Feindkontakt" % style)
		_run_decisions(f, 45)
		_check(not _sources_of(f, "enemy").has("enemy_patrol"), "8 (%s): mit Weg, ohne Kontakt keine Patrouille (Quellen %s)" % [style, str(_sources_of(f, "enemy"))])
		_check(not bool(f.driver._enemy_patrol_contact_locked.get("enemy", false)), "8 (%s): der Weg bleibt ungesperrt (die Gruppentaktik hat ihn nur uebergangen)" % style)
		f.scope.free()
	for style in ["patrol", "creep"]:
		var g := _patrol_rig(false, true, false, style)
		_run_decisions(g, 3)
		_check(_sources_of(g, "enemy").has("enemy_patrol"), "8 (%s): eine Streifen-Gruppe laeuft den Weg (Quellen %s)" % [style, str(_sources_of(g, "enemy"))])
		g.scope.free()


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


## Quellen der Befehle EINER Einheit.
func _sources_of(f: Dictionary, unit_id: String) -> Array:
	var kinds := {}
	for command in f.driver.commands:
		if String(command.get("unit_id", "")) == unit_id:
			kinds[String(command.get("source_command_type", ""))] = true
	var result: Array = kinds.keys()
	result.sort()
	return result


## Kontakt-Sperre (1f, Aufgabe 4a): Wer Schaden genommen hat, patrouilliert nicht weiter, auch ohne Sichtlinie zum Feind.
func _test_hit_patroller_stops_patrolling() -> void:
	var f := _patrol_rig(false, true)
	_run_decisions(f, 3)
	_check(_sources_of(f, "enemy").has("enemy_patrol"), "5: Vorbedingung: vor dem Treffer patrouilliert er")
	f.units["enemy"].apply_damage(5)
	_check(not _hold(f), "5: Vorbedingung: weiter kein Feind in Sicht und Reichweite")
	f.driver.commands.clear()
	_run_decisions(f, 30)
	_check(not f.driver.commands.is_empty() and not _sources_of(f, "enemy").has("enemy_patrol"), "5: nach einem Treffer keine Patrouille mehr (Quellen %s)" % str(_sources_of(f, "enemy")))
	_check(bool(f.driver._enemy_patrol_contact_locked.get("enemy", false)), "5: der Weg gilt als kontaktgesperrt")
	f.scope.free()


## Kontakt-Sperre (1f, Aufgabe 4a): Ein niedergestreckter Kamerad der Gruppe in Sichtweite sperrt den Patrouillenweg.
func _test_fallen_mate_in_sight_stops_patrolling() -> void:
	var far_own := Vector2i(CENTER.x - 7, CENTER.y - 7)
	var far_enemy := Vector2i(CENTER.x + 7, CENTER.y + 7)
	var specs := _line(far_own, far_enemy, "pistol", "pistol")
	specs.append({"id": "mate", "team": "red", "grid": far_enemy + HEX.DIRECTIONS[1], "facing": 3, "weapon": "pistol", "hp": 10})
	var f := _rig(specs)
	for unit_id in ["enemy", "mate"]:
		f.units[unit_id].set_meta("enemy_tactics_config", {"group_id": "wreck_probe", "advance_style": "probe"})
	var terrain = f.scope.get_node("TerrainRegistry")
	var waypoints: Array = [Vector2(terrain.grid_to_world(Vector2i(CENTER.x + 7, CENTER.y + 1))), Vector2(terrain.grid_to_world(Vector2i(CENTER.x + 7, CENTER.y - 4)))]
	f.driver._enemy_patrol_paths_by_unit_id["enemy"] = waypoints.duplicate(true)
	f.driver._enemy_patrol_waypoint_index_by_unit_id["enemy"] = 0
	f.driver._enemy_patrol_contact_locked["enemy"] = false
	f.units["mate"].apply_damage(50)
	_check(String(f.units["mate"].get_vital_state()) != "fit", "6: Vorbedingung: der Kamerad ist niedergestreckt")
	_check(not _hold(f), "6: Vorbedingung: kein Feind in Sicht und Reichweite")
	_run_decisions(f, 30)
	_check(not _sources_of(f, "enemy").is_empty() and not _sources_of(f, "enemy").has("enemy_patrol"), "6: mit niedergestrecktem Kameraden in Sicht keine Patrouille (Quellen %s)" % str(_sources_of(f, "enemy")))
	_check(bool(f.driver._enemy_patrol_contact_locked.get("enemy", false)), "6: der Weg gilt als kontaktgesperrt")
	f.scope.free()


## Wegpunkt nach Umlenkung (1f, Aufgabe 4b): Hat die Bewegungs-Laufzeit das Ziel eines Patrouillenpunkts auf eine Nachbarzelle umgelenkt
## (Niedergestreckter auf dem Punkt) und ist der Gegner dort "arrived", gilt der Punkt als erreicht und der Weg geht weiter.
## Die Attrappen dieses Aufbaus laufen nicht; die Lage der Bewegung wird deshalb vorgegeben (`fake_hex`). Der echte Auftrag mit
## umgelenktem Ziel steht in hex_goal_unfit_occupant_verifier, die ganze Kette im Wrack-Einsatz.
func _redirect_case(hex_state: Dictionary) -> Dictionary:
	var far_own := Vector2i(CENTER.x - 7, CENTER.y - 7)
	var far_enemy := Vector2i(CENTER.x + 7, CENTER.y + 7)
	var first_cell := Vector2i(CENTER.x + 7, CENTER.y + 1)
	var f := _rig(_line(far_own, far_enemy, "pistol", "pistol"))
	f.units["enemy"].set_meta("enemy_tactics_config", {"group_id": "wreck_probe", "advance_style": "probe"})
	var terrain = f.scope.get_node("TerrainRegistry")
	var waypoints: Array = [Vector2(terrain.grid_to_world(first_cell)), Vector2(terrain.grid_to_world(Vector2i(CENTER.x + 7, CENTER.y - 4)))]
	f["waypoints"] = waypoints
	f["first_cell"] = first_cell
	f.driver._enemy_patrol_paths_by_unit_id["enemy"] = waypoints.duplicate(true)
	f.driver._enemy_patrol_waypoint_index_by_unit_id["enemy"] = 0
	f.driver._enemy_patrol_contact_locked["enemy"] = false
	f.driver.fake_hex = hex_state
	return f


func _test_redirected_waypoint_counts_as_reached() -> void:
	var first_cell := Vector2i(CENTER.x + 7, CENTER.y + 1)
	var beside: Vector2i = first_cell + HEX.DIRECTIONS[0]
	var f := _redirect_case({"status": "arrived", "goal_grid": beside, "grid": beside})
	_run_decisions(f, 3)
	_check(int(f.driver._enemy_patrol_waypoint_index_by_unit_id.get("enemy", 0)) == 1, "7: umgelenkt und angekommen: der Wegpunkt gilt als erreicht, der Index rueckt weiter (Index %s)" % str(f.driver._enemy_patrol_waypoint_index_by_unit_id.get("enemy", 0)))
	var command: Dictionary = f.driver.live.get("enemy", {})
	_check(Vector2(command.get("target_position", Vector2.ZERO)).is_equal_approx(f.waypoints[1]) and String(command.get("source_command_type", "")) == "enemy_patrol", "7: der naechste Patrouillenbefehl geht zum zweiten Wegpunkt")
	f.scope.free()
	# Gegenproben: nichts davon darf den Index weiterschieben.
	var controls: Array = [
		["noch unterwegs (active)", {"status": "active", "goal_grid": beside, "grid": beside}],
		["Auftrag auf dem Wegpunkt selbst, aber 6 Felder entfernt", {"status": "arrived", "goal_grid": first_cell, "grid": first_cell}],
		["Ausweichzelle weiter als 2 Felder vom Wegpunkt", {"status": "arrived", "goal_grid": first_cell + HEX.DIRECTIONS[0] * 4, "grid": first_cell + HEX.DIRECTIONS[0] * 4}],
		["Ziel erreicht, aber nicht dort stehend", {"status": "arrived", "goal_grid": beside, "grid": beside + HEX.DIRECTIONS[0]}],
		["wartet auf besetztes Ziel", {"status": "waiting_reservation", "goal_grid": first_cell, "grid": beside}],
	]
	for control in controls:
		var g := _redirect_case(control[1])
		_run_decisions(g, 3)
		_check(int(g.driver._enemy_patrol_waypoint_index_by_unit_id.get("enemy", 0)) == 0, "7 Gegenprobe %s: der Index bleibt bei 0" % control[0])
		g.scope.free()


func _test_without_path_uses_group_tactics() -> void:
	var f := _patrol_rig(false, false)
	_run_decisions(f, 30)
	_check(not f.driver.commands.is_empty() and _sources(f) == ["enemy_team_tactics"], "4: ohne Weg bewegt die Gruppentaktik wie bisher (Quellen %s)" % str(_sources(f)))
	f.scope.free()
