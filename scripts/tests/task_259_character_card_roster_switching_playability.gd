extends SceneTree

const HARNESS_SCRIPT: GDScript = preload("res://scripts/tests/playability/playability_test_harness.gd")
const PLAYER_ROSTER_STORE_SCRIPT: GDScript = preload("res://scripts/meta/player_roster_store.gd")
const MISSION_PROGRESSION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/mission_progression_resolver.gd")

const HOMEBASE_SCENE_PATH: String = "res://scenes/meta/homebase_test_screen.tscn"
const FOB_SCENE_PATH: String = "res://scenes/meta/fob_test_screen.tscn"
const MISSION_SCENE_PATH: String = "res://scenes/tests/mission_reactivity_test.tscn"
const DEBRIEF_SCENE_PATH: String = "res://scenes/meta/debrief_test_screen.tscn"
const REPORT_PATH: String = "res://docs/reports/playability_character_card_roster_switching_report.md"
const PROFILE_ID: String = "task_259_roster_switching"
const SAVE_PATH: String = "user://profiles/task_259_roster_switching/roster_v1.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_259 Character Card Roster Switching Playability ===")
	var context: Dictionary = _build_roster_context()
	await _test_homebase_card_access_and_transfer(context)
	await _test_fob_card_access_loadout_and_fireteam_switching(context)
	await _test_mission_and_debrief_character_access(context)
	_test_roster_save_load_persistence(context)
	_test_report_exists()
	PLAYER_ROSTER_STORE_SCRIPT.call("delete_roster_for_tests", PROFILE_ID, SAVE_PATH)
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _build_roster_context() -> Dictionary:
	var ensure_result: Dictionary = _ensure_valid_task_roster()
	_assert(bool(ensure_result.get("ok", false)), "Task roster is generated and saved for switching smoke")
	var roster: Dictionary = Dictionary(ensure_result.get("roster", {})).duplicate(true)
	var units: Array = Array(roster.get("units", []))
	_assert(units.size() >= 8, "Task roster has enough operators for card and switching coverage")

	var selected_unit_ids: PackedStringArray = PackedStringArray()
	for index in range(6):
		selected_unit_ids.append(String(Dictionary(units[index]).get("unit_id", "")))
	var selected_fireteam_ids := PackedStringArray(["ft1", "ft1", "ft2", "ft2", "ft3", "ft3"])
	return {
		"roster": roster,
		"units": units,
		"selected_unit_ids": selected_unit_ids,
		"selected_fireteam_ids": selected_fireteam_ids,
		"fireteam_definitions": [
			_build_fireteam_definition("ft1", selected_unit_ids[0]),
			_build_fireteam_definition("ft2", selected_unit_ids[2]),
			_build_fireteam_definition("ft3", selected_unit_ids[4]),
		],
	}


