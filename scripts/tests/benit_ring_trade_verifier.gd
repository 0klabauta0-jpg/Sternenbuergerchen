extends SceneTree
## Benit-Ring (25.11.2026): A-Benit -> B-Posten, B-Benit -> C-Posten, C-Benit -> A-Posten.
## A-Posten = satellite_crash, C-Posten = trade_outpost, B-Posten = relay_ridge. Zahlen stehen NUR in den Daten; hier stehen Regeln.
## Abschlusszeile: BENIT_RING_TRADE passed=%d failed=%d
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const OFFER_PATH := "res://data/singleplayer/trade_offers.json"
const MARKET_PATH := "res://data/singleplayer/commodity_market.json"
const BENITS := ["a_benit", "b_benit", "c_benit"]
## Ring: Posten -> das Benit, das er ANKAUFT.
const BUYS := {"satellite_crash": "c_benit", "trade_outpost": "b_benit", "relay_ridge": "a_benit"}
## Neues Verkaufs-Benit des B-Postens: Einkauf 8, Vorrat 12.
const B_POST := "relay_ridge"
const OWN_PRICE := 8
const OLD_BUY := {"satellite_crash": {"c_benit": 15}, "trade_outpost": {"b_benit": 15}, "polisa": {"a_benit": 15, "b_benit": 15, "c_benit": 15}}
const OLD_SELL := {"satellite_crash": {"a_benit": 10, "b_benit": 10}, "trade_outpost": {"a_benit": 10, "c_benit": 10}}
## Hash von trade_offers.json VOR der Aenderung (die Datei bleibt unangetastet).
const OFFERS_SHA256 := "14A57625D72C00030FC761EF485C495B7FC58F9003333FD3E7766EBC92DB594A"
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
	_ring_part()
	_trade_part()
	_limit_part()
	_old_part()
	print("BENIT_RING_TRADE passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)

func _dat() -> Dictionary:
	return Dictionary(JSON.parse_string(FileAccess.get_file_as_string(OFFER_PATH)))

func _locs() -> Dictionary:
	return Dictionary(Dictionary(JSON.parse_string(FileAccess.get_file_as_string(MARKET_PATH))).get("locations", {}))

func _cmd(op: String, payload: Dictionary) -> Dictionary:
	_seq += 1
	return {"contract_category": "singleplayer_supply", "operation": op, "payload": payload, "request_id": "br:%d" % _seq}

func _sup() -> RefCounted:
	var s: RefCounted = SUPPLY.new()
	var cfg: Dictionary = s.configure([], _dat())
	if not cfg.get("ok", false): print("FAIL: Versorgung nicht konfiguriert: ", cfg)
	s.register_craft("ship", 5.0)
	s.configure_inventory([], ["ship"])
	return s

func _ctx(loc: String) -> Dictionary:
	return {"location_id": loc, "craft_busy": false, "craft_id": "ship"}

func _give(s: RefCounted, item: String, amount: int) -> void:
	s.apply_command(_cmd("campaign_cargo", {"container_id": "craft:ship", "item_id": item, "amount": amount}), {"campaign_authorized": true})

func _ship(s: RefCounted) -> Dictionary:
	return Dictionary(Dictionary(s.get_supply_snapshot().inventory)["craft:ship"].items)

func _sell(s: RefCounted, loc: String, item: String, qty: int = 1) -> Dictionary:
	return s.apply_command(_cmd("sell", {"item_id": item, "quantity": qty, "source_container_id": "craft:ship"}), _ctx(loc))

func _buy(s: RefCounted, loc: String, item: String, qty: int = 1) -> Dictionary:
	return s.apply_command(_cmd("buy", {"offer_id": "market:%s:%s" % [loc, item], "quantity": qty}), _ctx(loc))

# ---------- 1: der Ring in den Daten ----------

func _ring_part() -> void:
	var locs: Dictionary = _locs()
	var ok := true
	var label := ""
	for post: String in BUYS:
		var buys: Array = []
		for item: String in BENITS:
			var e: Dictionary = Dictionary(Dictionary(locs.get(post, {})).get(item, {}))
			if e.has("buy_price"): buys.append(item)
		if buys != [BUYS[post]]:
			ok = false
			label = "%s kauft %s" % [post, buys]
	check(ok, "Ring: jeder der drei Posten kauft genau ein Benit (A-Posten C, C-Posten B, B-Posten A) %s" % label)
	var b_sell: Dictionary = Dictionary(Dictionary(locs.get(B_POST, {})).get("b_benit", {}))
	check(int(b_sell.get("sell_price", 0)) == OWN_PRICE and int(b_sell.get("stock", 0)) == 12, "Ring: der B-Posten verkauft B-Benit fuer 8 Cr, Vorrat 12")
	var no_own := true
	for post: String in BUYS:
		for item: String in BENITS:
			var e: Dictionary = Dictionary(Dictionary(locs.get(post, {})).get(item, {}))
			if e.has("buy_price") and e.has("sell_price"): no_own = false
	check(no_own, "Ring: kein Posten kauft ein Benit, das er selbst verkauft")
	check(int(Dictionary(Dictionary(locs.get(B_POST, {})).get("a_benit", {})).get("buy_price", 0)) == 15, "Ring: der B-Posten kauft A-Benit zum Preis der vorhandenen Ankaeufe (15)")

# ---------- 2: Handel ----------

func _trade_part() -> void:
	var s: RefCounted = _sup()
	var c0: int = s.get_credits()
	var r: Dictionary = _buy(s, B_POST, "b_benit", 5)
	check(bool(r.get("ok", false)) and s.get_credits() == c0 - 5 * OWN_PRICE and int(_ship(s).get("b_benit", 0)) == 5, "Handel: 5 B-Benit am B-Posten kosten 40 Cr und liegen im Schiff (%s)" % r)
	var own: Dictionary = _sell(s, B_POST, "b_benit", 1)
	check(not bool(own.get("ok", true)) and int(_ship(s).get("b_benit", 0)) == 5, "Handel: das eigene B-Benit nimmt der B-Posten nicht an")
	var ok_sell := true
	var label := ""
	for post: String in BUYS:
		for item: String in BENITS:
			var t: RefCounted = _sup()
			_give(t, item, 3)
			var before: int = t.get_credits()
			var rr: Dictionary = _sell(t, post, item, 3)
			var should: bool = String(BUYS[post]) == item
			if bool(rr.get("ok", false)) != should or (should and t.get_credits() != before + 3 * 15) or (not should and (t.get_credits() != before or int(_ship(t).get(item, 0)) != 3)):
				ok_sell = false
				label = "%s %s -> %s" % [post, item, rr]
	check(ok_sell, "Handel: jeder Posten nimmt nur sein Ring-Benit an (3 x 15 Cr), alles andere wird abgelehnt %s" % label)
	var poli: RefCounted = _sup()
	var poli_ok := true
	for item: String in BENITS:
		_give(poli, item, 1)
		if not bool(_sell(poli, "polisa", item, 1).get("ok", false)): poli_ok = false
	check(poli_ok, "Handel: Polisa kauft weiter alle drei")

# ---------- 3: Vorrat 12 ----------

func _limit_part() -> void:
	var s: RefCounted = _sup()
	check(bool(_buy(s, B_POST, "b_benit", 12).get("ok", false)), "Vorrat: 12 B-Benit am B-Posten lassen sich kaufen")
	var c: int = s.get_credits()
	var r: Dictionary = _buy(s, B_POST, "b_benit", 1)
	check(not bool(r.get("ok", true)) and s.get_credits() == c and not String(r.get("message", "")).is_empty(), "Vorrat: die 13. Einheit wird abgelehnt, mit Meldung")
	s.replenish_market_stock()
	check(bool(_buy(s, B_POST, "b_benit", 1).get("ok", false)), "Vorrat: nach der Heimlandung ist wieder aufgefuellt")
	var other: RefCounted = _sup()
	var wrong: Dictionary = _buy(other, "satellite_crash", "c_benit", 1)
	check(not bool(wrong.get("ok", true)), "Vorrat: ein Benit, das der Posten nicht verkauft, ist dort nicht zu kaufen")

# ---------- 4: Altes unveraendert ----------

func _old_part() -> void:
	check(FileAccess.get_sha256(OFFER_PATH).to_upper() == OFFERS_SHA256, "Alt: trade_offers.json (Ankaeufe, Dienstorte, Strecken) ist unveraendert")
	var locs: Dictionary = _locs()
	var same := true
	for post: String in OLD_BUY:
		for item: String in Dictionary(OLD_BUY[post]):
			var e: Dictionary = Dictionary(Dictionary(locs.get(post, {})).get(item, {}))
			if int(e.get("buy_price", -1)) != int(OLD_BUY[post][item]) or e.has("sell_price"): same = false
	for post: String in OLD_SELL:
		for item: String in Dictionary(OLD_SELL[post]):
			var e: Dictionary = Dictionary(Dictionary(locs.get(post, {})).get(item, {}))
			if int(e.get("sell_price", -1)) != int(OLD_SELL[post][item]) or int(e.get("stock", -1)) != 8: same = false
	check(same, "Alt: Ankaeufe (Absturzstelle C, Handelsposten B, Polisa alle drei) und Verkaeufe der zwei alten Posten unveraendert")
