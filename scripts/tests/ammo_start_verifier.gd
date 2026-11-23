extends SceneTree
## M4b (23.11.2026): Startausstattung mit Magazinen, einmaliges Nachreichen fuer alte Staende, Auffuellen an der Heimatbasis,
## neue Personen mit vollem Fach. Alles ueber den echten Versorgungszustand; Ruestung und Waffe kommen wie im Spiel ueber
## Auskunftsgeber (SimulationRoot setzt sie aus dem Loadout-Besitzer). Zahlen aus data/combat/ammo_rules.json (start_base_stock).
## Schlusszeile: AMMO_START passed=N failed=M
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const OFFER_PATH := "res://data/singleplayer/trade_offers.json"
const BASE := "base:homebase"
var passed := 0
var failed := 0
var _armor := {"p1": "light", "p2": "medium", "p3": "suit", "p4": "suit", "p5": "heavy"}
var _weapons := {"p1": ["pistol", "none"], "p2": ["rifle", "none"], "p3": ["none", "medictool"], "p4": ["pistol", "none"], "p5": ["smg", "none"]}


func _init() -> void:
	call_deferred("_run")


func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("PASS: " if ok else "FAIL: ", label)


func _run() -> void:
	_new_campaign_part()
	_old_state_part()
	_homecoming_part()
	_recruit_part()
	print("AMMO_START passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)


func _sup(ids: Array) -> RefCounted:
	var s: RefCounted = SUPPLY.new()
	var data: Dictionary = Dictionary(JSON.parse_string(FileAccess.get_file_as_string(OFFER_PATH)))
	if not s.configure([], data).get("ok", false): print("FAIL: Versorgung nicht konfiguriert")
	s.register_craft("ship", 5.0)
	s.configure_inventory(ids, ["ship"], true)
	s.configure_start_inventory("campaign")
	s.set_armor_provider(func(unit_id: String) -> String: return String(_armor.get(unit_id, "")))
	s.set_weapon_provider(func(unit_id: String) -> Array: return Array(_weapons.get(unit_id, [])))
	return s


func _bag(s: RefCounted, id: String) -> Dictionary:
	return Dictionary(Dictionary(s.get_supply_snapshot().inventory).get("unit:%s:backpack" % id, {}))


func _n(container: Dictionary, item: String) -> int:
	return int(Dictionary(container.get("items", {})).get(item, 0))


func _base(s: RefCounted) -> Dictionary:
	return Dictionary(Dictionary(s.get_supply_snapshot().inventory).get(BASE, {}))


func _new_campaign_part() -> void:
	var s := _sup(["p1", "p2", "p3", "p4"])
	var rules: Dictionary = Dictionary(JSON.parse_string(FileAccess.get_file_as_string("res://data/combat/ammo_rules.json")))
	var configured: Dictionary = Dictionary(rules.get("start_base_stock", {}))
	check(configured.size() == 2 and int(configured.get("ammo_light", 0)) == 16 and int(configured.get("ammo_rifle", 0)) == 8, "Daten: start_base_stock ist 16 leichte und 8 Gewehr-Magazine")
	var done: bool = bool(s.grant_ammo_start_if_missing(["p1", "p2", "p3", "p4"]))
	check(done, "Neue Kampagne: die Startausstattung wird gewaehrt")
	check(_n(_base(s), "ammo_light") == 16 and _n(_base(s), "ammo_rifle") == 8, "Neue Kampagne: Basislager 16 leichte, 8 Gewehr-Magazine (%s)" % str(_base(s).get("items")))
	check(_n(_bag(s, "p1"), "ammo_light") == 3, "p1 leichte Ruestung (3 Plaetze) + Pistole: 3 leichte Magazine (%d)" % _n(_bag(s, "p1"), "ammo_light"))
	check(_n(_bag(s, "p2"), "ammo_rifle") == 5 and _n(_bag(s, "p2"), "ammo_light") == 0, "p2 mittlere Ruestung (5) + Sturmgewehr: 5 Gewehr-Magazine, keine leichten")
	check(_n(_bag(s, "p3"), "ammo_light") + _n(_bag(s, "p3"), "ammo_rifle") == 0, "p3 ohne munitionsbeduerftige Waffe: nichts")
	check(_n(_bag(s, "p4"), "ammo_light") == 1, "p4 Raumanzug (1 Platz) + Pistole: 1 leichtes Magazin")
	check(not bool(s.grant_ammo_start_if_missing(["p1", "p2", "p3", "p4"])), "Zweiter Aufruf gewaehrt nichts mehr")
	check(_n(_base(s), "ammo_light") == 16 and _n(_bag(s, "p1"), "ammo_light") == 3, "Zweiter Aufruf aendert den Bestand nicht")
	check(bool(Dictionary(s.export_state()).get("ammo_start_granted", false)), "Der Stand traegt den optionalen Merker ammo_start_granted")


func _old_state_part() -> void:
	var old := _sup(["p1", "p2", "p3", "p4"])
	var exported: Dictionary = JSON.parse_string(JSON.stringify(old.export_state()))
	check(not exported.has("ammo_start_granted"), "Alter Stand: kein Merker im Stand (vor der Aenderung geschrieben)")
	var loaded: RefCounted = SUPPLY.new()
	check(bool(Dictionary(loaded.restore_state(exported)).get("ok", false)), "Alter Stand ohne Merker laedt weiter")
	loaded.set_armor_provider(func(unit_id: String) -> String: return String(_armor.get(unit_id, "")))
	loaded.set_weapon_provider(func(unit_id: String) -> Array: return Array(_weapons.get(unit_id, [])))
	check(bool(loaded.grant_ammo_start_if_missing(["p1", "p2", "p3", "p4"])), "Alter Stand: Ausstattung wird einmal nachgereicht")
	check(_n(_base(loaded), "ammo_light") == 16 and _n(_base(loaded), "ammo_rifle") == 8 and _n(_bag(loaded, "p1"), "ammo_light") == 3, "Alter Stand: Lager 16/8, Fach von p1 voll")
	var again: Dictionary = JSON.parse_string(JSON.stringify(loaded.export_state()))
	var second: RefCounted = SUPPLY.new()
	check(bool(Dictionary(second.restore_state(again)).get("ok", false)), "Neuer Stand mit Merker laedt")
	second.set_armor_provider(func(unit_id: String) -> String: return String(_armor.get(unit_id, "")))
	second.set_weapon_provider(func(unit_id: String) -> Array: return Array(_weapons.get(unit_id, [])))
	check(not bool(second.grant_ammo_start_if_missing(["p1", "p2", "p3", "p4"])), "Zweites Laden reicht nichts mehr nach")
	check(_n(_base(second), "ammo_light") == 16 and _n(_bag(second, "p2"), "ammo_rifle") == 5, "Zweites Laden: Bestand unveraendert")


func _homecoming_part() -> void:
	var s := _sup(["p1", "p2", "p3", "p5"])
	s.grant_ammo_start_if_missing(["p1", "p2", "p3", "p5"])
	# Im Einsatz verbraucht: p1 zwei, p2 drei, p5 sieben (alles)
	for i in 2: s.take_person_magazine("p1", "ammo_light")
	for i in 3: s.take_person_magazine("p2", "ammo_rifle")
	for i in 7: s.take_person_magazine("p5", "ammo_light")
	var base_light_before := _n(_base(s), "ammo_light")
	var result: Dictionary = s.fill_person_compartments(["p5", "p1", "p2", "p3"], true)
	check(_n(_bag(s, "p1"), "ammo_light") == 3 and _n(_bag(s, "p2"), "ammo_rifle") == 5 and _n(_bag(s, "p5"), "ammo_light") == 7, "Heimkehr: alle Faecher wieder voll")
	check(_n(_base(s), "ammo_light") == base_light_before - 9 and _n(_base(s), "ammo_rifle") == 8 - 3, "Heimkehr: Lager um genau die aufgefuellten Magazine kleiner (leicht -9, Gewehr -3)")
	check(int(result.get("added", 0)) == 12 and String(result.get("message", "")) == "Munition aufgefüllt: 12 Magazine.", "Heimkehr: Meldung '%s'" % str(result.get("message")))
	# knapper Vorrat: nur 4 leichte im Lager, p1 braucht 3 und p5 braucht 7; feste Reihenfolge (sortiert): p1 vor p5
	var t := _sup(["p1", "p5"])
	t.grant_ammo_start_if_missing(["p1", "p5"])
	for i in 3: t.take_person_magazine("p1", "ammo_light")
	for i in 7: t.take_person_magazine("p5", "ammo_light")
	var base_items: Dictionary = _base(t).items
	var spare: int = _n(_base(t), "ammo_light") - 4
	check(t.apply_command({"contract_category": "singleplayer_supply", "operation": "inventory_transfer", "payload": {"source_container_id": BASE, "destination_container_id": "station:polisa:lift", "item_id": "ammo_light", "amount": spare}, "request_id": "m4b:spare"}, {"accessible_containers": [BASE, "station:polisa:lift"]}).get("ok", false), "Aufbau: Lager auf 4 leichte Magazine verkleinert")
	var scarce: Dictionary = t.fill_person_compartments(["p5", "p1"], true)
	check(_n(_bag(t, "p1"), "ammo_light") == 3 and _n(_bag(t, "p5"), "ammo_light") == 1 and _n(_base(t), "ammo_light") == 0, "Knapp: erst p1 (3), dann p5 den Rest (1); Lager leer")
	check(String(scarce.get("message", "")) == "Munition aufgefüllt: 4 Magazine. Munition knapp: 1 Fächer blieben leer." or String(scarce.get("message", "")).contains("Munition knapp: 1 "), "Knapp: Meldung nennt die Knappheit (%s)" % str(scarce.get("message")))
	var again: Dictionary = t.fill_person_compartments(["p5", "p1"], true)
	check(int(again.get("added", -1)) == 0 and String(again.get("message", "")).contains("Munition knapp"), "Knapp, zweiter Versuch: nichts mehr da, Meldung bleibt")
	var ready := _sup(["p1"])
	ready.grant_ammo_start_if_missing(["p1"])
	var full: Dictionary = ready.fill_person_compartments(["p1"], true)
	check(String(full.get("message", "")) == "", "Alles voll und nichts zu tun: keine Meldung")


func _recruit_part() -> void:
	var s := _sup(["p1"])
	s.grant_ammo_start_if_missing(["p1"])
	s.configure_inventory(["p4"], [], true)
	check(bool(s.provision_new_person("p4")), "Neue Person: wird ausgestattet")
	check(_n(_bag(s, "p4"), "ammo_light") == 1, "Neue Person p4 (Raumanzug + Pistole) kommt mit vollem Fach (1 Magazin)")
	var fresh := _sup(["p1"])
	fresh.configure_inventory(["p4"], [], true)
	check(not bool(fresh.provision_new_person("p4")) and _n(_bag(fresh, "p4"), "ammo_light") == 0, "Ohne gewaehrte Startausstattung (alter Stand) bekommt eine neue Person noch nichts")
