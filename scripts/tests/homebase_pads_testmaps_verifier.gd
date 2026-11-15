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
