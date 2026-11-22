extends "res://scripts/tests/campaign_casualty_recovery_flow_verifier.gd"
## Abschnitt K (22.11.2026): Schulden. Ins Minus nur durch Notdienste (Nottankdienst bis zum Kreditrahmen, Rettungsgebuehr der
## Notrettung ohne Rahmen), Zinsen in laufender Spielzeit, Spielstand mit Restzeit. Alle Zahlen stammen aus den Daten
## (trade_offers.json Block debt, casualty_rules.json total_loss); die Erwartungen unten nennen sie als Beispielrechnung.
## Reine Besitzer-Pruefungen (Versorgungsstand, Regeln) und ein Teil in der echten Meta-Szene (Takt, Meldung, Anzeige).
## Abschlusszeile: CAMPAIGN_DEBT passed=%d failed=%d

const SUPPLY: GDScript = preload("res://scripts/core/singleplayer_supply_state.gd")
const SERVICE: GDScript = preload("res://scripts/core/emergency_tanker_service.gd")
const RULES: GDScript = preload("res://scripts/core/campaign_casualty_rules.gd")
const CREDIT_TEXT: GDScript = preload("res://scripts/core/credit_text.gd")
const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const DATA_PATH: String = "res://data/singleplayer/trade_offers.json"
const RULES_PATH: String = "res://data/singleplayer/casualty_rules.json"

var _ship_calls := 0

func _run() -> void:
	var verdict: Dictionary = GUARD.verdict_from_environment()
	if not bool(verdict.get("ok", false)):
		print("CAMPAIGN_DEBT refused: needs a throwaway profile (SB_REVIEW2_USER_DIR), nothing written. Reason: %s" % str(verdict.get("reason", "")))
		quit(2)
		return
	_configure_entry()
	_data_block()
	_a_tanker_on_credit()
	_b_limit()
	_c_other_purchases()
	_d_rescue_rfee()
	_e_interest()
	_f_save_and_load()
	_g_income_repays()
	_h_texts()
	await _flow_part()
	print("CAMPAIGN_DEBT passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

# ---------- Hilfen ----------

func _dat() -> Dictionary:
	return Dictionary(JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH)))

## Versorgungsbesitzer mit einem Schiff "ship" (Tank 5 = naechste Etappe nicht gedeckt), Credits auf `credits` gestellt.
func _sup(credits: int = 500, fuel: float = 5.0) -> RefCounted:
	var supply: RefCounted = SUPPLY.new()
	var configured: Dictionary = supply.configure([], _dat())
	if not configured.get("ok", false): print("FAIL: Versorgungsbesitzer nicht konfiguriert: " + str(configured))
	supply.register_craft("ship", fuel)
	_setcr(supply, credits)
	return supply

## Nur abwaerts ueber die echten Wege (Rettungsgebuehr bucht voll, auch ins Minus).
func _setcr(supply: RefCounted, target: int) -> void:
	var now: int = supply.get_credits()
	if now > target: supply.charge_rescue_fee(now - target)
	elif now < target:
		# Aufwaerts nur ueber den echten Weg einer Einnahme (Auftragsbelohnung); nur fuer Faelle, die nicht gespeichert werden.
		supply.apply_command(_tcmd("apply_reward", {"completion_id": "k:up"}, "k:up"), {"completion_receipt": {"completion_id": "k:up", "runtime_verified": true, "job_id": "k:up", "reward": {"credits": target - now}}})

func _tctx(over: Dictionary = {}) -> Dictionary:
	var context := {"emergency_tanker_authorized": true, "craft_available": true, "at_service_point": false, "fuel_problem": true}
	context.merge(over, true)
	return context

func _tcmd(operation: String, payload: Dictionary, request_id: String) -> Dictionary:
	return {"contract_category": "singleplayer_supply", "operation": operation, "payload": payload, "request_id": request_id}

func _tord(supply: RefCounted, request_id: String) -> Dictionary:
	return supply.apply_command(_tcmd("emergency_tanker_order", {"craft_id": "ship"}, request_id), _tctx())

func _fulfill_ship(_offer: Dictionary, _request_id: String, _pad: String = "") -> Dictionary:
	_ship_calls += 1
	return {"ok": true}

# ---------- Datenblock ----------

