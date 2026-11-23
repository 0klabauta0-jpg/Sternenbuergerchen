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

## Schlanke Attrappen fuer den Einsatz: Ablauf (Flow), Einsatzszene mit Taktik-Steuerung und eine Einheit an einer Position.
class FakeUnit extends Node2D:
	func get_vital_state() -> String: return "fit"
class FakeController extends Node:
	var _deployed_unit_ids := {"u1": true}
	var unit: Node2D
	func _find_friendly_unit_by_id(_id: String) -> Node: return unit
	func _find_mission_dropship_card_entry(_craft: String) -> Dictionary: return {}
	func _get_deployed_unit_fireteam_id(_id: String) -> String: return ""
	func _is_parked_campaign_dropship(_craft: String) -> bool: return true
	func _campaign_landed_craft_position(_craft: String) -> Vector2: return Vector2.ZERO
class FakeFlow extends Node:
	var _aircraft_location_by_craft := {"ship": "mission"}
	var mission: Node
	func get_mission_for_craft(_craft: String) -> Node: return mission
	func _find_mission_drop_card_in_planning_state(_craft: String) -> Dictionary: return {"embarked_unit_ids": ["u1"]}
## Der echte Adapter; nur die Verbindung zur Simulation ist ersetzt: Befehle gehen direkt an den echten Versorgungszustand.
class FakeAdapter extends "res://scripts/meta/singleplayer_runtime_adapter.gd":
	func _service_context(_craft_id: String) -> Dictionary: return {}
	func _commit(category: String, operation: String, payload: Dictionary, request_id: String, context: Dictionary = {}) -> Dictionary:
		return _supply.apply_command({"contract_category": category, "operation": operation, "payload": payload, "request_id": request_id}, context)

func _run() -> void:
	_stack_part()
	_field_part()
	_hint_part()
	_hint_b5()
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
func _drag(s: RefCounted, source: String, item: String, target: String, one_only: bool = false, accessible: Array = [BASE, BAG, SHIP], adapter: Object = null) -> Dictionary:
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
	# Mit Adapter: der echte Befehlsweg des Einsatzes (request_operation -> Zugriffskontext der Person -> Versorgungsbefehl).
	var result: Dictionary = Dictionary(adapter.call("request_operation", "inventory_transfer", payload)) if adapter != null else s.apply_command(_cmd("inventory_transfer", payload), {"accessible_containers": accessible})
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

# ---------- B4 ----------

## Echter Adapter mit Attrappen fuer Ablauf und Einsatzszene; die Einheit u1 steht `distance` vom geparkten Schiff (Position 0,0) entfernt.
func _field_adapter(s: RefCounted, distance: float) -> Object:
	var unit := FakeUnit.new()
	unit.position = Vector2(distance, 0)
	var controller := FakeController.new()
	controller.name = "TacticalController"
	controller.unit = unit
	var mission := Node.new()
	mission.add_child(controller)
	mission.add_child(unit)
	var flow := FakeFlow.new()
	flow.mission = mission
	var adapter := FakeAdapter.new()
	adapter.set("_flow", flow)
	adapter.set("_supply", s)
	adapter.set("_simulation", Node.new())
	return adapter

