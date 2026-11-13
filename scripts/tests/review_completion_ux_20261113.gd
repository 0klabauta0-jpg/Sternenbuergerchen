extends SceneTree
## Real Flow/save/menu/operation owners; direct boundary data only for the pure
## projection matrix and an explicitly prepared in-flight save guard.
const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const PROJECTION = preload("res://scripts/meta/campaign_save_projection.gd")
const HOME = preload("res://scripts/meta/campaign_checkpoint_store.gd")
const ACTIVE = preload("res://scripts/meta/campaign_active_checkpoint_store.gd")
const STAR = preload("res://scripts/ui/star_map_screen.gd")
const VIEW = preload("res://scripts/meta/character_sheet_view.gd")
const PROFILE = preload("res://scripts/meta/meta_unit_profile.gd")
var passed := 0
var failed := 0
var commands: Array = []

class MenuProbe extends "res://scripts/ui/main_menu_screen.gd":
	var routed := ""
	func _change_scene(path: String) -> void: routed = path

func _init() -> void:
	if GUARD.require_isolated_user_data(): call_deferred("_run")

func check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failed += 1; print("FAIL: ", label)

func _matrix() -> void:
	var home := {"ok":true,"payload":{"campaign":{"locations":{"satellite_crash":{"name":"Satelliten-Absturzstelle"}}}}}
	var active := {"ok":true,"payload":{"components":{"identity":{"location_id":"satellite_crash"}}}}
	var meta := {"home_time":1000,"active_time":2000,"active_present":true}
	var before := [home.duplicate(true), active.duplicate(true), meta.duplicate(true)]
	var p := PROJECTION.project(home, active, meta)
	check(p.kind == "mission" and p.location == "Aschental" and p.saved_at_unix == 2000 and p.continue_available, "valid active selection names real location and file time")
	p = PROJECTION.project(home, {"ok":false,"reason":"active_home_mismatch"}, meta)
	check(p.kind == "home" and p.saved_at_unix == 1000 and p.continue_available, "superseded active selects actual home")
	p = PROJECTION.project(home, {"ok":false,"reason":"invalid_checkpoint_json"}, meta)
	check(p.kind == "none" and not p.continue_available and p.home_available and p.summary.contains("Wiederherstellung"), "corrupt active cannot silently advertise home Continue")
	meta.active_retired = true
	check(PROJECTION.project(home, {"ok":false}, meta).kind == "home", "exact retired artifact does not block new campaign")
	check(not PROJECTION.project({"ok":false,"reason":"checkpoint_missing"}, active, meta).continue_available, "active without validated home cannot resume")
	check(PROJECTION.blocked_text("world_active").contains("Reise") and not PROJECTION.blocked_text("mission_movement_pending").is_empty(), "shared save reasons distinguish travel and movement")
	check(PROJECTION.equivalent({"x":1,"y":[2.0]}, {"y":[2],"x":1.0}) and not PROJECTION.equivalent({"x":1},{"x":2}), "dirty comparison respects persisted numeric values")
	var precise := {"value":1.234567891234567}
	var home_wire: Dictionary = JSON.parse_string(JSON.stringify(precise, "", true))
	var active_wire: Dictionary = JSON.parse_string(JSON.stringify(precise, "", true, true))
	check(PROJECTION.equivalent(precise, home_wire), "home comparison uses the actual home-store decimal precision")
	check(PROJECTION.equivalent(precise, active_wire, true) and not PROJECTION.equivalent(precise, {"value":1.23456789}, true), "active comparison retains its full-precision saved domain")
	meta.erase("active_retired")
	check([home,active,meta] == before, "projection matrix mutates none of its source snapshots")

