extends "res://scripts/tests/combat_facing_verifier.gd"
## Stillstand 23.11.2026: Regeln R-B (Sehen im Dreh-/Umsehcode = Erkennungsreichweite), R-C (wer schiesst, verraet sich)
## und R-D (erfolglose Suche endet zur letzten bekannten Gegnerposition). Echte Klassen wie combat_facing_verifier.
## Reichweiten relativ zum Feldabstand s: Kontaktreichweite 2,3 s, Tarnung 0,5 -> Erkennung 1,725 s (ein Feld);
## ein Gegner zwei Felder entfernt ist damit "in Kontaktreichweite sichtbar", aber nicht erkennbar (wie 165 < d <= 220).


func _run() -> void:
	_test_b1_sees_uses_detection_range()
	_test_b2_lookaround_continues()
	_test_b3_own_target_beyond_detection()
	_test_c_shooter_reveals_himself()
	_test_d_search_ends_toward_last_position()
	await process_frame
	print("combat_stall_verifier passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _spacing(f: Dictionary) -> float:
	var t = f.terrain
	return float(t.get_movement_distance(t.grid_to_world(Vector2i.ZERO), t.grid_to_world(Vector2i(1, 0))))


## Kontaktreichweite so, dass zwei Felder in Kontaktreichweite liegen, ein getarnter Gegner aber nur auf ein Feld erkannt wird.
func _set_ranges(f: Dictionary) -> void:
	f.driver.contact_range = 2.3 * _spacing(f)


func _visible(f: Dictionary, a: String, b: String, range_world: float) -> bool:
	return bool(f.driver._query_current_visibility(f.units[a], f.units[b], range_world).get("visible", false))


func _pre(f: Dictionary, observer: String, opponent: String, tag: String) -> void:
	var in_contact := _visible(f, observer, opponent, f.driver.contact_range)
	var detected := bool(f.driver._has_valid_los(f.units[observer], f.units[opponent]))
	_check(in_contact and not detected, "%s: Ausgangslage %s in Kontaktreichweite sichtbar (%s), aber nicht erkennbar (%s)" % [tag, opponent, in_contact, detected])


# B1: "sieht einen Gegner" beim Umsehen nur in Erkennungsreichweite.
func _test_b1_sees_uses_detection_range() -> void:
	var a_grid := Vector2i(20, 20)
	var f := _fixture([{"id": "a", "team": "blue", "grid": a_grid, "facing": 0, "cmd": HOLD},
		{"id": "b", "team": "red", "grid": _line(a_grid, 0, 2), "facing": 0, "stealth": 0.5}])
	_set_ranges(f)
	_ticks(f, 2)
	_pre(f, "a", "b", "B1")
	_check(not bool(f.driver._facing_unit_sees_opponent(f.units.a)), "B1: Gegner zwei Felder entfernt (nicht erkennbar) gilt beim Umsehen NICHT als gesehen")
	f.scope.free()
	var g := _fixture([{"id": "a", "team": "blue", "grid": a_grid, "facing": 0, "cmd": HOLD},
		{"id": "c", "team": "red", "grid": _line(a_grid, 0, 1), "facing": 0, "stealth": 0.5}])
	_set_ranges(g)
	_ticks(g, 2)
	_check(bool(g.driver._has_valid_los(g.units.a, g.units.c)), "B1: Gegner ein Feld entfernt ist erkennbar")
	_check(bool(g.driver._facing_unit_sees_opponent(g.units.a)), "B1: Gegner ein Feld entfernt gilt beim Umsehen als gesehen")
	g.scope.free()


# B2: Die Suche hoert bei einem nie erkennbaren Gegner nicht auf.
func _test_b2_lookaround_continues() -> void:
	var a_grid := Vector2i(20, 20)
	var f := _fixture([{"id": "a", "team": "blue", "grid": a_grid, "facing": 0, "cmd": HOLD},
		{"id": "b", "team": "red", "grid": _line(a_grid, 0, 2), "facing": 0, "stealth": 0.5}])
	_set_ranges(f)
	_ticks(f, 3)
	_pre(f, "a", "b", "B2")
	_check(_alert(f, "a", _line(a_grid, 0, 2)), "B2: a alarmiert, letzte Position bei b")
	var turns := 0
	var prev := _face(f, "a")
	for step in range(200):
		_combat_tick(f)
		if _face(f, "a") != prev:
			prev = _face(f, "a")
			turns += 1
	_check(turns >= 1, "B2: die Suche laeuft weiter (%d Drehungen in 200 Ticks)" % turns)
	f.scope.free()


# B3: Ein Bezugsgegner ausserhalb der Erkennungsreichweite haelt die Einheit nicht fest; sie dreht sich zum Schuetzen von hinten.
func _test_b3_own_target_beyond_detection() -> void:
	var a_grid := Vector2i(20, 20)
	var f := _fixture([{"id": "a", "team": "blue", "grid": a_grid, "facing": 0, "cmd": HOLD},
		{"id": "b", "team": "red", "grid": _line(a_grid, 0, 2), "facing": 0, "stealth": 0.5},
		{"id": "s", "team": "red", "grid": _line(a_grid, 3, 1), "facing": 0, "stealth": 0.5}])
	_set_ranges(f)
	_ticks(f, 3)
	_pre(f, "a", "b", "B3")
	var now: int = int(f.driver._combat_facing_now())
	f.driver._facing_target_by_unit["a"] = {"target_id": "b", "tick": now, "seen": now}
	var turned_tick := -1
	for step in range(400):
		if step % 40 == 0:
			_shoot(f, "s", "a", false)
		_tick(f)
		if _face(f, "a") == 3:
			turned_tick = step
			break
	_check(turned_tick >= 0, "B3: a dreht sich zum Schuetzen von hinten (Richtung %d, nach %d Ticks)" % [_face(f, "a"), turned_tick])
	f.scope.free()


## Ein getarnter Schuetze s drei Felder vor a (ausserhalb Kontakt- und Erkennungsreichweite, in Waffenreichweite von a).
## variant: "shot_miss", "shot_hit", "no_shot", "blocked" (Sichtlinie durch ein Hindernis verdeckt), "expired" (nach dem Fenster).
func _c_fixture(variant: String) -> Dictionary:
	var a_grid := Vector2i(20, 20)
	# awareness 0,5 wie im Einsatz: die Erkennung braucht einige Ticks (bei 1,0 waere sie sofort fertig und nie zu loeschen).
	var f := _fixture([{"id": "a", "team": "blue", "grid": a_grid, "facing": 0, "cmd": HOLD, "hp": 400, "aw": 0.5},
		{"id": "s", "team": "red", "grid": _line(a_grid, 0, 3), "facing": 3, "stealth": 0.5, "hp": 400}])
	_set_ranges(f)
	if variant == "blocked":
		var wall := _line(a_grid, 0, 2)
		f.terrain.register_tile(TILE.new({"tile_id": str(wall) + "_wall", "grid_position": wall, "world_position": f.terrain.grid_to_world(wall),
			"explicit_hex_ramps": true, "blocks_los": true, "object_height": 3}))
	_ticks(f, 3)
	return f


func _shots_by(f: Dictionary, shooter: String) -> int:
	var count := 0
	for result in f.results:
		if String(Dictionary(result).get("attacker_unit_id", "")) == shooter:
			count += 1
	return count


# C: Wer schiesst, verraet sich (R-C).
func _test_c_shooter_reveals_himself() -> void:
	for variant in ["shot_miss", "shot_hit", "no_shot", "blocked", "expired"]:
		var tag := "C %s" % variant
		var f := _c_fixture(variant)
		var a = f.units.a
		var s = f.units.s
		var weapon_range: float = float(f.driver._get_weapon_attack_range(a, s))
		var open_los := _visible(f, "a", "s", weapon_range)
		_check(not bool(f.driver._has_valid_los(a, s)), "%s: vor dem Schuss erkennt a den Schuetzen nicht" % tag)
		if variant == "blocked":
			_check(not open_los, "%s: Ausgangslage Sichtlinie verdeckt" % tag)
		else:
			_check(open_los and not _visible(f, "a", "s", f.driver.contact_range), "%s: Ausgangslage s in Waffenreichweite sichtbar, ausserhalb der Kontaktreichweite" % tag)
		if variant != "no_shot":
			_shoot(f, "s", "a", variant == "shot_hit")
			_tick(f)  # Schuss im Folgetick aufgeloest
		if variant == "expired":
			_ticks(f, int(f.driver._get_return_fire_window_ticks(a)) + 2)
		var detected_now := bool(f.driver._has_valid_los(a, s))
		var replies_before := _shots_by(f, "a")
		var window: int = int(f.driver._get_return_fire_window_ticks(a))
		for step in range(window):
			_combat_tick(f)
		var replies := _shots_by(f, "a") - replies_before
		if variant in ["shot_miss", "shot_hit"]:
			_check(detected_now, "%s: im Fenster erkennt a den Schuetzen" % tag)
			_check(replies >= 1, "%s: a erwidert das Feuer im Fenster (%d Schuesse)" % [tag, replies])
		else:
			_check(not detected_now, "%s: a erkennt den Schuetzen nicht" % tag)
			_check(replies == 0, "%s: a schiesst nicht (%d)" % [tag, replies])
		f.scope.free()


# D: Eine erfolglose Suche endet nicht mit dem Ruecken zur Front (R-D): nach der letzten Suchdrehung einmal zurueck zur
# Richtung der letzten bekannten Gegnerposition, ohne bekannte Position zur Blickrichtung vor der Suche.
func _test_d_search_ends_toward_last_position() -> void:
	for with_position in [true, false]:
		var tag := "D %s" % ("letzte Position" if with_position else "ohne Position")
		var a_grid := Vector2i(20, 20)
		var f := _fixture([{"id": "a", "team": "blue", "grid": a_grid, "facing": 3, "aw": 1.0, "cmd": HOLD}])
		_ticks(f, 3)
		_check(_alert(f, "a", _line(a_grid, 1, 3)), "%s: alarmiert" % tag)
		if not with_position:
			f.driver._facing_last_enemy_position.erase("a")
		var turns := 0
		var prev := _face(f, "a")
		for step in range(800):
			_combat_tick(f)
			if _face(f, "a") != prev:
				prev = _face(f, "a")
				turns += 1
		var expected := 1 if with_position else 3
		_check(_face(f, "a") == expected, "%s: Endrichtung %d (erwartet %d) nach %d Drehungen" % [tag, _face(f, "a"), expected, turns])
		_check(turns <= 7, "%s: hoechstens sechs Suchdrehungen plus eine Rueckdrehung (%d)" % [tag, turns])
		f.scope.free()
