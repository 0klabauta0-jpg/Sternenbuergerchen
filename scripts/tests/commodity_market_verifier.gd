extends SceneTree
## Handel H2 (23.11.2026): Benit-Warenboerse mit festen Preisen und Bestaenden aus data/singleplayer/commodity_market.json,
## ueber den echten Versorgungszustand. Die Zahlen stehen NUR in der Datendatei; hier stehen Regeln und Rechnungen.
## Abschlusszeile: COMMODITY_MARKET passed=%d failed=%d
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const OFFER_PATH := "res://data/singleplayer/trade_offers.json"
const MARKET_PATH := "res://data/singleplayer/commodity_market.json"
const BENIT := ["a_benit", "b_benit", "c_benit"]
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
			if not item in BENIT: shape_ok = false
			if e.has("sell_price") and e.has("buy_price"): rule_ok = false # kein Haendler kauft, was er selbst verkauft
			if e.has("sell_price") and (int(e.sell_price) < 1 or not e.has("stock") or int(e.stock) < 0): shape_ok = false
			if e.has("buy_price") and int(e.buy_price) < 1: shape_ok = false
	check(rule_ok, "Regel: in keinem Ort steht dieselbe Ware sowohl als Verkauf als auch als Ankauf")
	check(shape_ok, "Daten: nur Benit-Waren, Preise >= 1, Bestand nur beim Verkauf")
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
	var bad: Dictionary = _roundtrip(s)
	bad["market_stock"]["trade_outpost:a_benit"] = 99
	check(not bool(SUPPLY.new().restore_state(bad).get("ok", true)), "Ladeschutz: ein Bestand ueber dem Datenwert macht den Stand unladbar")
	var bad2: Dictionary = _roundtrip(s)
	bad2["market_stock"]["trade_outpost:a_benit"] = -1
	check(not bool(SUPPLY.new().restore_state(bad2).get("ok", true)), "Ladeschutz: ein negativer Bestand macht den Stand unladbar")

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
