extends SceneTree

const CHARACTER_SHEET_FORMATTER_SCRIPT: GDScript = preload("res://scripts/meta/character_sheet_formatter.gd")
const CHARACTER_SHEET_VIEW_SCRIPT: GDScript = preload("res://scripts/meta/character_sheet_view.gd")
const META_UNIT_PROFILE_SCRIPT: GDScript = preload("res://scripts/meta/meta_unit_profile.gd")
const START_ROSTER_GENERATOR_SCRIPT: GDScript = preload("res://scripts/meta/start_roster_generator.gd")
const FOB_TEST_SCENE: PackedScene = preload("res://scenes/meta/fob_test_screen.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

const CATALOG_PATH: String = "res://data/contextual_help_catalog.json"
const COPY_DOC_PATH: String = "res://docs/content/character_sheet_loadout_help_copy.md"
const TASK_PATH: String = "res://docs/tasks/TASK_265_character_sheet_loadout_help_content_pass.md"

const REQUIRED_CATALOG_IDS: Array = [
	"character_sheet.identity",
	"character_sheet.role_loadout",
	"character_sheet.role",
	"character_sheet.fireteam_assignment",
	"character_sheet.rank_badges",
	"character_sheet.traits",
	"character_sheet.status_recovery",
	"character_sheet.status",
	"character_sheet.recovery",
	"character_sheet.morale",
	"character_sheet.frustration",
	"character_sheet.teamfit",
	"character_sheet.progression",
	"character_sheet.xp",
	"character_sheet.core_values",
	"character_sheet.core.accuracy",
	"character_sheet.core.speed",
	"character_sheet.core.toughness",
	"character_sheet.core.leadership",
	"character_sheet.communication",
	"character_sheet.platform_skills",
	"character_sheet.derived_badges",
	"character_sheet.behavior_profile",
	"character_sheet.loadout_summary",
	"loadout.member_row",
	"loadout.armor",
	"loadout.weapon_slot",
	"loadout.weapon.smg",
	"loadout.weapon.rifle",
	"loadout.weapon.sniper",
	"loadout.weapon.rocket_launcher",
	"loadout.weapon.medictool",
	"loadout.weapon.none",
	"loadout.weapon.lmg",
	"loadout.weapon_visual_only",
	"loadout.weight",
	"loadout.weapon_preview",
	"loadout.weapon_none",
	"loadout.disabled_reason",
	"loadout.clear_selection",
	"loadout.empty_team_default",
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_265 Character Sheet Loadout Help Content Pass ===")
	var catalog: Dictionary = _load_json(CATALOG_PATH)
	_test_catalog_content(catalog)
	_test_formatter_help_ids(catalog)
	await _test_character_sheet_rendered_help_ids(catalog)
	await _test_fob_loadout_help_ids(catalog)
	_test_copy_doc()
	_test_task_status()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_catalog_content(catalog: Dictionary) -> void:
	_assert(not catalog.is_empty(), "Contextual help catalog parses")
	var entries: Array = Array(catalog.get("entries", []))
	var ids: Dictionary = {}
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		var help_id: String = String(entry.get("help_id", ""))
		_assert(not ids.has(help_id), "Catalog help_id is unique: %s" % help_id)
		ids[help_id] = entry
		_assert(String(entry.get("title", "")).length() <= 48, "%s title fits compact rule" % help_id)
		var compact_lines: Array = Array(entry.get("compact_lines", []))
		if REQUIRED_CATALOG_IDS.has(help_id):
			_assert(compact_lines.size() >= 1 and compact_lines.size() <= 3, "%s has compact help" % help_id)
		for compact_line in compact_lines:
			_assert(String(compact_line).length() <= 96, "%s compact line fits" % help_id)
		for detail_line in Array(entry.get("detail_lines", [])):
			_assert(String(detail_line).length() <= 140, "%s detail line fits" % help_id)
	for required_id in REQUIRED_CATALOG_IDS:
		_assert(ids.has(required_id), "Catalog contains %s" % required_id)
		var entry: Dictionary = Dictionary(ids.get(required_id, {}))
		if required_id == "loadout.weapon.lmg":
			_assert(String(entry.get("status", "")) == "planned", "LMG is marked planned until WeaponData exists")
		else:
			_assert(String(entry.get("status", "")) == "ready", "%s is ready help copy" % required_id)
	_assert("\n".join(PackedStringArray(Dictionary(ids.get("loadout.weapon_visual_only", {})).get("detail_lines", []))).contains("WeaponData"), "Visual-only copy names WeaponData boundary")
	_assert("\n".join(PackedStringArray(Dictionary(ids.get("loadout.weapon.none", {})).get("detail_lines", []))).contains("no hidden fallback weapon"), "None copy forbids hidden fallback")


func _test_formatter_help_ids(catalog: Dictionary) -> void:
	var catalog_ids: Dictionary = _catalog_id_set(catalog)
	var profile = META_UNIT_PROFILE_SCRIPT.new(_build_profile_payload())
	var model: Dictionary = Dictionary(CHARACTER_SHEET_FORMATTER_SCRIPT.call("build_sheet_view_model", profile, {"fireteam_text": "BLUE"}))
	for row_group in ["role_loadout_rows", "status_rows", "relationship_rows", "progress_rows", "core_rows", "communication_rows", "behavior_rows"]:
		for row_variant in Array(model.get(row_group, [])):
			var row: Dictionary = Dictionary(row_variant)
			var help_id: String = String(row.get("help_id", ""))
			_assert(not help_id.is_empty(), "%s row %s carries help_id" % [row_group, String(row.get("label", ""))])
			_assert(catalog_ids.has(help_id), "Catalog contains formatter row help_id %s" % help_id)
	_assert(_rows_contain_help_id(Array(model.get("role_loadout_rows", [])), "Loadout", "character_sheet.loadout_summary"), "Loadout row uses loadout help_id")
	_assert(_rows_contain_help_id(Array(model.get("status_rows", [])), "Morale", "character_sheet.morale"), "Morale row uses morale help_id")
	_assert(_rows_contain_help_id(Array(model.get("status_rows", [])), "Frustration", "character_sheet.frustration"), "Frustration row uses frustration help_id")


func _test_character_sheet_rendered_help_ids(catalog: Dictionary) -> void:
	var catalog_ids: Dictionary = _catalog_id_set(catalog)
	var profile = META_UNIT_PROFILE_SCRIPT.new(_build_profile_payload())
	var host := VBoxContainer.new()
	root.add_child(host)
	CHARACTER_SHEET_VIEW_SCRIPT.call("render", host, profile, {"fireteam_text": "BLUE", "loadout_text": "Heavy Armor | Rocket | Keine Waffe | Weight 9.0"})
	await process_frame
	var help_ids: PackedStringArray = _collect_help_ids(host)
	for required_id in [
		"character_sheet.identity",
		"character_sheet.traits",
		"character_sheet.role_loadout",
		"character_sheet.loadout_summary",
		"character_sheet.status_recovery",
		"character_sheet.teamfit",
		"character_sheet.progression",
		"character_sheet.core_values",
		"character_sheet.core.accuracy",
		"character_sheet.core.speed",
		"character_sheet.core.leadership",
	]:
		_assert(help_ids.has(required_id), "Rendered character sheet carries %s" % required_id)
	for help_id in help_ids:
		_assert(catalog_ids.has(String(help_id)), "Rendered help_id has catalog entry: %s" % help_id)
	host.queue_free()
	await process_frame


func _test_fob_loadout_help_ids(catalog: Dictionary) -> void:
	var catalog_ids: Dictionary = _catalog_id_set(catalog)
	var screen: Control = FOB_TEST_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	var roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	screen.call("set_available_units", roster)
	screen.call("configure_transfer", PackedStringArray(["unit_alpha", "unit_bravo"]), PackedStringArray(["ft1", "ft1"]), [])
	screen.call("_on_staging_fireteam_dropped", "ft1", "loadout")
	screen.call("_set_member_loadout", "ft1", "unit_alpha", "heavy", "rocket_launcher", "none")
	await _wait_frames(3)
	var loadout_panel := screen.get_node("Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/LoadoutPanel")
	var help_ids: PackedStringArray = _collect_help_ids(loadout_panel)
	for required_id in [
		"loadout.member_row",
		"loadout.armor",
		"loadout.weapon_slot",
		"loadout.weight",
		"loadout.weapon_preview",
		"loadout.weapon_none",
		"loadout.empty_team_default",
	]:
		_assert(help_ids.has(required_id), "FOB loadout UI carries %s" % required_id)
	for help_id in help_ids:
		_assert(catalog_ids.has(String(help_id)), "FOB help_id has catalog entry: %s" % help_id)
	var weapon_2_preview := _find_node_by_name(loadout_panel, "Weapon2Preview") as TextureRect
	_assert(weapon_2_preview != null and String(weapon_2_preview.get_meta("help_id", "")) == "loadout.weapon_none", "None preview uses empty-slot help_id")
	_assert(weapon_2_preview != null and weapon_2_preview.tooltip_text.contains("No weapon"), "None preview keeps clear empty-slot tooltip")
	screen.queue_free()
	await process_frame


func _test_copy_doc() -> void:
	_assert(FileAccess.file_exists(COPY_DOC_PATH), "Character/loadout help copy doc exists")
	var doc_text: String = _read_text(COPY_DOC_PATH)
	for required_text in ["Character Sheet IDs", "Loadout IDs", "Source Rules", "Copy Rules", "WeaponData", "LoadoutModifierResolver"]:
		_assert(doc_text.contains(required_text), "Copy doc covers %s" % required_text)


func _test_task_status() -> void:
	var task_text: String = _read_text(TASK_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "TASK_265 is marked implemented")
	_assert(not task_text.contains("- [ ]"), "TASK_265 checklist is complete")


func _build_profile_payload() -> Dictionary:
	var roster: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("generate_start_roster", "task265_roster", 8))
	var units: Array = Array(roster.get("units", []))
	var unit: Dictionary = Dictionary(units[0]).duplicate(true) if not units.is_empty() else {}
	unit["availability_status"] = "recovering"
	unit["status_text"] = "recovering"
	unit["recovery_state"] = {"state": "recovering", "turns_remaining": 2}
	unit["relationship_summary_text"] = "trusts Blue Team timing"
	unit["relationship_links"] = [{"target_unit_id": "unit_partner", "target_name": "Partner", "affinity": 0.35}]
	unit["fireteam_history"] = [{"fireteam_id": "blue", "mission_id": "grid_sweep", "result": "success"}]
	unit["mission_history"] = [{"mission_id": "grid_sweep", "result": "success"}]
	unit["progression"] = {"xp": 12, "missions_completed": 3, "morale": 0.65, "frustration": 0.15}
	return unit


func _rows_contain_help_id(rows: Array, label: String, help_id: String) -> bool:
	for row_variant in rows:
		var row: Dictionary = Dictionary(row_variant)
		if String(row.get("label", "")) == label and String(row.get("help_id", "")) == help_id:
			return true
	return false


func _catalog_id_set(catalog: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for entry_variant in Array(catalog.get("entries", [])):
		var entry: Dictionary = Dictionary(entry_variant)
		result[String(entry.get("help_id", ""))] = true
	return result


func _collect_help_ids(node: Node) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	if node == null:
		return result
	if node.has_meta("help_id"):
		var help_id: String = String(node.get_meta("help_id", "")).strip_edges()
		if not help_id.is_empty() and not result.has(help_id):
			result.append(help_id)
	for child in node.get_children():
		for child_help_id in _collect_help_ids(child):
			if not result.has(child_help_id):
				result.append(child_help_id)
	return result


func _find_node_by_name(node: Node, target_name: String) -> Node:
	if node == null:
		return null
	if node.name == target_name:
		return node
	for child in node.get_children():
		var found := _find_node_by_name(child, target_name)
		if found != null:
			return found
	return null


func _load_json(path: String) -> Dictionary:
	var text: String = _read_text(path)
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return Dictionary(parsed)
	return {}


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		print("  FAIL: %s" % message)
