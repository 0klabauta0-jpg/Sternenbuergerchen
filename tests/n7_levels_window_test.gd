extends SceneTree
var failures:=0
var checks:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
func run() -> void:
	root.size=Vector2i(1440,900)
	var game:Node=load("res://scenes/game.tscn").instantiate();game.load_on_start=false;game.save_path="res://output/n7-levels-window.json";root.add_child(game)
	await process_frame;game.simulation.auto_tick=false
	# Site fixture isolates level UI; no claim of flying the preceding mission.
	var state:Dictionary=game.simulation._state
	var catalog=load("res://scripts/core/catalog.gd")
	state.region="bunker_surface";state.ship.position=catalog.landmarks(state.region).shuttle.duplicate();state.ship.target=state.ship.position.duplicate()
	for unit:Dictionary in state.crew.values():unit.position=catalog.landmarks(state.region).bunker_entry.duplicate();unit.target=unit.position.duplicate()
	await create_timer(0.3).timeout
	var selection:Array[String]=["ida"];game.hud.select_units(selection)
	check(game.send_command({"type":"use_elevator"}).ok,"UI sends selected crew to elevator")
	check(state.crew.ida.level_region=="bunker_depths" and state.crew.jaro.level_region=="bunker_surface","split levels confirmed")
	game._on_action("switch_level",{})
	await create_timer(0.3).timeout
	check(game.world._region=="bunker_depths","local lower view")
	check(game.world._units.ida.visible and not game.world._units.jaro.visible,"only local-level crew rendered")
	check(game.simulation.snapshot().region=="bunker_surface","view does not move simulation site")
	game.world._focus=Vector3(4,0,18);game.world._zoom=81
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://output/n7-bunker-lower.png")
	game._on_action("switch_level",{});await create_timer(0.2).timeout
	check(game.world._units.jaro.visible and not game.world._units.ida.visible,"surface retains left-behind crew")
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://output/n7-bunker-surface.png")
	game._on_action("switch_level",{});await create_timer(0.2).timeout
	check(game.world._focus.distance_to(Vector3(4,0,18))<0.01 and is_equal_approx(game.world._zoom,81),"level camera restored")
	check(game.simulation.save_game(game.save_path).ok,"native split state saves")
	check(game.simulation.load_game(game.save_path).ok,"native split state reloads")
	print("N7_LEVELS_WINDOW ",checks," checks, ",failures," failures");quit(1 if failures else 0)
