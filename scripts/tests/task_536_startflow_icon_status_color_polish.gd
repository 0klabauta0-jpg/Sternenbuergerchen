extends SceneTree

const HOMEBASE_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const DROPSHIP_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png"
const TASK_PATH: String = "res://docs/tasks/TASK_536_startflow_icon_status_color_polish.md"
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
	print("=== TASK_536 Startflow Icon And Status Color Polish ===")
	_test_docs_and_wiring()
	await _test_blocked_readiness_chips_have_status_visuals()
	await _test_ready_readiness_chips_and_start_button_color()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_536: FAILED")
		quit(1)
		return
	print("TASK_536: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_536 task file exists")
	_assert(_read_text(TASK_PATH).contains("## Status: IMPLEMENTIERT"), "TASK_536 task file marks implementation")
	_assert(_read_text(STATUS_PATH).contains("TASK_536 - Startflow Icon And Status Color Polish"), "Implementation status tracks TASK_536")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_536 - Startflow Icon And Status Color Polish (implementiert)"), "Roadmap marks TASK_536 implemented")
	_assert(_read_text(CONTRACT_PATH).contains("Startflow-Statuschips"), "Briefing contract documents startflow status chips")
	_assert(_read_text(REPORT_PATH).contains("TASK_536 - Startflow Icon And Status Color Polish"), "Review workbench tracks TASK_536")
	_assert(_read_text(HOMEBASE_PATH).contains("_build_readiness_chip_style"), "Homebase builds readiness chip styles")
	_assert(_read_text(HOMEBASE_PATH).contains("pre_mission_readiness_color_hex"), "Start button exposes readiness color metadata")


func _test_blocked_readiness_chips_have_status_visuals() -> void:
	var homebase: Node = await _build_homebase(false)
	var snapshot: Dictionary = Dictionary(homebase.call("get_pre_mission_readiness_snapshot"))
	var visual: Dictionary = Dictionary(homebase.call("get_pre_mission_startflow_visual_snapshot"))
	var chips: Array = Array(snapshot.get("rendered_item_visuals", []))
	var start_chip: Dictionary = _find_chip(chips, "start")
	_assert(not chips.is_empty(), "Readiness snapshot exposes chip visual entries")
	_assert(_all_chips_have_visuals(chips), "Every readiness chip has state, icon and color")
	_assert(String(start_chip.get("state", "")) == "blocked", "Blocked start chip keeps blocked state")
	_assert(String(start_chip.get("icon_text", "")) == "STOP", "Blocked start chip uses STOP icon text")
	_assert(String(start_chip.get("color_hex", "")) == "d66c66", "Blocked start chip uses danger color")
	_assert(String(start_chip.get("tooltip", "")).length() > String(start_chip.get("text", "")).length(), "Blocked chip keeps detailed tooltip")
	_assert(String(visual.get("start_button_readiness_color", "")) == "d66c66", "Blocked start button exposes matching danger color")
	_assert(_chips_use_at_least_two_status_colors(chips), "Blocked readiness set exposes multiple status colors")
	homebase.queue_free()
	await process_frame


func _test_ready_readiness_chips_and_start_button_color() -> void:
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
	var visual: Dictionary = Dictionary(homebase.call("get_pre_mission_startflow_visual_snapshot"))
	var chips: Array = Array(snapshot.get("rendered_item_visuals", []))
	var start_chip: Dictionary = _find_chip(chips, "start")
	_assert(String(start_chip.get("state", "")) == "ready", "Ready start chip keeps ready state")
	_assert(String(start_chip.get("icon_text", "")) == "OK", "Ready start chip uses OK icon text")
	_assert(String(start_chip.get("color_hex", "")) == "69c391", "Ready start chip uses ready color")
	_assert(String(visual.get("start_button_readiness_color", "")) == "69c391", "Ready start button exposes matching ready color")
	_assert(String(snapshot.get("rendered_item_text", "")).contains("OK Start"), "Chip text remains readable for older snapshots")
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


func _find_chip(chips: Array, item_id: String) -> Dictionary:
	for chip_variant in chips:
		var chip: Dictionary = Dictionary(chip_variant)
		if String(chip.get("id", "")).strip_edges() == item_id:
			return chip
	return {}


func _all_chips_have_visuals(chips: Array) -> bool:
	for chip_variant in chips:
		var chip: Dictionary = Dictionary(chip_variant)
		if String(chip.get("state", "")).strip_edges().is_empty():
			return false
		if String(chip.get("icon_text", "")).strip_edges().is_empty():
			return false
		if String(chip.get("color_hex", "")).strip_edges().length() != 6:
			return false
	return not chips.is_empty()


func _chips_use_at_least_two_status_colors(chips: Array) -> bool:
	var colors: Dictionary = {}
	for chip_variant in chips:
		var chip: Dictionary = Dictionary(chip_variant)
		var color_hex: String = String(chip.get("color_hex", "")).strip_edges()
		if not color_hex.is_empty():
			colors[color_hex] = true
	return colors.size() >= 2


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
