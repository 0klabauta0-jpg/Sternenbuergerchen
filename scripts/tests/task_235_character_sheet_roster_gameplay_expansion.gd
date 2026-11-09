extends SceneTree

const START_ROSTER_GENERATOR_SCRIPT: GDScript = preload("res://scripts/meta/start_roster_generator.gd")
const META_UNIT_PROFILE_SCRIPT: GDScript = preload("res://scripts/meta/meta_unit_profile.gd")
const CHARACTER_SHEET_FORMATTER_SCRIPT: GDScript = preload("res://scripts/meta/character_sheet_formatter.gd")
const CHARACTER_SHEET_VIEW_SCRIPT: GDScript = preload("res://scripts/meta/character_sheet_view.gd")
const HOMEBASE_TEST_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const FOB_TEST_SCENE: PackedScene = preload("res://scenes/meta/fob_test_screen.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_235 Character Sheet Roster Gameplay Expansion ===")
	_test_profile_fields_roundtrip()
	_test_sheet_formatter_blocks_and_fallbacks()
	await _test_character_sheet_view_sections()
	await _test_homebase_roster_scanability_with_30_profiles()
	await _test_homebase_and_fob_accept_same_profile_payload()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_profile_fields_roundtrip() -> void:
	var unit: Dictionary = _build_profile_payload()
	var profile = META_UNIT_PROFILE_SCRIPT.new(unit)
	var roundtrip: Dictionary = Dictionary(profile.call("to_dict"))
	_assert(String(profile.availability_status) == "recovering", "MetaUnitProfile stores availability status")
	_assert(String(Dictionary(profile.recovery_state).get("state", "")) == "recovering", "MetaUnitProfile stores recovery state")
	_assert(not Array(profile.relationship_links).is_empty(), "MetaUnitProfile stores relationship links")
	_assert(not Array(profile.fireteam_history).is_empty(), "MetaUnitProfile stores fireteam history")
	_assert(not Array(profile.mission_history).is_empty(), "MetaUnitProfile stores mission history")
	_assert(int(Dictionary(profile.progression).get("xp", 0)) == 12, "MetaUnitProfile stores progression")
	_assert(String(roundtrip.get("portrait_id", "")).begins_with("char_portrait_"), "MetaUnitProfile roundtrips portrait id")
	_assert(not PackedStringArray(roundtrip.get("trait_ids", PackedStringArray())).is_empty(), "MetaUnitProfile roundtrips traits")


func _test_sheet_formatter_blocks_and_fallbacks() -> void:
	var profile = META_UNIT_PROFILE_SCRIPT.new(_build_profile_payload())
	var model: Dictionary = Dictionary(CHARACTER_SHEET_FORMATTER_SCRIPT.call("build_sheet_view_model", profile, {"fireteam_text": "BLUE"}))
	for key in ["role_loadout_rows", "status_rows", "relationship_rows", "progress_rows"]:
		_assert(not Array(model.get(key, [])).is_empty(), "Sheet formatter emits %s" % key)
	_assert(_rows_contain(Array(model.get("status_rows", [])), "Erholung", "In Erholung"), "Sheet status rows include recovery")
	_assert(_rows_contain(Array(model.get("relationship_rows", [])), "Teamfit", "trusts"), "Sheet relationship rows include teamfit summary")
	_assert(_rows_contain(Array(model.get("progress_rows", [])), "XP", "12"), "Sheet progress rows include XP")

	var fallback_profile = META_UNIT_PROFILE_SCRIPT.new({
		"unit_id": "task235_missing_optional",
		"display_name": "Missing Optional",
		"portrait_id": "missing_portrait_id",
		"portrait_path": "",
		"role_name": "Operator",
		"skill_values": {"accuracy": 0.4, "speed": 0.4, "leadership": 0.4, "toughness": 0.4},
	})
	var fallback_model: Dictionary = Dictionary(CHARACTER_SHEET_FORMATTER_SCRIPT.call("build_sheet_view_model", fallback_profile))
	_assert(_rows_contain(Array(fallback_model.get("relationship_rows", [])), "Beziehungen", "Noch keine"), "Missing relationship data falls back cleanly")
	_assert(_rows_contain(Array(fallback_model.get("progress_rows", [])), "Letzter Einsatz", "Noch keine"), "Missing mission history falls back cleanly")


func _test_character_sheet_view_sections() -> void:
	var profile = META_UNIT_PROFILE_SCRIPT.new(_build_profile_payload())
	var host := VBoxContainer.new()
	root.add_child(host)
	CHARACTER_SHEET_VIEW_SCRIPT.call("render", host, profile, {"status_text": "recovering in medbay", "fireteam_text": "BLUE"})
	await process_frame
	var labels: PackedStringArray = _collect_label_texts(host)
	for required_header in ["AUFGABE & EIGNUNG", "STATUS & ERHOLUNG", "ZUSAMMENARBEIT", "ENTWICKLUNG", "KERNWERTE"]:
		_assert(_any_label_contains(labels, required_header), "Character sheet renders section %s" % required_header)
	var portrait_rect := host.find_child("PortraitRect", true, false) as TextureRect
	_assert(portrait_rect != null and portrait_rect.texture != null, "Character sheet portrait fallback/load remains stable")
	_assert(_any_label_contains(labels, "recovering") and _any_label_contains(labels, "trusts"), "Character sheet renders gameplay status and relationship text")
	host.queue_free()
	await process_frame


