extends SceneTree

const DEBRIEF := preload("res://scenes/meta/debrief_test_screen.tscn")
const AUTHORITY := preload("res://scripts/mission/mission_combat_authority_contract.gd")
var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for size in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		await _check_result(size, "aborted", "evacuation", "Einsatz abgebrochen", "Abgebrochen", "Evakuierung")
		await _check_result(size, "victory", "objective_capture", "Einsatz abgeschlossen", "Erfolg", "Ziel sichern")
		await _check_result(size, "defeat", "objective_capture", "Einsatz abgeschlossen", "Niederlage", "Ziel sichern")
		await _check_result(size, "unknown_review8_fixture", "", "Bericht unvollständig", "Ergebnis offen", "nicht angegeben")
	print("REVIEW8_UX_DEBRIEF: %d passed, %d failed" % [_passed, _failed])
	if _failed == 0:
		print("PASS: review8 UX aborted debrief")
	quit(0 if _failed == 0 else 1)


func _check_result(size: Vector2i, result_code: String, condition: String, heading: String, outcome: String, condition_text: String) -> void:
	var capture_dir := _capture_directory()
	var viewport: Viewport
	if not capture_dir.is_empty():
		root.content_scale_size = Vector2i.ZERO
		root.size = size
		viewport = root
	else:
		var isolated := SubViewport.new()
		isolated.size = size
		isolated.render_target_update_mode = SubViewport.UPDATE_DISABLED
		root.add_child(isolated)
		viewport = isolated
	var screen := DEBRIEF.instantiate() as Control
	screen.visible = true
	viewport.add_child(screen)
	# The existing authority builds the real result shape. This is a native UI
	# consumer fixture, not a physical evacuation or campaign-progression proof.
	var report: Dictionary = AUTHORITY.build_mission_result(result_code, "", "team_alpha", condition, false, 42.0, [])
	var original := report.duplicate(true)
	screen.call("set_mission_result", report)
	await _frames(8)
	var prefix := "%s %s: " % [size, result_code]
	var title := screen.find_child("OutcomeHeading", true, false) as Label
	var symbol := screen.find_child("OutcomeSymbol", true, false) as Label
	var summary := screen.get_node("Panel/Margin/VBox/SummaryStrip")
	_check(title != null and title.is_visible_in_tree() and title.text == heading, prefix + "native heading identifies the actual completed or incomplete outcome")
	_check((summary.get_child(0) as Label).text == outcome, prefix + "outcome chip names the authority result")
	_check((summary.get_child(3) as Label).text == "Auftrag: " + condition_text, prefix + "condition chip identifies evacuation without a diagnostic fallback")
	if result_code == "aborted":
		_check(symbol != null and symbol.text != "?" and symbol.tooltip_text == "Einsatz abgebrochen", prefix + "confirmed abort is not depicted as a missing result")
	_check(Dictionary(screen.call("get_mission_result")) == original and report == original, prefix + "presentation preserves the complete authority payload")
	if result_code == "aborted" and not capture_dir.is_empty():
		await _capture_abort(screen, size, capture_dir, original)
	screen.call("open_debrief_details")
	var detail := screen.find_child("DebriefOriginalText", true, false) as TextEdit
	_check(detail != null and JSON.parse_string(detail.text) == JSON.parse_string(JSON.stringify(original)), prefix + "original report details preserve result and condition")
	screen.call("close_debrief_details")
	var panel := screen.get_node("Panel") as Control
	_check(Rect2(Vector2.ZERO, Vector2(size)).encloses(panel.get_global_rect()), prefix + "actual report remains inside the viewport")
	if viewport == root:
		screen.queue_free()
	else:
		viewport.queue_free()
	await _frames(2)


func _capture_directory() -> String:
	if DisplayServer.get_name() == "headless":
		return ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--ux-output="):
			return argument.trim_prefix("--ux-output=").strip_edges()
	return ""


func _capture_abort(screen: Control, size: Vector2i, directory: String, report: Dictionary) -> void:
	_check(DirAccess.make_dir_recursive_absolute(directory) == OK, "native abort capture directory is available")
	await RenderingServer.frame_post_draw
	var stem := "review8_ux_debrief_abort_%dx%d" % [size.x, size.y]
	var path := directory.path_join(stem + ".png")
	_check(root.get_texture().get_image().save_png(path) == OK, "native root viewport abort PNG is saved")
	var panel := screen.get_node("Panel") as Control
	var heading := screen.find_child("OutcomeHeading", true, false) as Label
	var metadata := {"schema": "sternenbuergerchen.review8_ux_capture.v1", "capture": path, "display_server": DisplayServer.get_name(), "viewport": [size.x, size.y], "fixture_type": "native_debrief_authority_contract_consumer", "physical_gameplay_proof": false, "result": report.get("result"), "mission_outcome": report.get("mission_outcome"), "win_condition_type": report.get("win_condition_type"), "heading": heading.text, "panel_rect": [panel.position.x, panel.position.y, panel.size.x, panel.size.y]}
	var file := FileAccess.open(directory.path_join(stem + ".json"), FileAccess.WRITE)
	_check(file != null, "native abort capture metadata is writable")
	if file != null:
		file.store_string(JSON.stringify(metadata, "  ") + "\n")
	print("REVIEW8_UX_CAPTURE ", path)


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