func _test_homebase_card_access_and_transfer(context: Dictionary) -> void:
	root.size = Vector2i(1920, 1080)
	var units: Array = Array(context.get("units", []))
	var initially_selected := PackedStringArray([
		String(Dictionary(units[0]).get("unit_id", "")),
		String(Dictionary(units[1]).get("unit_id", "")),
	])
	var added_unit: Dictionary = Dictionary(units[2])
	var added_unit_id: String = String(added_unit.get("unit_id", ""))
	var homebase: Node = HARNESS_SCRIPT.instantiate_scene(HOMEBASE_SCENE_PATH, root)
	_assert(homebase != null, "Homebase instantiates for character roster switching")
	if homebase == null:
		return
	await _wait_frames(3)
	homebase.call("setup_roster", units, initially_selected)
	homebase.call("set_fireteam_context", PackedStringArray(["ft1", "ft1"]))
	await _wait_frames(2)

	var roster_card := _find_npc_card(homebase, added_unit_id, "roster")
	_assert(roster_card != null, "Homebase roster card exists for an unstaged operator")
	_assert(_open_npc_card(roster_card), "Homebase roster card exposes an open-character signal")
	await _wait_frames(2)
	_assert(_labels_contain(_collect_label_texts(homebase), String(added_unit.get("display_name", added_unit_id))), "Homebase character sheet follows the roster card selection")
	_assert(_labels_contain(_collect_label_texts(homebase), "Loc: Homebase / Roster"), "Homebase roster card sheet shows roster location")
	_assert(homebase.find_child("MetricPlus_accuracy", true, false) == null, "Homebase runtime character sheet is read-only")

	homebase.call("_on_team_drop_panel_unit_dropped", added_unit_id)
	await _wait_frames(2)
	var selected_after_add: PackedStringArray = PackedStringArray(homebase.call("get_selected_unit_ids"))
	_assert(selected_after_add.has(added_unit_id) and selected_after_add.size() == 3, "Homebase pool-to-team transfer adds the operator once")
	_assert(_homebase_lists_keep_all_units(homebase, units.size()), "Homebase roster plus transfer list keep every operator represented once")

	var staged_card := _find_npc_card(homebase, added_unit_id, "staged")
	_assert(staged_card != null, "Homebase transfer-team card exists after staging")
	_assert(_open_npc_card(staged_card), "Homebase transfer-team card opens the same character sheet")
	await _wait_frames(2)
	_assert(_labels_contain(_collect_label_texts(homebase), "Loc: Homebase / Transfer Window"), "Homebase staged card sheet shows transfer-window location")

	var snapshot_before_duplicate: PackedStringArray = PackedStringArray(homebase.call("get_selected_unit_ids"))
	homebase.call("_on_team_drop_panel_unit_dropped", added_unit_id)
	await _wait_frames(1)
	var snapshot_after_duplicate: PackedStringArray = PackedStringArray(homebase.call("get_selected_unit_ids"))
	_assert(_same_string_array(snapshot_before_duplicate, snapshot_after_duplicate), "Duplicate Homebase transfer attempt does not duplicate a unit")
	var team_panel := homebase.get_node("Panel/Margin/VBox/ContentRow/TeamPanel") as Control
	_assert(team_panel.tooltip_text.contains("already staged"), "Duplicate Homebase transfer attempt leaves clear feedback")

	homebase.call("_on_roster_drop_panel_unit_dropped", added_unit_id)
	await _wait_frames(2)
	var selected_after_remove: PackedStringArray = PackedStringArray(homebase.call("get_selected_unit_ids"))
	_assert(not selected_after_remove.has(added_unit_id) and selected_after_remove.size() == 2, "Homebase team-to-pool removal returns the operator without loss")
	_assert(_find_npc_card(homebase, added_unit_id, "roster") != null, "Returned operator is reachable from the roster again")
	homebase.queue_free()
	await process_frame