func _run() -> void:
	_matrix()
	root.size = Vector2i(1280,720)
	root.content_scale_size = root.size
	load("res://scripts/meta/game_start_contract.gd").request_start(self,"campaign","new")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	current_scene = flow
	for frame in range(24): await process_frame
	# Freeze only this test's periodic autosaver, never substitute its saver or
	# runtime owners. The real menu does not pause simulation.
	flow.set_process(false)
	var runtime: Node = flow.get("_singleplayer_runtime")
	var screen: Control = flow.get_node("HomebaseScreen")
	var presenter: Node = screen.get("_operations_presenter")
	var menu: Node = root.get_node("GlobalEscapeMenu")
	menu.set_test_mode(true)
	var saved: Dictionary = flow.request_campaign_save()
	check(saved.get("ok", false), "actual new campaign home save succeeds")
	var projection: Dictionary = flow.get_campaign_save_projection()
	if projection.has_unsaved_progress:
		var capture: Dictionary = flow.get("_campaign_start").capture_home_checkpoint(flow, runtime)
		var live: Dictionary = JSON.parse_string(JSON.stringify(capture.get("payload", {}), "", true))
		var differences: Array = []
		_payload_differences(live, HOME.load_checkpoint().get("payload", {}), "home", differences)
		print("UX_CLEAN_PROJECTION ", JSON.stringify({"projection":projection,"differences":differences}))
	check(projection.kind == "home" and projection.can_save and not projection.has_unsaved_progress and projection.saved_at_unix > 0, "actual clean home projection names persisted state without false loss warning")
	var file_before := FileAccess.get_sha256(HOME.DEFAULT_PATH)
	var config: RefCounted = flow.get("_campaign_start")
	var throttle_before := [config.get("_hex_export_scope"),config.get("_hex_export_msec"),config.get("last_save_signature")]
	var state_before: Dictionary = runtime.export_campaign_checkpoint()
	for index in range(3): flow.get_campaign_save_projection()
	check(FileAccess.get_sha256(HOME.DEFAULT_PATH) == file_before and runtime.export_campaign_checkpoint() == state_before, "live projection does not write checkpoint or change owner state")
	check([config.get("_hex_export_scope"),config.get("_hex_export_msec"),config.get("last_save_signature")] == throttle_before, "projection never consumes autosave throttle or signature")
	check(menu.request_quit_game().get("ok", false) and menu.was_quit_requested_for_tests(), "clean saved home permits direct exit")
	menu.set_test_mode(true)
	check(not auto_accept_quit and root.close_requested.is_connected(menu._on_window_close_requested), "actual autoload owns the main-window close boundary")
	root.close_requested.emit()
	check(menu.was_quit_requested_for_tests(), "real main-window signal permits clean exit through the owner")
	menu.set_test_mode(true)
	var accepted: Dictionary = screen.request_operation("accept_job", {"job_id":"satellite_recovery"})
	check(accepted.get("ok", false) and flow.get_campaign_save_projection().has_unsaved_progress, "actual job acceptance makes progress dirty")
	root.close_requested.emit()
	check(menu.get("_exit_panel").visible and not menu.was_quit_requested_for_tests(), "real main-window close protects dirty progress without OS input")
	menu._cancel_exit()
	menu.close_menu()
	menu.open_menu()
	# Godot Container sorting is deferred; inspect the displayed geometry after
	# layout, not stale dimensions from the hidden menu's previous content.
	for frame in range(3): await process_frame
	check(String(menu.get("_resume_label").text).contains("Basisstand"), "Escape names the same resumable home kind")
	print("UX_MENU_GEOMETRY viewport=", root.get_visible_rect(), " panel=", menu.get("_menu_panel").get_global_rect(), " minimum=", menu.get("_menu_panel").get_combined_minimum_size())
	check(root.get_visible_rect().encloses(menu.get("_menu_panel").get_global_rect()), "expanded save information and menu buttons fit 720p")
	menu.get("_quit_button").pressed.emit()
	check(menu.get("_exit_panel").visible and not menu.was_quit_requested_for_tests(), "real quit button requires explicit loss confirmation")
	check(root.gui_get_focus_owner().name == "CancelExitButton", "exit confirmation defaults to non-destructive focus")
	await _key(KEY_ESCAPE)
	check(menu.is_menu_visible() and not menu.get("_exit_panel").visible and not menu.was_quit_requested_for_tests(), "Escape cancels exit while preserving modal menu")
	menu.return_to_main_menu(false)
	check(menu.get("_exit_action") == "main_menu" and menu.get("_exit_panel").visible, "main menu uses the same guarded progress boundary")
	menu._cancel_exit()
	menu.request_quit_game()
	menu.get("_exit_save").pressed.emit()
	check(menu.was_quit_requested_for_tests() and HOME.load_checkpoint().payload.campaign.jobs.satellite_recovery.status == "accepted", "real Save and exit persists accepted job before departure")
	menu.close_menu()
	menu.set_test_mode(true)
	# Explicit flight boundary: preserve and restore exactly this travel owner's
	# phase. This tests the actual guard/UI, not a claimed complete flight.
	var fleet: RefCounted = runtime.get("_travel")
	var craft: String = String(flow.get_meta("singleplayer_bootstrap_craft_id"))
	var travel: RefCounted = fleet.get("_owners")[craft]
	var phase: String = travel.get("_phase")
	travel.set("_phase", "orbit")
	projection = flow.get_campaign_save_projection()
	check(not projection.can_save and projection.has_unsaved_progress and projection.save_blocked_reason == "world_active", "actual fleet guard exposes unsavable flight")
	menu.request_quit_game()
	check(menu.get("_exit_save").disabled and String(menu.get("_exit_label").text).contains("Reise") and String(menu.get("_exit_label").text).contains("Basisstand"), "flight exit names preserved home and disables unavailable save-and-exit")
	menu.get("_exit_confirm").pressed.emit()
	check(menu.was_quit_requested_for_tests(), "explicit discard confirmation reaches actual quit boundary")
	menu.close_menu()
	travel.set("_phase", phase)
	# Scene-presence boundary for the existing Skirmish mode. No fake mission
	# outcome or save is claimed; only the owner's exit policy is exercised.
	var entry: Dictionary = flow.get("_game_start_request")
	flow.set("_game_start_request", {"mode":"skirmish","action":"new"})
	check(flow.get_exit_progress_projection().is_empty(), "Skirmish preparation adds no exit confirmation")
	var mission_presence := Node.new()
	flow.set("_active_mission", mission_presence)
	var skirmish: Dictionary = flow.get_exit_progress_projection()
	check(skirmish.has_unsaved_progress and not skirmish.can_save and skirmish.summary.contains("Skirmish"), "active Skirmish explains loss without a fake save-and-exit")
	flow.set("_active_mission", null)
	flow.set("_game_start_request", entry)
	mission_presence.free()
	await _person_names(flow, screen, presenter, runtime)
	await _layouts(screen, presenter)
	await _fuel(runtime)
	await _relationships()
	var main_menu: Node = load("res://scenes/ui/main_menu.tscn").instantiate()
	main_menu.set_script(MenuProbe)
	root.add_child(main_menu)
	await process_frame
	main_menu._on_campaign_pressed()
	check(not main_menu.get("_campaign_continue_button").disabled and String(main_menu.get("_campaign_dialog").dialog_text).contains("Basisstand"), "actual main menu uses same saved-state projection")
	main_menu.get("_campaign_dialog").hide()
	var corrupt := FileAccess.open(ACTIVE.DEFAULT_PATH, FileAccess.WRITE)
	corrupt.store_string("{broken UX fixture")
	corrupt.close()
	main_menu._on_campaign_pressed()
	check(main_menu.get("_campaign_continue_button").disabled and not main_menu.get("_campaign_home_button").disabled, "real corrupt active disables Continue while preserving explicit home recovery")
	main_menu._on_campaign_continue_pressed()
	check(main_menu.routed.is_empty() and FileAccess.get_file_as_string(ACTIVE.DEFAULT_PATH) == "{broken UX fixture", "revalidation neither routes nor changes corrupted artifact")
	main_menu.get("_campaign_dialog").hide()
	main_menu.free()
	menu.close_menu()
	current_scene = null
	flow.queue_free()
	for frame in range(4): await process_frame
	_test_window_close_lifecycle(menu)
	print("REVIEW_COMPLETION_UX passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)

func _test_window_close_lifecycle(menu: Node) -> void:
	var original: bool = menu.get("_previous_auto_accept_quit")
	var callback := Callable(menu, "_on_window_close_requested")
	root.remove_child(menu)
	check(auto_accept_quit == original and not root.close_requested.is_connected(callback), "autoload teardown disconnects main-window signal and restores prior quit option")
	menu.free()
	auto_accept_quit = false
	var replacement: Node = load("res://scripts/ui/global_escape_menu.gd").new()
	root.add_child(replacement)
	check(replacement.get("_owns_window_close") and not auto_accept_quit, "replacement autoload preserves an already disabled automatic quit policy")
	var embedded: Node = load("res://scripts/ui/global_escape_menu.gd").new()
	replacement.add_child(embedded)
	check(not embedded.get("_owns_window_close"), "embedded menu cannot acquire a second main-window close handler")
	embedded.free()
	replacement.free()
	check(not auto_accept_quit, "teardown retains preexisting manual quit policy")
	auto_accept_quit = original

func _payload_differences(left: Variant, right: Variant, path: String, result: Array) -> void:
	if result.size() >= 12 or left == right: return
	if left is Dictionary and right is Dictionary:
		var keys: Array = left.keys()
		for key in right:
			if not keys.has(key): keys.append(key)
		keys.sort()
		for key in keys: _payload_differences(left.get(key), right.get(key), path + "." + String(key), result)
	elif left is Array and right is Array and left.size() == right.size():
		for index in left.size(): _payload_differences(left[index], right[index], path + "[%d]" % index, result)
	else:
		result.append({"path":path,"live":str(left).left(160),"saved":str(right).left(160)})

func _person_names(flow: Node, screen: Control, presenter: Node, runtime: Node) -> void:
	presenter._navigate_from_sidebar("base")
	var base: Node = presenter.get("_base")
	var roster: Array = flow.get("_all_team_units")
	var person: Dictionary = roster[1].duplicate(true)
	var id := String(person.unit_id)
	var original := String(person.display_name)
	base._select_person(String(roster[0].unit_id))
	base._update_personnel_controls()
	screen.request_operation("details", {"unit_id":id})
	for frame in range(3): await process_frame
	var names := _person_name_labels(screen, base, runtime, id)
	print("UX_PERSON_NAMES initial=", JSON.stringify(names))
	check(names.values().all(func(value: Variant): return value == original), "authored owner, profile, detail and other-person card share the exact name")
	await _click(screen.get_node("CharacterSheetPopup").find_child("ClosePopupButton",true,false))
	await _click(base.find_child("SelectPerson_" + id.validate_node_name(),true,false))
	var edit: LineEdit = base.get("_person_name")
	check(base.get("_selected_person_id") == id and edit.text == original, "person card selects the actual pilot and projects that person's editable name")
	await _edit_name(edit, "Unfertiger Entwurf")
	base._update_personnel_controls()
	check(edit.has_focus() and edit.text == "Unfertiger Entwurf" and flow.get("_all_team_units")[1] == person, "owner refresh preserves focused draft without renaming anyone")
	await _click(base.find_child("SelectPerson_" + String(roster[0].unit_id).validate_node_name(),true,false))
	check(edit.text == String(roster[0].display_name) and flow.get("_all_team_units")[1] == person and flow.get("_all_team_units")[0] == roster[0], "changing cards discards only the local draft and never renames the default person")
	await _click(base.find_child("SelectPerson_" + id.validate_node_name(),true,false))
	var renamed := "Ibarra · Einsatz 7"
	await _edit_name(edit, renamed)
	await _key(KEY_ENTER)
	base._update_personnel_controls()
	screen.request_operation("details", {"unit_id":id})
	for frame in range(3): await process_frame
	names = _person_name_labels(screen, base, runtime, id)
	print("UX_PERSON_NAMES renamed=", JSON.stringify(names))
	check(names.values().all(func(value: Variant): return value == renamed), "actual Enter rename updates the canonical owner, editable name and character details")
	var expected := person.duplicate(true)
	expected.display_name = renamed
	check(flow.get("_all_team_units")[1] == expected, "rename changes only the canonical display name, preserving identity and profile data")
	var saved: Dictionary = flow.request_campaign_save()
	check(saved.get("ok",false) and HOME.load_checkpoint().get("payload",{}).get("roster",[])[1].display_name == renamed, "owner save persists the exact user name")
	screen.request_operation("base_rename", {"unit_id":id,"display_name":original})
	names = _person_name_labels(screen, base, runtime, id)
	# External owner changes project into the base dock on its existing 0.2s UI tick.
	var projection_deadline := Time.get_ticks_msec() + 1000
	while not names.values().all(func(value: Variant): return value == original) and Time.get_ticks_msec() < projection_deadline:
		await process_frame
		names = _person_name_labels(screen, base, runtime, id)
	print("UX_PERSON_NAMES restored=", JSON.stringify(names))
	check(names.values().all(func(value: Variant): return value == original), "external owner rename also refreshes the already-open detail and direct-name editor")
	check(flow.request_campaign_save().get("ok",false), "fixture restores the authored name through the same owner and saver")
	screen.get_node("CharacterSheetPopup").find_child("ClosePopupButton",true,false).pressed.emit()

func _person_name_labels(screen: Control, base: Node, runtime: Node, id: String) -> Dictionary:
	var owner: Node = runtime.get_base_personnel_runtime()
	var detail: Label = screen.get_node("CharacterSheetPopup").find_child("IdentityName",true,false)
	var card: Button = base.find_child("SelectPerson_" + id.validate_node_name(),true,false)
	var edit: LineEdit = base.get("_person_name")
	var dock_name: String = edit.text if String(base.get("_selected_person_id")) == id else (card.text if card != null else "<missing>")
	return {"owner":String(owner.get("_states")[id].name),"profile":String(screen.get("_profiles_by_id")[id].display_name),"detail":detail.text if detail != null else "<missing>","dock":dock_name}

func _edit_name(edit: LineEdit, value: String) -> void:
	await _click(edit)
	edit.select_all()
	for index in value.length():
		var event := InputEventKey.new()
		event.unicode = value.unicode_at(index)
		event.pressed = true
		root.push_input(event,true)
		event = event.duplicate(); event.pressed = false
		root.push_input(event,true)
	await process_frame

func _layouts(screen: Control, presenter: Node) -> void:
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size = resolution
		root.content_scale_size = resolution
		presenter._navigate_from_sidebar("base")
		for frame in range(5): await process_frame
		var badge: Label = presenter.get("_homebase_location")
		var workspace: Control = presenter.get("_workspace")
		check(badge.text == "Standort: Heimathafen · Asterholm", "actual home header uses the same canonical location and moon display as the map")
		check(badge.get_parent().size.y < 100 and workspace.size.y > 360, "%s location badge leaves room for actual base viewport" % resolution)
		var flow: Node = screen.get_parent()
		var tutorial: Control = flow.get("_campaign_tutorial")
		var service_toggle: Button = flow.get("_singleplayer_services_toggle")
		flow._refresh_singleplayer_services()
		tutorial.refresh()
		tutorial.reopen_help()
		check(tutorial.visible and service_toggle.visible, "normal base retains tutorial and available service control")
		var unit := String(screen.get_operations_snapshot().focused_unit.id)
		screen.request_operation("details", {"unit_id":unit})
		var popup: Control = screen.get_node("CharacterSheetPopup")
		check(popup.is_visible_in_tree() and not tutorial.visible and not service_toggle.visible, "opening actual character sheet immediately hides higher context overlays without a timer")
		for frame in range(4): await process_frame
		await _capture("character_modal_%d" % resolution.x)
		await _click(popup.find_child("ClosePopupButton",true,false))
		check(not popup.visible and tutorial.visible and service_toggle.visible, "actual close button is reachable and restores context overlays")
		var jobs: Button = presenter.get("_nav").jobs
		var dock: Control = presenter.get("_base").get_node("BasePersonnelActions")
		var base: Node = presenter.get("_base")
		var first: VSeparator = dock.find_child("CommandsSelectionSeparator",true,false)
		var second: VSeparator = dock.find_child("SelectionPeopleSeparator",true,false)
		var portrait: TextureRect = base.get("_person_portrait")
		var badges: VBoxContainer = base.get("_person_badges")
		var edit: LineEdit = base.get("_person_name")
		check(first != null and second != null and first.get_parent() == second.get_parent() and first.get_global_rect().position.x < portrait.get_global_rect().position.x and second.get_global_rect().position.x > edit.get_global_rect().end.x, "%s two separators divide commands, selected person and other people" % resolution)
		check(root.get_visible_rect().encloses(dock.get_global_rect()) and dock.find_children("*", "OptionButton", true, false).is_empty() and edit.is_visible_in_tree(), "%s dock contains only the direct selected-name editor without a person dropdown" % resolution)
		check(portrait.size.x >= 68 and portrait.size.y >= 88 and badges.get_global_rect().position.x >= portrait.get_global_rect().end.x and absf(badges.global_position.y - portrait.global_position.y) < 2 and badges.get_child_count() > 0, "%s larger portrait and vertical badges align at the top" % resolution)
		var icon_source := preload("res://scripts/ui/homebase_navigation_icons.gd")
		for nav_id: String in icon_source.REGIONS:
			var nav: Button = presenter.get("_nav")[nav_id]
			var icon: AtlasTexture = nav.icon as AtlasTexture
			check(icon != null and icon.atlas.resource_path == icon_source.SOURCE and icon.region == icon_source.REGIONS[nav_id] and nav.icon == icon_source.get_icon(nav_id), "%s %s uses the cached colorful project illustration" % [resolution,nav_id])
		check(root.get_visible_rect().encloses(jobs.get_global_rect()) and not jobs.get_global_rect().intersects(dock.get_global_rect()), "%s Smart Mobile navigation is above the base command dock" % resolution)
		await _click(jobs)
		var board: Control = presenter.get("_job_board")
		check(board.is_visible_in_tree() and presenter.is_workspace_flyout_open(), "%s actual sidebar click opens the job app" % resolution)
		if not board.get("_details_expanded"): board._toggle_job_details("satellite_recovery")
		for frame in range(5): await process_frame
		var footer: PanelContainer = board.get("_footer")
		var accept: Button = board.get("_accept")
		var picture: TextureRect = board.get("_picture")
		var objectives: Label = board.get("_objectives")
		var facts: Label = board.get("_details")
		check(picture.get_global_rect().end.x <= facts.global_position.x and objectives.global_position.y >= picture.get_global_rect().end.y and absf(picture.global_position.y - facts.global_position.y) < 2, "%s briefing image is left above objectives with facts aligned beside it" % resolution)
		check(not board.get("_summary").visible and picture.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "%s satellite dossier preserves the full illustration without generic filler" % resolution)
		check(board.size.y <= 500.0, "%s job app keeps its actions close to the compact dossier" % resolution)
		check(footer.is_visible_in_tree() and board.get_global_rect().encloses(footer.get_global_rect()) and footer.get_global_rect().encloses(accept.get_global_rect()), "%s fixed actions are inside app and footer" % resolution)
		check(accept.get_global_rect().end.y <= dock.get_global_rect().position.y - 8 and root.get_visible_rect().encloses(footer.get_global_rect()), "%s actions remain above base band and inside viewport" % resolution)
		check((footer.get_theme_stylebox("panel") as StyleBoxFlat).bg_color.a == 1.0 and (board.get_theme_stylebox("panel") as StyleBoxFlat).bg_color.a == 1.0, "app shell and footer are opaque petrol")
		check(not tutorial.visible and not service_toggle.visible, "app flyout also suppresses competing context overlays")
		await _capture("job_footer_%d" % resolution.x)
		presenter._close_workspace_flyout()

func _fuel(runtime: Node) -> void:
	root.size = Vector2i(1280,720)
	root.content_scale_size = root.size
	var star := STAR.new()
	var layer := CanvasLayer.new()
	layer.layer = 200
	root.add_child(layer)
	layer.add_child(star)
	star.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	star.configure(Callable(runtime,"get_snapshot"), func(operation: String, payload: Dictionary): commands.append([operation,payload]); return {"ok":true})
	for frame in range(4): await process_frame
	var toggle: Button = star.get("_fuel_toggle")
	var label: Label = star.get("_fuel_help")
	check(toggle.focus_mode == Control.FOCUS_ALL and toggle.is_visible_in_tree() and not label.visible, "fuel information has visible keyboard-focusable control")
	await _click(toggle)
	check(toggle.button_pressed and label.visible and label.text.contains("TREIBSTOFF"), "actual pointer click pins fuel information")
	star.cancel_modal_input()
	check(label.visible and toggle.button_pressed, "Escape gesture cancellation preserves explicit pinned choice")
	toggle.grab_focus()
	await _key(KEY_SPACE)
	check(not toggle.button_pressed and not label.visible, "keyboard Space toggles fuel back off")
	var alt := InputEventKey.new()
	alt.keycode = KEY_ALT
	alt.pressed = true
	root.push_input(alt,true)
	check(label.visible and not toggle.button_pressed, "Alt hold still previews fuel without changing pinned choice")
	alt = alt.duplicate(); alt.pressed = false; root.push_input(alt,true)
	check(not label.visible and commands.is_empty(), "Alt release hides preview and all fuel controls send no gameplay commands")
	await _click(toggle)
	await _capture("fuel_control_1280")
	layer.free()

func _relationships() -> void:
	var host := VBoxContainer.new()
	host.size = Vector2(760,600)
	var layer := CanvasLayer.new()
	layer.layer = 200
	root.add_child(layer)
	layer.add_child(host)
	var profile := PROFILE.new({"unit_id":"ux_person","display_name":"UX Person","trait_ids":["calm"],"relationship_links":[]})
	var before: Dictionary = profile.to_dict()
	# Match the actual Homebase/mission read-only entry; editable metrics default
	# to true for the editor and deliberately select a different layout.
	VIEW.render(host,profile,{"compact_read_only":true,"editable_metrics":false})
	for frame in range(3): await process_frame
	var empty: Label = host.find_child("NoKnownRelationships",true,false)
	check(empty != null and empty.is_visible_in_tree() and empty.size.y < 50 and host.find_child("CharacterRelationshipOverview",true,false) == null, "empty relationships use one readable line without a vacant card")
	check(profile.to_dict() == before, "compact empty rendering preserves all profile data")
	layer.free()

func _key(code: Key) -> void:
	var event := InputEventKey.new(); event.keycode = code; event.pressed = true
	root.push_input(event,true); await process_frame
	event = event.duplicate(); event.pressed = false; root.push_input(event,true); await process_frame

func _click(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new(); motion.position=point; motion.global_position=point
	root.push_input(motion,true); await process_frame
	var event := InputEventMouseButton.new(); event.position=point; event.global_position=point; event.button_index=MOUSE_BUTTON_LEFT; event.pressed=true; event.button_mask=MOUSE_BUTTON_MASK_LEFT
	root.push_input(event,true)
	event=event.duplicate(); event.pressed=false; event.button_mask=0; root.push_input(event,true)
	await process_frame

func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var folder := "user://ux_completion_captures"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	check(root.get_texture().get_image().save_png(folder + "/" + label + ".png") == OK, "native capture " + label)
