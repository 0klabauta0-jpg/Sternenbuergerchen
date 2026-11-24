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
	_permit_part()
	_outside_part()
	_grants_file_part()
	_m3_state_part()
	_overview_part()
	await _ui_part()
	await _ui_locked_part()
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
## `heavy` = true: die Erlaubnisse fuer Raketenwerfer und Schienenkanone (mit ihrer Munition) kommen ueber echte Belohnungen dazu,
## damit die Teile, die Schienenladung und Raketen kaufen/herstellen, wie bisher laufen. `false` = frische Kampagne ohne Fund.
func _sup(credits: int = -1, heavy: bool = true) -> RefCounted:
	var s: RefCounted = SUPPLY.new()
	var cfg: Dictionary = s.configure([], _dat())
	if not cfg.get("ok", false): print("FAIL: Versorgung nicht konfiguriert: ", cfg)
	s.register_craft("ship", 5.0)
	s.configure_inventory([], ["ship"])
	if heavy:
		for bp: String in ["rocket_launcher", "rail_gun"]: _reward_bp(s, bp)
	if credits >= 0:
		var now: int = s.get_credits()
		if now > credits: s.charge_rescue_fee(now - credits)
		elif now < credits:
			var up_id: String = "m3:up%d" % (_seq + 1)
			s.apply_command(_cmd("apply_reward", {"completion_id": up_id}), {"completion_receipt": {"completion_id": up_id, "runtime_verified": true, "job_id": up_id, "reward": {"credits": credits - now}}})
	return s

## Echte Belohnung mit Erwerbserlaubnis (Weg wie fuer medium_armor).
func _reward_bp(s: RefCounted, bp: String) -> Dictionary:
	_seq += 1
	var cid: String = "erl:bp%d" % _seq
	return s.apply_command(_cmd("apply_reward", {"completion_id": cid}), {"completion_receipt": {"completion_id": cid, "runtime_verified": true, "job_id": cid, "reward": {"blueprint_id": bp}}})

## Kauf wie in der Kampagne: Erwerbserlaubnisse werden geprueft. `craft` = Schiff, an dem der Kauf haengt.
func _buy_c(s: RefCounted, offer: String, craft: String = "ship") -> Dictionary:
	return s.apply_command(_cmd("buy", {"offer_id": offer, "quantity": 1}), {"location_id": "polisa", "craft_busy": false, "craft_id": craft, "require_blueprints": true})

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
		check(o.get("location_ids", []) == ["polisa"] and String(o.get("name", "")) == String(names.get(want[1], "?")) and o.get("unlimited", false) == true and String(o.get("required_blueprint", "")) == String(want[1]), "Daten: Angebot %s: nur Polisa, Name aus ammo_rules.json, unbegrenzt, Erwerbserlaubnis %s" % [id, want[1]])
	var fab: Dictionary = Dictionary(Dictionary(JSON.parse_string(FileAccess.get_file_as_string(RESEARCH_PATH))).get("fabrication", {}))
	for id: String in RECIPES:
		var r: Dictionary = Dictionary(fab.get(id, {}))
		var want: Array = RECIPES[id]
		check(String(r.get("item", "")) == String(want[0]) and int(r.get("output_count", 1)) == int(want[1]) and int(r.get("cost", -1)) == int(want[2]) and _same_inputs(Dictionary(r.get("inputs", {})), want[3]) and not r.has("free"), "Daten: Rezept %s: %d x %s, %d Cr, Zutaten %s, nicht mehr frei (Erwerbserlaubnis noetig)" % [id, want[1], want[0], want[2], want[3]])
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
	# _sup() hat Raketenwerfer und Schienenkanone schon per Belohnung; dazu die zwei Start-Erlaubnisse und medium_armor, in genau dieser Reihenfolge.
	check(Array(snap.blueprints) == ["ammo_light", "ammo_rifle", "rocket_launcher", "ammo_rocket", "rail_gun", "ammo_rail", "medium_armor"], "Bestand: Liste der Erwerbserlaubnisse = Start, dann Belohnungen je mit ihrem Paar (%s)" % [snap.blueprints])

func _roundtrip(s: RefCounted) -> Dictionary:
	return Dictionary(JSON.parse_string(JSON.stringify(s.export_state())))

