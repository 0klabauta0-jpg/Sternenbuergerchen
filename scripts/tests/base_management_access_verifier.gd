extends SceneTree
var checks:=0
var failures:=0
func _init()->void:call_deferred("_run")
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: ",label)
	else:print("PASS: ",label)
func _run()->void:
	load("res://scripts/meta/game_start_contract.gd").request_start(self,"campaign","new")
	var flow:Node=load("res://scenes/meta/meta_layer_test.tscn").instantiate();root.add_child(flow);await process_frame
	var screen:Node=flow.get_node("HomebaseScreen")
	screen.request_operation("navigate",{"mode":"base"})
	var presenter:Node=screen.get("_operations_presenter")
	var bar:Control=presenter.get("_base_management_bar")
	check(bar.is_visible_in_tree(),"base management actions visible while exploring")
	var actions:Dictionary={}
	for button:Button in bar.get_children():actions[button.text]=button
	check(actions.has("Bauen") and actions.has("Werkstatt / Blueprints") and actions.has("Datenterminal / Hochladen"),"base exposes build workshop and upload directly")
	var before:Dictionary=flow.get("_singleplayer_runtime").get("_supply").export_state()
	actions["Datenterminal / Hochladen"].pressed.emit()
	var services:Node=presenter.get("_services_view")
	check(services.is_visible_in_tree() and services.get("_section")=="data","actual data-terminal button opens canonical upload view")
	check(services.get("_campaign_buttons").campaign_upload.button.is_visible_in_tree(),"upload location stays discoverable without a chip")
	check(services.get("_campaign_buttons").campaign_upload.button.disabled,"empty data terminal cannot fake upload")
	check(services.get("_section_note").text.contains("Keine geborgenen"),"empty terminal explains missing data without requiring tooltip")
	flow.call("_refresh_singleplayer_services")
	check(not flow.get("_singleplayer_services").visible,"full management page does not also show duplicate floating supply panel")
	flow.get("_campaign_tutorial").refresh()
	check(not flow.get("_campaign_tutorial").visible,"upload page keeps global tutorial clear of actual upload action")
	if DisplayServer.get_name()!="headless":
		for i in 12:await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("C:/dev/SternenBuergerchen/output/flugdeck_20261110/datenterminal.png")
	presenter.call("_open_base_management","workshop")
	for action:Dictionary in services.get("_campaign_buttons").values():
		if String(action.operation)=="campaign_fabricate":check(action.button.visible and action.button.disabled,"locked blueprint visible and disabled")
	var rejected:Dictionary=screen.request_operation("campaign_fabricate",{"blueprint_id":"assault_rifle"})
	check(not rejected.get("ok",false) and String(rejected.get("reason",""))=="blueprint_locked","canonical request reaches owner blueprint gate")
	presenter.call("_open_base_management","build")
	check(services.get("_campaign_buttons").campaign_build_pad.button.visible and services.get("_campaign_buttons").campaign_build_pad.button.disabled,"unearned second pad remains explained and locked")
	presenter.call("_open_base_management","inventory")
	check(String(presenter.get("_mode"))=="squad" and presenter.get("_inventory_panel").is_visible_in_tree(),"warehouse route opens actual finite inventory and equipment")
	check(flow.get("_singleplayer_runtime").get("_supply").export_state()==before,"navigation and locked actions create no items or money")
	flow.queue_free();await process_frame
	print("BASE_MANAGEMENT checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)
