extends RefCounted
## Campaign entry/checkpoint adapter. No writes to the Skirmish roster store.

const PRESETS = preload("res://scripts/npc/unit_roster_presets.gd")
const STORE = preload("res://scripts/meta/campaign_checkpoint_store.gd")
const ACTIVE_STORE = preload("res://scripts/meta/campaign_active_checkpoint_store.gd")
const BASE_MAP := "res://maps/campaign_intro_base.json"
const HEX_AUTOSAVE_INTERVAL_MSEC := 5 * 60 * 1000
const HEX_AUTOSAVE_RETRY_MSEC := 1000
var entry: Dictionary = {}
var checkpoint: Dictionary = {}
var last_save_signature := ""
var error_message := ""
var campaign_run_id := ""
var active_pending: Dictionary = {}
var active_restore_in_progress := false
var _hex_export_scope := ""
var _hex_export_msec: int = -1
var _hex_failed_scope := ""
var _hex_failed_msec: int = -1
var _hex_failed_result: Dictionary = {}
var _retired_active_sha256 := ""
var _retire_active_on_home_save := false

func configure(flow: Node, request: Dictionary) -> void:
	var run_source: Dictionary = {}
	entry = request.duplicate(true)
	var action := String(request.get("action", "new"))
	_retire_active_on_home_save = action == "new"
	if action in ["continue", "continue_home"]:
		var loaded: Dictionary = STORE.load_checkpoint()
		if not bool(loaded.get("ok", false)):
			error_message = "Kampagnenstand konnte nicht geladen werden. Zurueck zum Menue."
			return
		if loaded.payload.has("hex_tactical"):
			var adapter = load("res://scripts/meta/singleplayer_runtime_adapter.gd")
			var preflight: Dictionary = adapter.preflight_campaign_hex_checkpoint(flow, loaded.payload)
			if not preflight.get("ok", false):
				error_message = "Hex-Kampagnenstand passt nicht zur aktuellen Heimatbasis: " + String(preflight.get("reason", "checkpoint_invalid"))
				return
		# Orte, deren Karte seit dem Speichern ueberarbeitet wurde, beginnen frisch (Speicher: adopt_relocated_maps). Einmalige Meldung:
		# Es gibt beim Laden noch keinen Meldeweg zum Spieler, darum ins Protokoll und als Meta "campaign_load_notices" am Flow.
		var load_notices: Array = Array(loaded.get("notices", []))
		for notice in load_notices: print("Kampagnenstand: ", notice)
		if not load_notices.is_empty(): flow.set_meta("campaign_load_notices", load_notices.duplicate())
		checkpoint = Dictionary(loaded.payload).duplicate(true)
		_migrate_known_main_starter(checkpoint)
		run_source = checkpoint.duplicate(true)
		_retired_active_sha256 = String(checkpoint.get("retired_active_checkpoint_sha256", ""))
		if action == "continue" and FileAccess.file_exists(ACTIVE_STORE.DEFAULT_PATH) and FileAccess.get_sha256(ACTIVE_STORE.DEFAULT_PATH) != _retired_active_sha256:
			var bootstrap = load("res://scripts/mission/campaign_active_bootstrap_validation.gd")
			var active: Dictionary = ACTIVE_STORE.load_checkpoint(bootstrap.validate)
			if not active.get("ok",false):
				# A newer home save supersedes an older active file without deletion.
				if active.get("reason") != "active_home_mismatch":
					error_message = "Einsatzstand ist ungültig. Im Kampagnenmenü kannst du ausdrücklich den letzten Basisstand laden; der Einsatzstand wird dabei als Datei gesichert."
					return
			else:
				active_pending = active.payload.components
				active_restore_in_progress = true
				checkpoint["base_personnel"] = active_pending.base_personnel.duplicate(true)
				if active_pending.has("home_hex_tactical"):
					checkpoint["hex_tactical"] = active_pending.home_hex_tactical.duplicate(true)
	var run: Dictionary = resolve_checkpoint_run_id(run_source if not run_source.is_empty() else checkpoint, action == "new")
	if not run.get("ok", false):
		error_message = "Kampagnenkennung ist ungültig. Zurueck zum Menue."
		return
	if action == "continue_home" and FileAccess.file_exists(ACTIVE_STORE.DEFAULT_PATH):
		var archived: Dictionary = ACTIVE_STORE.archive_checkpoint(FileAccess.get_sha256(ACTIVE_STORE.DEFAULT_PATH))
		if not archived.get("ok", false):
			error_message = "Einsatzstand konnte nicht gesichert werden. Beide Speicherstände bleiben erhalten."
			return
		flow.set_meta("campaign_active_archive", archived)
	campaign_run_id = run.id
	var roster: Array = Array(checkpoint.get("roster", _initial_roster())).duplicate(true)
	flow.set("_all_team_units", roster)
	flow.set("_available_team_units", roster.duplicate(true))
	flow.set_meta("player_roster_source", "campaign_checkpoint" if not checkpoint.is_empty() else "campaign_new")
	flow.set_meta("player_roster_profile_id", "campaign_introduction")
	flow.set_meta("player_roster_store_path", STORE.DEFAULT_PATH)
	var craft_state: Dictionary = Dictionary(checkpoint.get("craft", {}))
	var definition: Dictionary = Dictionary(craft_state.get("definition", flow.call("_build_homebase_aircraft_definition", "dropship", 1))).duplicate(true)
	if checkpoint.is_empty():
		definition["model_id"] = "cutlass" # Authored starter; existing ship identities remain unchanged.
	var craft_id: String = String(definition.get("craft_id", ""))
	var pilot: String = String(craft_state.get("pilot_id", roster[1].unit_id))
	var leader: String = String(roster[0].unit_id)
	var staged_units := PackedStringArray(craft_state.get("staged_unit_ids", [leader]))
	var staged_teams := PackedStringArray(craft_state.get("staged_fireteam_ids", ["ft1"]))
	var fleet: Array = Array(checkpoint.get("fleet",[{"definition":definition,"pilot_id":pilot,"location":"homebase"}])).duplicate(true)
	var fleet_definitions: Array = []
	var pilots: Dictionary = {}
	var locations: Dictionary = {}
	for ship: Dictionary in fleet:
		var ship_id := String(ship.definition.craft_id)
		fleet_definitions.append(ship.definition)
		pilots[ship_id] = String(ship.get("pilot_id",""))
		locations[ship_id] = String(ship.get("location","homebase"))
	# The hidden Active-Continue bootstrap reconstructs the independently saved
	# away-base owner before any scene/world publication or user input is allowed.
	if active_restore_in_progress and active_pending.has("home_hex_tactical"):
		locations[String(active_pending.identity.craft_id)] = "mission"
	flow.set("_homebase_aircraft_definitions", fleet_definitions)
	# LC2e B1: Verlustbelege verlorener Schiffe (alte Staende haben den Schluessel nicht); bei leerer Flotte gibt es kein Bootstrap-Schiff.
	flow.set("_lost_craft_records", Array(checkpoint.get("lost_craft", [])).duplicate(true))
	if fleet_definitions.is_empty(): craft_id = ""
	flow.set("_assigned_aircraft_pilot_by_craft", pilots)
	flow.set("_aircraft_location_by_craft", locations)
	flow.set("_homebase_staged_unit_ids", staged_units)
	flow.set("_homebase_staged_fireteam_ids", staged_teams)
	flow.set("_selected_unit_ids", staged_units.duplicate())
	flow.set("_selected_fireteam_ids", staged_teams.duplicate())
	flow.set("_selected_aircraft_cargo_by_craft", Dictionary(craft_state.get("selected_cargo", {})).duplicate(true))
	flow.set("_loaded_aircraft_cargo_by_craft", Dictionary(craft_state.get("loaded_cargo", {})).duplicate(true))
	flow.set_meta("singleplayer_bootstrap_craft_id", craft_id)
	flow.set_meta("singleplayer_bootstrap_fireteam_id", String(staged_teams[0]) if not staged_teams.is_empty() else "")
	flow.set_meta("singleplayer_bootstrap_enabled", true)
	var fob: Node = flow.call("_get_fob_screen")
	var default_armor := "suit" if checkpoint.is_empty() else "light"
	# Neue Kampagne: nur Raumanzug, keine Waffen (der Spieler rüstet selbst aus dem Basislager aus). Alte Stände behalten ihren Standard.
	var default_weapon_1 := "none" if checkpoint.is_empty() else "pistol"
	var default_weapon_2 := "none" if checkpoint.is_empty() else "medictool"
	var definitions: Array = Array(craft_state.get("fireteam_definitions", [{"id": "ft1", "lead_unit_id": leader, "name": "Pioniertrupp", "loadout_id": "light", "member_unit_ids":[leader], "member_loadouts":{leader:{"armor":default_armor,"weapon_1":default_weapon_1,"weapon_2":default_weapon_2}}}])).duplicate(true)
	fob.call("set_team", staged_units, staged_teams, definitions)
	flow.set("_selected_mission_id", "satellite_recovery")
	flow.set("_selected_mission_map_path", "res://maps/satellite_crash_site.json")
	flow.call("_ensure_singleplayer_release_homebase_direct_drop_source")
	flow.get_node("HomebaseScreen").set_meta("campaign_base_map_path", BASE_MAP)
	var loadouts: Dictionary = Dictionary(craft_state.get("member_loadouts", {})).duplicate(true)
	if checkpoint.is_empty():
		for person: Dictionary in roster:
			loadouts[String(person.unit_id)] = {"armor":"suit","weapon_1":"none","weapon_2":"none"}
	flow.get_node("HomebaseScreen").call("restore_personnel_loadouts", loadouts)

