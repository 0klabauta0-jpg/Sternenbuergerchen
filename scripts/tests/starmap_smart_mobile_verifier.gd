extends SceneTree
## Real Campaign/Travel rules plus viewport-only interaction. No OS input.
const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const CAMPAIGN = preload("res://scripts/core/singleplayer_campaign_state.gd")
const TRAVEL = preload("res://scripts/core/singleplayer_space_travel_state.gd")
const COMMAND = preload("res://scripts/mission/singleplayer_campaign_command_contract.gd")
const ADAPTER = preload("res://scripts/meta/singleplayer_runtime_adapter.gd")
const STAR = preload("res://scripts/ui/star_map_screen.gd")
const BOARD = preload("res://scripts/meta/singleplayer_job_board_presenter.gd")
const DISPLAY = preload("res://scripts/mission/campaign_display_catalog.gd")
const APP_THEME = preload("res://scripts/ui/smart_mobile_theme.gd")
var passed := 0
var failed := 0
var sequence := 0
var owner: RefCounted
var travel: RefCounted
var calls: Array = []
var reject_next := false
var view: Control
var board: Control

class Operations extends Control:
	var provider: Callable
	var commands: Callable
	func get_operations_snapshot() -> Dictionary: return {"singleplayer":provider.call()}
	func request_operation(operation: String, payload: Dictionary) -> Dictionary: return commands.call(operation,payload)

class HomeContext extends Node:
	var _active_mission: Node
	var _pending_mission_craft_transfers: Array = []
	var _aircraft_location_by_craft: Dictionary = {"ship":"homebase"}

func _init() -> void:
	if GUARD.require_isolated_user_data(): call_deferred("run")

func check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failed += 1
	print(("PASS " if value else "FAIL ") + label)

func command(operation: String, payload: Dictionary, context: Dictionary = {}) -> Dictionary:
	sequence += 1
	return owner.apply_command(COMMAND.build_command(operation,payload,"mobile-test:%d" % sequence),context)

func snapshot() -> Dictionary:
	var campaign: Dictionary = owner.get_campaign_snapshot()
	campaign["job_availability"] = owner.get_job_availability(true)
	var places := {}
	for id: String in campaign.locations: places[id] = owner.validate_location_visit(id,true)
	campaign["location_availability"] = places
	return {"mode":"campaign", "campaign":campaign, "space_travel":travel.get_snapshot()}

func request(operation: String, payload: Dictionary = {}) -> Dictionary:
	calls.append({"operation":operation, "payload":payload.duplicate(true)})
	if reject_next:
		reject_next = false
		return {"ok":false,"reason":"pad_busy","message":"Kein freies Landepad"}
	if operation == "select_destination":
		var allowed: Dictionary = owner.validate_location_visit(String(payload.location_id),true)
		if not allowed.ok: return allowed
		return command(operation,payload)
	if operation == "accept_job": return command(operation,payload)
	return {"ok":true}

func travel_command(operation: String, payload: Dictionary = {}) -> Dictionary:
	sequence += 1
	payload = payload.duplicate(true)
	payload["craft_id"] = "ship"
	return travel.apply_command({"contract_category":"singleplayer_space_travel", "operation":operation, "payload":payload, "request_id":"mobile-travel:%d" % sequence}, {"runtime_authorized":true})

func finish_job(id: String) -> void:
	var job: Dictionary = owner.get_campaign_snapshot().jobs[id]
	check(command("accept_job",{"job_id":id}).get("ok",false), "actual accept " + id)
	check(command("bind_departure",{"craft_id":"ship", "origin_location_id":"homebase", "destination_location_id":job.location_id, "landing_pad_id":"homebase_pad_01", "job_id":id},{"departure_authorized":true}).get("ok",false), "actual bind " + id)
	check(command("activate_job",{"craft_id":"ship", "job_id":id},{"departure_authorized":true}).get("ok",false), "actual activate " + id)
	if id == "benit_delivery": check(command("deliver_crate",{},{"runtime_authorized":true}).get("ok",false), "actual delivery proof")
	check(command("complete_job",{"craft_id":"ship", "job_id":id},{"runtime_evidence":{"scenario_id":job.scenario_id,"result":"victory","mission_scenario_runtime_gates":{"all_gates_complete":true,"completed_step_ids":job.required_step_ids}}}).get("ok",false), "actual completion " + id)
	if bool(job.home_upload): check(command("upload_job",{"job_id":id},{"at_home":true}).get("ok",false), "actual home upload " + id)

