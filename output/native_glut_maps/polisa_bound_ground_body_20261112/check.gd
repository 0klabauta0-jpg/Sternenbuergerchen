extends SceneTree
const CATALOG = preload("res://scripts/terrain/frontier_ship_visuals.gd")
const BODY = preload("res://scripts/mission/polisa_station_craft_runtime.gd")

class FakeView extends Node:
	var yaw := 0.0
	var calls: Array[String] = []
	var returned: Dictionary = {}
	func get_station_craft_body_projection(craft: Dictionary) -> Dictionary:
		calls.append(String(craft.craft_id))
		var asset: Dictionary = CATALOG.get_ui_identity(craft)
		var d: Array = asset.bounds_size
		returned = {"ok":true,"model_id":craft.model_id,"asset_id":asset.asset_id,
			"bounds":AABB(Vector3(-float(d[0])*0.5,0,-float(d[2])*0.5),Vector3(d[0],d[1],d[2])),
			"model_scale":asset.scale,"cell_size":1.0,"yaw_degrees":yaw}
		return returned

class FakeMap extends RefCounted:
	var markers := {}
	func _init() -> void:
		var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BODY.LAYOUT_PATH))
		for pad in layout.pads:
			var center := Vector2(float(pad.center[0])+float(layout.origin_plane[0]),float(pad.center[1])+float(layout.origin_plane[1]))
			markers[String(pad.id)] = Vector2(64*(center.x-center.y),32*(center.x+center.y))
	func has_marker(id: String) -> bool: return markers.has(id)
	func get_marker_position(id: String) -> Vector2: return markers[id]

class FakeRegistry extends Node:
	func world_to_grid(_p: Vector2) -> Vector2i: return Vector2i.ZERO
	func grid_to_world(_p: Vector2i) -> Vector2: return Vector2.ZERO
	func get_grid_topology() -> String: return "hex_axial_v1"
	func get_tile_at_grid(_p: Vector2i) -> Dictionary: return {"height_level":0,"object_height":0}
	func is_walkable(_p: Vector2i) -> bool: return true

class Controller extends "res://scripts/tests/mission_tactical_sandbox_controller.gd":
	var fake_view: Node
	var fake_map: RefCounted
	var fake_registry: Node
	func _get_primary_3d_view(): return fake_view
	func _get_active_mission_terrain_map_data_for_readability(): return fake_map
	func _get_terrain_registry(): return fake_registry
	func _get_mission_dropship_card_entries() -> Array: return _mission_drop_cards.duplicate(true)
	func _build_drop_sequence_card_fields(sequence: Dictionary) -> Dictionary:
		return {"craft_id":sequence.craft_id,"state":"complete","lz_position":sequence.position,"has_lz_position":true}
	func _update_mission_dropship_card_fields(id: String, fields: Dictionary) -> void:
		var card := fields.duplicate(true); card["craft_id"] = id; _mission_drop_cards.append(card)

var passed := 0
var failed := 0
func check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failed += 1
	print("PASS " if value else "FAIL ",label)

func _initialize() -> void:
	var mission = Node.new(); mission.set_meta("location_id","polisa")
	var controller = Controller.new(); mission.add_child(controller)
	var view = FakeView.new(); var registry = FakeRegistry.new()
	controller.fake_view = view; controller.fake_map = FakeMap.new(); controller.fake_registry = registry
	controller._mission_drop_cards = []; controller._mission_drop_craft_id = ""
	var first := {"craft_id":"first","model_id":"cutlass","craft_type":"dropship","crew_capacity":8}
	var second := {"craft_id":"second","model_id":"buccaneer","craft_type":"fighter","crew_capacity":1}
	var preview: Dictionary = controller.preview_station_craft_admission(first,"polisa_pad_01")
	check(preview.get("ok",false) and preview.has("ground_body_profile"),"Preview exposes checked value profile")
	if preview.get("ok",false) and preview.has("ground_body_profile"):
		var saved := Dictionary(preview.ground_body_profile).duplicate(true)
		view.returned.model_scale = 99.0
		check(preview.ground_body_profile == saved,"Preview has no renderer dictionary alias")
	var admitted: Dictionary = controller.admit_station_craft(first,"polisa_pad_01","buy-first")
	check(admitted.get("ok",false) and controller._field_landing_by_craft.get("first",{}).has("ground_body_profile"),"Admission binds profile with existing location")
	if controller._field_landing_by_craft.get("first",{}).has("ground_body_profile"):
		var bound: Dictionary = controller._field_landing_by_craft.first.ground_body_profile.duplicate(true)
		view.returned.yaw_degrees = 181.0
		check(controller._field_landing_by_craft.first.ground_body_profile == bound,"Bound profile has no view alias")
		var footprint: Dictionary = BODY.projected_body(controller._parallel_drop_sequences_by_craft.first.lz_position,bound)
		view.yaw = 93.0; view.calls.clear()
		var next: Dictionary = controller.preview_station_craft_admission(second,"polisa_pad_02")
		check(next.get("ok",false) and not view.calls.has("first"),"Occupied craft never reprojects from changed camera")
		check(BODY.projected_body(controller._parallel_drop_sequences_by_craft.first.lz_position,controller._field_landing_by_craft.first.ground_body_profile) == footprint,"Camera change preserves occupied footprint")
		var revised := bound.duplicate(true); revised.yaw_degrees = 17.0
		controller._field_landing_by_craft.first.ground_body_profile = revised
		var changed: Dictionary = controller.preview_station_craft_admission(second,"polisa_pad_02")
		check(changed.get("ok",false) and changed.owner_signature != next.owner_signature,"Preview digest includes relevant occupied profile")
		var tampered := bound.duplicate(true); tampered.craft_id = "foreign"
		controller._field_landing_by_craft.first.ground_body_profile = tampered
		check(controller.preview_station_craft_admission(second).get("reason") == "ground_ship_geometry_unbound","Foreign craft profile rejected")
		tampered = bound.duplicate(true); tampered.model_id = "buccaneer"
		controller._field_landing_by_craft.first.ground_body_profile = tampered
		check(controller.preview_station_craft_admission(second).get("reason") == "ground_ship_geometry_unbound","Foreign model profile rejected")
		tampered = bound.duplicate(true); tampered.asset_id = "wrong_asset"
		controller._field_landing_by_craft.first.ground_body_profile = tampered
		check(controller.preview_station_craft_admission(second).get("reason") == "ground_ship_geometry_unbound","Foreign asset profile rejected")
		tampered = bound.duplicate(true); tampered.cell_size = "1"
		controller._field_landing_by_craft.first.ground_body_profile = tampered
		check(controller.preview_station_craft_admission(second).get("reason") == "ground_ship_geometry_unbound","Nonprimitive numeric coercion rejected")
	controller._field_landing_by_craft.first.erase("ground_body_profile")
	var before: Dictionary = controller._field_landing_by_craft.duplicate(true)
	check(controller.preview_station_craft_admission(second).get("reason") == "ground_ship_geometry_unbound" and controller._field_landing_by_craft == before,"Legacy unbound visitor fails closed without repair")
	mission.free(); view.free(); registry.free()
	print("POLISA_BOUND_GROUND_BODY passed=",passed," failed=",failed)
	quit(0 if failed == 0 else 1)