func _test_fob_card_access_loadout_and_fireteam_switching(context: Dictionary) -> void:
	root.size = Vector2i(1920, 1080)
	var units: Array = Array(context.get("units", []))
	var selected_unit_ids: PackedStringArray = PackedStringArray(context.get("selected_unit_ids", PackedStringArray()))
	var selected_fireteam_ids: PackedStringArray = PackedStringArray(context.get("selected_fireteam_ids", PackedStringArray()))
	var fireteam_definitions: Array = Array(context.get("fireteam_definitions", []))
	var fob: Node = HARNESS_SCRIPT.instantiate_scene(FOB_SCENE_PATH, root)
	_assert(fob != null, "FOB instantiates for character roster switching")
	if fob == null:
		return
	(fob as CanvasItem).visible = true
	await _wait_frames(3)
	fob.call("set_available_units", units)
	fob.call("configure_transfer", selected_unit_ids, selected_fireteam_ids, fireteam_definitions)
	await _wait_frames(3)

	var first_unit_id: String = String(selected_unit_ids[0])
	var first_unit: Dictionary = _find_unit(units, first_unit_id)
	var fob_member_card := _find_npc_card(fob, first_unit_id, "fob_fireteam")
	_assert(fob_member_card != null, "FOB fireteam member card exists")
	_assert(_open_npc_card(fob_member_card), "FOB fireteam member card opens character overlay")
	await _wait_frames(2)
	_assert(_control_visible(fob.get_node_or_null("CharacterOverlay") as Control), "FOB character overlay becomes visible")
	_assert(_labels_contain(_collect_label_texts(fob), String(first_unit.get("display_name", first_unit_id))), "FOB overlay follows the selected fireteam member")
	_assert(_labels_contain(_collect_label_texts(fob), "Assigned to FT1"), "FOB overlay shows initial fireteam assignment")
	_assert(fob.find_child("MetricPlus_accuracy", true, false) == null, "FOB runtime character overlay is read-only")

	fob.call("_on_fireteam_card_unit_dropped", first_unit_id, "ft2")
	await _wait_frames(2)
	_assert(_assignment_for_unit(fob, first_unit_id) == "ft2", "FOB fireteam-to-fireteam reassignment updates the selected slot")
	_assert(_assignment_integrity(fob, selected_unit_ids), "FOB reassignment keeps selected unit IDs unique and complete")

	fob.call("_on_available_panel_unit_dropped", first_unit_id)
	await _wait_frames(2)
	_assert(_assignment_for_unit(fob, first_unit_id).is_empty(), "FOB remove-to-pool path clears fireteam assignment without dropping the unit")
	_assert(_assignment_integrity(fob, selected_unit_ids), "FOB clear assignment keeps selected unit IDs unique and complete")

	fob.call("_on_fireteam_card_unit_dropped", first_unit_id, "ft3")
	await _wait_frames(2)
	_assert(_assignment_for_unit(fob, first_unit_id) == "ft3", "FOB pool-to-fireteam assignment restores the operator into another fireteam")
	var assignment_snapshot: PackedStringArray = PackedStringArray(fob.call("get_selected_fireteam_ids"))
	fob.call("_on_fireteam_card_unit_dropped", "missing_operator_id", "ft3")
	await _wait_frames(1)
	_assert(_same_string_array(assignment_snapshot, PackedStringArray(fob.call("get_selected_fireteam_ids"))), "Invalid FOB reassignment is blocked without changing assignments")

	fob.call("_on_staging_fireteam_dropped", "ft3", "loadout")
	await _wait_frames(2)
	var loadout_card := _find_npc_card(fob, first_unit_id, "loadout_staging")
	_assert(loadout_card != null, "FOB loadout slot card exists for staged fireteam member")
	_assert(_open_npc_card(loadout_card), "FOB loadout slot card opens character overlay")
	await _wait_frames(2)
	_assert(_labels_contain(_collect_label_texts(fob), "ROLLE / LOADOUT:"), "FOB loadout card overlay keeps character sheet sections visible")
	_assert(_labels_contain(_collect_label_texts(fob), "Assigned to FT3"), "FOB loadout card overlay stays synchronized with reassigned fireteam")
	fob.queue_free()
	await process_frame


func _test_mission_and_debrief_character_access(context: Dictionary) -> void:
	root.size = Vector2i(1920, 1080)
	var mission: Node = HARNESS_SCRIPT.instantiate_scene(MISSION_SCENE_PATH, root)
	_assert(mission != null, "Mission scene instantiates for selected-fireteam character access")
	if mission != null:
		await _wait_frames(8)
		var mission_card := _first_npc_card_in_path(mission, "TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamCardsScroll/FireteamCardsBody/FireteamCardsRow")
		_assert(mission_card != null, "Mission selected-fireteam card row exposes operator cards")
		var mission_unit_id: String = String(mission_card.call("get_unit_id")) if mission_card != null else ""
		_assert(_open_npc_card(mission_card), "Mission selected-fireteam card opens character overlay")
		await _wait_frames(2)
		_assert(_control_visible(mission.get_node_or_null("TacticalUI/CharacterOverlay") as Control), "Mission character overlay becomes visible")
		_assert(not mission_unit_id.is_empty() and _labels_contain(_collect_label_texts(mission), _mission_display_name(mission, mission_unit_id)), "Mission character overlay follows selected fireteam card identity")
		_assert(mission.find_child("MetricPlus_accuracy", true, false) == null, "Mission runtime character overlay is read-only")
		_assert(mission.get_node_or_null("TacticalUI/CharacterOverlay/OverlayPanel/OverlayMargin/OverlayVBox/OverlayScroll/OverlayContentVBox/DevStatsPanel") == null, "Mission runtime character overlay hides dev stat sliders")
		mission.queue_free()
		await process_frame

	var debrief: Node = HARNESS_SCRIPT.instantiate_scene(DEBRIEF_SCENE_PATH, root)
	_assert(debrief != null, "Debrief scene instantiates for character progression access")
	if debrief != null:
		var mission_result: Dictionary = _build_mission_result(context)
		debrief.call("set_mission_result", mission_result)
		await _wait_frames(2)
		var labels: PackedStringArray = _collect_label_texts(debrief)
		_assert(_labels_contain(labels, "Character updates:"), "Debrief exposes character progression updates")
		_assert(_labels_contain(labels, String(PackedStringArray(context.get("selected_unit_ids", PackedStringArray()))[0])), "Debrief character update keeps selected unit ID visible")
		debrief.queue_free()
		await process_frame


