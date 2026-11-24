extends SceneTree
## Windbruch als freier Kampf-Ort (24.11.2026), kopflos und rechnend. Teil 1: die Garnison.
##  - ohne angenommenen Kampagnenauftrag waehlt der Anflug das freie Szenario windbruch_free_camp, mit angenommenem Auftrag nur dessen Szenario;
##  - Gegnerzahl = 2 x Wache des Kampagnenauftrags, Bewaffnung eine Stufe hoeher (Gewehr/MPi), keine Heavy-Waffen, Haelfte haelt, Haelfte geht Streife;
##  - jeder neue Besuch ist wieder vollzaehlig (Szenario wird je Besuch frisch geladen; der Zustand der Kampagne aendert sich durch den Besuch nicht);
##  - kein Pflichtziel: kein Zeitlimit, Abflug ohne Kampf ist kein Fehlschlag (der Auftragsstand bleibt unberuehrt).
## Schlusszeile: WINDBRUCH_GARRISON passed=<n> failed=<m>

const CAMPAIGN_STATE = preload("res://scripts/core/singleplayer_campaign_state.gd")
const SCENARIO_DATA = preload("res://scripts/mission/mission_scenario_data.gd")
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const BOUNTY_ORDER := "bounty:rebels"
var _seq := 0
const LOCATION := "fortified_outpost"
const FREE_SCENARIO := "windbruch_free_camp"
const CAMPAIGN_SCENARIO := "outpost_chip_recovery"
## Stufen der Waffenkennungen (Vergleich "eine Stufe besser"); Heavy-Waffen stehen absichtlich nicht drin.
const WEAPON_TIER := {"pistol": 0, "sidearm": 0, "smg": 1, "rifle": 2}
const HEAVY := ["rocket_launcher", "rail_gun", "sniper"]

var passed := 0
var failed := 0

func _check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		print("ROT: ", label)

func _read(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}

func _enemy_count(scenario: Dictionary) -> int:
	var n := 0
	for g: Dictionary in Array(scenario.get("enemy_groups", [])): n += Array(g.get("enemy_ids", [])).size()
	return n

func _weapons(scenario: Dictionary) -> Array:
	var result: Array = []
	for g: Dictionary in Array(scenario.get("enemy_groups", [])):
		for _i in Array(g.get("enemy_ids", [])): result.append(String(Dictionary(g.get("tactics", {})).get("weapon_id", "")))
	return result

func _best_light_tier(weapons: Array) -> int:
	var best := -1
	for w in weapons:
		if WEAPON_TIER.has(String(w)): best = maxi(best, int(WEAPON_TIER[String(w)]))
	return best

