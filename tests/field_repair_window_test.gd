extends "res://tests/crew_product_test.gd"
## Finite damaged-hull/equipment fixture; native workshop and ship buttons perform all work.
const Journey=preload("res://tests/n4_test_journey.gd")
func _run() -> void:
	root.size=Vector2i(1440,900)
	game=load("res://scenes/game.tscn").instantiate();game.load_on_start=false;game.save_path="res://output/n5-repair-window-save.json"
	root.add_child(game);game.simulation.auto_tick=false
	await create_timer(0.4).timeout
	await _object("workbench");await _action("repair_attachment");await _step(12)
	_check(game.simulation.snapshot().inventory.repair_attachment==1,"native recipe crafts repair attachment from actual start materials")
	# Two finite supporting items and a damaged hull isolate the new interaction.
	game.simulation._state.inventory.backpack=1;game.simulation._state.inventory.multitool=1;game.simulation._state.ship.condition=40.0
	Journey.command(game.simulation,"move",{"unit_id":"ida","position":Catalog.interaction_point("base","storage")});await _step(20)
	for item: String in ["backpack","multitool","repair_attachment"]:
		_check(Journey.command(game.simulation,"equip_item",{"unit_id":"ida","slot":Catalog.Gear.slot_for(item),"item":item,"source":"inventory"}).ok,"real equip "+item)
	_check(Journey.command(game.simulation,"backpack_transfer",{"unit_id":"ida","item":"parts","amount":1,"source":"inventory","destination":"backpack"}).ok,"load real repair material")
	Journey.command(game.simulation,"move",{"unit_id":"ida","position":Catalog.ship_access(game.simulation.snapshot().ship)});await _step(20)
	game.world.set("_focus",Vector3(25,0,24));game.world.set("_zoom",40);await create_timer(0.2).timeout
	await _object("shuttle");await _action("field_repair")
	_check(game.simulation.snapshot().ship.condition==53,"native ship action repairs thirteen points")
	_check(game.simulation.snapshot().crew.ida.backpack.items.parts==0,"native action consumed one real part")
	await _capture("n5-field-repair")
	_check(game.simulation.save_game(game.save_path).ok,"repaired state persists")
	var file:=FileAccess.open("res://output/n5-repair-window-result.json",FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failed":failed},"  "));file.close()
	print("N5_REPAIR_WINDOW ",checks," checks, ",failed," failures");quit(1 if failed else 0)
