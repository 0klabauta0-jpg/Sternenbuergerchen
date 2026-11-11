extends RefCounted
## Authored start snapshots; never reads or writes the user's team library.
const DATA_PATH := "res://data/skirmish/prepared_starts.json"
const GENERATOR = preload("res://scripts/meta/start_roster_generator.gd")
const RELATIONSHIPS = preload("res://scripts/meta/roster_relationship_model.gd")
const POINTS = preload("res://scripts/meta/skirmish_points_catalog.gd")
const PRESET_IDS := ["early", "mid", "late"]

static func get_presets() -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	return Dictionary(raw).duplicate(true) if raw is Dictionary else {}

func build_start(preset_id: String) -> Dictionary:
	var preset: Dictionary = get_presets().get(preset_id, {})
	if preset.is_empty() or not PRESET_IDS.has(preset_id):
		return {"ok":false,"reason":"unknown_skirmish_preset"}
	return _build_configuration(preset_id, preset)


func build_points_start(draft: Dictionary) -> Dictionary:
	var purchase := POINTS.evaluate(draft)
	if not purchase.ok:
		return purchase
	if bool(draft.get("base_setup", false)):
		var result := _build_configuration("points", {"roster_size": 0, "crafts": [], "credits": 0,
			"title": "Skirmish · %d Punkte" % int(draft.budget),
			"infrastructure": {"paid": true, "habitat": 0, "workshop": 0, "bed": 0, "beds": 0, "pads": 0}})
		result["points_budget"] = int(draft.budget)
		return result
	var people: Array = []
	for role_is_pilot in [false, true]:
		for person: Dictionary in draft.people:
			if (person.role == "pilot") == role_is_pilot:
				people.append(person)
	var ships: Array = []
	for ship_id: String in ["cutlass", "buccaneer"]:
		for index in range(draft.ships.count(ship_id)):
			var entry: Dictionary = POINTS.SHIPS[ship_id]
			ships.append({"name": entry.name, "type": entry.type, "model_id": ship_id, "placeholder": false})
	return _build_configuration("points", {
		"roster_size": people.size(), "crafts": ships, "credits": 0,
		"title": "Skirmish · %d Punkte" % int(draft.budget),
		"infrastructure": {"beds": people.size(), "pads": ships.size(),
			"services": ["personnel", "equipment", "trade", "refuel"], "reserved_assets": []},
	}, people)


func build_points_person(person: Dictionary, unit_id: String, used_portraits: Dictionary) -> Dictionary:
	var generated := GENERATOR.generate_start_roster(unit_id, 20, "skirmish_points")
	var unit: Dictionary = generated.units[0].duplicate(true)
	var portraits = load("res://scripts/meta/portrait_identity_catalog.gd")
	var catalog: Dictionary = portraits.load_catalog()
	var preferred: Dictionary = catalog.entries_by_id.get(String(unit.portrait_id), {})
	var group: String = GENERATOR.get_authored_first_name_group(String(unit.display_name).get_slice(" ", 0))
	for number in range(45, 49):
		var candidate: Dictionary = catalog.entries_by_id.get("char_portrait_%03d" % number, {})
		if not candidate.is_empty() and candidate.presentation_group == group and not used_portraits.has(candidate.id):
			preferred = candidate
			break
	var entry: Dictionary = portraits.select_generated_entry(preferred,
		group, used_portraits)
	unit.unit_id = unit_id
	unit.player_profile_id = "skirmish_points"
	unit.portrait_id = String(entry.get("id", unit.portrait_id))
	unit.portrait_path = String(entry.get("path", unit.portrait_path))
	unit.fireteam_id = ""
	_apply_points_profile(unit, person, person.role == "pilot", false)
	return unit


## Explicit editor action: reuse the points profile, but return only ability fields.
## Opening an existing roster or selecting a dropdown never calls this method.
func build_experience_patch(unit: Dictionary, experience_id: String) -> Dictionary:
	if not POINTS.EXPERIENCE.has(experience_id):
		return {"ok": false, "reason": "experience_missing", "patch": {}}
	var category := String(unit.get("roster_role_category", "operator"))
	var role := category if POINTS.ROLES.has(category) else "operator"
	var candidate := unit.duplicate(true)
	_apply_points_profile(candidate, {"role": role, "experience": experience_id,
		"armor": "suit", "weapon": "pistol"}, role == "pilot", bool(unit.get("is_fireteam_lead", false)))
	var patch := {}
	for group: String in ["skill_values", "communication_values", "behavior_axes", "platform_values"]:
		patch[group] = Dictionary(candidate[group]).duplicate(true)
	# Preserve the same canonical and compatibility aliases as the existing purchase path.
	for key: String in candidate.skill_values:
		patch[key] = candidate.skill_values[key]
		patch["skill_" + key] = candidate.skill_values[key]
	for key: String in candidate.communication_values:
		patch[key] = candidate.communication_values[key]
	for key: String in candidate.platform_values:
		patch[key] = candidate.platform_values[key]
	return {"ok": true, "reason": "", "experience_id": experience_id, "patch": patch}