func _data_block() -> void:
	var debt: Dictionary = Dictionary(_dat().get("debt", {}))
	_check(int(debt.get("debt_limit", -1)) == 1500 and is_equal_approx(float(debt.get("interest_period_seconds", -1)), 600.0) and is_equal_approx(float(debt.get("interest_rate", -1)), 0.05) and int(debt.get("interest_min", -1)) == 5 and String(debt.get("balance_status", "")) == "initial", "Daten: Block debt: Rahmen 1500, Periode 600 s, Satz 0,05, Mindestzins 5, balance_status initial")
	var rules: Dictionary = Dictionary(JSON.parse_string(FileAccess.get_file_as_string(RULES_PATH)))
	_check(int(Dictionary(rules.get("total_loss", {})).get("rescue_fee_minimum", -1)) == 400 and is_equal_approx(float(Dictionary(rules.get("total_loss", {})).get("rescue_fee_fraction", -1)), 0.25), "Daten: Rettungsgebuehr: Mindestgebuehr 400, Anteil 25 %")
	for bad: Dictionary in [{"debt_limit": -1}, {"interest_rate": 0}, {"interest_rate": 2}, {"interest_period_seconds": 0}, {"interest_min": 1.5}, {"balance_status": 3}]:
		var data: Dictionary = _dat()
		var block: Dictionary = Dictionary(data.debt).duplicate(true)
		block.merge(bad, true)
		data["debt"] = block
		_check(not bool(SUPPLY.new().configure([], data).get("ok", true)), "Daten: ungueltiger Block debt abgelehnt: " + str(bad))
	var without: Dictionary = _dat()
	without.erase("debt")
	var supply: RefCounted = SUPPLY.new()
	_check(bool(supply.configure([], without).get("ok", false)), "Daten: ein fehlender Block debt ist erlaubt (dann gibt es keine Schulden)")
	supply.register_craft("ship", 5.0)
	var rejected: Dictionary = supply.preview_emergency_tanker({"craft_id": "ship"}, _tctx())
	_check(String(rejected.get("reason", "")) == "insufficient_credits" or bool(rejected.get("ok", false)), "Daten: ohne Block bleibt es bei der Regel Preis <= Credits (bei 500 Cr bestellbar)")

# ---------- a) Nottankdienst auf Kredit ----------

func _a_tanker_on_credit() -> void:
	var supply: RefCounted = _sup(150)
	var revision: int = supply.get_revision()
	var offer: Dictionary = supply.preview_emergency_tanker({"craft_id": "ship"}, _tctx())
	_check(bool(offer.get("ok", false)) and int(offer.get("price", 0)) == 280 and bool(offer.get("on_credit", false)) and int(offer.get("credits_after", 0)) == -130, "a: Angebot bei 150 Cr: ok, Preis 280, auf Kredit, Kontostand danach -130 (%s)" % [offer])
	_check(supply.get_credits() == 150 and supply.get_revision() == revision, "a: das Angebot bucht nichts")
	var order: Dictionary = _tord(supply, "k:a1")
	_check(bool(order.get("ok", false)) and supply.get_credits() == -130 and supply.get_open_tanker_orders().has("k:a1"), "a: Bestellung angenommen, Credits danach -130 = 150 - Preis 280")
	var cancel_early: Dictionary = supply.apply_command(_tcmd("emergency_tanker_cancel", {"order_id": "k:a1", "reason": "player"}, "k:a1:cancel"), {"emergency_tanker_authorized": true, "emergency_tanker_state": "requested"})
	_check(bool(cancel_early.get("ok", false)) and int(cancel_early.get("refund", -1)) == 280 and supply.get_credits() == 150, "a: Storno vor der Abfahrt erstattet alles (280): zurueck bei 150, ueber null")
	var second: RefCounted = _sup(150)
	_tord(second, "k:a2")
	var cancel_late: Dictionary = second.apply_command(_tcmd("emergency_tanker_cancel", {"order_id": "k:a2", "reason": "player"}, "k:a2:cancel"), {"emergency_tanker_authorized": true, "emergency_tanker_state": "en_route"})
	_check(bool(cancel_late.get("ok", false)) and int(cancel_late.get("refund", -1)) == 180 and second.get_credits() == 50, "a: Storno unterwegs erstattet den Mengenpreis (180): -130 + 180 = 50, wieder ueber null")
	var third: RefCounted = _sup(150)
	_tord(third, "k:a3")
	var delivered: Dictionary = third.apply_command(_tcmd("emergency_tanker_deliver", {"order_id": "k:a3"}, "k:a3:deliver"), {"emergency_tanker_authorized": true})
	_check(bool(delivered.get("ok", false)) and int(delivered.get("refund", -1)) == 0 and third.get_credits() == -130 and is_equal_approx(third.get_fuel("ship"), 35.0), "a: volle Lieferung: keine Erstattung, Kontostand bleibt -130, Tank 35")
	var expired: RefCounted = _sup(150)
	_tord(expired, "k:a4")
	var fell: Dictionary = expired.apply_command(_tcmd("emergency_tanker_cancel", {"order_id": "k:a4", "reason": "expired"}, "k:a4:cancel"), {"emergency_tanker_authorized": true, "emergency_tanker_state": "refuelling"})
	_check(bool(fell.get("ok", false)) and int(fell.get("refund", -1)) == 280 and expired.get_credits() == 150, "a: Verfall erstattet voll (280) und fuehrt zurueck auf 150")