# Existing campaigns without a run ID receive a deterministic migration ID;
# new campaigns use fresh entropy so an earlier active save cannot reappear.
static func resolve_checkpoint_run_id(payload: Dictionary, fresh: bool) -> Dictionary:
	if fresh:
		var bytes := Crypto.new().generate_random_bytes(32)
		if bytes.size() != 32: return {"ok":false, "reason":"run_identity_unavailable"}
		return {"ok":true,"id":bytes.hex_encode()}
	if payload.has("campaign_run_id"):
		var value: Variant = payload.campaign_run_id
		if typeof(value) != TYPE_STRING or value.length() != 64: return {"ok":false,"reason":"invalid_run_identity"}
		for letter in value:
			if not String(letter) in "0123456789abcdef": return {"ok":false,"reason":"invalid_run_identity"}
		return {"ok":true,"id":value}
	if payload.is_empty(): return {"ok":false,"reason":"invalid_run_identity"}
	return {"ok":true,"id":("legacy:" + JSON.stringify(payload, "", true, true)).sha256_text()}

static func _migrate_known_main_starter(payload: Dictionary) -> bool:
	# Exactly the historically authored Main starter, whose role already resolves
	# to the Cutlass GLB. Never infer a model for other legacy ships.
	var known := {"cargo_options":[], "craft_id":"dropship_1", "craft_type":"dropship", "display_name":"Dropship 1", "summary":"Single-pilot shuttle for the FOB corridor.", "supports_cargo":false, "texture_path":"res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png"}
	var craft: Variant = payload.get("craft")
	var fleet: Variant = payload.get("fleet")
	if not craft is Dictionary or not fleet is Array or fleet.is_empty() or not fleet[0] is Dictionary: return false
	if not craft.get("definition") is Dictionary or not fleet[0].get("definition") is Dictionary: return false
	if craft.definition != known or fleet[0].definition != known: return false
	craft.definition["model_id"] = "cutlass"
	fleet[0].definition["model_id"] = "cutlass"
	return true

