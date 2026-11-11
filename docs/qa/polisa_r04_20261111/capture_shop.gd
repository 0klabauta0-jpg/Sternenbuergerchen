extends SceneTree
const VIEW=preload("res://scripts/terrain/terrain_map_3d_view.gd")
const MAP=preload("res://scripts/terrain/terrain_map_data.gd")
const SCREEN=preload("res://scripts/ui/polisa_station_screen.gd")
const SUPPLY=preload("res://scripts/core/singleplayer_supply_state.gd")
const COMMANDS=preload("res://scripts/mission/singleplayer_supply_command_contract.gd")
class PreviewAdapter extends Node:
    var owner_state
    var sequence := 0
    func get_polisa_snapshot() -> Dictionary:
        var snap: Dictionary=owner_state.get_supply_snapshot()
        var offers := {}
        for id: String in snap.get("offers",{}):
            if Array(snap.offers[id].get("location_ids",[])).has("polisa"): offers[id]=snap.offers[id]
        return {"craft_id":"polisa_preview","craft_name":"Entermesser","service_ready":true,"fuel_registered":true,
            "fuel":snap.fuel_by_craft_id.get("polisa_preview",0),"fuel_capacity":snap.fuel_capacity,"fuel_price_per_unit":snap.fuel_price_per_unit,
            "credits":snap.credits,"offers":offers,"stock":snap.stock_by_offer_id,"inventory":snap.inventory,
            "people":[],"blueprints":snap.get("blueprints",[]),"require_blueprints":false,"campaign_mode":false,
            "buy_orders":snap.get("commodity_buy_orders",{}).get("polisa",{}),"free_home_pad":"","home_pad_count":2}
    func request_operation(operation: String,payload:Dictionary) -> Dictionary:
        sequence+=1
        return owner_state.execute_command(COMMANDS.build_command(operation,payload,"native-menu-preview-%d"%sequence),{"location_id":"polisa","craft_busy":false,"station_service_verified":true})
func _initialize() -> void: call_deferred("capture")
func capture() -> void:
    root.size=Vector2i(1920,1080)
    await process_frame
    var map=MAP.load_from_file("res://output/native_glut_maps/polisa_r04_20261111/polisa_station_candidate.json")
    var view=VIEW.new();root.add_child(view);await process_frame
    view.set_frontier_art_enabled(true);view.configure_from_map(map);view.set_hex_grid_visible(true)
    view.set("_camera_size",150.0);view.set("_camera_yaw_degrees",0.0);view.set("_camera_pitch_degrees",58.0)
    view.set("_camera_size",172.0)
    view.focus_world_position(Vector2(32*64,-32*32))
    view.call("_request_viewport_redraw",true,60000)
    for i in range(20): await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://docs/qa/polisa_r04_20261111/polisa_station_complete.png")
    root.size=Vector2i(1280,720)
    await process_frame
    view.set("_camera_size",90.0)
    view.focus_world_position(Vector2(60*64,-60*32))
    var provider:=PreviewAdapter.new();provider.owner_state=SUPPLY.new()
    provider.owner_state.configure([{"craft_id":"polisa_preview"}])
    provider.owner_state.configure_inventory([], ["polisa_preview"], false)
    root.add_child(provider)
    var menu=SCREEN.new();root.add_child(menu);menu.configure(provider);menu.refresh(provider.get_polisa_snapshot());menu.call("_select_page","armor")
    view.call("_request_viewport_redraw",true,60000)
    for i in range(25): await process_frame
    await RenderingServer.frame_post_draw
    var path="res://docs/qa/polisa_r04_20261111/polisa_purchase_menu.png"
    var result:=root.get_texture().get_image().save_png(path)
    print("POLISA_SHOP_NATIVE actual_screen=true private_supply=true real_offer_catalog=true capture=",result)
    menu.queue_free();provider.queue_free();view.queue_free();await process_frame
    quit(0 if result==OK else 1)