# ---------- b) Kreditrahmen ----------

func _b_limit() -> void:
	var edge: RefCounted = _sup(-1220)
	var ok_edge: Dictionary = _tord(edge, "k:b1")
	_check(bool(ok_edge.get("ok", false)) and edge.get_credits() == -1500, "b: -1220 - 280 = genau -1500 ist erlaubt")
	var over: RefCounted = _sup(-1221)
	var revision: int = over.get_revision()
	var rejected: Dictionary = _tord(over, "k:b2")
	_check(not bool(rejected.get("ok", true)) and String(rejected.get("reason", "")) == "debt_limit_reached" and over.get_credits() == -1221 and over.get_revision() == revision and over.get_open_tanker_orders().is_empty(), "b: -1221 - 280 = -1501 wird abgelehnt (debt_limit_reached), nichts gebucht, kein Auftrag")
	_check(String(rejected.get("message", "")) == "Kreditrahmen ausgeschöpft: Der Nottankdienst liefert nicht mehr.", "b: der Satz steht woertlich da: " + String(rejected.get("message", "")))
	var preview: Dictionary = over.preview_emergency_tanker({"craft_id": "ship"}, _tctx())
	_check(String(preview.get("reason", "")) == "debt_limit_reached", "b: schon das Angebot nennt den Grund")
	var deep: RefCounted = _sup(-1500)
	_check(String(_tord(deep, "k:b3").get("reason", "")) == "debt_limit_reached", "b: bei -1500 geht keine weitere Bestellung")

# ---------- c) Jeder andere Kauf bleibt "Preis <= Credits" ----------

func _c_other_purchases() -> void:
	for credits: int in [0, -200]:
		var supply: RefCounted = _sup(credits, 5.0)
		var revision: int = supply.get_revision()
		var refuel: Dictionary = supply.apply_command(_tcmd("refuel", {"craft_id": "ship", "amount": 10}, "k:c:refuel:%d" % credits), {"location_id": "homebase", "craft_busy": false})
		var ware: Dictionary = supply.apply_command(_tcmd("buy", {"offer_id": "medictool_supply", "quantity": 1}, "k:c:ware:%d" % credits), {"location_id": "trade_outpost", "craft_busy": false, "craft_id": "ship"})
		var gear: Dictionary = supply.apply_command(_tcmd("buy", {"offer_id": "polisa_pistol", "quantity": 1}, "k:c:gear:%d" % credits), {"location_id": "polisa", "craft_busy": false, "craft_id": "ship"})
		_ship_calls = 0
		var ship: Dictionary = supply.apply_command(_tcmd("station_buy_ship", {"offer_id": "polisa_ship_cutlass"}, "k:c:ship:%d" % credits), {"location_id": "polisa", "craft_busy": false, "station_service_verified": true, "station_ship_fulfillment": Callable(self, "_fulfill_ship")})
		for pair: Array in [["Treibstoff am Pad", refuel], ["Ware", ware], ["Ausruestung", gear], ["Schiff", ship]]:
			var result: Dictionary = pair[1]
			_check(not bool(result.get("ok", true)) and String(result.get("reason", "")) == "insufficient_credits", "c: %s bei %d Cr abgelehnt (insufficient_credits): %s" % [pair[0], credits, str(result.get("reason", result))])
		_check(supply.get_credits() == credits and supply.get_revision() == revision and _ship_calls == 0, "c: bei %d Cr bleibt alles unveraendert, die Schiffsuebergabe wurde nie gerufen" % credits)

