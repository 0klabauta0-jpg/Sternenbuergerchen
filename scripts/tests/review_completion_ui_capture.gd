extends "res://scripts/tests/review_completion_graphics_capture.gd"
## Native product UI at 720p, driven only by private Viewport events and public
## view commands. No OS input, fabricated gameplay state or replacement panels.
const UI_GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const UI_HOME = preload("res://scripts/meta/campaign_checkpoint_store.gd")
var _ui_flow: Node

func run() -> void:
	if not UI_GUARD.require_isolated_user_data(): return
	output = OS.get_environment("SB_REVIEW_COMPLETION_CAPTURE_DIR")
	if output.is_empty() or DisplayServer.get_name() == "headless":
		printerr("Native UI capture requires the private native review runner and capture directory")
		quit(2); return
	if not _expect(FileAccess.file_exists("user://review2_isolation_canary.json"), "real private-profile autoload canary exists"):
		await _finish_ui(); return
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	manifest["scope"] = "Actual campaign UI; viewport-local pointer and Escape events; no OS input. Only the periodic Flow autosaver is frozen after real bootstrap. Simulation is not paused."
	START.request_start(self, "campaign", "new")
	_ui_flow = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(_ui_flow)
	current_scene = _ui_flow
	await frames(24)
	_ui_flow.set_process(false)
	var screen: Control = _ui_flow.get_node("HomebaseScreen")
	var presenter: Node = screen.get("_operations_presenter")
	var runtime: Node = _ui_flow.get("_singleplayer_runtime")
	if not _expect(_ui_flow.request_campaign_save().get("ok", false), "actual initial campaign checkpoint saved"):
		await _finish_ui(); return
	var saved_sha := FileAccess.get_sha256(UI_HOME.DEFAULT_PATH)
	var jobs: Button = presenter.get("_nav").get("jobs")
	if not await _click_ui(jobs, "actual Smart Mobile navigation"):
		await _finish_ui(); return
	await frames(20)
	var board: Control = presenter.get("_job_board")
	var card: Button = board.get("_card_buttons").get("satellite_recovery")
	if not bool(board.get("_details_expanded")) and not await _click_ui(card, "actual satellite briefing card"):
		await _finish_ui(); return
	await frames(8)
	var footer: PanelContainer = board.get("_footer")
	var accept: Button = board.get("_accept")
	var dock: Control = presenter.get("_base").get_node("BasePersonnelActions")
	var shell_style: StyleBoxFlat = board.get_theme_stylebox("panel")
	var footer_style: StyleBoxFlat = footer.get_theme_stylebox("panel")
	check(footer.is_visible_in_tree() and shell_style.bg_color.a == 1.0 and footer_style.bg_color.a == 1.0, "actual app shell and footer have fully opaque backgrounds")
	check(board.get_global_rect().encloses(footer.get_global_rect()) and footer.get_global_rect().encloses(accept.get_global_rect()) and footer.get_global_rect().end.y <= dock.get_global_rect().position.y - 8.0, "actual footer and action remain inside the app and above the base dock")
	await capture("ui_job_app_footer", {"job_id": "satellite_recovery", "shell_rgba": shell_style.bg_color.to_html(true), "footer_rgba": footer_style.bg_color.to_html(true), "app_rect": _ui_rect(board), "footer_rect": _ui_rect(footer), "accept_rect": _ui_rect(accept), "accept_text": accept.text, "accept_enabled": not accept.disabled})
	if not await _click_ui(accept, "actual accept-job button"):
		await _finish_ui(); return
	var snapshot: Dictionary = runtime.get_snapshot()
	if not _expect(snapshot.campaign.jobs.satellite_recovery.status == "accepted" and _ui_flow.get_campaign_save_projection().has_unsaved_progress, "real UI job acceptance creates unsaved campaign progress"):
		await _finish_ui(); return
	if not await _click_ui(presenter.get("_flyout_close"), "actual app close button"):
		await _finish_ui(); return
	check(_ui_flow.open_location_view("star_map").get("ok", false), "public view command opens actual campaign star map")
	await frames(8)
	var star: Control = _ui_flow.get("_star_map_screen")
	var toggle: Button = star.get("_fuel_toggle")
	var fuel: Label = star.get("_fuel_help")
	if not await _click_ui(toggle, "actual fuel and range toggle"):
		await _finish_ui(); return
	check(toggle.button_pressed and fuel.is_visible_in_tree() and fuel.text.contains("TREIBSTOFF"), "actual pointer click visibly pins fuel and range information")
	check(root.get_visible_rect().encloses(toggle.get_global_rect()) and root.get_visible_rect().encloses(fuel.get_global_rect()), "visible toggle and fuel information fit the native 720p viewport")
	await capture("ui_starmap_fuel_range", {"toggle_text": toggle.text, "toggle_pressed": toggle.button_pressed, "toggle_rect": _ui_rect(toggle), "fuel_text": fuel.text, "fuel_rect": _ui_rect(fuel), "travel_phase": String(runtime.get_snapshot().space_travel.phase), "source": "Actual Flow star map with its real campaign runtime provider"})
	if not await _click_ui(star.get("_view_homebase"), "actual star-map return-to-base button"):
		await _finish_ui(); return
	await frames(8)
	var menu: Node = root.get_node("GlobalEscapeMenu")
	menu.set_test_mode(true) # Only prevents exiting this capture process.
	await _escape_ui()
	if not _expect(menu.is_menu_visible(), "viewport-local Escape opens the actual menu"):
		await _finish_ui(); return
	if not await _click_ui(menu.get("_quit_button"), "actual Quit button"):
		await _finish_ui(); return
	await frames(5)
	var exit_panel: Control = menu.get("_exit_panel")
	var description: Label = menu.get("_exit_label")
	var exit_save: Button = menu.get("_exit_save")
	var exit_confirm: Button = menu.get("_exit_confirm")
	check(exit_panel.is_visible_in_tree() and not menu.was_quit_requested_for_tests() and description.text.contains("Ungespeicherter Fortschritt") and description.text.contains("Basisstand"), "real exit dialog explicitly names dirty progress and the persisted resume state")
	check(not exit_save.disabled and root.gui_get_focus_owner().name == "CancelExitButton" and root.get_visible_rect().encloses(exit_panel.get_global_rect()), "safe cancellation is focused and all exit choices fit 720p")
	check(FileAccess.get_sha256(UI_HOME.DEFAULT_PATH) == saved_sha and UI_HOME.load_checkpoint().payload.campaign.jobs.satellite_recovery.status != "accepted", "accepted job is genuinely unsaved and all capture navigation preserves the saved file")
	await capture("ui_unsaved_exit_confirmation", {"description": description.text, "save_action": exit_save.text, "discard_action": exit_confirm.text, "focused_control": String(root.gui_get_focus_owner().name), "dialog_rect": _ui_rect(exit_panel), "live_job": String(runtime.get_snapshot().campaign.jobs.satellite_recovery.status), "saved_job": String(UI_HOME.load_checkpoint().payload.campaign.jobs.satellite_recovery.status), "save_sha256": saved_sha, "simulation_paused": paused})
	await _finish_ui()

