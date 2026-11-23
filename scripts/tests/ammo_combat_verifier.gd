extends "res://scripts/tests/combat_cadence_verifier.gd"
## M4a (23.11.2026): Munition im Bodengefecht. Jeder Schuss kostet eine Patrone aus dem eingelegten Magazin, ein leeres
## Magazin wird automatisch aus dem Bestand der Person nachgeladen (reload_ticks x reload_scale Ticks Pause), wer nichts mehr
## hat, schiesst nicht. Gegner laden nach, haben aber unbegrenzt Reserve. Echter Treiber und echte Versorgung wie
## combat_cadence_verifier (dessen Aufbau _rig/_run_ticks benutzt wird); Pistole: 12 Schuss, 30 Ticks x 6 = 180 Ticks Nachladen.
## Schlusszeile: AMMO_COMBAT passed=N failed=M

const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const WEAPONS = preload("res://scripts/core/weapon_data.gd")
const OFFER_PATH := "res://data/singleplayer/trade_offers.json"
const BASE := "base:homebase"
const SCALE := 6
const PISTOL_DATA_MAG := 12  # Waffendaten; im Gefecht wirkt magazine_scale (2.0)
const PISTOL_MAG := 24  # wirksame Magazingroesse der Pistole
const PISTOL_RELOAD := 180


## Treiber, bei dem die Unterdrueckungs-Sperre von aussen erzwungen werden kann.
class AmmoDriver extends QuietDriver:
	var deny_slots := false

	func _suppression_fire_slot_open(unit_id: String, unit) -> bool:
		if deny_slots:
			return false
		return super(unit_id, unit)


var _seq := 0


func _make_driver():
	return AmmoDriver.new()