func _test_roster_save_load_persistence(context: Dictionary) -> void:
	var roster: Dictionary = Dictionary(context.get("roster", {})).duplicate(true)
	var selected_unit_ids: PackedStringArray = PackedStringArray(context.get("selected_unit_ids", PackedStringArray()))
	var selected_fireteam_ids: PackedStringArray = PackedStringArray(context.get("selected_fireteam_ids", PackedStringArray()))
	var assigned_roster: Dictionary = _apply_assignments_to_roster(roster, selected_unit_ids, selected_fireteam_ids)
	var save_result: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("save_roster", assigned_roster, PROFILE_ID, SAVE_PATH))
	_assert(bool(save_result.get("ok", false)), "Roster with fireteam assignments saves")
	var load_result: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("load_roster", PROFILE_ID, SAVE_PATH))
	_assert(bool(load_result.get("ok", false)), "Roster with fireteam assignments loads")
	var loaded_roster: Dictionary = Dictionary(load_result.get("roster", {}))
	_assert(_loaded_roster_preserves_assignments(loaded_roster, selected_unit_ids, selected_fireteam_ids), "Save/load preserves expected fireteam assignments")
	_assert(_unit_id_set(Array(roster.get("units", []))).size() == _unit_id_set(Array(loaded_roster.get("units", []))).size(), "Save/load does not lose roster units")

	var progression_result: Dictionary = Dictionary(MISSION_PROGRESSION_RESOLVER_SCRIPT.call("apply_mission_result", loaded_roster, _build_mission_result(context)))
	var progressed_roster: Dictionary = Dictionary(progression_result.get("updated_roster", {}))
	_assert(_unit_id_set(Array(loaded_roster.get("units", []))) == _unit_id_set(Array(progressed_roster.get("units", []))), "Mission progression keeps roster unit set intact")


func _test_report_exists() -> void:
	_assert(FileAccess.file_exists(REPORT_PATH), "Character card roster switching report exists")
	var report: String = _read_text(REPORT_PATH)
	for required_text in ["Summary", "Covered Screens", "Automated Findings", "Manual Remainder", "State Integrity"]:
		_assert(report.contains(required_text), "Character roster switching report covers %s" % required_text)


func _homebase_lists_keep_all_units(homebase: Node, expected_count: int) -> bool:
	var roster_list := homebase.get_node_or_null("Panel/Margin/VBox/ContentRow/RosterPanel/RosterMargin/RosterVBox/RosterScroll/RosterList") as VBoxContainer
	var team_list := homebase.get_node_or_null("Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/TeamDropPanel/DropMargin/DropVBox/SelectedTeamScroll/SelectedTeamList") as VBoxContainer
	if roster_list == null or team_list == null:
		return false
	return roster_list.get_child_count() + team_list.get_child_count() == expected_count


