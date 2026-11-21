extends SceneTree

const Models = preload("res://models.gd")
const RESOLUTION := Vector2i(1280, 800)

var viewport: SubViewport
var stage: Node3D
var camera: Camera3D
var frames: Array[Dictionary]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("FAIL: render check needs a native rendering driver")
		quit(1)
		return

	_setup_stage()
	for variant in [
		[Models.SEGMENTED, "segmented"],
		[Models.ATLAS, "atlas"],
	]:
		var loaded := Models.load_asset(variant[0])
		if loaded.has("error"):
			_abort(loaded.error)
			return
		var model: Node3D = loaded.model
		stage.add_child(model)
		var names := [variant[1] + "_front.png", variant[1] + "_rear.png"]
		var target := Vector3(0.0, 13.0, 0.0)
		if not await _capture(names[0], Vector3(122, 82, 142), target, 80.0):
			return
		if not await _capture(names[1], Vector3(-122, 82, -142), target, 80.0):
			return
		model.free()

	var game := Models.load_asset(Models.GAME)
	var cutlass := Models.load_asset(Models.CUTLASS)
	if game.has("error") or cutlass.has("error"):
		for loaded in [game, cutlass]:
			if loaded.has("model"):
				(loaded.model as Node3D).free()
		_abort(str(game.get("error", cutlass.get("error", "size comparison failed"))))
		return
	var tanker: Node3D = game.model
	var reference: Node3D = cutlass.model
	stage.add_child(tanker)
	stage.add_child(reference)
	tanker.position.x = -2.0
	reference.position.x = 4.4
	if not await _capture("scale_top.png", Vector3(0.0, 22.0, 0.0), Vector3.ZERO, 12.3, Vector3.FORWARD):
		return
	if not await _capture("scale_front.png", Vector3(9.5, 10.0, 20.0), Vector3(0, 0.8, 0), 11.0):
		return

	var metadata := FileAccess.open("res://capture_evidence.json", FileAccess.WRITE)
	if metadata == null:
		_abort("could not write capture metadata")
		return
	metadata.store_line(JSON.stringify({
		"godot": Engine.get_version_info().string,
		"rendering_method": RenderingServer.get_current_rendering_method(),
		"rendering_device": RenderingServer.get_video_adapter_name(),
		"projection": "orthographic",
		"resolution": [RESOLUTION.x, RESOLUTION.y],
		"ship_lengths_world_units": {"tanker": Models.LENGTH_METERS * Models.GAME_SCALE, "cutlass": 3.52},
		"images": frames,
	}, "  ", true, true))
	metadata.close()
	print("PASS: tanker native capture")
	quit()


func _setup_stage() -> void:
	viewport = SubViewport.new()
	viewport.size = RESOLUTION
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)

	stage = Node3D.new()
	viewport.add_child(stage)

	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("#202b39")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("#d0e0f6")
	environment.environment.ambient_light_energy = 0.75
	stage.add_child(environment)

	_add_light(Vector3(-46.0, -36.0, 0.0), Color("#fff1dd"), 1.25)
	_add_light(Vector3(-35.0, 145.0, 0.0), Color("#bed9ff"), 0.95)

	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.far = 1000.0
	stage.add_child(camera)
	camera.make_current()


func _add_light(rotation: Vector3, color: Color, energy: float) -> void:
	var light := DirectionalLight3D.new()
	light.rotation_degrees = rotation
	light.light_color = color
	light.light_energy = energy
	stage.add_child(light)


func _capture(name: String, eye: Vector3, target: Vector3, size: float, up := Vector3.UP) -> bool:
	camera.position = eye
	camera.size = size
	camera.look_at(target, up)
	await process_frame
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw
	var pixels := viewport.get_texture().get_image()
	if pixels == null or pixels.is_empty():
		_abort("empty native viewport for " + name)
		return false
	if pixels.save_png("res://" + name) != OK:
		_abort("could not write " + name)
		return false
	frames.append({
		"image": name,
		"eye": [eye.x, eye.y, eye.z],
		"target": [target.x, target.y, target.z],
		"up": [up.x, up.y, up.z],
		"camera_size": size,
	})
	return true


func _abort(reason: String) -> void:
	printerr("FAIL: ", reason)
	quit(1)
