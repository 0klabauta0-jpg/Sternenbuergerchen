extends SceneTree

const SCREEN: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const PRESETS: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")
var _passed: int = 0
var _failed: int = 0
var _starts: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("HOMEBASE_OPERATIONS_VERIFY_BEGIN")
	var screen: Control = SCREEN.instantiate()
	root.add_child(screen)
	await process_frame
	_assert(screen.has_method("get_operations_snapshot"), "Homebase exposes read-only operations snapshot")
	_assert(screen.has_method("request_operation"), "Homebase exposes whitelisted operation bridge")
	if not screen.has_method("get_operations_snapshot") or not screen.has_method("request_operation"):
		screen.queue_free()
		await process_frame
		_finish()
		return
	var roster: Array = PRESETS.get_homebase_roster()
	var roster_bytes: PackedByteArray = var_to_bytes(roster)
	screen.call("setup_roster", roster, PackedStringArray(["unit_alpha", "unit_bravo", "unit_charlie"]))
	screen.call("set_fireteam_context", PackedStringArray(["ft1", "ft1", "ft1"]), [{"id": "ft1", "label": "ALPHA", "lead_unit_id": "unit_alpha", "loadout": "medium"}])
	var crafts: Array = [{"craft_id": "dropship_alpha", "craft_type": "dropship", "display_name": "Cutlass", "texture_path": "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png", "supports_cargo": false}]
	screen.call("set_transport_state", crafts, {"dropship_alpha": "unit_delta"}, [], [], {"dropship_alpha": "homebase"}, {}, {}, [])
	screen.connect("mission_start_requested", func(): _starts += 1)
	await process_frame
	var snapshot: Dictionary = screen.call("get_operations_snapshot")
	_assert(String(snapshot.get("mode", "")) == "squad", "Primary entry opens squad and equipment")
	_assert(Array(snapshot.get("roster", [])).size() == roster.size(), "All real roster identities are projected")
	_assert(screen.get_node_or_null("OperationsRoot") != null, "New primary surface exists")
	_assert(not screen.get_node("Panel").visible, "Legacy workbench is not primary")
	_assert(not bool(screen.call("request_operation", "not_allowed", {}).get("ok", true)), "Unknown operations are rejected")
	_assert(bool(screen.call("request_operation", "focus_unit", {"unit_id": "unit_alpha"}).get("ok", false)), "Real unit can be focused")
	_assert(bool(screen.call("request_operation", "loadout", {"unit_id": "unit_alpha", "key": "armor", "value": "heavy"}).get("ok", false)), "Armor selector delegates to existing member loadout")
	snapshot = screen.call("get_operations_snapshot")
	_assert(String(Dictionary(Dictionary(snapshot.get("focused_unit", {})).get("loadout", {})).get("armor", "")) == "heavy", "Selected member displays confirmed armor")
	_assert(not bool(screen.call("request_operation", "loadout", {"unit_id": "unit_alpha", "key": "armor", "value": "invented"}).get("ok", true)), "Unknown equipment value is rejected")
	_assert(bool(screen.call("request_operation", "remove", {"unit_id": "unit_charlie"}).get("ok", false)), "Remove uses existing fireteam callback")
	snapshot = screen.call("get_operations_snapshot")
	_assert(String(_unit(snapshot, "unit_charlie").get("fireteam_id", "")) == "", "Removed member leaves focused fireteam")
	_assert(not PackedStringArray(screen.call("get_selected_unit_ids")).has("unit_charlie"), "Remove releases the existing global staging selection")
	_assert(bool(screen.call("request_operation", "assign", {"unit_id": "unit_charlie", "fireteam_id": "ft1"}).get("ok", false)), "Assign restores the real unit to team")
	for id in ["unit_alpha", "unit_bravo", "unit_charlie"]:
		_assert(bool(screen.call("request_operation", "remove", {"unit_id": id}).get("ok", false)), "Remove real member until team is empty: %s" % id)
	snapshot = screen.call("get_operations_snapshot")
	_assert(Array(Dictionary(snapshot.get("focused_fireteam", {})).get("members", [])).is_empty(), "Last removal leaves no stale definition member")
	_assert(not bool(Dictionary(snapshot.get("selected_craft", {})).get("can_board", true)), "Empty squad cannot board")
	_assert(bool(screen.call("request_operation", "pilot", {"unit_id": "unit_alpha", "craft_id": "dropship_alpha"}).get("ok", false)), "Removed person is available for pilot assignment")
	_assert(String(Dictionary(screen.call("get_operations_snapshot").get("selected_craft", {})).get("pilot_id", "")) == "unit_alpha", "Pilot selector projects the existing manager assignment")
	screen.call("request_operation", "pilot", {"unit_id": "unit_delta", "craft_id": "dropship_alpha"})
	for id in ["unit_alpha", "unit_bravo", "unit_charlie"]:
		_assert(bool(screen.call("request_operation", "assign", {"unit_id": id, "fireteam_id": "ft1"}).get("ok", false)), "Squad restores from actual roster identity: %s" % id)
	_assert(bool(screen.call("request_operation", "board", {"fireteam_id": "ft1", "craft_id": "dropship_alpha"}).get("ok", false)), "Board uses existing craft payload callback")
	_assert(not bool(screen.call("request_operation", "loadout", {"unit_id": "unit_alpha", "key": "armor", "value": "light"}).get("ok", true)), "Boarding payload prevents equipment mutation")
	screen.call("_debug_advance_homebase_direct_boarding", 30.0)
	snapshot = screen.call("get_operations_snapshot")
	_assert(bool(Dictionary(snapshot.get("selected_craft", {})).get("can_start", false)), "Boarding-state fixture completion exposes existing launch gate")
	_assert(bool(screen.call("request_operation", "unboard", {"fireteam_id": "ft1", "craft_id": "dropship_alpha"}).get("ok", false)), "Staged payload can return to preparation")
	_assert(not bool(Dictionary(screen.call("get_operations_snapshot").get("selected_craft", {})).get("has_payload", true)), "Unboard clears existing payload")
	screen.call("request_operation", "board", {"fireteam_id": "ft1", "craft_id": "dropship_alpha"})
	screen.call("_debug_advance_homebase_direct_boarding", 30.0)
	screen.call("request_operation", "start", {"craft_id": "dropship_alpha"})
	_assert(_starts == 1, "Start emits existing mission request once")
	var transit_crafts: Array = crafts.duplicate(true)
	transit_crafts[0]["is_in_transit"] = true
	transit_crafts[0]["mission_transit_to_map"] = true
	transit_crafts[0]["transfer_progress"] = 25.0
	screen.call("set_transport_state", transit_crafts, {"dropship_alpha": "unit_delta"}, [], [], {"dropship_alpha": "mission"}, {}, {}, [])
	snapshot = screen.call("get_operations_snapshot")
	_assert(bool(Dictionary(snapshot.get("selected_craft", {})).get("busy", false)), "Actual transit fixture projects busy craft")
	_assert(not bool(screen.call("request_operation", "unboard", {"fireteam_id": "ft1", "craft_id": "dropship_alpha"}).get("ok", true)), "Transit payload cannot be removed")
	_assert(not bool(screen.call("request_operation", "start", {"craft_id": "dropship_alpha"}).get("ok", true)), "Transit craft cannot be sent twice")
	screen.call("set_mission_context", [], "", "Operations", 8, "")
	screen.call("request_operation", "add_fireteam", {})
	var free_id: String = String(Dictionary(roster[4]).get("unit_id", ""))
	_assert(bool(screen.call("request_operation", "assign", {"unit_id": free_id, "fireteam_id": "ft2"}).get("ok", false)), "Other free squad remains editable during first craft transit")
	_assert(var_to_bytes(roster) == roster_bytes, "Input roster bytes stay unchanged")
	var display: Dictionary = Dictionary(screen.call("get_operations_snapshot").get("presentation", {}))
	_assert(int(display.get("loadout_selector_count", 0)) == 3, "Exactly three focused equipment selectors")
	var portrait_rect: Rect2 = Rect2(display.get("focused_portrait_rect", Rect2()))
	_assert(is_equal_approx(portrait_rect.size.x, portrait_rect.size.y) and portrait_rect.size.x >= 176.0, "Focused portrait stays a large square rather than a cropped banner")
	_assert(int(display.get("focused_portrait_stretch_mode", -1)) == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "Focused portrait preserves full head and aspect")
	_assert(String(display.get("ship_preview_path", "")).ends_with("cutlass_ref03_preview.png"), "Flightdeck uses exact catalog Ref03 Cutlass native preview")
	_assert(int(display.get("team_slot_count", 0)) == 4, "Four visible squad slots")
	_assert(int(display.get("row_create_count", 0)) == roster.size(), "Roster rows are cached by real ID")
	var creates: int = int(display.get("row_create_count", 0))
	screen.call("request_operation", "navigate", {"mode": "personnel"})
	screen.call("request_operation", "navigate", {"mode": "squad"})
	_assert(int(Dictionary(screen.call("get_operations_snapshot").get("presentation", {})).get("row_create_count", 0)) == creates, "Navigation reuses cached roster rows")
	screen.call("request_operation", "navigate", {"mode": "base"})
	await process_frame
	var exploration: Dictionary = Dictionary(Dictionary(screen.call("get_operations_snapshot").get("presentation", {})).get("base", {}))
	_assert(bool(exploration.get("initialized", false)) and bool(exploration.get("active", false)), "Base navigation activates actual explorable scene")
	_assert(not bool(exploration.get("tree_paused", true)), "Base does not pause the global SceneTree")
	screen.call("request_operation", "navigate", {"mode": "squad"})
	exploration = Dictionary(Dictionary(screen.call("get_operations_snapshot").get("presentation", {})).get("base", {}))
	_assert(not bool(exploration.get("active", true)), "Leaving base deactivates its runtime branch")
	_assert(not bool(screen.call("request_operation", "legacy", {}).get("ok", true)), "Normal operations reject obsolete advanced tools entry")
	_assert(not screen.get_node("Panel").visible, "Legacy panels and NodePaths remain hidden in normal play")
	screen.call("request_operation", "navigate", {"mode": "squad"})
	_assert(not screen.get_node("Panel").visible, "Primary navigation returns from legacy tools")
	var original_window_size: Vector2i = root.size
	var original_scale_size: Vector2i = root.content_scale_size
	var operations: Control = screen.get_node("OperationsRoot")
	var owner_before_layout: PackedByteArray = _owner_projection(screen.call("get_operations_snapshot"))
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	await _settle_layout(operations)
	display = Dictionary(screen.call("get_operations_snapshot").get("presentation", {}))
	var columns: Dictionary = Dictionary(display.get("columns", {}))
	_assert(is_equal_approx(screen.size.x, 1280.0), "Narrow regression uses actual 1280 root layout")
	_assert(_visible_column_count(columns) == 3 and not bool(Dictionary(columns.get("flight", {})).get("visible", true)), "Narrow squad uses three preparation columns and moves flight to its navigation page")
	_assert(float(display.get("roster_minimum_name_width", 0.0)) >= 100.0, "1280 roster preserves at least 100px for person name")
	_assert(float(display.get("roster_minimum_portrait_width", 0.0)) >= 96.0 and float(display.get("roster_minimum_assign_width", 0.0)) >= 40.0, "1280 roster preserves portrait and assignment sizes")
	_assert(float(display.get("roster_minimum_row_width", 0.0)) >= 270.0 and bool(display.get("roster_role_status_single_line", false)), "1280 roster has full row width and never wraps role or status by letter")
	var mission_nav: Rect2 = Rect2(display.get("mission_navigation_rect", Rect2()))
	_assert(bool(display.get("mission_navigation_visible", false)) and Rect2(Vector2.ZERO, screen.size).encloses(mission_nav), "Narrow flight navigation remains fully visible")
	var flight_navigation: Button = operations.find_child("Navigate_mission", true, false) as Button
	flight_navigation.pressed.emit()
	await _settle_layout(operations)
	display = Dictionary(screen.call("get_operations_snapshot").get("presentation", {}))
	columns = Dictionary(display.get("columns", {}))
	_assert(String(display.get("mode", "")) == "mission" and _visible_column_count(columns) == 3 and bool(Dictionary(columns.get("flight", {})).get("visible", false)), "Narrow navigation opens the existing flightdeck page")
	_assert(_owner_projection(screen.call("get_operations_snapshot")) == owner_before_layout, "Narrow resize and flight navigation preserve roster, loadouts and transport owners")
	screen.call("request_operation", "navigate", {"mode": "personnel"})
	await _settle_layout(operations)
	display = Dictionary(screen.call("get_operations_snapshot").get("presentation", {}))
	_assert(_visible_column_count(Dictionary(display.get("columns", {}))) == 2, "Narrow personnel page keeps its two readable columns")
	screen.call("request_operation", "navigate", {"mode": "squad"})
	for width in [1600, 1920]:
		root.content_scale_size = Vector2i(width, 1080)
		root.size = Vector2i(width, 1080)
		await _settle_layout(operations)
		display = Dictionary(screen.call("get_operations_snapshot").get("presentation", {}))
		_assert(_visible_column_count(Dictionary(display.get("columns", {}))) == 4, "%d-wide squad keeps all four columns" % width)
		_assert(float(display.get("roster_minimum_name_width", 0.0)) >= 100.0 and bool(display.get("roster_role_status_single_line", false)), "%d-wide roster keeps readable names and single-line roles" % width)
	root.content_scale_size = original_scale_size
	root.size = original_window_size
	await _settle_layout(operations)
	screen.hide()
	await create_timer(0.35).timeout
	var hidden_refresh: int = int(Dictionary(screen.call("get_operations_snapshot").get("presentation", {})).get("refresh_count", 0))
	await create_timer(0.35).timeout
	_assert(int(Dictionary(screen.call("get_operations_snapshot").get("presentation", {})).get("refresh_count", 0)) == hidden_refresh, "Hidden presenter does not poll")
	screen.queue_free()
	await process_frame
	_finish()


func _settle_layout(operations: Control) -> void:
	for index in range(3):
		await process_frame
	operations.call("refresh")
	for index in range(2):
		await process_frame


func _visible_column_count(columns: Dictionary) -> int:
	var count: int = 0
	for value in columns.values():
		if bool(Dictionary(value).get("visible", false)):
			count += 1
	return count


func _owner_projection(snapshot: Dictionary) -> PackedByteArray:
	return var_to_bytes({"roster": snapshot.get("roster", []), "fireteams": snapshot.get("fireteams", []),
		"crafts": snapshot.get("crafts", []), "mission_id": snapshot.get("mission_id", "")})


func _unit(snapshot: Dictionary, id: String) -> Dictionary:
	for unit_variant in Array(snapshot.get("roster", [])):
		var unit: Dictionary = Dictionary(unit_variant)
		if String(unit.get("id", "")) == id:
			return unit
	return {}


func _assert(ok: bool, message: String) -> void:
	if ok:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)


func _finish() -> void:
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	print("HOMEBASE_OPERATIONS_VERIFY_PASS" if _failed == 0 else "HOMEBASE_OPERATIONS_VERIFY_FAIL")
	quit(0 if _failed == 0 else 1)
