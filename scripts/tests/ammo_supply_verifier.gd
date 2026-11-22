extends SceneTree
## Task M3 (22.11.2026): Munition herstellen (Werkstatt) und kaufen (Polisa) ueber den echten Versorgungszustand.
## Zahlen laut Auftrag m3-brief.md; sie stehen NUR in den Daten (trade_offers.json, research.json), hier stehen die Erwartungen.
## Abschlusszeile: AMMO_SUPPLY passed=%d failed=%d
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const INV = preload("res://scripts/mission/inventory_transfer_contract.gd")
const RULES = preload("res://scripts/core/ammo_rules.gd")
const PRESENTER = preload("res://scripts/meta/singleplayer_services_presenter.gd")
const OFFER_PATH := "res://data/singleplayer/trade_offers.json"
const RESEARCH_PATH := "res://data/singleplayer/research.json"
## Kennung -> [Preis, Gegenstand]
const OFFERS := {"polisa_ammo_light": [12, "ammo_light"], "polisa_ammo_rifle": [20, "ammo_rifle"], "polisa_ammo_rail": [45, "ammo_rail"], "polisa_ammo_rocket": [60, "ammo_rocket"]}
## Rezept -> [Gegenstand, Stueckzahl, Credits, Zutaten]
const RECIPES := {
	"ammo_light": ["ammo_light", 4, 5, {"a_benit": 1}],
	"ammo_rifle": ["ammo_rifle", 4, 5, {"a_benit": 1, "b_benit": 1}],
	"ammo_rail": ["ammo_rail", 2, 10, {"b_benit": 1, "c_benit": 1}],
	"ammo_rocket": ["ammo_rocket", 2, 10, {"a_benit": 1, "b_benit": 1, "c_benit": 1}],
}
var passed := 0
var failed := 0
var _seq := 0

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("PASS: " if ok else "FAIL: ", label)

