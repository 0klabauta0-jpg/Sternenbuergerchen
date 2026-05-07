extends SceneTree

const START_ROSTER_GENERATOR_SCRIPT: GDScript = preload("res://scripts/meta/start_roster_generator.gd")
const PLAYER_ROSTER_STORE_SCRIPT: GDScript = preload("res://scripts/meta/player_roster_store.gd")
const META_UNIT_PROFILE_SCRIPT: GDScript = preload("res://scripts/meta/meta_unit_profile.gd")
const CHARACTER_SHEET_VIEW_SCRIPT: GDScript = preload("res://scripts/meta/character_sheet_view.gd")
const FIRETEAM_COHESION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/fireteam_cohesion_resolver.gd")
const MISSION_PROGRESSION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/mission_progression_resolver.gd")
const PERSONNEL_EVENT_MODEL_SCRIPT: GDScript = preload("res://scripts/meta/personnel_event_model.gd")
const PERSONNEL_EVENT_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/personnel_event_resolver.gd")
const CHARACTER_GAMEPLAY_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/character_gameplay_resolver.gd")
const MULTIPLAYER_ROSTER_CONTRACT_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_roster_contract.gd")
const MULTIPLAYER_SNAPSHOT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_snapshot_contract.gd")
const FTL_BUBBLE_RESOLVER_SCRIPT: GDScript = preload("res://scripts/ui/fireteamleader_feedback_bubble_resolver.gd")
const NPC_THOUGHT_RESOLVER_SCRIPT: GDScript = preload("res://scripts/ui/npc_thought_bubble_resolver.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const HOMEBASE_TEST_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const FOB_TEST_SCENE: PackedScene = preload("res://scenes/meta/fob_test_screen.tscn")
const DEBRIEF_TEST_SCENE: PackedScene = preload("res://scenes/meta/debrief_test_screen.tscn")

const PROFILE_ID: String = "task_241_character_smoke"
const SAVE_PATH: String = "user://profiles/task_241_character_smoke/roster_v1.json"
const MANUAL_CHECKLIST_PATH: String = "res://docs/manual_checks/character_gameplay_playability_checklist.md"
const REVIEW_PATH: String = "res://docs/reviews/character_gameplay_balance_and_open_items_review.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_241 Character Gameplay Playability Smoke ===")
	var context: Dictionary = _test_first_start_save_load_roster_and_sheet()
	await _test_homebase_and_fob_show_character_fireteam_state(context)
	await _test_mission_debrief_progression_personnel_and_bubbles(context)
	_test_multiplayer_privacy_boundary(context)
	_test_manual_docs_exist()
	PLAYER_ROSTER_STORE_SCRIPT.call("delete_roster_for_tests", PROFILE_ID, SAVE_PATH)
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_first_start_save_load_roster_and_sheet() -> Dictionary:
	PLAYER_ROSTER_STORE_SCRIPT.call("delete_roster_for_tests", PROFILE_ID, SAVE_PATH)
	var ensure_result: Dictionary = _ensure_valid_first_start_roster()
	_assert(bool(ensure_result.get("ok", false)) and bool(ensure_result.get("created", false)), "First-start creates a persisted player roster")
	var roster: Dictionary = Dictionary(ensure_result.get("roster", {}))
	var units: Array = Array(roster.get("units", []))
	_assert(units.size() >= 20 and units.size() <= 30, "First-start roster has 20 to 30 operators")
	_assert(_all_units_have_visible_identity(units), "Roster units include portraits, badges, skills and traits")
	var load_result: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("load_roster", PROFILE_ID, SAVE_PATH))
	_assert(bool(load_result.get("ok", false)), "Roster can be loaded after first-start save")
	var loaded_roster: Dictionary = Dictionary(load_result.get("roster", {}))
	_assert(String(loaded_roster.get("seed", "")) == String(roster.get("seed", "")), "Loaded roster preserves first-start seed")

	var profile = META_UNIT_PROFILE_SCRIPT.new(Dictionary(units[0]))
	var host := VBoxContainer.new()
	root.add_child(host)
	CHARACTER_SHEET_VIEW_SCRIPT.call("render", host, profile, {"fireteam_text": String(Dictionary(units[0]).get("fireteam_id", "")).to_upper()})
	var labels: PackedStringArray = _collect_label_texts(host)
	_assert(_labels_contain(labels, "STATUS / RECOVERY:"), "Character sheet renders status/recovery section")
	_assert(_labels_contain(labels, "TEAMFIT:"), "Character sheet renders teamfit section")
	_assert(_labels_contain(labels, "PROGRESS:"), "Character sheet renders progress section")
	host.queue_free()

	var selected: Dictionary = _select_fireteam(roster)
	_assert(PackedStringArray(selected.get("selected_unit_ids", PackedStringArray())).size() >= 2, "Smoke selects a playable fireteam from roster suggestions")
	return {
		"roster": loaded_roster,
		"selected_unit_ids": selected.get("selected_unit_ids", PackedStringArray()),
		"selected_fireteam_ids": selected.get("selected_fireteam_ids", PackedStringArray()),
		"fireteam_definitions": selected.get("fireteam_definitions", []),
	}


