extends SceneTree
## Windbruch als freier Kampf-Ort (24.11.2026), kopflos und rechnend. Teil 1: die Garnison.
##  - ohne angenommenen Kampagnenauftrag waehlt der Anflug das freie Szenario windbruch_free_camp, mit angenommenem Auftrag nur dessen Szenario;
##  - Gegnerzahl = 2 x Wache des Kampagnenauftrags, Bewaffnung eine Stufe hoeher (Gewehr/MPi), keine Heavy-Waffen, Haelfte haelt, Haelfte geht Streife;
##  - jeder neue Besuch ist wieder vollzaehlig (Szenario wird je Besuch frisch geladen; der Zustand der Kampagne aendert sich durch den Besuch nicht);
##  - kein Pflichtziel: kein Zeitlimit, Abflug ohne Kampf ist kein Fehlschlag (der Auftragsstand bleibt unberuehrt).
## Schlusszeile: WINDBRUCH_GARRISON passed=<n> failed=<m>

const CAMPAIGN_STATE = preload("res://scripts/core/singleplayer_campaign_state.gd")
const SCENARIO_DATA = preload("res://scripts/mission/mission_scenario_data.gd")
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
