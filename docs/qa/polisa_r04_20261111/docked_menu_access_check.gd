extends SceneTree
const ADAPTER = preload("res://scripts/meta/singleplayer_runtime_adapter.gd")
class Campaign extends RefCounted:
    var destination := "polisa"
    func get_campaign_snapshot() -> Dictionary: return {"departures_by_craft_id":{"demo":{"destination_location_id":destination}}}
class Controller extends Node:
    var parked := true
    func _is_parked_campaign_dropship(_id: String) -> bool: return parked
class Flow extends Node:
    var _aircraft_location_by_craft := {"demo":"mission"}
    var pending := {}
    var exists := true
    var mission: Node
    func _find_homebase_aircraft_definition(_id: String) -> Dictionary: return {"craft_id":"demo"} if exists else {}
    func _find_pending_mission_craft_transfer(_id: String) -> Dictionary: return pending
    func get_mission_for_craft(_id: String) -> Node: return mission
    func _find_mission_drop_card_in_planning_state(_id: String) -> Dictionary: return {}
class CameraProbe extends Node:
    var _camera_yaw_degrees := 24.0
    var _camera_pitch_degrees := 45.0
    var _camera_size := 22.0
    var focus := Vector2.ZERO
    func focus_world_position(value: Vector2) -> void: focus=value
var failed := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
    failed += int(not ok)
    print("POLISA_DOCK ",label,": ","PASS" if ok else "FAIL")
func run() -> void:
    var flow := Flow.new(); root.add_child(flow)
    var mission := Node.new(); root.add_child(mission); flow.mission = mission
    var controller := Controller.new(); controller.name="TacticalController"; mission.add_child(controller)
    var campaign := Campaign.new()
    var adapter = ADAPTER.new(); adapter.set("_flow",flow); adapter.set("_campaign",campaign); root.add_child(adapter)
    check(adapter.call("_service_context","demo").get("station_service_verified",false),"real_parked_gate_allows_menu_without_counter_driver")
    controller.parked=false
    check(adapter.call("_service_context","demo").is_empty(),"airborne_cannot_use_menu_service")
    controller.parked=true; flow.pending={"craft_id":"demo"}
    check(adapter.call("_service_context","demo").is_empty(),"pending_transfer_cannot_use_menu_service")
    flow.pending={}; flow.exists=false
    check(adapter.call("_service_context","demo").is_empty(),"unknown_craft_cannot_use_menu_service")
    flow.exists=true; campaign.destination="satellite_crash"
    check(adapter.call("_service_context","demo").is_empty(),"other_visit_keeps_existing_counter_gate")
    var view=load("res://scripts/terrain/terrain_map_3d_view.gd").new(); root.add_child(view); await process_frame
    view.set("_orbital_station_view",true);view.zoom_camera(-1000)
    check(float(view.get("_camera_size")) >= 226.0,"whole_station_map_reachable_with_normal_zoom")
    view.set("_orbital_station_view",false);view.zoom_camera(-1000)
    check(is_equal_approx(float(view.get("_camera_size")),120.0),"other_map_zoom_limit_unchanged")
    var setup=load("res://scripts/tests/mission_test_setup.gd").new()
    setup.set("_loaded_terrain_map_data",load("res://scripts/terrain/terrain_map_data.gd").load_from_file("res://maps/polisa_station.json"))
    var probe:=CameraProbe.new()
    check(setup.call("_frame_reference_mission_camera",probe) and probe.focus.is_equal_approx(Vector2(3840,-1920)) and probe._camera_yaw_degrees==0.0 and probe._camera_pitch_degrees==58.0 and probe._camera_size==66.0,"normal_camera_matches_open_shop_capture")
    probe.focus=Vector2(100,100)
    check(setup.call("_frame_reference_mission_camera",probe) and probe.focus==Vector2(100,100),"initial_camera_does_not_reset_manual_pan")
    setup.free();probe.free();view.queue_free()
    adapter.queue_free(); mission.queue_free(); flow.queue_free(); await process_frame
    print("POLISA_DOCK failures=",failed); quit(0 if failed==0 else 1)
