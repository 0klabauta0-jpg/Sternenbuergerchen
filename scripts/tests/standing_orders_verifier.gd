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
	_nummer()
	_reihenfolge()
	_werkzeugpflicht()
	_besitz_zaehlung()
	_hilfen_und_revision()
	_adapter_und_takt()
	print("STANDING_ORDERS passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)

func _daten() -> void:
	var s := _fresh()
	var snap: Array = s.get_snapshot({})
	_check(snap.size() == 6, "sechs Auftraege (fuenf Waren-Auftraege und Rebellen hetzen; beobachtet %d)" % snap.size())
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
	_check(not bool(s.can_accept(MA, {"mining_tool": 1}).ok) and String(s.can_accept(MA, {"mining_tool": 1}).reason) == "not_playable" and String(s.can_accept(MA).reason) == "item_missing" and not bool(s.can_accept("x").ok), "Mining: nicht spielbar (mit Werkzeug), ohne Angabe fehlt das Werkzeug; unbekannte id abgelehnt")

func _texte() -> void:
	var s := _fresh()
	s.set_names({"trade_outpost": "Kestrel", "satellite_crash": "Aschental"}, {"mining_tool": "Hand-Mining-Tool", "salvage_tool": "Bergungswerkzeug", "a_benit": "A-Benit", "c_benit": "C-Benit", "salvage": "Bergungsgut"})
	_check(String(_entry(s, MA).message) == "Braucht: Hand-Mining-Tool. Ein Mining-Schiff gibt es noch nicht.", "Mining ohne Werkzeug (beobachtet \"%s\")" % _entry(s, MA).message)
	_check(String(_entry(s, MA, {"mining_tool": 1}).message) == "Noch nicht spielbar – kommt mit einem späteren Ausbau.", "Mining mit Werkzeug (beobachtet \"%s\")" % _entry(s, MA, {"mining_tool": 1}).message)
	_check(String(_entry(s, SV).message) == "Braucht: Bergungswerkzeug.", "Bergung ohne Werkzeug (beobachtet \"%s\")" % _entry(s, SV).message)
	_check(String(_entry(s, SV, {"salvage_tool": 2}).message) == "Noch nicht spielbar – kommt mit einem späteren Ausbau." and String(_entry(s, SV, {"salvage_tool": 2}).status) == "unavailable", "Bergung mit Werkzeug")
	_check(String(_entry(s, FA).message) == "Annahme beim Händler in Kestrel.", "Fracht offen (beobachtet \"%s\")" % _entry(s, FA).message)
	_check(String(_entry(s, FA).title) == "Fracht: 4 Kisten C-Benit nach Aschental · 30 Cr", "Titel Fracht (beobachtet \"%s\")" % _entry(s, FA).title)
	_check(String(_entry(s, MA).title) == "Mining: A-Benit (Aschental) · 8 Cr je Stück", "Titel Mining (beobachtet \"%s\")" % _entry(s, MA).title)
	_check(String(_entry(s, SV).title) == "Bergung: Bergungsgut (Aschental) · 8 Cr je Stück", "Titel Bergung mit dem Inventarnamen (beobachtet \"%s\")" % _entry(s, SV).title)
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
	_check(camp.get_standing_orders_snapshot().size() == 6, "Kampagne: Snapshot hat sechs Auftraege")
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

# ---------- Nachbesserung 1 ----------

## W1: Die Nummer der Annahme gehoert zum laufenden Auftrag und ueberlebt Speichern/Laden.
func _nummer() -> void:
	var s := _fresh()
	s.accept(FA)
	_check(int(s.get_active("freight").get("number", 0)) == 1 and int(s.get_counter()) == 1, "Nummer 1 bei der ersten Annahme")
	s.finish(FA, true)
	s.accept(FB)
	_check(int(s.get_active("freight").number) == 2 and String(s.get_active("freight").id) == FB, "zweite Annahme: Nummer 2")
	var data: Dictionary = JSON.parse_string(JSON.stringify(s.export_state()))
	_check(int(data.standing_active.freight.number) == 2, "Export traegt die Nummer je Art")
	var t := _fresh()
	_check(t.restore_state(data) and int(t.get_active("freight").number) == 2 and int(t.get_counter()) == 2, "Nummer ueberlebt Speichern/Laden")
	var old: Dictionary = {"standing_clock": 5.0, "standing_counter": 3, "standing_active": {"freight": {"id": FB}}}
	var u := _fresh()
	_check(u.restore_state(old) and int(u.get_active("freight").number) == 3, "Eintrag nur mit id (Stand von gestern): Nummer = Zaehler, keine Ablehnung")
	for bad: Variant in [0, 4, 1.5, "x", -1]:
		var v := _fresh()
		_check(not v.restore_state({"standing_counter": 3, "standing_active": {"freight": {"id": FB, "number": bad}}}), "Nummer %s wird abgelehnt" % str(bad))
	var w := _fresh()
	_check(w.restore_state({"standing_counter": 3, "standing_active": {"freight": {"id": FB, "number": 3}}}) and int(w.get_active("freight").number) == 3, "Nummer = Zaehler ist erlaubt")

## W3: feste Reihenfolge. finish zweimal: zweites Mal false, Sperre nicht verlaengert; accept nach abgelehntem can_accept: false.
func _reihenfolge() -> void:
	var s := _fresh()
	s.accept(FA)
	_check(s.finish(FA, true), "finish beim ersten Mal")
	s.advance_clock(10.0)
	var before: float = float(s.export_state().standing_locks[FA])
	_check(not s.finish(FA, true), "finish zum zweiten Mal: false")
	_check(float(s.export_state().standing_locks[FA]) == before and int(_entry(s, FA).lock_remaining_seconds) == 470, "Sperre wurde nicht verlaengert (beobachtet %s)" % str(_entry(s, FA).lock_remaining_seconds))
	var counter_before: int = s.get_counter()
	_check(not bool(s.can_accept(FA).ok) and not s.accept(FA), "accept nach abgelehntem can_accept: false")
	_check(s.get_counter() == counter_before and s.get_active("freight").is_empty(), "abgelehnte Annahme aendert weder Zaehler noch laufenden Auftrag")
	_check(s.accept(FB) and not s.accept(FB) and s.get_counter() == counter_before + 1, "laufender Auftrag: zweite Annahme false, Zaehler steigt nicht")

## K3: ohne owned_items kein Umgehen der Werkzeugpflicht (Fixture: spielbarer Mining-Auftrag).
func _werkzeugpflicht() -> void:
	var defs: Dictionary = _defs()
	defs.orders.append({"id": "mining:x:y", "kind": "mining", "origin": "trade_outpost", "item": "a_benit", "requires_item": "mining_tool", "pay_per_unit": 8})
	var s: RefCounted = STANDING.new()
	_check(s.configure(defs), "Fixture: spielbarer Mining-Auftrag konfiguriert")
	_check(not bool(s.can_accept("mining:x:y").ok) and String(s.can_accept("mining:x:y").reason) == "item_missing" and not s.accept("mining:x:y"), "ohne owned_items: Werkzeug fehlt, nicht annehmbar")
	_check(not bool(s.can_accept("mining:x:y", {}).ok) and not bool(s.can_accept("mining:x:y", {"mining_tool": 0}).ok), "leerer Besitz und 0 Stueck: abgelehnt")
	_check(bool(s.can_accept("mining:x:y", {"mining_tool": 1}).ok) and s.accept("mining:x:y", {"mining_tool": 1}), "mit Werkzeug: annehmbar")
	_check(_fresh().required_items() == ["mining_tool", "salvage_tool"], "required_items nennt nur die Gegenstaende aus den Daten (beobachtet %s)" % str(_fresh().required_items()))

## W2c / K2: Besitz-Zaehlung im Versorgungsstand: Basislager, Schiff, Rucksack je einmal; nur verlangte Gegenstaende.
func _besitz_zaehlung() -> void:
	var supply = SUPPLY.new()
	supply.configure()
	supply.enable_standing_orders()
	supply.configure_inventory(["u1"], ["ship"], false)
	supply._inventory["base:homebase"].items["mining_tool"] = 0
	supply._inventory["base:homebase"].items["salvage_tool"] = 0
	var reason := func() -> String:
		for e: Dictionary in supply.get_standing_orders_snapshot():
			if String(e.id) == MA: return String(e.reason)
		return "-"
	_check(String(reason.call()) == "item_missing", "kein Werkzeug irgendwo: item_missing")
	supply._inventory["craft:ship"].items["mining_tool"] = 1
	_check(String(reason.call()) == "not_playable", "Werkzeug im Schiff zaehlt")
	supply._inventory["craft:ship"].items["mining_tool"] = 0
	supply._inventory["unit:u1:backpack"].items["mining_tool"] = 1
	_check(String(reason.call()) == "not_playable", "Werkzeug im Rucksack zaehlt")
	supply._inventory["unit:u1:backpack"].items["mining_tool"] = 0
	_check(String(reason.call()) == "item_missing", "Werkzeug wieder weg: item_missing")
	supply._inventory["base:homebase"].items["mining_tool"] = 1
	_check(String(reason.call()) == "not_playable", "Werkzeug im Basislager zaehlt")
	supply._inventory["craft:ship"].items["a_benit"] = 7
	var owned: Dictionary = supply._standing_owned_items()
	_check(owned.keys().size() == 2 and int(owned.get("mining_tool", -1)) == 1 and int(owned.get("salvage_tool", -1)) == 0 and not owned.has("a_benit"), "gezaehlt werden nur mining_tool und salvage_tool (beobachtet %s)" % str(owned))

## W3: Hilfen im Versorgungsstand aendern Zustand und _revision zusammen.
func _hilfen_und_revision() -> void:
	var supply = SUPPLY.new()
	supply.configure()
	_check(not bool(supply.standing_accept_state(FA).get("ok", true)) and not supply.standing_finish_state(FA, true), "ohne Besitzer (Skirmish): Hilfen lehnen ab")
	supply.enable_standing_orders()
	var rev0: int = int(supply.export_state().revision)
	_check(bool(supply.standing_can_accept(FA).ok) and int(supply.export_state().revision) == rev0, "standing_can_accept aendert nichts")
	var accepted: Dictionary = supply.standing_accept_state(FA)
	_check(bool(accepted.ok) and int(accepted.number) == 1 and int(supply.export_state().revision) == rev0 + 1, "standing_accept_state: ok, Nummer 1, _revision +1 (beobachtet %s)" % str(accepted))
	var refused: Dictionary = supply.standing_accept_state(FB)
	_check(not bool(refused.ok) and String(refused.reason) == "kind_busy" and int(supply.export_state().revision) == rev0 + 1, "zweite Annahme der Art: abgelehnt, _revision unveraendert")
	_check(supply.standing_finish_state(FA, true) and int(supply.export_state().revision) == rev0 + 2, "standing_finish_state: true, _revision +1")
	_check(not supply.standing_finish_state(FA, true) and int(supply.export_state().revision) == rev0 + 2, "zweiter Abschluss: false, _revision unveraendert")
	var ex: Dictionary = JSON.parse_string(JSON.stringify(supply.export_state()))
	var back = SUPPLY.new()
	back.configure()
	back.enable_standing_orders()
	_check(bool(back.restore_state(ex).get("ok", false)) and not bool(back.standing_can_accept(FA).ok) and bool(back.standing_can_accept(FB).ok), "nach Speichern/Laden: Sperre von A bleibt, B frei")

func _adapter(campaign: bool) -> Node:
	var adapter: Node = load("res://scripts/meta/singleplayer_runtime_adapter.gd").new()
	adapter._campaign_mode = campaign
	adapter._supply = SUPPLY.new()
	adapter._supply.configure()
	adapter._setup_standing_orders()
	return adapter

func _source_between(path: String, start_marker: String, end_marker: String) -> String:
	var text: String = FileAccess.get_file_as_string(path)
	var from: int = text.find(start_marker)
	if from < 0: return ""
	var to: int = text.find(end_marker, from + start_marker.length())
	return text.substr(from, (to if to > from else text.length()) - from)

## W2a/W2b: echter Adapter (ohne Szene) fuer beide Modi; Takt ueber die einzeln aufrufbare Funktion des Ablaufs.
## Notbehelf: ohne laufende Szene prueft eine Quelltextpruefung, dass _process den Takt aufruft und configure/get_snapshot die Adapter-Stellen nutzen.
func _adapter_und_takt() -> void:
	var camp: Node = _adapter(true)
	_check(camp._supply.get_standing_orders() != null, "Kampagnen-Adapter legt den Besitzer an")
	var camp_snapshot: Dictionary = {}
	camp._attach_standing_orders(camp_snapshot)
	_check(camp_snapshot.has("standing_orders") and Array(camp_snapshot.standing_orders).size() == 6, "Kampagnen-Adapter liefert campaign.standing_orders (sechs Eintraege)")
	var titles: Array = []
	for e: Dictionary in camp_snapshot.standing_orders: titles.append(String(e.title))
	_check(titles.has("Fracht: 4 Kisten C-Benit nach Aschental · 30 Cr") and titles.has("Bergung: Bergungsgut (Aschental) · 8 Cr je Stück"), "Titel nutzen die echten Kataloge (beobachtet %s)" % str(titles))
	var skirmish: Node = _adapter(false)
	var skirmish_snapshot: Dictionary = {}
	skirmish._attach_standing_orders(skirmish_snapshot)
	_check(skirmish._supply.get_standing_orders() == null and not skirmish_snapshot.has("standing_orders") and not skirmish._supply.export_state().has("standing_clock"), "Skirmish-Adapter: kein Besitzer, kein Schluessel im Snapshot, keiner im Versorgungsstand")
	skirmish.advance_standing_clock(5.0)
	_check(not skirmish._supply.export_state().has("standing_clock"), "Skirmish-Adapter: die Uhr tickt nicht")
	var flow_script = load("res://scripts/meta/meta_layer_flow.gd")
	var flow: Node = flow_script.new()
	flow._game_start_request = {"mode": "campaign"}
	flow._singleplayer_runtime = camp
	flow._tick_standing_orders(1000.0)
	_check(is_equal_approx(float(camp._supply.export_state().standing_clock), 2.0), "Takt: ein Bild zaehlt hoechstens 2,0 s (beobachtet %s)" % str(camp._supply.export_state().standing_clock))
	flow._tick_standing_orders(0.5)
	_check(is_equal_approx(float(camp._supply.export_state().standing_clock), 2.5), "Takt: kleines Delta wird voll addiert")
	flow._game_start_request = {"mode": "skirmish"}
	flow._tick_standing_orders(1.0)
	_check(is_equal_approx(float(camp._supply.export_state().standing_clock), 2.5), "Takt: ausserhalb der Kampagne keine Addition")
	flow._singleplayer_runtime = skirmish
	flow._game_start_request = {"mode": "campaign"}
	flow._tick_standing_orders(1.0)
	_check(not skirmish._supply.export_state().has("standing_clock"), "Takt gegen Skirmish-Adapter: nichts")
	var process_text: String = _source_between("res://scripts/meta/meta_layer_flow.gd", "func _process(_delta: float)", "\nfunc ")
	_check(process_text.contains("_tick_standing_orders(_delta)"), "Quelltext: _process ruft den Takt der Daueraufträge")
	var tick_text: String = _source_between("res://scripts/meta/meta_layer_flow.gd", "func _tick_standing_orders(", "\nfunc ")
	_check(tick_text.contains("minf(delta, PERSONNEL_RECOVERY_MAX_FRAME_SECONDS)") and float(flow_script.PERSONNEL_RECOVERY_MAX_FRAME_SECONDS) == 2.0, "Quelltext: Kappung ist PERSONNEL_RECOVERY_MAX_FRAME_SECONDS = 2,0")
	var adapter_path := "res://scripts/meta/singleplayer_runtime_adapter.gd"
	_check(_source_between(adapter_path, "func configure(flow: Node", "\nfunc ").contains("_setup_standing_orders()") and _source_between(adapter_path, "func get_snapshot() -> Dictionary", "\nfunc ").contains("_attach_standing_orders(campaign)"), "Quelltext: configure und get_snapshot des Adapters nutzen die Dauerauftrags-Stellen")
	flow.free()
	camp.free()
	skirmish.free()
