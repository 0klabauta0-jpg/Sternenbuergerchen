extends SceneTree
## Dauerauftraege (Handel H3, Aufgabe A): reine Regeln, rechnerisch. Keine Szene, kein Flug, kein Einsatz.
## Prueft Daten, Uhr, Annahme, Sperrzeit je Auftrag, Ablehnungen, Texte, Export/Import, alten Stand, Fehlformen
## und dass der Skirmish-Versorgungsstand den Schluessel nicht fuehrt.
const STANDING = preload("res://scripts/core/standing_orders_state.gd")
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const FA := "freight:trade_outpost:c_benit"
const FB := "freight:satellite_crash:b_benit"
const MA := "mining:satellite_crash:a_benit"
const SV := "salvage:satellite_crash:salvage"
var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func _check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failed += 1
	print(("PASS " if value else "FAIL ") + label)

func _defs() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/standing_orders.json"))

func _fresh() -> RefCounted:
	var s: RefCounted = STANDING.new()
	_check(s.configure(_defs()), "Datei laedt und konfiguriert")
	return s

func _entry(s: RefCounted, id: String, owned: Dictionary = {}) -> Dictionary:
	for e: Dictionary in s.get_snapshot(owned):
		if String(e.id) == id: return e
	return {}

func _run() -> void:
	_daten()
	_uhr_und_sperre()
	_texte()
	_zustand()
	_fehlformen()
	_skirmish()
	print("STANDING_ORDERS passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)

func _daten() -> void:
	var s := _fresh()
	var snap: Array = s.get_snapshot({})
	_check(snap.size() == 5, "fuenf Auftraege (beobachtet %d)" % snap.size())
	var a: Dictionary = _entry(s, FA)
	_check(String(a.kind) == "freight" and String(a.origin) == "trade_outpost" and String(a.destination) == "satellite_crash" and int(a.crates) == 4 and int(a.pay) == 30, "Fracht-Eintrag traegt die Daten")
	_check(String(a.status) == "open" and int(a.lock_remaining_seconds) == 0, "Anfang: Fracht offen, keine Sperre")
	var m: Dictionary = _entry(s, MA)
	_check(int(m.pay_per_unit) == 8 and String(m.status) == "unavailable", "Mining: 8 Cr je Stueck, nicht verfuegbar")
	var bad: Dictionary = _defs()
	bad.orders[0].crates = 0
	_check(not STANDING.new().configure(bad), "Fehlform: Kistenzahl 0 wird abgelehnt")
	bad = _defs()
	bad.lock_seconds = "x"
	_check(not STANDING.new().configure(bad), "Fehlform: Sperrzeit keine Zahl wird abgelehnt")
	bad = _defs()
	bad.orders.append(bad.orders[0].duplicate())
	_check(not STANDING.new().configure(bad), "Fehlform: doppelte id wird abgelehnt")
	_check(not STANDING.new().configure({}), "Fehlform: leere Datei wird abgelehnt")

func _uhr_und_sperre() -> void:
	var s := _fresh()
	s.advance_clock(-5.0)
	s.advance_clock(NAN)
	s.advance_clock(INF)
	_check(float(s.export_state().standing_clock) == 0.0, "Uhr: negativ, NaN und unendlich werden ignoriert")
	s.advance_clock(1.5)
	s.advance_clock(2.5)
	_check(is_equal_approx(float(s.export_state().standing_clock), 4.0), "Uhr: addiert (beobachtet %s)" % str(s.export_state().standing_clock))
	_check(bool(s.can_accept(FA).ok), "Fracht A ist annehmbar")
	_check(s.accept(FA), "Annahme gelingt")
	_check(String(_entry(s, FA).status) == "active" and String(s.get_active("freight").get("id", "")) == FA, "danach active, get_active nennt den Auftrag")
	var second: Dictionary = s.can_accept(FB)
	_check(not bool(second.ok) and String(second.reason) == "kind_busy" and not s.accept(FB), "zweiter laufender Frachtauftrag wird abgelehnt (beobachtet %s)" % str(second))
	_check(not bool(s.can_accept(FA).ok) and String(s.can_accept(FA).reason) == "already_active", "derselbe Auftrag laeuft schon: abgelehnt")
	_check(not s.finish("gibt_es_nicht", true) and not s.finish(FB, true), "finish: unbekannte oder nicht laufende id wird abgelehnt")
	_check(s.finish(FA, true), "Abgabe beendet den Auftrag")
	var e: Dictionary = _entry(s, FA)
	_check(String(e.status) == "locked" and int(e.lock_remaining_seconds) == 480, "gesperrt, genau 480 s (beobachtet %s/%s)" % [e.status, str(e.lock_remaining_seconds)])
	_check(String(_entry(s, FB).status) == "open" and bool(s.can_accept(FB).ok), "Sperre von A beruehrt B nicht")
	s.advance_clock(479.0)
	_check(String(_entry(s, FA).status) == "locked" and int(_entry(s, FA).lock_remaining_seconds) == 1, "nach 479 s noch 1 s Sperre")
	s.advance_clock(1.0)
	_check(String(_entry(s, FA).status) == "open" and bool(s.can_accept(FA).ok), "nach 480 s wieder offen")
	_check(s.accept(FA) and s.finish(FA, false), "Aufgabe ohne Abgabe: finish(false) geht")
	_check(String(_entry(s, FA).status) == "locked" and int(_entry(s, FA).lock_remaining_seconds) == 480, "auch nach Aufgabe: 480 s Sperre")
	_check(String(s.can_accept(FA).reason) == "locked", "gesperrter Auftrag nicht annehmbar (Grund locked)")
	_check(not bool(s.can_accept(MA).ok) and String(s.can_accept(MA).reason) == "not_playable" and not bool(s.can_accept("x").ok), "Mining: nicht spielbar; unbekannte id abgelehnt")

func _texte() -> void:
	var s := _fresh()
	s.set_names({"trade_outpost": "Kestrel", "satellite_crash": "Aschental"}, {"mining_tool": "Hand-Mining-Tool", "salvage_tool": "Bergungswerkzeug", "a_benit": "A-Benit", "c_benit": "C-Benit"})
	_check(String(_entry(s, MA).message) == "Braucht: Hand-Mining-Tool. Ein Mining-Schiff gibt es noch nicht.", "Mining ohne Werkzeug (beobachtet \"%s\")" % _entry(s, MA).message)
	_check(String(_entry(s, MA, {"mining_tool": 1}).message) == "Noch nicht spielbar – kommt mit einem späteren Ausbau.", "Mining mit Werkzeug (beobachtet \"%s\")" % _entry(s, MA, {"mining_tool": 1}).message)
	_check(String(_entry(s, SV).message) == "Braucht: Bergungswerkzeug.", "Bergung ohne Werkzeug (beobachtet \"%s\")" % _entry(s, SV).message)
	_check(String(_entry(s, SV, {"salvage_tool": 2}).message) == "Noch nicht spielbar – kommt mit einem späteren Ausbau." and String(_entry(s, SV, {"salvage_tool": 2}).status) == "unavailable", "Bergung mit Werkzeug")
	_check(String(_entry(s, FA).message) == "Annahme beim Händler in Kestrel.", "Fracht offen (beobachtet \"%s\")" % _entry(s, FA).message)
	_check(String(_entry(s, FA).title) == "Fracht: 4 Kisten C-Benit nach Aschental · 30 Cr", "Titel Fracht (beobachtet \"%s\")" % _entry(s, FA).title)
	_check(String(_entry(s, MA).title) == "Mining: A-Benit (Aschental) · 8 Cr je Stück", "Titel Mining (beobachtet \"%s\")" % _entry(s, MA).title)
	_check(String(_entry(s, SV).title) == "Bergung: Wrackteile (Aschental) · 8 Cr je Stück", "Titel Bergung (beobachtet \"%s\")" % _entry(s, SV).title)
	s.accept(FA)
	_check(String(_entry(s, FA).message) == "Unterwegs: 4 Kisten nach Aschental.", "Fracht laeuft (beobachtet \"%s\")" % _entry(s, FA).message)
	s.finish(FA, true)
	s.advance_clock(61.0)
	_check(String(_entry(s, FA).message) == "Wieder verfügbar in 6:59.", "Sperre als M:SS (beobachtet \"%s\")" % _entry(s, FA).message)
	var raw := _fresh()
	_check(String(_entry(raw, FA).message).contains("trade_outpost"), "ohne Namenskatalog faellt der Text auf die Rohkennung zurueck")

func _zustand() -> void:
	var s := _fresh()
	s.advance_clock(100.0)
	s.accept(FA)
	s.finish(FA, true)
	s.advance_clock(10.0)
	s.accept(FB)
	var data: Dictionary = JSON.parse_string(JSON.stringify(s.export_state()))
	_check(data.has("standing_clock") and data.has("standing_locks") and data.has("standing_active") and data.has("standing_counter"), "Export fuehrt die vier Schluessel")
	_check(int(data.standing_counter) == 2, "Zaehler zaehlt Annahmen (beobachtet %s)" % str(data.standing_counter))
	var t := _fresh()
	_check(t.restore_state(data), "Import des Exports gelingt")
	_check(JSON.stringify(t.export_state()) == JSON.stringify(s.export_state()), "Export/Import rund")
	_check(String(_entry(t, FA).status) == "locked" and int(_entry(t, FA).lock_remaining_seconds) == 470 and String(_entry(t, FB).status) == "active", "Sperre und laufender Auftrag ueberleben")
	var old := _fresh()
	old.advance_clock(50.0)
	old.accept(FA)
	_check(old.restore_state({}), "alter Stand ohne die Schluessel laedt")
	var ex: Dictionary = old.export_state()
	_check(float(ex.standing_clock) == 0.0 and Dictionary(ex.standing_locks).is_empty() and Dictionary(ex.standing_active).is_empty() and int(ex.standing_counter) == 0, "alter Stand: Uhr 0, nichts gesperrt, nichts aktiv")
	var pruned := _fresh()
	pruned.accept(FA)
	pruned.finish(FA, true)
	pruned.advance_clock(480.0)
	_check(Dictionary(pruned.export_state().standing_locks).is_empty(), "abgelaufene Sperren stehen nicht im Export")

func _fehlformen() -> void:
	var s := _fresh()
	for bad: Dictionary in [{"standing_clock": -1.0}, {"standing_clock": "a"}, {"standing_clock": NAN}, {"standing_locks": []}, {"standing_locks": {FA: "x"}}, {"standing_active": 3}, {"standing_active": {"freight": 5}}, {"standing_counter": -1}, {"standing_counter": 1.5}, {"standing_counter": "1"}]:
		_check(not s.restore_state(bad), "Fehlform abgelehnt: %s" % str(bad))
	_check(float(s.export_state().standing_clock) == 0.0, "abgelehnter Import aendert nichts")
	_check(s.restore_state({"standing_clock": 10.0, "standing_locks": {"gibt_es_nicht": 99.0, FA: 9999.0}, "standing_active": {"unbekannt": {"id": "x"}, "freight": {"id": "gibt_es_nicht"}}}), "Unbekanntes wird still verworfen")
	var ex: Dictionary = s.export_state()
	_check(Dictionary(ex.standing_active).is_empty() and Dictionary(ex.standing_locks).size() == 1 and float(ex.standing_locks[FA]) == 490.0, "Sperrende auf Uhr + 480 gekappt (beobachtet %s)" % str(ex.standing_locks))

func _skirmish() -> void:
	var supply = SUPPLY.new()
	supply.configure()
	var ex: Dictionary = supply.export_state()
	_check(not ex.has("standing_clock") and not ex.has("standing_locks") and not ex.has("standing_active") and not ex.has("standing_counter"), "Versorgungsstand ohne Dauerauftraege (Skirmish) fuehrt die Schluessel nicht")
	_check(supply.get_standing_orders_snapshot().is_empty(), "Skirmish: kein Dauerauftrags-Snapshot")
	var camp = SUPPLY.new()
	camp.configure()
	_check(camp.enable_standing_orders(), "Kampagne: Besitzer wird angelegt")
	camp.advance_standing_clock(3.0)
	var cex: Dictionary = camp.export_state()
	_check(cex.has("standing_clock") and is_equal_approx(float(cex.standing_clock), 3.0), "Kampagne: Versorgungsexport fuehrt die Uhr")
	_check(camp.get_standing_orders_snapshot().size() == 5, "Kampagne: Snapshot hat fuenf Auftraege")
	var back = SUPPLY.new()
	back.configure()
	back.enable_standing_orders()
	_check(bool(back.restore_state(JSON.parse_string(JSON.stringify(cex))).get("ok", false)) and is_equal_approx(float(back.export_state().standing_clock), 3.0), "Kampagne: Versorgungsstand speichert und laedt die Uhr")
	var legacy: Dictionary = JSON.parse_string(JSON.stringify(cex))
	for key: String in ["standing_clock", "standing_locks", "standing_active", "standing_counter"]: legacy.erase(key)
	_check(bool(back.restore_state(legacy).get("ok", false)) and float(back.export_state().standing_clock) == 0.0, "Kampagne: alter Versorgungsstand ohne Schluessel laedt")
	var broken: Dictionary = JSON.parse_string(JSON.stringify(cex))
	broken["standing_clock"] = -4.0
	_check(not bool(back.restore_state(broken).get("ok", true)), "Kampagne: negative Uhr im Versorgungsstand wird abgelehnt")