## Staende mit einer Belohnung ohne echten Auftrag sind nicht speicherbar (Beleg ohne Auftrag): hier daher OHNE Fund (heavy = false);
## Schiene und Rakete werden gekauft (der Kauf prueft ohne Kampagnen-Kontext nichts), hergestellt werden Gewehr- und leichte Magazine.
func _save_part() -> void:
	var s: RefCounted = _sup(-1, false)
	_stock_all(s)
	_buy(s, "polisa_ammo_light")
	_make(s, "ammo_light")
	_buy(s, "polisa_ammo_rail")
	_make(s, "ammo_rifle")
	var loaded: RefCounted = SUPPLY.new()
	loaded.configure([], _dat())
	loaded.register_craft("ship", 5.0)
	var restored: Dictionary = loaded.restore_state(_roundtrip(s))
	check(bool(restored.get("ok", false)), "Speichern/Laden: Stand nach Kauf und Herstellung (je 4 leichte und Gewehr-Magazine) laedt ohne Ablehnung (%s)" % restored)
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
	var s: RefCounted = _sup(-1, false)
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

# ---------- Erwerbserlaubnis (24.11.2026) ----------

func _locked(r: Dictionary) -> bool:
	return not bool(r.get("ok", true)) and String(r.get("reason", "")) == "blueprint_locked"