func _initialize() -> void:
	_state_part()
	_scenario_part()
	_bounty_part()
	_count_part()
	_chest_part()
	_report_part()
	print("WINDBRUCH_GARRISON passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)

func _state_part() -> void:
	var cs: RefCounted = CAMPAIGN_STATE.new()
	cs.configure()
	_check(String(cs.open_garrison_scenario_id(LOCATION)) == FREE_SCENARIO, "Ohne Auftrag waehlt Windbruch das freie Szenario")
	_check(bool(cs.validate_location_visit(LOCATION).get("ok", false)), "Windbruch ist ohne Auftrag anfliegbar")
	_check(String(cs.open_garrison_scenario_id("trade_outpost")) == "" and String(cs.open_garrison_scenario_id("satellite_crash")) == "" and String(cs.open_garrison_scenario_id("polisa")) == "", "Andere Orte haben keine Garnison")
	# Kampagnenauftrag angenommen (Zustand direkt gesetzt: der Weg dorthin ist hier nicht das Thema): nur dessen Szenario.
	var jobs: Dictionary = cs.get("_jobs")
	var before_status := String(jobs[CAMPAIGN_SCENARIO].status)
	for status in ["accepted", "active", "pending_upload"]:
		jobs[CAMPAIGN_SCENARIO].status = status
		_check(String(cs.open_garrison_scenario_id(LOCATION)) == "", "Mit Auftrag im Stand %s ist die Garnison nicht da" % status)
	jobs[CAMPAIGN_SCENARIO].status = "offered"
	_check(String(cs.open_garrison_scenario_id(LOCATION)) == FREE_SCENARIO, "Nach Abgabe/Rueckzug des Auftrags (wieder angeboten) ist die Garnison wieder da")
	jobs[CAMPAIGN_SCENARIO].status = "completed"
	_check(String(cs.open_garrison_scenario_id(LOCATION)) == FREE_SCENARIO, "Auch nach abgeschlossenem Auftrag ist Windbruch ein wiederholbarer Kampf-Ort")
	jobs[CAMPAIGN_SCENARIO].status = before_status
	# Wiederholbar: der zweite Besuch sieht denselben Stand, der Besuch aendert nichts am Auftragsstand.
	var snapshot_a: String = JSON.stringify(cs.get_campaign_snapshot().jobs)
	var first := String(cs.open_garrison_scenario_id(LOCATION))
	var second := String(cs.open_garrison_scenario_id(LOCATION))
	_check(first == second and snapshot_a == JSON.stringify(cs.get_campaign_snapshot().jobs), "Zweiter Besuch: gleiches Szenario, Auftragsstand unveraendert (kein Fehlschlag durch Abflug ohne Kampf)")
	var free_play: RefCounted = CAMPAIGN_STATE.new()
	free_play.configure({}, {}, false)
	_check(String(free_play.open_garrison_scenario_id(LOCATION)) == "", "Ausserhalb der Kampagne gibt es keine Sonderregel")

func _scenario_part() -> void:
	var campaign := _read("res://data/mission_scenarios/%s.json" % CAMPAIGN_SCENARIO)
	var free := _read("res://data/mission_scenarios/%s.json" % FREE_SCENARIO)
	var map_ok := String(free.get("map_file_path", "")) == String(campaign.get("map_file_path", "-"))
	_check(map_ok, "Freies Lager liegt auf der Karte des Kampagnenauftrags")
	var guard := _enemy_count(campaign)
	var camp := _enemy_count(free)
	# Gesamtzahl der Gegner im Kampagnenauftrag: alle Gruppen UND alle Wellen (Wellen x Einheiten je Welle darf nicht mehr sein als die Gruppen).
	var campaign_waves: Dictionary = Dictionary(campaign.get("wave_config", {}))
	_check(int(campaign_waves.get("wave_count", 1)) * int(campaign_waves.get("units_per_wave", 0)) == guard, "Kampagnenwache: Gruppen (%d) und Wellen (%d x %d) ergeben dieselbe Gesamtzahl" % [guard, int(campaign_waves.get("wave_count", 1)), int(campaign_waves.get("units_per_wave", 0))])
	_check(guard == 2 and camp == 2 * guard, "Gegnerzahl = 2 x Wache (%d x 2 = %d)" % [guard, camp])
	_check(int(Dictionary(free.get("wave_config", {})).get("units_per_wave", 0)) == camp and int(Dictionary(free.get("wave_config", {})).get("wave_count", 0)) == 1, "Eine Welle mit allen Gegnern sofort (vollzaehlig bei jedem Besuch)")
	var free_weapons := _weapons(free)
	var campaign_weapons := _weapons(campaign)
	var heavy_free := false
	for w in free_weapons: heavy_free = heavy_free or HEAVY.has(String(w))
	_check(not heavy_free, "Keine Raketenwerfer/Schwerwaffen bei den Gegnern des Lagers")
	_check(not free_weapons.has("pistol") and not free_weapons.has(""), "Keine Pistolen im Lager")
	var campaign_light: Array = []
	for w in campaign_weapons:
		if not HEAVY.has(String(w)): campaign_light.append(w)
	_check(_best_light_tier(free_weapons) > _best_light_tier(campaign_light), "Bewaffnung eine Stufe hoeher (%s gegen %s)" % [free_weapons, campaign_light])
	var hold := 0
	var patrol := 0
	var bound: Dictionary = {}
	for b: Dictionary in Array(free.get("patrol_bindings", [])): bound[String(b.get("target_id", ""))] = String(b.get("patrol_path_id", ""))
	var map_text := FileAccess.get_file_as_string(String(free.get("map_file_path", "")))
	for g: Dictionary in Array(free.get("enemy_groups", [])):
		var style := String(Dictionary(g.get("tactics", {})).get("advance_style", ""))
		var n := Array(g.get("enemy_ids", [])).size()
		_check(map_text.contains('"%s"' % String(g.get("spawn_marker_id", "-"))), "Marke %s gibt es auf der Karte" % String(g.get("spawn_marker_id", "")))
		if style == "hold": hold += n
		elif style == "patrol":
			patrol += n
			_check(bound.has(String(g.group_id)) and map_text.contains('"%s"' % String(bound[String(g.group_id)])), "Streife %s hat einen vorhandenen Weg der Karte" % String(g.group_id))
	_check(hold >= 1 and patrol >= 1 and hold + patrol == camp and hold == patrol, "Haelfte haelt (%d), Haelfte geht Streife (%d)" % [hold, patrol])
	_check(float(free.get("time_limit_seconds", 1.0)) <= 0.0, "Kein Zeitlimit: kein Fehlschlag durch Zeit")
	_check(String(Dictionary(free.get("vertical_slice", {})).get("scenario_kind", "")) == "singleplayer_visit", "Szenarioart ist ein Besuch (kein Auftrag, kein Ergebnis fuer einen Auftrag)")
	var jobs := _read("res://data/singleplayer/jobs.json")
	var job_scenarios: Array = []
	for id: String in jobs: job_scenarios.append(String(Dictionary(jobs[id]).get("scenario_id", "")))
	_check(not job_scenarios.has(FREE_SCENARIO), "Das freie Lager gehoert zu keinem Auftrag")
	var loaded = SCENARIO_DATA.load_from_file("res://data/mission_scenarios/%s.json" % FREE_SCENARIO)
	_check(loaded != null, "Szenario laesst sich laden")

# ---------- Teil 2: Kopfgeld ----------

func _supply() -> RefCounted:
	var s: RefCounted = SUPPLY.new()
	var offers: Dictionary = Dictionary(JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/trade_offers.json")))
	s.configure([], offers)
	s.register_craft("ship", 5.0)
	s.configure_inventory([], ["ship"])
	s.enable_standing_orders()
	return s

func _cmd(op: String, payload: Dictionary, rid: String = "") -> Dictionary:
	_seq += 1
	return {"contract_category": "singleplayer_supply", "operation": op, "payload": payload, "request_id": rid if not rid.is_empty() else "wb:%d" % _seq}

func _credits(s: RefCounted) -> int:
	return int(s.get_supply_snapshot().credits)

func _bounty_part() -> void:
	var orders: Dictionary = _read("res://data/singleplayer/standing_orders.json")
	var entry: Dictionary = {}
	for raw: Variant in Array(orders.get("orders", [])):
		if String(Dictionary(raw).get("id", "")) == BOUNTY_ORDER: entry = Dictionary(raw)
	_check(not entry.is_empty() and int(entry.get("pay_per_unit", 0)) == 50 and String(entry.get("kind", "")) == "bounty", "Dauerauftrag Rebellen hetzen steht in den Daten: 50 Credits je Ausgeschaltetem")
	var s: RefCounted = _supply()
	var start := _credits(s)
	# Ohne angenommenen Dauerauftrag: kein Credit.
	var none: Dictionary = s.apply_command(_cmd("bounty_payout", {"kills": 3}), {})
	_check(not bool(none.get("ok", true)) and _credits(s) == start, "Ohne angenommenen Dauerauftrag zahlt nichts (+0)")
	var snap: Dictionary = {}
	for e: Variant in s.get_standing_orders_snapshot():
		if String(Dictionary(e).id) == BOUNTY_ORDER: snap = Dictionary(e)
	_check(String(snap.get("status", "")) == "open" and String(snap.get("title", "")).contains("Rebellen hetzen"), "Auftrag ist im Smart Mobile annehmbar (offen, Titel Rebellen hetzen)")
	var acc: Dictionary = s.apply_command(_cmd("standing_accept", {"order_id": BOUNTY_ORDER}), {"location_id": "homebase", "craft_busy": true})
	_check(bool(acc.get("ok", false)) and _credits(s) == start, "Annahme ohne Handelsort und ohne Kosten")
	var again: Dictionary = s.apply_command(_cmd("standing_accept", {"order_id": BOUNTY_ORDER}), {})
	_check(not bool(again.get("ok", true)), "Zweite Annahme derselben Art wird abgelehnt (laeuft schon)")
	var paid: Dictionary = s.apply_command(_cmd("bounty_payout", {"kills": 3}, "wb:fixed"), {})
	_check(bool(paid.get("ok", false)) and int(paid.get("credits_added", 0)) == 150 and _credits(s) == start + 150, "Mit Dauerauftrag: 3 Ausgeschaltete = +150 Credits")
	_check(String(paid.get("line", "")) == "Kopfgeld: 3 × 50 = 150 Credits", "Abrechnungszeile: %s" % String(paid.get("line", "")))
	var replay: Dictionary = s.apply_command(_cmd("bounty_payout", {"kills": 3}, "wb:fixed"), {})
	_check(bool(replay.get("replayed", false)) and _credits(s) == start + 150, "Wiederholte Abrechnung (gleicher Beleg) bucht nichts doppelt")
	_check(not bool(s.apply_command(_cmd("bounty_payout", {"kills": 0}), {}).get("ok", true)) and _credits(s) == start + 150, "Null oder ungueltige Anzahl zahlt nichts")
	# Auftragsbelohnung bleibt getrennt: der Kopfgeld-Befehl beruehrt sie nicht, die Zeile ist eigen.
	_check(String(paid.get("order_id", "")) == BOUNTY_ORDER and not paid.has("reward"), "Kopfgeld ist eine eigene Buchung, getrennt von der Auftragsbelohnung")
	# Abgeben: kein Kopfgeld mehr, sofort wieder annehmbar (keine Frist).
	var ab: Dictionary = s.apply_command(_cmd("standing_abandon", {"order_id": BOUNTY_ORDER}), {})
	_check(bool(ab.get("ok", false)), "Abgeben geht")
	_check(not bool(s.apply_command(_cmd("bounty_payout", {"kills": 2}), {}).get("ok", true)) and _credits(s) == start + 150, "Nach Abgabe zahlt nichts mehr")
	var reacc: Dictionary = s.apply_command(_cmd("standing_accept", {"order_id": BOUNTY_ORDER}), {})
	_check(bool(reacc.get("ok", false)), "Sofort wieder annehmbar (keine Sperrzeit)")
	# Speichern/Laden: der angenommene Auftrag bleibt angenommen.
	var saved: Dictionary = s.export_state()
	var loaded: RefCounted = _supply()
	var restore: Dictionary = loaded.restore_state(saved) if loaded.has_method("restore_state") else {"ok": true}
	_check(bool(restore.get("ok", true)) and bool(loaded.apply_command(_cmd("bounty_payout", {"kills": 1}), {}).get("ok", false)), "Nach Speichern/Laden bleibt der Dauerauftrag angenommen")

# ---------- Teil 2: Zaehlung im Einsatz (echter Treiber, echte Einheiten) ----------

func _count_part() -> void:
	var driver = load("res://scripts/tests/mission_combat_loop_driver.gd").new()
	var fixture := Node.new()
	var units: Array = []
	for i in range(3):
		var unit = load("res://scripts/npc/test_unit.gd").new()
		unit.name = "E%d" % i
		fixture.add_child(unit)
		unit.set("unit_id", "camp_%02d" % i)
		unit.set("team_id", "team_bravo")
		units.append(unit)
	driver.name = "Driver"
	fixture.add_child(driver)
	driver.set("_hotpath_unit_cache_active", true)
	driver.set("_hotpath_enemy_units", [units[0], units[1]])
	driver.set("_enemy_team_tactics_states_by_group_id", {"camp_hold_yard": {"unit_ids": ["camp_00", "camp_01"]}})
	driver.call("_build_enemy_group_fit_counts")
	_check(int(driver.call("get_enemies_out_of_action_count")) == 0, "Kampfbereite Gegner zaehlen nicht als ausgeschaltet")
	units[0].call("apply_damage", 1000, {})
	driver.call("_build_enemy_group_fit_counts")
	driver.call("_build_enemy_group_fit_counts")
	_check(int(driver.call("get_enemies_out_of_action_count")) == 1, "Ein ausgeschalteter Gegner zaehlt einmal (auch bei wiederholter Auswertung)")
	# Er faellt aus der Taktik, bleibt gezaehlt; ein zweiter wird ausgeschaltet.
	driver.set("_enemy_team_tactics_states_by_group_id", {"camp_hold_yard": {"unit_ids": ["camp_01"]}})
	units[1].call("apply_damage", 1000, {})
	driver.call("_build_enemy_group_fit_counts")
	_check(int(driver.call("get_enemies_out_of_action_count")) == 2, "Aus der Taktik gefallene Gegner bleiben gezaehlt, kein Doppelzaehlen")
	# Spaete Welle: neue Einheit kommt kampfbereit hinzu (zaehlt erst, wenn sie ausgeschaltet wird).
	driver.set("_hotpath_enemy_units", [units[1], units[2]])
	driver.set("_enemy_team_tactics_states_by_group_id", {"camp_hold_yard": {"unit_ids": ["camp_01"]}, "late_wave": {"unit_ids": ["camp_02"]}})
	driver.call("_build_enemy_group_fit_counts")
	_check(int(driver.call("get_enemies_out_of_action_count")) == 2, "Spaete Welle kampfbereit: noch nicht gezaehlt")
	units[2].call("apply_damage", 1000, {})
	driver.call("_build_enemy_group_fit_counts")
	_check(int(driver.call("get_enemies_out_of_action_count")) == 3, "Spaete Welle ausgeschaltet: genau einmal mehr")
	# Abrechnung nur der Differenz.
	_check(int(driver.call("get_bounty_settled_count")) == 0, "Vor der Abrechnung ist nichts abgerechnet")
	driver.call("mark_bounty_settled", 2)
	_check(int(driver.call("get_enemies_out_of_action_count")) - int(driver.call("get_bounty_settled_count")) == 1, "Nach einer Teilabrechnung bleibt genau die Differenz offen")
	driver.call("mark_bounty_settled", 1)
	_check(int(driver.call("get_bounty_settled_count")) == 2, "Abgerechnete Zahl faellt nie zurueck (kein Doppelbuchen)")
	fixture.free()

# ---------- Teil 3: Beutekiste ----------

func _chest_part() -> void:
	var scenario = SCENARIO_DATA.load_from_file("res://data/mission_scenarios/%s.json" % FREE_SCENARIO)
	_check(scenario != null, "Kiste: Szenario laedt")
	if scenario == null: return
	var point: Dictionary = {}
	for p: Variant in Array(Dictionary(scenario.call("get_vertical_slice")).get("interaction_points", [])):
		if String(Dictionary(p).get("interaction_id", "")) == "camp_chest": point = Dictionary(p)
	_check(not point.is_empty(), "Kiste: Benutzen-Stelle camp_chest ist da")
	var map_text := FileAccess.get_file_as_string("res://maps/windbruch_outpost.json")
	_check(map_text.contains('"%s"' % String(point.get("marker_id", "-"))) and not ["ship_return", "spawn_alpha"].has(String(point.get("marker_id", ""))), "Kiste: vorhandene Marke der Karte (%s), nicht am Landeplatz" % String(point.get("marker_id", "")))
	var pool: Array = Array(point.get("grants_pool", []))
	_check(pool.size() == 4, "Kiste: vier Fundmoeglichkeiten (Bauplan ausgelassen: es gibt ihn nicht als Gegenstand)")
	var wanted := {"rifle:1": true, "armor_medium:1": true, "rocket_launcher:1|ammo_rocket:2": true, "ammo_rocket:4": true}
	var seen: Dictionary = {}
	var always_one := true
	var stable := true
	for roll in range(200):
		var grants: Array = scenario.call("get_interaction_grants", "camp_chest", roll)
		var parts := PackedStringArray()
		for g: Dictionary in grants: parts.append("%s:%d" % [String(g.item_id), int(g.quantity)])
		var key := "|".join(parts)
		always_one = always_one and wanted.has(key)
		seen[key] = true
		stable = stable and key == "|".join(_key_of(scenario.call("get_interaction_grants", "camp_chest", roll)))
	_check(always_one, "Kiste: jeder Fund ist genau eine der vorgesehenen Moeglichkeiten")
	_check(stable, "Kiste: gleicher Startwert gibt denselben Fund")
	_check(seen.size() == 4, "Kiste: alle vier Funde kommen vor (%d gesehen)" % seen.size())
	_check(Array(scenario.call("get_interaction_grants", "camp_chest")).is_empty(), "Kiste: ohne Startwert gibt es nichts")
	# Buchung je Besuch: eigene Belege, zweiter Besuch bucht wieder; im selben Besuch doppelt gibt nichts.
	var s: RefCounted = _supply()
	var rid := "campaign-cargo:loot:%s:camp_chest:%d:0:0"
	var ctx := {"campaign_authorized": true}
	var first: Dictionary = s.apply_command(_cmd("campaign_cargo", {"container_id": "craft:ship", "item_id": "rifle", "amount": 1}, "campaign-cargo:loot:windbruch_free_camp:camp_chest:0:0:0"), ctx)
	_check(bool(first.get("ok", false)) and int(s.count_requests("campaign-cargo:loot:windbruch_free_camp:camp_chest:", ":0:0")) == 1, "Kiste: erster Besuch gebucht, Zaehler 1")
	var twice: Dictionary = s.apply_command(_cmd("campaign_cargo", {"container_id": "craft:ship", "item_id": "rifle", "amount": 1}, "campaign-cargo:loot:windbruch_free_camp:camp_chest:0:0:0"), ctx)
	_check(bool(twice.get("replayed", false)), "Kiste: zweites Buchen im selben Besuch ist ein Replay (gibt nichts)")
	var second: Dictionary = s.apply_command(_cmd("campaign_cargo", {"container_id": "craft:ship", "item_id": "rifle", "amount": 1}, "campaign-cargo:loot:windbruch_free_camp:camp_chest:1:0:0"), ctx)
	_check(bool(second.get("ok", false)) and not bool(second.get("replayed", false)) and int(s.count_requests("campaign-cargo:loot:windbruch_free_camp:camp_chest:", ":0:0")) == 2, "Kiste: zweiter Besuch bucht wieder (eigener Beleg)")
	for item in ["rocket_launcher", "ammo_rocket", "armor_medium"]:
		var r: Dictionary = s.apply_command(_cmd("campaign_cargo", {"container_id": "craft:ship", "item_id": item, "amount": 1}), ctx)
		_check(bool(r.get("ok", false)), "Kiste: %s laesst sich ins Schiff buchen" % item)

func _key_of(grants: Array) -> PackedStringArray:
	var parts := PackedStringArray()
	for g: Dictionary in grants: parts.append("%s:%d" % [String(g.item_id), int(g.quantity)])
	return parts

# ---------- Sichtbare Abrechnung beim freien Besuch ----------

func _report_part() -> void:
	var debrief: GDScript = load("res://scripts/meta/debrief_screen.gd")
	_check(String(debrief.call("build_bounty_text", {"bounty": {"line": "Kopfgeld: 3 × 50 = 150 Credits"}})) == "Kopfgeld: 3 × 50 = 150 Credits", "Meldung: Kopfgeld-Zeile kommt unveraendert")
	var chest: String = String(debrief.call("build_chest_text", [{"item_id": "rifle", "quantity": 1, "left_behind": 0}]))
	_check(chest.begins_with("Kiste: 1 ") and chest.length() > 10, "Meldung: Kistenfund als Zeile (%s)" % chest)
	var rockets: String = String(debrief.call("build_chest_text", [{"item_id": "rocket_launcher", "quantity": 1, "left_behind": 0}, {"item_id": "ammo_rocket", "quantity": 2, "left_behind": 0}]))
	_check(rockets.contains(", 2 "), "Meldung: Raketenwerfer mit zwei Raketen in einer Zeile (%s)" % rockets)
	_check(String(debrief.call("build_chest_text", [])) == "", "Meldung: ohne Fund keine Zeile")
	var flow_src := FileAccess.get_file_as_string("res://scripts/meta/meta_layer_flow.gd")
	_check(flow_src.count("_report_visit_settlement(visit_bounty, visit_loot)") == 2 and flow_src.contains("_show_save_feedback(\"  \".join(lines))"), "Meldung: Abflug und Heimflug von einem freien Ort melden ueber die Zeile am Bildschirmrand")
