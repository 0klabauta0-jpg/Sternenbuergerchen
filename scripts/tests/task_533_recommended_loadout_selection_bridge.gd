extends SceneTree

const BRIEFING_PANEL_PRESENTER_SCRIPT: GDScript = preload("res://scripts/mission/mission_briefing_panel_presenter.gd")
const HOMEBASE_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const TASK_PATH: String = "res://docs/tasks/TASK_533_recommended_loadout_selection_bridge.md"
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
	print("=== TASK_533 Recommended Loadout Selection Bridge ===")
	_test_docs_and_wiring()
	_test_panel_presenter_exposes_readonly_recommendation_patch()
	await _test_homebase_selects_without_mutation_then_applies_after_confirm()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_533: FAILED")
		quit(1)
		return
	print("TASK_533: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_533 task file exists")
	_assert(_read_text(TASK_PATH).contains("## Status: IMPLEMENTIERT"), "TASK_533 task file marks implementation")
	_assert(_read_text(STATUS_PATH).contains("TASK_533 - Recommended Loadout Selection Bridge"), "Implementation status tracks TASK_533")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_533 - Recommended Loadout Selection Bridge (implementiert)"), "Roadmap marks TASK_533 implemented")
	_assert(_read_text(CONTRACT_PATH).contains("Recommended-Loadout-Selection-Bridge"), "Briefing contract documents selection bridge")
	_assert(_read_text(REPORT_PATH).contains("TASK_533 - Recommended Loadout Selection Bridge"), "Review workbench tracks TASK_533")
	_assert(_read_text(PRESENTER_PATH).contains("recommendation_id"), "Briefing presenter exposes recommendation IDs")
	_assert(_read_text(HOMEBASE_PATH).contains("apply_briefing_loadout_recommendation_to_unit_ids"), "Homebase exposes confirmed apply bridge")


func _test_panel_presenter_exposes_readonly_recommendation_patch() -> void:
	var snapshot: Dictionary = Dictionary(BRIEFING_PANEL_PRESENTER_SCRIPT.new().call("build_snapshot_from_files", SCENARIO_PATH, MAP_PATH, "multiplayer_pvp"))
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Briefing panel snapshot remains read-only")
	var cards: Array = Array(snapshot.get("loadout_card_entries", []))
	_assert(cards.size() == 2, "Snapshot exposes two recommendation cards")
	var first: Dictionary = Dictionary(cards[0])
	_assert(not String(first.get("recommendation_id", "")).strip_edges().is_empty(), "Recommendation card has stable ID")
	_assert(String(first.get("primary_weapon_id", "")) == "sniper", "Recommendation exposes primary weapon")
	_assert(String(first.get("secondary_weapon_id", "")) == "rocket_launcher", "Recommendation exposes secondary weapon")
	_assert(Array(first.get("support_weapon_ids", [])).has("medictool"), "Recommendation keeps support weapon IDs")
	var patch: Dictionary = Dictionary(first.get("loadout_patch_preview", {}))
	_assert(String(patch.get("weapon_1", "")) == "sniper", "Patch preview uses existing member loadout keys")
	_assert(not _has_mutating_loadout_key(snapshot), "Pure briefing snapshot still exposes no mutating command keys")


