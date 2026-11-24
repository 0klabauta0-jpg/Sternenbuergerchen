extends SceneTree
## Handel 2a-1 (24.11.2026): fuenf Handelsgueter in der Warenboerse (Nahrung, Medizinische Gueter, Verbandsmaterial, Genussmittel, Stims).
## Die Zahlen stehen NUR in data/singleplayer/commodity_market.json; hier stehen Regeln und Rechnungen.
## Abschlusszeile: TRADE_GOODS passed=%d failed=%d
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const INVENTORY = preload("res://scripts/mission/inventory_transfer_contract.gd")
const OFFER_PATH := "res://data/singleplayer/trade_offers.json"
const MARKET_PATH := "res://data/singleplayer/commodity_market.json"
const GOODS := ["food", "medical_supplies", "bandage", "luxury_goods", "stim"]
const BUY_PRICES := {"food": 11, "medical_supplies": 20, "bandage": 11, "luxury_goods": 16, "stim": 24}
## Benit-Zeilen wie auf origin/main (dcf3f7cdb), wortlich.
const OLD_BENIT := {
	"trade_outpost": {"a_benit": {"sell_price": 10, "stock": 8}, "c_benit": {"sell_price": 10, "stock": 8}, "b_benit": {"buy_price": 15}},
	"satellite_crash": {"a_benit": {"sell_price": 10, "stock": 8}, "b_benit": {"sell_price": 10, "stock": 8}, "c_benit": {"buy_price": 15}},
	"polisa": {"a_benit": {"buy_price": 15}, "b_benit": {"buy_price": 15}, "c_benit": {"buy_price": 15}},
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
	_file_part()
	_sell_part()
	_buy_part()
	_old_state_part()
	_known_part()
	print("TRADE_GOODS passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)

func _dat() -> Dictionary:
	return Dictionary(JSON.parse_string(FileAccess.get_file_as_string(OFFER_PATH)))

func _locs() -> Dictionary:
	return Dictionary(Dictionary(JSON.parse_string(FileAccess.get_file_as_string(MARKET_PATH))).get("locations", {}))

func _cmd(op: String, payload: Dictionary) -> Dictionary:
	_seq += 1
	return {"contract_category": "singleplayer_supply", "operation": op, "payload": payload, "request_id": "tg:%d" % _seq}

## Versorgung mit den echten Daten; `market` ersetzt (wenn nicht leer) die Marktdaten durch eine Testkopie im Speicher.
func _sup(market: Dictionary = {}) -> RefCounted:
	var s: RefCounted = SUPPLY.new()
	var defs: Dictionary = _dat()
	if not market.is_empty(): defs["commodity_market"] = market
	var cfg: Dictionary = s.configure([], defs)
	if not cfg.get("ok", false): print("FAIL: Versorgung nicht konfiguriert: ", cfg)
	s.register_craft("ship", 5.0)
	s.configure_inventory([], ["ship"])
	return s

func _ctx(loc: String) -> Dictionary:
	return {"location_id": loc, "craft_busy": false, "craft_id": "ship"}

func _load_ship(s: RefCounted, item: String, amount: int) -> void:
	var r: Dictionary = s.apply_command(_cmd("campaign_cargo", {"container_id": "craft:ship", "item_id": item, "amount": amount}), {"campaign_authorized": true})
	if not r.get("ok", false): print("FAIL: Fracht nicht gebucht: ", item, " ", r)

func _ship(s: RefCounted) -> Dictionary:
	return Dictionary(Dictionary(s.get_supply_snapshot().inventory)["craft:ship"].items)

func _entry(s: RefCounted, loc: String, item: String) -> Dictionary:
	return Dictionary(Dictionary(Dictionary(s.get_supply_snapshot().get("market", {})).get(loc, {})).get(item, {}))

func _sell(s: RefCounted, loc: String, item: String, qty: int = 1) -> Dictionary:
	return s.apply_command(_cmd("sell", {"item_id": item, "quantity": qty, "source_container_id": "craft:ship"}), _ctx(loc))

# ---------- 1 und 2: Datei ----------

func _file_part() -> void:
	var locs: Dictionary = _locs()
	var ok := true
	for loc: String in ["trade_outpost", "satellite_crash"]:
		for item: String in GOODS:
			var e: Dictionary = Dictionary(Dictionary(locs.get(loc, {})).get(item, {}))
			if e.size() != 1 or int(e.get("buy_price", 0)) != int(BUY_PRICES[item]): ok = false
	check(ok, "Datei: die fuenf Gueter stehen an Handelsaussenposten und Absturzstelle nur mit buy_price 11/20/11/16/24")
	var rule_ok := true
	for loc: String in locs:
		for item: String in Dictionary(locs[loc]):
			if Dictionary(locs[loc][item]).has("sell_price") and Dictionary(locs[loc][item]).has("buy_price"): rule_ok = false
	check(rule_ok, "Datei: an keinem Ort Verkauf und Ankauf derselben Ware")
	var old_ok := true
	for loc: String in OLD_BENIT:
		for item: String in OLD_BENIT[loc]:
			var got: Dictionary = Dictionary(Dictionary(locs.get(loc, {})).get(item, {}))
			var want: Dictionary = OLD_BENIT[loc][item]
			if got.size() != want.size(): old_ok = false
			for key: String in want:
				if int(got.get(key, -1)) != int(want[key]): old_ok = false
	check(old_ok, "Datei: die Benit-Zeilen an Handelsaussenposten, Absturzstelle und Polisa sind unveraendert")
	var polisa_ok := true
	for item: String in GOODS:
		if Dictionary(Dictionary(locs.get("polisa", {}))).has(item): polisa_ok = false
	check(polisa_ok, "Datei: Polisa kauft die fuenf Gueter nicht")

# ---------- 3, 4, 8: Verkauf ----------

func _sell_part() -> void:
	var s: RefCounted = _sup()
	_load_ship(s, "food", 3)
	var c0: int = s.get_credits()
	var r: Dictionary = _sell(s, "trade_outpost", "food", 1)
	check(bool(r.get("ok", false)) and int(r.get("proceeds", 0)) == 11 and s.get_credits() == c0 + 11 and int(_ship(s).get("food", 0)) == 2, "Verkauf: 1 Nahrung am Handelsaussenposten bringt 11 Cr, 2 bleiben im Schiff (%s)" % r)
	var p: RefCounted = _sup()
	_load_ship(p, "food", 3)
	var pc: int = p.get_credits()
	var pr: Dictionary = _sell(p, "polisa", "food", 1)
	check(not bool(pr.get("ok", true)) and String(pr.get("reason", "")) == "not_purchased" and p.get_credits() == pc and int(_ship(p).get("food", 0)) == 3, "Verkauf: Polisa kauft Nahrung nicht (%s)" % pr)
	var q: RefCounted = _sup()
	_load_ship(q, "stim", 2)
	_load_ship(q, "b_benit", 1)
	check(q.get_sellable_proceeds("trade_outpost", ["craft:ship"]) == 63, "Verkaufswert: 2 Stims + 1 B-Benit am Handelsaussenposten = 63 Cr")
	var every_ok := true
	for loc: String in ["trade_outpost", "satellite_crash"]:
		for item: String in GOODS:
			var t: RefCounted = _sup()
			_load_ship(t, item, 2)
			var tc: int = t.get_credits()
			if not bool(_sell(t, loc, item, 2).get("ok", false)) or t.get_credits() != tc + 2 * int(BUY_PRICES[item]): every_ok = false
	check(every_ok, "Verkauf: alle fuenf Gueter an beiden Orten zu den Preisen der Datei")

# ---------- 5: Kauf ohne Dienst ----------

func _buy_part() -> void:
	var s: RefCounted = _sup()
	var r: Dictionary = s.apply_command(_cmd("buy", {"offer_id": "market:muellers_farm:food", "quantity": 1}), _ctx("muellers_farm"))
	check(not bool(r.get("ok", true)) and String(r.get("reason", "")) == "trade_unavailable", "Kauf: Nahrung in Muellers Farm ohne Handelsdienst -> trade_unavailable (%s)" % r)
	var locs: Dictionary = _locs()
	var want := {"muellers_farm": {"food": [5, 16]}, "templanon": {"medical_supplies": [12, 8], "bandage": [6, 8]}, "shady_lab": {"luxury_goods": [9, 8], "stim": [14, 4]}}
	var data_ok := true
	for loc: String in want:
		for item: String in want[loc]:
			var e: Dictionary = Dictionary(Dictionary(locs.get(loc, {})).get(item, {}))
			if e.size() != 2 or int(e.get("sell_price", -1)) != int(want[loc][item][0]) or int(e.get("stock", -1)) != int(want[loc][item][1]): data_ok = false
	check(data_ok, "Datei: Muellers Farm, Templanon und Shady Lab verkaufen zu den Preisen und Bestaenden des Plans")

# ---------- 6: alter Stand ----------

func _old_state_part() -> void:
	# Stand von VOR der Aenderung, rechnerisch: Versorgung mit der alten Boerse (nur Benit) erzeugt und gespeichert.
	var old_market := {"locations": OLD_BENIT}
	var old_sup: RefCounted = _sup(old_market)
	old_sup.apply_command(_cmd("buy", {"offer_id": "market:trade_outpost:a_benit", "quantity": 3}), _ctx("trade_outpost"))
	var saved: Dictionary = Dictionary(JSON.parse_string(JSON.stringify(old_sup.export_state())))
	var keys: Dictionary = Dictionary(saved.get("market_stock", {}))
	check(keys.size() == 4 and not keys.has("muellers_farm:food") and not keys.has("templanon:bandage"), "Alter Stand: der erzeugte Stand kennt nur die vier Benit-Bestaende (%d Schluessel)" % keys.size())
	var loaded: RefCounted = SUPPLY.new()
	loaded.configure([], _dat())
	loaded.register_craft("ship", 5.0)
	var r: Dictionary = loaded.restore_state(saved)
	check(bool(r.get("ok", false)), "Alter Stand: laedt mit der neuen Boerse (%s)" % r)
	check(int(_entry(loaded, "muellers_farm", "food").get("stock", -1)) == 16 and int(_entry(loaded, "templanon", "bandage").get("stock", -1)) == 8 and int(_entry(loaded, "templanon", "medical_supplies").get("stock", -1)) == 8 and int(_entry(loaded, "shady_lab", "luxury_goods").get("stock", -1)) == 8 and int(_entry(loaded, "shady_lab", "stim").get("stock", -1)) == 4, "Alter Stand: die neuen Gueter stehen mit vollem Startbestand da (16, 8, 8, 8, 4)")
	check(int(_entry(loaded, "trade_outpost", "a_benit").get("stock", -1)) == 5, "Alter Stand: der gespeicherte Benit-Bestand bleibt (5)")

# ---------- 7: Kennungen ----------

func _known_part() -> void:
	var all_known := true
	for item: String in GOODS:
		if not INVENTORY.known(item): all_known = false
	check(all_known, "Kennungen: alle fuenf Gueter sind dem Frachtvertrag bekannt")
	check(not INVENTORY.known("food_x"), "Kennungen: eine unbekannte Kennung bleibt unbekannt")
