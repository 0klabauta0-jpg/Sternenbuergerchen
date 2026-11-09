extends SceneTree

const SCREEN: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const PRESETS: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")
var passed: int = 0
var failed: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var screen: Control = SCREEN.instantiate()
	root.add_child(screen)
	await process_frame
	screen.set("_selected_mission_slot_count", 8)
	var roster: Array = PRESETS.get_homebase_roster()
	for index in range(roster.size()):
		var entry: Dictionary = Dictionary(roster[index])
		entry["progression"] = {"total_xp": 1500 if String(entry.get("unit_id", "")) == "unit_charlie" else 100}
		if String(entry.get("unit_id", "")) in ["unit_alpha", "unit_bravo"]:
			entry["display_name"] = "Same Name"
		roster[index] = entry
	var original: PackedByteArray = var_to_bytes(roster)
	screen.call("setup_roster", roster, PackedStringArray(["unit_alpha", "unit_bravo"]))
	screen.call("set_fireteam_context", PackedStringArray(["ft1", "ft1"]), [{"id": "ft1", "label": "ALPHA", "lead_unit_id": "unit_alpha", "loadout": "medium"}])
	screen.call("set_transport_state", [{"craft_id": "dropship_alpha", "craft_type": "dropship", "display_name": "Cutlass", "supports_cargo": false}], {"dropship_alpha": "unit_delta"}, [], [], {"dropship_alpha": "homebase"}, {}, {}, [])
	var operations: Control = screen.get_node("OperationsRoot")
	operations.call("refresh")
	var creates_before: int = int(operations.get("_row_create_count"))
	var sort_result: Dictionary = screen.call("request_operation", "sort_roster", {"sort_mode": "xp_desc"})
	_expect(bool(sort_result.get("ok", false)), "Operations reuses existing XP sorting")
	_expect(String(Dictionary(Array(screen.call("get_operations_snapshot").get("roster", []))[0]).get("id", "")) == "unit_charlie", "Most experienced fixture person is first in confirmed projection")
	var ids: Array = []
	for person in Array(screen.call("get_operations_snapshot").get("roster", [])):
		ids.append(String(Dictionary(person).get("id", "")))
	_expect(ids.find("unit_alpha") < ids.find("unit_bravo"), "Equal XP and name use stable real ID tie-break")
	_expect(not bool(screen.call("request_operation", "sort_roster", {"sort_mode": "invented"}).get("ok", true)), "Unknown roster ordering rejected")
	_expect(bool(screen.call("request_operation", "sort_roster", {"sort_mode": "badge"}).get("ok", false)), "Role badge ordering is available without invented ranks")
	_expect(int(operations.get("_row_create_count")) == creates_before, "Sorting reorders cached rows without rebuilding controls")
	var rows: Dictionary = operations.get("_rows")
	var alpha: Dictionary = Dictionary(rows.get("unit_alpha", {}))
	var alpha_root: Control = alpha.get("root")
	_expect(alpha_root != null and alpha_root.has_method("get_drag_payload"), "Operations person row is a real drag source")
	if alpha_root != null and alpha_root.has_method("get_drag_payload"):
		_expect(Dictionary(alpha_root.call("get_drag_payload")).get("unit_id", "") == "unit_alpha", "Dragged person uses stable real unit ID")
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		click.double_click = false
		(alpha.focus as Control).gui_input.emit(click)
		_expect(not bool(screen.get("_character_sheet_open")), "Single click does not open character sheet")
		click.double_click = true
		(alpha.focus as Control).gui_input.emit(click)
		_expect(bool(screen.get("_character_sheet_open")), "Double click opens existing character sheet path")
		screen.set("_character_sheet_open", false)
		screen.call("_update_character_sheet_visibility")
	screen.call("request_operation", "add_fireteam")
	var new_id: String = String(screen.call("get_operations_snapshot").get("focused_fireteam_id", ""))
	_expect(not new_id.is_empty() and new_id != "ft1", "New group is immediately selectable")
	var slots: Array = operations.get("_slots")
	var target: Control = Dictionary(slots[0]).root
	var payload: Dictionary = {"type": "homebase_unit_card", "unit_id": "unit_alpha", "source_context": "operations"}
	if target.has_method("_can_drop_data"):
		_expect(bool(target.call("_can_drop_data", Vector2.ZERO, payload)), "Empty new-team slot accepts real person drag")
		target.call("_drop_data", Vector2.ZERO, payload)
	else:
		_expect(false, "Team slot implements native drag/drop target")
	var snapshot: Dictionary = screen.call("get_operations_snapshot")
	_expect(String(_person(snapshot, "unit_alpha").get("fireteam_id", "")) == new_id, "Drop moves person into new group")
	_expect(_membership_count(snapshot, "unit_alpha") == 1, "Move never duplicates membership")
	var return_target: Control = operations.get("_roster_return_target")
	_expect(return_target != null, "Roster has an explicit person return drop area")
	if return_target != null:
		return_target.call("_drop_data", Vector2.ZERO, payload)
		_expect(String(_person(screen.call("get_operations_snapshot"), "unit_alpha").get("fireteam_id", "")) == "", "Dropping back removes last member from group")
	screen.call("request_operation", "assign", {"unit_id": "unit_alpha", "fireteam_id": "ft1"})
	screen.call("request_operation", "assign", {"unit_id": "unit_charlie", "fireteam_id": "ft1"})
	screen.call("request_operation", "assign", {"unit_id": "unit_echo", "fireteam_id": "ft1"})
	_expect(String(screen.call("request_operation", "assign", {"unit_id": "unit_foxtrot", "fireteam_id": "ft1"}).get("reason", "")) == "team_full", "Full team rejects fifth member concretely")
	screen.call("request_operation", "focus_fireteam", {"fireteam_id": "ft1"})
	var equipment: Dictionary = operations.get("_equipment_slots") if operations.get("_equipment_slots") != null else {}
	_expect(equipment.has("armor") and equipment.has("weapon_1") and equipment.has("weapon_2"), "Three visible equipment slots accept validated loadout items")
	if equipment.has("armor"):
		screen.call("request_operation", "focus_unit", {"unit_id": "unit_alpha"})
		var armor: Control = equipment.armor
		armor.call("_drop_data", Vector2.ZERO, {"type": "homebase_loadout_item", "key": "armor", "item_id": "heavy"})
		_expect(String(Dictionary(_person(screen.call("get_operations_snapshot"), "unit_alpha").get("loadout", {})).get("armor", "")) == "heavy", "Equipment drop commits existing member loadout")
		armor.call("_drop_data", Vector2.ZERO, {"type": "homebase_loadout_item", "key": "armor", "item_id": "invented"})
		_expect(String(Dictionary(_person(screen.call("get_operations_snapshot"), "unit_alpha").get("loadout", {})).get("armor", "")) == "heavy", "Unknown item cannot overwrite confirmed gear")
	var craft_target: Control = operations.get("_craft_drop_target")
	_expect(craft_target != null, "Real craft projection is a fireteam drop target")
	if craft_target != null:
		craft_target.call("_drop_data", Vector2.ZERO, {"type": "fob_fireteam_card", "fireteam_id": "ft1"})
		_expect(Array(Dictionary(screen.call("get_operations_snapshot").get("selected_craft", {})).get("payload_fireteam_ids", [])).has("ft1"), "Fireteam drop boards real craft payload")
		screen.call("_debug_advance_homebase_direct_boarding", 30.0)
		screen.call("configure_singleplayer_bridge", _bridge_snapshot, _reject_departure)
		_expect(String(Dictionary(Dictionary(screen.call("get_operations_snapshot").get("singleplayer", {})).get("campaign", {})).get("selected_location_id", "")) == "satellite_crash", "Operations projects bound campaign snapshot")
		_expect(String(screen.call("request_operation", "start", {"craft_id": "dropship_alpha"}).get("reason", "")) == "insufficient_fuel", "Departure rejects resource-owner failure before transport dispatch")
		_expect(not bool(Dictionary(screen.call("get_operations_snapshot").get("selected_craft", {})).get("busy", true)), "Rejected departure leaves craft at base")
		screen.call("configure_singleplayer_bridge", Callable(), Callable())
	_expect(not bool(screen.call("request_operation", "remove", {"unit_id": "unit_alpha"}).get("ok", true)), "Boarding member remains protected")
	_expect(bool(screen.call("request_operation", "assign", {"unit_id": "unit_foxtrot", "fireteam_id": new_id}).get("ok", false)), "Independent free group stays editable")
	_expect(not bool(screen.call("request_operation", "assign", {"unit_id": "unit_delta", "fireteam_id": new_id}).get("ok", true)), "Assigned pilot cannot silently become team member")
	_expect(bool(screen.call("request_operation", "pilot", {"unit_id": "", "craft_id": "dropship_alpha"}).get("ok", false)), "Existing pilot release operation succeeds")
	_expect(bool(screen.call("request_operation", "assign", {"unit_id": "unit_delta", "fireteam_id": new_id}).get("ok", false)), "Released pilot is available for independent team")
	screen.call("set_transport_state", [{"craft_id": "dropship_alpha", "craft_type": "dropship", "is_in_transit": true, "mission_transit_to_map": true}], {}, [], [], {"dropship_alpha": "mission"}, {}, {}, [])
	_expect(not bool(screen.call("request_operation", "unboard", {"fireteam_id": "ft1", "craft_id": "dropship_alpha"}).get("ok", true)), "Transit craft rejects payload removal")
	_expect(not bool(screen.call("request_operation", "loadout", {"unit_id": "unit_alpha", "key": "armor", "value": "light"}).get("ok", true)), "Transit payload rejects equipment changes")
	_expect(bool(screen.call("request_operation", "remove", {"unit_id": "unit_foxtrot"}).get("ok", false)), "Independent free group stays editable during another craft transit")
	_expect(var_to_bytes(roster) == original, "Original identities and portraits are preserved")
	screen.call("request_operation", "navigate", {"mode": "personnel"})
	_expect(not bool(Dictionary(screen.call("get_operations_snapshot").get("presentation", {})).get("reference_stage_visible", true)), "Personnel contains no craft backdrop")
	screen.queue_free()
	await process_frame
	print("PERSONNEL_DRAGDROP_20261109: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

func _person(snapshot: Dictionary, id: String) -> Dictionary:
	for person in Array(snapshot.get("roster", [])):
		if String(Dictionary(person).get("id", "")) == id:
			return Dictionary(person)
	return {}

func _bridge_snapshot() -> Dictionary:
	return {"campaign": {"selected_location_id": "satellite_crash"}, "supply": {}}

func _reject_departure(_operation: String, _payload: Dictionary) -> Dictionary:
	return {"ok": false, "reason": "insufficient_fuel", "message": "Treibstoff fehlt"}

func _membership_count(snapshot: Dictionary, id: String) -> int:
	var count: int = 0
	for team in Array(snapshot.get("fireteams", [])):
		for person in Array(Dictionary(team).get("members", [])):
			if String(Dictionary(person).get("id", "")) == id:
				count += 1
	return count

func _expect(value: bool, message: String) -> void:
	if value:
		passed += 1
		print("PASS: " + message)
	else:
		failed += 1
		print("FAIL: " + message)
