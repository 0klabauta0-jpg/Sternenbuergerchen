extends "res://scripts/tests/campaign_intro_loop_smoke.gd"
## Handel H1 (23.11.2026): Ein Aussenposten bleibt nach seinem Story-Auftrag als friedlicher Besuch offen.
## Echter Kampagnenzustand und der echte Flug des Einfuehrungstreibers (campaign_intro_loop_smoke): Auftrag satellite_recovery wird wirklich
## geflogen und abgeschlossen; danach wird die Absturzstelle OHNE Auftrag angeflogen. Geprueft wird:
##   A (Zustand, ohne Flug) vor dem Abschluss ist der Ort an seinen Auftrag gebunden, der Handelsaussenposten noch gesperrt;
##   B (Dateien) das Besuchsszenario ist friedlich (keine Gegner), gehoert zu keinem Auftrag und passt zu Karte und Markern;
##   C (Flug) nach dem Abschluss ist der Ort ohne Auftrag anfliegbar, geladen wird das Besuchsszenario, Auftragsstatus und Belege bleiben unveraendert, Abflug und Heimkehr gehen, der Marktbestand ist danach wieder voll, der Ort
##     ist weiter anfliegbar.
## Abschlusszeile: CAMPAIGN_OPEN_OUTPOSTS passed=%d failed=%d (danach die Zeile des Treibers SINGLEPLAYER_LOOP_RESULTS ...).

const CAMPAIGN_STATE = preload("res://scripts/core/singleplayer_campaign_state.gd")
const VISITS_PATH := "res://data/singleplayer/open_outposts.json"
const MARKET_PATH := "res://data/singleplayer/commodity_market.json"
const SAT_MAP := "res://maps/satellite_crash_site.json"
var _oo_visit_flown := false

func _market_file() -> Dictionary:
	return Dictionary(JSON.parse_string(FileAccess.get_file_as_string(MARKET_PATH)))

# ---------- A: Zustand vor dem Abschluss ----------

func _state_part() -> void:
	var cs: RefCounted = CAMPAIGN_STATE.new()
	cs.configure()
	var visits: Dictionary = Dictionary(JSON.parse_string(FileAccess.get_file_as_string(VISITS_PATH)))
	_check(visits.has("trade_outpost") and visits.has("satellite_crash"), "A: open_outposts.json nennt Handelsaussenposten und Absturzstelle")
	_check(String(cs.open_visit_scenario_id("satellite_crash")) == "" and String(cs.open_visit_scenario_id("trade_outpost")) == "", "A: frischer Stand: kein Ort hat ein offenes Besuchsszenario")
	_check(not bool(cs.validate_location_visit("trade_outpost").get("ok", true)), "A: der Handelsaussenposten ist vor seinem Auftrag nicht anfliegbar (tutorial_locked)")
	var accepted: Dictionary = cs.apply_command({"contract_category": "singleplayer_campaign", "operation": "accept_job", "payload": {"job_id": "satellite_recovery"}, "request_id": "oo:accept"})
	_check(bool(accepted.get("ok", false)) and String(cs.open_visit_scenario_id("satellite_crash")) == "", "A: mit angenommenem, noch nicht abgeschlossenem Auftrag bleibt der Ort an den Auftrag gebunden")
	var skirmish: RefCounted = CAMPAIGN_STATE.new()
	skirmish.configure({}, {}, false)
	_check(String(skirmish.open_visit_scenario_id("satellite_crash")) == "", "A: ausserhalb der Kampagne (freie Orte) gibt es keine Sonderregel")
	_check(String(cs.open_visit_scenario_id("polisa")) == "" and String(cs.open_visit_scenario_id("fortified_outpost")) == "", "A: Orte ohne Besuchsszenario (Polisa, Windbruch) bleiben unberuehrt")

# ---------- B: Dateien ----------