func _permit_part() -> void:
	var s: RefCounted = _sup(1000, false)
	var snap: Dictionary = s.get_supply_snapshot()
	check(Array(snap.blueprints) == ["ammo_light", "ammo_rifle"], "Erlaubnis: neue Kampagne hat genau ammo_light und ammo_rifle in der Liste (%s)" % [snap.blueprints])
	_stock_all(s)
	var l1: Dictionary = _buy_c(s, "polisa_ammo_light")
	var l2: Dictionary = _buy_c(s, "polisa_ammo_rifle")
	check(bool(l1.get("ok", false)) and bool(l2.get("ok", false)) and int(_ship(s).get("ammo_light", 0)) == 1 and int(_ship(s).get("ammo_rifle", 0)) == 1, "Erlaubnis: leichtes und Gewehr-Magazin sind mit Kampagnenpruefung kaufbar (%s, %s)" % [l1, l2])
	check(bool(_make(s, "ammo_light").get("ok", false)) and bool(_make(s, "ammo_rifle").get("ok", false)) and int(_base(s).get("ammo_light", 0)) == 4 and int(_base(s).get("ammo_rifle", 0)) == 4, "Erlaubnis: leichtes und Gewehr-Magazin sind herstellbar (je 4 Stueck)")
	for id: String in ["ammo_rail", "ammo_rocket"]:
		var key: String = _state_key(s)
		var b: Dictionary = _buy_c(s, "polisa_" + id)
		var m: Dictionary = _make(s, id)
		check(_locked(b) and _locked(m) and _state_key(s) == key, "Erlaubnis: %s ohne Fund: Kauf und Bau abgelehnt mit blueprint_locked, nichts gebucht (%s / %s)" % [id, b.get("reason", "?"), m.get("reason", "?")])
	for id: String in ["polisa_rocket_launcher", "polisa_rail_gun"]:
		check(_locked(_buy_c(s, id)), "Erlaubnis: Angebot %s ohne Fund gesperrt (blueprint_locked)" % id)
	# Echte Belohnung rocket_launcher: Werfer-Angebot, Raketen-Kauf und Raketen-Bau frei, Schiene bleibt gesperrt.
	var rw: Dictionary = _reward_bp(s, "rocket_launcher")
	check(bool(rw.get("ok", false)), "Erlaubnis: Belohnung rocket_launcher gebucht (%s)" % rw)
	var snap2: Dictionary = s.get_supply_snapshot()
	check(Array(snap2.blueprints) == ["ammo_light", "ammo_rifle", "rocket_launcher", "ammo_rocket"], "Erlaubnis: nach der Belohnung kommt ammo_rocket als Paar dazu, Schiene nicht (%s)" % [snap2.blueprints])
	var credits0: int = s.get_credits()
	var gun: Dictionary = _buy_c(s, "polisa_rocket_launcher")
	check(bool(gun.get("ok", false)) and s.get_credits() == credits0 - 260 and int(_ship(s).get("rocket_launcher", 0)) == 1, "Erlaubnis: Raketenwerfer kostet 260 Cr und liegt danach im Schiffslager (%s)" % gun)
	var rk: Dictionary = _buy_c(s, "polisa_ammo_rocket")
	check(bool(rk.get("ok", false)) and int(_ship(s).get("ammo_rocket", 0)) == 1, "Erlaubnis: Raketen kaufbar mit Erlaubnis, auch ohne dass jemand einen Werfer traegt (%s)" % rk)
	check(bool(_make(s, "ammo_rocket").get("ok", false)) and int(_base(s).get("ammo_rocket", 0)) == 2, "Erlaubnis: Raketen herstellbar (2 Stueck)")
	var key2: String = _state_key(s)
	check(_locked(_buy_c(s, "polisa_ammo_rail")) and _locked(_make(s, "ammo_rail")) and _locked(_buy_c(s, "polisa_rail_gun")) and _state_key(s) == key2, "Erlaubnis: Schiene und Schienenkanone weiter gesperrt")
	# Team-Erlaubnis: gilt fuer die ganze Kampagne, nicht je Schiff. Der Kauf kennt nur das Schiff (craft_id), keine einzelne Person.
	var t: RefCounted = SUPPLY.new()
	t.configure([], _dat())
	t.register_craft("ship", 5.0)
	t.register_craft("ship2", 5.0)
	t.configure_inventory([], ["ship", "ship2"])
	_seq += 1
	var up: String = "erl:up%d" % _seq
	t.apply_command(_cmd("apply_reward", {"completion_id": up}), {"completion_receipt": {"completion_id": up, "runtime_verified": true, "job_id": up, "reward": {"credits": 1000}}})
	_reward_bp(t, "rocket_launcher")
	var first: Dictionary = _buy_c(t, "polisa_ammo_rocket", "ship")
	var other: Dictionary = _buy_c(t, "polisa_ammo_rocket", "ship2")
	check(bool(first.get("ok", false)) and bool(other.get("ok", false)) and int(Dictionary(Dictionary(t.get_supply_snapshot().inventory)["craft:ship"].items).get("ammo_rocket", 0)) == 1 and int(Dictionary(Dictionary(t.get_supply_snapshot().inventory)["craft:ship2"].items).get("ammo_rocket", 0)) == 1, "Erlaubnis: gilt fuer das ganze Team - derselbe Kauf an einem ANDEREN Schiff klappt genauso (%s / %s)" % [first, other])
	# Danach die zweite Waffe.
	_reward_bp(s, "rail_gun")
	check(bool(_buy_c(s, "polisa_rail_gun").get("ok", false)) and bool(_buy_c(s, "polisa_ammo_rail").get("ok", false)) and bool(_make(s, "ammo_rail").get("ok", false)), "Erlaubnis: nach rail_gun sind Schienenkanone, Schienenladung (Kauf) und Bau frei")
	# Skirmish/Mehrspieler: required_blueprint wird nicht geprueft.
	var free_ctx: RefCounted = _sup(1000, false)
	var sk: Dictionary = _buy(free_ctx, "polisa_ammo_rocket")
	check(bool(sk.get("ok", false)) and int(_ship(free_ctx).get("ammo_rocket", 0)) == 1, "Skirmish: ohne require_blueprints kauft derselbe Kontext Raketen ohne Erlaubnis (%s)" % sk)
	var sk2: Dictionary = _buy(free_ctx, "polisa_rail_gun")
	check(bool(sk2.get("ok", false)), "Skirmish: auch die Schienenkanone ohne Erlaubnis kaufbar (%s)" % sk2)
	# Alter Stand: weder Erlaubnis noch neue Angebote noch das neue Feld an den Munitionsangeboten gespeichert.
	var old: Dictionary = _roundtrip(_sup(-1, false))
	for id: String in ["polisa_rocket_launcher", "polisa_rail_gun"]:
		old.definitions.offers.erase(id)
		old.stock_by_offer_id.erase(id)
	for id: String in SUPPLY.AMMO_OFFER_IDS: old.definitions.offers[id].erase("required_blueprint")
	var loaded: RefCounted = SUPPLY.new()
	loaded.configure([], _dat())
	var r: Dictionary = loaded.restore_state(old)
	check(bool(r.get("ok", false)), "Alter Stand: ohne neue Angebote und ohne required_blueprint an der Munition laedt (%s)" % r)
	check(Array(loaded.get_supply_snapshot().blueprints) == ["ammo_light", "ammo_rifle"] and bool(_buy_c(loaded, "polisa_ammo_rifle").get("ok", false)) and _locked(_buy_c(loaded, "polisa_ammo_rocket")), "Alter Stand: danach beide Start-Erlaubnisse da, Gewehrmunition kaufbar, Raketen gesperrt")
	var forged: Dictionary = _roundtrip(_sup(-1, false))
	forged.definitions.offers["polisa_ammo_rail"]["required_blueprint"] = "light_armor"
	check(not bool(SUPPLY.new().restore_state(forged).get("ok", true)), "Ladeschutz: eine andere Erlaubnis an einem Munitionsangebot macht den Stand unladbar")