func _initial_roster() -> Array:
	var presets: Array = PRESETS.get_homebase_roster()
	var leader: Dictionary = Dictionary(presets[0]).duplicate(true)
	leader.merge({"unit_id": "campaign_leader", "display_name": "Anja Voss", "roster_role_category": "operator", "role_name": "Fireteam Leader", "fireteam_id": "ft1", "armor":"suit", "armor_id":"suit", "weapon_1":"none", "weapon_1_id":"none", "weapon_2":"none", "weapon_2_id":"none"}, true)
	# The dedicated pilot preset already carries the canonical piloting values.
	var pilot: Dictionary = {}
	for unit: Dictionary in presets:
		if String(unit.get("roster_role_category", "")).contains("pilot") or String(unit.get("role_name", "")).to_lower().contains("pilot"):
			pilot = unit.duplicate(true)
			break
	if pilot.is_empty():
		pilot = Dictionary(presets.back()).duplicate(true)
	pilot.merge({"unit_id": "campaign_pilot", "roster_role_category": "pilot", "role_name": "Dropship Pilot", "dropship_piloting": 0.7, "fireteam_id": "", "armor":"suit", "armor_id":"suit", "weapon_1":"none", "weapon_1_id":"none", "weapon_2":"none", "weapon_2_id":"none"}, true)
	return [leader, pilot]