func _files_part() -> void:
	var visits: Dictionary = Dictionary(JSON.parse_string(FileAccess.get_file_as_string(VISITS_PATH)))
	var locations: Dictionary = Dictionary(JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/locations.json")))
	var jobs: Dictionary = Dictionary(JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/jobs.json")))
	var job_scenarios: Array = []
	for id: String in jobs: job_scenarios.append(String(Dictionary(jobs[id]).get("scenario_id", "")))
	for loc: String in visits:
		var sid := String(visits[loc])
		var path := "res://data/mission_scenarios/%s.json" % sid
		_check(FileAccess.file_exists(path), "B: Besuchsszenario %s existiert" % sid)
		if not FileAccess.file_exists(path): continue
		var sc: Dictionary = Dictionary(JSON.parse_string(FileAccess.get_file_as_string(path)))
		_check(String(sc.get("scenario_id", "")) == sid and Array(sc.get("enemy_groups", [1])).is_empty() and int(Dictionary(sc.get("wave_config", {})).get("wave_count", 1)) == 0 and Array(sc.get("patrol_bindings", [1])).is_empty(), "B: %s ist friedlich: keine Gegner, keine Wellen, keine Patrouillen" % sid)
		_check(not job_scenarios.has(sid), "B: %s gehoert zu keinem Auftrag (kein Einsatzergebnis kann einen Auftrag veraendern)" % sid)
		_check(String(sc.get("map_file_path", "")) == String(Dictionary(locations[loc]).get("map_file_path", "-")), "B: %s liegt auf der Karte des Ortes %s" % [sid, loc])
		var vs: Dictionary = Dictionary(sc.get("vertical_slice", {}))
		_check(String(vs.get("scenario_kind", "")) == "singleplayer_visit", "B: %s ist ein Besuch (scenario_kind singleplayer_visit)" % sid)
		var markers: String = FileAccess.get_file_as_string(String(sc.get("map_file_path", "")))
		var ids: Array = []
		for point: Dictionary in Array(vs.get("interaction_points", [])): ids.append(String(point.get("marker_id", "")))
		for step: Dictionary in Array(vs.get("flow_steps", [])): ids.append(String(step.get("target_marker_id", "")))
		ids.append(String(Dictionary(Array(vs.get("team_slots", [{}]))[0]).get("spawn_marker_id", "")))
		var all_markers := true
		for marker: String in ids: all_markers = all_markers and markers.contains('"%s"' % marker)
		_check(all_markers and ids.has("trade_service"), "B: %s nutzt nur Marker, die die Karte hat, und hat den Haendler (trade_service)" % sid)
	var adapter_src: String = FileAccess.get_file_as_string("res://scripts/meta/singleplayer_runtime_adapter.gd")
	_check(adapter_src.contains('"mission_id": "satellite_crash_visit"') and adapter_src.count("_destination_scenario_id(") == 3, "B: der Adapter kennt das Besuchsszenario im Katalog und nutzt die Zielwahl an beiden Stellen (Auswahl und Abflug)")

# ---------- C: Flug ----------

func _run() -> void:
	_state_part()
	_files_part()
	await super._run()

## Der Treiber fliegt zuerst satellite_recovery (mit Auftrag, bis zur Heimkehr und zum Hochladen) und waehlt dann den Handelsaussenposten. Statt
## dessen wird hier die jetzt abgeschlossene Absturzstelle ohne Auftrag angeflogen; danach endet der Lauf (false: der Treiber bricht ab und meldet).
func _launch_and_land(scenario_id: String, map_path: String) -> bool:
	if scenario_id != "outpost_recovery" or _oo_visit_flown:
		return await super._launch_and_land(scenario_id, map_path)
	_oo_visit_flown = true
	await _visit_part()
	return false

func _market_entry(supply: Dictionary, loc: String, item: String) -> Dictionary:
	return Dictionary(Dictionary(Dictionary(supply.get("market", {})).get(loc, {})).get(item, {}))

func _cargo_total(supply: Dictionary, item: String) -> int:
	var total := 0
	for container: String in ["craft:" + _craft_id, "station:trade_outpost:lift"]:
		total += int(Dictionary(Dictionary(Dictionary(supply.get("inventory", {})).get(container, {})).get("items", {})).get(item, 0))
	return total

func _visit_part() -> void:
	var market: Dictionary = Dictionary(_market_file().locations).satellite_crash
	var full_stock: int = int(market.a_benit.stock)
	var campaign_before: Dictionary = _campaign()
	var sat_before: Dictionary = Dictionary(campaign_before.jobs.satellite_recovery)
	var receipts_before: int = Dictionary(campaign_before.get("completion_receipts", {})).size()
	var live_campaign: RefCounted = _runtime.get("_campaign")
	_check(String(live_campaign.open_visit_scenario_id("satellite_crash")) == "satellite_crash_visit", "C: nach dem Abschluss meldet der Kampagnenzustand das Besuchsszenario der Absturzstelle")
	_check(String(live_campaign.open_visit_scenario_id("trade_outpost")) == "", "C: der Handelsaussenposten bleibt bis zu seinem Auftrag gebunden")
	var selected: Dictionary = _screen.call("request_operation", "select_destination", {"location_id": "satellite_crash", "job_id": "", "request_id": "open:sat"})
	_check(bool(selected.get("ok", false)), "C: die abgeschlossene Absturzstelle laesst sich ohne Auftrag als Ziel waehlen")
	_check(String(_flow.get("_selected_mission_id")) == "satellite_crash_visit", "C: gewaehlt ist das Besuchsszenario, nicht die Satellitenbergung (%s)" % String(_flow.get("_selected_mission_id")))
	if not await _launch_and_land("satellite_crash_visit", SAT_MAP):
		return
	var mission: Node = _flow.get("_active_mission")
	var controller: Node = mission.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray([_team_id]), false)
	_check(String(_campaign().get("selected_job_id", "")) == "" and String(Dictionary(_campaign().jobs.satellite_recovery).get("status", "")) == "completed", "C: der Besuch laeuft ohne Auftrag; der Story-Auftrag bleibt abgeschlossen")
	if not await _move_and_use(mission, "trade_service", "trade_service", SAT_MAP):
		return
	# Der Handel am Ort selbst (Haendlerfenster) ist in diesem Lauf nicht abgedeckt: die Absturzstelle gibt Handelsdienste nur, wenn das Schiff
	# hoechstens 256 Einheiten vom Haendler steht (Landepad und Haendler liegen 2400 Einheiten auseinander; ein Landepunkt neben dem Haendler
	# wurde im Lauf nicht erreicht). Handel und Anzeige prueft commodity_market_verifier. Hier wird der Bestand ueber den Versorgungsbesitzer
	# gesenkt, damit das Auffuellen bei der echten Heimlandung etwas zu tun hat.
	var supply_owner: RefCounted = _runtime.get("_supply")
	var depleted: Dictionary = supply_owner.apply_command({"contract_category": "singleplayer_supply", "operation": "buy", "payload": {"offer_id": "market:satellite_crash:a_benit", "quantity": 3}, "request_id": "open:deplete"}, {"location_id": "satellite_crash", "craft_busy": false, "craft_id": _craft_id})
	_check(bool(depleted.get("ok", false)) and int(_market_entry(_supply(), "satellite_crash", "a_benit").get("stock", -1)) == full_stock - 3, "C: der Marktbestand der Absturzstelle ist vor der Heimkehr gesenkt (%d)" % (full_stock - 3))
	var during: Dictionary = _campaign()
	_check(Dictionary(during.jobs.satellite_recovery).get("status") == sat_before.get("status") and Dictionary(during.get("completion_receipts", {})).size() == receipts_before, "C: der Besuch aendert weder Auftragsstatus noch Belege")
	var services: Control = _flow.get("_singleplayer_services")
	var toggle: Button = _flow.get("_singleplayer_services_toggle")
	if not await _wait(func(): return toggle != null and toggle.is_visible_in_tree(), 3000, "C: die Versorgung wird angeboten"):
		return
	toggle.pressed.emit()
	services.call("set_selected_craft", _craft_id)
	if not await _prepare_visit_return(mission):
		return
	var orbital_return: Button = services.find_child("ServiceReturnHomebase", true, false)
	if not await _wait(func(): return orbital_return != null and orbital_return.is_visible_in_tree() and not orbital_return.disabled, 2000, "C: der Rueckflug-Knopf ist frei"):
		_dump("open_outpost_return")
		return
	orbital_return.pressed.emit()
	if not await _wait_homebase():
		return
	_flow.call("_show_homebase")
	var after: Dictionary = _flow.call("get_singleplayer_snapshot")
	var after_campaign: Dictionary = Dictionary(after.campaign)
	_check(Dictionary(after_campaign.jobs.satellite_recovery).get("status") == "completed" and Dictionary(after_campaign.get("completion_receipts", {})).size() == receipts_before, "C: nach der Heimkehr bleibt der Auftrag abgeschlossen, kein zweiter Beleg, keine zweite Belohnung")
	_check(int(_market_entry(Dictionary(after.supply), "satellite_crash", "a_benit").get("stock", -1)) == full_stock, "C: die Heimlandung hat den Marktbestand wieder aufgefuellt")
	_check(String(after_campaign.get("selected_job_id", "")) == "", "C: kein Auftrag bleibt gewaehlt")
	var again: Dictionary = _screen.call("request_operation", "select_destination", {"location_id": "satellite_crash", "job_id": "", "request_id": "open:sat:again"})
	_check(bool(again.get("ok", false)) and String(live_campaign.open_visit_scenario_id("satellite_crash")) == "satellite_crash_visit", "C: der Ort ist danach weiter ohne Auftrag anfliegbar")

func _finish() -> void:
	print("CAMPAIGN_OPEN_OUTPOSTS passed=%d failed=%d" % [_passed, _failed])
	await super._finish()