func _test_homebase_selects_without_mutation_then_applies_after_confirm() -> void:
	var homebase: Node = await _build_homebase()
	var panel_snapshot: Dictionary = Dictionary(homebase.call("get_mission_briefing_panel_snapshot"))
	_assert(int(panel_snapshot.get("rendered_recommended_loadout_button_count", 0)) == 2, "Homebase renders two selectable recommendation buttons")
	var cards: Array = Array(panel_snapshot.get("loadout_card_entries", []))
	var recommendation_id: String = String(Dictionary(cards[0]).get("recommendation_id", "")).strip_edges()
	var before_bridge: Dictionary = Dictionary(homebase.call("get_briefing_loadout_bridge_snapshot"))
	var before_loadouts: Dictionary = Dictionary(before_bridge.get("selected_unit_loadouts", {})).duplicate(true)
	var before_alpha: Dictionary = Dictionary(before_loadouts.get("unit_alpha", {}))
	_assert(String(before_alpha.get("weapon_1", "")) != "sniper", "Alpha starts without recommended sniper primary")

	var selected: Dictionary = Dictionary(homebase.call("select_briefing_loadout_recommendation", recommendation_id))
	_assert(String(selected.get("selected_recommendation_id", "")) == recommendation_id, "Selecting recommendation stores bridge selection")
	_assert(bool(selected.get("apply_ready", false)), "Bridge is ready when selected units exist")
	_assert(int(selected.get("apply_count", -1)) == 0, "Selecting recommendation does not apply it")
	var selected_loadouts: Dictionary = Dictionary(selected.get("selected_unit_loadouts", {}))
	var selected_alpha: Dictionary = Dictionary(selected_loadouts.get("unit_alpha", {}))
	_assert(String(selected_alpha.get("weapon_1", "")) == String(before_alpha.get("weapon_1", "")), "Selection alone does not mutate member loadout")

	var applied: Dictionary = Dictionary(homebase.call("apply_briefing_loadout_recommendation_to_unit_ids", recommendation_id, PackedStringArray(["unit_alpha", "unit_bravo"])))
	_assert(bool(applied.get("ok", false)), "Confirmed apply succeeds for staged fireteam operators")
	_assert(int(applied.get("apply_count", 0)) == 1, "Confirmed apply increments apply count")
	_assert(Array(applied.get("applied_unit_ids", [])).has("unit_alpha") and Array(applied.get("applied_unit_ids", [])).has("unit_bravo"), "Confirmed apply reports affected operators")
	var after_loadouts: Dictionary = Dictionary(applied.get("selected_unit_loadouts", {}))
	var after_alpha: Dictionary = Dictionary(after_loadouts.get("unit_alpha", {}))
	_assert(String(after_alpha.get("armor", "")) == "medium", "Confirmed apply preserves recommendation armor")
	_assert(String(after_alpha.get("weapon_1", "")) == "sniper", "Confirmed apply writes primary weapon")
	_assert(String(after_alpha.get("weapon_2", "")) == "rocket_launcher", "Confirmed apply writes secondary weapon")
	var post_panel: Dictionary = Dictionary(homebase.call("get_mission_briefing_panel_snapshot"))
	_assert(String(post_panel.get("recommended_loadout_feedback_text", "")).contains("angewendet"), "Panel snapshot exposes apply feedback")
	_assert(not bool(post_panel.get("ui_sets_gameplay_truth", true)), "Homebase briefing snapshot remains read-only display state")
	homebase.queue_free()
	await process_frame


func _build_homebase() -> Node:
	var homebase: Node = HOMEBASE_SCENE.instantiate()
	root.add_child(homebase)
	await process_frame
	var roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	homebase.call("setup_roster", roster, PackedStringArray(["unit_alpha", "unit_bravo", "unit_charlie"]))
	homebase.call(
		"set_fireteam_context",
		PackedStringArray(["ft1", "ft1", "ft1"]),
		[
			{
				"id": "ft1",
				"label": "ALPHA",
				"lead_unit_id": "unit_alpha",
				"loadout": "medium",
				"respawn_enabled": false,
			}
		]
	)
	homebase.call(
		"set_mission_context",
		[
			{
				"mission_id": "frontier_probe_vertical_slice",
				"mission_name": "Operation: Frontier Probe Slice",
				"map_file_path": MAP_PATH,
				"scenario_file_path": SCENARIO_PATH,
				"slot_count": 8,
				"time_limit_seconds": 1500.0,
				"win_condition": "objective_capture",
			},
		],
		MAP_PATH,
		"Operation: Frontier Probe Slice",
		8,
		"frontier_probe_vertical_slice"
	)
	await process_frame
	await process_frame
	return homebase


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