## Auflage W1 (Nachbesserung 2): Ausserhalb der Kampagne (Schalter aus) bleibt alle Munition herstellbar; Vorgabe (Schalter an) ist streng.
func _outside_part() -> void:
	var s: RefCounted = _sup(-1, false)
	_stock_all(s)
	var exp_on: String = JSON.stringify(s.export_state(), "", true)
	var keys_on: Array = s.export_state().keys()
	keys_on.sort()
	check(Array(s.get_supply_snapshot().blueprints) == ["ammo_light", "ammo_rifle"] and _locked(_make(s, "ammo_rail")) and _locked(_make(s, "ammo_rocket")), "Skirmish-Bau: Vorgabe (Schalter an) ist streng wie die Kampagne - Schiene und Raketen gesperrt")
	s.set_blueprint_gate_enabled(false)
	var exp_off: String = JSON.stringify(s.export_state(), "", true)
	check(exp_on == exp_off, "Skirmish-Bau: Export eines Standes mit Schalter aus und mit Schalter an ist gleich (Schalter nicht im Spielstand)")
	var bp: Array = Array(s.get_supply_snapshot().blueprints)
	check(bp == ["ammo_light", "ammo_rifle", "ammo_rail", "ammo_rocket"], "Skirmish-Bau: Schalter aus - alle vier Sorten in den Erlaubnissen, Start zuerst, ohne Waffen (%s)" % [bp])
	check(not bp.has("rocket_launcher") and not bp.has("rail_gun"), "Skirmish-Bau: Waffen-Erlaubnisse (rocket_launcher, rail_gun) sind NICHT in der Liste")
	var owned_by_id: Dictionary = {}
	for row: Dictionary in Array(s.get_supply_snapshot().blueprint_overview): owned_by_id[String(row.get("id", ""))] = bool(row.get("owned", false))
	check(owned_by_id.get("ammo_light", false) == true and owned_by_id.get("ammo_rifle", false) == true and owned_by_id.get("ammo_rail", false) == true and owned_by_id.get("ammo_rocket", false) == true, "Skirmish-Bau: Uebersicht zeigt alle vier Munitionssorten als owned (%s)" % [owned_by_id])
	check(owned_by_id.get("rocket_launcher", true) == false and owned_by_id.get("rail_gun", true) == false, "Skirmish-Bau: Uebersicht zeigt die Waffen weiter als nicht erworben")
	var rail: Dictionary = _make(s, "ammo_rail")
	var rocket: Dictionary = _make(s, "ammo_rocket")
	check(bool(rail.get("ok", false)) and bool(rocket.get("ok", false)) and int(_base(s).get("ammo_rail", 0)) == 2 and int(_base(s).get("ammo_rocket", 0)) == 2, "Skirmish-Bau: Schienenladung und Raketen werden hergestellt (2 + 2 im Basislager) (%s / %s)" % [rail, rocket])
	var keys_off: Array = s.export_state().keys()
	keys_off.sort()
	check(keys_on == keys_off, "Skirmish-Bau: Export hat nach dem Bau dieselben Schluessel wie vorher (kein neuer Schluessel)")
	s.set_blueprint_gate_enabled(true)
	check(Array(s.get_supply_snapshot().blueprints) == ["ammo_light", "ammo_rifle"] and _locked(_make(s, "ammo_rail")) and _locked(_make(s, "ammo_rocket")), "Skirmish-Bau: Schalter wieder an - wieder gesperrt wie in der Kampagne")
	# Datei ohne den Schluessel oder mit falscher Art: leere Liste, keine Warnung; Doppelte entfallen.
	var path: String = "user://erl2_grants.json"
	var cases: Array = [
		['{"version":1,"start":["ammo_light","ammo_rifle"],"bundles":{},"labels":{}}', ["ammo_light", "ammo_rifle"], "fehlt der Schluessel"],
		['{"version":1,"start":["ammo_light","ammo_rifle"],"outside_campaign":"ammo_rail","bundles":{},"labels":{}}', ["ammo_light", "ammo_rifle"], "ist der Schluessel keine Liste"],
		['{"version":1,"start":["ammo_light"],"outside_campaign":["ammo_light","ammo_rail","ammo_rail"],"bundles":{},"labels":{}}', ["ammo_light", "ammo_rail"], "enthaelt die Liste Doppelte"],
		['{"version":1,"start":["ammo_light"],"outside_campaign":["ammo_rail",7],"bundles":{},"labels":{}}', ["ammo_light"], "ist die Liste keine reine Liste von Texten"],
	]
	for c: Array in cases:
		var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		f.store_string(String(c[0]))
		f.close()
		SUPPLY.grants_path_override = path
		SUPPLY.grants_warned = false
		SUPPLY.reset_grants_cache()
		var t: RefCounted = _sup(-1, false)
		t.set_blueprint_gate_enabled(false)
		var got: Array = Array(t.get_supply_snapshot().blueprints)
		check(got == c[1] and SUPPLY.grants_warned == false, "Skirmish-Bau: %s - Erlaubnisse %s, keine Warnung (%s)" % [c[2], c[1], got])
	SUPPLY.grants_path_override = ""
	SUPPLY.grants_warned = false
	SUPPLY.reset_grants_cache()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	# Der Adapter setzt den Schalter aus dem Modus (Quelltext-Pruefung; der echte Adapter-Aufbau ist hier zu gross).
	var adapter_src: String = FileAccess.get_file_as_string("res://scripts/meta/singleplayer_runtime_adapter.gd")
	check(adapter_src.contains("_supply.set_blueprint_gate_enabled(_campaign_mode)"), "Adapter: setzt den Schalter der Versorgung aus dem Kampagnenmodus")