# ---------- d) Rettungsgebuehr ----------

func _rfee(credits: int) -> int:
	var rules: Dictionary = Dictionary(JSON.parse_string(FileAccess.get_file_as_string(RULES_PATH)))
	return int(Dictionary(RULES.build_total_loss_penalty([{"unit_id": "u", "outcome": "unharmed"}], credits, rules)).get("rescue_fee", -1))

func _d_rescue_rfee() -> void:
	_check(_rfee(0) == 400 and _rfee(100) == 400 and _rfee(-200) == 400, "d: Gebuehr 400 bei Credits 0, 100 und -200 (Mindestgebuehr)")
	_check(_rfee(4000) == 1000 and _rfee(1600) == 400 and _rfee(1604) == 401, "d: max(25 %, 400): bei 4000 = 1000, bei 1600 = 400, bei 1604 = 401")
	var low: RefCounted = _sup(100)
	var booked: Dictionary = low.charge_rescue_fee(_rfee(100))
	_check(bool(booked.get("ok", false)) and low.get_credits() == -300, "d: die Gebuehr fuehrt ins Minus: 100 - 400 = -300 (voll gebucht)")
	var negative: RefCounted = _sup(-200)
	negative.charge_rescue_fee(_rfee(-200))
	_check(negative.get_credits() == -600, "d: bei -200 Cr: -200 - 400 = -600")
	var over: RefCounted = _sup(-1400)
	over.charge_rescue_fee(_rfee(-1400))
	_check(over.get_credits() == -1800 and over.get_credits() < -1500, "d: die Gebuehr fuehrt auch ueber den Kreditrahmen hinaus: -1400 - 400 = -1800")
	_check(not bool(_tord(over, "k:d:tank").get("ok", true)), "d: danach liefert der Nottankdienst nicht mehr")
	var rich: RefCounted = _sup(4000)
	rich.charge_rescue_fee(_rfee(4000))
	_check(rich.get_credits() == 3000, "d: bei 4000 Cr bleiben nach der Gebuehr 3000")
	_check(not bool(low.charge_rescue_fee(-5).get("ok", true)), "d: ein negativer Betrag wird abgelehnt")

# ---------- e) Zinsen ----------