func frames(count: int = 4) -> void:
	for index in count: await process_frame

func click(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point; motion.global_position = point
	root.push_input(motion,true)
	await process_frame
	var event := InputEventMouseButton.new()
	event.position = point; event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT; event.pressed = true; event.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(event,true)
	event = event.duplicate(); event.pressed = false; event.button_mask = 0
	root.push_input(event,true)
	await frames()

func key(code: Key, pressed: bool = true) -> void:
	var event := InputEventKey.new()
	event.keycode = code; event.pressed = pressed
	root.push_input(event,true)
	await frames(2)

func tree_click(tree: Tree, item: TreeItem) -> void:
	tree.scroll_to_item(item)
	await frames()
	var area: Rect2 = tree.get_item_area_rect(item)
	await click(tree.global_position + Vector2(minf(area.position.x + 95, tree.size.x - 15), area.get_center().y))

func tree_inspect_button(tree: Tree, item: TreeItem, button_id: int = 0) -> bool:
	var result: Dictionary = await preload("res://scripts/tests/viewport_tree_button_input.gd").click(tree,item,button_id)
	print("TREE_NATIVE_BUTTON ",result)
	return bool(result.ok)

func run() -> void:
	check(FileAccess.file_exists("user://review2_isolation_canary.json"), "actual isolated profile canary")
	owner = CAMPAIGN.new(); travel = TRAVEL.new()
	check(owner.configure().ok and travel.configure("ship").ok, "actual owners configure")
	var catalog_hash := FileAccess.get_sha256("res://data/singleplayer/star_system.json")
	var locations_hash := FileAccess.get_sha256("res://data/singleplayer/locations.json")
	var original: Dictionary = owner.export_state()
	var travel_before_names: Dictionary = travel.get_snapshot()
	check(DISPLAY.SYSTEM_NAME == "Börner" and DISPLAY.body_name("sun",travel_before_names.bodies.sun) == "Börner", "actual system and solar owner project Börner")
	check(DISPLAY.body_name("sun",{"name":"Glut"}) == "Börner" and DISPLAY.body_name("sun",{"name":"Eigenes System"}) == "Eigenes System" and travel.get_snapshot() == travel_before_names, "old standard solar label aliases Börner without changing authored content or travel owners")
	var available: Dictionary = owner.get_job_availability(true)
	check(available.satellite_recovery.can_accept and available.satellite_recovery.visible, "initial job is genuinely available")
	for id in ["outpost_recovery","benit_delivery","outpost_chip_recovery","buccaneer_rescue"]:
		check(not available[id].visible and not command("accept_job",{"job_id":id}).ok, "future job hidden and owner rejects " + id)
	check(owner.export_state() == original, "availability and rejected commands leave persisted owner unchanged")
	finish_job("satellite_recovery")
	check(owner.get_job_availability().satellite_recovery.visible and not owner.get_job_availability().satellite_recovery.can_accept and owner.validate_location_visit("satellite_crash").ok, "completed briefing remains readable and its location stays open")
	var restore := CAMPAIGN.new()
	check(restore.configure().ok and restore.restore_state(owner.export_state()).ok and restore.get_campaign_snapshot() == owner.get_campaign_snapshot(), "current campaign roundtrip contains unchanged owner definitions")
	# Reuse the authentic historical Home definitions, not a fabricated fingerprint.
	var legacy: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/qa/review_completion_20261113/legacy_source_pair/checkpoint_v1.json"))
	var legacy_payload: Dictionary = legacy.get("payload",legacy)
	if legacy_payload.has("campaign"):
		check(restore.restore_state(legacy_payload.campaign).ok, "actual historical campaign definitions still restore")
	else: check(false, "historical Home fixture contains campaign owner")
	var host := Operations.new()
	host.provider = snapshot; host.commands = request
	root.add_child(host)
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board = BOARD.new(); host.add_child(board)
	board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board.configure(host); board.refresh()
	board.get("_card_buttons").satellite_recovery.pressed.emit()
	for dimensions: Vector2i in [Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size = dimensions; root.content_scale_size = dimensions
		await frames(6)
		check(board.get("_picture").texture != null and board.get("_picture").size.y >= 120 and board.get("_picture").size.y <= 150, "color panorama remains a compact readable strip " + str(dimensions))
		check(root.get_visible_rect().encloses(board.get("_footer").get_global_rect()) and board.get("_footer").get_global_rect().encloses(board.get("_show_map").get_global_rect()), "footer and action remain reachable " + str(dimensions))
	check(board.get("_accept").disabled and not board.get("_show_map").disabled, "completed card exposes a visit, not acceptance")
	var receipts: Dictionary = owner.get_campaign_snapshot().completion_receipts.duplicate(true)
	await click(board.get("_show_map").get_global_rect().get_center())
	check(owner.get_campaign_snapshot().selected_job_id == "" and owner.get_campaign_snapshot().selected_location_id == "satellite_crash" and owner.get_campaign_snapshot().completion_receipts == receipts, "actual completed-card click selects empty-job visit without a reward")
	var board_ids: Array = board.get("_card_buttons").values().map(func(button: Button): return button.get_instance_id())
	var rebuilds: int = board.get("_job_list_rebuilds")
	for index in 120: board.refresh()
	check(rebuilds == board.get("_job_list_rebuilds") and board_ids == board.get("_card_buttons").values().map(func(button: Button): return button.get_instance_id()), "120 unchanged job refreshes preserve controls and resources")
	board.get("_card_buttons").outpost_recovery.grab_focus()
	check(command("accept_job",{"job_id":"outpost_recovery"}).ok, "actual status change for list focus")
	board.refresh()
	await frames()
	check(root.gui_get_focus_owner() == board.get("_card_buttons").outpost_recovery, "job-list status rebuild retains actual keyboard focus")
	board.hide()
	view = STAR.new(); host.add_child(view)
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.configure(snapshot,request)
	view.set_process(false)
	await frames()
	var tree: Tree = view.get("_navigation")
	var items: Dictionary = tree.get("_items")
	check(items["body:sun"].get_text(0) == "Börner  /  SYSTEM" and view.find_child("SystemCaption",true,false).text == "SYSTEM: Börner", "actual tree and heading display the same corrected system name")
	check(items.has("body:glut_2") and items.has("body:polisa") and items["body:polisa"].get_parent() == items["body:glut_2"], "Eidolon and its real station remain in the tree")
	check(items["body:glut_1a"].get_parent() == items["body:planet"] and items["location:satellite_crash"].get_parent() == items["body:glut_1a"], "actual moon and location hierarchy matches route owners")
	check(items.has("location:fortified_outpost") and items.has("location:distress_orbit") and not items["location:fortified_outpost"].get_metadata(0).can_select_destination and not board.get("_card_buttons").has("outpost_chip_recovery"), "all places are inspectable while future mission offers and routes remain unavailable")
	check(items["body:glut_1a"].get_text(0) == "Neralis" and items["location:satellite_crash"].get_text(0) == "Aschental" and items["body:glut_2"].get_text(0) == "Eidolon", "stable ID names agree in actual tree")
	check(items["location:satellite_crash"].get_tooltip_text(0).begins_with("Aschental ·"), "actual destination tooltip uses the same projected name")
	var expected_marker_count := 0
	var preserved_orbits: Dictionary = travel.get_snapshot().orbits.duplicate(true)
	for orbit_id: String in travel.get_snapshot().orbits:
		var orbit: Dictionary = travel.get_snapshot().orbits[orbit_id]
		var body_item: TreeItem = items["body:" + String(orbit.body_id)]
		check(body_item.get_button_count(0) == 1 and body_item.get_button(0,0).resource_path.ends_with("orbit_map.svg"), orbit_id + " has exactly one OM button beside its body")
		expected_marker_count += 1
	check(int(view.get_ui_snapshot().orbit_marker_count) == expected_marker_count and view.find_child("OrbitTargets",true,false) == null, "tree owns one orbit-map button per body without a second control list")
	check(int(view.get("_canvas").get_camera_snapshot().orbit_marker_count) == expected_marker_count and view.get("_canvas").get("_orbits") == preserved_orbits and travel.get_snapshot().orbits == preserved_orbits, "canvas shows one OM per body while preserving every owner travel alias")
	# Fuel preview values may exist for every catalog route; the displayed list
	# must retain exactly the owner-approved travel filter, not inspection places.
	var fuel_projection: Dictionary = snapshot()
	fuel_projection.space_travel.fuel_reachability = {"satellite_crash":{"ok":true},"trade_outpost":{"ok":false,"message":"Zu wenig Treibstoff"},"fortified_outpost":{"ok":true},"distress_orbit":{"ok":true}}
	view.refresh(fuel_projection)
	var fuel_text: String = view.get("_fuel_help").text
	check(fuel_text.contains("Aschental") and fuel_text.contains("Kestrel · Zu wenig Treibstoff") and not fuel_text.contains("Bastion Silex") and not fuel_text.contains("Fernwacht"), "fuel display retains real visible locations and exact supply outcome without revealing future jobs")
	view.refresh()
	for dimensions: Vector2i in [Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size = dimensions; root.content_scale_size = dimensions
		await frames(6)
		check(root.get_visible_rect().encloses(tree.get_global_rect()) and root.get_visible_rect().encloses(view.get("_canvas").get_global_rect()) and root.get_visible_rect().encloses(view.get("_details").get_global_rect()), "all three map columns fit " + str(dimensions))
		var before_inspection: Array = [owner.export_state(), travel.get_snapshot()]
		var inspection_count := calls.size()
		check(await tree_inspect_button(tree,items["body:glut_1a"]), "actual adjacent orbit marker button is reachable " + str(dimensions))
		print("TREE_INSPECTION orbit=", calls.slice(inspection_count), " selected=", tree.get_selected().get_metadata(0) if tree.get_selected() != null else {})
		check(calls.size() == inspection_count + 1 and calls.back() == {"operation":"inspect_orbit", "payload":{"body_id":"glut_1a", "orbit_id":"glut_1a_orbit"}}, "body OM button issues only its shared view intent " + str(dimensions))
		inspection_count = calls.size()
		check(await tree_inspect_button(tree,items["location:satellite_crash"]), "available location also has a reachable independent view button " + str(dimensions))
		print("TREE_INSPECTION available=", calls.slice(inspection_count))
		check(calls.size() == inspection_count + 1 and calls.back() == {"operation":"inspect_location", "payload":{"location_id":"satellite_crash"}}, "available location inspection also bypasses route selection " + str(dimensions))
		inspection_count = calls.size()
		check(await tree_inspect_button(tree,items["location:fortified_outpost"]), "unavailable mission location still has a reachable inspection button " + str(dimensions))
		print("TREE_INSPECTION unavailable=", calls.slice(inspection_count), " selected=", tree.get_selected().get_metadata(0) if tree.get_selected() != null else {})
		check(calls.size() == inspection_count + 1 and calls.back() == {"operation":"inspect_location", "payload":{"location_id":"fortified_outpost"}}, "unknown location view never selects a route or mission " + str(dimensions))
		await tree_click(tree,items["location:fortified_outpost"])
		check(calls.size() == inspection_count + 1 and tree.get_selected() == items["location:fortified_outpost"], "locked row focuses for keyboard inspection without a destination command " + str(dimensions))
		tree.grab_focus(); await key(KEY_ENTER); await key(KEY_ENTER,false)
		check(calls.size() == inspection_count + 2 and calls.back().operation == "inspect_location" and before_inspection == [owner.export_state(), travel.get_snapshot()], "Enter inspects and all view actions preserve actual campaign and travel owners " + str(dimensions))
		var count := calls.size()
		await tree_click(tree,items["body:glut_1a"])
		check(calls.size() == count and tree.get_selected() == items["body:glut_1a"] and not items["body:glut_1a"].collapsed, "body click focuses and expands without a flight " + str(dimensions))
		tree.grab_focus()
		await key(KEY_ENTER); await key(KEY_ENTER,false)
		check(calls.size() == count + 1 and calls.back() == {"operation":"inspect_orbit", "payload":{"body_id":"glut_1a", "orbit_id":"glut_1a_orbit"}} and before_inspection == [owner.export_state(), travel.get_snapshot()], "body Enter opens the same single OM without owner mutation " + str(dimensions))
		await key(KEY_LEFT); await key(KEY_LEFT,false)
		check(items["body:glut_1a"].collapsed, "keyboard collapses body " + str(dimensions))
		await key(KEY_RIGHT); await key(KEY_RIGHT,false)
		check(not items["body:glut_1a"].collapsed, "keyboard expands body " + str(dimensions))
		await tree_click(tree,items["location:trade_outpost"])
		check(owner.get_campaign_snapshot().selected_location_id == "trade_outpost" and calls.back().operation == "select_destination", "tree selects through real campaign command " + str(dimensions))
		view.get("_canvas").location_selected.emit("satellite_crash")
		check(tree.get_selected().get_metadata(0).id == "satellite_crash" and owner.get_campaign_snapshot().selected_location_id == "satellite_crash", "map location feeds the same selected tree item " + str(dimensions))
		var toggle: Button = view.get("_fuel_toggle")
		toggle.grab_focus(); await key(KEY_SPACE); await key(KEY_SPACE,false)
		check(toggle.button_pressed and view.get("_fuel_help").visible, "keyboard activates visible fuel toggle " + str(dimensions))
		await key(KEY_SPACE); await key(KEY_SPACE,false)
		await key(KEY_ALT)
		check(not toggle.button_pressed and view.get("_fuel_help").visible, "Alt preserves temporary fuel access " + str(dimensions))
		await key(KEY_ALT,false)
		check(not view.get("_fuel_help").visible, "Alt release restores unpinned state " + str(dimensions))
	view.get("_canvas").reset_camera()
	await frames()
	items["body:sun"].collapsed = true
	var body_calls := calls.size()
	var canvas: Control = view.get("_canvas")
	var eidolon: Vector2 = canvas.map_to_screen(Vector2(travel.get_snapshot().bodies.glut_2.position[0],travel.get_snapshot().bodies.glut_2.position[1]))
	await click(canvas.global_position + eidolon)
	check(calls.size() == body_calls and not items["body:sun"].collapsed and tree.get_selected() == items["body:glut_2"], "actual native body click synchronizes and reveals tree focus without travel")
	items["body:planet"].collapsed = true
	view.get("_canvas").body_selected.emit("glut_1a")
	check(not items["body:planet"].collapsed and tree.get_selected() == items["body:glut_1a"], "map body selection opens all hidden tree ancestors")
	items["body:glut_1b"].collapsed = true
	var tree_rebuilds: int = tree.get("rebuild_count")
	var saved_item: TreeItem = items["location:satellite_crash"]
	var before_ui: Dictionary = owner.export_state()
	for index in 120: view.refresh()
	check(tree_rebuilds == tree.get("rebuild_count") and saved_item == tree.get("_items")["location:satellite_crash"] and items["body:glut_1b"].collapsed, "120 unchanged map refreshes preserve topology, collapse and selection")
	check(before_ui == owner.export_state() and APP_THEME.get_theme() == view.theme and APP_THEME.box() == APP_THEME.box(), "UI reads preserve owners and reuse cached theme resources")
	# Preserve the former star-map safety cases against actual current travel.
	check(travel_command("launch_to_orbit").ok and travel_command("start_quantum",{"target_orbit_id":"glut_1a_orbit"}).ok, "real travel owner launches and begins a jump")
	view.refresh()
	check(not bool(tree.get("_items")["location:satellite_crash"].get_metadata(0).can_select_destination) and view.get("_abort").visible, "jump exposes abort and blocks location selection")
	check(travel_command("abort_quantum").ok, "actual aborted jump")
	view.refresh()
	check(not bool(tree.get("_items")["location:satellite_crash"].get_metadata(0).can_select_destination), "stopped ship cannot bypass destination orbit")
	check(travel_command("start_quantum",{"target_orbit_id":"glut_1a_orbit"}).ok, "same target can resume after abort")
	for index in 40: travel_command("advance",{"delta_seconds":1.0})
	view.refresh()
	check(travel.get_snapshot().phase == "orbit" and bool(tree.get("_items")["location:satellite_crash"].get_metadata(0).can_select_destination), "arrival enables only the matching orbit's destination")
	await tree_click(tree,tree.get("_items")["location:satellite_crash"])
	check(view.get("_approach").visible and not view.get("_approach").disabled and view.get_ui_snapshot().load_boundary.contains("Ortskarte"), "selected reachable site exposes explicit approach and map-loading boundary")
	var commands_before := calls.size()
	reject_next = true
	view.get("_approach").pressed.emit()
	check(calls.size() == commands_before + 1 and calls.back().operation == "space_begin_approach" and calls.back().payload.location_id == "satellite_crash", "only explicit approach issues the load command")
	check(view.get_ui_snapshot().error.contains("Landepad"), "actual command rejection is visible")
	view.refresh()
	check(view.get_ui_snapshot().error.contains("Landepad"), "unchanged refresh preserves actionable rejection")
	check(travel_command("begin_approach",{"location_id":"satellite_crash"}).ok, "actual owner starts map handoff")
	view.refresh()
	check(not bool(tree.get("_items")["location:satellite_crash"].get_metadata(0).can_select_destination) and view.get_ui_snapshot().error.is_empty() and view.get_ui_snapshot().status.contains("geladen"), "map handoff locks selection, clears stale rejection and explains loading")
	# The same retained map supports an embedded narrow workspace via its visible
	# tree switch, instead of squeezing three columns outside the panel.
	view.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	view.size = Vector2(800,650)
	await frames(6)
	check(view.get("_navigation_toggle").visible and not tree.visible and view.get("_canvas").is_visible_in_tree(), "embedded 800px map keeps a usable canvas and explicit tree switch")
	await click(view.get("_navigation_toggle").get_global_rect().get_center())
	check(tree.is_visible_in_tree() and not view.get("_canvas").is_visible_in_tree() and view.get_global_rect().encloses(tree.get_global_rect()), "embedded tree remains fully reachable without duplicate destination controls")
	var custom_locations: Dictionary = owner.get_campaign_snapshot().locations.duplicate(true)
	custom_locations["future_region"] = custom_locations.satellite_crash.duplicate(true)
	custom_locations.future_region.merge({"id":"future_region","name":"Eigener Ort","free_visit":true},true)
	var custom_owner := CAMPAIGN.new()
	check(custom_owner.configure(custom_locations,{},false).ok, "actual custom/skirmish catalog configures")
	# Changing topology while retaining the same owner selection must preserve
	# local body focus. A genuinely changed owner selection must instead win.
	check(custom_owner.apply_command(COMMAND.build_command("select_destination", {"location_id":owner.get_campaign_snapshot().selected_location_id,"job_id":""},"custom-selection")).ok, "custom topology retains the same actual selected destination")
	var custom_projection: Dictionary = snapshot()
	custom_projection.mode = "skirmish"
	var custom_travel := TRAVEL.new()
	check(custom_travel.configure("ship").ok, "actual custom travel starts grounded for destination selection")
	custom_projection.space_travel = custom_travel.get_snapshot()
	custom_projection.campaign = custom_owner.get_campaign_snapshot()
	custom_projection.campaign["job_availability"] = custom_owner.get_job_availability(true)
	custom_projection.campaign["location_availability"] = {}
	for id: String in custom_locations: custom_projection.campaign.location_availability[id] = custom_owner.validate_location_visit(id,true)
	tree.focus_body("glut_2")
	tree.get("_items")["body:planet"].collapsed = true
	view.refresh(custom_projection)
	check(tree.get_selected().get_metadata(0).id == "glut_2" and tree.get("_items")["body:planet"].collapsed, "actual topology changes preserve local body focus and collapsed branches")
	check(tree.get("_items").has("location:future_region") and tree.get("_items")["location:future_region"].get_text(0) == "Eigener Ort" and view.get("_canvas").get("_location_buttons").has("future_region"), "new authored free destination appears in real tree and native marker without a hardcoded button")
	check(custom_owner.apply_command(COMMAND.build_command("select_destination", {"location_id":"homebase","job_id":""},"custom-new-selection")).ok, "actual owner changes selected destination after local body focus")
	custom_projection.campaign.selected_location_id = custom_owner.get_campaign_snapshot().selected_location_id
	view.refresh(custom_projection)
	check(tree.get_selected().get_metadata(0).id == "homebase" and not tree.get("_items")["body:planet"].collapsed, "new owner selection supersedes local focus and reveals its ancestors")
	check(custom_owner.get_job_availability(true).values().all(func(entry: Dictionary): return bool(entry.visible)), "skirmish keeps its actual unsequenced jobs available")
	host.free()
	finish_job("outpost_recovery")
	check(owner.get_job_availability(true).benit_delivery.visible and owner.get_job_availability(true).benit_delivery.shown_as_locked and owner.get_job_availability(true).benit_delivery.reason == "outpost_preparation_required" and not command("accept_job",{"job_id":"benit_delivery"}).ok, "Benit is listed as locked with its reason after predecessor, and stays unacceptable until actual recruit and crate")
	check(command("claim_recruit",{"kind":"outpost"},{"runtime_authorized":true}).ok, "actual outpost recruit")
	check(owner.get_job_availability(true).benit_delivery.shown_as_locked and not owner.get_job_availability(true).benit_delivery.can_accept, "recruit alone does not unlock Benit")
	check(command("load_crate",{},{"runtime_authorized":true}).ok and owner.get_job_availability(true).benit_delivery.can_accept, "actual cargo and recruit unlock Benit together")
	finish_job("benit_delivery"); finish_job("outpost_chip_recovery"); finish_job("buccaneer_rescue")
	for id: String in owner.get_campaign_snapshot().jobs:
		check(owner.get_job_availability().get(id).visible and not owner.get_job_availability().get(id).can_accept and not command("accept_job",{"job_id":id}).ok, "completed job remains readable without repeat payout " + id)
	var failed_owner := CAMPAIGN.new(); failed_owner.configure()
	owner = failed_owner
	check(command("accept_job",{"job_id":"satellite_recovery"}).ok and command("fail_job",{"job_id":"satellite_recovery"},{"mission_aborted":true}).ok, "real failed-job owner fixture")
	check(not owner.get_job_availability(false).satellite_recovery.visible and owner.get_job_availability(true).satellite_recovery.can_accept, "failed retry is visible only with actual Home permission")
	check(owner.validate_location_visit("satellite_crash",true).ok and not owner.validate_location_visit("satellite_crash",false).ok, "failed location and job share the same Home-versus-away permission")
	var away_snapshot: Dictionary = snapshot()
	away_snapshot.campaign.job_availability = owner.get_job_availability(false)
	var away_host := Operations.new()
	away_host.provider = func(): return away_snapshot
	away_host.commands = request
	root.add_child(away_host)
	var away_board := BOARD.new()
	away_host.add_child(away_board); away_board.configure(away_host); away_board.refresh()
	check(away_board.get("_visible_job_ids").is_empty() and away_board.get("_empty").visible and away_board.get("_empty").text.contains("Basis") and not away_board.get("_footer").visible, "actual empty failed-away list explains its owner gate without a false acceptance action")
	away_host.free()
	var context := HomeContext.new()
	var adapter := ADAPTER.new()
	adapter.set("_flow",context)
	check(adapter._retry_failed_home_gate().ok, "actual adapter Home gate permits a grounded retry")
	context._aircraft_location_by_craft.ship = "mission"
	check(not adapter._retry_failed_home_gate().ok, "actual adapter blocks retry with an away ship")
	context._aircraft_location_by_craft.ship = "homebase"; context._pending_mission_craft_transfers.append({"craft_id":"ship"})
	check(not adapter._retry_failed_home_gate().ok, "actual adapter blocks retry during transit")
	context._pending_mission_craft_transfers.clear(); context._active_mission = Node.new()
	check(not adapter._retry_failed_home_gate().ok, "actual adapter blocks retry with a live mission")
	context._active_mission.free(); context.free(); adapter.free()
	check(catalog_hash == FileAccess.get_sha256("res://data/singleplayer/star_system.json") and locations_hash == FileAccess.get_sha256("res://data/singleplayer/locations.json"), "all reads and UI actions leave fingerprint-bearing catalog bytes unchanged")
	check(DISPLAY.body_name("custom",{"name":"Eigener Mond"}) == "Eigener Mond" and DISPLAY.location_name("custom",{"name":"Eigener Ort"}) == "Eigener Ort", "custom content keeps authored display names")
	print("STARMAP_SMART_MOBILE passed=%d failed=%d" % [passed,failed])
	print("STAR_MAP_UI checks=%d failed=%d" % [passed + failed,failed])
	print("Campaign star map: %d checks, %d failures" % [passed + failed,failed])
	quit(1 if failed else 0)
