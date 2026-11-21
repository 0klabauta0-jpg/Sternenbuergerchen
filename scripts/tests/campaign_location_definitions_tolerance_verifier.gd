extends SceneTree
## Ein Basisstand ueberlebt Aenderungen an den Ortsdaten (Abschnitt SB, Spielrunde 21.11.2026).
## Ausgangspunkt ist ein gueltiger Basisstand (Fixture von Main 639a49d65, auf die heutigen Ortsdaten gebracht, mit
## belegtem Ortszustand an satellite_crash und trade_outpost). Jede Abweichung wird im GESPEICHERTEN Stand hergestellt, nicht in
## den Daten, in eine Datei geschrieben und ueber STORE.load_checkpoint geladen (der Weg von "Fortsetzen").
##   a) anderer Anzeigename            -> laedt, Stand unveraendert
##   b) andere Sternkartenposition     -> laedt, Stand unveraendert
##   c) anderer Kartenpfad eines Ortes -> laedt, dieser Ort beginnt frisch (Ortsressourcen), alles andere gleich, eine Meldung
##   d) Felder, an denen Gespeichertes haengt (Dienste, Landeplaetze, Szenario, ...) -> stale_campaign_definitions
##   e) Ort fehlt oder ist zusaetzlich   -> stale_campaign_definitions (nur polisa darf fehlen)
##   f) unveraenderter Stand           -> laedt wie bisher, Inhalt und Datei gleich
##   g) Besitzer-Ebene: restore_state meldet die Orte mit anderem Kartenpfad (der Einsatz-Zwischenstand lehnt sie ab)
const STORE = preload("res://scripts/meta/campaign_checkpoint_store.gd")
const CAMPAIGN = preload("res://scripts/core/singleplayer_campaign_state.gd")
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const DISPLAY = preload("res://scripts/mission/campaign_display_catalog.gd")
const FIXTURE := "res://scripts/tests/fixtures/main_639a49d65_checkpoint.json"
const DIR := "user://campaigns/location_tolerance_test/"
const RESOURCES := "res://data/singleplayer/location_resources.json"

var _passed := 0
var _failed := 0
var _current: Dictionary = {}
var _case := 0

func _initialize() -> void: call_deferred("_run")

func _check(ok: bool, label: String) -> bool:
	if ok:
		_passed += 1
		print("PASS: ", label)
	else:
		_failed += 1
		print("FAIL: ", label)
	return ok

func _run() -> void:
	var isolated := OS.get_environment("POLISA_TEST_PROFILE").simplify_path().replace("\\", "/").to_lower()
	var user_dir := OS.get_user_data_dir().simplify_path().replace("\\", "/").to_lower()
	if isolated.is_empty() or not user_dir.begins_with(isolated + "/"):
		print("FAIL: isolated POLISA_TEST_PROFILE required")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	var owner = CAMPAIGN.new()
	if not _check(bool(owner.configure().get("ok", false)), "Besitzer konfiguriert mit den heutigen Ortsdaten"):
		_finish()
		return
	_current = Dictionary(owner.get_campaign_snapshot().locations).duplicate(true)
	var base := _base()
	if not _check(bool(STORE.validate_payload(base).get("ok", false)), "Ausgangsstand ist gueltig (%s)" % [STORE.validate_payload(base).get("reason", "")]):
		_finish()
		return
	_unchanged(base)
	_display_name(base)
	_region_position(base)
	_relocated_map(base)
	_relocated_map_all_places(base)
	_strict_fields(base)
	_places_missing_or_added(base)
	_owner_level(base)
	_finish()

func _finish() -> void:
	print("CAMPAIGN_LOCATION_TOLERANCE passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

# ---------------------------------------------------------------- Aufbau

func _base() -> Dictionary:
	var fixture: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	var base: Dictionary = Dictionary(fixture).duplicate(true)
	base.campaign.locations = _current.duplicate(true)
	_set_site(base, "satellite_crash", "iron_ridge_01", true, 8)
	_set_site(base, "satellite_crash", "b_benit_01", true, 0)
	_set_site(base, "trade_outpost", "a_benit_01", true, 0)
	return base

## Ortszustand steht zweimal im Stand: oben (location_resources) und beim Besitzer der Vorraete (supply.location_resources).
func _set_site(payload: Dictionary, place: String, site: String, discovered: bool, remaining: int) -> void:
	payload.location_resources[place].sites[site] = {"discovered": discovered, "remaining": remaining}
	payload.supply.location_resources[place][site] = {"discovered": discovered, "remaining": remaining}

func _fresh_sites(place: String) -> Dictionary:
	var definitions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RESOURCES))
	var sites := {}
	for site in Dictionary(definitions.get(place, {})):
		sites[site] = {"discovered": false, "remaining": int(definitions[place][site].quantity)}
	return sites

