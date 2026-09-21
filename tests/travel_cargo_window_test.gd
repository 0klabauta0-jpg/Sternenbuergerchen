extends "res://tests/crew_product_test.gd"
func _run() -> void:
	_start_ms=Time.get_ticks_msec()
	root.size=Vector2i(1440,900)
	root.gui_embed_subwindows=false
	game=load("res://scenes/game.tscn").instantiate()
	game.save_path="res://output/n6-product-save.json"
	game.load_on_start=false
	game.simulation_seed=3
	root.add_child(game)
	game.simulation.auto_tick=false
	root.grab_focus()
	await create_timer(0.2).timeout
	await process_frame
	await physics_frame
	await process_frame
	_check(game.simulation.snapshot().schema_version==5,"Fresh product uses schema 5")
	await _capture("n6-base")
	_check(game.hud._menu.get_item_index(7)==-1 and game.hud._menu.get_item_index(9)>=0,"System menu separates crew gameplay from session functions")
	await _object("workbench")
	await _action("backpack")
	_check(game.simulation.snapshot().work.active,"Scrollable workshop starts backpack recipe")
	if not game.simulation.snapshot().work.active:
		printerr("WORK CLICK: ",game.hud._action_buttons.backpack.get_global_rect()," toast=",game.hud._toast.text)
		quit(1)
		return
	await _step(1)
	await _click(game.hud._pause.get_global_rect().get_center())
	var held: Dictionary=game.simulation.snapshot()
	await _step(2)
	_check(game.simulation.snapshot().time==held.time,"GUI pause holds the authoritative simulation")
	await _capture("n6-workshop")
	await _click(game.hud._pause.get_global_rect().get_center())
	await _step(20)
	_check(game.simulation.snapshot().inventory.backpack==1,"Real materials become a finished backpack")
	await _window_click(root,game.hud._crew_buttons.ida.get_global_rect().get_center(),true)
	_check(game.hud._dossier.visible,"Actual double-click on crew portrait opens dossier")
	game.hud._dossier.close()
	await process_frame
	await _object("contracts")
	await _action("accept_contract")
	_check(game.simulation.snapshot().contract.status=="active","World console accepts the first mission")
	await _object("shuttle")
	_check(game.hud._action_buttons.launch.disabled,"Abheben is disabled before crew actually boards")
	await _board()
	var boarded: Dictionary=game.simulation.snapshot()
	_check(boarded.ship.seats.pilot=="ida" and boarded.ship.seats.gunner=="jaro","Right-click allocates pilot and gunner by actual skills")
	_check(boarded.ship.mode=="landed","Boarding does not automatically take off")
	await _capture("n6-boarding")
	await _trip("rust")
	_check(game.simulation.snapshot().ship.mode=="flying","Destination arrival stays airborne")
	_check(game.simulation.snapshot().crew.ida.assignment=="aboard","Arrival keeps crew inside")
	await _capture("n6-rust-arrival")
	await _exp_action("radar_scan")
	_check(game.simulation.snapshot().discovery.signals.size()==3,"Radar reveals three anonymous signals on enlarged map")
	await _exp_action("signal_01")
	await _step(35)
	_check(game.simulation.snapshot().discovery.satellite_found,"Flying to the contact identifies the satellite")
	await _fly_to(Vector2(145,-103))
	await _land_and_exit()
	await _object("satellite")
	await _action("salvage")
	await _step(28)
	_check(game.simulation.snapshot().contract.status=="recovered","First blackbox mission still works without bought tools")
	await _capture("n6-satellite")
	await _board()
	await _trip("base")
	await _fly_to(Vector2(25,22))
	await _land_and_exit()
	await _object("storage")
	var cargo_ui: Node=game.hud._cargo_panel
	game.hud._action_scroll.ensure_control_visible(cargo_ui._rows["cargo:blackbox"])
	await process_frame
	await drag(root,cargo_ui._rows["cargo:blackbox"].get_global_rect().get_center(),cargo_ui._headers.inventory.get_global_rect().get_center())
	await _capture("n6-cargo-unloaded")
	_check(game.simulation.snapshot().inventory.blackbox==1,"Dock unload transfers actual blackbox into base inventory")
	var credits_before: int=game.simulation.snapshot().credits
	await process_frame
	await _click(cargo_ui._claim.get_global_rect().get_center())
	_check(game.simulation.snapshot().credits==credits_before+260,"Lager claim actually pays 260 credits")
	_check(game.hud._context_panel.position.x<100 and game.hud._crew_buttons.ida.global_position.x>900,"Context by left toolbar, crew on right")
	await _object("office")
	await _named("Ida · Akte & Ausrüstung")
	_check(game.hud._dossier.visible,"World office opens actual crew dossier")
	await create_timer(0.15).timeout
	await RenderingServer.frame_post_draw
	game.hud._dossier.get_texture().get_image().save_png("res://output/n6-dossier.png")
	game.hud._dossier.close()
	_check(game.simulation.snapshot().contract.status=="claimed","First mission can still be paid after explicit return route")
	await _board()
	await _trip("station")
	await _fly_to(Vector2(0,28))
	await _land_and_exit()
	await _object("market")
	await _action("buy_multitool")
	await _action("buy_salvage_attachment")
	_check(game.simulation.snapshot().cargo.multitool==1 and game.simulation.snapshot().cargo.salvage_attachment==1,"Scrolled market buys the new actual equipment")
	await _capture("n6-market")
	await _key(KEY_F5)
	var saved: Dictionary=game.simulation.snapshot()
	await _step(1)
	await _key(KEY_F9)
	_check(game.simulation.snapshot().cargo==saved.cargo and game.simulation.snapshot().ship.seats==saved.ship.seats,"F5/F9 restores new cargo and seat state")
	await _board();await _object("shuttle");await _action("launch")
	game.hud.dismiss_context();await _exp_action("enter_orbit");await _step(6)
	await _object("shuttle");await _named("Patrouille setzen")
	_check(game._pending_flight_order=="patrol","Ship panel arms patrol point selection")
	game.world._flight_camera_follow=false;game.world._focus=Vector3(100,0,0);game.world._update_camera()
	await process_frame;await physics_frame
	await _right_click(game.world._camera.unproject_position(Vector3(100,0,0)))
	_check(game.simulation.snapshot().ship.order.get("kind","")=="patrol","Actual right-click confirms patrol in simulation")
	await _step(2)
	_check(game.simulation.snapshot().ship.position[0]>10,"Patrol actually moves")
	await _object("shuttle");await _action("ship_stop")
	_check(game.simulation.snapshot().ship.order.is_empty(),"Actual halt button clears patrol")
	await _capture("n6-flight-orders")
	var report: Dictionary={"checks":checks,"failed":failed,"engine":Engine.get_version_info().string,"wall_ms":Time.get_ticks_msec()-_start_ms,"input":"real GUI + ray targets + native Window events","time":"ordinary advance calls, accelerated; no state injection","evidence":evidence}
	var file:=FileAccess.open("res://output/n6-product-result.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"));file.close()
	print("N6 PRODUCT WINDOW: %d checks, %d failures"%[checks,failed])
	quit(0 if failed==0 else 1)

