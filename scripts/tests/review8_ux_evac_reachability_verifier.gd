extends SceneTree

const MISSION := preload("res://scenes/tests/mission_reactivity_test.tscn")
const BASE := "TacticalUI/BottomDock/BottomMargin/BottomRow/"
const ORIGINAL := BASE + "StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/MissionEvacuationButton"
const POPUP := "TacticalUI/A5TeamDetailsPopup"
const PROXY := POPUP + "/Margin/Box/A5EvacuationButton"
var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for size in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		await _check_mission(size)
	print("REVIEW8_UX_EVAC: %d passed, %d failed" % [_passed, _failed])
	if _failed == 0:
		print("PASS: review8 UX evacuation reachability")
	quit(0 if _failed == 0 else 1)


func _check_mission(size: Vector2i) -> void:
	root.content_scale_size = Vector2i.ZERO
	root.size = size
	var scene := MISSION.instantiate()
	# Configure an existing ground-start fixture before ready. No actor position,
	# HP, transport phase, timer or runtime eligibility is patched by this test.
	scene.get_node("MissionSetup").set("defer_friendly_runtime_activation", false)
	root.add_child(scene)
	await _frames(16)
	var controller := scene.get_node("TacticalController")
	var combat := scene.get_node("CombatLoopDriver")
	var prefix := "%s: " % size
	var ids := PackedStringArray(controller.call("_get_available_fireteam_ids"))
	_check(not ids.is_empty(), prefix + "ground-start fixture exposes an existing fireteam")
	if ids.is_empty():
		await _cleanup(scene)
		return
	controller.call("_on_fireteam_group_pressed", ids[0])
	controller.call("_update_ui")
	var anchor := controller.call("_get_selection_anchor_for_fireteam", ids[0]) as Node2D
	_check(anchor != null, prefix + "selection has a real ground fireteam anchor")
	if anchor == null:
		await _cleanup(scene)
		return
	var details := scene.get_node(BASE + "FireteamPanel/A5DetailsButton") as Button
	_check(details.is_visible_in_tree() and details.tooltip_text.to_lower().contains("evaku"), prefix + "visible Details affordance names the evacuation action")
	await _click(details)
	var popup := scene.get_node(POPUP) as PopupPanel
	_check(popup.visible, prefix + "real mouse activation opens the native Details window")
	var original := scene.get_node_or_null(ORIGINAL) as Button
	var proxy := scene.get_node_or_null(PROXY) as Button
	_check(original != null and not original.is_visible_in_tree(), prefix + "original command remains in its preserved hidden source path")
	_check(proxy != null, prefix + "details contain a real native evacuation action")
	if proxy == null or original == null:
		await _cleanup(scene)
		return
	var calls := {"count": 0, "proxy": 0, "mouse_events": 0}
	original.pressed.connect(func() -> void: calls.count += 1)
	proxy.pressed.connect(func() -> void: calls.proxy += 1)
	proxy.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			calls.mouse_events += 1
			print("REVIEW8_EVAC_GUI pressed=%s local=%s disabled=%s" % [event.pressed, event.position, proxy.disabled])
	)
	_check(proxy.is_visible_in_tree() and proxy.disabled and original.disabled, prefix + "missing LZ keeps the reachable action disabled")
	_check(proxy.tooltip_text == original.tooltip_text, prefix + "disabled action preserves the authoritative source explanation")
	proxy.pressed.emit()
	_check(calls.count == 0 and Dictionary(combat.call("get_mission_result")).is_empty(), prefix + "forced activation cannot bypass the missing-LZ gate")
	var primary := scene.get_node("Primary3DView")
	var far_screen: Vector2 = primary.call("world_to_screen_position", anchor.global_position + Vector2(256.0, 0.0))
	_check(bool(controller.call("_place_lz_from_screen_position", far_screen)), prefix + "regular LZ input accepts a valid remote map position")
	controller.call("_update_ui")
	await _frames(2)
	_check(proxy.disabled and original.disabled and proxy.tooltip_text == original.tooltip_text, prefix + "outside-LZ state remains disabled with the same regroup requirement")
	var near_screen: Vector2 = primary.call("world_to_screen_position", anchor.global_position)
	_check(bool(controller.call("_place_lz_from_screen_position", near_screen)), prefix + "regular LZ input places the zone at the unchanged ground team")
	controller.call("_update_ui")
	await _frames(3)
	_check(bool(Dictionary(controller.call("get_mission_evacuation_snapshot")).get("eligible", false)), prefix + "existing owner confirms evacuation eligibility")
	_check(proxy.is_visible_in_tree() and not proxy.disabled and not original.disabled, prefix + "eligible host can reach the enabled native action")
	_check(_fully_reachable(proxy, popup), prefix + "whole button rect fits viewport and every clipping ancestor")
	combat.set("_runs_local_authority", false)
	controller.call("_update_ui", false, false)
	_check(proxy.disabled and original.disabled, prefix + "authority loss disables the same action")
	proxy.pressed.emit()
	_check(calls.count == 0 and Dictionary(combat.call("get_mission_result")).is_empty(), prefix + "forced client activation cannot emit the original command")
	combat.set("_runs_local_authority", true)
	controller.call("_update_ui", false, false)
	_check(not proxy.disabled, prefix + "restored host reads the valid original state")
	await _capture_evacuation(proxy, popup, original, size)
	var proxy_before: int = calls.proxy
	await _click(proxy)
	var result: Dictionary = combat.call("get_mission_result")
	print("REVIEW8_EVAC_CLICK_RESULT proxy=%d before=%d source=%d gui_mouse_events=%d result=%s" % [calls.proxy, proxy_before, calls.count, calls.mouse_events, result])
	_check(calls.proxy == proxy_before + 1 and calls.mouse_events >= 2, prefix + "real mouse down/up reaches and activates the native evacuation control once")
	_check(calls.count == 1 and result.get("result") == "aborted" and result.get("win_condition_type") == "evacuation", prefix + "real native action invokes the original callback once and resolves the existing abort result")
	await _cleanup(scene)