func _expect(value: bool, label: String) -> bool:
	check(value, label)
	return value

func _click_ui(control: Button, label: String) -> bool:
	if not _expect(is_instance_valid(control) and control.is_visible_in_tree() and not control.disabled and root.get_visible_rect().encloses(control.get_global_rect()), label + " is visible and actionable"):
		return false
	var point := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point; motion.global_position = point
	root.push_input(motion, true)
	await process_frame
	var event := InputEventMouseButton.new()
	event.position = point; event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT; event.pressed = true; event.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(event, true)
	event = event.duplicate(); event.pressed = false; event.button_mask = 0
	root.push_input(event, true)
	await frames(3)
	return true

func _escape_ui() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE; event.pressed = true
	root.push_input(event, true)
	await process_frame
	event = event.duplicate(); event.pressed = false
	root.push_input(event, true)
	await frames(4)

func _ui_rect(control: Control) -> Array:
	var rectangle := control.get_global_rect()
	return [rectangle.position.x, rectangle.position.y, rectangle.size.x, rectangle.size.y]

func _finish_ui() -> void:
	var menu := root.get_node_or_null("GlobalEscapeMenu")
	if menu != null: menu.close_menu()
	if is_instance_valid(_ui_flow): _ui_flow.queue_free()
	current_scene = null
	await frames(2)
	if not output.is_empty():
		var file := FileAccess.open(output.path_join("capture_manifest.json"), FileAccess.WRITE)
		if _expect(file != null, "native UI capture manifest opens"):
			manifest["passed"] = passed
			manifest["failed"] = failed
			file.store_string(JSON.stringify(manifest, "\t"))
			file.close()
	print("REVIEW_COMPLETION_UI_CAPTURE passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)