func drag(window: Window, start: Vector2, finish: Vector2) -> void:
	window.warp_mouse(start)
	await create_timer(0.08).timeout
	var motion := InputEventMouseMotion.new()
	motion.position = start
	motion.window_id = window.get_window_id()
	motion.global_position = motion.position
	Input.parse_input_event(motion)
	var press := InputEventMouseButton.new()
	press.position = start
	press.button_index = MOUSE_BUTTON_LEFT
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	press.pressed = true
	press.window_id = window.get_window_id()
	press.global_position = press.position
	Input.parse_input_event(press)
	await process_frame
	motion = InputEventMouseMotion.new()
	motion.position = start + Vector2(15, 0)
	motion.relative = Vector2(15, 0)
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	motion.window_id = window.get_window_id()
	motion.global_position = motion.position
	Input.parse_input_event(motion)
	await process_frame
	motion = InputEventMouseMotion.new()
	window.warp_mouse(finish)
	await create_timer(0.08).timeout
	motion.position = finish
	motion.relative = finish - start
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	motion.window_id = window.get_window_id()
	motion.global_position = motion.position
	Input.parse_input_event(motion)
	await process_frame
	var release := InputEventMouseButton.new()
	release.position = finish
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.window_id = window.get_window_id()
	release.global_position = release.position
	Input.parse_input_event(release)
	await process_frame

func _trip(destination: String) -> void:
	await _object("shuttle")
	await _action("launch")
	_check(game.simulation.snapshot().ship.mode=="flying","Explicit takeoff")
	game.hud.dismiss_context()
	await _exp_action("enter_orbit");await _step(2.5)
	_check(game.hud._travel_panel.visible,"Actual ascent shows animated travel")
	_check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(game.hud._travel_panel.get_global_rect()),"Whole animation is visible inside window")
	_check(not game.hud._travel_panel.get_global_rect().intersects(game.hud._pause.get_global_rect()),"Pause stays accessible during travel")
	await _capture("n6-ascent")
	await _click(game.hud._pause.get_global_rect().get_center())
	var remaining: float=game.simulation.snapshot().travel.remaining
	await _step(1)
	_check(game.simulation.snapshot().travel.remaining==remaining and game.hud._travel_panel.paused,"Pause freezes real transition and animation")
	await _click(game.hud._pause.get_global_rect().get_center())
	await _step(3)
	await _exp_action("travel_chart")
	await create_timer(0.15).timeout
	await _window_activate(game.travel_chart,game.travel_chart._buttons[destination])
	await RenderingServer.frame_post_draw
	game.travel_chart.get_texture().get_image().save_png("res://output/n6-system-chart.png")
	await _window_activate(game.travel_chart,game.travel_chart._route)
	await _step(2.5);await _capture("n6-planet-approach")
	_check(game.hud._travel_panel.visible,"Actual planetary approach shows destination")
	await _step(3)
	if game.simulation.snapshot().region=="space":
		await _exp_action("fire_turret");await _step(15)
		if game.simulation.snapshot().region=="space":await _exp_action("flee");await _step(9)
	_check(game.simulation.snapshot().region==destination,"Travel arrives at "+destination)
