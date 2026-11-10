extends SceneTree
const SCREEN = preload("res://scenes/meta/homebase_test_screen.tscn")
const PRESETS = preload("res://scripts/npc/unit_roster_presets.gd")
const FORMATTER = preload("res://scripts/meta/character_sheet_formatter.gd")
var passed := 0
var failed := 0
func _init() -> void:
	call_deferred("_run")
func _check(ok: bool, message: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("PASS: " if ok else "FAIL: ", message)
func _run() -> void:
	root.size = Vector2i(1280,720)
	var screen: Control = SCREEN.instantiate()
	root.add_child(screen)
	await process_frame
	screen.call("setup_roster",PRESETS.get_homebase_roster(),PackedStringArray(["unit_alpha","unit_bravo"]))
	screen.call("request_operation","details",{"unit_id":"unit_alpha"})
	var panel: Node = screen.find_child("CharacterInventoryPanel",true,false)
	_check(panel != null,"Character details include actual right inventory component")
	var body: Control = screen.find_child("CharacterDetailsColumns",true,false)
	_check(body is HBoxContainer,"Character and inventory use side-by-side columns")
	var profiles: Dictionary = screen.get("_profiles_by_id")
	var model: Dictionary = FORMATTER.build_sheet_view_model(profiles.unit_alpha)
	var pilot: Dictionary = {}
	for row: Dictionary in model.suitability_rows:
		if row.badge_key == "pilot": pilot = row
	_check(String(pilot.get("detail_text","")).contains("\nWahrnehmung"),"Pilot ingredients have independent vertical lines")
	_check(not String(pilot.get("detail_text","")).contains("; Disziplin"),"No horizontally concatenated pilot factors")
	screen.call("set_fireteam_context",PackedStringArray(["ft1","ft1"]),[{"id":"ft1","label":"ALPHA","lead_unit_id":"unit_alpha","loadout":"medium"}])
	screen.call("request_operation","navigate",{"mode":"personnel"})
	screen.call("_on_close_sheet_button_pressed")
	var operations: Control = screen.get_node("OperationsRoot")
	operations.call("refresh")
	for frame in range(4): await process_frame
	var rows: Dictionary = operations.get("_rows")
	var row: Dictionary = rows.unit_alpha
	for key in ["portrait","focus","status"]:
		var control: Control = row[key]
		await _doubleclick(control.get_global_rect().get_center())
		_check(bool(screen.get("_character_sheet_open")) and String(screen.get("_focused_unit_id"))=="unit_alpha","Native doubleclick opens correct roster person via " + key)
		screen.call("_on_close_sheet_button_pressed")
		await process_frame
	screen.call("request_operation","navigate",{"mode":"squad"})
	operations.call("refresh")
	for frame in range(4): await process_frame
	var slots: Array = operations.get("_slots")
	for key in ["portrait","focus","status"]:
		var slot: Dictionary = slots[0]
		var control: Control = slot[key]
		await _doubleclick(control.get_global_rect().get_center())
		_check(bool(screen.get("_character_sheet_open")) and String(screen.get("_focused_unit_id"))==String(slot.unit_id),"Native doubleclick opens correct team person via " + key)
		screen.call("_on_close_sheet_button_pressed")
		await process_frame
	var preview := {"crafts":[{"craft_id":"preview","visible_on_pad":true,"location_id":"homebase","busy":true}],"space_travel":{"craft_id":"preview","phase":"boarding"}}
	operations.set("_craft_id","preview")
	_check(String(operations.call("_project_ship_context",preview).get("kind",""))=="base_pad","Busy boarding ship retains physical pad preview")
	var inventory: Node = load("res://scripts/ui/components/personnel_inventory_panel.gd").new()
	root.add_child(inventory)
	var data := {"base:homebase":{"capacity":200,"items":{"smg":2}},"unit:a:backpack":{"capacity":12,"items":{"ore":1}},"unit:b:backpack":{"capacity":12,"items":{}}}
	inventory.call("update_snapshot",data,{"id":"a","loadout":{}},"ship",["base:homebase","unit:a:backpack"])
	inventory.set("_selection",{"source_container_id":"unit:a:backpack","item_id":"ore"})
	inventory.call("update_snapshot",data,{"id":"b","loadout":{}},"ship",["base:homebase","unit:b:backpack"])
	_check(Dictionary(inventory.get("_selection")).is_empty(),"Changing person clears old backpack selection")
	_check(String(inventory.get("_unit_id"))=="b","Inventory commands target current person")
	inventory.set("_selection",{"source_container_id":"base:homebase","item_id":"smg"})
	inventory.call("update_snapshot",data,{"id":"b","loadout":{}},"ship",[],false)
	_check(Dictionary(inventory.get("_selection")).is_empty(),"Losing access clears unavailable item selection")
	_check(bool(inventory.get("_equip").disabled) and bool(inventory.get("_transfer").disabled),"Unavailable person has no enabled inventory mutation")
	inventory.free()
	screen.free()
	await process_frame
	await _campaign_inventory()
	print("PLAYTEST_DETAILS_INVENTORY passed=%d failed=%d" %[passed,failed])
	quit(1 if failed else 0)

func _doubleclick(position: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	root.push_input(motion,true)
	var click := InputEventMouseButton.new()
	click.position = position
	click.global_position = position
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.double_click = true
	root.push_input(click,true)
	click = click.duplicate()
	click.pressed = false
	click.double_click = false
	root.push_input(click,true)
	await process_frame

func _campaign_inventory() -> void:
	load("res://scripts/meta/game_start_contract.gd").request_start(self,"campaign","new")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	await process_frame
	var screen: Node = flow.get_node("HomebaseScreen")
	var adapter: Node = flow.get("_singleplayer_runtime")
	var runtime: Node = adapter.call("get_base_personnel_runtime")
	runtime.call("get_simulation_root").set_physics_process(false)
	screen.call("request_operation","details",{"unit_id":"campaign_pilot"})
	var panel: Node = screen.find_child("CharacterInventoryPanel",true,false)
	_check(panel != null and bool(panel.visible) and panel.get("_unit_id")=="campaign_pilot","Campaign details show actual selected pilot inventory")
	for frame in range(3): await process_frame
	var columns: Control = screen.find_child("CharacterDetailsColumns",true,false)
	var left: Control = columns.get_child(0)
	var right: Control = columns.get_child(1)
	var popup: Control = screen.get_node("CharacterSheetPopup")
	_check(left.get_global_rect().end.x <= right.global_position.x and popup.get_global_rect().encloses(right.get_global_rect()),"Actual 1280px popup keeps inventory right of character and within its bounds")
	_check(bool(screen.find_child("CharacterSheetDetails_values",true,false).visible),"Full character values begin expanded in details popup")
	var actual: Dictionary = adapter.call("get_snapshot")
	var view: Dictionary = screen.call("get_personnel_inventory_view","campaign_pilot")
	_check(view.inventory==actual.supply.inventory,"Details inventory equals authoritative finite supply snapshot")
	_check(view.unit.loadout==screen.call("_get_member_loadout","campaign_pilot"),"Details loadout equals authoritative personnel owner")
	var base: Control = Dictionary(panel.get("_bodies"))["base:homebase"]
	var medic: Button
	for child in base.find_children("*","Button",true,false):
		if String(child.text).begins_with("Sanitätsgerät"): medic=child
	_check(medic != null and not medic.disabled,"Real finite medictool is selectable in right inventory")
	if medic != null:
		medic.pressed.emit()
		panel.get("_slot_target").select(1)
		panel.get("_equip").pressed.emit()
		_check(String(screen.call("_get_member_loadout","campaign_pilot").weapon_1)=="medictool","Right inventory Anlegen button commits selected person's actual loadout")
		_check(int(Dictionary(adapter.call("get_snapshot").supply.inventory["base:homebase"].items).get("medictool",0))==0,"Equipped medictool leaves finite base supply")
	var target: Vector2 = runtime.call("get_actor","campaign_leader").position
	var move: Dictionary = screen.call("request_operation","base_move",{"unit_id":"campaign_pilot","target_position":target})
	_check(bool(move.get("ok",false)),"Actual moving pilot starts through authorized base command")
	screen.call("_update_character_inventory")
	_check(bool(panel.get("_equip").disabled) and bool(panel.get("_transfer").disabled),"Actual moving pilot disables popup stock mutation through same context")
	var denied: Dictionary = screen.call("request_operation","inventory_equip",{"unit_id":"campaign_pilot","source_container_id":"base:homebase","item_id":"smg","slot":"weapon_1"})
	screen.call("_on_character_inventory_operation","inventory_equip",{"unit_id":"campaign_pilot","source_container_id":"base:homebase","item_id":"smg","slot":"weapon_1"})
	var feedback: Label = screen.find_child("CharacterInventoryFeedback",true,false)
	_check(not bool(denied.get("ok",true)) and feedback.text==String(denied.get("message",denied.get("reason",""))),"Popup reports same authoritative rejection reason for unavailable person")
	screen.call("request_operation","details",{"unit_id":"campaign_leader"})
	_check(panel.get("_unit_id")=="campaign_leader","Open details switch inventory to newly selected actual person")
	var identities: Array = panel.get("_slots").get_children().map(func(child:Node):return child.get_instance_id())
	screen.call("_update_character_inventory")
	_check(identities==panel.get("_slots").get_children().map(func(child:Node):return child.get_instance_id()),"Unchanged detail inventory preserves existing controls")
	flow.queue_free()
	await process_frame