func _test_homebase_and_fob_show_character_fireteam_state(context: Dictionary) -> void:
	var roster: Dictionary = Dictionary(context.get("roster", {}))
	var units: Array = Array(roster.get("units", []))
	var selected_unit_ids: PackedStringArray = PackedStringArray(context.get("selected_unit_ids", PackedStringArray()))
	var selected_fireteam_ids: PackedStringArray = PackedStringArray(context.get("selected_fireteam_ids", PackedStringArray()))
	var fireteam_definitions: Array = Array(context.get("fireteam_definitions", []))

	var homebase: Control = HOMEBASE_TEST_SCENE.instantiate()
	var fob: Control = FOB_TEST_SCENE.instantiate()
	root.add_child(homebase)
	root.add_child(fob)
	await process_frame
	homebase.call("setup_roster", units, selected_unit_ids)
	homebase.call("set_fireteam_context", selected_fireteam_ids)
	fob.call("set_available_units", units)
	fob.call("configure_transfer", selected_unit_ids, selected_fireteam_ids, fireteam_definitions)
	await _wait_frames(2)

	var roster_list := homebase.get_node("Panel/Margin/VBox/ContentRow/RosterPanel/RosterMargin/RosterVBox/RosterScroll/RosterList") as VBoxContainer
	var selected_team_list := homebase.get_node("Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/TeamDropPanel/DropMargin/DropVBox/SelectedTeamScroll/SelectedTeamList") as VBoxContainer
	_assert(roster_list.get_child_count() + selected_team_list.get_child_count() == units.size(), "Homebase shows generated operators across roster and transfer team cards")
	var homebase_labels: PackedStringArray = _collect_label_texts(homebase)
	_assert(_labels_contain(homebase_labels, "STATUS / RECOVERY:") and _labels_contain(homebase_labels, "TEAMFIT:"), "Homebase character sheet shows gameplay sections")
	var overview: Dictionary = Dictionary(fob.call("build_meta_overview"))
	var fireteams: Array = Array(overview.get("fireteams", []))
	_assert(not fireteams.is_empty(), "FOB overview exposes fireteams")
	var first_fireteam: Dictionary = Dictionary(fireteams[0])
	_assert(float(first_fireteam.get("cohesion", 0.0)) > 0.0, "FOB fireteam overview computes cohesion")
	_assert(not String(first_fireteam.get("teamfit_summary_text", "")).strip_edges().is_empty(), "FOB fireteam card has teamfit summary text")
	homebase.queue_free()
	fob.queue_free()
	await process_frame


