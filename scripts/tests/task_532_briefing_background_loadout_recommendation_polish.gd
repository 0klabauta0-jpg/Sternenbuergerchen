extends SceneTree

const BRIEFING_PANEL_PRESENTER_SCRIPT: GDScript = preload("res://scripts/mission/mission_briefing_panel_presenter.gd")
const HOMEBASE_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")

const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const BACKGROUND_PATH: String = "res://Assets/used/npc/weapon_pack/previews/rocketlauncherModern.png"
const TASK_PATH: String = "res://docs/tasks/TASK_532_briefing_background_loadout_recommendation_polish.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_briefing_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const HOMEBASE_PATH: String = "res://scripts/meta/homebase_screen.gd"
const PRESENTER_PATH: String = "res://scripts/mission/mission_briefing_panel_presenter.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_532 Briefing Background / Loadout Recommendation Polish ===")
	_test_docs_and_wiring()
	_test_panel_presenter_exposes_background_and_loadout_cards()
	await _test_homebase_renders_background_and_loadout_cards()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_532: FAILED")
		quit(1)
		return
	print("TASK_532: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_532 task file exists")
	_assert(_read_text(TASK_PATH).contains("## Status: IMPLEMENTIERT"), "TASK_532 task file marks implementation")
	_assert(_read_text(STATUS_PATH).contains("TASK_532 - Briefing Background / Loadout Recommendation Polish"), "Implementation status tracks TASK_532")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_532 - Briefing Background / Loadout Recommendation Polish (implementiert)"), "Roadmap marks TASK_532 implemented")
	_assert(_read_text(CONTRACT_PATH).contains("Briefing-Bild-/Loadout-Polish"), "Briefing contract documents image/loadout polish")
	_assert(_read_text(REPORT_PATH).contains("TASK_532 - Briefing Background / Loadout Recommendation Polish"), "Review workbench tracks TASK_532")
	_assert(_read_text(PRESENTER_PATH).contains("loadout_card_entries"), "Briefing presenter exposes loadout cards")
	_assert(_read_text(HOMEBASE_PATH).contains("BriefingBackgroundImage"), "Homebase creates briefing background image")
	_assert(_read_text(HOMEBASE_PATH).contains("BriefingLoadoutCards"), "Homebase creates briefing loadout cards")


func _test_panel_presenter_exposes_background_and_loadout_cards() -> void:
	var snapshot: Dictionary = Dictionary(BRIEFING_PANEL_PRESENTER_SCRIPT.new().call("build_snapshot_from_files", SCENARIO_PATH, MAP_PATH, "multiplayer_pvp"))
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Briefing panel snapshot remains read-only")
	_assert(String(snapshot.get("background_image_path", "")) == BACKGROUND_PATH, "Snapshot exposes briefing background image path")
	_assert(bool(snapshot.get("background_image_exists", false)), "Snapshot verifies briefing background image exists")
	_assert(String(snapshot.get("background_image_status_text", "")).contains("rocketlauncherModern"), "Snapshot exposes image status text")
	_assert(int(snapshot.get("loadout_card_count", 0)) == 2, "Snapshot exposes two loadout cards")
	var cards: Array = Array(snapshot.get("loadout_card_entries", []))
	_assert(_card_text_contains(cards, "Solo / Alpha"), "Loadout cards include Solo / Alpha")
	_assert(_card_text_contains(cards, "Coop / Fireteam"), "Loadout cards include Coop / Fireteam")
	_assert(_card_text_contains(cards, "rocket_launcher"), "Loadout cards keep rocket launcher recommendation")
	_assert(_card_text_contains(cards, "rail_gun"), "Loadout cards keep rail gun recommendation")
	_assert(not _has_mutating_loadout_key(snapshot), "Briefing snapshot does not expose mutating loadout command keys")


func _test_homebase_renders_background_and_loadout_cards() -> void:
	var homebase: Node = HOMEBASE_SCENE.instantiate()
	root.add_child(homebase)
	await process_frame
	var catalog: Array = [
		{
			"mission_id": "frontier_probe_vertical_slice",
			"mission_name": "Operation: Frontier Probe Slice",
			"map_file_path": MAP_PATH,
			"scenario_file_path": SCENARIO_PATH,
			"slot_count": 8,
			"time_limit_seconds": 1500.0,
			"win_condition": "objective_capture",
		},
	]
	homebase.call("set_mission_context", catalog, MAP_PATH, "Operation: Frontier Probe Slice", 8, "frontier_probe_vertical_slice")
	await process_frame
	await process_frame
	var snapshot: Dictionary = Dictionary(homebase.call("get_mission_briefing_panel_snapshot"))
	_assert(bool(snapshot.get("rendered_background_visible", false)), "Homebase renders briefing background image")
	_assert(bool(snapshot.get("rendered_background_has_texture", false)), "Homebase background image has texture")
	_assert(String(snapshot.get("rendered_background_tooltip", "")).contains("rocketlauncherModern"), "Homebase background tooltip names image")
	_assert(int(snapshot.get("rendered_loadout_card_count", 0)) == 2, "Homebase renders two loadout cards")
	_assert(String(snapshot.get("rendered_loadout_card_text", "")).contains("Solo / Alpha"), "Homebase loadout cards include Solo / Alpha")
	_assert(String(snapshot.get("rendered_loadout_card_text", "")).contains("rail_gun"), "Homebase loadout cards include rail gun")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Homebase briefing snapshot remains read-only")
	homebase.queue_free()
	await process_frame


func _card_text_contains(cards: Array, needle: String) -> bool:
	var normalized_needle: String = needle.strip_edges()
	for card_variant in cards:
		var text: String = JSON.stringify(card_variant)
		if text.contains(normalized_needle):
			return true
	return false


func _has_mutating_loadout_key(value: Variant) -> bool:
	var mutating_keys: PackedStringArray = PackedStringArray(["apply_loadout", "set_loadout", "commit_loadout", "loadout_command"])
	if typeof(value) == TYPE_DICTIONARY:
		var value_dict: Dictionary = Dictionary(value)
		for key_variant in value_dict.keys():
			var key_text: String = String(key_variant).strip_edges().to_lower()
			if mutating_keys.has(key_text):
				return true
			if _has_mutating_loadout_key(value_dict.get(key_variant)):
				return true
	elif typeof(value) == TYPE_ARRAY:
		for item_variant in Array(value):
			if _has_mutating_loadout_key(item_variant):
				return true
	return false


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