func _test_homebase_roster_scanability_with_30_profiles() -> void:
	var screen: Control = HOMEBASE_TEST_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	var roster_units: Array = _build_roster_units(30)
	screen.call("setup_roster", roster_units)
	await process_frame
	await process_frame
	var roster_list := screen.get_node("Panel/Margin/VBox/ContentRow/RosterPanel/RosterMargin/RosterVBox/RosterScroll/RosterList") as VBoxContainer
	_assert(roster_list.get_child_count() == 30, "Homebase roster renders 30 scanable compact cards")
	var first_card := roster_list.get_child(0) as Control
	_assert(first_card.custom_minimum_size.y <= 76.0, "Compact roster card keeps bounded height")
	var first_detail := first_card.get_node("Margin/HBox/TextVBox/DataBLabel") as Label
	_assert(first_detail.text.contains("Mondbasis") and first_detail.text.contains("Einsatzbereit"), "Roster compact card combines confirmed status and actual location")
	var sheet_labels: PackedStringArray = _collect_label_texts(screen.get_node("CharacterSheetPopup"))
	_assert(_any_label_contains(sheet_labels, "STATUS & ERHOLUNG") and screen.find_child("CharacterSheetToggle_history", true, false) != null, "Homebase popup preserves gameplay sections behind the compact details action")
	screen.queue_free()
	await process_frame


func _test_homebase_and_fob_accept_same_profile_payload() -> void:
	var roster_units: Array = _build_roster_units(24)
	var homebase: Control = HOMEBASE_TEST_SCENE.instantiate()
	var fob: Control = FOB_TEST_SCENE.instantiate()
	root.add_child(homebase)
	root.add_child(fob)
	await process_frame
	homebase.call("setup_roster", roster_units)
	fob.call("set_available_units", roster_units)
	await process_frame
	await process_frame
	_assert(homebase.find_child("PortraitRect", true, false) != null, "Homebase renders profile portraits from shared payload")
	_assert(fob.find_child("PortraitRect", true, false) != null, "FOB accepts the same profile payload without conversion")
	homebase.queue_free()
	fob.queue_free()
	await process_frame


func _build_roster_units(count: int) -> Array:
	var roster: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("generate_start_roster", "task235_roster", count))
	var units: Array = Array(roster.get("units", []))
	for index in range(units.size()):
		var unit: Dictionary = Dictionary(units[index]).duplicate(true)
		unit["availability_status"] = "recovering" if index == 1 else "active"
		unit["status_text"] = "recovering" if index == 1 else "active"
		unit["relationship_summary_text"] = "trusts Blue Team timing" if index == 0 else "Teamfit pending"
		unit["relationship_links"] = [{"target_unit_id": "player_task235_roster_02", "target_name": "Partner", "affinity": 0.25}] if index == 0 else []
		unit["mission_history"] = [{"mission_id": "grid_sweep", "result": "success"}] if index == 0 else []
		unit["progression"] = {"xp": index, "missions_completed": 1 if index == 0 else 0, "morale": 0.55, "frustration": 0.05}
		units[index] = unit
	return units


func _build_profile_payload() -> Dictionary:
	var units: Array = _build_roster_units(24)
	var unit: Dictionary = Dictionary(units[0]).duplicate(true)
	unit["availability_status"] = "recovering"
	unit["status_text"] = "recovering"
	unit["recovery_state"] = {"state": "recovering", "turns_remaining": 2}
	unit["relationship_summary_text"] = "trusts Blue Team timing; avoids reckless pilots"
	unit["relationship_links"] = [
		{"target_unit_id": "unit_partner", "target_name": "Partner", "affinity": 0.35},
		{"target_unit_id": "unit_rival", "target_name": "Rival", "affinity": -0.20},
	]
	unit["fireteam_history"] = [{"fireteam_id": "blue", "mission_id": "grid_sweep", "result": "success"}]
	unit["mission_history"] = [{"mission_id": "grid_sweep", "result": "success"}]
	unit["progression"] = {"xp": 12, "missions_completed": 3, "morale": 0.65, "frustration": 0.15}
	return unit


func _rows_contain(rows: Array, label_fragment: String, value_fragment: String) -> bool:
	for row_variant in rows:
		if typeof(row_variant) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = Dictionary(row_variant)
		if String(row.get("label", "")).contains(label_fragment) and String(row.get("value_text", "")).contains(value_fragment):
			return true
	return false


func _collect_label_texts(root_node: Node) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for node in _collect_nodes(root_node):
		var label := node as Label
		if label != null:
			result.append(label.text)
	return result


func _any_label_contains(labels: PackedStringArray, fragment: String) -> bool:
	for text in labels:
		if String(text).contains(fragment):
			return true
	return false


func _collect_nodes(root_node: Node) -> Array:
	var nodes: Array = []
	if root_node == null:
		return nodes
	nodes.append(root_node)
	for child in root_node.get_children():
		nodes.append_array(_collect_nodes(child))
	return nodes


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
