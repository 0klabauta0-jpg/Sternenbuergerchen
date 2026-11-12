extends SceneTree
class CampaignStub extends Node:
	var saves := 0
	func is_campaign_start() -> bool: return true
	func request_campaign_save() -> Dictionary:
		saves += 1
		return {"ok":true,"message":"Kampagne gespeichert."}

func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	if OS.get_environment("POLISA_TEST_PROFILE").is_empty(): printerr("isolated profile required"); quit(1); return
	var menu: Node = root.get_node("GlobalEscapeMenu")
	menu.set_save_path_for_tests("user://campaign_menu_routing_fixture.cfg")
	var old := ConfigFile.new()
	old.set_value("mission_shell_slot","scene_path","res://scenes/meta/meta_layer_test.tscn")
	if old.save("user://campaign_menu_routing_fixture.cfg")!=OK: quit(1); return
	var flow := CampaignStub.new()
	root.add_child(flow)
	current_scene = flow
	var saved: Dictionary = menu.save_current_mission_slot()
	if not saved.get("ok",false) or flow.saves!=1: printerr("campaign owner did not receive save"); quit(1); return
	var loaded: Dictionary = menu.load_mission_slot(false)
	if loaded.get("ok",false) or loaded.get("reason")!="campaign_continue_from_main_menu": printerr("foreign shell slot was not blocked"); quit(1); return
	menu.open_menu()
	var button: Button = menu.get("_load_button")
	if not button.disabled or button.text!="Im Hauptmenü fortsetzen" or button.tooltip_text.is_empty(): printerr("campaign continue guidance unavailable"); quit(1); return
	menu.close_menu()
	flow.queue_free(); await process_frame
	print("CAMPAIGN_SAVE_MENU_ROUTING_PASS")
	quit(0)