func _ensure_valid_task_roster() -> Dictionary:
	for suffix in range(12):
		PLAYER_ROSTER_STORE_SCRIPT.call("delete_roster_for_tests", PROFILE_ID, SAVE_PATH)
		var seed: String = "task259_character_switching_%02d" % suffix
		var result: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("ensure_roster", seed, 24, PROFILE_ID, SAVE_PATH))
		var summary: Dictionary = Dictionary(result.get("summary", {}))
		if bool(result.get("ok", false)) and bool(summary.get("valid", false)):
			return result
	return {}


func _open_npc_card(card: Node) -> bool:
	if card == null or not card.has_signal("card_open_requested") or not card.has_method("get_unit_id") or not card.has_method("get_profile"):
		return false
	if not HARNESS_SCRIPT.has_signal_connection(card, "card_open_requested"):
		return false
	var unit_id: String = String(card.call("get_unit_id"))
	var source_context: String = String(card.call("get_source_context")) if card.has_method("get_source_context") else ""
	card.emit_signal("card_open_requested", unit_id, card.call("get_profile"), source_context)
	return true


func _find_npc_card(root_node: Node, unit_id: String, source_context: String = "") -> Node:
	for node in _collect_nodes(root_node):
		if not (node is Node) or not node.has_method("get_unit_id") or not node.has_method("get_source_context"):
			continue
		if String(node.call("get_unit_id")) != unit_id:
			continue
		if not source_context.is_empty() and String(node.call("get_source_context")) != source_context:
			continue
		return node
	return null


func _first_npc_card_in_path(root_node: Node, path: String) -> Node:
	var host := root_node.get_node_or_null(path)
	if host == null:
		return null
	for node in _collect_nodes(host):
		if node != host and node.has_method("get_unit_id") and node.has_signal("card_open_requested"):
			return node
	return null


func _assignment_for_unit(fob: Node, unit_id: String) -> String:
	var selected_unit_ids: PackedStringArray = PackedStringArray(fob.call("get_team"))
	var selected_fireteam_ids: PackedStringArray = PackedStringArray(fob.call("get_selected_fireteam_ids"))
	var index: int = selected_unit_ids.find(unit_id)
	if index < 0 or index >= selected_fireteam_ids.size():
		return ""
	return String(selected_fireteam_ids[index]).strip_edges().to_lower()


func _assignment_integrity(fob: Node, expected_selected_unit_ids: PackedStringArray) -> bool:
	var selected_unit_ids: PackedStringArray = PackedStringArray(fob.call("get_team"))
	var selected_fireteam_ids: PackedStringArray = PackedStringArray(fob.call("get_selected_fireteam_ids"))
	if selected_unit_ids.size() != expected_selected_unit_ids.size() or selected_fireteam_ids.size() != selected_unit_ids.size():
		return false
	var seen: Dictionary = {}
	for unit_id in selected_unit_ids:
		var normalized_unit_id: String = String(unit_id)
		if normalized_unit_id.is_empty() or seen.has(normalized_unit_id) or not expected_selected_unit_ids.has(normalized_unit_id):
			return false
		seen[normalized_unit_id] = true
	return seen.size() == expected_selected_unit_ids.size()


func _apply_assignments_to_roster(roster: Dictionary, selected_unit_ids: PackedStringArray, selected_fireteam_ids: PackedStringArray) -> Dictionary:
	var next_roster: Dictionary = roster.duplicate(true)
	var units: Array = []
	for unit_variant in Array(next_roster.get("units", [])):
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit: Dictionary = Dictionary(unit_variant).duplicate(true)
		var unit_id: String = String(unit.get("unit_id", ""))
		var selected_index: int = selected_unit_ids.find(unit_id)
		if selected_index >= 0 and selected_index < selected_fireteam_ids.size():
			unit["fireteam_id"] = String(selected_fireteam_ids[selected_index])
		units.append(unit)
	next_roster["units"] = units
	return next_roster


func _loaded_roster_preserves_assignments(roster: Dictionary, selected_unit_ids: PackedStringArray, selected_fireteam_ids: PackedStringArray) -> bool:
	var units: Array = Array(roster.get("units", []))
	for selected_index in range(selected_unit_ids.size()):
		var unit: Dictionary = _find_unit(units, String(selected_unit_ids[selected_index]))
		if unit.is_empty():
			return false
		var expected_fireteam_id: String = String(selected_fireteam_ids[selected_index]).strip_edges().to_lower()
		if String(unit.get("fireteam_id", "")).strip_edges().to_lower() != expected_fireteam_id:
			return false
	return true