func _grants_file_part() -> void:
	var text: String = FileAccess.get_file_as_string("res://data/singleplayer/blueprint_grants.json").strip_edges()
	check(text == '{"version":1,"start":["ammo_light","ammo_rifle"],"outside_campaign":["ammo_light","ammo_rifle","ammo_rail","ammo_rocket"],"bundles":{"rocket_launcher":["ammo_rocket"],"rail_gun":["ammo_rail"]},"labels":{"ammo_light":"Leichte Munition","ammo_rifle":"Gewehrmunition","ammo_rail":"Schienenladung","ammo_rocket":"Raketen","rocket_launcher":"Raketenwerfer","rail_gun":"Schienenkanone"}}', "Datei: blueprint_grants.json hat genau den vorgegebenen Wortlaut")
	# Kaputte Datei -> Rueckfall auf Start ohne Paare, einmal Warnung; nie eine leere Liste.
	var bad_path: String = "user://erl_bad_grants.json"
	var f: FileAccess = FileAccess.open(bad_path, FileAccess.WRITE)
	f.store_string("{ das ist kein json")
	f.close()
	SUPPLY.grants_path_override = bad_path
	SUPPLY.grants_warned = false
	SUPPLY.reset_grants_cache()
	var s: RefCounted = _sup(1000, false)
	check(Array(s.get_supply_snapshot().blueprints) == ["ammo_light", "ammo_rifle"] and SUPPLY.grants_warned == true, "Rueckfall: kaputte Datei loest die Warnung aus und die Liste ist nicht leer")
	check(Array(s.get_supply_snapshot().blueprint_overview).is_empty() and Dictionary(SUPPLY.blueprint_grants().labels).is_empty() and Dictionary(SUPPLY.blueprint_grants().bundles).is_empty(), "Rueckfall: keine Paare, keine Namen im Code (Uebersicht leer)")
	# Die Datei wird nur einmal gelesen: eine Aenderung der Datei wirkt erst nach dem Zuruecksetzen des Zwischenspeichers.
	var cached: Dictionary = SUPPLY.blueprint_grants()
	var f3: FileAccess = FileAccess.open(bad_path, FileAccess.WRITE)
	f3.store_string('{"version":1,"start":["ammo_rail"],"bundles":{},"labels":{}}')
	f3.close()
	check(SUPPLY.blueprint_grants() == cached and Array(SUPPLY.blueprint_grants().start) == ["ammo_light", "ammo_rifle"], "Zwischenspeicher: geaenderte Datei wird ohne Zuruecksetzen nicht erneut gelesen")
	SUPPLY.reset_grants_cache()
	check(Array(SUPPLY.blueprint_grants().start) == ["ammo_rail"], "Zwischenspeicher: nach dem Zuruecksetzen wird neu gelesen")
	SUPPLY.grants_warned = false
	SUPPLY.grants_path_override = bad_path
	var f4: FileAccess = FileAccess.open(bad_path, FileAccess.WRITE)
	f4.store_string("{ kaputt")
	f4.close()
	SUPPLY.reset_grants_cache()
	for i in 5: SUPPLY.blueprint_grants()
	check(SUPPLY.grants_warned == true, "Zwischenspeicher: kaputte Datei wird bei fuenf Aufrufen nur einmal gemeldet")
	SUPPLY.grants_warned = false
	for i in 5: SUPPLY.blueprint_grants()
	check(SUPPLY.grants_warned == false, "Zwischenspeicher: auch der Rueckfall wird gemerkt (kein erneutes Lesen, keine zweite Warnung)")
	SUPPLY.reset_grants_cache()
	_reward_bp(s, "rocket_launcher")
	var bl: Array = Array(s.get_supply_snapshot().blueprints)
	check(bl == ["ammo_light", "ammo_rifle", "rocket_launcher"], "Rueckfall: Start = leichte und Gewehrmunition, ohne Paare (%s)" % [bl])
	check(bool(_buy_c(s, "polisa_ammo_light").get("ok", false)), "Rueckfall: leichte Munition bleibt kaufbar")
	var f2: FileAccess = FileAccess.open(bad_path, FileAccess.WRITE)
	f2.store_string('{"version":1,"start":[],"bundles":{},"labels":{}}')
	f2.close()
	SUPPLY.reset_grants_cache()
	check(Array(SUPPLY.blueprint_grants().start) == ["ammo_light", "ammo_rifle"], "Rueckfall: leere Start-Liste gilt als unbrauchbar, nie eine leere Liste")
	SUPPLY.grants_path_override = "res://data/singleplayer/gibt_es_nicht.json"
	check(Array(SUPPLY.blueprint_grants().start) == ["ammo_light", "ammo_rifle"], "Rueckfall: fehlende Datei ebenso")
	SUPPLY.grants_path_override = ""
	SUPPLY.reset_grants_cache()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(bad_path))
	check(Array(SUPPLY.blueprint_grants().start) == ["ammo_light", "ammo_rifle"] and Dictionary(SUPPLY.blueprint_grants().bundles).size() == 2, "Rueckfall: Standardpfad wieder hergestellt, Paare sind da")

