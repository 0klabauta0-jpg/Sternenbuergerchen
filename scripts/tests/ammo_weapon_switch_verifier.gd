extends "res://scripts/tests/ammo_combat_verifier.gd"
## M6c (24.11.2026): Leere Waffe. C1: Ist die Hauptwaffe WIRKLICH leer (Zustand "empty", nicht "laedt nach") und traegt die Einheit eine
## zweite Angriffswaffe mit Munition im Magazin, wechselt sie darauf (Dauer = Nachladedauer der Zielwaffe, 30 x 6 = 180 Ticks bei der
## Pistole); zurueck auf Platz 1 bei Respawn und sobald die Hauptwaffe wieder Munition hat. C2: eine einmalige Zeile fuer den Spieler
## (Wechsel / "Keine Munition mehr."). C3: ein Gegner ganz ohne Munition sucht Deckung (vorhandener Deckungsbefehl), eigene Trupps nicht.
## Echter Treiber und echte Versorgung wie ammo_combat_verifier (dessen _ammo_rig/_duel/_run_ticks benutzt werden).
## Schlusszeile: AMMO_WEAPON_SWITCH passed=N failed=M

const RIFLE_MAG := 40  # wirksam: 20 (Waffendaten) x magazine_scale 2
const SWITCH_TICKS := 180  # Pistole: reload_ticks 30 x reload_scale 6
const TEST_UNIT = preload("res://scripts/npc/test_unit.gd")


## Treiber, der die Befehle an Gegner mitschreibt (Tick, Befehl), bevor er sie wie gewohnt einreiht.
class SwitchDriver extends AmmoDriver:
	var commands: Array = []

	func _enqueue_enemy_behavior_command(simulation_root: Node, command: Dictionary) -> bool:
		commands.append({"tick": _current_tick, "command": command.duplicate(true)})
		return super(simulation_root, command)


## Ersatz fuer den Taktik-Controller: nimmt die Kommunikationsereignisse (= Zeilen der Ereignisliste) entgegen.
class FakeController extends Node:
	var events: Array = []

	func record_tactical_communication_event(event_type: String, context: Dictionary = {}, _options: Dictionary = {}) -> Dictionary:
		events.append({"type": event_type, "text": String(context.get("short_text", "")), "unit_id": String(context.get("unit_id", ""))})
		return {}


func _make_driver():
	return SwitchDriver.new()


