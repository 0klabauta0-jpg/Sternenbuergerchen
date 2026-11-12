extends RefCounted
## Campaign entry/checkpoint adapter. No writes to the Skirmish roster store.

const PRESETS = preload("res://scripts/npc/unit_roster_presets.gd")
const STORE = preload("res://scripts/meta/campaign_checkpoint_store.gd")
const BASE_MAP := "res://maps/campaign_intro_base.json"
const HEX_AUTOSAVE_INTERVAL_MSEC := 5 * 60 * 1000
var entry: Dictionary = {}
var checkpoint: Dictionary = {}
var last_save_signature := ""
var error_message := ""
var _hex_export_scope := ""
var _hex_export_msec: int = -1

func configure(flow: Node, request: Dictionary) -> void:
	entry = request.duplicate(true)
	if String(request.get("action", "new")) == "continue":
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
		checkpoint = Dictionary(loaded.payload).duplicate(true)
		_migrate_known_main_starter(checkpoint)
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
	flow.set("_homebase_aircraft_definitions", fleet_definitions)
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
	var definitions: Array = Array(craft_state.get("fireteam_definitions", [{"id": "ft1", "lead_unit_id": leader, "name": "Pioniertrupp", "loadout_id": "light", "member_unit_ids":[leader], "member_loadouts":{leader:{"armor":default_armor,"weapon_1":"pistol","weapon_2":"medictool"}}}])).duplicate(true)
	fob.call("set_team", staged_units, staged_teams, definitions)
	flow.set("_selected_mission_id", "satellite_recovery")
	flow.set("_selected_mission_map_path", "res://maps/satellite_crash_site.json")
	flow.call("_ensure_singleplayer_release_homebase_direct_drop_source")
	flow.get_node("HomebaseScreen").set_meta("campaign_base_map_path", BASE_MAP)
	var loadouts: Dictionary = Dictionary(craft_state.get("member_loadouts", {})).duplicate(true)
	if checkpoint.is_empty():
		for person: Dictionary in roster:
			loadouts[String(person.unit_id)] = {"armor":"suit","weapon_1":"pistol","weapon_2":"medictool"}
	flow.get_node("HomebaseScreen").call("restore_personnel_loadouts", loadouts)

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
	leader.merge({"unit_id": "campaign_leader", "display_name": "Anja Voss", "roster_role_category": "operator", "role_name": "Fireteam Leader", "fireteam_id": "ft1", "armor":"suit", "armor_id":"suit", "weapon_1":"pistol", "weapon_1_id":"pistol", "weapon_2":"medictool", "weapon_2_id":"medictool"}, true)
	# The dedicated pilot preset already carries the canonical piloting values.
	var pilot: Dictionary = {}
	for unit: Dictionary in presets:
		if String(unit.get("roster_role_category", "")).contains("pilot") or String(unit.get("role_name", "")).to_lower().contains("pilot"):
			pilot = unit.duplicate(true)
			break
	if pilot.is_empty():
		pilot = Dictionary(presets.back()).duplicate(true)
	pilot.merge({"unit_id": "campaign_pilot", "roster_role_category": "pilot", "role_name": "Dropship Pilot", "dropship_piloting": 0.7, "fireteam_id": "", "armor":"suit", "armor_id":"suit", "weapon_1":"pistol", "weapon_1_id":"pistol", "weapon_2":"medictool", "weapon_2_id":"medictool"}, true)
	return [leader, pilot]

func _hex_save_throttled(scope: String, now: int, force: bool) -> bool:
	return not force and scope == _hex_export_scope and now - _hex_export_msec < HEX_AUTOSAVE_INTERVAL_MSEC

func save_home_checkpoint(flow: Node, runtime: Node, force: bool = false) -> Dictionary:
	if not error_message.is_empty():
		return {"ok": false, "reason": "campaign_load_failed"}
	var guard: Dictionary=runtime.call("get_world_checkpoint_guard")
	if not bool(guard.get("ok",false)): return guard
	if flow.get("_active_mission") != null or not Array(flow.get("_pending_mission_craft_transfers")).is_empty():
		return {"ok": false, "reason": "away_from_checkpoint"}
	var travel: Dictionary = runtime.call("get_space_travel_snapshot") if runtime != null and runtime.has_method("get_space_travel_snapshot") else {}
	if String(travel.get("phase", "grounded")) != "grounded":
		return {"ok": false, "reason": "away_from_checkpoint"}
	for field in ["_pending_homebase_team_transfers", "_pending_homebase_pilot_transfers", "_pending_homebase_cargo_loads"]:
		if not Array(flow.get(field)).is_empty():
			return {"ok": false, "reason": "preparation_in_progress"}
	var crafts: Array = flow.get("_homebase_aircraft_definitions")
	if crafts.is_empty():
		return {"ok": false, "reason": "campaign_craft_count"}
	var id: String = String(crafts[0].craft_id)
	for ship: Dictionary in crafts:
		if String(Dictionary(flow.get("_aircraft_location_by_craft")).get(String(ship.craft_id),"")) not in ["homebase","waiting_pad"]:
			return {"ok":false,"reason":"away_from_checkpoint"}
	# Safety gates always run first; explicit saves bypass the interval only.
	var simulation: Node = runtime.get("_simulation")
	var hex_export: bool = is_instance_valid(simulation) and simulation.is_hex_ground_runtime_required()
	if hex_export:
		var now := Time.get_ticks_msec()
		var scope := "%s:%s:%s" % [runtime.get_instance_id(), simulation.get_instance_id(), simulation.get_hex_ground_context_revision()]
		if _hex_save_throttled(scope, now, force): return {"ok":true,"unchanged":true,"throttled":true}
		_hex_export_scope = scope
		_hex_export_msec = now
	var payload: Dictionary = runtime.call("export_campaign_checkpoint")
	if hex_export: _hex_export_msec = Time.get_ticks_msec()
	if payload.is_empty():
		return {"ok": false, "reason": "runtime_unavailable"}
	payload["roster"] = Array(flow.get("_all_team_units")).duplicate(true)
	payload["craft"] = {
		"definition": Dictionary(crafts[0]).duplicate(true),
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
	var signature: String = JSON.stringify(payload, "", true).sha256_text()
	if signature == last_save_signature:
		return {"ok": true, "unchanged": true}
	var result: Dictionary = STORE.save_checkpoint(payload)
	if result.get("ok", false):
		last_save_signature = signature
	return result
