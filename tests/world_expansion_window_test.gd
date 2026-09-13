extends "res://tests/crew_product_test.gd"
## Native travel buttons use actual focus/Enter input; scenery snapshots are labelled fixtures.
const Regions=preload("res://scripts/core/regions.gd")
const Journey=preload("res://tests/n4_test_journey.gd")
const WorldProbe=preload("res://scripts/world/world_n4_probe.gd")
func _run() -> void:
	_start_ms=Time.get_ticks_msec();root.size=Vector2i(1440,900);root.gui_embed_subwindows=false
	game=load("res://scenes/game.tscn").instantiate();game.load_on_start=false;game.save_path="res://output/n5-window-save.json";game.simulation_seed=1
	root.add_child(game);game.simulation.auto_tick=false
	await create_timer(0.5).timeout
	game.world.set("_focus",Vector3(0,0,-4));game.world.set("_zoom",87)
	await photo("base-details")
	game.world.set("_focus",Vector3(0,0,180));game.world.set("_zoom",420)
	await photo("terraced-canyon")
	game.world.set("_focus",Vector3(25,0,22));game.world.set("_zoom",23)
	await photo("entersaebel")
	_check(Journey.board(game.simulation),"real crew walks to ship")
	_check(Journey.command(game.simulation,"launch").ok,"launch")
	_check(Journey.command(game.simulation,"enter_orbit").ok,"climb to orbit");await _step(5.1)
	game.world.set("_flight_camera_follow",false);game.world.set("_focus",Vector3.ZERO);game.world.set("_zoom",480)
	await photo("orbit")
	var chart: Window=game.travel_chart
	chart.transient=true
	chart.open_chart(game.simulation.snapshot());await create_timer(0.3).timeout
	_check(chart._buttons.size()==9,"nine native destination controls")
	for id: String in Regions.DESTINATIONS:
		var button: Button=chart._buttons[id]
		_check(Rect2(Vector2.ZERO,Vector2(chart.size)).encloses(button.get_global_rect()),"visible destination "+id)
		await _window_activate(chart,button)
		_check(chart._selected==id,"native selection "+id)
	_check(Rect2(Vector2.ZERO,Vector2(chart.size)).encloses(chart._route.get_global_rect()),"travel confirmation within window")
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://output/n5-world")
	chart.get_texture().get_image().save_png("res://output/n5-world/travel-chart.png")
	for destination: String in ["bunker_surface","bunker_medium","bunker_hard","distribution","distribution_friendly","tradepost","station"]:
		if game.simulation.snapshot().region!="orbit":
			_check(Journey.command(game.simulation,"enter_orbit").ok,"return orbit");await _step(5.1)
		chart.open_chart(game.simulation.snapshot());await create_timer(0.15).timeout
		await _window_activate(chart,chart._buttons[destination]);await _window_activate(chart,chart._route)
		_check(game.simulation.snapshot().travel.active,"native travel starts "+destination)
		chart.hide();await _step(5.1)
		if game.simulation.snapshot().region=="space":
			game.world.set("_zoom",360);await photo("space-contact")
			_check(Journey.command(game.simulation,"flee").ok,"escape actual encounter");await _step(7.1)
		_check(game.simulation.snapshot().region==destination,"actual selected arrival "+destination)
		game.world.set("_flight_camera_follow",false);game.world.set("_focus",Vector3.ZERO)
		game.world.set("_zoom",290 if Regions.archetype(destination)=="distribution" else 170 if Regions.bunker(destination) else 120)
		await photo(destination)
		_check(game.simulation.save_game("res://output/n5-window-save.json").ok,"arrival persists "+destination)
		if destination=="station":
			_check(Journey.fly_land(game.simulation,Catalog.landmarks(destination).shuttle),"station landing")
			game.world.present(game.simulation.snapshot());await process_frame
			await _object("market");game._refresh();await process_frame
			_check(game.hud._prices.parts.buy==24 and game.hud._prices.alloy.sell==145,"regional price UI matches authoritative table")
			await photo("market-prices")
	chart.hide()
	# These interior photographs are projection fixtures, not claims of a UI combat playthrough.
	game.set_process(false)
	for region: String in ["bunker_depths","bunker_medium_depths","bunker_hard_depths"]:
		var state: Dictionary=game.simulation.snapshot();state.region=region;state.ship.mode="landed"
		for unit: Dictionary in state.crew.values():unit.assignment="idle";unit.position=Catalog.landmarks(region).elevator.duplicate();unit.target=unit.position.duplicate()
		game.world.present(state);game.world.set("_flight_camera_follow",false);game.world.set("_focus",Vector3.ZERO);game.world.set("_zoom",200*Regions.depth_scale(region)/2.0)
		game.hud.present(state)
		await photo(region+"-fixture")
	var report: Dictionary={"checks":checks,"failures":failed,"scope":"Actual native destination selection and travel; real stock prices. Underground screenshots are labelled projection fixtures; core test covers combat and each elevator.","elapsed_ms":Time.get_ticks_msec()-_start_ms}
	var file:=FileAccess.open("res://output/n5-window-result.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
	print("N5_WINDOW_RESULT ",JSON.stringify(report));quit(1 if failed else 0)
func photo(id: String) -> void:
	await create_timer(0.22).timeout
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://output/n5-world")
	_check(root.get_texture().get_image().save_png("res://output/n5-world/"+id+".png")==OK,"photo "+id)
