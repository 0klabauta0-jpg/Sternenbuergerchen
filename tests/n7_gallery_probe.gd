extends SceneTree
## Visual fixtures only: actual renderer, no claims about completing gameplay journeys.
func _initialize() -> void:call_deferred("run")
func run() -> void:
	root.size=Vector2i(1440,900)
	var game:Node=load("res://scenes/game.tscn").instantiate();game.load_on_start=false
	game.save_path="res://output/n7-gallery-unused.json";root.add_child(game)
	await process_frame
	game.simulation.auto_tick=false;game.set_process(false)
	game.hud.hide();game.expedition.hide()
	var state:Dictionary=game.simulation.snapshot()
	DirAccess.make_dir_recursive_absolute("res://assets/original/previews")
	for region:String in ["base","rust","distribution_friendly","tradepost","bunker_surface","station"]:
		var view:Dictionary=state.duplicate(true);view.region=region
		view.ship.position=preload("res://scripts/core/catalog.gd").landmarks(region).shuttle.duplicate();view.ship.target=view.ship.position.duplicate()
		game.world.present(view)
		game.world._flight_camera_follow=false
		game.world._focus=Vector3(0,0,-3) if region=="base" else Vector3(0,0,0)
		game.world._zoom=86 if region=="base" else 245 if region=="distribution_friendly" else 140
		if region=="rust":game.world._focus=Vector3(-80,0,20);game.world._zoom=240
		await create_timer(0.35).timeout;await RenderingServer.frame_post_draw
		var picture:Image=root.get_texture().get_image()
		picture.save_png("res://output/n7-gallery-%s.png"%region)
		picture.resize(640,400,Image.INTERPOLATE_LANCZOS)
		picture.save_jpg("res://assets/original/previews/%s.jpg"%region,0.86)
	game.hud._dossier.present(state,"ida")
	game.hud._dossier.open_for("ida")
	await create_timer(0.3).timeout;await RenderingServer.frame_post_draw
	game.hud._dossier.get_texture().get_image().save_png("res://output/n7-dossier.png")
	print("N7_GALLERY captured actual renderer previews")
	quit()
