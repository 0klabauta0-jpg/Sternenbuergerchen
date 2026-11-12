extends SceneTree
class Adapter extends Node:
	var sent:Dictionary={}
	var snapshot:Dictionary={}
	func request_operation(op:String,payload:Dictionary)->Dictionary:
		sent={"operation":op,"payload":payload.duplicate(true)}
		return {"ok":true}
	func get_polisa_snapshot()->Dictionary:return snapshot
	func get_polisa_globe_controller():return null
func _init():call_deferred("run")
func run():
	var adapter=Adapter.new();root.add_child(adapter)
	adapter.snapshot={"craft_id":"a","craft_name":"Schiff A","service_ready":true,"local_crafts":[{"craft_id":"a","name":"Schiff A"},{"craft_id":"b","name":"Schiff B"}],"inventory":{"station:polisa:lift":{"capacity":256,"items":{"pistol":2}},"craft:a":{"capacity":48,"items":{}},"craft:b":{"capacity":48,"items":{}}},"cargo_transfer":{"phase":"idle"}}
	var screen=load("res://scripts/ui/polisa_station_screen.gd").new();root.add_child(screen);screen.configure(adapter);screen.refresh(adapter.snapshot);screen._select_page("cargo_transfer")
	var selectors:Array=screen.get("_content").find_children("*","OptionButton",true,false)
	var action:Button
	for button:Button in screen.get("_content").find_children("*","Button",true,false):
		if button.text=="Alles automatisch transportieren":action=button
	var ok=selectors.size()==2 and action!=null
	if ok:
		selectors[0].select(2);selectors[0].emit_signal("item_selected",2)
		selectors[1].select(1);selectors[1].emit_signal("item_selected",1)
		action.emit_signal("pressed")
		ok=adapter.sent.get("operation","")=="cargo_transfer_all" and adapter.sent.payload.get("source_container_id","")=="craft:b" and adapter.sent.payload.get("destination_container_id","")=="craft:a"
	print(("PASS" if ok else "FAIL")+": cargo UI sends selected ship-to-ship command")
	screen.free();adapter.free()
	if ok:print("AUTOMATIC_CARGO_UI_PASS")
	quit(0 if ok else 1)
