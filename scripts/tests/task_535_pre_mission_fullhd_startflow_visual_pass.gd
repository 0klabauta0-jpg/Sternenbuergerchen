extends SceneTree

const HOMEBASE_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/meta/drop_light_layout_contract.gd")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const DROPSHIP_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png"
const TASK_PATH: String = "res://docs/tasks/TASK_535_pre_mission_fullhd_startflow_visual_pass.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const HOMEBASE_PATH: String = "res://scripts/meta/homebase_screen.gd"
const LAYOUT_CONTRACT_PATH: String = "res://scripts/meta/drop_light_layout_contract.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_535 Pre-Mission FullHD Startflow Visual Pass ===")
	_test_docs_and_wiring()
	_test_layout_contract_moves_work_columns_below_mission_deck()
	await _test_blocked_startflow_is_compact_and_non_overlapping()
	await _test_ready_startflow_button_and_readiness_visuals()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_535: FAILED")
		quit(1)
		return
	print("TASK_535: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_535 task file exists")
	_assert(_read_text(TASK_PATH).contains("## Status: IMPLEMENTIERT"), "TASK_535 task file marks implementation")
	_assert(_read_text(STATUS_PATH).contains("TASK_535 - Pre-Mission FullHD Startflow Visual Pass"), "Implementation status tracks TASK_535")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_535 - Pre-Mission FullHD Startflow Visual Pass (implementiert)"), "Roadmap marks TASK_535 implemented")
	_assert(_read_text(REPORT_PATH).contains("TASK_535 - Pre-Mission FullHD Startflow Visual Pass"), "Review workbench tracks TASK_535")
	_assert(_read_text(HOMEBASE_PATH).contains("get_pre_mission_startflow_visual_snapshot"), "Homebase exposes startflow visual snapshot")
	_assert(_read_text(LAYOUT_CONTRACT_PATH).contains("Rect2i(24, 80, 1872, 568)"), "Homebase layout contract reserves a real mission deck")


func _test_layout_contract_moves_work_columns_below_mission_deck() -> void:
	var layout: Dictionary = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_homebase_layout")
	var mission_rect: Rect2i = layout.get("mission_brief")
	for key in ["roster", "fireteams", "flightdeck"]:
		var rect: Rect2i = layout.get(key)
		_assert(rect.position.y >= mission_rect.end.y + 16, "%s starts below the expanded mission deck" % key)
		_assert(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("is_rect_inside_viewport", rect), "%s stays inside FullHD viewport" % key)
	_assert(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("is_rect_inside_viewport", mission_rect), "Mission deck stays inside FullHD viewport")
	_assert(mission_rect.size.y >= 560, "Mission deck has enough vertical room for briefing and readiness")


func _test_blocked_startflow_is_compact_and_non_overlapping() -> void:
	var homebase: Node = await _build_homebase(false)
	var visual: Dictionary = Dictionary(homebase.call("get_pre_mission_startflow_visual_snapshot"))
	var readiness: Dictionary = Dictionary(homebase.call("get_pre_mission_readiness_snapshot"))
	_assert(not bool(visual.get("ui_sets_gameplay_truth", true)), "Startflow visual snapshot remains read-only")
	_assert(not bool(visual.get("mission_overlaps_work_columns", true)), "Mission deck does not overlap roster/fireteam/flightdeck columns")
	_assert(not bool(visual.get("mission_child_overflows", true)), "Mission deck children fit inside the fixed FullHD mission deck")
	_assert(float(visual.get("briefing_min_height", 999.0)) <= 170.0, "Briefing panel is compact enough for top deck")
	_assert(float(visual.get("readiness_min_height", 999.0)) <= 80.0, "Readiness panel is compact enough for top deck")
	_assert(int(readiness.get("rendered_item_columns", 0)) == 4, "Readiness renders as a four-column chip grid")
	_assert(String(visual.get("start_button_text", "")) == "Start blockiert", "Blocked startflow labels the start button as blocked")
	_assert(bool(visual.get("start_button_disabled", false)), "Blocked startflow keeps start button disabled")
	_assert(String(visual.get("start_button_tooltip", "")).to_lower().contains("block"), "Blocked start button tooltip explains readiness")
	homebase.queue_free()
	await process_frame


