extends RefCounted
## Campaign entry/checkpoint adapter. No writes to the Skirmish roster store.

const PRESETS = preload("res://scripts/npc/unit_roster_presets.gd")
const STORE = preload("res://scripts/meta/campaign_checkpoint_store.gd")
const BASE_MAP := "res://maps/campaign_intro_base.json"
var entry: Dictionary = {}
var checkpoint: Dictionary = {}
var last_save_signature := ""
var error_message := ""

func configure(flow: Node, request: Dictionary) -> void:
	entry = request.duplicate(true)
	if String(request.get("action", "new")) == "continue":
		var loaded: Dictionary = STORE.load_checkpoint()
		if not bool(loaded.get("ok", false)):
			error_message = "Kampagnenstand konnte nicht geladen werden. Zurueck zum Menue."
			return
		checkpoint = Dictionary(loaded.payload).duplicate(true)
	var roster: Array = Array(checkpoint.get("roster", _initial_roster())).duplicate(true)
	flow.set("_all_team_units", roster)
	flow.set("_available_team_units", roster.duplicate(true))
	flow.set_meta("player_roster_source", "campaign_checkpoint" if not checkpoint.is_empty() else "campaign_new")
	flow.set_meta("player_roster_profile_id", "campaign_introduction")
	flow.set_meta("player_roster_store_path", STORE.DEFAULT_PATH)
	var craft_state: Dictionary = Dictionary(checkpoint.get("craft", {}))
	var definition: Dictionary = Dictionary(craft_state.get("definition", flow.call("_build_homebase_aircraft_definition", "dropship", 1))).duplicate(true)
	var craft_id: String = String(definition.get("craft_id", ""))
	var pilot: String = String(craft_state.get("pilot_id", roster[1].unit_id))
	var leader: String = String(roster[0].unit_id)
	var staged_units := PackedStringArray(craft_state.get("staged_unit_ids", [leader]))
	var staged_teams := PackedStringArray(craft_state.get("staged_fireteam_ids", ["ft1"]))
	flow.set("_homebase_aircraft_definitions", [definition])
	flow.set("_assigned_aircraft_pilot_by_craft", {craft_id: pilot})
	flow.set("_aircraft_location_by_craft", {craft_id: "homebase"})
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
	var definitions: Array = Array(craft_state.get("fireteam_definitions", [{"id": "ft1", "lead_unit_id": leader, "name": "Pioniertrupp", "loadout_id": "medium"}])).duplicate(true)
	fob.call("set_team", staged_units, staged_teams, definitions)
	flow.set("_selected_mission_id", "satellite_recovery")
	flow.set("_selected_mission_map_path", "res://maps/satellite_crash_site.json")
	flow.call("_ensure_singleplayer_release_homebase_direct_drop_source")
	flow.get_node("HomebaseScreen").set_meta("campaign_base_map_path", BASE_MAP)
	if not checkpoint.is_empty():
		flow.get_node("HomebaseScreen").set("_member_loadout_by_unit_id", Dictionary(craft_state.get("member_loadouts", {})).duplicate(true))

func _initial_roster() -> Array:
	var presets: Array = PRESETS.get_homebase_roster()
	var leader: Dictionary = Dictionary(presets[0]).duplicate(true)
	leader.merge({"unit_id": "campaign_leader", "display_name": "Anja Voss", "roster_role_category": "operator", "role_name": "Fireteam Leader", "fireteam_id": "ft1"}, true)
	# The dedicated pilot preset already carries the canonical piloting values.
	var pilot: Dictionary = {}
	for unit: Dictionary in presets:
		if String(unit.get("roster_role_category", "")).contains("pilot") or String(unit.get("role_name", "")).to_lower().contains("pilot"):
			pilot = unit.duplicate(true)
			break
	if pilot.is_empty():
		pilot = Dictionary(presets.back()).duplicate(true)
	pilot.merge({"unit_id": "campaign_pilot", "roster_role_category": "pilot", "role_name": "Dropship Pilot", "dropship_piloting": 0.7, "fireteam_id": ""}, true)
	return [leader, pilot]

func save_home_checkpoint(flow: Node, runtime: Node) -> Dictionary:
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
	if crafts.size() != 1:
		return {"ok": false, "reason": "campaign_craft_count"}
	var id: String = String(crafts[0].craft_id)
	if String(Dictionary(flow.get("_aircraft_location_by_craft")).get(id, "")) != "homebase":
		return {"ok": false, "reason": "away_from_checkpoint"}
	var payload: Dictionary = runtime.call("export_campaign_checkpoint")
	if payload.is_empty():
		return {"ok": false, "reason": "runtime_unavailable"}
	payload["roster"] = Array(flow.get("_all_team_units")).duplicate(true)
	payload["craft"] = {
		"definition": Dictionary(crafts[0]).duplicate(true),
		"pilot_id": String(Dictionary(flow.get("_assigned_aircraft_pilot_by_craft")).get(id, "")),
		"staged_unit_ids": Array(flow.get("_homebase_staged_unit_ids")),
		"staged_fireteam_ids": Array(flow.get("_homebase_staged_fireteam_ids")),
		"fireteam_definitions": flow.get_node("HomebaseScreen").call("_get_fireteam_definitions_snapshot"),
		"member_loadouts": flow.get_node("HomebaseScreen").get("_member_loadout_by_unit_id"),
		"selected_cargo": flow.get("_selected_aircraft_cargo_by_craft"),
		"loaded_cargo": flow.get("_loaded_aircraft_cargo_by_craft")
	}
	var signature: String = JSON.stringify(payload, "", true).sha256_text()
	if signature == last_save_signature:
		return {"ok": true, "unchanged": true}
	var result: Dictionary = STORE.save_checkpoint(payload)
	if result.get("ok", false):
		last_save_signature = signature
	return result
