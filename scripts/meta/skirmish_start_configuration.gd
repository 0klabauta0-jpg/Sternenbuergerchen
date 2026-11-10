extends RefCounted
## Authored start snapshots; never reads or writes the user's team library.
const DATA_PATH := "res://data/skirmish/prepared_starts.json"
const GENERATOR = preload("res://scripts/meta/start_roster_generator.gd")
const RELATIONSHIPS = preload("res://scripts/meta/roster_relationship_model.gd")
const PRESET_IDS := ["early", "mid", "late"]

static func get_presets() -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	return Dictionary(raw).duplicate(true) if raw is Dictionary else {}

func build_start(preset_id: String) -> Dictionary:
	var preset: Dictionary = get_presets().get(preset_id, {})
	if preset.is_empty() or not PRESET_IDS.has(preset_id):
		return {"ok":false,"reason":"unknown_skirmish_preset"}
	var size := int(preset.roster_size)
	var generated := GENERATOR.generate_start_roster("prepared_skirmish_" + preset_id, maxi(20, size), "skirmish_" + preset_id)
	var roster: Array = Array(generated.units).slice(0, size).duplicate(true)
	var loadouts := {}
	var crafts: Array = []
	var pilots := {}
	var craft_locations := {}
	var fireteams: Array = []
	var unit_ids := PackedStringArray()
	var team_ids := PackedStringArray()
	var unit_team_ids := PackedStringArray()
	var pilot_count: int = preset.crafts.size()
	for index in range(size):
		var unit: Dictionary = roster[index]
		var id := "skirmish_%s_%02d" % [preset_id, index + 1]
		unit.unit_id = id
		unit.player_profile_id = "skirmish_" + preset_id
		unit.relationship_links = []
		unit.erase("relationship_summary_text")
		var is_pilot: bool = index >= size - pilot_count
		unit.roster_role_category = "pilot" if is_pilot else "operator"
		unit.role_name = "Pilot" if is_pilot else ("Fireteam Leader" if index % 4 == 0 else "Rifle Operator")
		unit.fireteam_id = "" if is_pilot else "ft%d" % [index / 4 + 1]
		unit.dropship_piloting = 0.75 if is_pilot else 0.0
		unit.fighter_piloting = 0.75 if is_pilot else 0.0
		unit.freighter_piloting = 0.75 if is_pilot else 0.0
		unit.skill_leadership = 0.75 if index % 4 == 0 else float(unit.get("skill_leadership", 0.5))
		unit.armor = "heavy" if index % 2 == 0 else "medium"
		unit.weapon_1 = "rifle"
		unit.weapon_2 = "pistol"
		unit.armor_id = unit.armor
		unit.weapon_1_id = "rifle"
		unit.weapon_2_id = "pistol"
		unit.loadout_summary = "Sturmgewehr · " + ("schwere Rüstung" if unit.armor == "heavy" else "mittlere Rüstung")
		loadouts[id] = {"armor":unit.armor,"weapon_1":"rifle","weapon_2":"pistol"}
		if not is_pilot:
			unit_ids.append(id)
			unit_team_ids.append(unit.fireteam_id)
			if not team_ids.has(unit.fireteam_id):
				team_ids.append(unit.fireteam_id)
				fireteams.append({"id":unit.fireteam_id,"lead_unit_id":id,"name":"Trupp %d" % team_ids.size(),"loadout_id":"heavy" if index % 2 == 0 else "medium","member_unit_ids":[],"member_loadouts":{}})
			fireteams.back().member_unit_ids.append(id)
			fireteams.back().member_loadouts[id] = loadouts[id].duplicate()
	roster = RELATIONSHIPS.apply_relationships_to_units(roster, RELATIONSHIPS.build_deterministic_start_relationships(roster,"skirmish_" + preset_id),true)
	for index in range(pilot_count):
		var authored: Dictionary = preset.crafts[index]
		var craft_id := "skirmish_%s_%s_%d" % [preset_id,authored.model_id,index + 1]
		crafts.append({"craft_id":craft_id,"craft_type":authored.type,"display_name":authored.name,"model_id":authored.model_id,"visual_placeholder":authored.placeholder,"summary":"Modellplatzhalter; Spezialfunktionen noch offen" if authored.placeholder else "Vorbereitetes Einsatzschiff", "texture_path":"res://Assets/curated/ui_native_r4/cutlass_ref03_preview.png" if authored.model_id == "cutlass" else "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png","supports_cargo":authored.type == "craft_cargoB","cargo_options":[],"seat_capacity":size if authored.type == "dropship" else 1})
		pilots[craft_id] = roster[size - pilot_count + index].unit_id
		craft_locations[craft_id] = "homebase"
	return {"ok":true,"preset_id":preset_id,"roster":roster,"member_loadouts":loadouts,"crafts":crafts,"pilots":pilots,"craft_locations":craft_locations,"fireteams":fireteams,"staged_units":unit_ids,"staged_teams":unit_team_ids,"infrastructure":Dictionary(preset.infrastructure).duplicate(true),"credits":int(preset.credits),"title":String(preset.title)}

func configure(flow: Node, request: Dictionary) -> Dictionary:
	var result := build_start(String(request.get("preset_id", "")))
	if not result.get("ok", false): return result
	flow.set("_all_team_units", result.roster.duplicate(true))
	flow.set("_available_team_units", result.roster.duplicate(true))
	flow.set("_homebase_aircraft_definitions", result.crafts.duplicate(true))
	flow.set("_assigned_aircraft_pilot_by_craft", result.pilots.duplicate(true))
	flow.set("_aircraft_location_by_craft", result.craft_locations.duplicate(true))
	flow.set("_homebase_staged_unit_ids", result.staged_units.duplicate())
	flow.set("_homebase_staged_fireteam_ids", result.staged_teams.duplicate())
	flow.set("_selected_unit_ids", result.staged_units.duplicate())
	flow.set("_selected_fireteam_ids", result.staged_teams.duplicate())
	flow.set_meta("skirmish_preset_id", result.preset_id)
	flow.set_meta("skirmish_infrastructure", result.infrastructure.duplicate(true))
	flow.set_meta("skirmish_start_credits", result.credits)
	flow.set_meta("skirmish_start_loadouts", result.member_loadouts.duplicate(true))
	flow.set_meta("player_roster_source", "skirmish_preset")
	flow.set_meta("player_roster_profile_id", "skirmish_" + String(result.preset_id))
	flow.set_meta("singleplayer_bootstrap_enabled", true)
	flow.set_meta("singleplayer_bootstrap_craft_id", String(result.crafts[0].craft_id))
	flow.set_meta("singleplayer_bootstrap_fireteam_id", "ft1")
	flow.get_node("FOBScreen").call("set_team", result.staged_units, result.staged_teams, result.fireteams)
	flow.get_node("HomebaseScreen").call("restore_personnel_loadouts", result.member_loadouts.duplicate(true))
	flow.call("_ensure_singleplayer_release_homebase_direct_drop_source")
	return result
