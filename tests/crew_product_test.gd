extends "res://tests/product_flow_test.gd"
## N4 product journey: real clicks, ray targets and native windows; no state injection.
const Catalog=preload("res://scripts/core/catalog.gd")
const Nav=preload("res://scripts/core/ground_navigation.gd")

func _run() -> void:
	_start_ms=Time.get_ticks_msec()
	root.size=Vector2i(1440,900)
	root.gui_embed_subwindows=false
	game=load("res://scenes/game.tscn").instantiate()
	game.save_path="res://output/n4-product-save.json"
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
	await _capture("n4-base")
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
	await _capture("n4-workshop")
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
	await _capture("n4-boarding")
	await _trip("rust")
	_check(game.simulation.snapshot().ship.mode=="flying","Destination arrival stays airborne")
	_check(game.simulation.snapshot().crew.ida.assignment=="aboard","Arrival keeps crew inside")
	await _capture("n4-rust-arrival")
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
	await _capture("n4-satellite")
	await _board()
	await _trip("base")
	await _fly_to(Vector2(25,22))
	await _land_and_exit()
	await _object("storage")
	var cargo_ui: Node=game.hud._cargo_panel
	game.hud._action_scroll.ensure_control_visible(cargo_ui._rows["cargo:blackbox"])
	await process_frame
	await _click(cargo_ui._rows["cargo:blackbox"].get_global_rect().get_center())
	_check(game.simulation.snapshot().inventory.blackbox==1,"Dock unload transfers actual blackbox into base inventory")
	await _object("contracts")
	await _action("claim_contract")
	_check(game.simulation.snapshot().contract.status=="claimed","First mission can still be paid after explicit return route")
	await _board()
	await _trip("station")
	await _fly_to(Vector2(0,28))
	await _land_and_exit()
	await _object("market")
	await _action("buy_multitool")
	await _action("buy_salvage_attachment")
	_check(game.simulation.snapshot().cargo.multitool==1 and game.simulation.snapshot().cargo.salvage_attachment==1,"Scrolled market buys the new actual equipment")
	await _capture("n4-market")
	await _key(KEY_F5)
	var saved: Dictionary=game.simulation.snapshot()
	await _step(1)
	await _key(KEY_F9)
	_check(game.simulation.snapshot().cargo==saved.cargo and game.simulation.snapshot().ship.seats==saved.ship.seats,"F5/F9 restores new cargo and seat state")
	var report: Dictionary={"checks":checks,"failed":failed,"engine":Engine.get_version_info().string,"wall_ms":Time.get_ticks_msec()-_start_ms,"input":"real GUI + ray targets + native Window events","time":"ordinary advance calls, accelerated; no state injection","evidence":evidence}
	var file:=FileAccess.open("res://output/n4-product-result.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"));file.close()
	print("N4 PRODUCT WINDOW: %d checks, %d failures"%[checks,failed])
	quit(0 if failed==0 else 1)

func _action(key: String) -> void:
	await process_frame
	await process_frame
	if not game.hud._action_buttons.has(key):
		_check(false,"Missing action "+key+" in "+game.hud.selection_id)
		return
	var button: Button=game.hud._action_buttons[key]
	game.hud._action_scroll.ensure_control_visible(button)
	await process_frame
	await process_frame
	await _click(button.get_global_rect().get_center())

func _named(text: String) -> void:
	for node: Node in game.hud._context_actions.get_children():
		if node is Button and node.text==text:
			game.hud._action_scroll.ensure_control_visible(node)
			await process_frame
			await _click(node.get_global_rect().get_center())
			return
	_check(false,"Missing visible action "+text)

func _board() -> void:
	# Selection is view-only setup; boarding itself must arrive through the real world ray.
	var ids: Array[String]=["ida","jaro"]
	game.hud.select_units(ids)
	game.hud.dismiss_context()
	game.world.focus_object("shuttle")
	await process_frame
	await physics_frame
	var ship: Node3D=game.world._objects.shuttle
	var screen: Vector2=game.world._camera.unproject_position(ship.global_position+Vector3(0,0.8,0))
	await _right_click(screen)
	_check(game.simulation.snapshot().crew.ida.assignment in ["boarding","aboard"],"Actual right-click on ship starts boarding")
	await _step(35)
	var s: Dictionary=game.simulation.snapshot()
	_check(s.crew.ida.assignment=="aboard" and s.crew.jaro.assignment=="aboard","Both crew walk to ship access before seats become aboard")

