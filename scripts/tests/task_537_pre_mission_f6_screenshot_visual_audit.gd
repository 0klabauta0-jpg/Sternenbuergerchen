extends SceneTree

const HOMEBASE_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const DROPSHIP_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png"
const TASK_PATH: String = "res://docs/tasks/TASK_537_pre_mission_f6_screenshot_visual_audit.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_briefing_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const HOMEBASE_PATH: String = "res://scripts/meta/homebase_screen.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_537 Pre-Mission F6 Screenshot Visual Audit ===")
	_test_docs_and_wiring()
	await _test_blocked_startflow_visual_audit()
	await _test_ready_startflow_visual_audit()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_537: FAILED")
		quit(1)
		return
	print("TASK_537: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_537 task file exists")
	_assert(_read_text(TASK_PATH).contains("## Status: IMPLEMENTIERT"), "TASK_537 task file marks implementation")
	_assert(_read_text(STATUS_PATH).contains("TASK_537 - Pre-Mission F6 Screenshot Visual Audit"), "Implementation status tracks TASK_537")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_537 - Pre-Mission F6 Screenshot Visual Audit (implementiert)"), "Roadmap marks TASK_537 implemented")
	_assert(_read_text(CONTRACT_PATH).contains("Pre-Mission-Visual-Audit"), "Briefing contract documents visual audit")
	_assert(_read_text(REPORT_PATH).contains("TASK_537 - Pre-Mission F6 Screenshot Visual Audit"), "Review workbench tracks TASK_537")
	_assert(_read_text(HOMEBASE_PATH).contains("get_pre_mission_visual_audit_snapshot"), "Homebase exposes visual audit snapshot")
	_assert(_read_text(HOMEBASE_PATH).contains("readiness_text_color_hex"), "Readiness chips expose text color metadata")


func _test_blocked_startflow_visual_audit() -> void:
	var homebase: Node = await _build_homebase(false)
	var audit: Dictionary = Dictionary(homebase.call("get_pre_mission_visual_audit_snapshot"))
	var readiness: Dictionary = Dictionary(homebase.call("get_pre_mission_readiness_snapshot"))
	var chips: Array = Array(readiness.get("rendered_item_visuals", []))
	_assert(not bool(audit.get("ui_sets_gameplay_truth", true)), "Blocked audit remains read-only")
	_assert(String(audit.get("audit_id", "")) == "pre_mission_f6_visual_audit_v1", "Blocked audit uses stable audit id")
	_assert(String(audit.get("automated_visual_gate", "")) == "pass", "Blocked startflow passes automated visual gate")
	_assert(int(audit.get("failed_count", -1)) == 0, "Blocked startflow has no critical visual failures")
	_assert(bool(audit.get("manual_screenshot_required", false)), "Blocked audit still marks manual screenshot as required")
	_assert(not bool(audit.get("manual_screenshot_done", true)), "Blocked audit does not pretend a manual screenshot happened")
	_assert(String(audit.get("readiness_overall_state", "")) == "blocked", "Blocked audit preserves readiness state")
	_assert(float(audit.get("readiness_text_min_contrast", 0.0)) >= 4.5, "Blocked readiness text contrast is readable")
	_assert(float(audit.get("readiness_status_min_contrast", 0.0)) >= 3.0, "Blocked readiness status contrast is visible")
	_assert(_all_chips_have_text_color(chips), "Blocked readiness chip visuals expose text colors")
	_assert(_check_passed(audit, "start_button_matches_readiness"), "Blocked start button matches readiness")
	homebase.queue_free()
	await process_frame


func _test_ready_startflow_visual_audit() -> void:
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

	var audit: Dictionary = Dictionary(homebase.call("get_pre_mission_visual_audit_snapshot"))
	_assert(String(audit.get("automated_visual_gate", "")) == "pass", "Ready startflow passes automated visual gate")
	_assert(int(audit.get("failed_count", -1)) == 0, "Ready startflow has no critical visual failures")
	_assert(String(audit.get("readiness_overall_state", "")) == "ready", "Ready audit preserves readiness state")
	_assert(int(audit.get("readiness_chip_count", 0)) >= 6, "Ready audit counts readiness chips")
	_assert(float(audit.get("mission_deck_density", 0.0)) > 0.20, "Ready mission deck uses visible space")
	_assert(_check_passed(audit, "mission_deck_bounds"), "Ready mission deck stays in bounds")
	_assert(_check_passed(audit, "readiness_chip_grid"), "Ready readiness grid stays stable")
	_assert(_check_passed(audit, "readiness_chip_contrast"), "Ready readiness chip contrast passes")
	_assert(_check_passed(audit, "start_button_color_matches_readiness"), "Ready start button color matches readiness")
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


func _check_passed(audit: Dictionary, check_id: String) -> bool:
	for check_variant in Array(audit.get("checks", [])):
		var check: Dictionary = Dictionary(check_variant)
		if String(check.get("id", "")) == check_id:
			return bool(check.get("passed", false))
	return false


func _all_chips_have_text_color(chips: Array) -> bool:
	if chips.is_empty():
		return false
	for chip_variant in chips:
		var chip: Dictionary = Dictionary(chip_variant)
		if String(chip.get("text_color_hex", "")).strip_edges().length() != 6:
			return false
	return true


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
