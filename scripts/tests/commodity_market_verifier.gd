extends SceneTree
## Handel H2 (23.11.2026): Benit-Warenboerse mit festen Preisen und Bestaenden aus data/singleplayer/commodity_market.json,
## ueber den echten Versorgungszustand. Die Zahlen stehen NUR in der Datendatei; hier stehen Regeln und Rechnungen.
## Abschlusszeile: COMMODITY_MARKET passed=%d failed=%d
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const OFFER_PATH := "res://data/singleplayer/trade_offers.json"
const MARKET_PATH := "res://data/singleplayer/commodity_market.json"
const BENIT := ["a_benit", "b_benit", "c_benit"]
## Handel 2a: die fuenf Handelsgueter, ausdruecklich benannt (nichts anderes ausser Benit ist zulaessig).
const TRADE_GOODS := ["food", "medical_supplies", "bandage", "luxury_goods", "stim"]
const PRESENTER = preload("res://scripts/meta/singleplayer_services_presenter.gd")
var _ui_supply: RefCounted
var _ui_location := "trade_outpost"
var _ui_far := false
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
	_price_part()
	_buy_part()
	_sell_part()
	_replay_part()
	_full_ship_part()
	_refill_part()
	_save_part()
	_old_state_part()
	_skirmish_part()
	await _ui_part()
	print("COMMODITY_MARKET passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)

# ---------- Hilfen ----------

func _dat() -> Dictionary:
	return Dictionary(JSON.parse_string(FileAccess.get_file_as_string(OFFER_PATH)))

func _market_file() -> Dictionary:
	return Dictionary(JSON.parse_string(FileAccess.get_file_as_string(MARKET_PATH)))

func _cmd(op: String, payload: Dictionary) -> Dictionary:
	_seq += 1
	return {"contract_category": "singleplayer_supply", "operation": op, "payload": payload, "request_id": "mk:%d" % _seq}

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

func _ctx(loc: String, lift: bool = false) -> Dictionary:
	var c := {"location_id": loc, "craft_busy": false, "craft_id": "ship"}
	if lift:
		c["cargo_lift_delivery"] = true
		c["cargo_lift_container_id"] = "station:%s:lift" % loc
	return c

func _offer(loc: String, item: String) -> String:
	return "market:%s:%s" % [loc, item]

func _buy(s: RefCounted, loc: String, item: String, qty: int = 1, ctx: Dictionary = {}, rid: String = "") -> Dictionary:
	var cmd: Dictionary = _cmd("buy", {"offer_id": _offer(loc, item), "quantity": qty})
	if not rid.is_empty(): cmd["request_id"] = rid
	return s.apply_command(cmd, _ctx(loc) if ctx.is_empty() else ctx)

func _sell(s: RefCounted, loc: String, item: String, qty: int = 1, source: String = "craft:ship") -> Dictionary:
	return s.apply_command(_cmd("sell", {"item_id": item, "quantity": qty, "source_container_id": source}), _ctx(loc))

func _load_ship(s: RefCounted, item: String, amount: int) -> void:
	var r: Dictionary = s.apply_command(_cmd("campaign_cargo", {"container_id": "craft:ship", "item_id": item, "amount": amount}), {"campaign_authorized": true})
	if not r.get("ok", false): print("FAIL: Fracht nicht gebucht: ", item, " ", r)

func _ship(s: RefCounted) -> Dictionary:
	return Dictionary(Dictionary(s.get_supply_snapshot().inventory)["craft:ship"].items)

func _market(s: RefCounted) -> Dictionary:
	return Dictionary(s.get_supply_snapshot().get("market", {}))

func _entry(s: RefCounted, loc: String, item: String) -> Dictionary:
	return Dictionary(Dictionary(_market(s).get(loc, {})).get(item, {}))

func _roundtrip(s: RefCounted) -> Dictionary:
	return Dictionary(JSON.parse_string(JSON.stringify(s.export_state())))

# ---------- Daten ----------

func _data_part() -> void:
	var f: Dictionary = _market_file()
	var locs: Dictionary = Dictionary(f.get("locations", {}))
	check(FileAccess.file_exists(MARKET_PATH) and locs.has("trade_outpost") and locs.has("satellite_crash") and locs.has("polisa"), "Daten: commodity_market.json hat die drei Orte")
	var rule_ok := true
	var shape_ok := true
	for loc: String in locs:
		for item: String in Dictionary(locs[loc]):
			var e: Dictionary = locs[loc][item]
			# Gueter-Dreieck (24.11.2026): an den drei kleinen Aussenposten kommen Heilkraeuter, Duenger, Aufputschmittel dazu (buy_limit = Abnahme je Heimlandung).
			if not item in BENIT and not item in TRADE_GOODS and not (item in ["heilkraeuter", "duenger", "aufputschmittel"] and loc in ["muellers_farm", "shady_lab", "templanon"]): shape_ok = false
			if loc == "polisa" and item in TRADE_GOODS: shape_ok = false # Polisa kauft die Handelsgueter in 2a nicht
			if e.has("sell_price") and e.has("buy_price"): rule_ok = false # kein Haendler kauft, was er selbst verkauft
			if e.has("sell_price") and (int(e.sell_price) < 1 or not e.has("stock") or int(e.stock) < 0): shape_ok = false
			if e.has("buy_price") and int(e.buy_price) < 1: shape_ok = false
	check(rule_ok, "Regel: in keinem Ort steht dieselbe Ware sowohl als Verkauf als auch als Ankauf")
	check(shape_ok, "Daten: nur Benit oder eines der fuenf Handelsgueter, Preise >= 1, Bestand nur beim Verkauf")
	var s: RefCounted = _sup()
	for loc: String in locs:
		var snap_ok := true
		for item: String in Dictionary(locs[loc]):
			var e: Dictionary = locs[loc][item]
			var got: Dictionary = _entry(s, loc, item)
			if int(got.get("sell_price", 0)) != int(e.get("sell_price", 0)) or int(got.get("stock", 0)) != int(e.get("stock", 0)) or int(got.get("buy_price", 0)) != int(e.get("buy_price", 0)): snap_ok = false
		check(snap_ok, "Daten: der Versorgungszustand zeigt die Datei fuer %s unveraendert (Preis, Bestand)" % loc)
	# Regel des Auftraggebers: verkauft wird, was am Ort abbaubar ist; gekauft, was es dort nicht gibt.
	var res: Dictionary = Dictionary(JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/location_resources.json")))
	var mined_ok := true
	for loc: String in ["trade_outpost", "satellite_crash"]:
		var mined: Array = []
		for site: Variant in Dictionary(res.get(loc, {})).get("sites", Dictionary(res.get(loc, {})).values()):
			if typeof(site) == TYPE_DICTIONARY and BENIT.has(String(site.get("item_id", ""))): mined.append(String(site.item_id))
		for item: String in BENIT:
			var e: Dictionary = Dictionary(locs[loc].get(item, {}))
			if mined.has(item) != e.has("sell_price"): mined_ok = false
	check(mined_ok, "Regel: Haendler verkauft genau das Benit, das am Ort abbaubar ist (Daten gegen location_resources.json)")

# ---------- Preise kommen aus der Datei ----------

func _price_part() -> void:
	var m: Dictionary = _market_file()
	var s: RefCounted = _sup()
	_load_ship(s, "b_benit", 2)
	var base: int = int(Dictionary(Dictionary(m.locations.trade_outpost).b_benit).buy_price)
	var c0: int = s.get_credits()
	check(bool(_sell(s, "trade_outpost", "b_benit").get("ok", false)) and s.get_credits() == c0 + base, "Preis: Verkauf am Handelsaussenposten bringt den Dateipreis (%d)" % base)
	# Testkopie der Daten mit anderen Zahlen: der Preis folgt, nichts ist fest im Code.
	var alt: Dictionary = m.duplicate(true)
	alt.locations.trade_outpost.b_benit.buy_price = 37
	alt.locations.trade_outpost.a_benit.sell_price = 21
	alt.locations.satellite_crash.c_benit.buy_price = 41
	var s2: RefCounted = _sup(alt)
	_load_ship(s2, "b_benit", 1)
	var c1: int = s2.get_credits()
	check(bool(_sell(s2, "trade_outpost", "b_benit").get("ok", false)) and s2.get_credits() == c1 + 37, "Preis: geaenderter Ankaufspreis (37) wirkt am Handelsaussenposten")
	_load_ship(s2, "c_benit", 2)
	var c2: int = s2.get_credits()
	check(bool(_sell(s2, "satellite_crash", "c_benit", 2).get("ok", false)) and s2.get_credits() == c2 + 82, "Preis: geaenderter Ankaufspreis (41) wirkt an der Absturzstelle, 2 Stueck = 82")
	var c3: int = s2.get_credits()
	check(bool(_buy(s2, "trade_outpost", "a_benit", 3).get("ok", false)) and s2.get_credits() == c3 - 63, "Preis: geaenderter Verkaufspreis (21) wirkt beim Kauf, 3 Stueck = 63")
	# Ort ohne Eintrag im Markt: kein Ankauf (kein Preis im Code).
	var none: Dictionary = {"version": 1, "locations": {"polisa": {"a_benit": {"buy_price": 15}}}}
	var s3: RefCounted = _sup(none)
	_load_ship(s3, "b_benit", 1)
	var r3: Dictionary = _sell(s3, "trade_outpost", "b_benit")
	check(not bool(r3.get("ok", true)) and s3.get_credits() == int(_dat().initial_credits), "Preis: ohne Dateieintrag kauft der Haendler nichts (kein fester Preis im Code)")

# ---------- Kaufen ----------

func _buy_part() -> void:
	var m: Dictionary = _market_file().locations
	for loc: String in ["trade_outpost", "satellite_crash"]:
		for item: String in BENIT:
			var e: Dictionary = Dictionary(m[loc].get(item, {}))
			if not e.has("sell_price"): continue
			var s: RefCounted = _sup()
			var c0: int = s.get_credits()
			var stock0: int = int(_entry(s, loc, item).stock)
			var r: Dictionary = _buy(s, loc, item, 2)
			check(bool(r.get("ok", false)), "Kauf: %s am Ort %s gelingt (%s)" % [item, loc, r.get("reason", "")])
			check(s.get_credits() == c0 - 2 * int(e.sell_price), "Kauf: %s/%s bucht 2 x %d Credits ab" % [loc, item, int(e.sell_price)])
			check(int(_ship(s).get(item, 0)) == 2, "Kauf: %s/%s liegt im Schiffslager" % [loc, item])
			check(int(_entry(s, loc, item).stock) == stock0 - 2, "Kauf: %s/%s senkt den Bestand um 2" % [loc, item])
	# Bestand 0: Ablehnung, nichts geaendert.
	var s2: RefCounted = _sup()
	var stock: int = int(_entry(s2, "satellite_crash", "a_benit").stock)
	check(bool(_buy(s2, "satellite_crash", "a_benit", stock).get("ok", false)) and int(_entry(s2, "satellite_crash", "a_benit").stock) == 0, "Bestand: alles kaufbar, danach Bestand 0")
	var before: String = JSON.stringify([s2.get_credits(), _ship(s2), _market(s2)], "", true)
	var r2: Dictionary = _buy(s2, "satellite_crash", "a_benit", 1)
	check(not bool(r2.get("ok", true)) and String(r2.get("reason", "")) == "insufficient_stock" and before == JSON.stringify([s2.get_credits(), _ship(s2), _market(s2)], "", true), "Bestand 0: Ablehnung ohne Abbuchung und ohne Ware")
	var r3: Dictionary = _buy(s2, "satellite_crash", "b_benit", stock + 1)
	check(not bool(r3.get("ok", true)), "Bestand: mehr als vorhanden wird abgelehnt")
	# Falscher Ort, Ware die der Haendler nicht verkauft, Arm, unbekannt, Menge.
	check(not bool(_buy(null if false else _sup(), "polisa", "a_benit", 1).get("ok", true)), "Kauf: Polisa verkauft kein Benit")
	check(not bool(_buy(_sup(), "trade_outpost", "b_benit", 1).get("ok", true)), "Kauf: der Handelsaussenposten verkauft kein B-Benit (er kauft es nur)")
	check(not bool(_buy(_sup(), "trade_outpost", "a_benit", 1, _ctx("satellite_crash")).get("ok", true)), "Kauf: Angebot gilt nur an seinem Ort")
	check(not bool(_buy(_sup(), "trade_outpost", "a_benit", 0).get("ok", true)) and not bool(_buy(_sup(), "trade_outpost", "a_benit", -1).get("ok", true)), "Kauf: Menge 0 oder negativ wird abgelehnt")
	var busy: Dictionary = _ctx("trade_outpost")
	busy["craft_busy"] = true
	check(not bool(_buy(_sup(), "trade_outpost", "a_benit", 1, busy).get("ok", true)), "Kauf: nicht in Bewegung")
	var poor: Dictionary = _dat()
	poor["initial_credits"] = 5
	var s5: RefCounted = SUPPLY.new()
	s5.configure([], poor)
	s5.register_craft("ship", 5.0)
	s5.configure_inventory([], ["ship"])
	var r5: Dictionary = _buy(s5, "trade_outpost", "a_benit", 1)
	check(not bool(r5.get("ok", true)) and s5.get_credits() == 5 and int(_entry(s5, "trade_outpost", "a_benit").stock) == 8, "Kauf: zu wenig Credits wird abgelehnt, nichts geaendert")
	# Frachtaufzug in der Kampagne: gekaufte Ware kommt in den Aufzug, nicht ins Schiff.
	var s6: RefCounted = _sup()
	var lift_ctx: Dictionary = _ctx("trade_outpost", true)
	check(bool(_buy(s6, "trade_outpost", "a_benit", 1, lift_ctx).get("ok", false)), "Aufzug: Kauf am Handelsaussenposten mit Frachtaufzug gelingt")
	var lift_items: Dictionary = Dictionary(Dictionary(s6.get_supply_snapshot().inventory)["station:trade_outpost:lift"].items)
	check(int(lift_items.get("a_benit", 0)) == 1 and int(_ship(s6).get("a_benit", 0)) == 0, "Aufzug: die Ware liegt im Frachtaufzug, nicht im Schiff")

# ---------- Verkaufen ----------

func _sell_part() -> void:
	var m: Dictionary = _market_file().locations
	for loc: String in m:
		for item: String in BENIT:
			var e: Dictionary = Dictionary(m[loc].get(item, {}))
			var s: RefCounted = _sup()
			_load_ship(s, item, 3)
			var c0: int = s.get_credits()
			var r: Dictionary = _sell(s, loc, item, 2)
			if e.has("buy_price"):
				check(bool(r.get("ok", false)) and s.get_credits() == c0 + 2 * int(e.buy_price) and int(_ship(s).get(item, 0)) == 1, "Verkauf: %s an %s: 2 x %d Credits, Ware raus" % [item, loc, int(e.buy_price)])
			else:
				check(not bool(r.get("ok", true)) and String(r.get("message", "")) != "" and s.get_credits() == c0 and int(_ship(s).get(item, 0)) == 3, "Verkauf: %s an %s abgelehnt mit Text, nichts geaendert (%s)" % [item, loc, r.get("message", "")])
	# Heimatbasis ohne Handel, nicht genug Ware, fremde Quelle.
	var s2: RefCounted = _sup()
	_load_ship(s2, "b_benit", 1)
	check(not bool(_sell(s2, "homebase", "b_benit").get("ok", true)), "Verkauf: an der Heimatbasis gibt es keinen Handel")
	check(not bool(_sell(s2, "trade_outpost", "b_benit", 2).get("ok", true)), "Verkauf: mehr als im Lager wird abgelehnt")
	check(not bool(_sell(s2, "trade_outpost", "b_benit", 1, "base:homebase").get("ok", true)), "Verkauf: nur aus Schiffslager oder Aufzug")
	# Der Verkauf aendert den Bestand des Haendlers nicht (der Haendler hat keine Obergrenze).
	var stock_before: String = JSON.stringify(_market(s2), "", true)
	_sell(s2, "trade_outpost", "b_benit", 1)
	check(stock_before == JSON.stringify(_market(s2), "", true), "Verkauf: aendert keinen Haendlerbestand")
	# Frachtaufzug als Quelle des Verkaufs.
	var s3: RefCounted = _sup()
	check(bool(_buy(s3, "trade_outpost", "a_benit", 2, _ctx("trade_outpost", true)).get("ok", false)), "Aufzug: Kauf von A-Benit in den Aufzug")
	var c0: int = s3.get_credits()
	check(bool(s3.apply_command(_cmd("sell", {"item_id": "a_benit", "quantity": 1, "source_container_id": "station:polisa:lift"}), {"location_id": "polisa", "craft_busy": false, "craft_id": "ship", "cargo_lift_container_id": "station:polisa:lift"}).get("ok", true)) == false, "Aufzug: aus dem Aufzug von Polisa laesst sich nichts verkaufen, was dort nicht liegt")
	check(s3.get_credits() == c0, "Aufzug: ohne Verkauf bleiben die Credits")

# ---------- Wiederholung und volles Lager ----------

func _replay_part() -> void:
	var s: RefCounted = _sup()
	var r1: Dictionary = _buy(s, "trade_outpost", "a_benit", 1, {}, "same-id")
	var after: String = JSON.stringify([s.get_credits(), _ship(s), _market(s)], "", true)
	var r2: Dictionary = _buy(s, "trade_outpost", "a_benit", 1, {}, "same-id")
	check(bool(r1.get("ok", false)) and bool(r2.get("replayed", false)), "Beleg: dieselbe Request-Id wird als Wiederholung erkannt")
	check(after == JSON.stringify([s.get_credits(), _ship(s), _market(s)], "", true), "Beleg: Wiederholung bucht nicht doppelt (Credits, Ware, Bestand)")
	check(not bool(_buy(s, "trade_outpost", "a_benit", 2, {}, "same-id").get("ok", true)), "Beleg: dieselbe Id mit anderer Menge wird abgelehnt")
	_load_ship(s, "b_benit", 1)
	var s1: Dictionary = s.apply_command({"contract_category": "singleplayer_supply", "operation": "sell", "payload": {"item_id": "b_benit", "quantity": 1, "source_container_id": "craft:ship"}, "request_id": "sell-id"}, _ctx("trade_outpost"))
	var c1: int = s.get_credits()
	var s2: Dictionary = s.apply_command({"contract_category": "singleplayer_supply", "operation": "sell", "payload": {"item_id": "b_benit", "quantity": 1, "source_container_id": "craft:ship"}, "request_id": "sell-id"}, _ctx("trade_outpost"))
	check(bool(s1.get("ok", false)) and bool(s2.get("replayed", false)) and s.get_credits() == c1, "Beleg: auch der Verkauf bucht mit derselben Id nur einmal")

func _full_ship_part() -> void:
	var s: RefCounted = _sup()
	var capacity: int = int(Dictionary(Dictionary(s.get_supply_snapshot().inventory)["craft:ship"]).capacity)
	_load_ship(s, "ore", capacity - 1)
	var c0: int = s.get_credits()
	var stock0: int = int(_entry(s, "trade_outpost", "a_benit").stock)
	check(bool(_buy(s, "trade_outpost", "a_benit", 1).get("ok", false)), "Lager: das letzte freie Stueck passt noch")
	var c1: int = s.get_credits()
	var stock1: int = int(_entry(s, "trade_outpost", "a_benit").stock)
	var r: Dictionary = _buy(s, "trade_outpost", "a_benit", 1)
	check(not bool(r.get("ok", true)) and String(r.get("reason", "")) == "container_full", "Lager: volles Schiffslager lehnt den Kauf ab (%s)" % r.get("reason", ""))
	check(s.get_credits() == c1 and int(_entry(s, "trade_outpost", "a_benit").stock) == stock1 and c0 > c1 and stock0 > stock1, "Lager: keine Abbuchung und kein Bestandsverlust bei der Ablehnung")

# ---------- Auffuellen ----------

func _refill_part() -> void:
	var s: RefCounted = _sup()
	check(s.has_method("replenish_market_stock"), "Auffuellen: der Versorgungszustand kennt replenish_market_stock")
	if not s.has_method("replenish_market_stock"): return
	_buy(s, "trade_outpost", "a_benit", 5)
	_buy(s, "trade_outpost", "c_benit", 8)
	_buy(s, "satellite_crash", "b_benit", 3)
	var rev: int = int(s.get_supply_snapshot().revision)
	var credits: int = s.get_credits()
	var inventory: String = JSON.stringify(_ship(s), "", true)
	var full: Dictionary = _market_file().locations
	s.replenish_market_stock()
	var ok := true
	for loc: String in full:
		for item: String in Dictionary(full[loc]):
			if Dictionary(full[loc][item]).has("stock") and int(_entry(s, loc, item).stock) != int(full[loc][item].stock): ok = false
	check(ok, "Auffuellen: nach der Heimlandung steht jeder Bestand wieder auf dem Wert der Datei")
	check(s.get_credits() == credits and inventory == JSON.stringify(_ship(s), "", true), "Auffuellen: Credits und Schiffslager bleiben unberuehrt")
	check(int(s.get_supply_snapshot().revision) > rev, "Auffuellen: Aenderung hebt die Revision")
	var rev2: int = int(s.get_supply_snapshot().revision)
	s.replenish_market_stock()
	check(int(s.get_supply_snapshot().revision) == rev2, "Auffuellen: bei vollem Bestand aendert sich nichts mehr")
	check(bool(_buy(s, "trade_outpost", "c_benit", 8).get("ok", false)), "Auffuellen: danach ist wieder alles kaufbar")
	# Andere Angebote bleiben, wie sie sind.
	var t: RefCounted = _sup()
	var rid: Dictionary = t.apply_command(_cmd("buy", {"offer_id": "medictool_supply", "quantity": 1}), _ctx("trade_outpost"))
	var med: int = int(t.get_supply_snapshot().stock_by_offer_id.medictool_supply)
	t.replenish_market_stock()
	check(bool(rid.get("ok", false)) and int(t.get_supply_snapshot().stock_by_offer_id.medictool_supply) == med, "Auffuellen: Bestand anderer Angebote (Sanitaetswerkzeug) bleibt unveraendert")

# ---------- Speichern und Laden ----------

func _save_part() -> void:
	var s: RefCounted = _sup()
	_buy(s, "trade_outpost", "a_benit", 3)
	_buy(s, "satellite_crash", "b_benit", 8)
	var saved: Dictionary = _roundtrip(s)
	check(saved.has("market_stock"), "Speichern: der Stand traegt die Marktbestaende (optionaler Schluessel market_stock)")
	var loaded: RefCounted = SUPPLY.new()
	loaded.configure([], _dat())
	loaded.register_craft("ship", 5.0)
	var r: Dictionary = loaded.restore_state(saved)
	check(bool(r.get("ok", false)), "Laden: Stand mit Marktbestand laedt (%s)" % r)
	check(int(_entry(loaded, "trade_outpost", "a_benit").stock) == 5 and int(_entry(loaded, "satellite_crash", "b_benit").stock) == 0 and int(_entry(loaded, "trade_outpost", "c_benit").stock) == 8, "Laden: die Bestaende sind erhalten (5, 0, 8)")
	check(int(Dictionary(Dictionary(loaded.get_supply_snapshot().inventory)["craft:ship"].items).get("a_benit", 0)) == 3, "Laden: gekaufte Ware liegt weiter im Schiff")
	# Nachbesserung W1: alte Staende muessen weiter laden - ein Bestand ueber dem (spaeter gesenkten) Datenwert wird gekappt, nicht abgelehnt.
	var cap: int = int(_market_file().locations.trade_outpost.a_benit.stock)
	var high: Dictionary = _roundtrip(s)
	high["market_stock"]["trade_outpost:a_benit"] = cap + 3
	var high_loaded: RefCounted = _loader()
	var high_r: Dictionary = high_loaded.restore_state(high)
	check(bool(high_r.get("ok", false)), "Laden: ein Bestand ueber dem Datenwert (Daten gesenkt) laedt (%s)" % high_r)
	check(bool(high_r.get("ok", false)) and int(_entry(high_loaded, "trade_outpost", "a_benit").stock) == cap, "Laden: der zu hohe Bestand wird auf den Datenwert gekappt")
	var neg: Dictionary = _roundtrip(s)
	neg["market_stock"]["trade_outpost:a_benit"] = -1
	var neg_loaded: RefCounted = _loader()
	var neg_r: Dictionary = neg_loaded.restore_state(neg)
	check(bool(neg_r.get("ok", false)) and int(_entry(neg_loaded, "trade_outpost", "a_benit").stock) == 0, "Laden: ein negativer Bestand wird auf 0 gesetzt, der Stand laedt (%s)" % neg_r)
	var gone: Dictionary = _roundtrip(s)
	gone["market_stock"]["trade_outpost:gestrichene_ware"] = 4
	gone["market_stock"]["verlassener_ort:a_benit"] = 2
	var gone_loaded: RefCounted = _loader()
	var gone_r: Dictionary = gone_loaded.restore_state(gone)
	check(bool(gone_r.get("ok", false)) and int(_entry(gone_loaded, "trade_outpost", "a_benit").stock) == 5, "Laden: Bestaende fuer unbekannte Waren/Orte werden still verworfen, der Rest bleibt (%s)" % gone_r)
	var junk: Dictionary = _roundtrip(s)
	junk["market_stock"]["trade_outpost:a_benit"] = "viel"
	check(not bool(SUPPLY.new().restore_state(junk).get("ok", true)), "Ladeschutz: ein Bestand, der keine Zahl ist, macht den Stand weiter unladbar")

func _loader() -> RefCounted:
	var l: RefCounted = SUPPLY.new()
	l.configure([], _dat())
	l.register_craft("ship", 5.0)
	return l

func _old_state_part() -> void:
	var s: RefCounted = _sup()
	var old: Dictionary = _roundtrip(s)
	old.erase("market_stock")
	var loaded: RefCounted = SUPPLY.new()
	loaded.configure([], _dat())
	loaded.register_craft("ship", 5.0)
	var r: Dictionary = loaded.restore_state(old)
	check(bool(r.get("ok", false)), "Alter Stand: ohne market_stock laedt (%s)" % r)
	var full: Dictionary = _market_file().locations
	var ok := true
	for loc: String in full:
		for item: String in Dictionary(full[loc]):
			if Dictionary(full[loc][item]).has("stock") and int(_entry(loaded, loc, item).stock) != int(full[loc][item].stock): ok = false
	check(ok, "Alter Stand: alle Marktbestaende sind voll")
	check(bool(_buy(loaded, "trade_outpost", "a_benit", 2).get("ok", false)), "Alter Stand: danach ist Benit kaufbar")

# ---------- Skirmish: Kauf an einem Ort, Verkauf am anderen ----------

func _skirmish_part() -> void:
	# Ohne Frachtaufzug (Skirmish): Kauf geht direkt ins Schiffslager; Verkauf am anderen Ort mit den Datenpreisen.
	var m: Dictionary = _market_file().locations
	var s: RefCounted = _sup()
	var c0: int = s.get_credits()
	var buy_price: int = int(m.trade_outpost.c_benit.sell_price)
	var sell_price: int = int(m.satellite_crash.c_benit.buy_price)
	check(bool(_buy(s, "trade_outpost", "c_benit", 4).get("ok", false)), "Skirmish: C-Benit am Handelsaussenposten gekauft")
	check(int(_ship(s).get("c_benit", 0)) == 4 and s.get_credits() == c0 - 4 * buy_price, "Skirmish: Ware direkt im Schiffslager, Credits um 4 x %d niedriger" % buy_price)
	check(bool(_sell(s, "satellite_crash", "c_benit", 4).get("ok", false)), "Skirmish: C-Benit an der Absturzstelle verkauft")
	check(s.get_credits() == c0 + 4 * (sell_price - buy_price) and int(_ship(s).get("c_benit", 0)) == 0, "Skirmish: Gewinn laut Datenpreisen (4 x %d)" % (sell_price - buy_price))
	check(not bool(_sell(s, "trade_outpost", "c_benit", 1).get("ok", true)), "Skirmish: am Kaufort laesst sich dieselbe Ware nicht zurueckverkaufen")

# ---------- Anzeige (D6): Haendlerfenster aus den Daten ----------

func _ui_snapshot() -> Dictionary:
	return {"mode": "campaign", "campaign": {"jobs": {}, "progress": {}}, "supply": _ui_supply.get_supply_snapshot(),
		"crafts": [{"craft_id": "ship", "location_id": _ui_location, "busy": false}],
		"location_view": {"location_id": _ui_location, "craft_id": "ship"},
		"service_contexts_by_craft_id": {"ship": {"location_id": _ui_location, "craft_busy": false, "services": [] if _ui_far else ["trade", "refuel"], "ground_service_verified": true}}}

func _ui_cmd(operation: String, payload: Dictionary) -> Dictionary:
	var data: Dictionary = payload.duplicate(true)
	var rid: String = String(data.get("request_id", ""))
	data.erase("request_id")
	return _ui_supply.apply_command({"contract_category": "singleplayer_supply", "operation": operation, "payload": data, "request_id": rid}, {"location_id": _ui_location, "craft_busy": false, "craft_id": "ship"})

func _btn(panel: Control, node_name: String) -> Button:
	return panel.find_child(node_name, true, false) as Button

func _shown(b: Button) -> bool:
	return b != null and b.is_visible_in_tree()

## Handel 2a, Nachbesserung 1: Verkaufsknoepfe der fuenf Handelsgueter erscheinen nur, wenn davon etwas im Schiff liegt (sonst verborgen).
func _goods_buttons(panel: Control, loc: String, m: Dictionary) -> void:
	_ui_supply = _sup()
	_ui_location = loc
	_ui_far = false
	panel.call("refresh")
	var names := ["SellBenit", "SellBenit2", "SellBenit3", "SellBenit4", "SellBenit5", "SellBenit6", "SellBenit7", "SellBenit8"]
	var shown_texts: Array = []
	for n: String in names:
		if _shown(_btn(panel, n)): shown_texts.append(_btn(panel, n).text)
	check(shown_texts.size() == 1 and String(shown_texts[0]).contains("Benit"), "Anzeige %s: ohne Handelsware ist nur der Benit-Verkaufsknopf sichtbar (%s)" % [loc, shown_texts])
	_load_ship(_ui_supply, "food", 1)
	panel.call("refresh")
	shown_texts.clear()
	for n: String in names:
		if _shown(_btn(panel, n)): shown_texts.append(_btn(panel, n).text)
	var food_price: int = int(m[loc].food.buy_price)
	check(shown_texts.size() == 2 and String(shown_texts[1]).contains("Nahrung") and String(shown_texts[1]).contains("%d Cr" % food_price), "Anzeige %s: mit Nahrung im Schiff kommt genau der Nahrung-Knopf dazu (%s)" % [loc, shown_texts])
	for item: String in ["medical_supplies", "bandage", "luxury_goods", "stim"]: _load_ship(_ui_supply, item, 1)
	panel.call("refresh")
	shown_texts.clear()
	for n: String in names:
		if _shown(_btn(panel, n)): shown_texts.append(_btn(panel, n).text)
	var all_named := true
	for word: String in ["Benit", "Nahrung", "Medizinische Güter", "Verbandsmaterial", "Genussmittel", "Stims"]:
		var found := false
		for t: Variant in shown_texts:
			if String(t).contains(word): found = true
		if not found: all_named = false
	check(shown_texts.size() == 6 and all_named, "Anzeige %s: mit allen fuenf Gueterarten im Schiff sind alle sechs Verkaufsknoepfe sichtbar (%s)" % [loc, shown_texts])

func _ui_part() -> void:
	var m: Dictionary = _market_file().locations
	_ui_supply = _sup()
	_ui_location = "trade_outpost"
	var panel: Control = PRESENTER.new()
	root.add_child(panel)
	panel.size = Vector2(340, 900)
	panel.call("configure", Callable(self, "_ui_snapshot"), Callable(self, "_ui_cmd"))
	for frame in range(4): await process_frame
	panel.call("refresh")
	var buy_a: Button = _btn(panel, "BuyMarket_a_benit")
	var buy_b: Button = _btn(panel, "BuyMarket_b_benit")
	var buy_c: Button = _btn(panel, "BuyMarket_c_benit")
	var sell1: Button = _btn(panel, "SellBenit")
	var sell2: Button = _btn(panel, "SellBenit2")
	check(buy_a != null and sell1 != null and sell2 != null, "Anzeige: Kauf- und Verkaufsknoepfe der Warenboerse sind gebaut")
	if buy_a == null or sell1 == null: return
	var pa: int = int(m.trade_outpost.a_benit.sell_price)
	var stock: int = int(m.trade_outpost.a_benit.stock)
	check(_shown(buy_a) and _shown(buy_c) and not _shown(buy_b), "Anzeige Handelsaussenposten: Kaufknopf fuer A- und C-Benit, keiner fuer B-Benit")
	check(buy_a.text.contains("%d Cr" % pa) and buy_a.text.contains("%d verfügbar" % stock), "Anzeige: Kaufknopf nennt Preis und Bestand aus der Datei (%s)" % buy_a.text)
	var pb: int = int(m.trade_outpost.b_benit.buy_price)
	check(_shown(sell1) and sell1.text.contains("B-Benit") and sell1.text.contains("%d Cr" % pb) and not _shown(sell2), "Anzeige Handelsaussenposten: ohne Handelsware im Schiff nur der Verkaufsknopf B-Benit mit Preis aus der Datei (%s)" % sell1.text)
	check(sell1.disabled, "Anzeige: Verkaufsknopf ohne B-Benit im Schiff ist gesperrt")
	var c0: int = _ui_supply.get_credits()
	buy_a.pressed.emit()
	check(int(_ship(_ui_supply).get("a_benit", 0)) == 1 and _ui_supply.get_credits() == c0 - pa, "Anzeige: Druck auf den Kaufknopf kauft ein Stueck (Ware im Schiff, Credits ab)")
	check(buy_a.text.contains("%d verfügbar" % (stock - 1)), "Anzeige: der Bestand im Knopf sinkt (%s)" % buy_a.text)
	_load_ship(_ui_supply, "b_benit", 1)
	panel.call("refresh")
	check(not sell1.disabled, "Anzeige: mit B-Benit im Schiff ist der Verkaufsknopf frei")
	var c1: int = _ui_supply.get_credits()
	sell1.pressed.emit()
	check(_ui_supply.get_credits() == c1 + pb and int(_ship(_ui_supply).get("b_benit", 0)) == 0, "Anzeige: Verkaufsknopf verkauft zum Datenpreis")
	# Ausverkauft: Knopf gesperrt, Grund steht als Text.
	var left: int = int(_entry(_ui_supply, "trade_outpost", "a_benit").stock)
	_buy(_ui_supply, "trade_outpost", "a_benit", left)
	panel.call("refresh")
	check(buy_a.disabled and buy_a.tooltip_text.contains("Ausverkauft"), "Anzeige: ausverkaufte Ware sperrt den Knopf mit Text (%s)" % buy_a.tooltip_text)
	_ui_supply.replenish_market_stock()
	panel.call("refresh")
	check(not buy_a.disabled and buy_a.text.contains("%d verfügbar" % stock), "Anzeige: nach dem Auffuellen ist der Knopf wieder frei")
	# Andere Zahlen in den Daten -> andere Anzeige (nichts im Text fest).
	var alt: Dictionary = _market_file()
	alt.locations.trade_outpost.a_benit.sell_price = 23
	alt.locations.trade_outpost.b_benit.buy_price = 31
	_ui_supply = _sup(alt)
	panel.call("refresh")
	check(buy_a.text.contains("23 Cr") and sell1.text.contains("31 Cr"), "Anzeige: geaenderte Datenpreise erscheinen im Fenster (%s | %s)" % [buy_a.text, sell1.text])
	# Absturzstelle: A- und B-Benit zu kaufen, C-Benit zu verkaufen.
	_ui_supply = _sup()
	_ui_location = "satellite_crash"
	panel.call("refresh")
	check(_shown(buy_a) and _shown(buy_b) and not _shown(buy_c), "Anzeige Absturzstelle: Kaufknopf fuer A- und B-Benit, keiner fuer C-Benit")
	check(_shown(sell1) and sell1.text.contains("C-Benit") and sell1.text.contains("%d Cr" % int(m.satellite_crash.c_benit.buy_price)) and not _shown(sell2), "Anzeige Absturzstelle: ohne Handelsware im Schiff nur der Verkaufsknopf C-Benit mit Datenpreis")
	_goods_buttons(panel, "satellite_crash", m)
	# Nachbesserung W2: Schiff an der Absturzstelle gelandet, aber zu weit vom Haendler (Dienst "trade" fehlt) -> gesperrt, Text sagt, was zu tun ist.
	_goods_buttons(panel, "trade_outpost", m)
	_ui_supply = _sup()
	_ui_location = "satellite_crash"
	_ui_far = true
	panel.call("refresh")
	check(buy_a.disabled and buy_a.tooltip_text.contains("in Sichtweite des Händlers landen, aber nicht direkt neben ihm") and not buy_a.tooltip_text.contains("256"), "Anzeige Absturzstelle, Schiff zu weit vom Haendler: Kaufknopf gesperrt, Text nennt die Abhilfe ohne Zahl (%s)" % buy_a.tooltip_text)
	_ui_far = false
	panel.call("refresh")
	check(not buy_a.disabled, "Anzeige Absturzstelle: mit Handelsdienst ist der Kaufknopf wieder frei")
	panel.queue_free()
	await process_frame