func _build_mission_result(context: Dictionary) -> Dictionary:
	var selected_unit_ids: PackedStringArray = PackedStringArray(context.get("selected_unit_ids", PackedStringArray()))
	var selected_fireteam_ids: PackedStringArray = PackedStringArray(context.get("selected_fireteam_ids", PackedStringArray()))
	var units: Array = Array(context.get("units", []))
	var team_states: Array = []
	var unit_events: Dictionary = {}
	for index in range(selected_unit_ids.size()):
		var unit_id: String = String(selected_unit_ids[index])
		var unit: Dictionary = _find_unit(units, unit_id)
		team_states.append({
			"unit_id": unit_id,
			"display_name": String(unit.get("display_name", unit_id)),
			"fireteam_id": String(selected_fireteam_ids[index]) if index < selected_fireteam_ids.size() else "",
			"vital_state": "alive",
			"health_points": 10,
		})
		unit_events[unit_id] = {
			"unit_id": unit_id,
			"objective_participation": index <= 1,
			"fired_weapon": index == 0,
			"medic_action": index == 1,
			"healed": index == 1,
			"downed": false,
			"role_mismatch": false,
		}
	return {
		"mission_id": "task259_roster_switching_mission",
		"mission_outcome": "success",
		"result": "success",
		"winning_team_id": "team_alpha",
		"objective_captured": true,
		"duration_seconds": 75.0,
		"selected_unit_ids": selected_unit_ids,
		"selected_fireteam_ids": selected_fireteam_ids,
		"team_states": team_states,
		"unit_events": unit_events,
		"character_events": [
			{
				"unit_id": String(selected_unit_ids[0]),
				"display_name": String(_find_unit(units, String(selected_unit_ids[0])).get("display_name", selected_unit_ids[0])),
				"summary_text": "%s Task259 roster switch smoke awarded mission XP." % String(selected_unit_ids[0]),
			},
		],
	}


func _mission_display_name(mission: Node, unit_id: String) -> String:
	var unit := mission.get_node_or_null("UnitAlpha")
	for child in mission.get_children():
		if child.has_method("get_unit_id") and String(child.call("get_unit_id")) == unit_id:
			unit = child
			break
	if unit != null and unit.has_method("get_display_name"):
		return String(unit.call("get_display_name"))
	return unit_id


func _unit_id_set(units: Array) -> Dictionary:
	var result: Dictionary = {}
	for unit_variant in units:
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit_id: String = String(Dictionary(unit_variant).get("unit_id", "")).strip_edges()
		if not unit_id.is_empty():
			result[unit_id] = true
	return result


func _find_unit(units: Array, unit_id: String) -> Dictionary:
	for unit_variant in units:
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit: Dictionary = Dictionary(unit_variant)
		if String(unit.get("unit_id", "")) == unit_id:
			return unit
	return {}


func _build_fireteam_definition(fireteam_id: String, lead_unit_id: String) -> Dictionary:
	return {
		"id": fireteam_id,
		"label": fireteam_id.to_upper(),
		"lead_unit_id": lead_unit_id,
		"loadout": "medium",
		"respawn_enabled": false,
	}


func _collect_label_texts(root_node: Node) -> PackedStringArray:
	var result := PackedStringArray()
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
	if fragment.strip_edges().is_empty():
		return false
	for text in labels:
		if String(text).contains(fragment):
			return true
	return false


func _control_visible(control: Control) -> bool:
	return control != null and control.visible and (control.is_visible_in_tree() if control.is_inside_tree() else true)


func _same_string_array(first: PackedStringArray, second: PackedStringArray) -> bool:
	if first.size() != second.size():
		return false
	for index in range(first.size()):
		if String(first[index]) != String(second[index]):
			return false
	return true


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
