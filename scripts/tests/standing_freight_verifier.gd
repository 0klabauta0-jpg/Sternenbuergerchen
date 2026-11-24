extends SceneTree
## Dauerauftraege B (24.11.2026): Fracht spielbar. Rechnerisch ueber den echten Versorgungszustand und den Presenter des Haendlerfensters:
## Kisten uebernehmen, abliefern, Lohn genau einmal, aufgeben, Sperrzeit, Speichern dazwischen, alter Stand, Knoepfe.
## Die Zahlen (Kisten, Lohn, Sperrzeit) stehen NUR in data/singleplayer/standing_orders.json; hier stehen Regeln und Rechnungen.
## Abschlusszeile: STANDING_FREIGHT passed=%d failed=%d
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const STATE = preload("res://scripts/core/standing_orders_state.gd")
const INV = preload("res://scripts/mission/inventory_transfer_contract.gd")
const PRESENTER = preload("res://scripts/meta/singleplayer_services_presenter.gd")
const OFFER_PATH := "res://data/singleplayer/trade_offers.json"
const ORDERS_PATH := "res://data/singleplayer/standing_orders.json"
const A := "freight:trade_outpost:c_benit"
const B := "freight:satellite_crash:b_benit"
const MINING := "mining:satellite_crash:a_benit"
const CRATE := "cargo_crate"
var passed := 0
var failed := 0
var _seq := 0
var _ui_supply: RefCounted
var _ui_location := "trade_outpost"
var _ui_far := false

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("PASS: " if ok else "FAIL: ", label)

