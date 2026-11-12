extends SceneTree
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const CONTROLLER = preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")
const PROFILE = preload("res://scripts/mission/polisa_ground_body_profile.gd")
const CATALOG = preload("res://scripts/terrain/frontier_ship_visuals.gd")
class MethodView extends VIEW:
	var test_asset_offset := 0.0
	func _ready() -> void: pass
	func _get_frontier_dropship_visual_entry(payload: Dictionary = {}) -> Dictionary:
		var result: Dictionary = super._get_frontier_dropship_visual_entry(payload)
		if not result.is_empty() and test_asset_offset != 0.0: result.root_rotation_y_degrees = test_asset_offset
		return result
class MethodController extends CONTROLLER:
	func _ready() -> void: pass
var checks := 0
var failures := 0
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ",label)
func _init() -> void: call_deferred("run")
func run() -> void:
	var view := MethodView.new()
	var craft := {"craft_id":"cutlass_local","model_id":"cutlass","craft_type":"dropship"}
	var payload := {"craft_id":"cutlass_local","model_id":"cutlass","craft_type":"dropship","state":"complete","flight_heading_origin":Vector2(-128,-64),"dropship_target_position":Vector2(64,32),"lz_position":Vector2(64,32)}
	var location := Vector2(64,32)
	view._camera_yaw_degrees = 25
	var actual := view._get_dropship_rotation_y_for_payload(payload,location)
	var projection := view.get_landed_craft_body_projection(craft,payload,location)
	var asset := CATALOG.get_ui_identity(craft)
	check(projection.get("ok",false) and projection.yaw_degrees == actual and projection.model_scale == asset.scale and projection.bounds.size == Vector3(asset.bounds_size[0],asset.bounds_size[1],asset.bounds_size[2]) and projection.cell_size == view._get_3d_cell_size(),"unbound landed getter reads real shipped asset bounds/scale and actual heading")
	if not projection.get("ok",false): view.free(); finish(); return
	var normalized: Dictionary = PROFILE.from_projection(craft,projection)
	payload.ground_body_profile = normalized.profile.duplicate(true)
	check(view._get_dropship_rotation_y_for_payload(payload,location) == actual and view.get_landed_craft_body_projection(craft,payload,location).yaw_degrees == actual,"binding the observed heading produces no turn")
	payload.ground_body_profile.yaw_degrees = 73.0
	view.test_asset_offset = 37.0
	var stable := true
	for state in ["landed","unloading","complete"]:
		payload.state = state
		for camera in [0.0,93.0,280.0]:
			view._camera_yaw_degrees = camera
			stable = stable and view._get_dropship_rotation_y_for_payload(payload,location) == 73.0
	check(stable,"all parked states use total bound yaw despite camera and simulated nonzero asset offset")
	var fallback := view._get_dropship_model_yaw(payload.flight_heading_origin,payload.dropship_target_position,-view._camera_yaw_degrees,payload)
	var unchanged := true
	for state in ["inbound","outbound"]:
		payload.state = state
		unchanged = unchanged and view._get_dropship_rotation_y_for_payload(payload,location) == fallback
	payload.state = "complete"
	payload.ground_body_profile.craft_id = "foreign"
	unchanged = unchanged and view._get_dropship_rotation_y_for_payload(payload,location) == fallback
	payload.ground_body_profile = normalized.profile.duplicate(true)
	payload.ground_body_profile.yaw_degrees = NAN
	unchanged = unchanged and view._get_dropship_rotation_y_for_payload(payload,location) == fallback
	payload.erase("ground_body_profile")
	check(unchanged and view._get_dropship_rotation_y_for_payload(payload,location) == fallback,"flight, foreign, invalid and legacy payloads retain existing heading calculation")
	var bad := payload.duplicate(true)
	bad.craft_id = "other"
	var wrong: bool = not view.get_landed_craft_body_projection(craft,bad,location).get("ok",false)
	bad = payload.duplicate(true); bad.state = "inbound"
	wrong = wrong and not view.get_landed_craft_body_projection(craft,bad,location).get("ok",false)
	bad = payload.duplicate(true); bad.flight_heading_origin = bad.dropship_target_position
	wrong = wrong and not view.get_landed_craft_body_projection(craft,bad,location).get("ok",false)
	check(wrong and not view.get_landed_craft_body_projection(craft,payload,Vector2(NAN,0)).get("ok",false),"getter fails closed for identity, airborne, nonfinite or camera-only heading")
	var host := Node.new()
	root.add_child(host)
	var controller := MethodController.new()
	host.add_child(controller)
	var card := craft.duplicate(true)
	card.merge({"state":"complete","has_lz_position":true,"lz_position":location,"dropship_position":location})
	controller._field_landing_by_craft[craft.craft_id] = {"ground_body_profile":normalized.profile.duplicate(true)}
	var owner_before: Dictionary = controller._field_landing_by_craft.duplicate(true)
	var visual: Dictionary = controller._build_mission_dropship_visual_entry(card,0,false,location,false,false)
	var forwarded: bool = visual.has("ground_body_profile") and visual.ground_body_profile == normalized.profile
	if visual.has("ground_body_profile"): visual.ground_body_profile.yaw_degrees = -99
	check(forwarded and controller._field_landing_by_craft == owner_before,"real Controller forwards parked owner profile as detached payload")
	card.state = "inbound"
	var airborne: Dictionary = controller._build_mission_dropship_visual_entry(card,0,false,location,false,false)
	card.state = "complete"
	controller._field_landing_by_craft[craft.craft_id].ground_body_profile.craft_id = "foreign"
	var foreign: Dictionary = controller._build_mission_dropship_visual_entry(card,0,false,location,false,false)
	check(not airborne.has("ground_body_profile") and not foreign.has("ground_body_profile"),"Controller omits bound ground data for flight or wrong owner identity")
	host.free()
	view.free()
	finish()
func finish() -> void:
	print("LANDED_CRAFT_RENDER_YAW_RESULT checks=%d failures=%d producer_wired=false native_visual_approved=false"%[checks,failures])
	quit(1 if failures else 0)


