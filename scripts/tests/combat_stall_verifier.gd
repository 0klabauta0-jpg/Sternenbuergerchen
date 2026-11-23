extends "res://scripts/tests/combat_facing_verifier.gd"
## Stillstand 23.11.2026: Regeln R-B (Sehen im Dreh-/Umsehcode = Erkennungsreichweite), R-C (wer schiesst, verraet sich)
## und R-D (erfolglose Suche endet zur letzten bekannten Gegnerposition). Echte Klassen wie combat_facing_verifier.
## Reichweiten relativ zum Feldabstand s: Kontaktreichweite 2,3 s, Tarnung 0,5 -> Erkennung 1,725 s (ein Feld);
## ein Gegner zwei Felder entfernt ist damit "in Kontaktreichweite sichtbar", aber nicht erkennbar (wie 165 < d <= 220).


func _run() -> void:
	_test_b1_sees_uses_detection_range()
	_test_b2_lookaround_continues()
	_test_b3_own_target_beyond_detection()
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
