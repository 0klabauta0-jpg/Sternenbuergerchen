extends SceneTree

class StationController extends "res://scripts/tests/mission_tactical_sandbox_controller.gd":
	var test_map
	var test_registry
	var test_view
	func _ready() -> void: pass
	func _process(_delta: float) -> void: pass
	func _get_active_mission_terrain_map_data_for_readability(): return test_map
	func _get_terrain_registry(): return test_registry
	func _get_primary_3d_view(): return test_view

var failures := 0
func _initialize() -> void: call_deferred("_run")
func check(value: bool, label: String) -> void:
	print("%s: %s" % ["PASS" if value else "FAIL", label])
	if not value: failures += 1

func _run() -> void:
	var map = load("res://scripts/terrain/terrain_map_data.gd").load_from_file("res://maps/polisa_station.json")
	var registry = load("res://scripts/terrain/terrain_registry.gd").new()
	var size: Dictionary = map.get_tile_size()
	registry.configure_iso_grid(map.get_grid_origin(), size.half_width, size.half_height, map.get_grid_topology())
	for tile in map.get_tiles(): registry.register_tile(tile)
	var station := Node.new(); station.set_meta("location_id", "polisa"); root.add_child(station)
	station.add_child(registry)
	var view = load("res://scripts/terrain/terrain_map_3d_view.gd").new()
	var controller := StationController.new(); controller.test_map=map; controller.test_registry=registry; controller.test_view=view; station.add_child(controller)
	var craft := {"craft_id":"collision-test-shuttle", "model_id":"cutlass", "craft_type":"dropship", "crew_capacity":8}
	var projection: Dictionary = view.get_station_craft_body_projection(craft)
	check(projection.get("ok", false), "actual Cutlass renderer model and bounds load")
	var pads: Array = load("res://scripts/mission/polisa_station_craft_runtime.gd").station_pads(map)
	check(pads.size()==7, "all seven authored station pads loaded")
	for pad: Dictionary in pads:
		var admission: Dictionary = controller.preview_station_craft_admission(craft, pad.pad_id)
		if not admission.get("ok", false): print("ADMISSION: ", pad.pad_id, " ", admission)
		check(admission.get("ok", false), "%s accepts actual Cutlass body" % pad.pad_id)
		if not admission.get("ok",false): continue
		var raster: Dictionary = load("res://scripts/mission/hex_ground_ship_footprint.gd").new().cells_for_body(registry,craft,admission.position,admission.ground_body_profile)
		check(raster.get("ok",false) and not raster.get("blocked_cells",[]).is_empty(), "%s yields nonempty actual ship mask" % pad.pad_id)
		var body: Dictionary = load("res://scripts/mission/polisa_station_craft_runtime.gd").projected_body(admission.position, admission.ground_body_profile)
		var conflict: Dictionary = load("res://scripts/mission/polisa_station_craft_runtime.gd").preview_admission(craft, [pad], admission.ground_body_profile, [{"pad_id":pad.pad_id,"footprint":body.footprint}], pad.pad_id)
		check(not conflict.get("ok",false), "%s rejects occupied ship footprint" % pad.pad_id)
		controller._mission_drop_cards = [craft.duplicate(true)]
		controller._parallel_drop_sequences_by_craft[craft.craft_id] = {"craft_id":craft.craft_id,"phase":"complete","lz_position":admission.position,"position":admission.position}
		controller._field_landing_by_craft[craft.craft_id] = {"ground_body_profile":admission.ground_body_profile,"resolved_lz_position":admission.position}
		var rect: Rect2 = body.footprint
		var near_plane := Vector2(rect.end.x + 0.5, rect.get_center().y)
		var far_plane := Vector2(rect.end.x + 5.0, rect.get_center().y)
		var near_world := Vector2(64.0 * (near_plane.x-near_plane.y),32.0 * (near_plane.x+near_plane.y))
		var far_world := Vector2(64.0 * (far_plane.x-far_plane.y),32.0 * (far_plane.x+far_plane.y))
		check(controller._campaign_unit_near_boarding_ship(craft.craft_id,near_world,admission.position), "%s boarding accepts position beside hull" % pad.pad_id)
		check(not controller._campaign_unit_near_boarding_ship(craft.craft_id,far_world,admission.position), "%s boarding rejects remote position" % pad.pad_id)
		var mask: Dictionary = controller.get_ground_ship_blocked_cells()
		var own: Dictionary = controller.get_ground_ship_blocked_cells(craft.craft_id)
		check(mask.get("ok",false) and mask.get("blocked_cells",[]).size()==raster.blocked_cells.size(), "%s controller uses actual footprint" % pad.pad_id)
		check(own.get("ok",false) and own.get("blocked_cells",[]).is_empty(), "%s boarding ignores own hull only" % pad.pad_id)
		var other := {"craft_id":"second-ship", "model_id":"cutlass", "craft_type":"dropship", "crew_capacity":8}
		var real_conflict: Dictionary = controller.preview_station_craft_admission(other, pad.pad_id)
		check(not real_conflict.get("ok",false), "%s controller blocks second ship" % pad.pad_id)
		controller._mission_drop_cards.clear(); controller._parallel_drop_sequences_by_craft.clear(); controller._field_landing_by_craft.clear()
	view.free(); station.free()
	print("RESULT: %d failures" % failures)
	if failures==0: print("POLISA_ACTUAL_STATION_COLLISION_PASS")
	quit(0 if failures==0 else 1)