func _norm(value: Variant) -> String:
	return JSON.stringify(JSON.parse_string(JSON.stringify(value)), "", true)

## Schreibt den Stand in eine Datei und laedt ihn wie "Fortsetzen". Rueckgabe: Ergebnis von load_checkpoint plus "sha_before"/"sha_after".
func _load(payload: Dictionary) -> Dictionary:
	_case += 1
	var path := DIR + "case_%d.json" % _case
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(payload, "\t", true))
	file.close()
	var before := FileAccess.get_sha256(path)
	var result: Dictionary = STORE.load_checkpoint(path)
	result["sha_unchanged"] = FileAccess.get_sha256(path) == before
	return result

func _rejected(result: Dictionary) -> bool:
	return not bool(result.get("ok", false)) and String(result.get("reason", "")) == "stale_campaign_definitions"

## Alles ausser Ortsblock, Ortsressourcen und Vorrats-Ortsressourcen eines Ortes (zum Vergleich "alles andere bleibt").
func _rest(payload: Dictionary, places: Array = []) -> String:
	var copy: Dictionary = payload.duplicate(true)
	copy.campaign.erase("locations")
	for place in places:
		copy.location_resources.erase(place)
		copy.supply.location_resources.erase(place)
	return _norm(copy)

# ---------------------------------------------------------------- f) unveraendert

func _unchanged(base: Dictionary) -> void:
	var result := _load(base)
	_check(bool(result.get("ok", false)), "f) unveraenderter Stand laedt (%s)" % [result.get("reason", "")])
	if not bool(result.get("ok", false)): return
	_check(_norm(result.payload) == _norm(base), "f) Inhalt gleich")
	_check(Array(result.get("relocated_location_ids", [])).is_empty() and Array(result.get("notices", [])).is_empty(), "f) keine Ortsmeldung")
	_check(bool(result.sha_unchanged), "f) Datei beim Laden nicht veraendert (Pruefsumme gleich)")

# ---------------------------------------------------------------- a) und b) Darstellung

func _display_name(base: Dictionary) -> void:
	var saved: Dictionary = base.duplicate(true)
	saved.campaign.locations.homebase.name = "Anderer Name der Heimatbasis"
	saved.campaign.locations.satellite_crash.name = "Anderer Name der Absturzstelle"
	var result := _load(saved)
	_check(bool(result.get("ok", false)), "a) anderer Anzeigename laedt (%s)" % [result.get("reason", "")])
	if not bool(result.get("ok", false)): return
	_check(_rest(result.payload) == _rest(base), "a) Stand unveraendert (nur der Ortsblock darf sich unterscheiden)")
	_check(Array(result.get("relocated_location_ids", [])).is_empty(), "a) kein Ort gilt als neu aufgesetzt")
	_check(_norm(result.payload.location_resources) == _norm(base.location_resources), "a) Ortsressourcen unveraendert")
	var restored = CAMPAIGN.new()
	_check(bool(restored.restore_state(result.payload.campaign).get("ok", false)) and String(restored.get_campaign_snapshot().locations.homebase.name) == String(_current.homebase.name), "a) Besitzer zeigt den heutigen Namen")

func _region_position(base: Dictionary) -> void:
	var saved: Dictionary = base.duplicate(true)
	saved.campaign.locations.satellite_crash.region_position = [0.11, 0.97]
	saved.campaign.locations.trade_outpost.region_position = [0.0, 0.0]
	var result := _load(saved)
	_check(bool(result.get("ok", false)), "b) andere Sternkartenposition laedt (%s)" % [result.get("reason", "")])
	if not bool(result.get("ok", false)): return
	_check(_rest(result.payload) == _rest(base), "b) Stand unveraendert")
	_check(Array(result.get("relocated_location_ids", [])).is_empty(), "b) kein Ort gilt als neu aufgesetzt")
	var restored = CAMPAIGN.new()
	_check(bool(restored.restore_state(result.payload.campaign).get("ok", false)) and restored.get_campaign_snapshot().locations.satellite_crash.region_position == _current.satellite_crash.region_position, "b) Besitzer zeigt die heutige Position")

# ---------------------------------------------------------------- c) Kartenpfad