func _test_mission_debrief_progression_personnel_and_bubbles(context: Dictionary) -> void:
	var roster: Dictionary = Dictionary(context.get("roster", {}))
	var selected_unit_ids: PackedStringArray = PackedStringArray(context.get("selected_unit_ids", PackedStringArray()))
	var selected_fireteam_ids: PackedStringArray = PackedStringArray(context.get("selected_fireteam_ids", PackedStringArray()))
	var mission_result: Dictionary = _build_mission_result(roster, selected_unit_ids, selected_fireteam_ids, true, true)
	var progression_result: Dictionary = Dictionary(MISSION_PROGRESSION_RESOLVER_SCRIPT.call("apply_mission_result", roster, mission_result))
	var updated_roster: Dictionary = Dictionary(progression_result.get("updated_roster", {}))
	var character_events: Array = Array(progression_result.get("character_events", []))
	_assert(not character_events.is_empty(), "Mission progression emits character events")
	var progressed_unit: Dictionary = _find_unit(Array(updated_roster.get("units", [])), selected_unit_ids[0])
	_assert(int(Dictionary(progressed_unit.get("progression", {})).get("xp", 0)) > 0, "Mission progression awards XP")
	_assert(not Array(progressed_unit.get("mission_history", [])).is_empty(), "Mission progression writes mission history")
	var save_result: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("save_roster", updated_roster, PROFILE_ID, SAVE_PATH))
	_assert(bool(save_result.get("ok", false)), "Progressed roster saves after mission")
	var load_result: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("load_roster", PROFILE_ID, SAVE_PATH))
	_assert(bool(load_result.get("ok", false)), "Progressed roster loads after mission")

	var personnel_roster: Dictionary = _apply_extra_successes_for_personnel(Dictionary(load_result.get("roster", {})), selected_unit_ids, selected_fireteam_ids)
	var personnel_result: Dictionary = Dictionary(PERSONNEL_EVENT_RESOLVER_SCRIPT.call("evaluate_roster", personnel_roster))
	var personnel_events: Array = Array(personnel_result.get("events", []))
	_assert(_events_contain(personnel_events, PERSONNEL_EVENT_MODEL_SCRIPT.EVENT_RECRUIT_AVAILABLE), "Several missions can surface a personnel event")

	var debrief: Control = DEBRIEF_TEST_SCENE.instantiate()
	root.add_child(debrief)
	await process_frame
	var debrief_payload: Dictionary = mission_result.duplicate(true)
	debrief_payload["character_events"] = character_events
	debrief_payload["personnel_events"] = personnel_events
	debrief.call("set_mission_result", debrief_payload)
	await process_frame
	var debrief_labels: PackedStringArray = _collect_label_texts(debrief)
	_assert(_labels_contain(debrief_labels, "Character updates:"), "Debrief shows character updates")
	_assert(_labels_contain(debrief_labels, "Personnel updates:"), "Debrief shows personnel updates")
	debrief.queue_free()
	await process_frame

	var selected_units: Array = _units_for_ids(Array(Dictionary(personnel_result.get("updated_roster", personnel_roster)).get("units", [])), selected_unit_ids)
	var character_context: Dictionary = Dictionary(CHARACTER_GAMEPLAY_RESOLVER_SCRIPT.call("build_mission_character_context", selected_units))
	var public_snapshot: Array = Array(character_context.get("public_snapshot", []))
	_assert(not public_snapshot.is_empty(), "Mission character gameplay builds a public snapshot")
	_assert(not bool(CHARACTER_GAMEPLAY_RESOLVER_SCRIPT.call("snapshot_has_private_fields", public_snapshot)), "Character gameplay public snapshot is privacy-safe")
	var bubble_result: Dictionary = _build_character_bubbles(selected_units, selected_fireteam_ids[0])
	_assert(bool(bubble_result.get("ftl_ok", false)), "FTL bubble reacts to character context")
	_assert(bool(bubble_result.get("thought_ok", false)), "NPC thought bubble reacts to character state")


