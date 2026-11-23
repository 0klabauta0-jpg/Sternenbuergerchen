extends SceneTree
## Task M2 (22.11.2026): Das Ruestungsfach bekommt so viele Plaetze, wie die getragene Ruestung erlaubt, und nimmt Chips UND Magazine.
## Zahlen laut Auftrag m2-brief.md; sie stehen NUR in data/combat/ammo_rules.json, hier stehen die Erwartungen.
## Alles ueber den echten Versorgungszustand und den Transfervertrag (kein Panel-Umbau, kein neuer Befehl).
## Abschlusszeile: AMMO_EQUIP passed=%d failed=%d
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const INV = preload("res://scripts/mission/inventory_transfer_contract.gd")
const RULES = preload("res://scripts/core/ammo_rules.gd")
const SIM = preload("res://scripts/core/simulation_root.gd")
const LOADOUT_STATE = preload("res://scripts/core/personnel_loadout_state.gd")
const PANEL = preload("res://scripts/ui/components/personnel_inventory_panel.gd")
const OFFER_PATH := "res://data/singleplayer/trade_offers.json"
const BAG := "unit:u1:backpack"
const BASE := "base:homebase"
const SENTENCE := "Erst das Rüstungsfach leeren: Die neue Rüstung hat weniger Plätze."
var passed := 0
var failed := 0
var _seq := 0
var _armor := {"u1": "suit"}

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("PASS: " if ok else "FAIL: ", label)