func _hex_save_throttled(scope: String, now: int, force: bool) -> bool:
	return not force and scope == _hex_export_scope and now - _hex_export_msec < HEX_AUTOSAVE_INTERVAL_MSEC

## Fix-Runde 1 (W2): "flight", wenn irgendein Schiff wirklich fliegt (Reisephase quantum, stopped, orbit oder approach, oder auf der Sternkarte),
## sonst "place" (ein Schiff steht an einem anderen Ort, etwa gelandet bei einem Besuch). Gelesen wird der Zustand der Schiffe.
func _away_detail(flow: Node, runtime: Node) -> String:
	var flight_phases := ["quantum", "stopped", "orbit", "approach"]
	var travel: Dictionary = runtime.call("get_space_travel_snapshot") if runtime != null and runtime.has_method("get_space_travel_snapshot") else {}
	if String(travel.get("phase", "grounded")) in flight_phases: return "flight"
	var routes: Variant = travel.get("routes", {})
	if routes is Dictionary:
		for route in Dictionary(routes).values():
			if route is Dictionary and String(Dictionary(route).get("phase", "grounded")) in flight_phases: return "flight"
	var craft_locations: Variant = flow.get("_aircraft_location_by_craft")
	if craft_locations is Dictionary:
		for location in Dictionary(craft_locations).values():
			if String(location) == "starmap": return "flight"
	return "place"

func get_home_checkpoint_guard(flow: Node, runtime: Node) -> Dictionary:
	if active_restore_in_progress: return {"ok":false,"reason":"active_restore_pending"}
	if not error_message.is_empty():
		return {"ok": false, "reason": "campaign_load_failed"}
	var guard: Dictionary=runtime.call("get_world_checkpoint_guard")
	if not bool(guard.get("ok",false)):
		# Fix-Runde 1 (W2): im echten Flug und am Ort meldet der Welt-Schutz world_active. Der Zustand der Schiffe (nicht ein Text) sagt, welcher
		# der beiden Faelle es ist; "detail" dient nur der Anzeige, die Schutzpruefung selbst bleibt unveraendert.
		if String(guard.get("reason", "")) == "world_active" and not guard.has("detail"):
			guard = guard.duplicate()
			guard["detail"] = _away_detail(flow, runtime)
		return guard
	# Speichern, erster Teil / 21.11.: "detail" trennt "Schiff im Flug" (flight) von "Schiff an einem anderen Ort" (place), nur fuer die Anzeige;
	# der Grund bleibt away_from_checkpoint, die Schutzpruefung selbst ist unveraendert.
	var travel: Dictionary = runtime.call("get_space_travel_snapshot") if runtime != null and runtime.has_method("get_space_travel_snapshot") else {}
	if flow.get("_active_mission") != null or not Array(flow.get("_pending_mission_craft_transfers")).is_empty():
		return {"ok": false, "reason": "away_from_checkpoint", "detail": _away_detail(flow, runtime)}
	if String(travel.get("phase", "grounded")) != "grounded":
		return {"ok": false, "reason": "away_from_checkpoint", "detail": "flight"}
	for field in ["_pending_homebase_team_transfers", "_pending_homebase_pilot_transfers", "_pending_homebase_cargo_loads"]:
		if not Array(flow.get(field)).is_empty():
			return {"ok": false, "reason": "preparation_in_progress"}
	var crafts: Array = flow.get("_homebase_aircraft_definitions")
	# LC2e B1: Eine leere Flotte ist nur nach einem Schiffsverlust erlaubt (Verlustbeleg vorhanden).
	if crafts.is_empty() and _lost_records(flow).is_empty():
		return {"ok": false, "reason": "campaign_craft_count"}
	for ship: Dictionary in crafts:
		var ship_location := String(Dictionary(flow.get("_aircraft_location_by_craft")).get(String(ship.craft_id),""))
		if ship_location not in ["homebase","waiting_pad"]:
			return {"ok":false,"reason":"away_from_checkpoint","detail":"flight" if ship_location == "starmap" else "place"}
	return {"ok":true}

## LC2e B1: Verlustbelege verlorener Schiffe aus der Meta-Szene ([] ohne den Schluessel, etwa bei Pruefattrappen).
func _lost_records(flow: Node) -> Array:
	var value: Variant = flow.get("_lost_craft_records")
	return Array(value) if value is Array else []

