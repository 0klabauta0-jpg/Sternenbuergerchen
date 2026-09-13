extends SceneTree
## Actual window, product scene, ray picks and GUI input. No success-state injection.
var game: Node
var checks := 0
var failed := 0
var evidence: Array[String] = []
var _start_ms := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_start_ms=Time.get_ticks_msec()
	root.size=Vector2i(1440,900)
	game=load("res://scenes/game.tscn").instantiate()
	game.save_path="res://output/product-test-save.json"
	game.load_on_start=false
	game.simulation_seed=3
	root.add_child(game)
	game.simulation.auto_tick=false
	await process_frame
	await physics_frame
	await process_frame
	_check(game.simulation.snapshot().crew.size()==2,"Two crew members in visible base")
	_check(not game.hud._network_window.visible,"No unwanted startup popup")
	await _capture("product-01-base")
	await _object("workbench")
	_check(game.hud.selection_id=="workbench","World ray click opens workbench menu")
	await _click(game.hud._crew_buttons.jaro.get_global_rect().get_center())
	_check(game.hud.selection_id=="workbench","Choosing a worker preserves the workbench context")
	_check(game.hud._action_buttons.toolkit.disabled and game.hud._action_buttons.toolkit.text.contains("Technik 2"),"Recipe explains the selected worker's missing skill")
	await _click(game.hud._crew_buttons.ida.get_global_rect().get_center())
	await _action("toolkit")
	_check(game.simulation.snapshot().work.active,"GUI starts assigned production")
	game.hud.choose_unit("jaro",false)
	_check(game.hud._context_text.text.contains("Ida") and game.hud._context_text.text.contains("Werkzeug"),"Active job names its assigned worker and recipe even when another crew member is selected")
	game.hud.choose_unit("ida",false)
	await _step(1.5)
	await _click(game.hud._pause.get_global_rect().get_center())
	var before: Dictionary=game.simulation.snapshot()
	await _step(4)
	_check(game.simulation.snapshot().time==before.time,"Pause holds production and simulation time")
	await _capture("product-02-crafting-paused")
	await _click(game.hud._pause.get_global_rect().get_center())
	await _step(10)
	_check(game.simulation.snapshot().inventory.toolkit==1,"Crafted item reaches real inventory")
	await _object("storage")
	await _action("load_toolkit")
	_check(game.simulation.snapshot().cargo.toolkit==1,"Inventory item loaded via GUI")
	await _action("unload_toolkit")
	_check(game.simulation.snapshot().inventory.toolkit==1 and game.simulation.snapshot().cargo.toolkit==0,"Accidental cargo loading is reversible in UI")
	await _action("load_toolkit")
	await _object("shuttle")
	await _action("station")
	await _step(5)
	_check(game.simulation.snapshot().travel.active,"Visible timed travel, no teleport")
	await _capture("product-03-travel")
	await _step(15)
	_check(game.simulation.snapshot().region=="space","Random station route loads a separate space contact")
	await _capture("product-space-contact")
	await _exp_action("fire_turret")
	_check(game.simulation.snapshot().encounter.turret_target=="pirate","Actual turret button assigns Jaro to attack")
	await _step(8)
	_check(game.simulation.snapshot().region=="station","Arrived at market region")
	await _object("market")
	await _action("sell_toolkit")
	await _action("buy_parts")
	_check(game.simulation.snapshot().credits==195 and game.simulation.snapshot().cargo.parts==1,"Market sells crafted goods and purchases materials")
	await _capture("product-04-market")
	await _object("shuttle")
	await _action("base")
	await _step(20)
	_check(game.simulation.snapshot().inventory.parts==3,"Market parts returned to base storage")
	await _object("contracts")
	await _capture("product-contract-check")
	await _action("accept_contract")
	_check(game.simulation.snapshot().contract.status=="active","Contract accepted through world console")
	await _object("shuttle")
	await _action("rust")
	await _step(20)
	_check(game.simulation.snapshot().region=="rust","Rostwelt mission entered normally")
	await _capture("product-05-rust-arrival")
	var hidden_wreck: Node3D=game.world._objects.satellite
	var wreck_colliders: Array[Node]=hidden_wreck.find_children("*","CollisionObject3D",true,false)
	var hidden_pickable := false
	for collider: CollisionObject3D in wreck_colliders:
		if collider.collision_layer!=0: hidden_pickable=true
	_check(not hidden_wreck.visible and not hidden_pickable,"Undiscovered wreck is hidden and cannot be picked")
	await _exp_action("launch")
	await _step(5)
	await _exp_action("radar_scan")
	_check(game.simulation.snapshot().discovery.signals.size()==3,"Actual radar button reveals anonymous contacts")
	await _exp_action("contact_signal_01")
	await _step(4)
	await _capture("product-search-flight")
	await _step(16)
	_check(game.simulation.snapshot().discovery.satellite_found,"Flying to the radar contact discovers the satellite")
	await _exp_action("land")
	await _step(1)
	await _click(game.hud._objective_button.get_global_rect().get_center())
	await _action("salvage")
	_check(game.simulation.snapshot().salvage.active,"Commander assigns satellite work")
	await _step(5)
	_check(game.simulation.snapshot().cargo.blackbox==0,"Distant work requires real approach")
	await _click(game.hud._crew_buttons.ida.get_global_rect().get_center())
	await _step(25)
	_check(game.simulation.snapshot().cargo.blackbox==1,"Finite satellite yields blackbox")
	await _click(game.hud._crew_buttons.ida.get_global_rect().get_center())
	await process_frame
	await _object("satellite")
	await _capture("product-06-satellite")
	await _click(game.hud._objective_button.get_global_rect().get_center())
	await _action("base")
	await _step(30)
	_check(game.simulation.snapshot().region=="base","Crew boards and returns with cargo")
	await _object("contracts")
	await _action("claim_contract")
	var paid: int=game.simulation.snapshot().credits
	_check(paid==455 and game.simulation.snapshot().blueprints.has("cutter"),"Payout and blueprint awarded in product")
	await _action("claim_contract")
	_check(game.simulation.snapshot().credits==paid,"Disabled second hand-in grants no duplicate payout")
	await _object("workbench")
	_check(game.hud._action_buttons.cutter.disabled,"First-tier bench cannot craft the advanced reward blueprint")
	await _action("upgrade_workbench")
	await _step(25)
	_check(int(game.simulation.snapshot().base.workbench_tier)==2,"Worker upgrades the actual bench to tier two")
	await _action("cutter")
	await _step(2)
	await _click(game.hud._pause.get_global_rect().get_center())
	await _key(KEY_F5)
	_check(FileAccess.file_exists(game.save_path),"F5 saves to isolated test file")
	var saved_time: float=game.simulation.snapshot().time
	await _click(game.hud._pause.get_global_rect().get_center())
	await _step(20)
	_check(game.simulation.snapshot().inventory.cutter==1,"Reward blueprint produces useful equipment")
	await _key(KEY_F9)
	_check(game.simulation.snapshot().paused and is_equal_approx(game.simulation.snapshot().time,saved_time) and game.simulation.snapshot().work.active,"F9 restores paused in-progress work")
	await _click(game.hud._pause.get_global_rect().get_center())
	await _step(20)
	_check(game.simulation.snapshot().inventory.cutter==1 and game.simulation.snapshot().credits==paid,"Restored production and payout stay exactly once")
	await _capture("product-07-return")
	await _object("storage")
	await _action("load_cutter")
	await _object("shuttle")
	await _action("station")
	await _step(20)
	if game.simulation.snapshot().region=="space":
		await _exp_action("flee")
		await _step(8)
	await _click(game.hud._objective_button.get_global_rect().get_center())
	await _action("sell_cutter")
	_check(game.simulation.snapshot().credits==paid+85 and game.simulation.snapshot().cargo.cutter==0,"Blueprint-produced cutter can be sold through GUI")
	await _action("buy_parts")
	await _object("shuttle")
	await _action("base")
	await _step(25)
	await _object("workbench")
	await _action("helmet")
	await _step(20)
	_check(int(game.simulation.snapshot().inventory.helmet)==1,"Tier-one helmet repair is a real worker recipe")
	game.hud._menu_action(7)
	await process_frame
	_check(game.hud.selection_id=="ida" and game.hud._context_text.text.contains("Pilot"),"Menu opens the real character profile")
	await _capture("product-crew-sheet")
	await _action("equip_helmet")
	_check(game.simulation.snapshot().crew.ida.equipment.helmet=="helmet" and int(game.simulation.snapshot().inventory.helmet)==0,"Character profile equips helmet from actual inventory")
	var report: Dictionary={"engine":Engine.get_version_info().string,"checks":checks,"failed":failed,"wall_ms":Time.get_ticks_msec()-_start_ms,"viewport":"1440x900","input":"Input.parse_input_event GUI clicks + world ray picks","time":"accelerated by normal advance steps; no success-state injection","evidence":evidence}
	var file:=FileAccess.open("res://output/product-result.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t")); file.close()
	print("PRODUCT WINDOW: %d checks, %d failures" % [checks,failed])
	quit(0 if failed==0 else 1)