func _run() -> void:
	_data_part()
	_buy_part()
	_craft_part()
	_space_part()
	_legacy_recipe_part()
	_save_part()
	_receipt_part()
	_old_state_part()
	await _ui_part()
	print("AMMO_SUPPLY passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)

# ---------- Hilfen ----------

func _dat() -> Dictionary:
	return Dictionary(JSON.parse_string(FileAccess.get_file_as_string(OFFER_PATH)))

func _cmd(op: String, payload: Dictionary) -> Dictionary:
	_seq += 1
	return {"contract_category": "singleplayer_supply", "operation": op, "payload": payload, "request_id": "m3:%d" % _seq}

## Versorgung mit den unveraenderten Daten (Startguthaben aus trade_offers.json). Mit `credits` > 0 wird das Guthaben ueber
## die echten Wege eingestellt (Einnahme bzw. Rettungsgebuehr); solche Staende werden nicht gespeichert (Beleg ohne Auftrag).
func _sup(credits: int = -1) -> RefCounted:
	var s: RefCounted = SUPPLY.new()
	var cfg: Dictionary = s.configure([], _dat())
	if not cfg.get("ok", false): print("FAIL: Versorgung nicht konfiguriert: ", cfg)
	s.register_craft("ship", 5.0)
	s.configure_inventory([], ["ship"])
	if credits >= 0:
		var now: int = s.get_credits()
		if now > credits: s.charge_rescue_fee(now - credits)
		elif now < credits:
			var up_id: String = "m3:up%d" % (_seq + 1)
			s.apply_command(_cmd("apply_reward", {"completion_id": up_id}), {"completion_receipt": {"completion_id": up_id, "runtime_verified": true, "job_id": up_id, "reward": {"credits": credits - now}}})
	return s

func _buy(s: RefCounted, offer: String) -> Dictionary:
	return s.apply_command(_cmd("buy", {"offer_id": offer, "quantity": 1}), {"location_id": "polisa", "craft_busy": false, "craft_id": "ship"})

func _give(s: RefCounted, item: String, amount: int) -> void:
	var r: Dictionary = s.apply_command(_cmd("campaign_cargo", {"container_id": "base:homebase", "item_id": item, "amount": amount}), {"campaign_authorized": true})
	if not r.get("ok", false): print("FAIL: Fracht nicht gebucht: ", item, " ", r)

func _make(s: RefCounted, recipe: String) -> Dictionary:
	return s.apply_command(_cmd("campaign_fabricate", {"blueprint_id": recipe}), {"at_home": true, "campaign_authorized": true})

func _base(s: RefCounted) -> Dictionary:
	return Dictionary(s.get_supply_snapshot().item_quantities)

func _ship(s: RefCounted) -> Dictionary:
	return Dictionary(Dictionary(s.get_supply_snapshot().inventory)["craft:ship"].items)

func _state_key(s: RefCounted) -> String:
	return JSON.stringify([s.get_credits(), _base(s), _ship(s)], "", true)

func _stock_all(s: RefCounted) -> void:
	for item: String in ["a_benit", "b_benit", "c_benit"]: _give(s, item, 10)

# ---------- Daten ----------

func _same_inputs(a: Dictionary, b: Dictionary) -> bool:
	if a.size() != b.size(): return false
	for k: String in b:
		if not a.has(k) or int(a[k]) != int(b[k]): return false
	return true

func _data_part() -> void:
	var names: Dictionary = Dictionary(RULES.load_rules().get("ammo_items", {}))
	var offers: Dictionary = Dictionary(_dat().get("offers", {}))
	for id: String in OFFERS:
		var o: Dictionary = Dictionary(offers.get(id, {}))
		var want: Array = OFFERS[id]
		check(not o.is_empty() and String(o.get("item_id", "")) == String(want[1]) and int(o.get("unit_price", -1)) == int(want[0]), "Daten: Angebot %s: Gegenstand %s, Preis %d" % [id, want[1], want[0]])
		check(o.get("location_ids", []) == ["polisa"] and String(o.get("name", "")) == String(names.get(want[1], "?")) and o.get("unlimited", false) == true and not o.has("required_blueprint"), "Daten: Angebot %s: nur Polisa, Name aus ammo_rules.json, unbegrenzt, ohne Erwerbserlaubnis" % id)
	var fab: Dictionary = Dictionary(Dictionary(JSON.parse_string(FileAccess.get_file_as_string(RESEARCH_PATH))).get("fabrication", {}))
	for id: String in RECIPES:
		var r: Dictionary = Dictionary(fab.get(id, {}))
		var want: Array = RECIPES[id]
		check(String(r.get("item", "")) == String(want[0]) and int(r.get("output_count", 1)) == int(want[1]) and int(r.get("cost", -1)) == int(want[2]) and _same_inputs(Dictionary(r.get("inputs", {})), want[3]) and r.get("free", false) == true, "Daten: Rezept %s: %d x %s, %d Cr, Zutaten %s, frei" % [id, want[1], want[0], want[2], want[3]])
	check(not fab.get("medium_armor", {}).has("output_count") and not fab.get("medium_armor", {}).has("free"), "Daten: bestehendes Rezept medium_armor ohne neue Felder")

# ---------- Kaufen ----------

func _buy_part() -> void:
	for id: String in OFFERS:
		var price: int = int(OFFERS[id][0])
		var item: String = String(OFFERS[id][1])
		var s: RefCounted = _sup(1000)
		var stock_before: Dictionary = Dictionary(s.get_supply_snapshot().stock_by_offer_id).duplicate(true)
		var r: Dictionary = _buy(s, id)
		check(bool(r.get("ok", false)) and s.get_credits() == 1000 - price and int(_ship(s).get(item, 0)) == 1, "Kauf %s: bucht genau %d Cr, legt genau 1 %s ab (%s)" % [id, price, item, r])
		for i in 2: _buy(s, id)
		check(int(_ship(s).get(item, 0)) == 3 and s.get_credits() == 1000 - 3 * price and Dictionary(s.get_supply_snapshot().stock_by_offer_id) == stock_before, "Kauf %s: unbegrenzt oft, Bestandszahl bleibt" % id)
		var poor: RefCounted = _sup(price - 1)
		var before: String = _state_key(poor)
		var denied: Dictionary = _buy(poor, id)
		check(not bool(denied.get("ok", true)) and _state_key(poor) == before and poor.get_credits() == price - 1, "Kauf %s: ohne Geld abgelehnt, nichts abgebucht, keine Schulden" % id)
		var exact: RefCounted = _sup(price)
		check(bool(_buy(exact, id).get("ok", false)) and exact.get_credits() == 0, "Kauf %s: mit genau dem Preis moeglich, Guthaben 0" % id)

# ---------- Herstellen ----------

func _craft_part() -> void:
	for id: String in RECIPES:
		var want: Array = RECIPES[id]
		var s: RefCounted = _sup(1000)
		_stock_all(s)
		var base0: Dictionary = _base(s).duplicate(true)
		var r: Dictionary = _make(s, id)
		var base1: Dictionary = _base(s)
		var ok: bool = bool(r.get("ok", false)) and s.get_credits() == 1000 - int(want[2]) and int(base1.get(want[0], 0)) == int(want[1])
		for z: String in want[3]: ok = ok and int(base1.get(z, 0)) == int(base0.get(z, 0)) - int(want[3][z])
		check(ok, "Herstellen %s: genau die Zutaten und %d Cr, genau %d x %s (%s)" % [id, want[2], want[1], want[0], r])
		for fehlt: String in want[3]:
			var t: RefCounted = _sup(1000)
			for z: String in want[3]:
				if z != fehlt: _give(t, z, 3)
			var key: String = _state_key(t)
			var denied: Dictionary = _make(t, id)
			check(not bool(denied.get("ok", true)) and _state_key(t) == key, "Herstellen %s: fehlt %s -> abgelehnt, nichts abgebucht" % [id, fehlt])
		var poor: RefCounted = _sup(int(want[2]) - 1)
		_stock_all(poor)
		var pk: String = _state_key(poor)
		check(not bool(_make(poor, id).get("ok", true)) and _state_key(poor) == pk, "Herstellen %s: zu wenig Credits -> abgelehnt, nichts abgebucht" % id)

func _space_part() -> void:
	for id: String in RECIPES:
		var want: Array = RECIPES[id]
		var made: int = int(want[1])
		var consumed: int = 0
		for z: String in want[3]: consumed += int(want[3][z])
		var s: RefCounted = _sup(1000)
		_stock_all(s)
		var cap: int = int(Dictionary(s.get_supply_snapshot().inventory)["base:homebase"].capacity)
		var used: int = INV.used(_base(s))
		# Platz nach der Herstellung: used - consumed + made. Nur wenn mehr entsteht als verbraucht wird, kann der Platz knapp werden.
		if made > consumed:
			_give(s, "ore", cap + 1 - made + consumed - used)
			var key: String = _state_key(s)
			var denied: Dictionary = _make(s, id)
			check(not bool(denied.get("ok", true)) and _state_key(s) == key, "Platz %s: ein Platz zu wenig -> ganz abgelehnt, nichts abgebucht, nichts teilweise hergestellt" % id)
		var t: RefCounted = _sup(1000)
		_stock_all(t)
		_give(t, "ore", mini(cap, cap - made + consumed) - INV.used(_base(t)))
		check(bool(_make(t, id).get("ok", false)) and int(_base(t).get(want[0], 0)) == made, "Platz %s: genau passend -> hergestellt" % id)

# ---------- Bestehende Rezepte, Spielstand, Belege ----------

func _legacy_recipe_part() -> void:
	var s: RefCounted = _sup(1000)
	var fabricate_before: Dictionary = _make(s, "medium_armor")
	check(not bool(fabricate_before.get("ok", true)), "Bestand: medium_armor ohne Erwerbserlaubnis weiter gesperrt")
	var reward: Dictionary = s.apply_command(_cmd("apply_reward", {"completion_id": "m3:bp"}), {"completion_receipt": {"completion_id": "m3:bp", "runtime_verified": true, "job_id": "m3:bp", "reward": {"blueprint_id": "medium_armor"}}})
	check(bool(reward.get("ok", false)), "Bestand: Erwerbserlaubnis medium_armor ueber die echte Belohnung (%s)" % reward)
	var credits0: int = s.get_credits()
	var armor0: int = int(_base(s).get("armor_medium", 0))
	var r: Dictionary = _make(s, "medium_armor")
	check(bool(r.get("ok", false)) and s.get_credits() == credits0 - 40 and int(_base(s).get("armor_medium", 0)) == armor0 + 1 and not r.has("output_count"), "Bestand: medium_armor liefert weiter genau 1 Stueck fuer 40 Cr, ohne neues Belegfeld (%s)" % r)
	var snap: Dictionary = s.get_supply_snapshot()
	check(not Array(snap.blueprints).has("ammo_light"), "Bestand: die Liste der Erwerbserlaubnisse bleibt unveraendert (keine Munitionseintraege)")

func _roundtrip(s: RefCounted) -> Dictionary:
	return Dictionary(JSON.parse_string(JSON.stringify(s.export_state())))

func _save_part() -> void:
	var s: RefCounted = _sup()
	_stock_all(s)
	_buy(s, "polisa_ammo_light")
	_make(s, "ammo_light")
	_buy(s, "polisa_ammo_rail")
	_make(s, "ammo_rocket")
	var loaded: RefCounted = SUPPLY.new()
	loaded.configure([], _dat())
	loaded.register_craft("ship", 5.0)
	var restored: Dictionary = loaded.restore_state(_roundtrip(s))
	check(bool(restored.get("ok", false)), "Speichern/Laden: Stand nach Kauf und Herstellung (4 und 2 Stueck) laedt ohne Ablehnung (%s)" % restored)
	check(loaded.get_credits() == s.get_credits() and _same_inputs(_base(loaded), _base(s)) and _same_inputs(_ship(loaded), _ship(s)) and int(_base(loaded).get("ammo_light", 0)) == 4 and int(_ship(loaded).get("ammo_light", 0)) == 1, "Speichern/Laden: Credits, Basislager und Schiffslager gleich")
	check(bool(_make(loaded, "ammo_rifle").get("ok", false)) and bool(_buy(loaded, "polisa_ammo_rifle").get("ok", false)), "Speichern/Laden: danach weiter herstellen und kaufen")

func _req(blueprint: String, result: Dictionary) -> Dictionary:
	result["ok"] = true
	result["operation"] = "campaign_fabricate"
	result["request_id"] = "x"
	return {"signature": JSON.stringify({"operation": "campaign_fabricate", "payload": {"blueprint_id": blueprint}}), "result": result}

func _valid(blueprint: String, result: Dictionary) -> bool:
	var s: RefCounted = _sup()
	var requests: Dictionary = Dictionary(JSON.parse_string(JSON.stringify({"x": _req(blueprint, result)})))
	return bool(s._valid_campaign_fabrication_requests(requests))

func _receipt_part() -> void:
	check(_valid("backpack_recycling", {"item_id": "backpack", "recipe_id": "backpack_recycling", "cost": 20, "materials_consumed": {"salvage": 2}}), "Beleg alt: Rucksack-Rezept (mit Zutaten, ohne Stueckzahl) besteht")
	check(_valid("salvage_tool", {"item_id": "salvage_tool"}), "Beleg alt: Rezept ohne Zutaten (nur Kurzbeleg) besteht")
	check(not _valid("backpack_recycling", {"item_id": "backpack", "recipe_id": "backpack_recycling", "cost": 20, "materials_consumed": {"salvage": 2}, "output_count": 4}), "Beleg: Stueckzahl 4 an einem Rezept ohne Stueckzahl wird abgelehnt")
	check(_valid("ammo_light", {"item_id": "ammo_light", "recipe_id": "ammo_light", "cost": 5, "materials_consumed": {"a_benit": 1}, "output_count": 4}), "Beleg neu: ammo_light mit Stueckzahl 4 besteht")
	check(_valid("ammo_rocket", {"item_id": "ammo_rocket", "recipe_id": "ammo_rocket", "cost": 10, "materials_consumed": {"a_benit": 1, "b_benit": 1, "c_benit": 1}, "output_count": 2}), "Beleg neu: ammo_rocket mit Stueckzahl 2 besteht")
	check(not _valid("ammo_light", {"item_id": "ammo_light", "recipe_id": "ammo_light", "cost": 5, "materials_consumed": {"a_benit": 1}, "output_count": 3}), "Beleg neu: falsche Stueckzahl wird abgelehnt")
	check(not _valid("ammo_light", {"item_id": "ammo_light", "recipe_id": "ammo_light", "cost": 5, "materials_consumed": {"a_benit": 1}}), "Beleg neu: fehlende Stueckzahl bei Rezept mit Stueckzahl 4 wird abgelehnt")

func _old_state_part() -> void:
	var s: RefCounted = _sup()
	var old: Dictionary = _roundtrip(s)
	for id: String in OFFERS:
		old.definitions.offers.erase(id)
		old.stock_by_offer_id.erase(id)
	var loaded: RefCounted = SUPPLY.new()
	loaded.configure([], _dat())
	var r: Dictionary = loaded.restore_state(old)
	check(bool(r.get("ok", false)) and Dictionary(loaded.get_supply_snapshot().offers).has("polisa_ammo_rail"), "Alter Stand: ohne die vier Angebote laedt, Angebote sind danach da (%s)" % r)
	check(bool(_buy(loaded, "polisa_ammo_light").get("ok", false)), "Alter Stand: nach dem Laden ist Munition kaufbar")
	# Aenderung an einem bestehenden Angebot bliebe unladbar (Ladeschutz unveraendert streng).
	var tampered: Dictionary = _roundtrip(s)
	tampered.definitions.offers["polisa_pistol"]["unit_price"] = 31
	check(not bool(SUPPLY.new().restore_state(tampered).get("ok", true)), "Ladeschutz: geaenderter Preis eines bestehenden Angebots macht den Stand weiter unladbar")

# ---------- Anzeige ----------

func _ui_part() -> void:
	var names: Dictionary = Dictionary(RULES.load_rules().get("ammo_items", {}))
	var s: RefCounted = _sup(1000)
	var panel: Control = PRESENTER.new()
	root.add_child(panel)
	panel.call("_build")
	panel.call("refresh", {"mode": "campaign", "campaign": {"jobs": {}, "progress": {}}, "supply": s.get_supply_snapshot(), "crafts": [{"craft_id": "ship", "location_id": "homebase", "busy": false}], "service_contexts_by_craft_id": {"ship": {"location_id": "homebase", "craft_busy": false}}, "home_services": {"workshop_available": true}})
	var actions: Dictionary = panel.get("_campaign_buttons")
	for id: String in RECIPES:
		var want: Array = RECIPES[id]
		var entry: Dictionary = Dictionary(actions.get("campaign_fabricate" + id, {}))
		var title: String = ""
		if not entry.is_empty():
			title = String(entry.card.get_child(0).get_child(0).text)
		var expect: String = "%s × %d" % [names[want[0]], want[1]]
		check(not entry.is_empty() and entry.button.visible and title == expect, "Anzeige Werkstatt: Zeile %s sichtbar mit Titel '%s' (ist '%s')" % [id, expect, title])
		var details: String = PRESENTER.get_blueprint_details(id)
		check(details.contains("%d" % int(want[2])) and details.contains("%d × " % int(want[1])), "Anzeige Werkstatt: Detail %s nennt Kosten und Stueckzahl" % id)
	panel.free()
	_polisa_part()

## Haendlerzeilen auf Polisa: die echte Stationsansicht mit dem echten Versorgungs-Auszug (Angebote, Bestand, Schiffslager).
func _polisa_part() -> void:
	var s: RefCounted = _sup()
	_buy(s, "polisa_ammo_rail")
	var supply: Dictionary = s.get_supply_snapshot()
	var offers: Dictionary = {}
	for id: String in supply.offers:
		if Array(supply.offers[id].get("location_ids", [])).has("polisa"): offers[id] = supply.offers[id]
	var snapshot: Dictionary = {"service_ready": true, "craft_id": "ship", "craft_name": "ship", "credits": 30, "offers": offers, "stock": supply.stock_by_offer_id, "inventory": supply.inventory, "people": [], "blueprints": [], "require_blueprints": true, "fuel": 5.0, "fuel_capacity": 10.0, "fuel_price_per_unit": 1.0, "revision": 1}
	var screen: Control = load("res://scripts/ui/polisa_station_screen.gd").new()
	root.add_child(screen)
	screen.call("configure", Node.new())
	screen.call("_select_page", "infantry")
	screen.call("refresh", snapshot)
	var names: Dictionary = Dictionary(RULES.load_rules().get("ammo_items", {}))
	for id: String in OFFERS:
		var card: Node = screen.find_child("Product_" + id, true, false)
		var texts: Array = []
		var buttons: Array = []
		if card != null:
			for n: Node in card.find_children("*", "Label", true, false): texts.append(String((n as Label).text))
			for n: Node in card.find_children("*", "Button", true, false): buttons.append(n)
		var price: int = int(OFFERS[id][0])
		check(card != null and texts.has(String(names[OFFERS[id][1]])) and texts.has("%d Cr" % price), "Anzeige Polisa: Zeile %s mit Name aus ammo_rules.json und Preis %d Cr" % [id, price])
		var shows_unlimited: bool = false
		for t: String in texts: shows_unlimited = shows_unlimited or t.begins_with("Unbegrenzt")
		var only_buy: bool = buttons.size() == 1 and String((buttons[0] as Button).text) == "Kaufen"
		var buy_enabled: bool = only_buy and not (buttons[0] as Button).disabled
		check(shows_unlimited and only_buy and buy_enabled == (price <= 30), "Anzeige Polisa: Zeile %s zeigt 'Unbegrenzt', nur den Knopf Kaufen (bei 30 Cr %s), kein Ausruesten" % [id, "aktiv" if price <= 30 else "gesperrt"])
	screen.free()