## Read-only value match, never a statement of purchase/training provenance.
func match_experience_template(unit: Dictionary) -> Dictionary:
	for experience_id: String in POINTS.EXPERIENCE:
		var proposal := build_experience_patch(unit, experience_id)
		var matches := true
		for group: String in ["skill_values", "communication_values", "behavior_axes", "platform_values"]:
			var expected: Dictionary = proposal.patch[group]
			var actual: Variant = unit.get(group)
			if not actual is Dictionary or actual.size() != expected.size():
				matches = false
				break
			for key: String in expected:
				var value: Variant = actual.get(key)
				if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)) or float(value) != float(expected[key]):
					matches = false
					break
			if not matches: break
		if matches:
			return {"matches_template": true, "experience_id": experience_id, "label": "Entspricht Vorlage: " + String(POINTS.EXPERIENCE[experience_id].label)}
	return {"matches_template": false, "experience_id": "", "label": "Individuelles Profil"}


func _build_configuration(preset_id: String, preset: Dictionary, bought_people: Array = []) -> Dictionary:
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
		if not bought_people.is_empty():
			_apply_points_profile(unit, bought_people[index], is_pilot, not is_pilot and index % 4 == 0)
		loadouts[id] = {"armor":unit.armor,"weapon_1":unit.weapon_1,"weapon_2":unit.weapon_2}
		if not is_pilot:
			unit_ids.append(id)
			unit_team_ids.append(unit.fireteam_id)
			if not team_ids.has(unit.fireteam_id):
				team_ids.append(unit.fireteam_id)
				fireteams.append({"id":unit.fireteam_id,"lead_unit_id":id,"name":"Trupp %d" % team_ids.size(),"loadout_id":unit.armor,"member_unit_ids":[],"member_loadouts":{}})
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


func _apply_points_profile(unit: Dictionary, person: Dictionary, is_pilot: bool, leads_team: bool) -> void:
	var experience: Dictionary = POINTS.EXPERIENCE[person.experience]
	var skill: float = experience.value
	unit.role_name = POINTS.ROLES[person.role].name
	unit.role_id = {"operator": "security_guard", "medic": "combat_medic",
		"engineer": "combat_engineer", "pilot": "dropship_pilot"}[person.role]
	unit.roster_role_category = person.role
	unit.trait_ids = []
	unit.relationship_links = []
	unit.is_fireteam_lead = leads_team
	unit.specialty_text = POINTS.ROLES[person.role].label
	unit.armor = person.armor
	unit.armor_id = person.armor
	unit.weapon_1 = person.weapon
	unit.weapon_1_id = person.weapon
	unit.weapon_2 = "medictool" if person.role == "medic" else "none"
	unit.weapon_2_id = unit.weapon_2
	unit.loadout_summary = "%s · %s · %s" % [experience.label, POINTS.WEAPONS[person.weapon].label, POINTS.ARMOR[person.armor].label]
	unit.skill_values = {"accuracy": skill, "speed": skill, "toughness": skill,
		"leadership": skill if leads_team else 0.3, "awareness": skill, "recognition": skill,
		"stealth": skill, "discipline": skill}
	unit.communication_values = {"speech_quality": skill, "speech_quantity": 0.5}
	unit.behavior_axes = {"initiative": skill, "order_fidelity": skill, "signature_control": skill,
		"contact_stability": skill, "autonomy": skill}
	unit.platform_values = {"dropship_piloting": skill if is_pilot else 0.0,
		"fighter_piloting": skill if is_pilot else 0.0, "freighter_piloting": skill if is_pilot else 0.0,
		"ground_vehicle_handling": 0.0}
	for id: String in unit.skill_values:
		unit["skill_" + id] = unit.skill_values[id]
		unit[id] = unit.skill_values[id]
	unit.speech_quality = skill
	unit.speech_quantity = 0.5
	for id: String in unit.platform_values:
		unit[id] = unit.platform_values[id]


func configure(flow: Node, request: Dictionary) -> Dictionary:
	var result := build_points_start(request.points_draft) if request.has("points_draft") else build_start(String(request.get("preset_id", "")))
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
	if result.has("points_budget"):
		flow.set_meta("skirmish_points_budget", int(result.points_budget))
	flow.set_meta("player_roster_source", "skirmish_preset")
	flow.set_meta("player_roster_profile_id", "skirmish_" + String(result.preset_id))
	flow.set_meta("singleplayer_bootstrap_enabled", true)
	flow.set_meta("singleplayer_bootstrap_craft_id", String(result.crafts[0].craft_id) if not result.crafts.is_empty() else "")
	flow.set_meta("singleplayer_bootstrap_fireteam_id", "ft1")
	flow.get_node("FOBScreen").call("set_team", result.staged_units, result.staged_teams, result.fireteams)
	flow.get_node("HomebaseScreen").call("restore_personnel_loadouts", result.member_loadouts.duplicate(true))
	flow.call("_ensure_singleplayer_release_homebase_direct_drop_source")
	return result