## Stand der Zeit, als die Raketen-Herstellung noch frei war (M3): Die Erlaubnis wird fuer die Herstellung ueber eine eigene Datei
## vorgetaeuscht (Start-Liste mit allen vier Sorten), danach wird der Stand wie damals exportiert (ohne required_blueprint an der Munition,
## ohne die zwei Waffenangebote). Er muss mit den heutigen Daten laden - mit dem Raketen-Herstellbeleg und den Raketen im Bestand.
func _m3_state_part() -> void:
	var tmp: String = "user://erl_m3_grants.json"
	var f: FileAccess = FileAccess.open(tmp, FileAccess.WRITE)
	f.store_string('{"version":1,"start":["ammo_light","ammo_rifle","ammo_rail","ammo_rocket"],"bundles":{},"labels":{}}')
	f.close()
	SUPPLY.grants_path_override = tmp
	SUPPLY.reset_grants_cache()
	var s: RefCounted = _sup(-1, false)
	_stock_all(s)
	var made: Dictionary = _make(s, "ammo_rocket")
	var bought: Dictionary = _buy(s, "polisa_ammo_rocket")
	check(bool(made.get("ok", false)) and bool(bought.get("ok", false)) and int(_base(s).get("ammo_rocket", 0)) == 2 and int(_ship(s).get("ammo_rocket", 0)) == 1, "M3-Stand: Raketen hergestellt (2) und gekauft (1), wie zur Zeit der freien Rezepte (%s / %s)" % [made, bought])
	var m3: Dictionary = _roundtrip(s)
	SUPPLY.grants_path_override = ""
	SUPPLY.reset_grants_cache()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))
	var has_receipt: bool = false
	for req: Variant in Dictionary(m3.requests).values():
		if String(Dictionary(req).get("signature", "")).contains("ammo_rocket"): has_receipt = true
	check(has_receipt, "M3-Stand: der Stand enthaelt den Herstellbeleg ammo_rocket")
	for id: String in ["polisa_rocket_launcher", "polisa_rail_gun"]:
		m3.definitions.offers.erase(id)
		m3.stock_by_offer_id.erase(id)
	for id: String in SUPPLY.AMMO_OFFER_IDS: m3.definitions.offers[id].erase("required_blueprint")
	var loaded: RefCounted = SUPPLY.new()
	loaded.configure([], _dat())
	loaded.register_craft("ship", 5.0)
	var r: Dictionary = loaded.restore_state(m3.duplicate(true))
	check(bool(r.get("ok", false)) and String(r.get("reason", "")) != "stale_supply_definitions", "M3-Stand: Stand mit Raketen-Herstellbeleg laedt, kein stale_supply_definitions (%s)" % r)
	check(int(_base(loaded).get("ammo_rocket", 0)) == 2 and int(_ship(loaded).get("ammo_rocket", 0)) == 1, "M3-Stand: Raketen im Bestand unveraendert (Basislager 2, Schiffslager 1)")
	check(_locked(_make(loaded, "ammo_rocket")) and _locked(_buy_c(loaded, "polisa_ammo_rocket")), "M3-Stand: danach Raketen-Bau und -Kauf ohne Erlaubnis gesperrt")
	var stock: Dictionary = Dictionary(loaded.get_supply_snapshot().stock_by_offer_id)
	check(int(stock.get("polisa_rocket_launcher", -1)) == 2 and int(stock.get("polisa_rail_gun", -1)) == 2, "Alter Stand: die zwei neuen Waffenangebote haben nach dem Laden Bestand 2")
	# Die Ausnahme ist eng: fehlendes required_blueprint UND anderer Preis an einem Munitionsangebot bleibt unladbar.
	var priced: Dictionary = m3.duplicate(true)
	priced.definitions.offers["polisa_ammo_rail"]["unit_price"] = 46
	var rp: Dictionary = SUPPLY.new().restore_state(priced)
	check(not bool(rp.get("ok", true)) and String(rp.get("reason", "")) == "stale_supply_definitions", "Ladeschutz eng: M3-Stand ohne required_blueprint, aber mit anderem Preis, bleibt unladbar (%s)" % rp)

