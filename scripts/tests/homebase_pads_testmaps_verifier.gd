extends SceneTree
## Home base landing pads stand PAD_DECK_TOP above ground (display only) and the two
## old station test maps are not offered in player-facing map lists, but still load.

const MAPS = preload("res://scripts/mission/productive_ground_maps.gd")
const DRESSING = preload("res://scripts/terrain/place_reference_dressing.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const TEST_MAPS: PackedStringArray = ["res://maps/station_outpost_64x64.json", "res://maps/station_outpost_192x192.json"]
var passed: int = 0
var failed: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_check_map_lists()
	_check_allow_list()
	await _check_mission_list()
	await _check_home_base()
	print("HOMEBASE_PADS_TESTMAPS passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)

func _check_map_lists() -> void:
	var selectable: PackedStringArray = MAPS.selectable_paths()
	_check(selectable.size() > 0, "player-facing map list is not empty")
	for path: String in TEST_MAPS:
		_check(not selectable.has(path), "%s is not in the player-facing list" % path.get_file())
		_check(MAPS.TEST_ONLY.has(path), "%s is marked test-only" % path.get_file())
		_check(FileAccess.file_exists(path), "%s is still on disk" % path.get_file())
		var data = MAP.load_from_file(path)
		_check(data != null and data.get_tiles().size() > 0, "%s still loads directly" % path.get_file())
		_check(MAPS.all_paths().has(path), "%s stays in the full catalog used by map verifiers" % path.get_file())
	_check(selectable.has("res://maps/Ground_Mission01_32x32.json") and selectable.has("res://maps/trade_outpost.json"), "regular playable maps stay selectable")

const ALLOW_LIST: PackedStringArray = [
	"res://maps/Ground_Mission01_32x32.json", "res://maps/Ground_Mission02_128x128.json", "res://maps/satellite_crash_site.json",
	"res://maps/trade_outpost.json", "res://maps/windbruch_outpost.json", "res://maps/polisa_station.json",
]
const HIDDEN_MISSIONS: PackedStringArray = ["frontier_probe", "frontier_probe_vertical_slice", "station_route_one_screen_multiplayer_drill"]

func _check_allow_list() -> void:
	_check(MAPS.selectable_paths() == ALLOW_LIST, "selectable list equals the allow-list in order: %s" % [MAPS.selectable_paths()])
	var playable: PackedStringArray = MAPS.playable_paths()
	for path: String in MAPS.TEST_ONLY:
		_check(FileAccess.file_exists(path), "%s (test-only) still exists" % path.get_file())
		_check(MAPS.PLAYABLE.has(path) and playable.has(path), "%s (test-only) is still in playable_paths()" % path.get_file())
		_check(not MAPS.selectable_paths().has(path), "%s (test-only) is not selectable" % path.get_file())
		var data = MAP.load_from_file(path)
		_check(data != null and data.get_tiles().size() > 0, "%s (test-only) still loads" % path.get_file())
	_check(MAPS.TEST_ONLY.size() == 9, "TEST_ONLY documents the nine unoffered maps")

func _check_mission_list() -> void:
	var catalog: Array = load("res://scripts/meta/meta_layer_flow.gd").HOMEBASE_MISSION_CATALOG
	var screen: Control = load("res://scenes/meta/homebase_test_screen.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	screen.call("set_mission_context", catalog, "res://maps/Ground_Mission01_32x32.json", "Operation: Grid Sweep", 3, "grid_sweep")
	var listed: PackedStringArray = PackedStringArray()
	for entry in Array(screen.call("get_operations_snapshot", false).get("missions", [])):
		listed.append(String(Dictionary(entry).get("id", "")))
	var selector := OptionButton.new()
	screen.call("_populate_mission_selector", selector)
	var selector_ids := PackedStringArray()
	for i in range(selector.item_count): selector_ids.append(String(selector.get_item_metadata(i)))
	for mission_id: String in HIDDEN_MISSIONS:
		var found := false
		for entry in catalog:
			found = found or String(Dictionary(entry).get("mission_id", "")) == mission_id
		_check(found, "%s is still in the catalog (startable by id)" % mission_id)
		_check(not listed.has(mission_id), "%s is not in the operations mission list" % mission_id)
		_check(not selector_ids.has(mission_id), "%s is not in the mission selector" % mission_id)
	_check(listed.has("grid_sweep") and listed.has("fob_transfer"), "visible missions stay listed: %s" % [listed])
	selector.free()
	screen.call("set_mission_context", catalog, "res://maps/station_outpost_192x192.json", "Operation: Frontier Probe", 3, "frontier_probe")
	_check(String(screen.call("_resolve_selected_mission_scenario_path")) == "", "hidden mission still resolves by id (frontier_probe)")
	screen.call("set_mission_context", catalog, "res://maps/station_outpost_192x192.json", "x", 8, "station_route_one_screen_multiplayer_drill")
	_check(String(screen.call("_resolve_selected_mission_scenario_path")).ends_with("station_route_one_screen_multiplayer_drill.json"), "hidden mission still resolves by id (station route)")
	screen.queue_free()
	await process_frame
	# Campaign job list: printed so before/after runs can be diffed; must equal jobs.json keys.
	var state = load("res://scripts/core/singleplayer_campaign_state.gd").new()
	_check(bool(state.configure().get("ok", false)), "campaign state configures")
	var job_ids: Array = Dictionary(state.get_campaign_snapshot().jobs).keys()
	job_ids.sort()
	var file_ids: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/jobs.json")).keys()
	file_ids.sort()
	print("CAMPAIGN_JOB_IDS=%s" % [job_ids])
	_check(job_ids == file_ids and not job_ids.is_empty(), "campaign job list is unchanged and non-empty (%d jobs)" % job_ids.size())

func _check_home_base() -> void:
	var base: Control = load("res://scenes/meta/explorable_homebase.tscn").instantiate()
	root.add_child(base)
	await process_frame
	base.set_transport_snapshot({"crafts": [{"craft_id": "actual_ship", "craft_type": "dropship", "display_name": "Real Ship", "landing_pad_id": "homebase_pad_01", "location_id": "homebase", "visible_on_pad": true, "busy": false}]})
	base.set_pad_preview(true, "actual_ship")
	await process_frame
	var stage: Node3D = base.get("_authored_stage")
	var layout: Dictionary = base.get("_layout")
	var pads: Array = Array(layout.get("landing_pads", []))
	_check(stage != null and pads.size() >= 1, "home base stage and landing pads exist")
	for raw_pad in pads:
		var pad: Dictionary = Dictionary(raw_pad)
		if not bool(pad.get("built", true)): continue
		var node: Node3D = stage.get_node_or_null(String(pad.id))
		_check(node != null, "%s visual exists" % pad.id)
		if node == null: continue
		var top := -INF
		var bottom := INF
		for child in node.get_children():
			if child is MeshInstance3D:
				var box: AABB = (child as MeshInstance3D).global_transform * (child as MeshInstance3D).get_aabb()
				if box.size.x < float(pad.size[0]) - 0.5: continue # only the two full-width deck slabs
				top = maxf(top, box.end.y)
				bottom = minf(bottom, box.position.y)
		_check(absf(top - (float(pad.get("surface_y", 0.0)) + DRESSING.PAD_DECK_TOP)) < 0.002, "%s deck top is at PAD_DECK_TOP (%.4f)" % [pad.id, top])
		_check(bottom <= 0.05, "%s deck is not floating (bottom %.3f)" % [pad.id, bottom])
		var plane := Vector3(float(pad.plane[0]), 0.0, float(pad.plane[1]))
		_check(absf(float(base.call("_pad_deck_lift_at", plane)) - DRESSING.PAD_DECK_TOP) < 0.0001, "%s: people on the pad are lifted by PAD_DECK_TOP" % pad.id)
		var outside := plane + Vector3(float(pad.size[0]) * 0.5 + 1.0, 0.0, 0.0)
		_check(is_zero_approx(float(base.call("_pad_deck_lift_at", outside))), "%s: people beside the pad are not lifted" % pad.id)
		_check(Array(pad.plane).size() == 2 and Array(pad.size).size() == 2, "%s: logic plane/size data untouched" % pad.id)
	var entry: Dictionary = Dictionary(base.get("_craft_visuals")).get("actual_ship", {})
	_check(not entry.is_empty(), "parked ship visual exists")
	if not entry.is_empty():
		_check(absf((entry.node as Node3D).position.y - DRESSING.PAD_DECK_TOP) < 0.0001, "parked ship sits on the deck top (y=%.3f)" % (entry.node as Node3D).position.y)
	base.queue_free()
	await process_frame

func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("PASS: " + label)
	else:
		failed += 1
		print("FAIL: " + label)
