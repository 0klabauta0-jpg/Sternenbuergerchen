extends SceneTree

const CATALOG_PATH: String = "res://data/portrait_identity_catalog.json"
const INVENTORY_DOC_PATH: String = "res://docs/assets/portrait_identity_inventory.md"
const PORTRAIT_CATALOG_SCRIPT: GDScript = preload("res://scripts/meta/portrait_identity_catalog.gd")
const START_ROSTER_GENERATOR_SCRIPT: GDScript = preload("res://scripts/meta/start_roster_generator.gd")
const META_UNIT_PROFILE_SCRIPT: GDScript = preload("res://scripts/meta/meta_unit_profile.gd")
const CHARACTER_SHEET_VIEW_SCRIPT: GDScript = preload("res://scripts/meta/character_sheet_view.gd")
const NPC_COMPACT_CARD_SCRIPT: GDScript = preload("res://scripts/meta/npc_compact_card.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_233 Portrait Identity Catalog and Roster Presentation ===")
	_test_inventory_doc_and_json()
	_test_catalog_helper_validation_and_loadability()
	_test_deterministic_assignment()
	_test_start_roster_generator_uses_portrait_ids()
	await _test_character_sheet_and_roster_card_contract()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_inventory_doc_and_json() -> void:
	var catalog: Dictionary = _load_json(CATALOG_PATH)
	var doc: String = _read_text(INVENTORY_DOC_PATH)
	_assert(not catalog.is_empty(), "Portrait catalog JSON exists and parses")
	_assert(not doc.is_empty(), "Portrait inventory doc exists")
	_assert(int(catalog.get("schema_version", 0)) == 1, "Portrait catalog schema is v1")
	_assert(String(catalog.get("catalog_id", "")) == "portrait_identity_catalog_v1", "Portrait catalog has stable catalog id")
	var source_png_count: int = _count_char_pngs()
	_assert(int(Dictionary(catalog.get("legacy_source_inventory", {})).get("scanned_png_count", 0)) == source_png_count, "Legacy inventory still records all original PNGs under Assets/Char")
	_assert(doc.contains("PNG-Dateien gesamt: %d" % source_png_count), "Inventory doc records total PNG count")
	_assert(doc.contains("96x120") and doc.contains("64x64") and doc.contains("38x38"), "Inventory doc documents fixed UI target sizes")
	var active_count: int = _count_pngs("res://Assets/curated/portraits/frontier_20261105/sheets")
	_assert(active_count == 11, "Active source directory has all eleven portrait sheets")
	_assert(int(Dictionary(catalog.get("source_inventory", {})).get("scanned_png_count", 0)) == active_count, "Active inventory records actual portrait sheet count")
	_assert(doc.contains("Aktive Viererboegen: %d" % active_count), "Inventory doc records the current atlas count")
	_assert(String(catalog.get("source_root", "")) == "res://Assets/curated/portraits/frontier_20261105/", "Active catalog uses the curated project-local portrait package")


func _test_catalog_helper_validation_and_loadability() -> void:
	var validation: Dictionary = Dictionary(PORTRAIT_CATALOG_SCRIPT.call("validate_catalog"))
	_assert(bool(validation.get("valid", false)), "Portrait catalog validates")
	_assert(int(validation.get("entry_count", 0)) >= 30, "Portrait catalog contains at least 30 entries")
	_assert(int(validation.get("candidate_count", 0)) >= 30, "Portrait catalog contains at least 30 start-roster candidates")
	_assert(int(validation.get("loadable_count", 0)) >= 30, "Portrait catalog contains at least 30 loadable portraits")
	_assert(int(validation.get("large_source_count", 0)) > 0, "Shared source atlas handling is diagnosed")
	var loaded: Dictionary = Dictionary(PORTRAIT_CATALOG_SCRIPT.call("load_catalog"))
	var seen_ids: Dictionary = {}
	for entry_variant in Array(loaded.get("entries", [])):
		var entry: Dictionary = Dictionary(entry_variant)
		var id: String = String(entry.get("id", ""))
		var path: String = String(entry.get("path", ""))
		_assert(not id.is_empty(), "Portrait entry has stable id")
		_assert(not seen_ids.has(id), "Portrait id is unique: %s" % id)
		seen_ids[id] = true
		_assert(path.begins_with(String(loaded.get("source_root", ""))), "Portrait path uses active curated project root: %s" % id)
		_assert(not path.contains("C:/") and not path.contains("C:\\"), "Portrait path is not an absolute local path: %s" % id)
		_assert(ResourceLoader.exists(path), "ResourceLoader sees portrait path: %s" % id)
		_assert(ResourceLoader.load(path) != null, "ResourceLoader loads portrait texture: %s" % id)