func capture_home_checkpoint(flow: Node, runtime: Node) -> Dictionary:
	var guard := get_home_checkpoint_guard(flow, runtime)
	if not guard.get("ok", false): return guard
	var crafts: Array = flow.get("_homebase_aircraft_definitions")
	var lost_records: Array = _lost_records(flow)
	# LC2e B1: Bei leerer Flotte traegt "craft" (Pflichtschluessel aelterer Pruefungen) die Definition des zuletzt verlorenen Schiffs.
	var primary: Dictionary = Dictionary(crafts[0]) if not crafts.is_empty() else Dictionary(Dictionary(lost_records[lost_records.size() - 1]).get("definition", {}))
	var id: String = String(primary.get("craft_id", ""))
	var payload: Dictionary = runtime.call("export_campaign_checkpoint")
	if payload.is_empty():
		return {"ok": false, "reason": "runtime_unavailable"}
	payload["campaign_run_id"] = campaign_run_id
	payload["roster"] = Array(flow.get("_all_team_units")).duplicate(true)
	if not lost_records.is_empty(): payload["lost_craft"] = lost_records.duplicate(true)
	payload["craft"] = {
		"definition": primary.duplicate(true),
		"pilot_id": String(Dictionary(flow.get("_assigned_aircraft_pilot_by_craft")).get(id, "")),
		"staged_unit_ids": Array(flow.get("_homebase_staged_unit_ids")),
		"staged_fireteam_ids": Array(flow.get("_homebase_staged_fireteam_ids")),
		"fireteam_definitions": flow.get_node("HomebaseScreen").call("_get_fireteam_definitions_snapshot"),
		"member_loadouts": runtime.get("_simulation").call("get_personnel_loadout_state").call("get_snapshot"),
		"selected_cargo": flow.get("_selected_aircraft_cargo_by_craft"),
		"loaded_cargo": flow.get("_loaded_aircraft_cargo_by_craft")
	}
	payload["fleet"] = []
	for ship: Dictionary in crafts:
		payload.fleet.append({"definition":ship.duplicate(true),"pilot_id":String(Dictionary(flow.get("_assigned_aircraft_pilot_by_craft")).get(String(ship.craft_id),"")),"location":String(Dictionary(flow.get("_aircraft_location_by_craft")).get(String(ship.craft_id),"homebase"))})
	if not _retired_active_sha256.is_empty(): payload["retired_active_checkpoint_sha256"] = _retired_active_sha256
	return {"ok":true,"payload":payload}

func save_home_checkpoint(flow: Node, runtime: Node, force: bool = false) -> Dictionary:
	var guard := get_home_checkpoint_guard(flow, runtime)
	if not guard.get("ok", false): return guard
	# Safety gates always run first; explicit saves bypass the interval only.
	var simulation: Node = runtime.get("_simulation")
	var hex_export: bool = is_instance_valid(simulation) and simulation.is_hex_ground_runtime_required()
	var scope := ""
	if hex_export:
		var now := Time.get_ticks_msec()
		scope = "%s:%s:%s" % [runtime.get_instance_id(), simulation.get_instance_id(), simulation.get_hex_ground_context_revision()]
		if _hex_save_throttled(scope, now, force) and FileAccess.file_exists(STORE.DEFAULT_PATH): return {"ok":true,"unchanged":true,"throttled":true}
		if not force and scope == _hex_failed_scope and now - _hex_failed_msec < HEX_AUTOSAVE_RETRY_MSEC:
			var retry := _hex_failed_result.duplicate(true)
			retry["retry_pending"] = true
			return retry
	var captured := capture_home_checkpoint(flow, runtime)
	if not captured.get("ok", false): return _remember_hex_save_failure(scope,captured) if hex_export else captured
	var payload: Dictionary = captured.payload
	# Commit the exact superseded file identity WITH the new home checkpoint.
	# If archiving fails or the process exits after the atomic home rename,
	# Continue can still ignore only that retired artifact without parsing it.
	var active_sha := FileAccess.get_sha256(ACTIVE_STORE.DEFAULT_PATH) if _retire_active_on_home_save and FileAccess.file_exists(ACTIVE_STORE.DEFAULT_PATH) else ""
	if not active_sha.is_empty(): _retired_active_sha256 = active_sha
	if not _retired_active_sha256.is_empty(): payload["retired_active_checkpoint_sha256"] = _retired_active_sha256
	var signature: String = JSON.stringify(payload, "", true).sha256_text()
	if signature == last_save_signature and FileAccess.file_exists(STORE.DEFAULT_PATH):
		if hex_export: _remember_hex_save_success(scope)
		return {"ok": true, "unchanged": true}
	var result: Dictionary = STORE.save_checkpoint(payload)
	if result.get("ok", false):
		if hex_export: _remember_hex_save_success(scope)
		last_save_signature = signature
		_retire_active_on_home_save = false
		if not active_sha.is_empty():
			var archived: Dictionary = ACTIVE_STORE.archive_checkpoint(active_sha)
			result["active_archive"] = archived
			if archived.get("ok", false): flow.set_meta("campaign_active_archive", archived)
	return _remember_hex_save_failure(scope,result) if hex_export and not result.get("ok",false) else result