func _e_interest() -> void:
	var s: RefCounted = _sup(-100)
	var none: Dictionary = s.advance_debt_clock(599.0)
	_check(Array(none.get("charges", [])).is_empty() and s.get_credits() == -100, "e: nach 599 s keine Buchung")
	var first: Dictionary = s.advance_debt_clock(1.0)
	_check(Array(first.get("charges", [])).size() == 1 and int(Dictionary(first.charges[0]).get("amount", -1)) == 5 and s.get_credits() == -105, "e: nach 600 s eine Buchung: -100 -> Zinsen 5 -> -105")
	var second: Dictionary = s.advance_debt_clock(600.0)
	_check(int(Dictionary(second.charges[0]).get("amount", -1)) == 6 and s.get_credits() == -111, "e: zweite Periode (Zins auf Zins): -105 -> ceil(5,25) = 6 -> -111")
	var third: Dictionary = s.advance_debt_clock(600.0)
	_check(int(Dictionary(third.charges[0]).get("amount", -1)) == 6 and s.get_credits() == -117, "e: dritte Periode: -111 -> ceil(5,55) = 6 -> -117")
	_check(_iof(-101) == 6 and _iof(-100) == 5 and _iof(-40) == 5 and _iof(-1) == 5 and _iof(-3000) == 150 and _iof(-1500) == 75, "e: Betrag bei -101 = 6, -100 = 5, -40 = 5 (Mindestzins), -1 = 5, -3000 = 150, -1500 = 75")
	var many: RefCounted = _sup(-100)
	var batch: Dictionary = many.advance_debt_clock(1800.0)
	_check(Array(batch.charges).size() == 3 and many.get_credits() == -100 - 5 - 6 - 6, "e: 1800 s auf einmal = drei Buchungen nacheinander, auch dabei Zins auf Zins (-117)")
	var limit: RefCounted = _sup(-1500)
	limit.advance_debt_clock(600.0)
	_check(limit.get_credits() == -1575, "e: Zinsen duerfen ueber den Kreditrahmen fuehren: -1500 - 75 = -1575")
	var plus: RefCounted = _sup(500)
	var idle: Dictionary = plus.advance_debt_clock(6000.0)
	_check(Array(idle.charges).is_empty() and plus.get_credits() == 500 and is_equal_approx(plus.get_debt_interest_remaining(), -1.0), "e: im Plus steht die Uhr (keine Zinsen, Restzeit -1)")
	var clock: RefCounted = _sup(-100)
	clock.advance_debt_clock(400.0)
	_check(is_equal_approx(clock.get_debt_interest_remaining(), 200.0), "e: nach 400 s im Minus bleiben 200 s bis zur Buchung")
	clock.apply_command(_tcmd("apply_reward", {"completion_id": "k:e:r"}, "k:e:reward"), {"completion_receipt": {"completion_id": "k:e:r", "runtime_verified": true, "job_id": "k:e", "reward": {"credits": 200}}})
	_check(clock.get_credits() == 100, "e: Einnahme 200 bringt -100 auf +100")
	clock.advance_debt_clock(10.0)
	_check(is_equal_approx(clock.get_debt_interest_remaining(), -1.0), "e: im Plus steht die Uhr wieder")
	clock.charge_rescue_fee(300)
	_check(clock.get_credits() == -200 and is_equal_approx(clock.get_debt_interest_remaining(), -1.0), "e: nach neuem Minus beginnt die Uhr von vorn (Restzeit erst mit dem naechsten Takt gesetzt)")
	clock.advance_debt_clock(100.0)
	_check(is_equal_approx(clock.get_debt_interest_remaining(), 500.0), "e: dann volle Periode minus 100 s = 500 s")
	var guard: RefCounted = _sup(-100)
	guard.advance_debt_clock(-5.0)
	guard.advance_debt_clock(NAN)
	guard.advance_debt_clock(599.0)
	_check(guard.get_credits() == -100, "e: negatives und ungueltiges Delta bucht nichts und verschiebt die Uhr nicht (danach 599 s ohne Buchung)")

func _iof(credits: int) -> int:
	return _sup(credits).debt_interest_for(credits)

# ---------- f) Spielstand ----------

func _rt(supply: RefCounted) -> Dictionary:
	return Dictionary(JSON.parse_string(JSON.stringify(supply.export_state())))