func _test_multiplayer_privacy_boundary(context: Dictionary) -> void:
	var roster: Dictionary = Dictionary(context.get("roster", {}))
	var preview: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("build_public_roster_preview", roster, 2, "player", "player_rosters"))
	_assert(bool(preview.get("valid", false)), "Multiplayer public roster preview validates")
	_assert(not bool(MULTIPLAYER_ROSTER_CONTRACT_SCRIPT.call("has_private_roster_fields", preview)), "Multiplayer roster preview has no private fields")
	var contract: RefCounted = MULTIPLAYER_SNAPSHOT_CONTRACT_SCRIPT.new()
	var first_unit: Dictionary = Dictionary(Array(roster.get("units", []))[0])
	var snapshot: Dictionary = Dictionary(contract.call("build_state_snapshot", {
		"tick": 11,
		"units": [
			first_unit.merged({
				"owner_peer_id": 2,
				"roster_source": "player",
				"roster_mode": "player_rosters",
				"visible": true,
			}, true)
		],
	}))
	var unit_snapshot: Dictionary = Dictionary(Array(snapshot.get("units", []))[0])
	_assert(int(unit_snapshot.get("owner_peer_id", 0)) == 2 and String(unit_snapshot.get("roster_source", "")) == "player", "Multiplayer unit snapshot keeps ownership")
	_assert(not bool(MULTIPLAYER_ROSTER_CONTRACT_SCRIPT.call("has_private_roster_fields", unit_snapshot)), "Multiplayer unit snapshot strips private roster fields")


func _test_manual_docs_exist() -> void:
	_assert(FileAccess.file_exists(MANUAL_CHECKLIST_PATH), "Manual character gameplay checklist exists")
	_assert(FileAccess.file_exists(REVIEW_PATH), "Character gameplay balance/open-items review exists")
	var checklist_text: String = _read_text(MANUAL_CHECKLIST_PATH)
	var review_text: String = _read_text(REVIEW_PATH)
	_assert(checklist_text.contains("First-start") and checklist_text.contains("Debrief") and checklist_text.contains("Multiplayer"), "Manual checklist covers first-start, debrief and multiplayer")
	_assert(review_text.contains("Balance") and review_text.contains("Open Items"), "Review documents balance and open items")


func _ensure_valid_first_start_roster() -> Dictionary:
	for suffix in range(12):
		PLAYER_ROSTER_STORE_SCRIPT.call("delete_roster_for_tests", PROFILE_ID, SAVE_PATH)
		var seed: String = "task241_first_start_%02d" % suffix
		var result: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("ensure_roster", seed, 24, PROFILE_ID, SAVE_PATH))
		var summary: Dictionary = Dictionary(result.get("summary", {}))
		if bool(result.get("ok", false)) and bool(summary.get("valid", false)):
			return result
	return {}


func _all_units_have_visible_identity(units: Array) -> bool:
	for unit_variant in units:
		if typeof(unit_variant) != TYPE_DICTIONARY:
			return false
		var unit: Dictionary = Dictionary(unit_variant)
		if String(unit.get("unit_id", "")).strip_edges().is_empty():
			return false
		if String(unit.get("portrait_id", "")).strip_edges().is_empty():
			return false
		if Array(unit.get("rank_badges", [])).is_empty():
			return false
		if Dictionary(unit.get("skill_values", {})).is_empty():
			return false
		if PackedStringArray(unit.get("trait_ids", PackedStringArray())).is_empty():
			return false
	return true


func _select_fireteam(roster: Dictionary) -> Dictionary:
	var units: Array = Array(roster.get("units", []))
	for suggestion_variant in Array(roster.get("fireteam_suggestions", [])):
		if typeof(suggestion_variant) != TYPE_DICTIONARY:
			continue
		var suggestion: Dictionary = Dictionary(suggestion_variant)
		var member_ids: PackedStringArray = PackedStringArray(suggestion.get("unit_ids", PackedStringArray()))
		if member_ids.size() < 2:
			continue
		var selected_unit_ids: PackedStringArray = PackedStringArray()
		var selected_fireteam_ids: PackedStringArray = PackedStringArray()
		var fireteam_id: String = String(suggestion.get("fireteam_id", suggestion.get("id", "ft1"))).strip_edges().to_lower()
		for index in range(mini(4, member_ids.size())):
			selected_unit_ids.append(String(member_ids[index]))
			selected_fireteam_ids.append(fireteam_id)
		var snapshot: Dictionary = Dictionary(FIRETEAM_COHESION_RESOLVER_SCRIPT.call("build_fireteam_snapshot_from_ids", fireteam_id, units, selected_unit_ids, String(suggestion.get("leader_unit_id", ""))))
		return {
			"selected_unit_ids": selected_unit_ids,
			"selected_fireteam_ids": selected_fireteam_ids,
			"fireteam_definitions": [{
				"id": fireteam_id,
				"label": String(suggestion.get("display_name", fireteam_id.to_upper())),
				"lead_unit_id": String(snapshot.get("lead_unit_id", suggestion.get("leader_unit_id", ""))),
				"loadout": "medium",
				"respawn_enabled": false,
			}],
		}
	return {}