func _trip(destination: String) -> void:
	await _object("shuttle")
	await _action("launch")
	_check(game.simulation.snapshot().ship.mode=="flying","Explicit Abheben starts local flight")
	game.hud.dismiss_context()
	await _exp_action("enter_orbit")
	await _step(6)
	_check(game.simulation.snapshot().region=="orbit","Orbit is its own loaded map")
	await _capture("n4-orbit")
	await _exp_action("travel_chart")
	_check(game.travel_chart.visible,"Reisekarte opens from the actual orbit HUD")
	await create_timer(0.1).timeout
	await _window_activate(game.travel_chart,game.travel_chart._buttons[destination])
	_check(game.travel_chart._selected==destination and not game.travel_chart._route.disabled,"Named destination is selected in real chart")
	await process_frame
	await RenderingServer.frame_post_draw
	game.travel_chart.get_texture().get_image().save_png("res://output/n4-travel-chart.png")
	await _window_activate(game.travel_chart,game.travel_chart._route)
	_check(game.simulation.snapshot().travel.active,"Chart confirms a timed route instead of local movement")
	await _step(6)
	if game.simulation.snapshot().region=="space":
		await _capture("n4-pirates")
		await _exp_action("fire_turret")
		await _step(15)
		if game.simulation.snapshot().region=="space":
			await _exp_action("flee")
			await _step(9)
	_check(game.simulation.snapshot().region==destination,"Travel reaches "+destination+" after any encounter")

func _fly_to(point: Vector2) -> void:
	game.hud.dismiss_context()
	game.world._flight_camera_follow=false
	game.world._focus=Vector3(point.x,0,point.y)
	game.world._update_camera()
	await process_frame
	await physics_frame
	var screen: Vector2=game.world._camera.unproject_position(Vector3(point.x,0,point.y))
	await _right_click(screen)
	_check(game.world._destination_label.text.begins_with("FLUGZIEL"),"Accepted right-click labels local flight target distinctly")
	await _step(40)
	var p: Array=game.simulation.snapshot().ship.position
	_check(Vector2(p[0],p[1]).distance_to(point)<1.0,"Ship flies to actual right-click destination")

func _land_and_exit() -> void:
	await _exp_action("land")
	await _step(0.3)
	_check(game.simulation.snapshot().ship.mode=="landed" and game.simulation.snapshot().crew.ida.assignment=="aboard","Landing keeps crew aboard until explicit exit")
	await _object("shuttle")
	await _named("Crew aussteigen")
	_check(game.simulation.snapshot().crew.ida.assignment=="idle" and game.simulation.snapshot().crew.jaro.assignment=="idle","Crew exit appears at walkable ship access")

func _right_click(at: Vector2) -> void:
	root.warp_mouse(at)
	var motion:=InputEventMouseMotion.new();motion.position=at
	Input.parse_input_event(motion)
	await process_frame
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new()
		event.button_index=MOUSE_BUTTON_RIGHT;event.position=at;event.pressed=pressed
		Input.parse_input_event(event)
		await process_frame
	await process_frame

func _click(at: Vector2) -> void:
	await _window_click(root,at)

func _window_activate(window: Window,button: Button) -> void:
	# Scope keyboard activation to this native window; no signal or command shortcuts.
	button.grab_focus()
	await process_frame
	for pressed in [true,false]:
		var event:=InputEventKey.new()
		event.keycode=KEY_ENTER;event.physical_keycode=KEY_ENTER;event.pressed=pressed
		window.push_input(event,true)
		await process_frame
	await process_frame

func _window_click(window: Window,at: Vector2,double: bool=false) -> void:
	window.warp_mouse(at)
	await create_timer(0.05).timeout
	var motion:=InputEventMouseMotion.new();motion.position=at;motion.window_id=window.get_window_id()
	Input.parse_input_event(motion)
	await process_frame
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new()
		event.button_index=MOUSE_BUTTON_LEFT;event.position=at;event.pressed=pressed
		event.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.window_id=window.get_window_id();event.double_click=double and pressed
		Input.parse_input_event(event)
		await process_frame
	await process_frame
