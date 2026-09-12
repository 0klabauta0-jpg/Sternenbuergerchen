extends SceneTree
## Real renderer inspection through production commands. No fixture game state.
## godot --path . --script res://scripts/world/world_visual_probe.gd
var game: Node
var observed := ""
var samples: Array[float] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var loaded := load("res://scenes/game.tscn") as PackedScene
	game = loaded.instantiate()
	root.add_child(game)
	await process_frame
	game.simulation.auto_tick = false
	game.world.object_selected.connect(func(kind: String,id: String): observed=kind+":"+id)
	await create_timer(0.6).timeout
	var crew_model: Node = game.world.get("_units").ida
	for player in crew_model.find_children("*","AnimationPlayer",true,false):
		print("CREW_ANIMATIONS ",player.get_animation_list()," current=",player.current_animation," position=",player.current_animation_position)
	await _capture("base")
	game.world.focus_unit("ida")
	game.world.set("_zoom",19.0)
	await create_timer(0.3).timeout
	await _capture("crew-detail")
	game.world.focus_home()
	await process_frame
	var camera: Camera3D = game.world.get("_camera")
	game.world.call("_pick",camera.unproject_position(Vector3(3,1,-1)))
	assert(observed == "object:workbench","Workbench picking did not resolve its stable ID")
	var ida: Array = game.simulation.snapshot().crew.ida.position
	game.world.call("_pick",camera.unproject_position(Vector3(ida[0],1,ida[1])))
	assert(observed == "unit:ida","Crew picking did not resolve its stable ID")
	_send({"type":"assign_work","unit_id":"ida","recipe_id":"toolkit"})
	game.simulation.advance(0.15)
	await create_timer(0.2).timeout
	var astronaut: AnimationPlayer = crew_model.get_meta("animation_player")
	assert(astronaut.current_animation == "Walk","Walking snapshot must play Walk")
	game.simulation.advance(1.5)
	await create_timer(0.2).timeout
	assert(astronaut.current_animation == "Work","Working snapshot must play Work")
	game.world.focus_unit("ida")
	game.world.set("_zoom",19.0)
	await create_timer(0.2).timeout
	await _capture("crew-working")
	game.simulation.advance(10.0)
	await process_frame
	assert(not game.simulation.snapshot().work.active)
	game.world.focus_home()
	_send({"type":"accept_contract"})
	_send({"type":"travel","destination":"rust"})
	for i in range(300): game.simulation.advance(0.1)
	assert(game.simulation.snapshot().region == "rust")
	await process_frame
	game.hud.select_object("object","satellite")
	await create_timer(0.4).timeout
	await _capture("rust-landing")
	game.world.focus_object("satellite")
	await create_timer(0.3).timeout
	await _capture("rust-wreck")
	game.world.call("_pick",camera.unproject_position(Vector3(22,1,-15)))
	assert(observed == "object:satellite")
	_send({"type":"travel","destination":"station"})
	for i in range(300): game.simulation.advance(0.1)
	assert(game.simulation.snapshot().region == "station")
	await process_frame
	game.hud.select_object("object","market")
	await create_timer(0.5).timeout
	await _capture("station")
	game.world.call("_pick",camera.unproject_position(Vector3(0,1,-3)))
	assert(observed == "object:market")
	await create_timer(1.3).timeout
	var previous := Time.get_ticks_usec()
	for i in range(120):
		await process_frame
		var current := Time.get_ticks_usec()
		samples.append((current-previous)/1000.0)
		previous=current
	samples.sort()
	print("WORLD_VISUAL_PROBE_PASS real_commands=travel/base/rust/station picking=workbench/ida/satellite/market frames=120 frame_median_ms=",samples[60]," frame_p95_ms=",samples[114]," process_ms=",Performance.get_monitor(Performance.TIME_PROCESS)*1000.0," physics_ms=",Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0," objects=",Performance.get_monitor(Performance.OBJECT_COUNT)," nodes=",Performance.get_monitor(Performance.OBJECT_NODE_COUNT)," draw_calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)," static_memory_mb=",Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0)
	quit()

func _send(command: Dictionary) -> void:
	var result: Dictionary = game.send_command(command)
	assert(result.get("ok",false),str(result))

func _capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var path := "res://output/world/"+name+"-verified.png"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://output/world"))
	var image: Image = root.get_texture().get_image()
	if image.get_width() > 1440:
		path = path.replace("-verified.png","-1440p-verified.png")
	assert(image.save_png(path) == OK)
	print("WORLD_CAPTURE ",ProjectSettings.globalize_path(path))