func _test_deterministic_assignment() -> void:
	var role_plan: PackedStringArray = PackedStringArray()
	for index in range(30):
		role_plan.append(String(START_ROSTER_GENERATOR_SCRIPT.VALID_ROLE_CATEGORIES[index % START_ROSTER_GENERATOR_SCRIPT.VALID_ROLE_CATEGORIES.size()]))
	var first: Array = Array(PORTRAIT_CATALOG_SCRIPT.call("build_deterministic_assignment", "task233_seed", 30, role_plan))
	var second: Array = Array(PORTRAIT_CATALOG_SCRIPT.call("build_deterministic_assignment", "task233_seed", 30, role_plan))
	var other: Array = Array(PORTRAIT_CATALOG_SCRIPT.call("build_deterministic_assignment", "task233_other", 30, role_plan))
	_assert(first.size() == 30, "Portrait assignment returns requested 30 entries")
	_assert(_assignment_fingerprint(first) == _assignment_fingerprint(second), "Same seed returns same portrait assignment")
	_assert(_assignment_fingerprint(first) != _assignment_fingerprint(other), "Different seed changes portrait assignment order")
	var seen_ids: Dictionary = {}
	for entry_variant in first:
		var entry: Dictionary = Dictionary(entry_variant)
		var id: String = String(entry.get("id", ""))
		_assert(not seen_ids.has(id), "Thirty-entry assignment does not repeat portrait id: %s" % id)
		seen_ids[id] = true
		_assert(ResourceLoader.exists(String(entry.get("path", ""))), "Assigned portrait path is loadable: %s" % id)


func _test_start_roster_generator_uses_portrait_ids() -> void:
	var roster: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("generate_start_roster", "task233_roster", 30, "player_portrait"))
	var validation: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("validate_roster", roster))
	_assert(bool(roster.get("valid", false)), "Generated roster remains valid with portrait catalog")
	_assert(bool(validation.get("valid", false)), "Roster validator accepts catalog portrait paths")
	var units: Array = Array(roster.get("units", []))
	_assert(units.size() == 30, "Generated roster can fill 30 portrait-backed NPCs")
	var seen_portrait_ids: Dictionary = {}
	for unit_variant in units:
		var unit: Dictionary = Dictionary(unit_variant)
		var portrait_id: String = String(unit.get("portrait_id", ""))
		var portrait_path: String = String(unit.get("portrait_path", ""))
		_assert(portrait_id.begins_with("char_portrait_"), "Generated unit has catalog portrait id")
		_assert(not seen_portrait_ids.has(portrait_id), "Generated 30-unit roster does not repeat portrait id: %s" % portrait_id)
		seen_portrait_ids[portrait_id] = true
		_assert(portrait_path.begins_with("res://Assets/curated/portraits/frontier_20261105/portraits/"), "Generated unit portrait path stays under active curated portrait root")
		_assert(ResourceLoader.exists(portrait_path), "Generated unit portrait path is loadable")
		var profile = META_UNIT_PROFILE_SCRIPT.new(unit)
		_assert(String(profile.portrait_id) == portrait_id and String(profile.portrait_path) == portrait_path, "MetaUnitProfile preserves portrait id and path")


func _test_character_sheet_and_roster_card_contract() -> void:
	var assignment: Array = Array(PORTRAIT_CATALOG_SCRIPT.call("build_deterministic_assignment", "task233_ui", 1))
	var entry: Dictionary = Dictionary(assignment[0])
	var profile = META_UNIT_PROFILE_SCRIPT.new({
		"unit_id": "task233_ui_unit",
		"display_name": "Task 233 UI Unit",
		"portrait_id": String(entry.get("id", "")),
		"portrait_path": String(entry.get("path", "")),
		"callsign": "PORT",
		"role_name": "Combat Medic",
		"roster_role_category": "medic",
		"skill_values": {"accuracy": 0.5, "speed": 0.5, "leadership": 0.5, "toughness": 0.5},
	})

	var sheet_host := VBoxContainer.new()
	root.add_child(sheet_host)
	CHARACTER_SHEET_VIEW_SCRIPT.call("render", sheet_host, profile)
	await process_frame
	var sheet_portrait := sheet_host.find_child("PortraitRect", true, false) as TextureRect
	_assert(sheet_portrait != null, "Character sheet creates a portrait TextureRect")
	_assert(sheet_portrait.texture != null, "Character sheet portrait loads through catalog helper")
	_assert(sheet_portrait.custom_minimum_size == Vector2(96.0, 120.0), "Character sheet portrait uses 96x120 target")
	_assert(sheet_portrait.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED, "Character sheet portrait is constrained by TextureRect crop")

	var card = NPC_COMPACT_CARD_SCRIPT.new()
	root.add_child(card)
	card.call("setup_from_profile", profile, {"compact_mode": false})
	await process_frame
	var card_portrait := card.get_node("Margin/HBox/PortraitRect") as TextureRect
	_assert(card_portrait.texture != null, "Roster card portrait loads through catalog helper")
	_assert(card_portrait.custom_minimum_size == Vector2(64.0, 64.0), "Roster card portrait uses 64x64 target")
	card.call("setup_from_profile", profile, {"compact_mode": true})
	await process_frame
	_assert(card_portrait.custom_minimum_size == Vector2(38.0, 38.0), "Compact roster card portrait uses 38x38 target")
	sheet_host.queue_free()
	card.queue_free()
	await process_frame


func _assignment_fingerprint(entries: Array) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		parts.append("%s:%s" % [String(entry.get("id", "")), String(entry.get("path", ""))])
	return "\n".join(parts)


func _count_char_pngs() -> int:
	return _count_pngs("res://Assets/Char")


func _count_pngs(path: String) -> int:
	var dir := DirAccess.open(path)
	if dir == null:
		return 0
	var count: int = 0
	dir.list_dir_begin()
	var entry_name: String = dir.get_next()
	while not entry_name.is_empty():
		if not dir.current_is_dir() and entry_name.get_extension().to_lower() == "png":
			count += 1
		entry_name = dir.get_next()
	dir.list_dir_end()
	return count


func _load_json(path: String) -> Dictionary:
	var text: String = _read_text(path)
	if text.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return Dictionary(parsed)


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
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
