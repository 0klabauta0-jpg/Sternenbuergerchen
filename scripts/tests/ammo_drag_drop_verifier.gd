extends SceneTree
## M6b (23.11.2026): Munition von Hand auffuellen per Drag and Drop.
##   B2 ein Zug bewegt den ganzen Stapel, soweit im Ziel Platz ist (Fach plus Rucksack); Umschalttaste = 1; passt nichts -> alles bleibt
##   B4 Schiffsfracht im Einsatz: nah (erreichbar, Zug moeglich) / fern (nicht erreichbar, Hinweis); an der Basis Lager -> Schiffsfracht
##   B5 Fach voll ohne Rucksack: Hinweis "Fach voll - mit einem Rucksack passen mehr Magazine hinein."
## Alles ueber den echten Weg: Panel (_drop_to) -> Signal operation_requested -> Befehl inventory_transfer im echten Versorgungszustand.
## Abschlusszeile: AMMO_DRAG_DROP passed=%d failed=%d
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const INV = preload("res://scripts/mission/inventory_transfer_contract.gd")
const PANEL = preload("res://scripts/ui/components/personnel_inventory_panel.gd")
const OFFER_PATH := "res://data/singleplayer/trade_offers.json"
const BAG := "unit:u1:backpack"
const BASE := "base:homebase"
const SHIP := "craft:ship"
var passed := 0
var failed := 0
var _seq := 0
var _armor := {"u1": "light"}

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("PASS: " if ok else "FAIL: ", label)

