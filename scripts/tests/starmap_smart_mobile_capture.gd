extends "res://scripts/tests/review_completion_ui_capture.gd"
## Same genuine campaign state/camera at 720p and 1080p, usable on before/after
## source snapshots. All actions use actual controls or public view commands.
func run() -> void:
	if not UI_GUARD.require_isolated_user_data(): return
	output = OS.get_environment("SB_REVIEW_COMPLETION_CAPTURE_DIR")
	if output.is_empty() or DisplayServer.get_name() == "headless": quit(2); return
	DirAccess.make_dir_recursive_absolute(output)
	check(FileAccess.file_exists("user://review2_isolation_canary.json"), "actual private-profile canary")
	root.size = Vector2i(1280,720)
	root.content_scale_size = root.size
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	START.request_start(self,"campaign","new")
	_ui_flow = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(_ui_flow); current_scene = _ui_flow
	await frames(24)
	_ui_flow.set_process(false)
	var screen: Control = _ui_flow.get_node("HomebaseScreen")
	var presenter: Node = screen.get("_operations_presenter")
	var runtime: Node = _ui_flow.get("_singleplayer_runtime")
	check(_ui_flow.request_campaign_save().get("ok",false), "actual initial checkpoint")
	var original_home_sha := FileAccess.get_sha256(UI_HOME.DEFAULT_PATH)
	for dimensions: Vector2i in [Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size = dimensions; root.content_scale_size = dimensions
		await frames(10)
		if not await _click_ui(presenter.get("_nav").get("base"), "actual base navigation before person selection"):
			await finish_capture(); return
		await frames(8)
		var base_dock: Rect2 = presenter.get("_base").get_command_dock_rect()
		check(presenter.get("_base_management_bar").visible and presenter.get("_nav").jobs.get_global_rect().end.y < base_dock.position.y, "expanded base actions keep Smart Mobile above the command dock " + str(dimensions))
		var selected_base: Node = presenter.get("_base")
		var pilot_id := String(_ui_flow.get("_all_team_units")[1].unit_id)
		if String(selected_base.get("_selected_person_id")) != pilot_id:
			if not await _click_ui(selected_base.find_child("SelectPerson_" + pilot_id.validate_node_name(),true,false), "actual other-person card selects pilot"):
				await finish_capture(); return
		check(selected_base.get("_selected_person_id") == pilot_id and selected_base.get("_person_name").text == String(_ui_flow.get("_all_team_units")[1].display_name), "native inline editor shows the selected pilot's unchanged canonical name")
		if not await _click_ui(presenter.get("_nav").get("jobs"), "actual Smart Mobile navigation"):
			await finish_capture(); return
		await frames(18)
		check(presenter.get("_base_management_bar").visible, "switching to the actual job app keeps the unfolded base actions open")
		var board: Control = presenter.get("_job_board")
		if not _expect(board.is_visible_in_tree() and presenter.is_workspace_flyout_open(), "actual navigation opens the visible job app " + str(dimensions)):
			await finish_capture(); return
		if not bool(board.get("_details_expanded")):
			if not await _click_ui(board.get("_card_buttons").get("satellite_recovery"), "actual mission dossier"):
				await finish_capture(); return
		var footer: Control = board.get("_footer")
		var facts: Label = board.get("_details")
		var picture: TextureRect = board.get("_picture")
		var objectives: Label = board.get("_objectives")
		check(picture.get_global_rect().end.x <= facts.global_position.x and absf(picture.global_position.y - facts.global_position.y) < 2 and objectives.global_position.y >= picture.get_global_rect().end.y and not board.get("_summary").visible, "native dossier keeps full illustration left above goals beside compact facts " + str(dimensions))
		var base: Node = presenter.get("_base")
		var name_edit: LineEdit = base.get("_person_name")
		check(name_edit.is_visible_in_tree() and base.find_child("CommandsSelectionSeparator",true,false) != null and base.find_child("SelectionPeopleSeparator",true,false) != null, "native dock shows inline name and both section separators " + str(dimensions))
		check(board.size.y <= 500.0, "actual job app remains compact " + str(dimensions))
		var illustration: TextureRect = board.get("_picture")
		check(illustration.texture != null and illustration.texture.resource_path == "res://Assets/curated/mission_illustrations_20261113/satellite_recovery.png" and illustration.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "actual full satellite illustration " + str(dimensions))
		check(footer.is_visible_in_tree() and board.get_global_rect().encloses(footer.get_global_rect()) and root.get_visible_rect().encloses(footer.get_global_rect()), "actual app footer fits " + str(dimensions))
		await capture("smart_mobile_%d" % dimensions.y, {"resolution":[dimensions.x,dimensions.y], "status":runtime.get_snapshot().campaign.jobs.satellite_recovery.status, "dossier":board.get("_details").text, "footer":_ui_rect(footer), "illustration":illustration.texture.resource_path, "illustration_rect":_ui_rect(illustration), "source":"actual new campaign, offered satellite job"})
		if not await _click_ui(presenter.get("_flyout_close"), "actual app close"):
			await finish_capture(); return
		check(runtime.request_operation("select_destination", {"location_id":"satellite_crash", "job_id":""}).get("ok",false), "actual destination selection with no mission binding or flight")
		check(_ui_flow.open_location_view("star_map").get("ok",false), "actual star map opens")
		await frames(10)
		var star: Control = _ui_flow.get("_star_map_screen")
		check(star.find_child("SystemCaption",true,false).text == "SYSTEM: Börner" and star.get("_navigation").get("_items")["body:sun"].get_text(0) == "Börner  /  SYSTEM", "native actual heading and tree show Börner")
		check(star.get("_navigation").orbit_marker_count == runtime.get_snapshot().space_travel.orbits.size(), "native tree exposes exactly one OM per body")
		star.get("_canvas").reset_camera()
		if not star.get("_fuel_toggle").button_pressed:
			if not await _click_ui(star.get("_fuel_toggle"), "actual range toggle"):
				await finish_capture(); return
		check(star.get("_fuel_help").is_visible_in_tree(), "native range information visible")
		await capture("starmap_%d" % dimensions.y, {"resolution":[dimensions.x,dimensions.y], "phase":runtime.get_snapshot().space_travel.phase, "selected_location_id":runtime.get_snapshot().campaign.selected_location_id, "camera":star.get("_canvas").get_camera_snapshot(), "fuel_text":star.get("_fuel_help").text, "source":"actual same new campaign, same system reset camera, no flight"})
		if dimensions.y == 720:
			var tree: Tree = star.get("_navigation")
			for inspection: Dictionary in [{"key":"location:fortified_outpost", "image":"inspection_unknown_location_720", "kind":"location"}, {"key":"body:glut_1a", "image":"inspection_unknown_orbit_720", "kind":"orbit"}]:
				if not await _click_tree_inspection(tree, tree.get("_items")[inspection.key]):
					await finish_capture(); return
				var projected: Dictionary = _ui_flow.get_remote_inspection_snapshot()
				if not _expect(projected.get("view") == "inspection" and projected.get("screen", {}).get("blackout", false) and projected.get("target", {}).get("kind") == inspection.kind, "actual unknown view opens through adjacent tree button: " + String(inspection.kind)):
					await finish_capture(); return
				check(not _ui_flow.get("_campaign_tutorial").visible and not _ui_flow.get("_singleplayer_services_toggle").visible, "first remote view immediately hides unrelated tutorial and services: " + String(inspection.kind))
				await capture(inspection.image, {"resolution":[1280,720], "inspection":projected, "source":"actual new campaign; no mission/area admission or crew movement"})
				var remote: Control = _ui_flow.get("_remote_inspection_screen")
				if not await _click_ui(remote.find_child("BackToStarMap", true, false), "actual inspection return to star map"):
					await finish_capture(); return
			check(runtime.get_snapshot().space_travel.phase == "grounded" and runtime.get_snapshot().campaign.selected_location_id == "satellite_crash", "native inspection never changes the selected route or grounded travel phase")
		if not await _click_ui(star.get("_view_homebase"), "actual return to base"):
			await finish_capture(); return
		# This capture freezes Flow for reproducible views, but normal home
		# tutorial/services projection belongs to its existing 0.25s process tick.
		# Run that real owner briefly instead of forcing a refresh or UI visibility.
		var was_processing: bool = _ui_flow.is_processing()
		_ui_flow.set_process(true)
		var restored_deadline := Time.get_ticks_msec() + 1500
		while (not _ui_flow.get("_campaign_tutorial").visible or not _ui_flow.get("_singleplayer_services_toggle").visible) and Time.get_ticks_msec() < restored_deadline:
			await process_frame
		_ui_flow.set_process(was_processing)
		print("NATIVE_HOME_RESTORE view=",_ui_flow.get("_current_meta_view")," mode=",presenter.get("_mode")," tutorial=",_ui_flow.get("_campaign_tutorial").visible," services=",_ui_flow.get("_singleplayer_services_toggle").visible)
		check(_ui_flow.get("_campaign_tutorial").visible and _ui_flow.get("_singleplayer_services_toggle").visible, "normal home context restores its actual tutorial and available services")
	check(original_home_sha == FileAccess.get_sha256(UI_HOME.DEFAULT_PATH) and runtime.get_snapshot().campaign.jobs.satellite_recovery.status == "offered", "capture navigation never accepts a job, flies or changes the original Home file")
	await finish_capture()

func capture(id: String, facts: Dictionary = {}) -> void:
	await frames(12)
	await RenderingServer.frame_post_draw
	var pixels := root.get_texture().get_image()
	check(pixels != null and pixels.get_size() == root.size, id + " actual native dimensions")
	if id.begins_with("inspection_unknown_"):
		check(pixels.get_pixel(int(root.size.x / 2), int(root.size.y / 2)) == Color.BLACK, id + " unobserved world is actually rendered black")
	check(pixels.save_png(output.path_join(id + ".png")) == OK, id + " PNG written")
	manifest.images.append({"id":id,"facts":facts})

func _click_tree_inspection(tree: Tree, item: TreeItem) -> bool:
	var result: Dictionary = await preload("res://scripts/tests/viewport_tree_button_input.gd").click(tree,item)
	print("NATIVE_TREE_INSPECTION ",result)
	return _expect(bool(result.ok), "actual Tree button emits its native signal using viewport-local input")

func finish_capture() -> void:
	if is_instance_valid(_ui_flow): _ui_flow.queue_free()
	current_scene = null
	await frames(2)
	manifest["scope"] = "Native actual UI, 720p/1080p, same campaign and camera. No OS input. Before/after sources supplied by isolated runner."
	manifest["passed"] = passed; manifest["failed"] = failed
	var file := FileAccess.open(output.path_join("capture_manifest.json"),FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(manifest,"\t")); file.close()
	else: check(false,"manifest opens")
	print("STARMAP_SMART_MOBILE_CAPTURE passed=%d failed=%d" % [passed,failed])
	quit(1 if failed else 0)
