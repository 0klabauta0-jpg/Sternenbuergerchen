extends SceneTree
## Headless negative-input guard; positive click/product flow is tested by
## tests/control_window_test.gd. No second native window during that test.
var game: Node
var boxes := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1440,900)
	game = load("res://scenes/game.tscn").instantiate()
	game.load_on_start = false
	game.save_path = "res://output/ui-guard-unused-save.json"
	root.add_child(game)
	game.simulation.auto_tick = false
	game.world.units_selected.connect(func(_ids: Array[String]): boxes+=1)
	await create_timer(0.15).timeout
	await _mouse(Vector2(20,135),true)
	await _motion(Vector2(700,600))
	_check(not game.world._control._frame.visible,"HUD press cannot begin selection frame")
	await _mouse(Vector2(700,600),false)
	_check(boxes==0,"HUD-origin drag emits no world selection")
	await _mouse(Vector2(330,600),true)
	await _motion(Vector2(730,550))
	_check(game.world._control._frame.visible,"World-origin drag displays frame")
	await _mouse(Vector2(1150,300),false)
	_check(not game.world._control._frame.visible and not game.world._control._selecting and boxes==1,"World drag releases cleanly over HUD")
	print("WORLD_UI_GUARD: 4 checks, ",failures," failures")
	quit(1 if failures else 0)

func _mouse(position: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = position
	event.global_position = position
	event.pressed = pressed
	Input.parse_input_event(event)
	await process_frame
	await process_frame

func _motion(position: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = position
	event.global_position = position
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(event)
	await process_frame

func _check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: ",label)
	else:
		failures+=1
		printerr("FAIL: ",label)