func _run() -> void:
	CADENCE.override_config_for_test({"cadence_scale": 1.0, "reaction_initiative_ticks": 20})
	_test_w1_switch_to_second_weapon()
	_test_w2_reloading_is_no_reason_to_switch()
	_test_w3_nothing_to_switch_to()
	_test_w4_back_to_main_weapon()
	_test_w5_no_change_without_empty_weapon()
	_test_m1_message_once()
	_test_g1_enemy_without_ammo_seeks_cover()
	_test_g2_own_squad_without_ammo_gets_no_order()
	await process_frame
	print("AMMO_WEAPON_SWITCH passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)

	_test_p1_default_second_weapon_is_no_weapon()
	_test_p2_given_second_weapon_switches_on_real_unit()
	_test_p3_enemy_spawn_path_has_no_second_weapon()

# ---- Hilfen ------------------------------------------------------------------------------------------------------

## Eigene Einheit "own" (Name Anna): Gewehr als Hauptwaffe (aktiv), Pistole als Zweitwaffe; Gegner "enemy" ohne Waffe daneben.
func _wrig(own_extra: Dictionary = {}, reserves: Dictionary = {}, enemy_weapon: String = "none") -> Dictionary:
	var extra := {"weapon_1": "rifle", "weapon_2": "pistol", "name": "Anna"}
	extra.merge(own_extra, true)
	var f := _ammo_rig(_duel("rifle", enemy_weapon, extra), reserves)
	_add_controller(f)
	return f


func _add_controller(f: Dictionary) -> void:
	var ctl := FakeController.new()
	ctl.name = "TacticalController"
	f.scope.add_child(ctl)
	f["ctl"] = ctl


func _gaps(ticks: Array) -> Array:
	var gaps: Array = []
	for i in range(1, ticks.size()):
		gaps.append(int(ticks[i]) - int(ticks[i - 1]))
	return gaps


func _all_equal(values: Array, expected: int) -> bool:
	for v in values:
		if int(v) != expected:
			return false
	return not values.is_empty()


# ---- Tests -------------------------------------------------------------------------------------------------------

## W1: Gewehr (Magazin und Vorrat leer) -> nach der Wechselzeit ist die Pistole aktiv; es fallen Schuesse mit Pistolen-Takt (9 statt 12 Ticks)
## und -Reichweite; das Pistolen-Magazin sinkt. Waehrend des Wechsels (180 Ticks) faellt kein Schuss.
func _test_w1_switch_to_second_weapon() -> void:
	var f := _wrig()
	var own = f.units["own"]
	var range_main: float = f.driver._get_weapon_attack_range(own, f.units["enemy"])
	_run_until_shots(f, "own", RIFLE_MAG)
	var last_rifle_tick: int = int(f.calls[-1].tick)
	var rifle_ticks := _shot_ticks(f, "own")
	_check(rifle_ticks.size() == RIFLE_MAG and _all_equal(_gaps(rifle_ticks), 12), "W1: Vorbedingung: 40 Gewehrschuesse im Takt von 12 Ticks (%d, Luecken %s)" % [rifle_ticks.size(), str(_gaps(rifle_ticks).slice(0, 3))])
	_check(String(f.driver.get_unit_ammo_status("own").get("state", "")) != "empty" and own.get_combat_weapon_slot() == 2 and own.get_active_weapon_id() == "pistol", "W1: mit dem letzten Schuss ist die Hauptwaffe leer, die Einheit steht auf Platz 2, aktive Waffe Pistole (Platz %d, %s)" % [own.get_combat_weapon_slot(), own.get_active_weapon_id()])
	var st := _status(f, "own")
	_check(String(st.get("state", "")) == "ready" and int(st.get("rounds", 0)) == PISTOL_MAG and int(st.get("magazine_size", 0)) == PISTOL_MAG, "W1: die Anzeige folgt der Pistole (%s)" % str(st))
	_check(f.driver.get_unit_ammo_text("own") == "Mun. 24/24 +0", "W1: Kartentext zeigt die Pistole, Vorrat 0 (%s)" % f.driver.get_unit_ammo_text("own"))
	_run_ticks(f, SWITCH_TICKS - 3)
	_check(_shots_by(f, "own") == RIFLE_MAG, "W1: waehrend des Wechsels (180 Ticks) feuert die Einheit nicht")
	_run_ticks(f, 60 + 3)
	var after: Array = []
	for tick in _shot_ticks(f, "own"):
		if int(tick) > last_rifle_tick:
			after.append(int(tick))
	_check(not after.is_empty() and int(after[0]) - last_rifle_tick >= SWITCH_TICKS and int(after[0]) - last_rifle_tick <= SWITCH_TICKS + 12, "W1: der erste Pistolenschuss faellt nach der Wechselzeit (%s)" % (str(int(after[0]) - last_rifle_tick) if not after.is_empty() else "keiner"))
	_check(after.size() >= 4 and _all_equal(_gaps(after), 9), "W1: Pistolen-Takt 9 Ticks statt 12 (%s)" % str(_gaps(after)))
	_check(int(_status(f, "own").get("rounds", -1)) == PISTOL_MAG - after.size(), "W1: das Pistolen-Magazin sinkt mit jedem Schuss (%d Schuesse, rounds %s)" % [after.size(), str(_status(f, "own").get("rounds"))])
	var range_second: float = f.driver._get_weapon_attack_range(own, f.units["enemy"])
	_check(range_second > 0.0 and range_second < range_main, "W1: Reichweite der Pistole (%.0f) statt der des Gewehrs (%.0f)" % [range_second, range_main])
	_check(int(f.driver._ammo_tracker().shots_fired("own", "rifle")) == RIFLE_MAG and int(f.driver._ammo_tracker().shots_fired("own", "pistol")) == after.size(), "W1: die Schuesse sind je Waffe gebucht")
	f.scope.free()


## W2: Das Gewehr ist nur "leer, laedt nach" (Vorrat da): KEIN Wechsel, die Pistole bleibt unberuehrt.
func _test_w2_reloading_is_no_reason_to_switch() -> void:
	var f := _wrig({}, {"own": {"ammo_rifle": 1}})
	var own = f.units["own"]
	_run_until_shots(f, "own", RIFLE_MAG)
	_check(String(_status(f, "own").get("state", "")) == "reloading", "W2: Vorbedingung: nach dem 40. Schuss laedt das Gewehr nach (%s)" % str(_status(f, "own")))
	_run_ticks(f, 120)
	_check(own.get_combat_weapon_slot() == 1 and own.get_active_weapon_id() == "rifle" and _shots_by(f, "own") == RIFLE_MAG, "W2: beim Nachladen kein Wechsel, kein Schuss (Platz %d, %s)" % [own.get_combat_weapon_slot(), own.get_active_weapon_id()])
	var pistol: Dictionary = f.driver._ammo_tracker().status("own", "pistol", f.driver._current_tick, false)
	_check(int(pistol.get("rounds", 0)) == PISTOL_MAG and int(f.driver._ammo_tracker().shots_fired("own", "pistol")) == 0, "W2: die Pistole bleibt voll und unbenutzt")
	_run_ticks(f, 200)
	_check(_shots_by(f, "own") > RIFLE_MAG and own.get_combat_weapon_slot() == 1 and own.get_active_weapon_id() == "rifle" and f.driver._ammo_tracker().shots_fired("own", "pistol") == 0, "W2: danach schiesst das Gewehr weiter (%d Schuesse)" % _shots_by(f, "own"))
	_check(f.ctl.events.is_empty(), "W2: keine Meldung beim normalen Nachladen (%s)" % str(f.ctl.events))
	f.scope.free()


## W3: Die Zweitwaffe ist ebenfalls leer bzw. es gibt keine: kein Wechsel zurueck/hin, die Einheit ist "ganz leer" (Anzeige, kein Schuss mehr).
func _test_w3_nothing_to_switch_to() -> void:
	var a := _wrig()
	var own_a = a.units["own"]
	var ra := _run_until_empty(a, "own")
	_check(int(ra.shots) == RIFLE_MAG + PISTOL_MAG and String(_status(a, "own").get("state", "")) == "empty", "W3: Gewehr 40 + Pistole 24 Schuesse, dann ganz leer (%d)" % int(ra.shots))
	_check(int(ra.shots_later) == int(ra.shots) and own_a.get_combat_weapon_slot() == 2 and a.driver._ammo_fully_empty_ids.has("own"), "W3: danach kein Schuss, kein Hin-und-Her-Wechseln (Platz %d), Einheit gilt als ganz leer" % own_a.get_combat_weapon_slot())
	_check(a.driver.get_unit_ammo_text("own") == "Keine Munition", "W3: Anzeige 'Keine Munition'")
	a.scope.free()
	var b := _wrig({"weapon_2": ""})
	var own_b = b.units["own"]
	var rb := _run_until_empty(b, "own")
	_check(int(rb.shots) == RIFLE_MAG and own_b.get_combat_weapon_slot() == 1 and own_b.get_active_weapon_id() == "rifle", "W3: ohne Zweitwaffe 40 Schuesse, kein Wechsel (Platz %d)" % own_b.get_combat_weapon_slot())
	_check(b.driver._ammo_fully_empty_ids.has("own") and int(rb.shots_later) == int(rb.shots), "W3: ohne Zweitwaffe ist die Einheit ganz leer, schiesst nicht mehr")
	b.scope.free()
	var c := _wrig({"weapon_2": "rifle"})
	var rc := _run_until_empty(c, "own")
	_check(int(rc.shots) == RIFLE_MAG and c.units["own"].get_combat_weapon_slot() == 1, "W3: gleiche Waffe als Zweitwaffe (gleiches Magazin) ist kein Wechselziel (%d Schuesse)" % int(rc.shots))
	c.scope.free()


## W4: Hauptwaffe bekommt wieder Munition (Auffuellen im Feld) -> zurueck auf Platz 1 (ohne Meldung); Respawn -> Platz 1.
func _test_w4_back_to_main_weapon() -> void:
	var f := _wrig()
	var own = f.units["own"]
	_run_until_shots(f, "own", RIFLE_MAG + 3)
	_check(own.get_combat_weapon_slot() == 2, "W4: Vorbedingung: auf der Pistole")
	_stock(f.sup, "own", "ammo_rifle", 1)
	var guard := 0
	while own.get_combat_weapon_slot() != 1 and guard < 40:
		_run_ticks(f, 3)
		guard += 1
	var back_tick: int = f.sim.tick_counter
	_check(own.get_combat_weapon_slot() == 1 and own.get_active_weapon_id() == "rifle", "W4: nach dem Auffuellen steht die Einheit wieder auf Platz 1, aktive Waffe Gewehr")
	_check(f.ctl.events.size() == 1, "W4: der Rueckwechsel macht keine Meldung (nur die vom Hinwechsel: %d)" % f.ctl.events.size())
	var shots_back: int = _shots_by(f, "own")
	_run_ticks(f, SWITCH_TICKS - 6)
	_check(_shots_by(f, "own") == shots_back, "W4: der Rueckwechsel kostet ebenfalls Zeit (kein Schuss in den ersten 174 Ticks)")
	_run_ticks(f, 120)
	var later: Array = []
	for tick in _shot_ticks(f, "own"):
		if int(tick) > back_tick:
			later.append(int(tick))
	_check(later.size() >= 3 and int(later[0]) - back_tick >= SWITCH_TICKS and _all_equal(_gaps(later), 12), "W4: danach schiesst das Gewehr wieder im Takt von 12 Ticks (%s)" % str(later.slice(0, 4)))
	f.scope.free()
	var g := _wrig()
	var own_g = g.units["own"]
	var rg := _run_until_empty(g, "own")
	_check(int(rg.shots) == RIFLE_MAG + PISTOL_MAG and own_g.get_combat_weapon_slot() == 2, "W4: Vorbedingung: ganz leer auf Platz 2")
	g.driver._on_unit_respawn_completed("own")
	_check(own_g.get_combat_weapon_slot() == 1 and own_g.get_active_weapon_id() == "rifle" and not g.driver._ammo_fully_empty_ids.has("own"), "W4: Respawn: Platz 1, Gewehr aktiv, nicht mehr ganz leer")
	var st := _status(g, "own")
	_check(String(st.get("state", "")) == "ready" and int(st.get("rounds", 0)) == RIFLE_MAG, "W4: Respawn: Gewehr voll (%s)" % str(st))
	var before := _shots_by(g, "own")
	_run_ticks(g, 60)
	_check(_shots_by(g, "own") > before, "W4: nach dem Respawn schiesst sie sofort wieder, ohne Wechselpause")
	g.scope.free()


## W5: Ohne leere Waffe verhaelt sich das Gefecht wie vorher: dieselbe Schussfolge mit und ohne Zweitwaffe, und dieselben festen Zahlen
## wie in ammo_combat_verifier (A1: Pistole 24 Schuesse, dann leer).
func _test_w5_no_change_without_empty_weapon() -> void:
	var with_second := _wrig()
	var without_second := _ammo_rig(_duel("rifle", "none", {"weapon_1": "rifle"}), {})
	var enemy_armed := _wrig({}, {}, "pistol")
	var enemy_ref := _ammo_rig(_duel("rifle", "pistol", {"weapon_1": "rifle"}), {})
	for f in [with_second, without_second, enemy_armed, enemy_ref]:
		_run_ticks(f, 400)
	var a_ticks: Array = []
	var b_ticks: Array = []
	for entry in with_second.calls:
		a_ticks.append([int(entry.tick), Array(entry.shooters)])
	for entry in without_second.calls:
		b_ticks.append([int(entry.tick), Array(entry.shooters)])
	_check(a_ticks == b_ticks and _shots_by(with_second, "own") > 20 and _shots_by(with_second, "own") < RIFLE_MAG, "W5: 400 Ticks Gewehr: gleiche Schussfolge mit und ohne Zweitwaffe (%d Schuesse)" % _shots_by(with_second, "own"))
	_check(_shot_ticks(enemy_armed, "own") == _shot_ticks(enemy_ref, "own") and _shot_ticks(enemy_armed, "enemy") == _shot_ticks(enemy_ref, "enemy") and _shots_by(enemy_armed, "enemy") > 0, "W5: auch mit bewaffnetem Gegner gleiche Schussfolge beider Seiten")
	_check(with_second.units["own"].get_combat_weapon_slot() == 1 and with_second.ctl.events.is_empty() and with_second.driver._ammo_slot2_ids.is_empty(), "W5: nichts gewechselt, nichts gemeldet")
	for f in [with_second, without_second, enemy_armed, enemy_ref]:
		f.scope.free()
	var same := _wrig({"weapon": "pistol", "weapon_1": "pistol", "weapon_2": "pistol"})
	_run_ticks(same, 600)
	_check(_shots_by(same, "own") == PISTOL_MAG and same.units["own"].get_combat_weapon_slot() == 1, "W5: wie A1: Pistole als Haupt- und Zweitwaffe: 24 Schuesse, dann leer, kein Wechsel (%d)" % _shots_by(same, "own"))
	same.scope.free()


## M1 (C2): Wechselt eine eigene Einheit, steht genau EINE Zeile "<Name>: Hauptwaffe leer – wechselt auf <Waffe>." in der Ereignisliste;
## ist sie ganz leer, genau eine Zeile "<Name>: Keine Munition mehr."; ohne Auffuellen kein zweites Mal, danach (Auffuellen, wieder leer) wieder.
func _test_m1_message_once() -> void:
	var f := _wrig()
	_run_until_shots(f, "own", RIFLE_MAG + 1)
	var texts: Array = []
	for e in f.ctl.events:
		texts.append(String(e.text))
	_check(texts == ["Anna: Hauptwaffe leer – wechselt auf Pistole."], "M1: genau eine Wechselzeile (%s)" % str(texts))
	_check(f.ctl.events.size() == 1 and String(f.ctl.events[0].type) == "ammo_report" and String(f.ctl.events[0].unit_id) == "own", "M1: Ereignisart ammo_report, Einheit own")
	var r := _run_until_empty(f, "own")
	_check(int(r.shots) == RIFLE_MAG + PISTOL_MAG, "M1: Vorbedingung: ganz leer (%d)" % int(r.shots))
	texts = []
	for e in f.ctl.events:
		texts.append(String(e.text))
	_check(texts == ["Anna: Hauptwaffe leer – wechselt auf Pistole.", "Anna: Keine Munition mehr."], "M1: danach genau eine Zeile 'Keine Munition mehr.' (%s)" % str(texts))
	_run_ticks(f, 900)
	_check(f.ctl.events.size() == 2, "M1: ohne Auffuellen kommt keine weitere Zeile (%d)" % f.ctl.events.size())
	_stock(f.sup, "own", "ammo_rifle", 1)
	_run_until_shots(f, "own", RIFLE_MAG + PISTOL_MAG + RIFLE_MAG, 400)
	_run_ticks(f, 30)
	_check(f.ctl.events.size() == 3 and String(f.ctl.events[2].text) == "Anna: Keine Munition mehr.", "M1: nach Auffuellen und erneutem Leerschiessen darf die Zeile wieder kommen (%d Zeilen)" % f.ctl.events.size())
	f.scope.free()


## Schiesst die Einheit mit dem echten Munitions-Tor (Frage "darf schiessen", Buchung) in jedem Tick, bis sie ganz leer ist.
func _drain(f: Dictionary, unit_id: String, limit: int = 4000) -> int:
	var unit = f.units[unit_id]
	for i in range(limit):
		_tick(f)
		if f.driver._ammo_unit_can_fire(unit_id, unit):
			f.driver._ammo_note_shot(unit)
		if f.driver._ammo_fully_empty_ids.has(unit_id):
			return i
	return -1


## Laeuft `ticks` Ticks; in jedem Entscheidungsschritt (3 Ticks) entscheidet der Treiber ueber die Gegner (Vorruecken/Patrouille/Deckung).
func _run_enemy_decisions(f: Dictionary, ticks: int) -> void:
	for i in range(ticks):
		_tick(f)
		if f.sim.tick_counter % 3 == 0:
			f.driver._advance_enemy_units(f.sim)


func _cover_commands(f: Dictionary, unit_id: String) -> Array:
	var found: Array = []
	for entry in f.driver.commands:
		if String(entry.command.get("unit_id", "")) == unit_id and String(entry.command.get("enemy_bt_action", "")) == "seek_cover":
			found.append(entry)
	return found


## G1 (C3): Ein Gegner ganz ohne Munition loest den Deckungsbefehl aus (einmal je Abkuehlzeit), ruecken nicht weiter vor, patrouilliert nicht.
## Die Einheiten stehen weit auseinander (kein Kontakt): ein Gegner MIT Munition rueckt dann vor und sucht keine Deckung.
func _test_g1_enemy_without_ammo_seeks_cover() -> void:
	var far_own := Vector2i(CENTER.x - 7, CENTER.y - 7)
	var far_enemy := Vector2i(CENTER.x + 7, CENTER.y + 7)
	var specs := _line(far_own, far_enemy, "pistol", "pistol")
	specs[1]["weapon_1"] = "pistol"
	var f := _ammo_rig(specs, {})
	_add_controller(f)
	# Deckung in der Naehe des Gegners (zwei Felder mit Deckungswert), sonst gibt es fuer den Deckungsbefehl kein Ziel.
	var terrain = f.scope.get_node("TerrainRegistry")
	for dir_index in [1, 2]:
		var cover_grid: Vector2i = far_enemy + HEX.DIRECTIONS[dir_index]
		terrain.register_tile(TILE.new({"tile_id": str(cover_grid), "grid_position": cover_grid, "world_position": terrain.grid_to_world(cover_grid), "explicit_hex_ramps": true, "cover_value": 60}))
	_run_enemy_decisions(f, 120)
	var advancing: Array = f.driver.commands.duplicate()
	var advance_kinds := {}
	for entry in advancing:
		advance_kinds[String(entry.command.get("source_command_type", ""))] = true
	_check(not advancing.is_empty() and _cover_commands(f, "enemy").is_empty(), "G1: Kontrolle: mit Munition und ohne Kontakt rueckt der Gegner vor, keine Deckung (%s)" % str(advance_kinds.keys()))
	var drained := _drain(f, "enemy")
	_check(drained >= 0 and f.driver.get_unit_ammo_text("enemy") == "Keine Munition", "G1: Vorbedingung: der Gegner ist ganz leer (nach %d Ticks)" % drained)
	f.driver.commands.clear()
	var start_tick: int = f.sim.tick_counter
	_run_enemy_decisions(f, 400)
	var kinds := {}
	for entry in f.driver.commands:
		kinds[String(entry.command.get("source_command_type", ""))] = true
		_check(String(entry.command.get("enemy_bt_action", "")) == "seek_cover", "G1: jeder Befehl des leeren Gegners ist der Deckungsbefehl (%s)" % str(entry.command.get("source_command_type", "")))
	var cover := _cover_commands(f, "enemy")
	_check(cover.size() >= 2 and kinds.size() == 1, "G1: der leere Gegner sucht Deckung und rueckt nicht weiter vor (%d Deckungsbefehle, Arten %s)" % [cover.size(), str(kinds.keys())])
	var spaced := true
	for i in range(1, cover.size()):
		if int(cover[i].tick) - int(cover[i - 1].tick) < f.driver.enemy_limbo_cover_cooldown_ticks:
			spaced = false
	_check(spaced and cover.size() <= 400 / f.driver.enemy_limbo_cover_cooldown_ticks + 1, "G1: der Deckungsbefehl kommt hoechstens einmal je Abkuehlzeit (%d in 400 Ticks, Ticks %s)" % [cover.size(), str(cover.map(func(e): return int(e.tick) - start_tick))])
	_check(f.ctl.events.is_empty(), "G1: fuer Gegner gibt es keine Spielermeldung (%s)" % str(f.ctl.events))
	f.scope.free()


## G2 (C3): Ein eigener Trupp ganz ohne Munition bekommt keinen automatischen Befehl (nur C1 und C2 gelten fuer ihn).
func _test_g2_own_squad_without_ammo_gets_no_order() -> void:
	var f := _ammo_rig(_duel("pistol", "none", {"name": "Anna"}), {})
	_add_controller(f)
	_run_ticks(f, 600)
	_check(f.driver._ammo_fully_empty_ids.has("own") and f.driver.get_unit_ammo_text("own") == "Keine Munition", "G2: Vorbedingung: der eigene Schuetze ist ganz leer")
	f.driver.commands.clear()
	_run_enemy_decisions(f, 300)
	f.driver._apply_friendly_standard_behavior(f.sim)
	var own_orders := 0
	for entry in f.driver.commands:
		if String(entry.command.get("unit_id", "")) == "own":
			own_orders += 1
	_check(own_orders == 0, "G2: kein automatischer Befehl fuer den eigenen Trupp (%d)" % own_orders)
	_check(f.ctl.events.size() == 1 and String(f.ctl.events[0].text) == "Anna: Keine Munition mehr.", "G2: aber die einmalige Meldung ist da (%s)" % str(f.ctl.events))
	f.scope.free()
# ---- W2: Zweitwaffe nur, wenn sie wirklich gegeben wurde (echte Einheit TestUnit) ---------------------------------

## Echte TestUnit ohne Szene (wie die Spielwege sie ausruesten: apply_identity_config). Die Kennung gehoert zu keiner Attrappe des Aufbaus.
func _real_unit(unit_id: String, team: String, config: Dictionary):
	var unit = TEST_UNIT.new()
	var full := {"unit_id": unit_id, "team_id": team}
	full.merge(config, true)
	unit.apply_identity_config(full, false)
	return unit


## Aufbau mit einer eigenen Attrappe "real" (Versorgung der Kennung) und dem Gegner; die echte Einheit benutzt dieselbe Kennung.
func _real_rig() -> Dictionary:
	var specs := _duel("rifle", "none", {"weapon_1": "rifle", "name": "Anna"})
	specs.append({"id": "real", "team": "blue", "grid": CENTER + HEX.DIRECTIONS[2], "facing": 0, "weapon": "pistol"})
	var f := _ammo_rig(specs, {})
	_add_controller(f)
	return f


## Wie _drain, aber mit einer frei gegebenen Einheit (nicht aus dem Aufbau). Gibt die Zahl der Schuesse zurueck, bis ganz leer.
func _drain_unit(f: Dictionary, unit_id: String, unit, limit: int = 5000) -> int:
	var shots := 0
	for i in range(limit):
		_tick(f)
		if f.driver._ammo_unit_can_fire(unit_id, unit):
			f.driver._ammo_note_shot(unit)
			shots += 1
		if f.driver._ammo_fully_empty_ids.has(unit_id):
			return shots
	return -1


func _event_texts(f: Dictionary) -> Array:
	var texts: Array = []
	for e in f.ctl.events:
		texts.append(String(e.text))
	return texts


## P1 (W2): Die Vorgabe weapon_2_id = "rifle" ist KEINE Zweitwaffe. Eine Einheit, deren Zweitwaffe nie gesetzt wurde, wechselt mit leerer
## Pistole NICHT auf ein Phantom-Gewehr, sondern ist ganz leer. get_active_weapon_id bleibt fuer sie wie vorher (Rueckfall auf die Vorgabe).
func _test_p1_default_second_weapon_is_no_weapon() -> void:
	var f := _real_rig()
	var unit = _real_unit("real", "blue", {"weapon_1_id": "pistol"})
	_check(unit.get_weapon_2_id() == "rifle" and not unit.is_weapon_2_explicit(), "P1: Vorbedingung: Zweitwaffe nur die Vorgabe 'rifle', nicht gesetzt")
	var shots := _drain_unit(f, "real", unit)
	_check(shots == PISTOL_MAG and unit.get_combat_weapon_slot() == 1 and unit.get_active_weapon_id() == "pistol", "P1: 24 Pistolenschuesse, dann ganz leer, kein Wechsel auf das Vorgabe-Gewehr (%d Schuesse, Platz %d)" % [shots, unit.get_combat_weapon_slot()])
	_check(int(f.driver._ammo_tracker().shots_fired("real", "rifle")) == 0 and _event_texts(f) == ["Test Unit: Keine Munition mehr."], "P1: nur die Meldung 'Keine Munition mehr.' (%s)" % str(_event_texts(f)))
	unit.free()
	# Bitgleich: ohne ausdruecklich gesetzte Zweitwaffe liefert get_active_weapon_id weiter die Vorgabe, wenn Waffe 1 keine Angriffswaffe ist.
	var no_main = _real_unit("real_b", "blue", {"weapon_1_id": "none"})
	_check(no_main.get_active_weapon_id() == "rifle" and not no_main.is_weapon_2_explicit(), "P1: Rueckfall 'Waffe 1 keine Angriffswaffe -> Waffe 2' unveraendert (%s)" % no_main.get_active_weapon_id())
	no_main.free()
	var fresh = TEST_UNIT.new()
	_check(not fresh.is_weapon_2_explicit() and fresh.get_active_weapon_id() == "rifle", "P1: eine frische Einheit ohne jede Ausruestung: Zweitwaffe nicht gesetzt")
	fresh.free()
	f.scope.free()


## P2 (W2): Ausdruecklich gesetzte Zweitwaffe (Ausruestung ueber apply_identity_config) wechselt wie bisher, auch ein ausdruecklich
## gegebenes Gewehr als Zweitwaffe; das Waffenbild und die aktive Waffe der echten Einheit folgen.
func _test_p2_given_second_weapon_switches_on_real_unit() -> void:
	var f := _real_rig()
	var unit = _real_unit("real", "blue", {"weapon_1_id": "rifle", "weapon_2_id": "pistol"})
	_check(unit.is_weapon_2_explicit(), "P2: Vorbedingung: Zweitwaffe ausdruecklich gesetzt")
	var shots := _drain_unit(f, "real", unit)
	_check(shots == RIFLE_MAG + PISTOL_MAG and unit.get_combat_weapon_slot() == 2 and unit.get_active_weapon_id() == "pistol", "P2: Gewehr 40 + Pistole 24, aktive Waffe der echten Einheit Pistole auf Platz 2 (%d, Platz %d, %s)" % [shots, unit.get_combat_weapon_slot(), unit.get_active_weapon_id()])
	_check(_event_texts(f) == ["Test Unit: Hauptwaffe leer – wechselt auf Pistole.", "Test Unit: Keine Munition mehr."], "P2: Wechselzeile und danach 'Keine Munition mehr.' (%s)" % str(_event_texts(f)))
	unit.free()
	f.scope.free()
	var g := _real_rig()
	var rifle_side = _real_unit("real", "blue", {"weapon_1_id": "pistol", "weapon_2_id": "rifle"})
	var gs := _drain_unit(g, "real", rifle_side)
	_check(gs == PISTOL_MAG + RIFLE_MAG and rifle_side.get_combat_weapon_slot() == 2 and rifle_side.get_active_weapon_id() == "rifle", "P2: ein ausdruecklich gegebenes Gewehr als Zweitwaffe wird benutzt (%d Schuesse)" % gs)
	rifle_side.free()
	g.scope.free()


## P3 (W2): Gegner ueber den Weg der Szenario-Ausruestung (mission_test_setup._apply_authored_enemy_loadout setzt weapon_1_id + weapon_2_id "none";
## ohne Eintrag bleibt es bei der Vorgabe): kein Wechsel, ganz leer, keine Spielermeldung.
func _test_p3_enemy_spawn_path_has_no_second_weapon() -> void:
	var authored := _real_rig()
	var guard = _real_unit("real", "red", {"weapon_1_id": "pistol", "weapon_2_id": "none"})
	var s1 := _drain_unit(authored, "real", guard)
	_check(s1 == PISTOL_MAG and guard.get_combat_weapon_slot() == 1 and authored.ctl.events.is_empty(), "P3: Gegner mit Szenario-Waffe und Zweitwaffe 'none': 24 Schuesse, ganz leer, kein Wechsel (%d)" % s1)
	guard.free()
	authored.scope.free()
	var plain := _real_rig()
	var unauthored = _real_unit("real", "red", {"weapon_1_id": "pistol", "armor_id": "medium"})
	var s2 := _drain_unit(plain, "real", unauthored)
	_check(s2 == PISTOL_MAG and unauthored.get_combat_weapon_slot() == 1 and int(plain.driver._ammo_tracker().shots_fired("real", "rifle")) == 0 and plain.ctl.events.is_empty(), "P3: Gegner ohne Eintrag fuer die Zweitwaffe (nur Vorgabe 'rifle'): kein Phantom-Gewehr (%d)" % s2)
	unauthored.free()
	plain.scope.free()