func _build_mission_result(roster: Dictionary, selected_unit_ids: PackedStringArray, selected_fireteam_ids: PackedStringArray, success: bool, down_first: bool) -> Dictionary:
	var team_states: Array = []
	var unit_events: Dictionary = {}
	for index in range(selected_unit_ids.size()):
		var unit_id: String = String(selected_unit_ids[index])
		var unit: Dictionary = _find_unit(Array(roster.get("units", [])), unit_id)
		var fireteam_id: String = String(selected_fireteam_ids[index]) if index < selected_fireteam_ids.size() else String(unit.get("fireteam_id", "blue"))
		var is_downed: bool = down_first and index == 0
		team_states.append({
			"unit_id": unit_id,
			"display_name": String(unit.get("display_name", unit_id)),
			"fireteam_id": fireteam_id,
			"vital_state": "downed" if is_downed else "alive",
			"health_points": 0 if is_downed else 10,
		})
		unit_events[unit_id] = {
			"unit_id": unit_id,
			"objective_participation": index <= 1,
			"fired_weapon": index == 0 or index == 2,
			"medic_action": index == 1,
			"healed": index == 1,
			"downed": is_downed,
			"role_mismatch": is_downed,
		}
	return {
		"mission_id": "task241_character_smoke_mission",
		"mission_outcome": "success" if success else "failed",
		"result": "success" if success else "failed",
		"winning_team_id": "team_alpha" if success else "team_bravo",
		"objective_captured": success,
		"duration_seconds": 48.0,
		"selected_unit_ids": selected_unit_ids,
		"selected_fireteam_ids": selected_fireteam_ids,
		"team_states": team_states,
		"unit_events": unit_events,
	}


func _apply_extra_successes_for_personnel(roster: Dictionary, selected_unit_ids: PackedStringArray, selected_fireteam_ids: PackedStringArray) -> Dictionary:
	var current: Dictionary = roster.duplicate(true)
	for index in range(2):
		var mission_result: Dictionary = _build_mission_result(current, selected_unit_ids, selected_fireteam_ids, true, false)
		mission_result["mission_id"] = "task241_followup_%d" % index
		var progression_result: Dictionary = Dictionary(MISSION_PROGRESSION_RESOLVER_SCRIPT.call("apply_mission_result", current, mission_result))
		current = Dictionary(progression_result.get("updated_roster", current))
	return current