func _relocated_map(base: Dictionary) -> void:
	var saved: Dictionary = base.duplicate(true)
	saved.campaign.locations.satellite_crash.map_file_path = "res://maps/satellite_crash_site_alt.json"
	var result := _load(saved)
	_check(bool(result.get("ok", false)), "c) anderer Kartenpfad laedt (%s)" % [result.get("reason", "")])
	if not bool(result.get("ok", false)): return
	var payload: Dictionary = result.payload
	_check(Array(result.get("relocated_location_ids", [])) == ["satellite_crash"], "c) genau satellite_crash gilt als neu aufgesetzt")
	var message := ""
	if Array(result.get("notices", [])).size() == 1: message = String(result.notices[0])
	var place := DISPLAY.location_name("satellite_crash", Dictionary(_current.satellite_crash))
	_check(message == "Die Karte von %s wurde überarbeitet; der Ort beginnt frisch." % place, "c) einmalige Meldung nennt den Ort (%s)" % [message])
	var fresh := _fresh_sites("satellite_crash")
	_check(not fresh.is_empty() and _norm(payload.location_resources.satellite_crash) == _norm({"version": 1, "location_id": "satellite_crash", "sites": fresh}), "c) Ortsressourcen oben: Anfangszustand der neuen Karte")
	_check(_norm(payload.supply.location_resources.satellite_crash) == _norm(fresh), "c) Ortsressourcen beim Besitzer der Vorraete: Anfangszustand")
	_check(_norm(payload.location_resources.trade_outpost) == _norm(base.location_resources.trade_outpost) and _norm(payload.supply.location_resources.trade_outpost) == _norm(base.supply.location_resources.trade_outpost), "c) trade_outpost (anderer Ort mit Zustand) unberuehrt")
	_check(base.location_resources.trade_outpost.sites.a_benit_01.discovered == true and payload.location_resources.trade_outpost.sites.a_benit_01.discovered == true, "c) Gegenprobe: trade_outpost hat wirklich einen belegten Zustand")
	_check(_rest(payload, ["satellite_crash"]) == _rest(base, ["satellite_crash"]), "c) Kader, Guthaben, Lager, Auftraege, Fortschritt gleich")
	_check(payload.campaign.locations.satellite_crash.map_file_path == _current.satellite_crash.map_file_path, "c) Stand nennt den heutigen Kartenpfad")
	_check(bool(result.sha_unchanged), "c) Datei beim Laden nicht veraendert")
	var supply = SUPPLY.new()
	var campaign = CAMPAIGN.new()
	_check(bool(supply.restore_state(payload.supply).get("ok", false)) and bool(campaign.restore_state(payload.campaign).get("ok", false)), "c) Besitzer nehmen den neu aufgesetzten Stand an")
	_check(bool(STORE.validate_payload(payload).get("ok", false)), "c) neu aufgesetzter Stand besteht die Pruefung des Speichers")
	_check(bool(STORE.validate_payload(saved).get("ok", false)), "c) Stand mit altem Kartenpfad besteht die Pruefung des Speichers (alte Staende bleiben pruefbar)")
	# Kartenpfad und ein streng geprueftes Feld an einem ANDEREN Ort: das Neu-Aufsetzen verdeckt die strenge Abweichung nicht.
	var mixed: Dictionary = saved.duplicate(true)
	mixed.campaign.locations.homebase.services = ["personnel", "jobs", "refuel", "trade"]
	_check(_rejected(_load(mixed)), "c) Kartenpfad an einem Ort plus Dienste an einem anderen -> abgelehnt")
	# Kein gueltiger Kartenpfad: nicht annehmen.
	for broken in ["", "maps/satellite_crash_site.json", "res://maps/satellite_crash_site.txt", "res://data/satellite_crash_site.json"]:
		var invalid: Dictionary = base.duplicate(true)
		invalid.campaign.locations.satellite_crash.map_file_path = broken
		_check(_rejected(_load(invalid)), "c) ungueltiger Kartenpfad '%s' -> abgelehnt" % broken)
	var typed: Dictionary = base.duplicate(true)
	typed.campaign.locations.satellite_crash.map_file_path = 7
	_check(_rejected(_load(typed)), "c) Kartenpfad kein Text -> abgelehnt")

## Der echte Altstand: der Kartenpfad von fortified_outpost (kein Ortszustand) wird angenommen, der Rest bleibt.
func _relocated_map_all_places(base: Dictionary) -> void:
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	var result := _load(fixture)
	_check(bool(result.get("ok", false)), "c) echter Altstand (Main 639a49d65) laedt (%s)" % [result.get("reason", "")])
	if not bool(result.get("ok", false)): return
	_check(Array(result.get("relocated_location_ids", [])) == ["fortified_outpost"], "c) echter Altstand: nur fortified_outpost mit anderem Kartenpfad")
	_check(result.payload.campaign.locations.fortified_outpost.map_file_path == "res://maps/windbruch_outpost.json", "c) echter Altstand: heutiger Kartenpfad")
	_check(_rest(result.payload) == _rest(fixture), "c) echter Altstand: alles ausser dem Ortsblock gleich")

# ---------------------------------------------------------------- d) streng

