extends SceneTree
## Real point-and-click movement, rectangle selection and camera-only WASD.
var game: Node
var checks := 0
var failed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size=Vector2i(1440,900)
	game=load("res://scenes/game.tscn").instantiate()
	game.load_on_start=false
	game.save_path="res://output/control-unused-save.json"
	root.add_child(game)
	await create_timer(0.3).timeout
	var first: Vector2=game.world._camera.unproject_position(game.world._units.ida.position+Vector3(0,1,0))
	var second: Vector2=game.world._camera.unproject_position(game.world._units.jaro.position+Vector3(0,1,0))
	var area:=Rect2(first,Vector2.ZERO).expand(second).grow(28)
	await _mouse(MOUSE_BUTTON_LEFT,area.position,true)
	var motion:=InputEventMouseMotion.new()
	motion.position=area.end;motion.global_position=area.end
	motion.relative=area.size;motion.button_mask=MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(motion)
	await process_frame
	await _capture("controls-01-selection-frame")
	await _mouse(MOUSE_BUTTON_LEFT,area.end,false)
	_check(game.hud.selected_units.size()==2,"Rectangle selects both crew members")
	await _mouse(MOUSE_BUTTON_LEFT,Vector2(50,110),true)
	var blocked:=InputEventMouseMotion.new()
	blocked.position=Vector2(260,390);blocked.global_position=blocked.position
	blocked.relative=Vector2(210,280);blocked.button_mask=MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(blocked)
	await process_frame
	_check(not game.world._control._selecting,"A drag starting on the HUD cannot select the world")
	await _mouse(MOUSE_BUTTON_LEFT,blocked.position,false)
	var before: Dictionary=game.simulation.snapshot()
	var destination: Vector2=game.world._camera.unproject_position(Vector3(2,0,6))
	await _mouse(MOUSE_BUTTON_RIGHT,destination,true)
	await _mouse(MOUSE_BUTTON_RIGHT,destination,false)
	var ordered: Dictionary=game.simulation.snapshot()
	_check(ordered.crew.ida.target!=before.crew.ida.target and ordered.crew.jaro.target!=before.crew.jaro.target,"One right click commands both selected crew")
	_check(ordered.crew.ida.target!=ordered.crew.jaro.target,"Group destinations leave space between crew")
	await create_timer(2.0).timeout
	await _button(game.hud._crew_buttons.ida)
	_check(not game.world._units.jaro.get_node("Selection").visible,"Single selection clears the old group ring")
	await _button(game.hud._control_toggle)
	_check(game._direct_mode,"Visible switch enables single-figure camera follow")
	var initial: Dictionary=game.simulation.snapshot()
	var target: Vector2=game.world._camera.unproject_position(Vector3(-2,0,4))
	await _mouse(MOUSE_BUTTON_RIGHT,target,true)
	await _mouse(MOUSE_BUTTON_RIGHT,target,false)
	await create_timer(0.5).timeout
	var moved: Dictionary=game.simulation.snapshot()
	_check(_position(moved,"ida").distance_to(_position(initial,"ida"))>1.0,"Right click moves the chosen figure in single view")
	_check(_position(moved,"jaro").distance_to(_position(initial,"jaro"))<0.05,"Unselected crew remains in place")
	_key(KEY_SPACE,true);await process_frame;_key(KEY_SPACE,false)
	await process_frame
	var paused: Dictionary=game.simulation.snapshot()
	await create_timer(0.3).timeout
	_check(paused.paused and _position(game.simulation.snapshot(),"ida").distance_to(_position(paused,"ida"))<0.05,"Space pauses a point-and-click movement")
	await _button(game.hud._pause)
	await create_timer(1.5).timeout
	var settled: Dictionary=game.simulation.snapshot()
	var camera_before: Vector3=game.world._focus
	_key(KEY_W,true)
	await create_timer(0.3).timeout
	_key(KEY_W,false)
	_check(game.world._focus.distance_to(camera_before)>1.0,"W moves only the camera even in single view")
	_check(_position(game.simulation.snapshot(),"ida").distance_to(_position(settled,"ida"))<0.05,"WASD never moves the figure")
	await _capture("controls-02-point-and-click")
	_key(KEY_V,true);await process_frame;_key(KEY_V,false)
	await process_frame
	_check(not game._direct_mode,"V returns to the free crew view")
	_check(game.hud._toast.get_global_rect().end.y<=900,"Event feedback remains inside the viewport")
	var file:=FileAccess.open("res://output/control-result.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failed":failed,"input":"Actual product viewport, rectangle selection, right-click crew orders, camera-only WASD and view switch"},"\t"));file.close()
	print("CONTROL WINDOW: %d checks, %d failures" % [checks,failed])
	quit(0 if failed==0 else 1)

func _position(state: Dictionary,id: String) -> Vector2:
	return Vector2(state.crew[id].position[0],state.crew[id].position[1])

func _check(value: bool,label: String) -> void:
	checks+=1
	if not value: failed+=1;printerr("FAIL: ",label)
	else: print("PASS: ",label)

func _key(code: Key,down: bool) -> void:
	var event:=InputEventKey.new()
	event.keycode=code;event.physical_keycode=code;event.pressed=down
	Input.parse_input_event(event)

func _mouse(button: MouseButton,position: Vector2,down: bool) -> void:
	var event:=InputEventMouseButton.new()
	event.button_index=button;event.position=position;event.global_position=position;event.pressed=down
	Input.parse_input_event(event)
	await process_frame
	await process_frame

func _button(button: Button) -> void:
	await _mouse(MOUSE_BUTTON_LEFT,button.get_global_rect().get_center(),true)
	await _mouse(MOUSE_BUTTON_LEFT,button.get_global_rect().get_center(),false)

func _capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://output/"+name+".png")