func _field_part() -> void:
	# An der Basis: Magazine aus dem Lager in die Schiffsfracht ziehen (Mitnehmen), ganzer Stapel.
	var s := _sup("light")
	_give(s, BASE, "ammo_light", 12)
	var take: Dictionary = _drag(s, BASE, "ammo_light", SHIP)
	check(int(take.amount) == 12 and bool(take.result.get("ok", false)) and _n(s, SHIP, "ammo_light") == 12 and _n(s, BASE, "ammo_light") == 0, "B4: Basis: 12 Magazine vom Lager in die Schiffsfracht in einem Zug (%s)" % str(take.result.get("reason", "ok")))
	# Im Einsatz, nah am Schiff (50 <= 128): Schiffsfracht erreichbar, Fach in einem Zug fuellen, zurueckziehen.
	var near_adapter: Object = _field_adapter(s, 50.0)
	var near_context: Dictionary = near_adapter.call("get_inventory_context", "u1", "ship")
	check(Array(near_context.get("accessible_containers", [])).has(SHIP) and Array(near_context.get("accessible_containers", [])).has(BAG) and not Array(near_context.get("accessible_containers", [])).has(BASE), "B4: nah am Schiff: Schiffsfracht und eigener Stauraum erreichbar, das Basislager nicht (%s)" % str(near_context.get("accessible_containers")))
	var fill: Dictionary = _drag(s, SHIP, "ammo_light", BAG, false, [], near_adapter)
	check(int(fill.amount) == 3 and bool(fill.result.get("ok", false)) and _n(s, BAG, "ammo_light") == 3 and _n(s, SHIP, "ammo_light") == 9, "B4: im Einsatz am Schiff: das Fach (3) wird in einem Zug aus der Schiffsfracht gefuellt, Fracht 12 -> 9 (%s)" % str(fill))
	var back: Dictionary = _drag(s, BAG, "ammo_light", SHIP, false, [], near_adapter)
	check(int(back.amount) == 3 and bool(back.result.get("ok", false)) and _n(s, BAG, "ammo_light") == 0 and _n(s, SHIP, "ammo_light") == 12, "B4: im Einsatz: zurueck in die Schiffsfracht (%s)" % str(back))
	# Weit weg (500 > 128): Schiffsfracht nicht erreichbar, der Befehl lehnt ab, nichts bewegt sich.
	var far_adapter: Object = _field_adapter(s, 500.0)
	var far_context: Dictionary = far_adapter.call("get_inventory_context", "u1", "ship")
	check(not Array(far_context.get("accessible_containers", [])).has(SHIP) and Array(far_context.get("accessible_containers", [])).has(BAG), "B4: zu weit vom Schiff: Schiffsfracht nicht erreichbar (%s)" % str(far_context.get("accessible_containers")))
	var far: Dictionary = _drag(s, SHIP, "ammo_light", BAG, false, [], far_adapter)
	check(not bool(far.result.get("ok", true)) and String(far.result.get("reason", "")) == "inventory_access" and _n(s, BAG, "ammo_light") == 0 and _n(s, SHIP, "ammo_light") == 12, "B4: zu weit: Zug abgelehnt (%s), nichts bewegt" % str(far.result.get("reason", "")))
	near_adapter.free()
	far_adapter.free()

func _find_label(node: Node, text: String) -> Label:
	if node is Label and String(node.text) == text: return node
	for child in node.get_children():
		var hit: Label = _find_label(child, text)
		if hit != null: return hit
	return null

func _hint_part() -> void:
	var s := _sup("light")
	_give(s, SHIP, "ammo_light", 5)
	var unit := {"id": "u1", "name": "Test", "role": "Soldat", "loadout": {"armor": "light", "weapon_1": "pistol", "weapon_2": "none"}}
	var far_panel: Control = PANEL.new()
	root.add_child(far_panel)
	far_panel.call("update_snapshot", _inv(s), unit, "ship", [BAG], false)
	check(_find_label(far_panel, "Schiffsfracht nur in der Nähe des Schiffs erreichbar.") != null, "B4: Fenster im Einsatz, Schiff zu weit: der Hinweis steht da")
	far_panel.free()
	var near_panel: Control = PANEL.new()
	root.add_child(near_panel)
	near_panel.call("update_snapshot", _inv(s), unit, "ship", [BAG, SHIP], false)
	check(_find_label(near_panel, "Schiffsfracht nur in der Nähe des Schiffs erreichbar.") == null, "B4: Fenster im Einsatz, Schiff nah: kein Hinweis")
	near_panel.free()

# ---------- B5 ----------

func _hint_b5() -> void:
	var s := _sup("light")
	_give(s, BASE, "ammo_light", 6)
	_drag(s, BASE, "ammo_light", BAG)
	var full: Dictionary = _drag(s, BASE, "ammo_light", BAG)
	check(not bool(full.result.get("ok", true)) and String(full.result.get("message", "")) == "Fach voll – mit einem Rucksack passen mehr Magazine hinein.", "B5: Fach voll, kein Rucksack: Hinweis (%s)" % str(full.result.get("message", "")))
	check(_n(s, BAG, "ammo_light") == 3 and _n(s, BASE, "ammo_light") == 3, "B5: nichts bewegt")
	# Mit Rucksack (voll): der allgemeine Satz, nicht der Rucksack-Hinweis.
	var t := _sup("light")
	Dictionary(t._inventory[BAG])["capacity"] = 1
	_give(t, BASE, "ammo_light", 6)
	_drag(t, BASE, "ammo_light", BAG)
	var packed: Dictionary = _drag(t, BASE, "ammo_light", BAG)
	check(not bool(packed.result.get("ok", true)) and String(packed.result.get("message", "")) == "Kein freier Platz im Zielcontainer", "B5: mit vollem Rucksack bleibt der allgemeine Satz (%s)" % str(packed.result.get("message", "")))
	# Kein Magazin: der allgemeine Satz.
	var w := _sup("light")
	Dictionary(w._inventory[BAG])["capacity"] = 0
	_give(w, BASE, "rifle", 1)
	var rifle: Dictionary = _drag(w, BASE, "rifle", BAG)
	check(not bool(rifle.result.get("ok", true)) and String(rifle.result.get("message", "")) == "Kein freier Platz im Zielcontainer", "B5: Gewehr ohne Rucksack: allgemeiner Satz (%s)" % str(rifle.result.get("message", "")))