func _strict_fields(base: Dictionary) -> void:
	var cases := [
		["Dienste (services) eines Ortes", "satellite_crash", "services", ["trade"]],
		["Landeplaetze (landing_pad_ids)", "homebase", "landing_pad_ids", ["homebase_pad_01"]],
		["Szenariopfad (scenario_file_path)", "trade_outpost", "scenario_file_path", "res://data/mission_scenarios/satellite_recovery.json"],
		["Orts-ID im Block (id)", "homebase", "id", "homebase_2"],
		["freier Besuch (free_visit) bei polisa", "polisa", "free_visit", false],
		["unbekanntes Zusatzfeld", "homebase", "orbit_id", "orbit_x"]]
	for entry in cases:
		var saved: Dictionary = base.duplicate(true)
		saved.campaign.locations[entry[1]][entry[2]] = entry[3]
		var result := _load(saved)
		_check(_rejected(result), "d) %s geaendert -> stale_campaign_definitions (%s)" % [entry[0], result.get("reason", "ok")])
	# Fehlende Pflichtfelder im Ortsblock gelten nicht als Darstellung.
	for field in ["name", "region_position", "map_file_path", "services", "landing_pad_ids"]:
		var saved: Dictionary = base.duplicate(true)
		saved.campaign.locations.homebase.erase(field)
		_check(_rejected(_load(saved)), "d) Feld %s fehlt im Ortsblock -> abgelehnt" % field)
	# Darstellungsfelder mit unbrauchbarem Inhalt werden nicht stillschweigend angenommen.
	var empty_name: Dictionary = base.duplicate(true)
	empty_name.campaign.locations.homebase.name = ""
	_check(_rejected(_load(empty_name)), "d) leerer Name -> abgelehnt")
	var bad_position: Dictionary = base.duplicate(true)
	bad_position.campaign.locations.homebase.region_position = [0.5]
	_check(_rejected(_load(bad_position)), "d) Position ohne zwei Werte -> abgelehnt")
	# Auftragsbindung: der Zielort eines Auftrags im Stand bleibt streng.
	var job_moved: Dictionary = base.duplicate(true)
	job_moved.campaign.jobs.outpost_chip_recovery.location_id = "trade_outpost"
	var job_result := _load(job_moved)
	_check(not bool(job_result.get("ok", false)), "d) Auftrag an einem anderen Ort -> abgelehnt (%s)" % [job_result.get("reason", "ok")])

# ---------------------------------------------------------------- e) Ort fehlt / zusaetzlich

func _places_missing_or_added(base: Dictionary) -> void:
	for place in ["satellite_crash", "homebase", "fortified_outpost"]:
		var saved: Dictionary = base.duplicate(true)
		saved.campaign.locations.erase(place)
		var result := _load(saved)
		_check(_rejected(result), "e) Ort %s fehlt -> stale_campaign_definitions (%s)" % [place, result.get("reason", "ok")])
	var added: Dictionary = base.duplicate(true)
	added.campaign.locations["extra_place"] = Dictionary(_current.homebase).duplicate(true)
	added.campaign.locations.extra_place.id = "extra_place"
	_check(_rejected(_load(added)), "e) zusaetzlicher Ort -> abgelehnt")
	var without_polisa: Dictionary = base.duplicate(true)
	without_polisa.campaign.locations.erase("polisa")
	_check(bool(_load(without_polisa).get("ok", false)), "e) die schon geduldete Ausnahme polisa darf weiter fehlen")

# ---------------------------------------------------------------- g) Besitzer

func _owner_level(base: Dictionary) -> void:
	var saved: Dictionary = base.duplicate(true)
	saved.campaign.locations.satellite_crash.map_file_path = "res://maps/satellite_crash_site_alt.json"
	saved.campaign.locations.homebase.name = "Anderer Name"
	var owner = CAMPAIGN.new()
	var result: Dictionary = owner.restore_state(saved.campaign)
	_check(bool(result.get("ok", false)), "g) restore_state nimmt den Stand mit anderem Kartenpfad und Namen an (%s)" % [result.get("reason", "")])
	_check(Array(result.get("relocated_location_ids", [])) == ["satellite_crash"], "g) restore_state nennt die Orte mit anderem Kartenpfad (daran lehnt der Einsatz-Zwischenstand ab)")
	var plain = CAMPAIGN.new()
	var plain_result: Dictionary = plain.restore_state(base.campaign)
	_check(plain_result == {"ok": true}, "g) ohne Abweichung bleibt das Ergebnis genau {ok:true}")
	var strict: Dictionary = base.duplicate(true)
	strict.campaign.locations.satellite_crash.services = []
	var strict_result: Dictionary = CAMPAIGN.new().restore_state(strict.campaign)
	_check(not bool(strict_result.get("ok", true)) and String(strict_result.get("reason", "")) == "stale_campaign_definitions", "g) restore_state lehnt ein streng geprueftes Feld mit stale_campaign_definitions ab")