func _run() -> void:
	_item_part()
	_accept_part()
	_deliver_part()
	_lock_part()
	_full_ship_part()
	_replay_part()
	_missing_part()
	_abandon_part()
	_save_part()
	_old_state_part()
	_number_part()
	_skirmish_part()
	_adapter_part()
	await _ui_part()
	print("STANDING_FREIGHT passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)

# ---------- Hilfen ----------

func _dat() -> Dictionary:
	return Dictionary(JSON.parse_string(FileAccess.get_file_as_string(OFFER_PATH)))

func _orders() -> Dictionary:
	return Dictionary(JSON.parse_string(FileAccess.get_file_as_string(ORDERS_PATH)))

func _order(id: String) -> Dictionary:
	for raw: Variant in Array(_orders().orders):
		if String(Dictionary(raw).id) == id: return Dictionary(raw)
	return {}

func _sup(standing: bool = true) -> RefCounted:
	var s: RefCounted = SUPPLY.new()
	var cfg: Dictionary = s.configure([], _dat())
	if not cfg.get("ok", false): print("FAIL: Versorgung nicht konfiguriert: ", cfg)
	s.register_craft("ship", 5.0)
	s.configure_inventory([], ["ship"])
	if standing:
		if not s.enable_standing_orders(): print("FAIL: Dauerauftraege nicht angelegt")
		s.set_standing_orders_names(load("res://scripts/mission/campaign_display_catalog.gd").LOCATION_NAMES, load("res://scripts/ui/components/personnel_inventory_panel.gd").LABELS)
	return s

func _loader() -> RefCounted:
	var l: RefCounted = SUPPLY.new()
	l.configure([], _dat())
	l.register_craft("ship", 5.0)
	l.enable_standing_orders()
	return l

func _ctx(loc: String, busy: bool = false) -> Dictionary:
	return {"location_id": loc, "craft_busy": busy, "craft_id": "ship"}

func _cmd(op: String, payload: Dictionary, rid: String = "") -> Dictionary:
	_seq += 1
	return {"contract_category": "singleplayer_supply", "operation": op, "payload": payload, "request_id": rid if not rid.is_empty() else "fr:%d" % _seq}

func _accept(s: RefCounted, id: String, loc: String, rid: String = "", busy: bool = false) -> Dictionary:
	return s.apply_command(_cmd("standing_accept", {"order_id": id, "craft_id": "ship", "service_location_id": loc}, rid), _ctx(loc, busy))

func _deliver(s: RefCounted, id: String, loc: String, rid: String = "") -> Dictionary:
	return s.apply_command(_cmd("standing_deliver", {"order_id": id, "craft_id": "ship", "service_location_id": loc}, rid), _ctx(loc))

func _abandon(s: RefCounted, id: String, loc: String, rid: String = "") -> Dictionary:
	return s.apply_command(_cmd("standing_abandon", {"order_id": id, "craft_id": "ship", "service_location_id": loc}, rid), _ctx(loc))

func _ship(s: RefCounted) -> Dictionary:
	return Dictionary(Dictionary(s.get_supply_snapshot().inventory)["craft:ship"].items)

func _crates(s: RefCounted) -> int:
	var total := 0
	var inventory: Dictionary = Dictionary(s.get_supply_snapshot().inventory)
	for container: Variant in inventory:
		total += int(Dictionary(Dictionary(inventory[container]).get("items", {})).get(CRATE, 0))
	return total

func _ship_crates(s: RefCounted) -> int:
	return int(_ship(s).get(CRATE, 0))

func _load(s: RefCounted, container: String, item: String, amount: int) -> Dictionary:
	return s.apply_command(_cmd("campaign_cargo", {"container_id": container, "item_id": item, "amount": amount}), {"campaign_authorized": true})

func _status(s: RefCounted, id: String) -> Dictionary:
	for entry: Variant in s.get_standing_orders_snapshot():
		if String(Dictionary(entry).id) == id: return Dictionary(entry)
	return {}

func _revision(s: RefCounted) -> int:
	return int(s.get_supply_snapshot().revision)

func _roundtrip(s: RefCounted) -> Dictionary:
	return Dictionary(JSON.parse_string(JSON.stringify(s.export_state())))

# ---------- Gegenstand ----------

func _item_part() -> void:
	check(INV.known(CRATE), "Gegenstand: cargo_crate ist ein bekannter Gegenstand")
	var s: RefCounted = _sup()
	var crates: int = int(_order(A).crates)
	check(bool(_accept(s, A, "trade_outpost").get("ok", false)) and INV.used(_ship(s)) == crates, "Gegenstand: %d Kisten belegen %d Plaetze im Schiff" % [crates, crates])
	var credits: int = s.get_credits()
	var sold: Dictionary = s.apply_command(_cmd("sell", {"item_id": CRATE, "quantity": 1, "source_container_id": "craft:ship"}), _ctx("satellite_crash"))
	check(not bool(sold.get("ok", true)) and s.get_credits() == credits and _ship_crates(s) == crates, "Gegenstand: eine Kiste laesst sich nicht verkaufen (Credits und Kisten unveraendert)")
	check(int(s.get_sellable_proceeds("satellite_crash", ["craft:ship"])) == 0, "Gegenstand: die Kisten zaehlen nicht zum verkaufbaren Erloes")

# ---------- Uebernehmen ----------

func _accept_part() -> void:
	var s: RefCounted = _sup()
	var crates: int = int(_order(A).crates)
	var c0: int = s.get_credits()
	var rev0: int = _revision(s)
	check(String(_status(s, A).get("status", "")) == "open", "Annahme: vorher ist der Auftrag offen")
	var r: Dictionary = _accept(s, A, "trade_outpost")
	check(bool(r.get("ok", false)) and int(r.get("number", 0)) == 1, "Annahme: beim Haendler am Startort klappt (%s)" % r.get("reason", ""))
	check(_ship_crates(s) == crates and s.get_credits() == c0, "Annahme: %d Kisten im Schiff, Credits unveraendert" % crates)
	check(String(_status(s, A).get("status", "")) == "active" and int(Dictionary(s.get_standing_orders().get_active("freight")).get("number", 0)) == 1, "Annahme: der Auftrag laeuft, Belegnummer 1")
	check(_revision(s) > rev0, "Annahme: die Revision steigt")
	check(int(r.get("quantity", 0)) == crates and String(r.get("order_id", "")) == A and String(r.get("receipt_id", "")) == "standing:%s:1" % A, "Annahme: der Beleg nennt Auftrag, Menge und Nummer (%s)" % r.get("receipt_id", ""))
	var rev1: int = _revision(s)
	var busy: Dictionary = _accept(s, B, "satellite_crash")
	check(not bool(busy.get("ok", true)) and String(busy.get("reason", "")) == "kind_busy", "Annahme: ein zweiter Frachtauftrag waehrend der erste laeuft wird abgelehnt (%s)" % busy.get("reason", ""))
	check(_ship_crates(s) == crates and _revision(s) == rev1 and s.get_standing_orders().get_counter() == 1, "Annahme: die Ablehnung bucht nichts (Kisten, Revision, Zaehler)")
	var f: RefCounted = _sup()
	var wrong: Dictionary = _accept(f, A, "satellite_crash")
	var offline: Dictionary = _accept(f, A, "trade_outpost", "", true)
	var unknown: Dictionary = _accept(f, "freight:nirgends", "trade_outpost")
	var mining: Dictionary = _accept(f, MINING, "satellite_crash")
	check(String(wrong.get("reason", "")) == "wrong_location" and not bool(wrong.get("ok", true)), "Annahme: am falschen Ort abgelehnt (%s)" % wrong.get("reason", ""))
	check(String(offline.get("reason", "")) == "trade_unavailable" and not bool(offline.get("ok", true)), "Annahme: ohne gelandetes Schiff (busy) abgelehnt (%s)" % offline.get("reason", ""))
	check(not bool(unknown.get("ok", true)) and not bool(mining.get("ok", true)), "Annahme: unbekannter Auftrag und Mining-Auftrag werden abgelehnt (%s / %s)" % [unknown.get("reason", ""), mining.get("reason", "")])
	check(_crates(f) == 0 and f.get_standing_orders().get_counter() == 0 and String(_status(f, A).get("status", "")) == "open", "Annahme: nach allen Ablehnungen ist nichts gebucht und der Auftrag noch offen")

# ---------- Abliefern ----------

func _deliver_part() -> void:
	var s: RefCounted = _sup()
	var pay: int = int(_order(A).pay)
	var crates: int = int(_order(A).crates)
	var lock: int = int(_orders().lock_seconds)
	_accept(s, A, "trade_outpost")
	var c0: int = s.get_credits()
	var wrong: Dictionary = _deliver(s, A, "trade_outpost")
	var offline: Dictionary = s.apply_command(_cmd("standing_deliver", {"order_id": A}), _ctx("satellite_crash", true))
	var idle: Dictionary = _deliver(s, B, "trade_outpost")
	check(String(wrong.get("reason", "")) == "wrong_location" and String(offline.get("reason", "")) == "trade_unavailable" and String(idle.get("reason", "")) == "not_active", "Abgabe: falscher Ort, kein Handel, nicht laufender Auftrag werden abgelehnt (%s/%s/%s)" % [wrong.get("reason", ""), offline.get("reason", ""), idle.get("reason", "")])
	check(s.get_credits() == c0 and _ship_crates(s) == crates and String(_status(s, A).get("status", "")) == "active", "Abgabe: die Ablehnungen aendern nichts")
	var r: Dictionary = _deliver(s, A, "satellite_crash", "deliver-1")
	check(bool(r.get("ok", false)) and int(r.get("pay", -1)) == pay and String(r.get("outcome", "")) == "delivered" and int(r.get("number", 0)) == 1, "Abgabe: beim Haendler am Zielort klappt, Beleg 'delivered' mit Lohn und Nummer (%s)" % r.get("reason", ""))
	check(s.get_credits() == c0 + pay, "Abgabe: der Lohn (%d) ist genau einmal gebucht" % pay)
	check(_crates(s) == 0 and s.get_standing_orders().get_active("freight").is_empty(), "Abgabe: keine Kiste mehr, der Auftrag ist beendet")
	check(String(_status(s, A).get("status", "")) == "locked" and int(_status(s, A).get("lock_remaining_seconds", 0)) == lock, "Abgabe: die Sperrzeit (%d s) beginnt" % lock)
	var again: Dictionary = _deliver(s, A, "satellite_crash")
	var replay: Dictionary = _deliver(s, A, "satellite_crash", "deliver-1")
	check(not bool(again.get("ok", true)) and s.get_credits() == c0 + pay, "Abgabe: ein zweiter Klick mit neuer Kennung zahlt nicht noch einmal")
	check(bool(replay.get("replayed", false)) and s.get_credits() == c0 + pay, "Abgabe: dieselbe Kennung zweimal ist eine Wiederholung und zahlt nicht doppelt")

# ---------- Sperrzeit je Auftrag ----------

func _lock_part() -> void:
	var s: RefCounted = _sup()
	var lock: int = int(_orders().lock_seconds)
	_accept(s, A, "trade_outpost")
	_deliver(s, A, "satellite_crash")
	var again: Dictionary = _accept(s, A, "trade_outpost")
	check(not bool(again.get("ok", true)) and String(again.get("reason", "")) == "locked" and _crates(s) == 0, "Sperre: derselbe Auftrag ist gleich nach der Abgabe gesperrt (%s)" % again.get("reason", ""))
	s.advance_standing_clock(100.0)
	var other: Dictionary = _accept(s, B, "satellite_crash")
	check(bool(other.get("ok", false)) and int(other.get("number", 0)) == 2, "Sperre: der andere Auftrag (B-Benit) ist trotz gesperrtem A-Benit frei, Belegnummer 2")
	check(bool(_deliver(s, B, "trade_outpost").get("ok", false)), "Sperre: auch der andere Auftrag laesst sich abliefern")
	s.advance_standing_clock(float(lock) - 101.0)
	check(String(_status(s, A).get("status", "")) == "locked" and int(_status(s, A).get("lock_remaining_seconds", 0)) == 1, "Sperre: eine Sekunde vor Ende noch gesperrt")
	s.advance_standing_clock(1.0)
	check(bool(_accept(s, A, "trade_outpost").get("ok", false)), "Sperre: nach genau %d s ist A-Benit wieder annehmbar" % lock)
	check(String(_status(s, B).get("status", "")) == "locked" and int(_status(s, B).get("lock_remaining_seconds", 0)) == 100, "Sperre: B-Benit hat seine eigene Restzeit (100 s)")

# ---------- Schiff voll ----------

func _full_ship_part() -> void:
	var s: RefCounted = _sup()
	var crates: int = int(_order(A).crates)
	var capacity: int = int(Dictionary(Dictionary(s.get_supply_snapshot().inventory)["craft:ship"]).capacity)
	_load(s, "craft:ship", "ore", capacity - crates + 1)
	var rev: int = _revision(s)
	var r: Dictionary = _accept(s, A, "trade_outpost")
	check(not bool(r.get("ok", true)) and String(r.get("reason", "")) == "container_full", "Schiff voll: ein Platz zu wenig lehnt die Annahme ab (%s)" % r.get("reason", ""))
	check(_crates(s) == 0 and _revision(s) == rev and s.get_standing_orders().get_counter() == 0 and String(_status(s, A).get("status", "")) == "open", "Schiff voll: nichts gebucht, Auftrag bleibt offen")
	_load(s, "craft:ship", "ore", -1)
	check(bool(_accept(s, A, "trade_outpost").get("ok", false)) and _ship_crates(s) == crates, "Schiff voll: mit genau %d freien Plaetzen klappt die Annahme" % crates)

# ---------- Wiederholung ----------

func _replay_part() -> void:
	var s: RefCounted = _sup()
	var crates: int = int(_order(A).crates)
	var r1: Dictionary = _accept(s, A, "trade_outpost", "acc-1")
	var rev: int = _revision(s)
	var r2: Dictionary = _accept(s, A, "trade_outpost", "acc-1")
	check(bool(r1.get("ok", false)) and bool(r2.get("replayed", false)), "Wiederholung: dieselbe Kennung bei der Annahme wird erkannt")
	check(_ship_crates(s) == crates and s.get_standing_orders().get_counter() == 1 and _revision(s) == rev, "Wiederholung: keine zweite Ladung, Zaehler und Revision unveraendert")

# ---------- Kiste fehlt ----------

func _missing_part() -> void:
	var s: RefCounted = _sup()
	var crates: int = int(_order(A).crates)
	_accept(s, A, "trade_outpost")
	_load(s, "craft:ship", CRATE, -1)
	var c0: int = s.get_credits()
	var r: Dictionary = _deliver(s, A, "satellite_crash")
	check(not bool(r.get("ok", true)) and String(r.get("reason", "")) == "cargo_missing" and String(r.get("message", "")) == "Fracht unvollständig – nur Aufgeben möglich.", "Kiste fehlt: keine Abgabe, Text 'Fracht unvollständig – nur Aufgeben möglich.' (%s)" % r.get("message", ""))
	check(s.get_credits() == c0 and _ship_crates(s) == crates - 1 and String(_status(s, A).get("status", "")) == "active" and String(_status(s, A).get("status", "")) != "locked", "Kiste fehlt: kein Lohn, der Auftrag laeuft weiter, keine Sperre")
	_load(s, "craft:ship", CRATE, 1)
	check(bool(_deliver(s, A, "satellite_crash").get("ok", false)) and s.get_credits() == c0 + int(_order(A).pay), "Kiste fehlt: nach dem Zurueckladen klappt die Abgabe")
	var t: RefCounted = _sup()
	_accept(t, A, "trade_outpost")
	_load(t, "craft:ship", CRATE, -crates)
	_load(t, "base:homebase", CRATE, crates)
	var c1: int = t.get_credits()
	check(not bool(_deliver(t, A, "satellite_crash").get("ok", true)) and t.get_credits() == c1 and _crates(t) == crates, "Kiste fehlt: Kisten im Basislager statt im Schiff bringen keinen Lohn")

# ---------- Aufgeben ----------

func _abandon_part() -> void:
	var s: RefCounted = _sup()
	var lock: int = int(_orders().lock_seconds)
	_accept(s, A, "trade_outpost")
	_load(s, "base:homebase", CRATE, 1)
	_load(s, "station:trade_outpost:lift", CRATE, 1)
	var c0: int = s.get_credits()
	var r: Dictionary = _abandon(s, A, "trade_outpost")
	check(bool(r.get("ok", false)) and int(r.get("pay", -1)) == 0 and String(r.get("outcome", "")) == "abandoned" and int(r.get("number", 0)) == 1, "Aufgeben: klappt, Beleg 'abandoned' ohne Lohn mit der Nummer des Auftrags (%s)" % r.get("reason", ""))
	check(s.get_credits() == c0 and _crates(s) == 0, "Aufgeben: kein Lohn, alle Kisten aus allen Behaeltern entfernt (Schiff, Basislager, Frachtaufzug)")
	check(String(_status(s, A).get("status", "")) == "locked" and int(_status(s, A).get("lock_remaining_seconds", 0)) == lock and s.get_standing_orders().get_active("freight").is_empty(), "Aufgeben: die Sperrzeit beginnt, der Auftrag ist beendet")
	var rev: int = _revision(s)
	var again: Dictionary = _abandon(s, A, "trade_outpost")
	check(not bool(again.get("ok", true)) and String(again.get("reason", "")) == "not_active" and _revision(s) == rev and s.get_credits() == c0, "Aufgeben: ein zweites Mal geht nicht und aendert nichts")
	var f: RefCounted = _sup()
	check(not bool(_abandon(f, A, "trade_outpost").get("ok", true)), "Aufgeben: ohne laufenden Auftrag abgelehnt")
	_accept(f, A, "trade_outpost")
	var other: Dictionary = _abandon(f, B, "trade_outpost")
	check(not bool(other.get("ok", true)) and _ship_crates(f) == int(_order(A).crates), "Aufgeben: ein anderer als der laufende Auftrag wird abgelehnt, die Kisten bleiben")
	check(bool(_abandon(f, A, "polisa").get("ok", false)), "Aufgeben: geht auch unterwegs, nicht nur bei den Haendlern")

# ---------- Speichern zwischen Uebernehmen und Abliefern ----------

func _save_part() -> void:
	var s: RefCounted = _sup()
	var crates: int = int(_order(A).crates)
	var pay: int = int(_order(A).pay)
	var lock: int = int(_orders().lock_seconds)
	_accept(s, A, "trade_outpost", "sv-1")
	s.advance_standing_clock(50.0)
	var saved: Dictionary = _roundtrip(s)
	var l: RefCounted = _loader()
	var r: Dictionary = l.restore_state(saved)
	check(bool(r.get("ok", false)), "Speichern: Stand mit laufendem Frachtauftrag laedt (%s)" % r)
	check(String(_status(l, A).get("status", "")) == "active" and int(Dictionary(l.get_standing_orders().get_active("freight")).get("number", 0)) == 1 and _crates(l) == crates, "Laden: der Auftrag laeuft weiter, Nummer 1, die Kisten liegen im Schiff")
	var rep: Dictionary = _accept(l, A, "trade_outpost", "sv-1")
	check(bool(rep.get("replayed", false)) and _crates(l) == crates, "Laden: die alte Annahme-Kennung ist weiter eine Wiederholung (keine zweite Ladung)")
	var c0: int = l.get_credits()
	check(bool(_deliver(l, A, "satellite_crash").get("ok", false)) and l.get_credits() == c0 + pay and _crates(l) == 0, "Laden: Abgabe nach dem Laden zahlt den Lohn einmal")
	var l2: RefCounted = _loader()
	check(bool(l2.restore_state(_roundtrip(l)).get("ok", false)) and String(_status(l2, A).get("status", "")) == "locked" and int(_status(l2, A).get("lock_remaining_seconds", 0)) == lock, "Laden: die Sperrzeit (%d s) ueberlebt Speichern und Laden" % lock)
	l2.advance_standing_clock(100.0)
	check(int(_status(l2, A).get("lock_remaining_seconds", 0)) == lock - 100, "Laden: die Sperre laeuft nach dem Laden weiter")

func _old_state_part() -> void:
	var s: RefCounted = _sup()
	var old: Dictionary = _roundtrip(s)
	for key: String in ["standing_clock", "standing_locks", "standing_active", "standing_counter"]: old.erase(key)
	var l: RefCounted = _loader()
	var r: Dictionary = l.restore_state(old)
	check(bool(r.get("ok", false)) and String(_status(l, A).get("status", "")) == "open", "Alter Stand: ohne Dauerauftrags-Schluessel laedt, Auftrag offen (%s)" % r)
	check(bool(_accept(l, A, "trade_outpost").get("ok", false)) and _ship_crates(l) == int(_order(A).crates), "Alter Stand: danach laesst sich Fracht uebernehmen")

# ---------- N1: laufender Eintrag nur mit id ----------

func _number_part() -> void:
	var s: RefCounted = _sup()
	var saved: Dictionary = _roundtrip(s)
	saved["standing_active"] = {"freight": {"id": A}}
	saved.erase("standing_counter")
	var l: RefCounted = _loader()
	var r: Dictionary = l.restore_state(saved)
	check(bool(r.get("ok", false)), "N1: laufender Eintrag nur mit id und ohne Zaehler laedt (%s)" % r)
	check(int(Dictionary(l.get_standing_orders().get_active("freight")).get("number", 0)) == 1 and l.get_standing_orders().get_counter() >= 1, "N1: Nummer 1, Zaehler mindestens 1")
	saved["standing_counter"] = 0
	var l0: RefCounted = _loader()
	check(bool(l0.restore_state(saved).get("ok", false)) and int(Dictionary(l0.get_standing_orders().get_active("freight")).get("number", 0)) == 1 and l0.get_standing_orders().get_counter() >= 1, "N1: auch mit Zaehler 0 laedt er, Nummer 1")
	saved["standing_counter"] = 5
	var l5: RefCounted = _loader()
	check(bool(l5.restore_state(saved).get("ok", false)) and int(Dictionary(l5.get_standing_orders().get_active("freight")).get("number", 0)) == 5, "N1: mit Zaehler 5 gilt wie bisher Nummer 5")
	var ab: Dictionary = _abandon(l, A, "trade_outpost")
	check(bool(ab.get("ok", false)) and int(ab.get("number", 0)) == 1, "N1: der geladene Auftrag laesst sich aufgeben, Beleg traegt Nummer 1")

# ---------- Skirmish ----------

func _skirmish_part() -> void:
	var s: RefCounted = _sup(false)
	var rs: Array = [_accept(s, A, "trade_outpost"), _deliver(s, A, "satellite_crash"), _abandon(s, A, "trade_outpost")]
	var all_refused := true
	for r: Dictionary in rs:
		if bool(r.get("ok", true)) or String(r.get("reason", "")) != "standing_unavailable": all_refused = false
	check(all_refused and _crates(s) == 0, "Skirmish: ohne Besitzer lehnen alle drei Befehle ab (standing_unavailable), keine Kiste")
	check(not _roundtrip(s).has("standing_clock"), "Skirmish: der Spielstand traegt keinen Dauerauftrags-Schluessel")

# ---------- Befehlsvertrag und Adapter ----------

## Ohne laufende Szene: der Vertrag kennt die drei Befehle; der echte Adapter lehnt sie im Skirmish ab; eine Quelltextpruefung (Notbehelf) belegt,
## dass request_operation sie an _request_standing weitergibt und den Dienstort wie beim Verkauf prueft.
func _adapter_part() -> void:
	var commands: GDScript = load("res://scripts/mission/singleplayer_supply_command_contract.gd")
	var known := true
	for op: String in ["standing_accept", "standing_deliver", "standing_abandon"]:
		if commands.build_command(op, {"order_id": A}, "x").is_empty(): known = false
	check(known, "Vertrag: standing_accept, standing_deliver und standing_abandon stehen in den OPERATIONS")
	var adapter: Node = load("res://scripts/meta/singleplayer_runtime_adapter.gd").new()
	adapter._campaign_mode = false
	adapter._supply = SUPPLY.new()
	adapter._supply.configure()
	var refused: Array = [adapter._request_standing("standing_accept", {"order_id": A, "craft_id": "ship"}, "a1"), adapter._request_standing("standing_deliver", {"order_id": A}, "a2"), adapter._request_standing("standing_abandon", {"order_id": A}, "a3")]
	var all_refused := true
	for r: Dictionary in refused:
		if bool(r.get("ok", true)) or String(r.get("reason", "")) != "standing_unavailable": all_refused = false
	check(all_refused, "Adapter: im Skirmish (kein Besitzer) lehnt _request_standing alle drei Befehle ab")
	adapter.free()
	var source: String = FileAccess.get_file_as_string("res://scripts/meta/singleplayer_runtime_adapter.gd").replace("\r\n", "\n")
	check(source.contains("operation in [\"standing_accept\", \"standing_deliver\", \"standing_abandon\"]:\n\t\treturn _request_standing(operation, data, request_id)"), "Adapter (Quelltext): request_operation leitet die drei Befehle an _request_standing")
	check(source.contains("operation in [\"buy\", \"sell\", \"standing_accept\", \"standing_deliver\", \"standing_abandon\", \"refuel\""), "Adapter (Quelltext): die Pruefung des Versorgungsorts (service_location_id) gilt auch fuer die drei Befehle")
	var request_source: String = source.substr(source.find("func _request_standing"), 900)
	check(request_source.contains("_service_context(craft_id)") and request_source.contains("has(\"trade\")"), "Adapter (Quelltext): Uebernehmen und Abliefern brauchen Schiffskontext und Handelsdienst wie der Verkauf")

# ---------- Anzeige: Haendlerfenster ----------

func _ui_snapshot() -> Dictionary:
	var campaign: Dictionary = {"jobs": {}, "progress": {}}
	if _ui_supply.get_standing_orders() != null: campaign["standing_orders"] = _ui_supply.get_standing_orders_snapshot()
	return {"mode": "campaign" if _ui_supply.get_standing_orders() != null else "skirmish", "campaign": campaign, "supply": _ui_supply.get_supply_snapshot(),
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

func _name(prefix: String, id: String) -> String:
	return prefix + id.replace(":", "_")

func _shown(b: Button) -> bool:
	return b != null and b.is_visible_in_tree()

func _ui_refresh(panel: Control) -> void:
	panel.call("refresh")

func _ui_part() -> void:
	var order_a: Dictionary = _order(A)
	var pay: int = int(order_a.pay)
	var crates: int = int(order_a.crates)
	_ui_supply = _sup()
	_ui_location = "trade_outpost"
	var panel: Control = PRESENTER.new()
	root.add_child(panel)
	panel.size = Vector2(340, 900)
	panel.call("configure", Callable(self, "_ui_snapshot"), Callable(self, "_ui_cmd"))
	for frame in range(4): await process_frame
	_ui_refresh(panel)
	var acc_a: Button = _btn(panel, _name("StandingAccept_", A))
	var acc_b: Button = _btn(panel, _name("StandingAccept_", B))
	var del_a: Button = _btn(panel, _name("StandingDeliver_", A))
	var abandon: Button = _btn(panel, "StandingAbandon")
	check(acc_a != null and acc_b != null and del_a != null and abandon != null, "Knoepfe: Uebernehmen, Abliefern und Aufgeben sind gebaut")
	if acc_a == null or del_a == null or abandon == null: return
	var want_accept: String = "Fracht übernehmen: %d Kisten C-Benit nach Aschental · %d Cr" % [crates, pay]
	check(_shown(acc_a) and acc_a.text == want_accept and not acc_a.disabled, "Knoepfe Startort: Uebernehmen sichtbar und frei, Text '%s' (%s)" % [want_accept, acc_a.text])
	check(not _shown(del_a) and not _shown(abandon) and not _shown(acc_b), "Knoepfe Startort: Abliefern, Aufgeben und der Auftrag des anderen Orts sind nicht zu sehen")
	acc_a.pressed.emit()
	check(_ship_crates(_ui_supply) == crates and String(_status(_ui_supply, A).get("status", "")) == "active", "Knoepfe: Druck auf Uebernehmen laedt %d Kisten, der Auftrag laeuft" % crates)
	check(acc_a.disabled and _shown(abandon) and abandon.text == "Auftrag aufgeben (kein Lohn)" and not abandon.disabled, "Knoepfe: danach Uebernehmen gesperrt, 'Auftrag aufgeben (kein Lohn)' sichtbar")
	var session: String = String(panel.get("_request_session"))
	var own_ids: Array = []
	for rid: Variant in _ui_supply.export_state().requests:
		if String(rid).begins_with("standing-") and not session.is_empty() and String(rid).contains(session):
			own_ids.append(String(rid))
	check(own_ids.size() == 1, "Knoepfe: die Anfragekennung des Klicks traegt die Sitzungskennung des Presenters (%s)" % str(own_ids))
	_ui_location = "satellite_crash"
	_ui_refresh(panel)
	var want_deliver: String = "Fracht abliefern · %d Cr" % pay
	check(_shown(del_a) and del_a.text == want_deliver and not del_a.disabled, "Knoepfe Zielort: Abliefern sichtbar und frei, Text '%s' (%s)" % [want_deliver, del_a.text])
	check(_shown(acc_b) and acc_b.disabled and acc_b.tooltip_text.contains("läuft bereits"), "Knoepfe Zielort: der Auftrag dieses Orts ist gesperrt, solange einer laeuft (%s)" % acc_b.tooltip_text)
	_ui_far = true
	_ui_refresh(panel)
	check(del_a.disabled, "Knoepfe: ohne Handelsdienst am Landeplatz ist Abliefern gesperrt")
	_ui_far = false
	_load(_ui_supply, "craft:ship", CRATE, -1)
	_ui_refresh(panel)
	var note: String = "Fracht unvollständig – nur Aufgeben möglich."
	check(del_a.disabled and del_a.tooltip_text.contains(note) and not abandon.disabled, "Knoepfe: fehlt eine Kiste, ist Abliefern gesperrt, Text '%s'" % note)
	var c0: int = _ui_supply.get_credits()
	del_a.pressed.emit()
	check(_ui_supply.get_credits() == c0 and String(_status(_ui_supply, A).get("status", "")) == "active", "Knoepfe: ein Druck auf das gesperrte Abliefern bewirkt nichts")
	abandon.pressed.emit()
	check(_ui_supply.get_credits() == c0 and _crates(_ui_supply) == 0 and String(_status(_ui_supply, A).get("status", "")) == "locked", "Knoepfe: Aufgeben beendet ohne Lohn, entfernt die Kisten, Sperre laeuft")
	_ui_location = "trade_outpost"
	_ui_refresh(panel)
	check(acc_a.disabled and acc_a.tooltip_text.contains("Wieder verfügbar in"), "Knoepfe: Uebernehmen zeigt die Sperrzeit als Grund (%s)" % acc_a.tooltip_text)
	await _ui_more(panel, acc_a, del_a, abandon)
	panel.queue_free()
	await process_frame

func _ui_more(panel: Control, acc_a: Button, del_a: Button, abandon: Button) -> void:
	var order_a: Dictionary = _order(A)
	var pay: int = int(order_a.pay)
	var crates: int = int(order_a.crates)
	# Neuer Stand: uebernehmen per Knopf, abliefern per Knopf, ein zweiter Druck zahlt nicht noch einmal.
	_ui_supply = _sup()
	_ui_location = "trade_outpost"
	_ui_refresh(panel)
	acc_a.pressed.emit()
	_ui_location = "satellite_crash"
	_ui_refresh(panel)
	var c0: int = _ui_supply.get_credits()
	del_a.pressed.emit()
	check(_ui_supply.get_credits() == c0 + pay and _crates(_ui_supply) == 0, "Knoepfe: Abliefern per Knopf zahlt %d Cr und nimmt die Kisten" % pay)
	del_a.pressed.emit()
	check(_ui_supply.get_credits() == c0 + pay and not _shown(del_a) and not _shown(abandon), "Knoepfe: nach der Abgabe sind Abliefern und Aufgeben weg, ein weiterer Druck zahlt nichts")
	# Zwei Annahmen mit zwei Klicks (zweiter nach Aufgeben und Ablauf der Sperre): jede Kennung ist neu.
	var session_ids: int = 0
	for rid: Variant in _ui_supply.export_state().requests:
		if String(rid).begins_with("standing-"): session_ids += 1
	check(session_ids == 2, "Knoepfe: zwei Klicks (Uebernehmen, Abliefern) erzeugen zwei verschiedene Anfragekennungen (%d)" % session_ids)
	# Schiff voll: Uebernehmen gesperrt mit Grund.
	_ui_supply = _sup()
	var capacity: int = int(Dictionary(Dictionary(_ui_supply.get_supply_snapshot().inventory)["craft:ship"]).capacity)
	_load(_ui_supply, "craft:ship", "ore", capacity - crates + 1)
	_ui_location = "trade_outpost"
	_ui_refresh(panel)
	check(acc_a.disabled and acc_a.tooltip_text.contains("Schiffsfracht ist voll"), "Knoepfe: bei vollem Schiff ist Uebernehmen gesperrt (%s)" % acc_a.tooltip_text)
	# Schiff nicht am Haendler: gesperrt.
	_ui_supply = _sup()
	_ui_far = true
	_ui_refresh(panel)
	check(_shown(acc_a) and acc_a.disabled, "Knoepfe: ohne Handelsdienst am Landeplatz ist Uebernehmen gesperrt")
	_ui_far = false
	# Skirmish (kein Besitzer, kein Schluessel): keine Dauerauftrags-Knoepfe.
	_ui_supply = _sup(false)
	_ui_refresh(panel)
	check(not _shown(acc_a) and not _shown(del_a) and not _shown(abandon), "Knoepfe: im Skirmish ohne Dauerauftraege ist nichts davon zu sehen")