func _build_character_bubbles(selected_units: Array, fireteam_id: String) -> Dictionary:
	if selected_units.is_empty():
		return {"ftl_ok": false, "thought_ok": false}
	var leader_unit: Dictionary = Dictionary(selected_units[0]).duplicate(true)
	var thought_unit: Dictionary = Dictionary(selected_units[mini(1, selected_units.size() - 1)]).duplicate(true)
	var thought_progression: Dictionary = Dictionary(thought_unit.get("progression", {})).duplicate(true)
	thought_progression["morale"] = 0.20
	thought_progression["frustration"] = 0.88
	thought_unit["progression"] = thought_progression
	var leader_node: Node2D = _make_test_unit(leader_unit, Vector2(80.0, 80.0), true)
	var thought_node: Node2D = _make_test_unit(thought_unit, Vector2(112.0, 80.0), false)
	var context_units: Array = [leader_unit, thought_unit]
	var fireteam_context: Dictionary = Dictionary(CHARACTER_GAMEPLAY_RESOLVER_SCRIPT.call("build_fireteam_character_context", fireteam_id, context_units))
	var unit_state_by_id: Dictionary = {
		String(thought_unit.get("unit_id", "")).strip_edges().to_lower(): thought_unit,
	}
	var ftl_payload: Dictionary = Dictionary(FTL_BUBBLE_RESOLVER_SCRIPT.call(
		"build_command_feedback",
		"move",
		"accepted",
		leader_node,
		leader_node.global_position,
		{},
		{"fireteam_id": fireteam_id, "fireteam_units": [leader_unit, thought_unit], "fireteam_character_context": fireteam_context}
	))
	var thought_payload: Dictionary = Dictionary(NPC_THOUGHT_RESOLVER_SCRIPT.call(
		"build_unit_thought",
		thought_node,
		{},
		{
			"selected": true,
			"fireteam_character_context": fireteam_context,
			"unit_character_state_by_id": unit_state_by_id,
		}
	))
	var result: Dictionary = {
		"ftl_ok": bool(ftl_payload.get("ok", false)) and String(ftl_payload.get("character_gameplay_source", "")) == "character_gameplay_resolver",
		"thought_ok": bool(thought_payload.get("ok", false)) and String(thought_payload.get("thought_kind", "")).begins_with("character:"),
	}
	leader_node.free()
	thought_node.free()
	return result


func _make_test_unit(unit: Dictionary, world_position: Vector2, is_lead: bool) -> Node2D:
	var node: Node2D = TEST_UNIT_SCRIPT.new()
	node.unit_id = String(unit.get("unit_id", ""))
	node.display_name = String(unit.get("display_name", node.unit_id))
	node.team_id = String(unit.get("team_id", "team_alpha"))
	node.fireteam_id = String(unit.get("fireteam_id", "blue"))
	node.role_id = String(unit.get("role_id", unit.get("roster_role_category", "operator")))
	node.is_fireteam_lead = is_lead or bool(unit.get("is_fireteam_lead", false))
	var skills: Dictionary = Dictionary(unit.get("skill_values", {}))
	node.skill_leadership = float(skills.get("leadership", 0.5))
	node.skill_accuracy = float(skills.get("accuracy", 0.5))
	node.skill_speed = float(skills.get("speed", 0.5))
	node.skill_toughness = float(skills.get("toughness", 0.5))
	node.awareness = float(skills.get("awareness", 0.5))
	node.discipline = float(skills.get("discipline", 0.5))
	node.speech_quality = float(Dictionary(unit.get("communication_values", {})).get("speech_quality", node.skill_leadership))
	node.global_position = world_position
	node._ready()
	return node


func _find_unit(units: Array, unit_id: String) -> Dictionary:
	var normalized_unit_id: String = unit_id.strip_edges().to_lower()
	for unit_variant in units:
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit: Dictionary = Dictionary(unit_variant)
		if String(unit.get("unit_id", "")).strip_edges().to_lower() == normalized_unit_id:
			return unit
	return {}


func _units_for_ids(units: Array, unit_ids: PackedStringArray) -> Array:
	var result: Array = []
	for unit_id in unit_ids:
		var unit: Dictionary = _find_unit(units, String(unit_id))
		if not unit.is_empty():
			result.append(unit)
	return result


func _events_contain(events: Array, event_type: String) -> bool:
	for event_variant in events:
		if typeof(event_variant) == TYPE_DICTIONARY and String(Dictionary(event_variant).get("event_type", "")) == event_type:
			return true
	return false


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _collect_label_texts(root_node: Node) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for node in _collect_nodes(root_node):
		var label := node as Label
		if label != null:
			result.append(label.text)
	return result


func _collect_nodes(root_node: Node) -> Array:
	var nodes: Array = []
	if root_node == null:
		return nodes
	nodes.append(root_node)
	for child in root_node.get_children():
		nodes.append_array(_collect_nodes(child))
	return nodes


func _labels_contain(labels: PackedStringArray, fragment: String) -> bool:
	for text in labels:
		if String(text).contains(fragment):
			return true
	return false


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
