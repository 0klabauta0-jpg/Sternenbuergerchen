extends SceneTree
class FixtureController extends Node:
	signal polisa_globe_requested(interaction: Dictionary)
class FixtureAdapter extends Node:
	var controller: Node
	var operations: Array = []
	var offers: Array = []
	func get_polisa_globe_controller() -> Node: return controller
	func get_polisa_snapshot() -> Dictionary:
		return {"service_ready":true,"campaign_mode":true,"craft_id":"ship","craft_name":"Ship","credits":900,"local_crafts":[],"stock":{},"offers":{},"inventory":{},"station_residents":[{"unit_id":"polisa_recruit_resident","name":"Resident"}]}
	func get_polisa_recruitment_snapshot() -> Dictionary:
		return {"offers":offers,"recruiter_id":"r1","credits":900,"beds":2,"roster_size":2,"capacity_available":true,"pending":false}
	func request_operation(operation: String, payload: Dictionary = {}) -> Dictionary:
		operations.append({"operation":operation,"payload":payload})
		return {"ok":true}
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var adapter := FixtureAdapter.new()
	root.add_child(adapter)
	var controller := FixtureController.new()
	root.add_child(controller)
	adapter.controller=controller
	adapter.offers=load("res://scripts/meta/polisa_recruit_offers.gd").build_offers("fixture",{"unit_id":"r1","skill_values":{"leadership":1.0},"communication_values":{"speech_quality":1.0}}, {})
	var screen=load("res://scripts/ui/polisa_station_screen.gd").new()
	root.add_child(screen)
	screen.configure(adapter)
	screen.refresh(adapter.get_polisa_snapshot())
	controller.polisa_globe_requested.emit({"ok":true,"unit_id":"r1"})
	if screen._page != "recruitment" or adapter.operations.is_empty() or adapter.operations[0].operation != "station_recruit_open": _fail("globe open"); return
	var views: Array = screen._content.find_children("*", "VBoxContainer", true, false)
	var recruit_view: Node
	for node in views:
		if node.has_signal("hire_requested"): recruit_view=node; break
	if recruit_view == null: _fail("candidate view missing"); return
	recruit_view.emit_signal("hire_requested",String(adapter.offers[0].id))
	if adapter.operations.back().operation != "station_recruit_hire" or adapter.operations.back().payload.recruiter_id != "r1": _fail("hire command"); return
	screen._select_page("ships")
	var claim: Node=screen.find_child("ClaimResident_polisa_recruit_resident",true,false)
	if claim == null: _fail("resident claim button missing"); return
	claim.emit_signal("pressed")
	if adapter.operations.back().operation != "station_claim_resident" or adapter.operations.back().payload.unit_id != "polisa_recruit_resident": _fail("resident claim intent"); return
	screen.free();controller.free();adapter.free()
	print("PASS: globe opens candidate cards and sends hire intent")
	quit(0)
func _fail(message:String)->void: printerr("FAIL: "+message); quit(1)