func _f_save_and_load() -> void:
	var s: RefCounted = _sup(-130)
	s.advance_debt_clock(250.0)
	var exported: Dictionary = _rt(s)
	_check(int(exported.get("credits", 0)) == -130 and is_equal_approx(float(exported.get("debt_interest_remaining", -1)), 350.0), "f: der Spielstand traegt -130 Credits und die Restzeit 350 s (halbe Periode)")
	var loaded: RefCounted = SUPPLY.new()
	loaded.configure([], _dat())
	var restored: Dictionary = loaded.restore_state(exported)
	_check(bool(restored.get("ok", false)) and loaded.get_credits() == -130 and is_equal_approx(loaded.get_debt_interest_remaining(), 350.0), "f: Laden gibt denselben Stand: -130 Credits, Restzeit 350 s (%s)" % [restored])
	loaded.advance_debt_clock(349.0)
	_check(loaded.get_credits() == -130, "f: nach dem Laden 349 s weiter: noch keine Buchung")
	loaded.advance_debt_clock(1.0)
	_check(loaded.get_credits() == -137, "f: nach 350 s Restzeit gebucht: -130 - ceil(6,5) = -137")
	var old: Dictionary = _rt(s)
	old.erase("debt_interest_remaining")
	var old_loaded: RefCounted = SUPPLY.new()
	old_loaded.configure([], _dat())
	_check(bool(old_loaded.restore_state(old).get("ok", false)) and old_loaded.get_credits() == -130 and is_equal_approx(old_loaded.get_debt_interest_remaining(), -1.0), "f: Stand mit negativen Credits ohne den Schluessel laedt (Restzeit = volle Periode beim naechsten Takt)")
	old_loaded.advance_debt_clock(599.0)
	_check(old_loaded.get_credits() == -130, "f: ohne Schluessel gilt die volle Periode: nach 599 s keine Buchung")
	var plain: RefCounted = _sup(500)
	var plain_state: Dictionary = _rt(plain)
	_check(not plain_state.has("debt_interest_remaining"), "f: im Plus schreibt der Spielstand den Schluessel nicht (alte Staende bleiben gleich)")
	var legacy: Dictionary = plain_state.duplicate(true)
	var definitions: Dictionary = Dictionary(legacy.definitions).duplicate(true)
	definitions.erase("debt")
	legacy["definitions"] = definitions
	var legacy_loaded: RefCounted = SUPPLY.new()
	legacy_loaded.configure([], _dat())
	_check(bool(legacy_loaded.restore_state(legacy).get("ok", false)) and legacy_loaded.get_credits() == 500, "f: ein alter Stand ohne den Block debt in den Definitionen laedt")
	var bad: Dictionary = _rt(s)
	bad["debt_interest_remaining"] = "bald"
	var bad_loaded: RefCounted = SUPPLY.new()
	bad_loaded.configure([], _dat())
	_check(not bool(bad_loaded.restore_state(bad).get("ok", true)), "f: eine ungueltige Restzeit wird abgelehnt (nie stillschweigend repariert)")
	var fraction: Dictionary = _rt(s)
	fraction["credits"] = -130.5
	_check(not bool(bad_loaded.restore_state(fraction).get("ok", true)), "f: Credits ohne ganze Zahl bleiben ungueltig")

# ---------- g) Einnahmen ----------

func _g_income_repays() -> void:
	var s: RefCounted = _sup(-300)
	s.advance_debt_clock(300.0)
	var reward: Dictionary = s.apply_command(_tcmd("apply_reward", {"completion_id": "k:g:r"}, "k:g:reward"), {"completion_receipt": {"completion_id": "k:g:r", "runtime_verified": true, "job_id": "k:g", "reward": {"credits": 250}}})
	_check(bool(reward.get("ok", false)) and s.get_credits() == -50, "g: Einnahme 250 tilgt: -300 -> -50, noch im Minus")
	_check(is_equal_approx(s.get_debt_interest_remaining(), 300.0), "g: noch im Minus laeuft die Uhr weiter (Restzeit 300 s)")
	s.apply_command(_tcmd("apply_reward", {"completion_id": "k:g:r2"}, "k:g:reward2"), {"completion_receipt": {"completion_id": "k:g:r2", "runtime_verified": true, "job_id": "k:g2", "reward": {"credits": 50}}})
	_check(s.get_credits() == 0, "g: Einnahme bis genau 0")
	var after: Dictionary = s.advance_debt_clock(6000.0)
	_check(Array(after.charges).is_empty() and s.get_credits() == 0, "g: ab >= 0 keine Zinsen mehr")

# ---------- h) Texte ----------