func _overview_part() -> void:
	var s: RefCounted = _sup(-1, false)
	var ov: Array = Array(s.get_supply_snapshot().blueprint_overview)
	var ids: Array = []
	for row: Dictionary in ov: ids.append(row.id)
	check(ov.size() == 6 and ids == ["ammo_light", "ammo_rifle", "ammo_rail", "ammo_rocket", "rocket_launcher", "rail_gun"], "Uebersicht: sechs Eintraege in der Reihenfolge der Datei (%s)" % [ids])
	var owned: Array = []
	for row: Dictionary in ov: owned.append(bool(row.owned))
	check(owned == [true, true, false, false, false, false], "Uebersicht: neue Kampagne - nur leichte und Gewehrmunition gehoert (%s)" % [owned])
	check(String(ov[0].name) == "Leichte Munition" and String(ov[3].name) == "Raketen" and String(ov[5].name) == "Schienenkanone", "Uebersicht: Namen aus der Datei")
	_reward_bp(s, "rail_gun")
	var owned2: Array = []
	for row: Dictionary in Array(s.get_supply_snapshot().blueprint_overview): owned2.append(bool(row.owned))
	check(owned2 == [true, true, true, false, false, true], "Uebersicht: nach rail_gun gehoeren auch Schienenladung und Schienenkanone (%s)" % [owned2])

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

func _no_snapshot() -> Dictionary:
	return {}

func _no_command(_a: Variant = null, _b: Variant = null, _c: Variant = null) -> Dictionary:
	return {"ok": false}

