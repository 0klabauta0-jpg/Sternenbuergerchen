extends SceneTree
## Gueter-Dreieck an den drei kleinen Aussenposten (24.11.2026): Muellers Farm, Shady Lab, Templanon.
## Jeder Ort verkauft ein Gut und kauft die zwei anderen. Die Zahlen stehen NUR in data/singleplayer/commodity_market.json; hier stehen Regeln und Rechnungen.
## Abschlusszeile: OUTPOST_TRIANGLE_TRADE passed=%d failed=%d
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const INVENTORY = preload("res://scripts/mission/inventory_transfer_contract.gd")
const OFFER_PATH := "res://data/singleplayer/trade_offers.json"
const MARKET_PATH := "res://data/singleplayer/commodity_market.json"
## Reihenfolge der Runde: Gewaechshaus -> Labor -> Templer -> Gewaechshaus ...
const PLACES := ["muellers_farm", "shady_lab", "templanon"]
const SELLS := {"muellers_farm": "heilkraeuter", "shady_lab": "duenger", "templanon": "aufputschmittel"}
const GOODS := ["heilkraeuter", "duenger", "aufputschmittel"]
const ORIGIN_PRICE := 20
const LIMIT := 12
## Hash der Handelsdatei VOR der Aenderung (die Datei bleibt unangetastet).
const OFFERS_SHA256 := "14A57625D72C00030FC761EF485C495B7FC58F9003333FD3E7766EBC92DB594A"
## Benit-Zeilen und die fuenf Handelsgueter-Zeilen der Warenboerse wie auf origin/main, wortlich.
const OLD_MARKET := {
	"trade_outpost": {"food": {"buy_price": 11}, "medical_supplies": {"buy_price": 20}, "bandage": {"buy_price": 11}, "luxury_goods": {"buy_price": 16}, "stim": {"buy_price": 24}, "a_benit": {"sell_price": 10, "stock": 8}, "c_benit": {"sell_price": 10, "stock": 8}, "b_benit": {"buy_price": 15}},
	"satellite_crash": {"food": {"buy_price": 11}, "medical_supplies": {"buy_price": 20}, "bandage": {"buy_price": 11}, "luxury_goods": {"buy_price": 16}, "stim": {"buy_price": 24}, "a_benit": {"sell_price": 10, "stock": 8}, "b_benit": {"sell_price": 10, "stock": 8}, "c_benit": {"buy_price": 15}},
	"muellers_farm": {"food": {"sell_price": 5, "stock": 16}},
	"templanon": {"medical_supplies": {"sell_price": 12, "stock": 16}, "bandage": {"sell_price": 6, "stock": 16}},
	"shady_lab": {"luxury_goods": {"sell_price": 9, "stock": 16}, "stim": {"sell_price": 14, "stock": 8}},
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
	_data_part()
	_buy_part()
	_sell_part()
	_limit_part()
	_replenish_part()
	_save_part()
	_round_part()
	_scope_part()
	_old_data_part()
	print("OUTPOST_TRIANGLE_TRADE passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)

func _dat() -> Dictionary:
	return Dictionary(JSON.parse_string(FileAccess.get_file_as_string(OFFER_PATH)))

func _locs() -> Dictionary:
	return Dictionary(Dictionary(JSON.parse_string(FileAccess.get_file_as_string(MARKET_PATH))).get("locations", {}))

func _cmd(op: String, payload: Dictionary) -> Dictionary:
	_seq += 1
	return {"contract_category": "singleplayer_supply", "operation": op, "payload": payload, "request_id": "ot:%d" % _seq}

func _sup() -> RefCounted:
	var s: RefCounted = SUPPLY.new()
	var cfg: Dictionary = s.configure([], _dat())
	if not cfg.get("ok", false): print("FAIL: Versorgung nicht konfiguriert: ", cfg)
	s.register_craft("ship", 5.0)
	s.configure_inventory([], ["ship"])
	return s

func _ctx(loc: String) -> Dictionary:
	return {"location_id": loc, "craft_busy": false, "craft_id": "ship"}

func _ship(s: RefCounted) -> Dictionary:
	return Dictionary(Dictionary(s.get_supply_snapshot().inventory)["craft:ship"].items)

func _entry(s: RefCounted, loc: String, item: String) -> Dictionary:
	return Dictionary(Dictionary(Dictionary(s.get_supply_snapshot().get("market", {})).get(loc, {})).get(item, {}))

func _buy(s: RefCounted, loc: String, item: String, qty: int = 1) -> Dictionary:
	return s.apply_command(_cmd("buy", {"offer_id": "market:%s:%s" % [loc, item], "quantity": qty}), _ctx(loc))

func _sell(s: RefCounted, loc: String, item: String, qty: int = 1) -> Dictionary:
	return s.apply_command(_cmd("sell", {"item_id": item, "quantity": qty, "source_container_id": "craft:ship"}), _ctx(loc))

func _used(s: RefCounted) -> int:
	return INVENTORY.used(_ship(s))

## Ankaufspreis aus den Daten (0 = kauft nicht).
func _buy_price(loc: String, item: String) -> int:
	return int(Dictionary(Dictionary(_locs().get(loc, {})).get(item, {})).get("buy_price", 0))

# ---------- 1: Daten ----------

func _data_part() -> void:
	var locs: Dictionary = _locs()
	var ok_roles := true
	var label := ""
	var buy_price_seen := 0
	for place: String in PLACES:
		var sells: Array = []
		var buys: Array = []
		for item: String in GOODS:
			var e: Dictionary = Dictionary(Dictionary(locs.get(place, {})).get(item, {}))
			if e.has("sell_price"): sells.append(item)
			if e.has("buy_price"): buys.append(item)
		if sells != [SELLS[place]] or buys.size() != 2 or buys.has(SELLS[place]):
			ok_roles = false
			label = "%s sells=%s buys=%s" % [place, sells, buys]
		var sell_entry: Dictionary = Dictionary(Dictionary(locs.get(place, {})).get(SELLS[place], {}))
		if int(sell_entry.get("sell_price", 0)) != ORIGIN_PRICE or int(sell_entry.get("stock", 0)) != LIMIT:
			ok_roles = false
			label = "%s Ursprung %s" % [place, sell_entry]
		for item: String in buys:
			var b: Dictionary = Dictionary(Dictionary(locs.get(place, {})).get(item, {}))
			if int(b.get("buy_limit", 0)) != LIMIT or int(b.get("buy_price", 0)) < 32 or int(b.get("buy_price", 0)) % 2 != 0:
				ok_roles = false
				label = "%s Ankauf %s %s" % [place, item, b]
			buy_price_seen = int(b.get("buy_price", 0))
	check(ok_roles, "Daten: je Ort genau ein Verkaufsgut (20 Cr, Vorrat 12) und zwei Ankaufsgueter (Abnahme 12, Preis ab 32 in 2er-Schritten) %s" % label)
	var all_known := true
	for item: String in GOODS:
		if not INVENTORY.known(item): all_known = false
	check(all_known, "Daten: die drei Gueter sind dem Frachtvertrag bekannt")
	var prices := {}
	for place: String in PLACES:
		for item: String in GOODS:
			if _buy_price(place, item) > 0: prices[_buy_price(place, item)] = true
	check(prices.size() == 1 and buy_price_seen > 0, "Daten: ein einheitlicher Ankaufspreis an allen drei Orten (%s)" % [prices.keys()])

# ---------- 2: Kauf am Ursprung ----------

func _buy_part() -> void:
	var s: RefCounted = _sup()
	var c0: int = s.get_credits()
	var r: Dictionary = _buy(s, "muellers_farm", "heilkraeuter", 3)
	check(bool(r.get("ok", false)) and s.get_credits() == c0 - 3 * ORIGIN_PRICE and int(_ship(s).get("heilkraeuter", 0)) == 3, "Kauf: 3 Heilkraeuter in Muellers Farm buchen 60 Cr ab und liegen im Schiff (%s)" % r)
	check(int(_entry(s, "muellers_farm", "heilkraeuter").get("stock", -1)) == LIMIT - 3, "Kauf: der Vorrat sinkt auf 9")
	var ok_all := true
	for place: String in PLACES:
		var t: RefCounted = _sup()
		var before: int = t.get_credits()
		var rr: Dictionary = _buy(t, place, String(SELLS[place]), 1)
		if not bool(rr.get("ok", false)) or t.get_credits() != before - ORIGIN_PRICE or int(_ship(t).get(SELLS[place], 0)) != 1: ok_all = false
	check(ok_all, "Kauf: an jedem Ort kostet das eigene Gut 20 Cr je Einheit")

# ---------- 3: Verkauf an den zwei anderen Orten, eigenes Gut abgelehnt ----------

func _sell_part() -> void:
	var s: RefCounted = _sup()
	var pay_ok := true
	var own_rejected := true
	var label := ""
	for origin: String in PLACES:
		var good: String = SELLS[origin]
		for place: String in PLACES:
			var t: RefCounted = _sup()
			t.apply_command(_cmd("campaign_cargo", {"container_id": "craft:ship", "item_id": good, "amount": 2}), {"campaign_authorized": true})
			var before: int = t.get_credits()
			var r: Dictionary = _sell(t, place, good, 2)
			if place == origin:
				if bool(r.get("ok", true)) or t.get_credits() != before or int(_ship(t).get(good, 0)) != 2:
					own_rejected = false
					label = "%s kauft sein eigenes %s: %s" % [place, good, r]
			else:
				var price: int = _buy_price(place, good)
				if not bool(r.get("ok", false)) or price <= 0 or t.get_credits() != before + 2 * price or int(_ship(t).get(good, 0)) != 0:
					pay_ok = false
					label = "%s %s: %s" % [place, good, r]
	check(pay_ok, "Verkauf: die zwei anderen Orte kaufen jedes Gut zum Ankaufspreis (Gutschrift stimmt) %s" % label)
	check(own_rejected, "Verkauf: das eigene Gut wird am Ursprung nicht angekauft, nichts bewegt sich %s" % label)

# ---------- 4: Vorrat 12 und Abnahme 12 ----------

func _limit_part() -> void:
	var s: RefCounted = _sup()
	var r12: Dictionary = _buy(s, "muellers_farm", "heilkraeuter", 12)
	check(bool(r12.get("ok", false)), "Vorrat: 12 Heilkraeuter lassen sich kaufen (%s)" % r12)
	var c1: int = s.get_credits()
	var r13: Dictionary = _buy(s, "muellers_farm", "heilkraeuter", 1)
	check(not bool(r13.get("ok", true)) and String(r13.get("reason", "")) == "insufficient_stock" and s.get_credits() == c1 and int(_ship(s).get("heilkraeuter", 0)) == 12 and not String(r13.get("message", "")).is_empty(), "Vorrat: die 13. Einheit wird abgelehnt, mit Meldung (%s)" % r13.get("message", ""))
	# Abnahme: 12 Heilkraeuter nimmt Shady Lab ab, die 13. nicht (mehr Ware liegt per Fracht-Befehl im Schiff).
	var t: RefCounted = _sup()
	t.apply_command(_cmd("campaign_cargo", {"container_id": "craft:ship", "item_id": "heilkraeuter", "amount": 14}), {"campaign_authorized": true})
	var s12: Dictionary = _sell(t, "shady_lab", "heilkraeuter", 12)
	check(bool(s12.get("ok", false)) and int(_entry(t, "shady_lab", "heilkraeuter").get("demand", -1)) == 0, "Abnahme: Shady Lab nimmt 12 Heilkraeuter ab, danach nimmt es keine mehr an (%s)" % s12)
	var c2: int = t.get_credits()
	var s13: Dictionary = _sell(t, "shady_lab", "heilkraeuter", 1)
	var msg: String = String(s13.get("message", ""))
	check(not bool(s13.get("ok", true)) and t.get_credits() == c2 and int(_ship(t).get("heilkraeuter", 0)) == 2 and msg.length() > 12, "Abnahme: die 13. Einheit wird abgelehnt, nichts bewegt sich (%s)" % msg)
	# Die Abnahme gilt je Ort und Gut: Templanon nimmt dieselbe Ware noch ab.
	var other: Dictionary = _sell(t, "templanon", "heilkraeuter", 2)
	check(bool(other.get("ok", false)), "Abnahme: Templanon nimmt die restlichen zwei ab, die Grenze gilt je Ort (%s)" % other)
	# Ein Verkauf ueber der Restabnahme wird als Ganzes abgelehnt.
	var u: RefCounted = _sup()
	u.apply_command(_cmd("campaign_cargo", {"container_id": "craft:ship", "item_id": "duenger", "amount": 13}), {"campaign_authorized": true})
	var big: Dictionary = _sell(u, "templanon", "duenger", 13)
	check(not bool(big.get("ok", true)) and int(_ship(u).get("duenger", 0)) == 13, "Abnahme: 13 auf einmal werden abgelehnt (%s)" % big.get("reason", ""))

# ---------- 5: Auffuellen nach dem Takt der Warenboerse (Heimlandung -> replenish_market_stock) ----------

func _replenish_part() -> void:
	var s: RefCounted = _sup()
	_buy(s, "shady_lab", "duenger", 12)
	s.apply_command(_cmd("campaign_cargo", {"container_id": "craft:ship", "item_id": "heilkraeuter", "amount": 12}), {"campaign_authorized": true})
	_sell(s, "shady_lab", "heilkraeuter", 12)
	var empty_ok: bool = int(_entry(s, "shady_lab", "duenger").get("stock", -1)) == 0 and int(_entry(s, "shady_lab", "heilkraeuter").get("demand", -1)) == 0
	var added: int = s.replenish_market_stock()
	var full_ok: bool = int(_entry(s, "shady_lab", "duenger").get("stock", -1)) == LIMIT and int(_entry(s, "shady_lab", "heilkraeuter").get("demand", -1)) == LIMIT
	check(empty_ok and full_ok and added >= 12, "Auffuellen: nach replenish_market_stock (Heimlandung) stehen Vorrat und Abnahme wieder auf 12 (%d aufgefuellt)" % added)
	var r: Dictionary = _sell(s, "shady_lab", "heilkraeuter", 0)
	check(not bool(r.get("ok", true)), "Auffuellen: eine Menge 0 bleibt abgelehnt")

# ---------- 6: Speichern und Laden ----------

func _save_part() -> void:
	var s: RefCounted = _sup()
	_buy(s, "templanon", "aufputschmittel", 7)
	s.apply_command(_cmd("campaign_cargo", {"container_id": "craft:ship", "item_id": "duenger", "amount": 5}), {"campaign_authorized": true})
	_sell(s, "templanon", "duenger", 5)
	var saved: Dictionary = Dictionary(JSON.parse_string(JSON.stringify(s.export_state())))
	var loaded: RefCounted = _sup()
	var r: Dictionary = loaded.restore_state(saved)
	check(bool(r.get("ok", false)), "Laden: der Stand laedt (%s)" % r)
	check(int(_entry(loaded, "templanon", "aufputschmittel").get("stock", -1)) == 5, "Laden: der Vorrat (5 von 12) bleibt erhalten")
	check(int(_entry(loaded, "templanon", "duenger").get("demand", -1)) == 7, "Laden: der Abnahmestand (7 von 12 frei) bleibt erhalten")
	check(int(_ship(loaded).get("aufputschmittel", 0)) == 7, "Laden: die Fracht (7 Aufputschmittel) bleibt erhalten")
	check(loaded.get_credits() == s.get_credits(), "Laden: die Credits bleiben erhalten")
	var again: Dictionary = _sell(loaded, "templanon", "duenger", 8)
	check(not bool(again.get("ok", true)), "Laden: die Abnahmegrenze gilt nach dem Laden weiter")

# ---------- 7: volle Runde, Rechnung ----------

func _fuel_for_post(route_costs: Dictionary, place: String) -> float:
	return float(route_costs.get("homebase>" + place, 0.0)) + float(route_costs.get(place + ">homebase", 0.0))

func _round_part() -> void:
	var dat: Dictionary = _dat()
	var routes: Dictionary = Dictionary(dat.get("route_fuel_costs", {}))
	var fuel_price: float = float(dat.get("fuel_price_per_unit", 0.0))
	var s: RefCounted = _sup()
	var peak := 0
	var credits_after_first := 0
	# Zwei Umlaeufe; jeder Posten wird von der Heimatbasis aus angeflogen (zwischen den Posten gibt es keine Strecke), nach jeder Heimlandung ist aufgefuellt.
	for lap in range(2):
		if lap == 1: credits_after_first = s.get_credits()
		for place: String in PLACES:
			var carried: Dictionary = _ship(s).duplicate()
			for good: String in carried:
				if good in GOODS and _buy_price(place, good) > 0: _sell(s, place, good, int(carried[good]))
			_buy(s, place, String(SELLS[place]), LIMIT)
			peak = maxi(peak, _used(s))
			s.replenish_market_stock()
	var gross: int = s.get_credits() - credits_after_first
	var fuel_units := 0.0
	for place: String in PLACES: fuel_units += _fuel_for_post(routes, place)
	var fuel_cost: float = fuel_units * fuel_price
	var net: float = float(gross) - fuel_cost
	print("RUNDE: Einnahmen minus Einkauf = %d Cr, Treibstoff %.0f Einheiten = %.0f Cr, Gewinn nach Treibstoff = %.0f Cr (verlangt: mindestens %.0f), Laderaum Spitze %d von 48" % [gross, fuel_units, fuel_cost, net, 3.0 * fuel_cost, peak])
	check(fuel_units > 0.0 and gross > 0, "Runde: die Runde bringt Geld (%d Cr vor Treibstoff)" % gross)
	check(net >= 3.0 * fuel_cost, "Runde: Gewinn nach Treibstoff %.0f Cr ist mindestens das Dreifache der Treibstoffkosten %.0f Cr" % [net, fuel_cost])
	check(peak <= 48, "Runde: der Laderaum des Startschiffs (48) reicht (Spitze %d)" % peak)

# ---------- 8: Dienst am Ort ----------

func _scope_part() -> void:
	var ok_equipment := true
	var label := ""
	for place: String in PLACES:
		for offer: String in ["medictool_supply", "mining_tool_supply", "polisa_pistol", "polisa_ore", "polisa_ammo_light"]:
			var s: RefCounted = _sup()
			var c0: int = s.get_credits()
			var r: Dictionary = s.apply_command(_cmd("buy", {"offer_id": offer, "quantity": 1}), _ctx(place))
			if bool(r.get("ok", true)) or s.get_credits() != c0:
				ok_equipment = false
				label = "%s:%s -> %s" % [place, offer, r]
	check(ok_equipment, "Dienst: Ausruestung und Waffen sind an den drei Orten nicht zu kaufen %s" % label)
	var ok_fuel := true
	for place: String in PLACES:
		var s: RefCounted = _sup()
		var r: Dictionary = s.apply_command(_cmd("refuel", {"craft_id": "ship", "amount": 5.0}), _ctx(place))
		if bool(r.get("ok", true)): ok_fuel = false
	check(ok_fuel, "Dienst: Tanken ist an den drei Orten nicht moeglich")
	# Nur die drei Gueter: die frueheren Handelsgueter der Warenboerse (Nahrung ...) werden an den drei Orten weder verkauft noch gekauft.
	var ok_only := true
	for place: String in PLACES:
		for item: String in ["food", "medical_supplies", "bandage", "luxury_goods", "stim"]:
			var s: RefCounted = _sup()
			var buy: Dictionary = _buy(s, place, item, 1)
			s.apply_command(_cmd("campaign_cargo", {"container_id": "craft:ship", "item_id": item, "amount": 1}), {"campaign_authorized": true})
			var sell: Dictionary = _sell(s, place, item, 1)
			if bool(buy.get("ok", true)) or bool(sell.get("ok", true)): ok_only = false
	check(ok_only, "Dienst: an den drei Orten gibt es nur Heilkraeuter, Duenger und Aufputschmittel")
	var texts_ok := true
	var snap: Dictionary = Dictionary(_sup().get_supply_snapshot().get("post_goods", {}))
	for place: String in PLACES:
		var entry: Dictionary = Dictionary(snap.get(place, {}))
		if Array(entry.get("goods", [])).size() != 3 or String(entry.get("text", "")).length() < 20: texts_ok = false
	check(texts_ok, "Dienst: je Ort drei erlaubte Gueter und ein kurzer deutscher Satz in den Daten")

# ---------- 9: bestehende Daten unveraendert ----------

func _old_data_part() -> void:
	check(FileAccess.get_sha256(OFFER_PATH).to_upper() == OFFERS_SHA256, "Alt: trade_offers.json (Angebote, Polisa, Benit-Ankaeufe, Orte, Strecken) ist unveraendert")
	var locs: Dictionary = _locs()
	var same := true
	var label := ""
	for place: String in OLD_MARKET:
		for item: String in Dictionary(OLD_MARKET[place]):
			var have: Dictionary = Dictionary(Dictionary(locs.get(place, {})).get(item, {}))
			var want: Dictionary = Dictionary(OLD_MARKET[place][item])
			if have.size() != want.size():
				same = false
				label = "%s:%s" % [place, item]
			for key: String in want:
				if int(have.get(key, -1)) != int(want[key]):
					same = false
					label = "%s:%s" % [place, item]
	check(same, "Alt: alle bisherigen Zeilen der Warenboerse (Benit, fuenf Handelsgueter) stehen wortgleich da %s" % label)
	var extra_ok := true
	for place: String in OLD_MARKET:
		var allowed: Dictionary = Dictionary(OLD_MARKET[place]).duplicate()
		for item: String in Dictionary(locs.get(place, {})):
			if not allowed.has(item) and not (place in PLACES and item in GOODS): extra_ok = false
	check(extra_ok, "Alt: neu sind nur die drei Gueter an den drei Orten")
