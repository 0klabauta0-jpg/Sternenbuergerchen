extends SceneTree
const Core = preload("res://scripts/core/simulation_root.gd")
const Catalog = preload("res://scripts/core/catalog.gd")
var checks: int = 0
var failed: int = 0
var commands: Array[Dictionary] = []
var real_results: Array[Dictionary] = []
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failed += 1
		printerr("FAIL ", label)
func run() -> void:
	check(ResourceLoader.exists("res://scripts/ui/crew_dossier.gd"), "crew dossier available")
	if failed > 0:
		quit(1)
		return
	root.size = Vector2i(1280, 850)
	root.gui_embed_subwindows = false
	var script: GDScript = load("res://scripts/ui/crew_dossier.gd")
	var dossier: Window = script.new()
	root.add_child(dossier)
	check(dossier.has_method("present") and dossier.has_method("open_for"), "dossier integration API")
	check(dossier.has_signal("action_requested"), "dossier sends commands instead of mutating core")
	if DisplayServer.get_name() == "headless":
		print("DOSSIER_API checks=", checks, " failed=", failed, "; native mouse/render checks require a window (omit --headless)")
		quit(0 if failed == 0 else 1)
		return
	var sim: Node = Core.new(3)
	sim.auto_tick = false
	root.add_child(sim)
	var before: Dictionary = sim.snapshot()
	dossier.present(before, "ida")
	dossier.action_requested.connect(func(action: String, payload: Dictionary) -> void: commands.append({"type":action, "payload":payload}))
	dossier.open_for("ida")
	dossier.grab_focus()
	await create_timer(0.15).timeout
	# Keep this isolated test window under the OS pointer while injecting events.
	# No product window flags, command results or simulation values are changed.
	dossier.transient = false
	dossier.always_on_top = true
	await process_frame
	await process_frame
	check(dossier.visible, "real dossier window opened")
	check(dossier.get("_doll").get_child_count() > 0, "paperdoll has private rendered viewport")
	var source: Control = dossier.get("_rows")["inventory:scrap"]
	var destination: Control = dossier.get("_lists")["cargo"].get_parent().get_parent().get_child(1)
	await drag(dossier, source.get_global_rect().get_center(), destination.get_global_rect().get_center())
	check(commands.size() == 1, "real mouse drag emits one command")
	if commands.size() == 1:
		check(commands[0].type == "transfer" and commands[0].payload == {"item":"scrap", "amount":1, "direction":"load"}, "drag keeps authoritative transfer contract")
	check(sim.snapshot() == before, "drag never mutates simulation or snapshot")
	var helmet: Control = dossier.get("_slots").helmet
	await drag(dossier, source.get_global_rect().get_center(), helmet.get_global_rect().get_center())
	check(commands.size() == 1, "incompatible slot rejects actual mouse drop")
	dossier.present_result({"ok":false,"reason":"Test: Schiffszugang zu weit entfernt."})
	check("Schiffszugang" in str(dossier.get("_feedback").text), "host rejection appears in dossier")
	dossier.present_result({"ok":true,"pending":true})
	check("Warte auf Host" in str(dossier.get("_feedback").text), "pending guest RPC never appears as confirmed success")
	check(sim.submit({"type":"assign_work", "unit_id":"ida", "recipe_id":"backpack", "request_id":"dossier-craft"}).ok, "real backpack recipe starts")
	for step: int in range(400): sim.advance(0.1)
	check(sim.snapshot().inventory.get("backpack", 0) == 1, "backpack crafted with actual materials and work time")
	var storage: Array = Catalog.landmarks("base").storage.duplicate()
	storage[0] += 6.0
	check(sim.submit({"type":"move", "unit_id":"ida", "position":storage, "request_id":"dossier-storage"}).ok, "walk to actual storage access")
	for step: int in range(300): sim.advance(0.1)
	dossier.present(sim.snapshot(), "ida")
	dossier.action_requested.connect(func(action: String, payload: Dictionary) -> void:
		var packet: Dictionary = payload.duplicate(true)
		packet.type = action
		packet.request_id = "dossier-drop-" + str(real_results.size())
		var result: Dictionary = sim.submit(packet)
		real_results.append(result)
		dossier.present_result(result)
		dossier.present(sim.snapshot(), "ida"))
	await process_frame
	if dossier.get("_rows").has("inventory:backpack"):
		var pack: Control = dossier.get("_rows")["inventory:backpack"]
		var pack_slot: Control = dossier.get("_slots").backpack
		await drag(dossier, pack.get_global_rect().get_center(), pack_slot.get_global_rect().get_center())
		check(sim.snapshot().crew.ida.equipment.get("backpack") == "backpack", "real mouse drop equips crafted backpack")
		check(sim.snapshot().crew.ida.backpack.capacity == 8 and sim.snapshot().inventory.backpack == 0, "equip atomically consumes item and enables eight slots")
		var backpack_drop: Control = dossier.get("_lists")["backpack"].get_parent().get_parent().get_child(1)
		source = dossier.get("_rows")["inventory:scrap"]
		dossier.get("_amount").value = 2
		await drag(dossier, source.get_global_rect().get_center(), backpack_drop.get_global_rect().get_center())
		check(sim.snapshot().crew.ida.backpack.items.scrap == 2, "actual mouse drop transfers selected quantity into backpack")
		var inventory_drop: Control = dossier.get("_lists")["inventory"].get_parent().get_parent().get_child(1)
		await drag(dossier, pack_slot.get_global_rect().get_center(), inventory_drop.get_global_rect().get_center())
		check(not real_results.is_empty() and not real_results.back().ok and sim.snapshot().crew.ida.backpack.capacity == 8, "host rejects removal of filled backpack without item loss")
		if not dossier.get("_rows").has("backpack:scrap"):
			quit(1)
			return
		var carried: Control = dossier.get("_rows")["backpack:scrap"]
		await drag(dossier, carried.get_global_rect().get_center(), inventory_drop.get_global_rect().get_center())
		check(sim.snapshot().crew.ida.backpack.items.scrap == 0 and sim.snapshot().inventory.scrap == 6, "actual mouse drop returns full quantity to inventory")
		await drag(dossier, pack_slot.get_global_rect().get_center(), inventory_drop.get_global_rect().get_center())
		check(sim.snapshot().crew.ida.backpack.capacity == 0 and sim.snapshot().inventory.backpack == 1, "empty backpack can be unequipped by real drag")
		pack = dossier.get("_rows")["inventory:backpack"]
		await drag(dossier, pack.get_global_rect().get_center(), pack_slot.get_global_rect().get_center())
		check(sim.snapshot().crew.ida.backpack.capacity == 8 and sim.snapshot().inventory.backpack == 0, "backpack re-equip conserves item")
	if DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		var destination_path: String = "res://output/n4-crew-dossier.png"
		dossier.get_texture().get_image().save_png(destination_path)
	dossier.always_on_top = false
	dossier.close()
	check(not dossier.visible, "close hides reusable dossier")
	print("DOSSIER_WINDOW checks=", checks, " failed=", failed)
	quit(0 if failed == 0 else 1)
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