func _fully_reachable(control: Control, popup: PopupPanel) -> bool:
	var actual := control.get_global_rect()
	var root_bounds := Rect2(Vector2.ZERO if popup.is_embedded() else Vector2(root.position), Vector2(root.size))
	var popup_bounds := Rect2(Vector2(popup.position), Vector2(popup.size))
	print("REVIEW8_EVAC_GEOMETRY root=%s popup=%s button=%s embedded=%s" % [root_bounds, popup_bounds, actual, popup.is_embedded()])
	if not root_bounds.encloses(popup_bounds):
		return false
	if not Rect2(Vector2.ZERO, Vector2(popup.size)).encloses(actual):
		return false
	var ancestor := control.get_parent()
	while ancestor != null and ancestor != popup:
		if ancestor is Control and (not ancestor.is_visible_in_tree() or (ancestor.clip_contents and not ancestor.get_global_rect().encloses(actual))):
			return false
		ancestor = ancestor.get_parent()
	return true


func _capture_evacuation(action: Button, popup: PopupPanel, source: Button, size: Vector2i) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var directory := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--ux-output="):
			directory = argument.trim_prefix("--ux-output=").strip_edges()
	if directory.is_empty():
		return
	_check(DirAccess.make_dir_recursive_absolute(directory) == OK, "native evacuation capture directory is available")
	await RenderingServer.frame_post_draw
	var stem := "review8_ux_evac_%dx%d" % [size.x, size.y]
	var path := directory.path_join(stem + ".png")
	_check(root.get_texture().get_image().save_png(path) == OK, "native root viewport evacuation PNG is saved")
	var rect := action.get_global_rect()
	var metadata := {"schema": "sternenbuergerchen.review8_ux_capture.v1", "capture": path, "display_server": DisplayServer.get_name(), "viewport": [size.x, size.y], "fixture_type": "ground_start_native_ui_contract", "physical_gameplay_proof": false, "popup_rect": [popup.position.x, popup.position.y, popup.size.x, popup.size.y], "button_rect_in_popup": [rect.position.x, rect.position.y, rect.size.x, rect.size.y], "button_visible": action.is_visible_in_tree(), "button_disabled": action.disabled, "source_disabled": source.disabled, "source_tooltip": source.tooltip_text}
	var file := FileAccess.open(directory.path_join(stem + ".json"), FileAccess.WRITE)
	_check(file != null, "native evacuation capture metadata is writable")
	if file != null:
		file.store_string(JSON.stringify(metadata, "  ") + "\n")
	print("REVIEW8_UX_CAPTURE ", path)


func _click(control: Control) -> void:
	var viewport := control.get_viewport()
	var point := control.get_global_rect().get_center()
	var local_point := point
	if viewport is Window and viewport.is_embedded():
		# Embedded Windows receive hover through their embedder. Sending only to
		# the child skips that mouse-over path; use the real parent-window route.
		point = Vector2(viewport.position) + viewport.get_final_transform() * point
		viewport = viewport.get_parent().get_viewport()
	viewport.notify_mouse_entered()
	print("REVIEW8_UX_MOUSE control=%s local=%s routed=%s viewport=%s" % [control.get_path(), local_point, point, viewport.get_path()])
	var motion := InputEventMouseMotion.new()
	motion.position = point
	viewport.push_input(motion, true)
	await _frames(1)
	var hovered := control.get_viewport().gui_get_hovered_control()
	print("REVIEW8_UX_MOUSE hovered=", hovered.get_path() if hovered != null else "none")
	var press := InputEventMouseButton.new()
	press.position = point
	press.button_index = MOUSE_BUTTON_LEFT
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	press.pressed = true
	viewport.push_input(press, true)
	var release := press.duplicate() as InputEventMouseButton
	release.pressed = false
	release.button_mask = 0
	viewport.push_input(release, true)
	await _frames(2)


func _cleanup(scene: Node) -> void:
	scene.queue_free()
	await _frames(2)


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _check(ok: bool, message: String) -> void:
	if ok:
		_passed += 1
		print("PASS: " + message)
	else:
		_failed += 1
		push_error("FAIL: " + message)