func _h_texts() -> void:
	_check(CREDIT_TEXT.format(150) == "150" and CREDIT_TEXT.format(0, " Cr") == "0 Cr" and CREDIT_TEXT.format(-105) == "-105 Schulden" and CREDIT_TEXT.format(-130, " Credits") == "-130 Credits Schulden", "h: Anzeige: 150 / 0 Cr / -105 Schulden / -130 Credits Schulden (eine Formatfunktion)")
	_check(CREDIT_TEXT.credit_offer_line(-130, 0.05, 600.0) == "Auf Kredit: Kontostand danach -130 Cr. Zinsen 5 % alle 10 Minuten.", "h: Zusatzzeile im Angebot woertlich: " + CREDIT_TEXT.credit_offer_line(-130, 0.05, 600.0))
	_check(CREDIT_TEXT.interest_message(5, -105) == "Zinsen: -5 Cr. Kontostand -105 Cr.", "h: Zinsbuchung woertlich: " + CREDIT_TEXT.interest_message(5, -105))
	var supply: RefCounted = _sup(150)
	var offer: Dictionary = supply.preview_emergency_tanker({"craft_id": "ship"}, _tctx())
	var line: String = CREDIT_TEXT.credit_offer_line(int(offer.credits_after), float(offer.interest_rate), float(offer.interest_period_seconds))
	_check(line == "Auf Kredit: Kontostand danach -130 Cr. Zinsen 5 % alle 10 Minuten.", "h: die Zahlen des Angebots (aus den Daten) ergeben dieselbe Zeile")
	var panel: Node = load("res://scripts/ui/emergency_tanker_panel.gd").new()
	panel.call("configure", Callable(), Callable(), 13)
	var offer_text: String = String(panel.call("_offer_text", offer.merged({"fuel_after": 35.0, "capacity": 100.0, "reach": []}), {}))
	_check(offer_text.contains("Auf Kredit: Kontostand danach -130 Cr. Zinsen 5 % alle 10 Minuten.") and offer_text.contains("Preis: Anfahrt 100 Cr + 30 × 6 Cr = 280 Cr"), "h: das Angebotsfeld zeigt die Zusatzzeile unter dem Preis")
	var rich_offer: Dictionary = _sup(500).preview_emergency_tanker({"craft_id": "ship"}, _tctx())
	_check(not String(panel.call("_offer_text", rich_offer.merged({"fuel_after": 35.0, "capacity": 100.0, "reach": []}), {})).contains("Auf Kredit"), "h: mit genug Credits keine Zusatzzeile")
	panel.free()

# ---------- Spielablauf (echte Meta-Szene, Kampagne) ----------

func _flow_part() -> void:
	if not await _open("campaign", "new"): return
	var start: int = int(_runtime.call("get_campaign_credits"))
	_check(start > 0, "Flow: Kampagne beginnt im Plus (%d)" % start)
	# Rettungsgebuehr ueber den echten Adapter: ins Minus, dann laeuft die Zinsuhr im Echtzeit-Takt des Ablaufs.
	_runtime.call("charge_campaign_rescue_fee", start + 100)
	_check(int(_runtime.call("get_campaign_credits")) == -100, "Flow: Rettungsgebuehr ueber den Adapter fuehrt auf -100")
	_flow.call("_tick_debt_interest", 1000.0)
	var after_big_frame: Dictionary = Dictionary(_runtime.call("advance_debt_interest", 0.0))
	_check(int(_runtime.call("get_campaign_credits")) == -100 and Array(after_big_frame.get("charges", [])).is_empty(), "Flow: ein Frame zaehlt hoechstens 2 s (Deckelung): 1000 s Delta bucht nichts")
	for _i in range(298):
		_flow.call("_tick_debt_interest", 2.0)
	_check(int(_runtime.call("get_campaign_credits")) == -100, "Flow: nach 598 s (299 Takte zu 2 s) keine Buchung")
	_flow.call("_tick_debt_interest", 2.0)
	_check(int(_runtime.call("get_campaign_credits")) == -105, "Flow: nach 600 s eine Zinsbuchung: -100 -> -105")
	_check(String(_flow.get_meta("campaign_save_feedback", "")) == "Zinsen: -5 Cr. Kontostand -105 Cr.", "Flow: die Rueckmeldungszeile meldet die Buchung: " + String(_flow.get_meta("campaign_save_feedback", "")))
	var checkpoint: Dictionary = Dictionary(_runtime.call("export_campaign_checkpoint"))
	var supply_state: Dictionary = Dictionary(checkpoint.get("supply", {}))
	_check(int(supply_state.get("credits", 0)) == -105 and is_equal_approx(float(supply_state.get("debt_interest_remaining", -1.0)), 600.0), "Flow: der Speicherpunkt des Adapters traegt -105 und die Restzeit (volle Periode 600 s nach der Buchung)")
	# Anzeige: das Versorgungsfeld zeigt das Minus mit "Schulden".
	var services: Control = _flow.get("_singleplayer_services")
	var label: Label = services.find_child("SupplyCredits", true, false) as Label if services != null else null
	if label != null:
		services.call("refresh")
		_check(label.text == "Kredite: -105 Schulden", "Flow: Versorgungsanzeige: " + label.text)
	else:
		_check(false, "Flow: Label SupplyCredits nicht gefunden")
	await _close()
