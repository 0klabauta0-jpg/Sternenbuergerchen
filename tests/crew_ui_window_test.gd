extends "res://tests/crew_product_test.gd"
## Real native role popup in an offset window; local selection is not gameplay state.
func _run() -> void:
	root.size=Vector2i(1440,900)
	root.position=Vector2i(120,70)
	root.gui_embed_subwindows=false
	game=load("res://scenes/game.tscn").instantiate()
	game.load_on_start=false
	game.save_path="res://output/n4-ui-unused.json"
	root.add_child(game)
	game.simulation.auto_tick=false
	root.grab_focus()
	await create_timer(0.2).timeout
	var ids: Array[String]=["jaro"]
	game.hud.select_units(ids)
	var at:=Vector2(150,120)
	game.boarding_menu.open_for(game.simulation.snapshot(),ids,at)
	await process_frame
	await process_frame
	var expected: Vector2=root.get_screen_transform()*at
	_check(Vector2(game.boarding_menu.position).distance_to(expected)<2,"Native role popup uses actual window and viewport transform")
	_check(game.boarding_menu.visible,"Manual seat menu is visible")
	var menu: PopupMenu=game.boarding_menu
	menu.set_focused_item(menu.get_item_index(0))
	for pressed in [true,false]:
		var event:=InputEventKey.new()
		event.keycode=KEY_ENTER;event.physical_keycode=KEY_ENTER;event.pressed=pressed
		event.window_id=menu.get_window_id()
		Input.parse_input_event(event)
		await process_frame
	_check(game.simulation.snapshot().ship.seats.pilot=="jaro","Real keyboard activation assigns Jaro manually as pilot")
	await _step(20)
	ids=["ida"]
	game.hud.select_units(ids)
	game.hud.dismiss_context()
	game.world.focus_object("shuttle")
	await process_frame
	await physics_frame
	var ship: Node3D=game.world._objects.shuttle
	await _right_click(game.world._camera.unproject_position(ship.global_position+Vector3(0,0.8,0)))
	await _step(20)
	var s: Dictionary=game.simulation.snapshot()
	_check(s.ship.seats.pilot=="jaro" and s.ship.seats.gunner=="ida","Automatic second boarding preserves explicit pilot choice")
	_check(s.crew.ida.assignment=="aboard" and s.crew.jaro.assignment=="aboard" and s.ship.mode=="landed","Both walk aboard and still wait for takeoff")
	await _object("shuttle")
	await _capture("n4-manual-seats")
	var file:=FileAccess.open("res://output/n4-ui-result.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failed":failed,"input":"native offset popup, actual keyboard selection and right-click boarding"},"\t"));file.close()
	print("N4 UI WINDOW: %d checks, %d failures"%[checks,failed])
	quit(0 if failed==0 else 1)