func _check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:
		failed+=1
		printerr("FAIL: ",label)
	else: print("PASS: ",label)

func _step(seconds: float) -> void:
	var remaining: float=seconds
	while remaining>0:
		game.simulation.advance(minf(0.2,remaining))
		remaining-=0.2
		await process_frame
	game._refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	await process_frame

func _action(key: String) -> void:
	await process_frame
	await process_frame
	if not game.hud._action_buttons.has(key):
		_check(false,"Missing action "+key+" in "+game.hud.selection_id)
		return
	var button: Button=game.hud._action_buttons[key]
	await _click(button.get_global_rect().get_center())

func _exp_action(key: String) -> void:
	game._refresh()
	await process_frame
	await process_frame
	if not game.expedition._buttons.has(key):
		_check(false,"Missing flight action "+key)
		return
	var button: Button=game.expedition._buttons[key]
	await _click(button.get_global_rect().get_center())

func _object(id: String) -> void:
	if not game.world._objects.has(id):
		_check(false,"Missing world object "+id)
		return
	var object: Node3D=game.world._objects[id]
	game.world.focus_object(id)
	await process_frame
	await process_frame
	var at: Vector2=game.world._camera.unproject_position(object.global_position+Vector3(0,0.8,0))
	await _click(at)
	_check(game.hud.selection_id==id,"Ray selects "+id)

func _click(position: Vector2) -> void:
	var motion:=InputEventMouseMotion.new()
	motion.position=position; motion.global_position=position
	Input.parse_input_event(motion)
	await process_frame
	var press:=InputEventMouseButton.new()
	press.button_index=MOUSE_BUTTON_LEFT;press.position=position;press.global_position=position;press.pressed=true
	Input.parse_input_event(press)
	await process_frame
	var release:=InputEventMouseButton.new()
	release.button_index=MOUSE_BUTTON_LEFT;release.position=position;release.global_position=position;release.pressed=false
	Input.parse_input_event(release)
	await process_frame
	await process_frame

func _key(code: Key) -> void:
	var press:=InputEventKey.new()
	press.keycode=code;press.physical_keycode=code;press.pressed=true
	Input.parse_input_event(press)
	await process_frame
	var release:=InputEventKey.new()
	release.keycode=code;release.physical_keycode=code;release.pressed=false
	Input.parse_input_event(release)
	await process_frame
	await process_frame

func _capture(name: String) -> void:
	game._refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	var path: String="res://output/"+name+".png"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://output"))
	var error: Error=root.get_texture().get_image().save_png(path)
	_check(error==OK,"Capture "+name)
	evidence.append(path)