func _run() -> void:
	CADENCE.override_config_for_test({"cadence_scale": 1.0, "reaction_initiative_ticks": 20})
	_test_a0_data()
	_test_a1_no_reserve()
	_test_a2_reserve_reload()
	_test_a3_hit_miss_and_suppression()
	_test_a4_enemy_reloads_never_empty()
	_test_a5_no_ammo_weapon()
	_test_a6_second_source_and_wrong_class()
	_test_a7_stock_after_mission()
	_test_a8_determinism()
	_test_a9_texts()
	_test_overwatch_costs_a_round()
	await process_frame
	print("AMMO_COMBAT passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)


# ---- Hilfen ------------------------------------------------------------------------------------------------------

func _cmd(op: String, payload: Dictionary) -> Dictionary:
	_seq += 1
	return {"contract_category": "singleplayer_supply", "operation": op, "payload": payload, "request_id": "m4a:%d" % _seq}


## Versorgung mit den genannten Personen (Kampagnen-Behaelter); "heavy" = sieben Faecher, damit alle Magazine ins Fach passen.
func _make_supply(unit_ids: Array) -> RefCounted:
	var s: RefCounted = SUPPLY.new()
	var data: Dictionary = Dictionary(JSON.parse_string(FileAccess.get_file_as_string(OFFER_PATH)))
	s.configure([], data)
	s.register_craft("ship", 5.0)
	s.configure_inventory(unit_ids, ["ship"], true)
	s.set_armor_provider(func(_id: String) -> String: return "heavy")
	return s


func _stock(s: RefCounted, unit_id: String, item: String, amount: int) -> void:
	var bag := "unit:%s:backpack" % unit_id
	var given: Dictionary = s.apply_command(_cmd("campaign_cargo", {"container_id": BASE, "item_id": item, "amount": amount}), {"campaign_authorized": true})
	var moved: Dictionary = s.apply_command(_cmd("inventory_transfer", {"source_container_id": BASE, "destination_container_id": bag, "item_id": item, "amount": amount}), {"accessible_containers": [BASE, bag]})
	_check(bool(given.get("ok", false)) and bool(moved.get("ok", false)), "Aufbau: %d x %s in die Person %s gelegt" % [amount, item, unit_id])


## reserves: {unit_id: {item: Anzahl}}. Die Versorgung haengt am echten SimulationRoot (wie im Spiel).
func _ammo_rig(specs: Array, reserves: Dictionary, seed_value: int = 7) -> Dictionary:
	var f := _rig(specs, seed_value)
	var ids: Array = []
	for spec in specs:
		if String(spec.team) == "blue":
			ids.append(String(spec.id))
	var s := _make_supply(ids)
	for unit_id in reserves:
		for item in Dictionary(reserves[unit_id]):
			_stock(s, String(unit_id), String(item), int(reserves[unit_id][item]))
	f.sim.configure_singleplayer_owners(null, s)
	f["sup"] = s
	return f


func _bag_count(f: Dictionary, unit_id: String, item: String) -> int:
	var inv: Dictionary = Dictionary(f.sup.get_supply_snapshot().inventory)
	return int(Dictionary(Dictionary(inv.get("unit:%s:backpack" % unit_id, {})).get("items", {})).get(item, 0))


func _total_items(f: Dictionary, item: String) -> int:
	var total := 0
	var inv: Dictionary = Dictionary(f.sup.get_supply_snapshot().inventory)
	for id in inv:
		total += int(Dictionary(Dictionary(inv[id]).get("items", {})).get(item, 0))
	return total


func _shot_ticks(f: Dictionary, unit_id: String) -> Array:
	var ticks: Array = []
	for entry in f.calls:
		if Array(entry.shooters).has(unit_id):
			ticks.append(int(entry.tick))
	return ticks


func _status(f: Dictionary, unit_id: String) -> Dictionary:
	return Dictionary(f.driver.get_unit_ammo_status(unit_id))


## Laeuft in Entscheidungsschritten (3 Ticks), bis die Einheit `count` Schuesse abgegeben hat (oder `limit` Schritte vergangen sind).
func _run_until_shots(f: Dictionary, unit_id: String, count: int, limit: int = 600) -> void:
	var guard := 0
	while _shots_by(f, unit_id) < count and guard < limit:
		_run_ticks(f, 3)
		guard += 1


func _duel(own_weapon: String, enemy_weapon: String, own_extra: Dictionary = {}, enemy_extra: Dictionary = {}) -> Array:
	var specs := _line(CENTER, CENTER + HEX.DIRECTIONS[0], own_weapon, enemy_weapon)
	for key in own_extra:
		specs[0][key] = own_extra[key]
	for key in enemy_extra:
		specs[1][key] = enemy_extra[key]
	return specs


# ---- Tests -------------------------------------------------------------------------------------------------------

## Vorbedingung: die Zahlen, auf die sich die Tests stuetzen (Waffendaten und reload_scale aus der Datendatei).
func _test_a0_data() -> void:
	var pistol: Dictionary = WEAPONS.get_weapon("pistol")
	_check(int(pistol.get("magazine_size", 0)) == PISTOL_DATA_MAG and int(pistol.get("reload_ticks", 0)) * SCALE == PISTOL_RELOAD, "A0: Pistole 12 Schuss, 30 Ticks x reload_scale 6 = 180")
	var rules: Dictionary = Dictionary(JSON.parse_string(FileAccess.get_file_as_string("res://data/combat/ammo_rules.json")))
	_check(int(rules.get("reload_scale", -1)) == SCALE, "A0: reload_scale in ammo_rules.json ist 6")
	_check(float(rules.get("magazine_scale", -1.0)) == 2.0, "A0: magazine_scale in ammo_rules.json ist 2.0 (M4b)")
	_check(PISTOL_DATA_MAG * 2 == PISTOL_MAG and int(f_info_size("pistol")) == PISTOL_MAG and int(f_info_size("sniper")) == 10 and int(f_info_size("rocket_launcher")) == 2, "M4b: wirksame Magazingroesse = Waffendaten x 2 (Pistole 24, Scharfschuetze 10, Raketenwerfer 2)")


func f_info_size(weapon_id: String) -> int:
	return int(preload("res://scripts/combat/combat_ammo.gd").new().weapon_info(weapon_id).magazine_size)


## A1: ohne Reserve genau ein Magazin, danach kein Schuss mehr; Zustand "Keine Munition".
func _test_a1_no_reserve() -> void:
	var f := _ammo_rig(_duel("pistol", "none"), {})
	_run_ticks(f, 600)
	var shots := _shots_by(f, "own")
	_check(shots == PISTOL_MAG, "A1: ohne Reserve genau %d Schuesse in 600 Ticks (%d)" % [PISTOL_MAG, shots])
	var st := _status(f, "own")
	_check(String(st.get("state", "")) == "empty" and int(st.get("rounds", -1)) == 0, "A1: Zustand leer (%s)" % str(st))
	_check(String(f.driver.get_unit_ammo_text("own")) == "Keine Munition", "A1: Anzeige 'Keine Munition' (%s)" % f.driver.get_unit_ammo_text("own"))
	# sonst voll handlungsfaehig: kein Fehler, die Einheit steht noch, der Gegner ist unbeeinflusst
	_check(f.units["own"].hp > 0, "A1: die Einheit ohne Munition bleibt im Spiel")
	f.scope.free()


## A2: mit einem Reservemagazin: nach dem letzten Schuss genau 180 Ticks Pause, dann weiter; Magazin aus dem Bestand weg.
func _test_a2_reserve_reload() -> void:
	var f := _ammo_rig(_duel("pistol", "none"), {"own": {"ammo_light": 1}})
	_check(_bag_count(f, "own", "ammo_light") == 1, "A2: Ausgangslage: ein Reservemagazin in der Person")
	_run_until_shots(f, "own", PISTOL_MAG)
	_check(_shots_by(f, "own") == PISTOL_MAG, "A2: zwoelf Schuesse aus dem ersten Magazin")
	var last_tick: int = int(f.calls[-1].tick)
	var st := _status(f, "own")
	_check(String(st.get("state", "")) == "reloading" and int(st.get("reload_ticks_left", 0)) == PISTOL_RELOAD, "A2: sofort nach dem letzten Schuss laedt sie nach, 180 Ticks (%s)" % str(st))
	_check(_bag_count(f, "own", "ammo_light") == 0, "A2: das Reservemagazin ist aus dem Bestand der Person weg")
	_run_ticks(f, 700)
	var later: Array = []
	for tick in _shot_ticks(f, "own"):
		if int(tick) > last_tick:
			later.append(int(tick))
	_check(not later.is_empty(), "A2: nach dem Nachladen schiesst sie weiter")
	if not later.is_empty():
		var gap: int = int(later[0]) - last_tick
		_check(gap >= PISTOL_RELOAD, "A2: kein Schuss waehrend der 180 Ticks Nachladen (naechster nach %d Ticks)" % gap)
		_check(gap <= PISTOL_RELOAD + 12, "A2: danach laeuft der Takt normal weiter, keine angesparten Schuesse, kein spaeter Start (%d)" % gap)
		var burst := 0
		for tick in later:
			if int(tick) < int(later[0]) + 9:
				burst += 1
		_check(burst == 1, "A2: kein Schnellfeuer nach dem Nachladen (%d Schuesse im ersten Takt)" % burst)
	_check(_shots_by(f, "own") == 2 * PISTOL_MAG, "A2: insgesamt zwei Magazine = 24 Schuesse (%d)" % _shots_by(f, "own"))
	_check(String(_status(f, "own").get("state", "")) == "empty", "A2: danach leer, keine weitere Reserve")
	f.scope.free()


## A3: Treffer wie Fehlschuss kosten je eine Patrone; ein durch die Unterdrueckungs-Sperre ausgefallener Schuss kostet keine.
func _test_a3_hit_miss_and_suppression() -> void:
	for mode in ["hit", "miss"]:
		var f := _ammo_rig(_duel("pistol", "none", {"hit_multiplier": 10.0 if mode == "hit" else 0.0}), {})
		var counts := {"hit": 0, "miss": 0}
		f.sim.damage_effect_resolved.connect(func(result: Dictionary) -> void:
			counts["hit" if bool(result.get("hit", false)) else "miss"] += 1)
		_run_ticks(f, 600)
		_check(int(counts[mode]) >= 1, "A3: im Lauf '%s' gibt es solche Schuesse (%s)" % [mode, str(counts)])
		_check(_shots_by(f, "own") == PISTOL_MAG and _status(f, "own").state == "empty", "A3: %s: genau %d Schuesse, dann leer (%d)" % [mode, PISTOL_MAG, _shots_by(f, "own")])
		f.scope.free()
	var g := _ammo_rig(_duel("pistol", "none"), {})
	g.driver.deny_slots = true
	_run_ticks(g, 90)
	_check(_shots_by(g, "own") == 0 and int(_status(g, "own").get("rounds", -1)) == PISTOL_MAG, "A3: von der Unterdrueckung gesperrte Gelegenheiten kosten keine Patrone (rounds %s)" % str(_status(g, "own").get("rounds")))
	g.driver.deny_slots = false
	_run_ticks(g, 90)
	var fired := _shots_by(g, "own")
	_check(fired > 0 and int(_status(g, "own").get("rounds", -1)) == PISTOL_MAG - fired, "A3: nach der Sperre kostet jeder Schuss eine Patrone (%d Schuesse, rounds %s)" % [fired, str(_status(g, "own").get("rounds"))])
	g.scope.free()


## A4: Der Gegner laedt nach (mit Pause), geht aber nie leer aus.
func _test_a4_enemy_reloads_never_empty() -> void:
	var f := _ammo_rig(_duel("none", "pistol"), {})
	var states := {}
	for i in range(500):
		_run_ticks(f, 3)
		states[String(_status(f, "enemy").get("state", ""))] = true
	var ticks := _shot_ticks(f, "enemy")
	var max_gap := 0
	var small_gaps := true
	for i in range(1, ticks.size()):
		var gap: int = int(ticks[i]) - int(ticks[i - 1])
		max_gap = maxi(max_gap, gap)
		if gap < PISTOL_RELOAD and gap > 20:
			small_gaps = false
	_check(ticks.size() > 2 * PISTOL_MAG, "A4: der Gegner schiesst weit mehr als zwei Magazine (%d)" % ticks.size())
	_check(max_gap >= PISTOL_RELOAD and max_gap <= PISTOL_RELOAD + 12, "A4: zwischen den Magazinen liegt die Nachladepause von 180 Ticks (groesste Luecke %d)" % max_gap)
	_check(small_gaps, "A4: sonst nur der normale Takt")
	_check(states.has("reloading") and not states.has("empty"), "A4: er laedt nach und ist nie ohne Munition (%s)" % str(states.keys()))
	_check(String(f.driver.get_unit_ammo_text("enemy")) != "Keine Munition", "A4: Anzeige nie 'Keine Munition'")
	f.scope.free()


## A5: Eine Waffe ohne Munitionsbedarf schiesst unbegrenzt (die Waffendaten kennen nur "none" und "medictool" ohne Bedarf;
## darum wird dem Treiber hier fuer die Pistole ein Waffeneintrag ohne ammo_class untergeschoben).
func _test_a5_no_ammo_weapon() -> void:
	var f := _ammo_rig(_duel("pistol", "none"), {})
	f.driver._ammo_tracker().weapon_lookup = func(_weapon_id: String) -> Dictionary:
		return {"ammo_class": "", "magazine_size": 0, "reload_ticks": 0}
	_run_ticks(f, 600)
	_check(_shots_by(f, "own") > 2 * PISTOL_MAG, "A5: ohne Munitionsbedarf mehr als zwei Magazine Schuesse (%d)" % _shots_by(f, "own"))
	_check(String(_status(f, "own").get("state", "")) == "none" and String(f.driver.get_unit_ammo_text("own")) == "", "A5: Zustand 'none', keine Anzeige")
	f.scope.free()
	var g := _ammo_rig(_duel("medictool", "none"), {})
	_run_ticks(g, 30)
	_check(String(_status(g, "own").get("state", "")) == "none", "A5: medictool braucht keine Munition")
	g.scope.free()


## A6: Reserve auch aus dem Rucksack; eine falsche Sorte wird nicht genommen.
func _test_a6_second_source_and_wrong_class() -> void:
	var s := _make_supply(["own"])
	var f_specs := _duel("pistol", "none")
	var f := _rig(f_specs)
	_stock(s, "own", "ammo_light", 1)
	_stock(s, "own", "ammo_rifle", 3)
	# zweites leichtes Magazin im Rucksack (Rucksack mit 12 Plaetzen neben dem Fach)
	var bag: Dictionary = s._inventory["unit:own:backpack"]
	bag["capacity"] = 12
	bag.items["ammo_light"] = int(bag.items.get("ammo_light", 0)) + 1
	f.sim.configure_singleplayer_owners(null, s)
	f["sup"] = s
	_run_ticks(f, 1800)
	_check(_shots_by(f, "own") == 3 * PISTOL_MAG, "A6: eingelegtes + zwei Reservemagazine (Fach und Rucksack) = 72 Schuesse (%d)" % _shots_by(f, "own"))
	_check(_bag_count(f, "own", "ammo_light") == 0, "A6: beide leichten Magazine verbraucht")
	_check(_bag_count(f, "own", "ammo_rifle") == 3, "A6: die falsche Sorte (Gewehrmagazine) bleibt unangetastet (%d)" % _bag_count(f, "own", "ammo_rifle"))
	_check(String(_status(f, "own").get("state", "")) == "empty", "A6: danach leer, obwohl Gewehrmagazine da sind")
	f.scope.free()


## A7: Nach dem Einsatz fehlen die verbrauchten Magazine; das eingelegte Magazin ist beim naechsten Einsatz wieder voll.
func _test_a7_stock_after_mission() -> void:
	var f := _ammo_rig(_duel("pistol", "none"), {"own": {"ammo_light": 2, "ammo_rail": 1}})
	var before := _total_items(f, "ammo_light")
	_run_ticks(f, 1800)
	_check(before == 2 and _total_items(f, "ammo_light") == 0, "A7: beide leichten Magazine sind aus dem gesamten Bestand verschwunden (%d -> %d)" % [before, _total_items(f, "ammo_light")])
	_check(_bag_count(f, "own", "ammo_rail") == 1, "A7: nicht benutzte Magazine bleiben")
	_check(String(_status(f, "own").get("state", "")) == "empty", "A7: am Ende des Einsatzes leer")
	f.driver.reset_suppression()
	var st := _status(f, "own")
	_check(int(st.get("rounds", -1)) == PISTOL_MAG and String(st.get("state", "")) == "ready", "A7: im naechsten Einsatz ist das eingelegte Magazin wieder voll (%s)" % str(st))
	f.scope.free()


## A8: gleicher Zufallsstart und gleiche Tickfolge: gleiche Schussfolge und gleicher Verbrauch.
func _test_a8_determinism() -> void:
	var specs: Array = [
		{"id": "u1", "team": "blue", "grid": CENTER + HEX.DIRECTIONS[0], "facing": 3, "weapon": "smg"},
		{"id": "u2", "team": "red", "grid": CENTER, "facing": 0, "weapon": "smg"},
		{"id": "u3", "team": "blue", "grid": CENTER + HEX.DIRECTIONS[2], "facing": 5, "weapon": "pistol"},
		{"id": "u4", "team": "red", "grid": CENTER + HEX.DIRECTIONS[1], "facing": 4, "weapon": "pistol"},
	]
	var reserves := {"u1": {"ammo_light": 1}, "u3": {"ammo_light": 1}}
	var a := _ammo_rig(specs, reserves, 11)
	var b := _ammo_rig(specs, reserves, 11)
	var log_a := _hit_log(a, 800)
	var log_b := _hit_log(b, 800)
	_check(log_a.size() > PISTOL_MAG, "A8: der Lauf hat viele Schuesse (%d)" % log_a.size())
	_check(log_a == log_b, "A8: gleiche Schuss- und Trefferfolge in zwei Durchlaeufen")
	_check(a.calls == b.calls, "A8: gleiche Schuetzen in jedem Schritt")
	_check(_bag_count(a, "u1", "ammo_light") == _bag_count(b, "u1", "ammo_light") and _bag_count(a, "u3", "ammo_light") == _bag_count(b, "u3", "ammo_light"), "A8: gleicher Verbrauch an Magazinen")
	_check(JSON.stringify(_status(a, "u1")) == JSON.stringify(_status(b, "u1")) and JSON.stringify(_status(a, "u4")) == JSON.stringify(_status(b, "u4")), "A8: gleicher Munitionszustand am Ende")
	a.scope.free()
	b.scope.free()


## A9: Anzeigetext in den drei Zustaenden.
func _test_a9_texts() -> void:
	var f := _ammo_rig(_duel("pistol", "none"), {"own": {"ammo_light": 1}})
	_check(String(f.driver.get_unit_ammo_text("own")) == "Mun. 24/24 +1", "A9: vor dem ersten Schuss 'Mun. 24/24 +1' (%s)" % f.driver.get_unit_ammo_text("own"))
	_run_until_shots(f, "own", 3)
	_check(String(f.driver.get_unit_ammo_text("own")) == "Mun. 21/24 +1", "A9: nach drei Schuessen 'Mun. 21/24 +1' (%s)" % f.driver.get_unit_ammo_text("own"))
	_run_until_shots(f, "own", PISTOL_MAG)
	_check(String(f.driver.get_unit_ammo_text("own")) == "lädt nach", "A9: beim Nachladen 'lädt nach' (%s)" % f.driver.get_unit_ammo_text("own"))
	_run_ticks(f, 1000)
	_check(String(f.driver.get_unit_ammo_text("own")) == "Keine Munition", "A9: ohne Munition 'Keine Munition' (%s)" % f.driver.get_unit_ammo_text("own"))
	_check(String(f.driver.get_unit_ammo_text("enemy")) == "", "A9: Waffe ohne Munitionsbedarf zeigt nichts")
	f.scope.free()


## Ein Ueberwachungsschuss kostet ebenfalls eine Patrone.
func _test_overwatch_costs_a_round() -> void:
	var f := _ammo_rig(_duel("pistol", "none"), {})
	f.driver.overwatch_plan = {9: ["own"]}
	_run_ticks(f, 30)
	var consumed: int = PISTOL_MAG - int(_status(f, "own").get("rounds", PISTOL_MAG))
	_check(consumed == _shots_by(f, "own") + 1, "Ueberwachung: Normalschuesse + 1 Ueberwachungsschuss = verbrauchte Patronen (%d verbraucht, %d normale)" % [consumed, _shots_by(f, "own")])
	f.scope.free()