## Anzeige OHNE Raketen-/Schienen-Erlaubnis (frische Kampagne): Werkstatt und Polisa mit den echten Ansichten.
func _ui_locked_part() -> void:
	var s: RefCounted = _sup(1000, false)
	_stock_all(s)
	var panel: Control = PRESENTER.new()
	root.add_child(panel)
	panel.call("_build")
	panel.call("configure", Callable(self, "_no_snapshot"), Callable(self, "_no_command"))  # ohne Befehlsweg sind alle Knoepfe gesperrt
	panel.call("set_section", "workshop")  # Der Zustandstext je Zeile entsteht beim Aufbau der Werkstatt-Seite; set_section holt sich selbst einen Abzug, daher VOR dem eigenen refresh.
	panel.call("refresh", {"mode": "campaign", "campaign": {"jobs": {}, "progress": {}}, "supply": s.get_supply_snapshot(), "crafts": [{"craft_id": "ship", "location_id": "homebase", "busy": false}], "service_contexts_by_craft_id": {"ship": {"location_id": "homebase", "craft_busy": false}}, "home_services": {"workshop_available": true}})
	panel.call("_apply_section")  # setzt Zustandstext und Kartensichtbarkeit aus dem eben uebergebenen Abzug
	var actions: Dictionary = panel.get("_campaign_buttons")
	for id: String in ["ammo_light", "ammo_rifle"]:
		var entry: Dictionary = Dictionary(actions.get("campaign_fabricate" + id, {}))
		check(not entry.is_empty() and entry.button.visible and not entry.button.disabled and String(entry.state_label.text) == "Erwerbserlaubnis freigeschaltet", "Anzeige ohne Fund, Werkstatt: %s zeigt 'Erwerbserlaubnis freigeschaltet' und ist bedienbar (ist '%s', sichtbar %s, gesperrt %s, Tipp '%s', Eintraege %d)" % [id, "" if entry.is_empty() else String(entry.state_label.text), "" if entry.is_empty() else str(entry.button.visible), "" if entry.is_empty() else str(entry.button.disabled), "" if entry.is_empty() else String(entry.button.tooltip_text), actions.size()])
	for id: String in ["ammo_rail", "ammo_rocket"]:
		var entry2: Dictionary = Dictionary(actions.get("campaign_fabricate" + id, {}))
		# Ist-Stand (geprueft in der Werkstatt-Ansicht): gesperrte Rezepte bleiben in der Liste, als gesperrt gezeigt. (In der Ansicht "Alles" waeren sie ausgeblendet.)
		check(not entry2.is_empty() and entry2.button.visible and entry2.card.visible and entry2.button.disabled and String(entry2.state_label.text) == "Gesperrt · Erwerbserlaubnis fehlt", "Anzeige ohne Fund, Werkstatt: %s steht gesperrt in der Liste mit 'Gesperrt · Erwerbserlaubnis fehlt' (ist: leer %s, Knopf sichtbar %s, Karte sichtbar %s, Text '%s')" % [id, entry2.is_empty(), "-" if entry2.is_empty() else str(entry2.button.visible), "-" if entry2.is_empty() else str(entry2.card.visible), "-" if entry2.is_empty() else String(entry2.state_label.text)])
	panel.free()
	var supply: Dictionary = s.get_supply_snapshot()
	var offers: Dictionary = {}
	for oid: String in supply.offers:
		if Array(supply.offers[oid].get("location_ids", [])).has("polisa"): offers[oid] = supply.offers[oid]
	var snapshot: Dictionary = {"service_ready": true, "craft_id": "ship", "craft_name": "ship", "credits": 1000, "offers": offers, "stock": supply.stock_by_offer_id, "inventory": supply.inventory, "people": [], "blueprints": supply.blueprints, "require_blueprints": true, "fuel": 5.0, "fuel_capacity": 10.0, "fuel_price_per_unit": 1.0, "revision": 1}
	var screen: Control = load("res://scripts/ui/polisa_station_screen.gd").new()
	root.add_child(screen)
	screen.call("configure", Node.new())
	screen.call("_select_page", "infantry")
	screen.call("refresh", snapshot)
	for oid: String in ["polisa_ammo_light", "polisa_ammo_rifle", "polisa_ammo_rail", "polisa_ammo_rocket", "polisa_rocket_launcher", "polisa_rail_gun"]:
		var card: Node = screen.find_child("Product_" + oid, true, false)
		var texts: Array = []
		var enabled_buy: bool = false
		var locked_button: bool = false
		if card != null:
			for n: Node in card.find_children("*", "Button", true, false):
				texts.append(String((n as Button).text))
				if String((n as Button).text) == "Kaufen" and not (n as Button).disabled: enabled_buy = true
				if String((n as Button).text) == "Erwerbserlaubnis fehlt" and (n as Button).disabled: locked_button = true
		var should_open: bool = oid in ["polisa_ammo_light", "polisa_ammo_rifle"]
		check(card != null and enabled_buy == should_open and locked_button == (not should_open), "Anzeige ohne Fund, Polisa: %s %s (Knoepfe %s)" % [oid, "kaufbar" if should_open else "'Erwerbserlaubnis fehlt', gesperrt", texts])
	screen.free()

## Haendlerzeilen auf Polisa: die echte Stationsansicht mit dem echten Versorgungs-Auszug (Angebote, Bestand, Schiffslager).
func _polisa_part() -> void:
	var s: RefCounted = _sup()
	_buy(s, "polisa_ammo_rail")
	var supply: Dictionary = s.get_supply_snapshot()
	var offers: Dictionary = {}
	for id: String in supply.offers:
		if Array(supply.offers[id].get("location_ids", [])).has("polisa"): offers[id] = supply.offers[id]
	var snapshot: Dictionary = {"service_ready": true, "craft_id": "ship", "craft_name": "ship", "credits": 30, "offers": offers, "stock": supply.stock_by_offer_id, "inventory": supply.inventory, "people": [], "blueprints": supply.blueprints, "require_blueprints": true, "fuel": 5.0, "fuel_capacity": 10.0, "fuel_price_per_unit": 1.0, "revision": 1}
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