func _run() -> void:
	_size_part()
	_chip_equivalence_part()
	_container_part()
	_swap_part()
	_save_part()
	_loss_part()
	_panel_part()
	print("AMMO_EQUIP passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)

# ---------- Hilfen ----------

func _cmd(op: String, payload: Dictionary) -> Dictionary:
	_seq += 1
	return {"contract_category": "singleplayer_supply", "operation": op, "payload": payload, "request_id": "m2:%d" % _seq}

## Versorgung mit einer Person u1 (Kampagnen-Behaelter: Rucksack 0 plus Fach) und einer Ruestungsquelle.
func _sup(armor: String) -> RefCounted:
	var s: RefCounted = SUPPLY.new()
	var data: Dictionary = Dictionary(JSON.parse_string(FileAccess.get_file_as_string(OFFER_PATH)))
	if not s.configure([], data).get("ok", false): print("FAIL: Versorgung nicht konfiguriert")
	s.register_craft("ship", 5.0)
	s.configure_inventory(["u1"], ["ship"], true)
	_armor["u1"] = armor
	s.set_armor_provider(func(unit_id: String) -> String: return String(_armor.get(unit_id, "")))
	return s

func _give(s: RefCounted, item: String, amount: int) -> void:
	var r: Dictionary = s.apply_command(_cmd("campaign_cargo", {"container_id": BASE, "item_id": item, "amount": amount}), {"campaign_authorized": true})
	if not r.get("ok", false): print("FAIL: Fracht nicht gebucht: ", item, " ", r)

func _move(s: RefCounted, item: String, source: String, target: String, amount: int = 1) -> Dictionary:
	return s.apply_command(_cmd("inventory_transfer", {"source_container_id": source, "destination_container_id": target, "item_id": item, "amount": amount}), {"accessible_containers": [BASE, BAG]})

func _equip_armor(s: RefCounted, item: String, loadout_armor: String) -> Dictionary:
	var ctx := {"accessible_containers": [BASE, BAG], "unit_id": "u1", "equipment_allowed": true, "loadout": {"armor": loadout_armor, "weapon_1": "pistol", "weapon_2": "none"}}
	return s.apply_command(_cmd("inventory_equip", {"unit_id": "u1", "craft_id": "ship", "source_container_id": BASE, "slot": "armor", "item_id": item}), ctx)

func _inv(s: RefCounted) -> Dictionary:
	return Dictionary(s.get_supply_snapshot().inventory)

func _bag(s: RefCounted) -> Dictionary:
	return Dictionary(_inv(s).get(BAG, {}))

func _count(s: RefCounted, item: String) -> int:
	var total := 0
	for id in _inv(s):
		total += int(Dictionary(Dictionary(_inv(s)[id]).items).get(item, 0))
	return total

const MAGS := ["ammo_light", "ammo_rifle", "ammo_rail", "ammo_rocket"]

# ---------- Fachgroesse je Ruestung ----------

func _size_part() -> void:
	var sizes := {"suit": 1, "light": 3, "medium": 5, "heavy": 7}
	for armor in sizes:
		var s := _sup(armor)
		for m in MAGS: _give(s, m, 3)
		check(int(_bag(s).armor_chip_capacity) == int(sizes[armor]), "%s: Fachgroesse im Behaelter ist %d" % [armor, sizes[armor]])
		var ok_count := 0
		for i in range(8):
			if _move(s, MAGS[i % 4], BASE, BAG).get("ok", false): ok_count += 1
		check(ok_count == int(sizes[armor]), "%s: nimmt genau %d Magazine, das naechste wird abgelehnt (genommen: %d)" % [armor, sizes[armor], ok_count])
		check(not _move(s, "ammo_light", BASE, BAG).get("ok", true) and _bag(s).capacity == 0, "%s: ohne Rucksack kein Platz ausser dem Fach" % armor)
	var s := _sup("light")
	_give(s, "satellite_chip", 1); _give(s, "ammo_light", 4)
	check(_move(s, "satellite_chip", BASE, BAG).get("ok", false), "light: Chip kommt ins Fach")
	var fit := 0
	for i in range(3):
		if _move(s, "ammo_light", BASE, BAG).get("ok", false): fit += 1
	check(fit == 3, "light: neben dem Chip passen weiter genau 3 Magazine (M2-5: Chips zaehlen nicht gegen die Fachgroesse)")
	var fourth: Dictionary = _move(s, "ammo_light", BASE, BAG)
	check(not fourth.get("ok", true) and String(fourth.get("reason", "")) == "container_full", "light: das vierte Magazin neben dem Chip wird abgelehnt")
	# W1 (a): Fach mit Magazinen voll, Chip-Aufnahme ueber den Befehl des Einsatz-Weges (campaign_cargo, Adapter _recover_secured_campaign_chips)
	for chip in ["satellite_chip", "outpost_chip"]:
		var full := _sup("light")
		_give(full, "ammo_light", 3)
		_move(full, "ammo_light", BASE, BAG, 3)
		var got: Dictionary = full.apply_command(_cmd("campaign_cargo", {"container_id": BAG, "item_id": chip, "amount": 1}), {"campaign_authorized": true})
		check(bool(got.get("ok", false)) and int(_bag(full).items.get(chip, 0)) == 1 and int(_bag(full).items.get("ammo_light", 0)) == 3, "%s: Chip-Aufnahme klappt bei vollem Magazinfach (Magazine bleiben)" % chip)
	# W1 (c): zweiter Chip wie vor M2 (ohne Rucksack abgelehnt, mit Rucksackplatz ein Platz)
	var two := _sup("heavy")
	_give(two, "satellite_chip", 1); _give(two, "outpost_chip", 1)
	check(_move(two, "satellite_chip", BASE, BAG).get("ok", false) and not _move(two, "outpost_chip", BASE, BAG).get("ok", true), "zweiter Chip: ohne Rucksack abgelehnt wie vor M2")
	check(INV.valid_container({"capacity": 1, "armor_chip_capacity": 7, "items": {"satellite_chip": 1, "outpost_chip": 1}}) and not INV.valid_container({"capacity": 0, "armor_chip_capacity": 7, "items": {"satellite_chip": 1, "outpost_chip": 1}}), "zweiter Chip belegt einen Rucksackplatz, egal wie gross das Fach ist")
	var p := _sup("heavy")
	_give(p, "pistol", 1)
	check(not _move(p, "pistol", BASE, BAG).get("ok", true), "heavy: eine Pistole passt nicht ins Fach (ohne Rucksack abgelehnt)")
	var q := _sup("heavy")
	check(q.apply_command(_cmd("inventory_equip", {"unit_id": "u1", "craft_id": "ship", "source_container_id": BASE, "slot": "backpack", "item_id": "backpack"}), {"accessible_containers": [BASE, BAG], "unit_id": "u1", "equipment_allowed": true, "loadout": {"armor": "heavy"}}).get("reason", "") == "insufficient_items", "Rucksack-Weg unveraendert (kein Rucksack im Lager)")

# ---------- Chips wie vorher: alte Formel (Stand d18883441) gegen den neuen Vertrag ----------

func _legacy_chips(items: Dictionary) -> int:
	return int(items.get("satellite_chip", 0)) + int(items.get("outpost_chip", 0))

func _legacy_used(data: Dictionary) -> int:
	var items: Dictionary = data.get("items", {})
	var armor_slots := int(data.get("armor_chip_capacity", 0))
	var used_slots := INV.used(items)
	if armor_slots > 0:
		used_slots += maxi(0, _legacy_chips(items) - armor_slots) + int(items.get("c_benit_crate", 0))
	return used_slots

func _legacy_has_space(data: Dictionary, item: String, amount: int) -> bool:
	var used_slots := _legacy_used(data)
	var armor_slots := int(data.get("armor_chip_capacity", 0))
	if armor_slots > 0 and ["satellite_chip", "outpost_chip"].has(item):
		used_slots += maxi(0, amount - maxi(0, armor_slots - _legacy_chips(data.items)))
	elif armor_slots > 0 or not INV.RESERVED_QUEST_ITEMS.has(item):
		used_slots += amount
	return used_slots <= int(data.capacity)

func _chip_equivalence_part() -> void:
	var same := 0
	var diff := 0
	for armor_slots in [0, 1]:
		for capacity in [0, 1, 3, 12]:
			for sat in [0, 1]:
				for outp in [0, 1]:
					for crate in [0, 1]:
						for ore in [0, 2, 5]:
							var data := {"capacity": capacity, "items": {}}
							if armor_slots > 0: data["armor_chip_capacity"] = armor_slots
							for pair in [["satellite_chip", sat], ["outpost_chip", outp], ["c_benit_crate", crate], ["ore", ore]]:
								if int(pair[1]) > 0: data.items[pair[0]] = pair[1]
							if INV.backpack_slots_used(data) != _legacy_used(data): diff += 1
							else: same += 1
							for item in ["satellite_chip", "outpost_chip", "c_benit_crate", "ore", "pistol", "backpack"]:
								for amount in [1, 2]:
									if INV.has_space(data, item, amount) != _legacy_has_space(data, item, amount): diff += 1
									else: same += 1
	check(diff == 0 and same > 1000, "Chips und Fracht: Platzrechnung gleich der alten Formel in %d Faellen, %d Abweichungen" % [same, diff])

func _container_part() -> void:
	for size in [1, 2, 3, 5, 7]:
		check(INV.valid_container({"capacity": 0, "armor_chip_capacity": size, "items": {}}), "Behaelter mit Fachgroesse %d ist gueltig" % size)
	check(INV.valid_container({"capacity": 0, "armor_chip_capacity": 1, "items": {"satellite_chip": 1}}), "alte Form (Fach 1, ein Chip) bleibt gueltig")
	check(INV.valid_container({"capacity": 0, "armor_chip_capacity": 3, "items": {"satellite_chip": 1, "ammo_light": 3}}), "light: Chip + 3 Magazine gueltig")
	check(not INV.valid_container({"capacity": 0, "armor_chip_capacity": 3, "items": {"satellite_chip": 1, "ammo_light": 4}}), "light: Chip + 4 Magazine ohne Rucksack ungueltig")
	check(INV.valid_container({"capacity": 12, "armor_chip_capacity": 1, "items": {"ammo_light": 13}}), "Rucksack 12 + Fach 1 nehmen 13 Magazine")
	for bad in [0, -1, 1.5, "3", null, 999]:
		check(not INV.valid_container({"capacity": 0, "armor_chip_capacity": bad, "items": {}}), "Fachgroesse %s ist ungueltig" % str(bad))
	check(INV.compartment_used({"armor_chip_capacity": 3, "items": {"satellite_chip": 1, "ammo_rail": 1, "pistol": 2}}) == 1, "belegt zaehlt nur Magazine, keine Chips und Waffen")
	check(INV.compartment_used({"armor_chip_capacity": 1, "items": {"ammo_rail": 4}}) == 1, "belegt ist nie mehr als die Fachgroesse")

# ---------- Ruestungswechsel ----------

func _fill_heavy() -> RefCounted:
	var s := _sup("heavy")
	_give(s, "satellite_chip", 1)
	var plan := {"ammo_light": 2, "ammo_rifle": 2, "ammo_rail": 2, "ammo_rocket": 1}
	for m in plan: _give(s, m, int(plan[m]))
	_move(s, "satellite_chip", BASE, BAG)
	for m in plan: _move(s, m, BASE, BAG, int(plan[m]))
	return s

func _totals(s: RefCounted) -> Dictionary:
	var out := {}
	for item in MAGS + ["satellite_chip"]: out[item] = _count(s, item)
	return out

func _swap_part() -> void:
	var s := _fill_heavy()
	check(INV.compartment_used(_bag(s)) == 7 and int(_bag(s).armor_chip_capacity) == 7, "heavy: sieben Plaetze belegt")
	var before := _totals(s)
	var heavy_before := _count(s, "armor_heavy")
	var r: Dictionary = _equip_armor(s, "suit", "heavy")
	_armor["u1"] = "suit"
	check(bool(r.get("ok", false)) and String(r.loadout.armor) == "suit", "heavy -> suit wird angenommen")
	check(int(_bag(s).armor_chip_capacity) == 1, "danach hat das Fach 1 Platz")
	var items: Dictionary = _bag(s).items
	check(items.size() == 2 and int(items.get("satellite_chip", 0)) == 1 and int(items.get("ammo_rocket", 0)) == 1, "im Behaelter bleiben der Chip und ein Magazin (Chip wandert nie)")
	check(int(Dictionary(_inv(s)[BASE].items).get("ammo_light", 0)) + int(Dictionary(_inv(s)[BASE].items).get("ammo_rifle", 0)) + int(Dictionary(_inv(s)[BASE].items).get("ammo_rail", 0)) == 6, "sechs Magazine liegen im Lager")
	check(_totals(s) == before, "Summe aller Magazine und Chips vorher == nachher (nichts weg, nichts doppelt)")
	check(_count(s, "armor_heavy") == heavy_before + 1, "abgelegte schwere Ruestung liegt im Lager")
	# vier Magazine + Chip: light -> suit
	var t := _sup("light")
	_give(t, "ammo_rocket", 2); _give(t, "ammo_light", 1)
	_move(t, "ammo_rocket", BASE, BAG, 2); _move(t, "ammo_light", BASE, BAG)
	var order_before := _totals(t)
	check(bool(_equip_armor(t, "suit", "light").get("ok", false)), "light (3 belegt) -> suit")
	check(int(_bag(t).items.get("ammo_light", 0)) + int(_bag(t).items.get("ammo_rocket", 0)) == 1 and _totals(t) == order_before, "feste Reihenfolge der Kennung: ammo_light zuerst ins Lager, ein Magazin bleibt, Summe gleich")
	check(int(_bag(t).items.get("ammo_rocket", 0)) == 1 and int(_inv(t)[BASE].items.get("ammo_light", 0)) == 1 and int(_inv(t)[BASE].items.get("ammo_rocket", 0)) == 1, "bleibt ammo_rocket, geht ammo_light + ein ammo_rocket")
	# volles Lager: Ablehnung, nichts veraendert
	var u := _fill_heavy()
	var base: Dictionary = u.get("_inventory")[BASE]
	var used: int = INV.used(base.items)
	base.items["ore"] = int(base.capacity) - used - 1
	var snap: Dictionary = _inv(u).duplicate(true)
	var revision: int = int(u.get_supply_snapshot().revision)
	var rej: Dictionary = _equip_armor(u, "suit", "heavy")
	check(not rej.get("ok", true) and String(rej.get("message", "")) == SENTENCE, "volles Lager: Ablehnung mit dem Satz (%s)" % str(rej.get("message", "")))
	check(_inv(u) == snap and int(u.get_supply_snapshot().revision) == revision, "volles Lager: nichts veraendert (Behaelter und Revision gleich)")
	# kleiner Wechsel mit Platz und Wechsel nach oben
	var v := _sup("suit")
	_give(v, "armor_heavy", 1); _give(v, "ammo_light", 2)
	check(bool(_equip_armor(v, "armor_heavy", "suit").get("ok", false)), "suit -> heavy angenommen")
	_armor["u1"] = "heavy"
	check(int(_bag(v).armor_chip_capacity) == 7 and _move(v, "ammo_light", BASE, BAG, 2).get("ok", false), "danach 7 Plaetze und zwei Magazine passen")

# ---------- Spielstand ----------

func _fresh_restored(state: Dictionary, armor: String, after_load: bool = true) -> Array:
	var r: RefCounted = SUPPLY.new()
	var data: Dictionary = Dictionary(JSON.parse_string(FileAccess.get_file_as_string(OFFER_PATH)))
	r.configure([], data)
	# Echter Ablauf: erst laden (die Auskunft ist noch nicht gebunden), dann bindet der Besitzer und gleicht einmal ab.
	var res: Dictionary = r.restore_state(state)
	_armor["u1"] = armor
	r.set_armor_provider(func(unit_id: String) -> String: return String(_armor.get(unit_id, "")))
	if after_load: r.sync_compartments_after_load()
	return [r, res]

func _save_part() -> void:
	var s := _fill_heavy()
	var state: Dictionary = JSON.parse_string(JSON.stringify(s.export_state()))
	var loaded := _fresh_restored(state, "heavy")
	check(bool(loaded[1].get("ok", false)), "Stand mit Magazinen im Fach laedt (%s)" % str(loaded[1].get("reason", "")))
	check(_totals(loaded[0]) == _totals(s) and INV.compartment_used(_bag(loaded[0])) == 7 and int(_bag(loaded[0]).armor_chip_capacity) == 7, "Inhalt und Fachgroesse 7 nach dem Laden gleich")
	# Stand von VOR M2: Fach 1, ein Chip, Ruestung light
	var old := _sup("suit")
	_give(old, "satellite_chip", 1); _move(old, "satellite_chip", BASE, BAG)
	var old_state: Dictionary = JSON.parse_string(JSON.stringify(old.export_state()))
	check(int(old_state.inventory[BAG].armor_chip_capacity) == 1 and Dictionary(old_state.inventory[BAG].items).size() == 1, "Altstand von Hand: Fach 1, ein Chip")
	var alt := _fresh_restored(old_state, "light")
	check(bool(alt[1].get("ok", false)), "Stand von vor M2 laedt (%s)" % str(alt[1].get("reason", "")))
	check(int(_bag(alt[0]).armor_chip_capacity) == 3, "danach hat das Fach 3 Plaetze (aus der Ruestung light)")
	_give(alt[0], "ammo_light", 4)
	check(_move(alt[0], "ammo_light", BASE, BAG, 3).get("ok", false) and not _move(alt[0], "ammo_light", BASE, BAG).get("ok", true), "neben dem Chip genau 3 Magazine")
	var plain := _fresh_restored(old_state, "")
	check(bool(plain[1].get("ok", false)) and int(_bag(plain[0]).armor_chip_capacity) == 1, "ohne Ruestungsauskunft bleibt der gespeicherte Wert 1")
	# Ueberschuss beim Laden: heavy-Stand, Person traegt nun suit
	var over := _fresh_restored(state, "suit")
	check(bool(over[1].get("ok", false)), "Stand mit zu viel im Fach laedt trotzdem (%s)" % str(over[1].get("reason", "")))
	check(_bag(over[0]).items.size() == 2 and int(_bag(over[0]).items.get("satellite_chip", 0)) == 1 and int(_bag(over[0]).armor_chip_capacity) == 1 and _totals(over[0]) == _totals(s), "Ueberschuss liegt nach dem Laden im Lager (Chip bleibt), Summe gleich, ohne Ruestungswechsel")
	# W2: kein Lager am Ort -> nichts verschieben, nichts loeschen; Mehrinhalt bleibt bis zu einem Ort mit Lager
	var nolager := _fresh_restored(state, "heavy", false)
	var inv_ref: Dictionary = nolager[0].get("_inventory")
	var base_saved: Dictionary = inv_ref[BASE]
	inv_ref.erase(BASE)
	_armor["u1"] = "suit"
	nolager[0].sync_compartments_after_load()
	check(int(inv_ref[BAG].armor_chip_capacity) == 7 and INV.count_ammo(inv_ref[BAG].items) == 7, "ohne Lager: nichts verschoben, nichts geloescht, Groesse bleibt")
	inv_ref[BASE] = base_saved
	nolager[0].sync_compartments_after_load()
	check(int(inv_ref[BAG].armor_chip_capacity) == 1 and INV.count_ammo(inv_ref[BAG].items) == 1 and _totals(nolager[0]) == _totals(s), "am Ort mit Lager geht der Mehrinhalt ins Lager, Summe gleich")
	# Abfragen aendern keinen Zustand: Speichern/Abfragen zeigen die neue Groesse, der Behaelter selbst bleibt
	var pure := _fresh_restored(state, "heavy")
	_armor["u1"] = "light"
	var stored_before: Dictionary = pure[0].get("_inventory")[BAG].duplicate(true)
	var view_size := int(pure[0].get_supply_snapshot().inventory[BAG].armor_chip_capacity)
	var exported_size := int(pure[0].export_state().inventory[BAG].armor_chip_capacity)
	check(pure[0].get("_inventory")[BAG] == stored_before and int(stored_before.armor_chip_capacity) == 7, "Abfrage und Speichern aendern den Zustand nicht")
	check(view_size == 7 and exported_size == 7, "Inhalt passt nicht in 3 Plaetze: Abfrage zeigt weiter 7")
	# Echter Besitzer: SimulationRoot reicht Loadout-Wiederherstellung an die Versorgung weiter
	var sim: Node = SIM.new()
	var owner: RefCounted = LOADOUT_STATE.new()
	var wired := _fresh_restored(state, "heavy", false)
	sim.configure_personnel_loadouts(owner)
	sim.configure_singleplayer_owners(null, wired[0])
	sim.request_personnel_loadout_command("restore", {"loadouts": {"u1": {"armor": "suit", "weapon_1": "pistol", "weapon_2": "none"}}})
	check(int(_bag(wired[0]).armor_chip_capacity) == 1 and INV.count_ammo(_bag(wired[0]).items) == 1 and _totals(wired[0]) == _totals(s), "SimulationRoot: nach dem Wiederherstellen der Loadouts stimmt Fachgroesse und Ueberschuss liegt im Lager")
	sim.free()
	# Zahl im Behaelter ausser Reichweite: Stand wird abgelehnt (strenge Form bleibt)
	var broken: Dictionary = state.duplicate(true)
	broken.inventory[BAG].armor_chip_capacity = 0
	check(not _fresh_restored(broken, "heavy")[1].get("ok", true), "Fachgroesse 0 im Stand bleibt ungueltig")

# ---------- Verlust ----------

func _loss_part() -> void:
	var s := _sup("light")
	_give(s, "satellite_chip", 1); _give(s, "ammo_light", 2)
	_move(s, "satellite_chip", BASE, BAG); _move(s, "ammo_light", BASE, BAG, 2)
	var r: Dictionary = s.discard_person_equipment("u1")
	check(bool(r.get("ok", false)) and int(r.discarded) == 2 and Array(r.kept_quest_items) == ["satellite_chip"], "Verlust: Magazine gehen verloren, der Chip kommt ins Lager (wie vorher)")
	check(not _inv(s).has(BAG) and _count(s, "ammo_light") == 0 and _count(s, "satellite_chip") == 1, "Verlust: Behaelter weg, kein Magazin mehr, genau ein Chip im Lager")

# ---------- Anzeige ----------

func _panel_part() -> void:
	var panel: Control = PANEL.new()
	var heading: String = panel.call("_carried_storage_title", {"capacity": 0, "armor_chip_capacity": 7, "items": {"satellite_chip": 1, "ammo_light": 2}})
	check(heading.begins_with("Rüstungsfach (2/7)"), "Ueberschrift: Ruestungsfach (belegt/gesamt) -> '%s'" % heading.replace("\n", " | "))
	var light_h: String = panel.call("_carried_storage_title", {"capacity": 12, "armor_chip_capacity": 3, "items": {"ammo_rail": 4}})
	check(light_h.begins_with("Rüstungsfach (3/3)") and light_h.contains("Rucksack · 1/12"), "voll belegtes Fach, Rest im Rucksack -> '%s'" % light_h.replace("\n", " | "))
	panel.free()