func _test_ready_startflow_button_and_readiness_visuals() -> void:
	var homebase: Node = await _build_homebase(true)
	var briefing_snapshot: Dictionary = Dictionary(homebase.call("get_mission_briefing_panel_snapshot"))
	var cards: Array = Array(briefing_snapshot.get("loadout_card_entries", []))
	var recommendation_id: String = String(Dictionary(cards[0]).get("recommendation_id", "")).strip_edges()
	homebase.call("select_briefing_loadout_recommendation", recommendation_id)
	homebase.call("apply_briefing_loadout_recommendation_to_unit_ids", recommendation_id, PackedStringArray(["unit_alpha", "unit_bravo"]))
	_drop_fireteam_on_shipcard(homebase, "ft1", "dropship_alpha")
	await process_frame
	homebase.call("_debug_advance_homebase_direct_boarding", 9.2)
	await process_frame
	await process_frame

	var visual: Dictionary = Dictionary(homebase.call("get_pre_mission_startflow_visual_snapshot"))
	var readiness: Dictionary = Dictionary(homebase.call("get_pre_mission_readiness_snapshot"))
	_assert(String(visual.get("readiness_overall_state", "")) == "ready", "Ready startflow reports ready readiness state")
	_assert(String(visual.get("start_button_text", "")) == "Start Mission", "Ready startflow labels the start command clearly")
	_assert(not bool(visual.get("start_button_disabled", true)), "Ready startflow keeps the start button enabled")
	_assert(String(visual.get("start_button_tooltip", "")).contains("Startbereit"), "Ready start button tooltip mirrors readiness summary")
	_assert(String(readiness.get("rendered_item_text", "")).contains("OK Start"), "Ready readiness chip line includes start-ready state")
	_assert(not bool(visual.get("mission_overlaps_work_columns", true)), "Ready mission deck still does not overlap work columns")
	_assert(not bool(visual.get("mission_child_overflows", true)), "Ready mission deck content still fits")
	homebase.queue_free()
	await process_frame


func _build_homebase(with_team: bool) -> Node:
	var homebase: Node = HOMEBASE_SCENE.instantiate()
	root.add_child(homebase)
	await process_frame
	var roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	if with_team:
		homebase.call("setup_roster", roster, PackedStringArray(["unit_alpha", "unit_bravo"]))
		homebase.call(
			"set_fireteam_context",
			PackedStringArray(["ft1", "ft1"]),
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
	else:
		homebase.call("setup_roster", roster, PackedStringArray())
		homebase.call("set_fireteam_context", PackedStringArray(), [])
	homebase.call(
		"set_transport_state",
		[
			{
				"craft_id": "dropship_alpha",
				"craft_type": "dropship",
				"display_name": "Dropship",
				"texture_path": DROPSHIP_TEXTURE_PATH,
				"supports_cargo": false,
				"cargo_options": [],
			}
		],
		{"dropship_alpha": "unit_delta"},
		[],
		[],
		{"dropship_alpha": "homebase"},
		{},
		{},
		[]
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


func _drop_fireteam_on_shipcard(screen: Node, fireteam_id: String, craft_id: String) -> void:
	var target := _find_shipcard_drop_target(screen, craft_id)
	if target == null:
		return
	target.call("_drop_data", Vector2.ZERO, {"type": "fob_fireteam_card", "fireteam_id": fireteam_id})


func _find_shipcard_drop_target(screen: Node, craft_id: String) -> Control:
	var aircraft_panel := screen.get_node_or_null("Panel/Margin/VBox/ContentRow/AircraftPanel")
	for node in _collect_nodes(aircraft_panel):
		if node is Control \
			and bool((node as Control).get_meta("homebase_fireteam_drop_target", false)) \
			and String((node as Control).get_meta("homebase_fireteam_drop_target_id", "")).strip_edges() == craft_id:
			return node as Control
	return null


func _collect_nodes(root_node: Node) -> Array:
	var nodes: Array = []
	if root_node == null:
		return nodes
	nodes.append(root_node)
	for child in root_node.get_children():
		nodes.append_array(_collect_nodes(child))
	return nodes


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