func _remember_hex_save_success(scope: String) -> void:
	_hex_export_scope = scope
	_hex_export_msec = Time.get_ticks_msec()
	_hex_failed_scope = ""
	_hex_failed_result.clear()

func _remember_hex_save_failure(scope: String, result: Dictionary) -> Dictionary:
	# A newer failed explicit attempt supersedes an older successful interval.
	if scope == _hex_export_scope:
		_hex_export_scope = ""
		_hex_export_msec = -1
	_hex_failed_scope = scope
	_hex_failed_msec = Time.get_ticks_msec()
	_hex_failed_result = result.duplicate(true)
	return result


func save_active_checkpoint(flow: Node, runtime: Node, _force: bool = false) -> Dictionary:
	var capture = load("res://scripts/mission/campaign_active_mission_capture.gd")
	var collected: Dictionary = capture.capture_components(flow,runtime)
	if not collected.get("ok",false): return collected
	var normalizer = load("res://scripts/mission/campaign_active_json_normalizer.gd")
	var normalized: Dictionary = normalizer.normalize(collected.components)
	if not normalized.get("ok",false): return normalized
	var payload := {"schema":"campaign_active_checkpoint.v1", "components":normalized.value}
	# Validate in the exact persisted numeric domain on the first and second
	# store pass; all values were already explicitly checked as JSON-native.
	var wire: Variant = JSON.parse_string(JSON.stringify(payload,"",true,true))
	if not wire is Dictionary: return {"ok":false,"reason":"active_json_roundtrip_failed"}
	payload = wire
	var validator = load("res://scripts/mission/campaign_active_checkpoint_validation.gd")
	var store = load("res://scripts/meta/campaign_active_checkpoint_store.gd")
	return store.save_checkpoint(payload,func(value: Dictionary) -> Dictionary: return validator.validate_live(value,flow,runtime))


func get_save_projection(flow: Node, runtime: Node) -> Dictionary:
	var projection = load("res://scripts/meta/campaign_save_projection.gd")
	var saved: Dictionary = projection.inspect_saved()
	var result: Dictionary = saved.projection
	var captured: Dictionary
	var active := is_instance_valid(flow.get("_active_mission"))
	if active_restore_in_progress:
		captured = {"ok":false,"reason":"active_restore_pending"}
	elif active:
		var capture = load("res://scripts/mission/campaign_active_mission_capture.gd")
		captured = capture.capture_components(flow, runtime)
		if captured.get("ok", false):
			var normalizer = load("res://scripts/mission/campaign_active_json_normalizer.gd")
			var normalized: Dictionary = normalizer.normalize(captured.components)
			captured = {"ok":true,"payload":{"schema":"campaign_active_checkpoint.v1","components":normalized.value}} if normalized.get("ok", false) else normalized
	else:
		captured = capture_home_checkpoint(flow, runtime)
	result.can_save = bool(captured.get("ok", false))
	result.save_blocked_reason = String(captured.get("reason", ""))
	result.save_blocked_text = projection.blocked_text(result.save_blocked_reason, String(captured.get("detail", "") if captured.has("detail") else ("" if active else "home")))
	var expected_kind := "mission" if active else "home"
	var stored: Dictionary = saved.active if active else saved.home
	result.has_unsaved_progress = not result.can_save or result.kind != expected_kind or not projection.equivalent(Dictionary(captured.get("payload", {})), Dictionary(stored.get("payload", {})), active)
	return result
