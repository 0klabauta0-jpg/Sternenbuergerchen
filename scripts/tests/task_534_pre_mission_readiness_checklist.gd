extends SceneTree

const PRE_MISSION_READINESS_PRESENTER_SCRIPT: GDScript = preload("res://scripts/mission/pre_mission_readiness_presenter.gd")
const HOMEBASE_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const DROPSHIP_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png"
const TASK_PATH: String = "res://docs/tasks/TASK_534_pre_mission_readiness_checklist.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_briefing_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const HOMEBASE_PATH: String = "res://scripts/meta/homebase_screen.gd"
const PRESENTER_PATH: String = "res://scripts/mission/pre_mission_readiness_presenter.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_534 Pre-Mission Readiness Checklist ===")
	_test_docs_and_wiring()
	_test_presenter_blocks_empty_payload()
	await _test_homebase_renders_blocked_readiness()
	await _test_homebase_renders_ready_direct_payload()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_534: FAILED")
		quit(1)
		return
	print("TASK_534: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_534 task file exists")
	_assert(_read_text(TASK_PATH).contains("## Status: IMPLEMENTIERT"), "TASK_534 task file marks implementation")
	_assert(_read_text(STATUS_PATH).contains("TASK_534 - Pre-Mission Readiness Checklist"), "Implementation status tracks TASK_534")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_534 - Pre-Mission Readiness Checklist (implementiert)"), "Roadmap marks TASK_534 implemented")
	_assert(_read_text(CONTRACT_PATH).contains("Pre-Mission-Readiness"), "Briefing contract documents readiness checklist")
	_assert(_read_text(REPORT_PATH).contains("TASK_534 - Pre-Mission Readiness Checklist"), "Review workbench tracks TASK_534")
	_assert(_read_text(PRESENTER_PATH).contains("PreMissionReadinessPresenter"), "Readiness presenter exists")
	_assert(_read_text(HOMEBASE_PATH).contains("get_pre_mission_readiness_snapshot"), "Homebase exposes readiness snapshot")


func _test_presenter_blocks_empty_payload() -> void:
	var snapshot: Dictionary = Dictionary(PRE_MISSION_READINESS_PRESENTER_SCRIPT.new().call("build_snapshot", {
		"briefing": {"configured": true, "valid": true, "title": "Briefing"},
		"loadout": {},
		"aircraft": {},
		"staging": {"selected_unit_ids": [], "payload_operator_count": 0, "payload_fireteam_ids": []},
		"can_start": false,
	}))
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Presenter snapshot remains read-only")
	_assert(String(snapshot.get("overall_state", "")) == "blocked", "Empty payload blocks readiness")
	_assert(int(snapshot.get("blocked_count", 0)) >= 3, "Empty payload exposes multiple blockers")
	_assert(_find_item_state(snapshot, "start") == "blocked", "Start item follows blocked guard")


func _test_homebase_renders_blocked_readiness() -> void:
	var homebase: Node = await _build_homebase(false)
	var snapshot: Dictionary = Dictionary(homebase.call("get_pre_mission_readiness_snapshot"))
	_assert(bool(snapshot.get("panel_visible", false)), "Homebase renders readiness panel")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Homebase readiness snapshot remains read-only")
	_assert(String(snapshot.get("overall_state", "")) == "blocked", "Empty Homebase state is not start-ready")
	_assert(int(snapshot.get("rendered_item_count", 0)) >= 8, "Readiness panel renders all checklist items")
	_assert(String(snapshot.get("rendered_item_text", "")).contains("X Start"), "Rendered list explains blocked start")
	homebase.queue_free()
	await process_frame


func _test_homebase_renders_ready_direct_payload() -> void:
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

	var snapshot: Dictionary = Dictionary(homebase.call("get_pre_mission_readiness_snapshot"))
	_assert(bool(snapshot.get("can_start", false)), "Readiness snapshot mirrors the existing can-start guard")
	_assert(String(snapshot.get("overall_state", "")) == "ready", "Ready direct payload has no blocking readiness items")
	_assert(_find_item_state(snapshot, "team") == "ready", "Team item is ready")
	_assert(_find_item_state(snapshot, "loadout") == "ready", "Loadout recommendation apply is visible as ready")
	_assert(_find_item_state(snapshot, "dropship") == "ready", "Dropship item is ready")
	_assert(_find_item_state(snapshot, "boarding") == "ready", "Boarding item is ready")
	_assert(_find_item_state(snapshot, "start") == "ready", "Start item is ready")
	_assert(String(snapshot.get("rendered_summary_text", "")).contains("Startbereit"), "Rendered readiness summary names start-ready state")
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


func _find_item_state(snapshot: Dictionary, item_id: String) -> String:
	for item_variant in Array(snapshot.get("items", [])):
		var item: Dictionary = Dictionary(item_variant)
		if String(item.get("id", "")).strip_edges() == item_id:
			return String(item.get("state", "")).strip_edges()
	return ""


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
