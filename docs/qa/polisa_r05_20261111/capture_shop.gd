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
        return owner_state.apply_command(COMMANDS.build_command(operation,payload,"native-menu-preview-%d"%sequence),{"location_id":"polisa","craft_id":"polisa_preview","craft_busy":false,"station_service_verified":true})
func _initialize() -> void: call_deferred("capture")
func capture() -> void:
    root.size=Vector2i(1280,720)
    await process_frame
    var provider:=PreviewAdapter.new();provider.owner_state=SUPPLY.new()
    provider.owner_state.configure([{"craft_id":"polisa_preview"}])
    provider.owner_state.configure_inventory([], ["polisa_preview"], false)
    root.add_child(provider)
    var menu=SCREEN.new();root.add_child(menu);menu.configure(provider);menu.refresh(provider.get_polisa_snapshot());menu.call("_select_page","armor")
    for i in range(25): await process_frame
    await RenderingServer.frame_post_draw
    var path="res://docs/qa/polisa_r05_20261111/polisa_purchase_menu.png"
    var result:=root.get_texture().get_image().save_png(path)
    print("POLISA_SHOP_NATIVE actual_screen=true private_supply=true real_offer_catalog=true capture=",result)
    var product: Node = menu.get_node("Shop").find_child("Product_polisa_armor_light",true,false)
    if product == null:
        # Offer identifiers belong to Supply; locate the card by its real offer data.
        for offer_id: String in provider.get_polisa_snapshot().offers:
            if provider.get_polisa_snapshot().offers[offer_id].item_id == "armor_light":
                product = menu.get_node("Shop").find_child("Product_" + offer_id,true,false)
                break
    var buy_button: Button
    if product != null:
        for node: Node in product.find_children("*","Button",true,false):
            if node.text == "Kaufen": buy_button = node; break
    if buy_button == null or buy_button.disabled:
        push_error("POLISA native card buy button unavailable")
        quit(1); return
    buy_button.pressed.emit()
    var after: Dictionary = provider.get_polisa_snapshot()
    var passed: bool = after.credits == 445 and after.inventory.get("craft:polisa_preview",{}).get("items",{}).get("armor_light",0) == 1
    for i in range(10): await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://docs/qa/polisa_r05_20261111/polisa_menu_after_purchase.png")
    print("POLISA_CARD_PURCHASE actual_button=true credits445_and_ship_cargo1=",passed)
    result = result if passed else ERR_INVALID_DATA
    menu.queue_free();provider.queue_free();await process_frame
    quit(0 if result==OK else 1)