func _run() -> void:
	_stack_part()
	print("AMMO_DRAG_DROP passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)

# ---------- Hilfen ----------

func _cmd(op: String, payload: Dictionary) -> Dictionary:
	_seq += 1
	return {"contract_category": "singleplayer_supply", "operation": op, "payload": payload, "request_id": "m6b:%d" % _seq}

func _sup(armor: String) -> RefCounted:
	var s: RefCounted = SUPPLY.new()
	var data: Dictionary = Dictionary(JSON.parse_string(FileAccess.get_file_as_string(OFFER_PATH)))
	if not s.configure([], data).get("ok", false): print("FAIL: Versorgung nicht konfiguriert")
	s.register_craft("ship", 5.0)
	s.configure_inventory(["u1"], ["ship"], true)
	_armor["u1"] = armor
	s.set_armor_provider(func(unit_id: String) -> String: return String(_armor.get(unit_id, "")))
	return s

func _give(s: RefCounted, container: String, item: String, amount: int) -> void:
	var r: Dictionary = s.apply_command(_cmd("campaign_cargo", {"container_id": container, "item_id": item, "amount": amount}), {"campaign_authorized": true})
	if not r.get("ok", false): print("FAIL: Fracht nicht gebucht: ", item, " ", r)

func _inv(s: RefCounted) -> Dictionary:
	return Dictionary(s.get_supply_snapshot().inventory)

func _n(s: RefCounted, container: String, item: String) -> int:
	return int(Dictionary(Dictionary(_inv(s).get(container, {})).get("items", {})).get(item, 0))

## Der echte Weg: das Panel bekommt den Bestand, ein Zug (_drop_to) schickt seine Anfrage, die ueber den Befehl im Versorgungszustand laeuft.
## Rueckgabe: {"amount": gesendete Menge, "result": Antwort des Befehls}.
func _drag(s: RefCounted, source: String, item: String, target: String, one_only: bool = false, accessible: Array = [BASE, BAG, SHIP]) -> Dictionary:
	var panel: Control = PANEL.new()
	panel.set("_unit_id", "u1")
	panel.set("_craft_id", "ship")
	panel.set("_inventory_data", _inv(s))
	var sent: Array = []
	panel.connect("operation_requested", func(op: String, payload: Dictionary) -> void: sent.append([op, payload]))
	panel.call("_drop_to", {"type": "inventory_item", "source_container_id": source, "item_id": item}, target, one_only)
	panel.free()
	if sent.size() != 1 or String(sent[0][0]) != "inventory_transfer": return {"amount": -1, "result": {}}
	var payload: Dictionary = sent[0][1]
	var result: Dictionary = s.apply_command(_cmd("inventory_transfer", payload), {"accessible_containers": accessible})
	return {"amount": int(payload.get("amount", -1)), "result": result}

# ---------- B2 ----------

func _stack_part() -> void:
	# Ganzer Stapel, der ins Fach passt: 2 von 2 (Leichte Ruestung: Fach 3).
	var s := _sup("light")
	_give(s, BASE, "ammo_light", 2)
	var one: Dictionary = _drag(s, BASE, "ammo_light", BAG)
	check(int(one.amount) == 2 and bool(one.result.get("ok", false)) and _n(s, BAG, "ammo_light") == 2 and _n(s, BASE, "ammo_light") == 0, "B2: ein Zug bewegt den ganzen Stapel (2), Lager 0, Fach 2 (%s)" % str(one))
	# Platzgrenze: 10 im Lager, Fach 3, kein Rucksack -> 3 bewegt (eins ist schon da: nur 1 passt noch).
	var t := _sup("light")
	_give(t, BASE, "ammo_light", 10)
	var limit: Dictionary = _drag(t, BASE, "ammo_light", BAG)
	check(int(limit.amount) == 3 and _n(t, BAG, "ammo_light") == 3 and _n(t, BASE, "ammo_light") == 7, "B2: Platzgrenze: Fach 3 -> 3 von 10 bewegt, Lager 7 (%s)" % str(limit))
	var more: Dictionary = _drag(t, BASE, "ammo_light", BAG)
	check(int(more.amount) == 1 and not bool(more.result.get("ok", true)) and _n(t, BAG, "ammo_light") == 3 and _n(t, BASE, "ammo_light") == 7, "B2: Fach voll: nichts passt -> alles bleibt, Ablehnung (%s)" % str(more.result.get("reason", "")))
	# Umschalttaste: genau 1.
	var u := _sup("light")
	_give(u, BASE, "ammo_light", 10)
	var shift: Dictionary = _drag(u, BASE, "ammo_light", BAG, true)
	check(int(shift.amount) == 1 and _n(u, BAG, "ammo_light") == 1 and _n(u, BASE, "ammo_light") == 9, "B2: mit Umschalttaste genau 1 Stueck (%s)" % str(shift))
	# Teilweise belegt: Fach 3, 1 drin, 10 im Lager -> 2 passen.
	var part := _drag(u, BASE, "ammo_light", BAG)
	check(int(part.amount) == 2 and _n(u, BAG, "ammo_light") == 3 and _n(u, BASE, "ammo_light") == 7, "B2: teilweise belegtes Fach: nur die freien 2 Plaetze (%s)" % str(part))
	# Fach plus Rucksack: Rucksack (12) angelegt -> 3 + 12 = 15 Plaetze fuer Magazine.
	var v := _sup("light")
	Dictionary(v._inventory[BAG])["capacity"] = 12
	_give(v, BASE, "ammo_light", 20)
	var big: Dictionary = _drag(v, BASE, "ammo_light", BAG)
	check(int(big.amount) == 15 and _n(v, BAG, "ammo_light") == 15 and _n(v, BASE, "ammo_light") == 5, "B2: Fach 3 plus Rucksack 12: 15 von 20 bewegt (%s)" % str(big))
	# Andere Gegenstaende: Gewehre ins Schiffslager (Kapazitaet 48): ganzer Stapel.
	var w := _sup("light")
	_give(w, BASE, "rifle", 2)
	var rifle_stack := _n(w, BASE, "rifle") # Startlager hat schon 2: der Stapel ist 4
	var rifles: Dictionary = _drag(w, BASE, "rifle", SHIP)
	check(rifle_stack == 4 and int(rifles.amount) == 4 and _n(w, SHIP, "rifle") == 4 and _n(w, BASE, "rifle") == 0, "B2: auch andere Gegenstaende: der ganze Stapel (4 Gewehre) in einem Zug ins Schiffslager (%s)" % str(rifles))
