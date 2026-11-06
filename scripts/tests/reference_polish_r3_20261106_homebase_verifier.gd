extends SceneTree
## Synthetic presentation fixtures over the real one-built presenter.
## No timers, actors, saved rosters, transport managers, or native visual claim.

const PRESENTER: GDScript = preload("res://scripts/meta/homebase_operations_presenter.gd")
const BASE_STAGE := "res://Assets/curated/main_menu/frontier_outpost_main_20261101.png"
const REF03_PREVIEW := "res://Assets/curated/ui_native_r4/cutlass_ref03_preview.png"

class SnapshotOwner extends Control:
	var snapshot: Dictionary = {}
	var operations: Array = []
	func get_operations_snapshot() -> Dictionary:
		return snapshot.duplicate(true)
	func request_operation(operation: String, payload: Dictionary) -> Dictionary:
		operations.append({"operation": operation, "payload": payload.duplicate(true)})
		return {"ok": true, "message": ""}

var _passed := 0
var _failed := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("REFERENCE_POLISH_R3_HOMEBASE_VERIFY_BEGIN")
	var owner := SnapshotOwner.new()
	owner.snapshot = _snapshot(_craft())
	root.add_child(owner)
	owner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var presenter: Control = PRESENTER.new()
	presenter.call("configure", owner)
	owner.add_child(presenter)
	await process_frame
	presenter.set_process(false)
	var instances := _control_instances(presenter)
	for dimensions in [Vector2i(3440, 1440), Vector2i(1920, 1080), Vector2i(1600, 1080)]:
		await _resize(owner, presenter, dimensions, "squad")
		_check_wide_composition(presenter, dimensions)
		_check_flight_controls(presenter, dimensions, "wide_%d" % dimensions.x)
		_check(_control_instances(presenter) == instances, "%d resize reuses the existing selectors, actions, rows and active ship preview" % dimensions.x)
	await _resize(owner, presenter, Vector2i(1280, 720), "squad")
	var display: Dictionary = presenter.call("get_presentation_snapshot")
	var columns: Dictionary = Dictionary(display.get("columns", {}))
	_check(_visible_count(columns) == 3 and not bool(Dictionary(columns.get("flight", {})).get("visible", true)), "1280 squad keeps three preparation roles and the existing flight navigation")
	_check(not bool(display.get("reference_stage_visible", true)), "1280 squad does not cover preparation with the passive scene")
	_check(float(display.get("roster_minimum_name_width", 0.0)) >= 100.0 and bool(display.get("roster_role_status_single_line", false)), "1280 keeps real name width and single-line role/status text")
	_check(bool(display.get("mission_navigation_visible", false)) and _root_rect(Vector2i(1280, 720)).encloses(Rect2(display.get("mission_navigation_rect", Rect2()))), "1280 keeps the existing flight navigation fully inside the screen")
	await _resize(owner, presenter, Vector2i(1280, 720), "mission")
	display = presenter.call("get_presentation_snapshot")
	columns = Dictionary(display.get("columns", {}))
	_check(_visible_count(columns) == 3 and bool(Dictionary(columns.get("flight", {})).get("visible", false)), "1280 mission uses the existing team, equipment and flight roles")
	_check_flight_controls(presenter, Vector2i(1280, 720), "narrow_mission")
	_check_stage(presenter, Vector2i(1280, 720), false)
	_check(_control_instances(presenter) == instances, "Narrow navigation retains the same action/selector/row instances")
	await _resize(owner, presenter, Vector2i(1920, 1080), "squad")
	_check_state_projection(owner, presenter)
	_check_callback_routes(owner, presenter)
	owner.queue_free()
	for _index in range(2):
		await process_frame
	print("REFERENCE_POLISH_R3_HOMEBASE: %d passed, %d failed" % [_passed, _failed])
	if _failed == 0:
		print("REFERENCE_POLISH_R3_HOMEBASE_VERIFY_PASS")
	quit(1 if _failed > 0 else 0)


func _resize(owner: SnapshotOwner, presenter: Control, dimensions: Vector2i, mode: String) -> void:
	root.content_scale_size = dimensions
	root.size = dimensions
	owner.snapshot["mode"] = mode
	for _index in range(3):
		await process_frame
	var before := var_to_bytes(owner.snapshot)
	var operations_before := owner.operations.size()
	presenter.call("refresh")
	presenter.call("_layout_columns")
	for _index in range(3):
		await process_frame
	_check(root.get_visible_rect().size.is_equal_approx(Vector2(dimensions)), "%dx%d %s uses the requested logical viewport" % [dimensions.x, dimensions.y, mode])
	_check(_root_rect(dimensions).encloses((presenter.get("_workspace") as Control).get_global_rect()), "%dx%d %s keeps the complete workspace within the actual viewport" % [dimensions.x, dimensions.y, mode])
	if dimensions.x == 1280:
		_dump_layout(owner, presenter, mode)
	_check(var_to_bytes(owner.snapshot) == before and owner.operations.size() == operations_before, "%dx%d %s layout/refresh is a read-only projection" % [dimensions.x, dimensions.y, mode])


func _dump_layout(owner: Control, presenter: Control, mode: String) -> void:
	var facts: Dictionary = {"mode": mode, "window_size": root.size, "content_scale_size": root.content_scale_size, "logical_viewport": root.get_visible_rect(), "owner_rect": owner.get_global_rect(), "presenter_rect": presenter.get_global_rect(), "workspace_rect": (presenter.get("_workspace") as Control).get_global_rect()}
	var controls: Dictionary = {"mission_navigation": Dictionary(presenter.get("_nav")).get("mission")}
	for key in ["_mission_selector", "_craft_selector", "_pilot_selector", "_board", "_start"]:
		controls[key] = presenter.get(key)
	for key in controls:
		var control: Control = controls[key] as Control
		var ancestors: Array = []
		var ancestor := control.get_parent()
		while ancestor is Control:
			var item := ancestor as Control
			ancestors.append({"name": item.name, "rect": item.get_global_rect(), "minimum": item.get_combined_minimum_size(), "clip": item.clip_contents})
			ancestor = ancestor.get_parent()
		facts[key] = {"rect": control.get_global_rect(), "visible": control.is_visible_in_tree(), "minimum": control.get_combined_minimum_size(), "ancestors": ancestors}
	print("HOMEBASE_LAYOUT_FACTS ", facts)


func _check_wide_composition(presenter: Control, dimensions: Vector2i) -> void:
	var display: Dictionary = presenter.call("get_presentation_snapshot")
	var columns: Dictionary = Dictionary(display.get("columns", {}))
	_check(_visible_count(columns) == 4, "%d keeps all existing work roles visible" % dimensions.x)
	var roster := Rect2(Dictionary(columns.get("roster", {})).get("rect", Rect2()))
	var squad := Rect2(Dictionary(columns.get("squad", {})).get("rect", Rect2()))
	var equipment := Rect2(Dictionary(columns.get("equipment", {})).get("rect", Rect2()))
	var flight := Rect2(Dictionary(columns.get("flight", {})).get("rect", Rect2()))
	var portrait := Rect2(display.get("focused_portrait_rect", Rect2()))
	_check(is_equal_approx(portrait.size.x, portrait.size.y) and portrait.size.x >= 176.0, "%d keeps the focused identity a large square portrait" % dimensions.x)
	_check(int(display.get("focused_portrait_stretch_mode", -1)) == TextureRect.STRETCH_KEEP_ASPECT_CENTERED and equipment.encloses(portrait), "%d keeps the full focused portrait inside the equipment card" % dimensions.x)
	var workspace: Control = presenter.get("_workspace") as Control
	_check(roster.position.x - workspace.global_position.x <= 24.0, "%d starts personnel near the workspace edge instead of an ultrawide empty gutter" % dimensions.x)
	_check(roster.end.x <= squad.position.x + 1.0 and squad.end.x <= equipment.position.x + 1.0, "%d retains left-to-right personnel, team and focused identity" % dimensions.x)
	_check(flight.size.x > equipment.size.x * 1.4 and flight.position.y >= equipment.end.y - 1.0, "%d uses a broad boarding footer below the focused equipment card" % dimensions.x)
	_check(not flight.intersects(roster) and not flight.intersects(squad), "%d flight footer never covers the left work roles" % dimensions.x)
	_check(_root_rect(dimensions).encloses(roster) and _root_rect(dimensions).encloses(squad) and _root_rect(dimensions).encloses(equipment) and _root_rect(dimensions).encloses(flight), "%d keeps every existing work role inside the actual screen" % dimensions.x)
	_check_stage(presenter, dimensions, true)


func _check_stage(presenter: Control, dimensions: Vector2i, wide: bool) -> void:
	var display: Dictionary = presenter.call("get_presentation_snapshot")
	_check(bool(display.get("reference_stage_visible", false)), "%d shows the passive native basis stage" % dimensions.x)
	var stage := presenter.find_child("ReferenceBaseStage", true, false) as Control
	_check(stage != null, "%d has a real native scene surface rather than a metadata-only claim" % dimensions.x)
	if stage == null:
		return
	_check(stage.is_visible_in_tree() and stage.mouse_filter == Control.MOUSE_FILTER_IGNORE and bool(stage.get_meta("visual_only", false)), "%d basis stage is visible and never handles input" % dimensions.x)
	_check(String(stage.get_meta("source_resource", "")) == BASE_STAGE and String(stage.get_meta("image_status", "")) == "static_native_capture", "%d identifies the actual static native basis source" % dimensions.x)
	var background := stage.find_child("BaseImage", true, false) as TextureRect
	_check(background != null and background.texture != null and background.texture.resource_path == BASE_STAGE, "%d actually uses the declared native capture texture" % dimensions.x)
	var caption := stage.find_child("StageCaption", true, false) as Label
	_check(caption != null and caption.text.contains("Basisansicht"), "%d labels the static stage as a basis view instead of current boarding or actors" % dimensions.x)
	var image: TextureRect = presenter.get("_craft_image") as TextureRect
	_check(String(image.get_meta("rendered_path", "")) == REF03_PREVIEW and image.texture != null and image.texture.resource_path == REF03_PREVIEW, "%d active ship preview remains the exact selected native Ref03 image" % dimensions.x)
	_check(image.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED and stage.get_global_rect().encloses(image.get_global_rect()), "%d keeps the complete active silhouette within its scene preview" % dimensions.x)
	_check(_root_rect(dimensions).encloses(stage.get_global_rect()), "%d scene surface remains inside the actual screen" % dimensions.x)
	var columns: Dictionary = Dictionary(display.get("columns", {}))
	for key in ["roster", "squad", "equipment", "flight"]:
		var entry: Dictionary = Dictionary(columns.get(key, {}))
		if bool(entry.get("visible", false)):
			_check(not stage.get_global_rect().intersects(Rect2(entry.get("rect", Rect2()))), "%d scene surface does not cover %s controls" % [dimensions.x, key])
	if wide:
		var workspace: Control = presenter.get("_workspace") as Control
		_check(stage.size.x >= workspace.size.x * 0.20 and stage.size.y >= workspace.size.y * 0.40, "%d gives the scene a meaningful share of the composition" % dimensions.x)


func _check_flight_controls(presenter: Control, dimensions: Vector2i, label: String) -> void:
	for key in ["_mission_selector", "_craft_selector", "_pilot_selector", "_board", "_start"]:
		var control: Control = presenter.get(key) as Control
		_check(_control_fully_visible(control, dimensions), "%s keeps %s fully reachable without a hidden footer scroll" % [label, key])
	var unboard: Control = presenter.get("_unboard") as Control
	if unboard.visible:
		_check(_control_fully_visible(unboard, dimensions), "%s keeps the current return action fully reachable" % label)


func _check_state_projection(owner: SnapshotOwner, presenter: Control) -> void:
	var cases: Array[Dictionary] = [
		{"id": "empty", "craft": {}},
		{"id": "missing_pilot", "craft": _craft({"pilot_id": "", "status": "Pilot fehlt", "can_board": false, "next_step": "Pilot auswählen"})},
		{"id": "preparing", "craft": _craft()},
		{"id": "boarding", "craft": _craft({"has_payload": true, "can_board": false, "progress": 37.0, "status": "Boarding läuft", "next_step": "Boarding abwarten"})},
		{"id": "ready", "craft": _craft({"has_payload": true, "can_board": false, "can_unboard": true, "can_start": true, "progress": 100.0, "status": "Bereit", "next_step": "Einsatz starten"})},
		{"id": "transit", "craft": _craft({"busy": true, "can_board": false, "has_payload": true, "progress": 43.0, "status": "Unterwegs", "next_step": "Rückkehr abwarten"})},
	]
	var instances := _control_instances(presenter)
	for spec in cases:
		var craft: Dictionary = spec.craft
		owner.snapshot = _snapshot(craft)
		var before := var_to_bytes(owner.snapshot)
		var count := owner.operations.size()
		presenter.call("refresh")
		_check(var_to_bytes(owner.snapshot) == before and owner.operations.size() == count, "%s display never writes owner data or sends operations" % spec.id)
		_check((presenter.get("_craft_status") as Label).text == String(craft.get("status", "Kein Schiff verfügbar")), "%s shows the precise owner status text" % spec.id)
		_check((presenter.get("_board") as Button).disabled == (not bool(craft.get("can_board", false))), "%s preserves boarding permission" % spec.id)
		_check((presenter.get("_start") as Button).disabled == (not bool(craft.get("can_start", false))), "%s preserves launch permission" % spec.id)
		_check((presenter.get("_unboard") as Button).disabled == (not bool(craft.get("can_unboard", false))) and (presenter.get("_unboard") as Button).visible == bool(craft.get("has_payload", false)), "%s preserves return permission and payload visibility" % spec.id)
		_check(is_equal_approx((presenter.get("_progress") as ProgressBar).value, float(craft.get("progress", 0.0))), "%s shows only the real progress" % spec.id)
		_check((presenter.get("_pilot_selector") as OptionButton).disabled == (craft.is_empty() or bool(craft.get("busy", false))), "%s keeps pilot editability at its owner gate" % spec.id)
		var image: TextureRect = presenter.get("_craft_image") as TextureRect
		_check((image.texture == null) if craft.is_empty() else (String(image.get_meta("rendered_path", "")) == REF03_PREVIEW), "%s never fabricates a selected replacement ship" % spec.id)
		_check(_control_instances(presenter) == instances, "%s keeps the one-built control and roster instances" % spec.id)
	owner.snapshot = _snapshot(_craft())
	owner.snapshot["focused_unit"] = {}
	owner.snapshot["focused_fireteam"]["members"] = []
	presenter.call("refresh")
	_check((presenter.get("_focused_portrait") as TextureRect).texture == null and (presenter.get("_focused_details") as Button).disabled, "Empty focus has no invented portrait or enabled details")
	for key in Dictionary(presenter.get("_selectors")):
		_check((Dictionary(presenter.get("_selectors"))[key] as OptionButton).disabled, "Empty focus disables %s via the existing input gate" % key)
	owner.snapshot = _snapshot(_craft())
	presenter.call("refresh")


func _check_callback_routes(owner: SnapshotOwner, presenter: Control) -> void:
	var signature := _control_instances(presenter)
	var selectors: Dictionary = presenter.get("_selectors")
	for spec in [{"field": "armor", "expected": "heavy"}, {"field": "weapon_1", "expected": "smg"}, {"field": "weapon_2", "expected": "medictool"}]:
		var selector := selectors[String(spec.field)] as OptionButton
		var before := owner.operations.size()
		selector.item_selected.emit(1)
		_check(owner.operations.size() == before + 1 and Dictionary(owner.operations.back()).get("operation") == "loadout" and Dictionary(Dictionary(owner.operations.back()).get("payload", {})) == {"unit_id": "fixture_alpha", "key": String(spec.field), "value": String(spec.expected)}, "%s selector retains the existing operation and owner IDs" % spec.field)
	for spec in [{"field": "_mission_selector", "operation": "mission", "payload": {"mission_id": "other_mission"}}, {"field": "_craft_selector", "operation": "craft", "payload": {"craft_id": "fixture_second"}}, {"field": "_pilot_selector", "operation": "pilot", "payload": {"unit_id": "fixture_second_pilot", "craft_id": "fixture_cutlass"}}]:
		var selector: OptionButton = presenter.get(String(spec.field)) as OptionButton
		var before := owner.operations.size()
		selector.item_selected.emit(1)
		_check(owner.operations.size() == before + 1 and Dictionary(owner.operations.back()).get("operation") == String(spec.operation) and Dictionary(Dictionary(owner.operations.back()).get("payload", {})) == Dictionary(spec.payload), "%s selector delegates the original exact payload" % spec.operation)
	for spec in [{"field": "_focused_details", "operation": "details", "payload": {"unit_id": "fixture_alpha"}}, {"field": "_remove_member", "operation": "remove", "payload": {"unit_id": "fixture_alpha"}}, {"field": "_board", "operation": "board", "payload": {"fireteam_id": "ft1", "craft_id": "fixture_cutlass"}}]:
		_check_button_route(owner, presenter, spec)
	owner.snapshot = _snapshot(_craft({"has_payload": true, "can_board": false, "can_unboard": true, "can_start": true, "progress": 100.0}))
	presenter.call("refresh")
	for spec in [{"field": "_unboard", "operation": "unboard", "payload": {"fireteam_id": "ft1", "craft_id": "fixture_cutlass"}}, {"field": "_start", "operation": "start", "payload": {"craft_id": "fixture_cutlass"}}]:
		_check_button_route(owner, presenter, spec)
	_check(_control_instances(presenter) == signature, "Callback exercise never recreates controls or roster identities")
	for key in ["_mission_selector", "_craft_selector", "_pilot_selector"]:
		_check((presenter.get(key) as OptionButton).get_signal_connection_list("item_selected").size() == 1, "%s remains connected exactly once" % key)


func _check_button_route(owner: SnapshotOwner, presenter: Control, spec: Dictionary) -> void:
	var button: Button = presenter.get(String(spec.field)) as Button
	_check(not button.disabled, "%s callback fixture uses its actual enabled state" % spec.operation)
	var before := owner.operations.size()
	button.pressed.emit()
	_check(owner.operations.size() == before + 1 and Dictionary(owner.operations.back()).get("operation") == String(spec.operation) and Dictionary(Dictionary(owner.operations.back()).get("payload", {})) == Dictionary(spec.payload), "%s button keeps the existing operation and owner IDs" % spec.operation)


func _control_instances(presenter: Control) -> Dictionary:
	var result: Dictionary = {}
	for key in ["_craft_image", "_mission_selector", "_craft_selector", "_pilot_selector", "_start", "_board", "_unboard", "_focused_details", "_remove_member"]:
		result[key] = (presenter.get(key) as Node).get_instance_id()
	for key in Dictionary(presenter.get("_selectors")):
		result["loadout_" + String(key)] = (Dictionary(presenter.get("_selectors"))[key] as Node).get_instance_id()
	for key in Dictionary(presenter.get("_rows")):
		result["row_" + String(key)] = (Dictionary(Dictionary(presenter.get("_rows"))[key])["root"] as Node).get_instance_id()
	return result


func _control_fully_visible(control: Control, dimensions: Vector2i) -> bool:
	if control == null or not control.is_visible_in_tree() or control.size.x < 30.0 or control.size.y < 30.0 or not _root_rect(dimensions).encloses(control.get_global_rect()):
		return false
	var ancestor := control.get_parent()
	while ancestor != null:
		if ancestor is Control and (ancestor as Control).clip_contents and not (ancestor as Control).get_global_rect().encloses(control.get_global_rect()):
			return false
		ancestor = ancestor.get_parent()
	return true


func _root_rect(dimensions: Vector2i) -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(dimensions))


func _visible_count(columns: Dictionary) -> int:
	var count := 0
	for entry in columns.values():
		count += int(bool(Dictionary(entry).get("visible", false)))
	return count


func _snapshot(craft: Dictionary) -> Dictionary:
	var alpha := {"id": "fixture_alpha", "name": "Alexandra Lange-Hohenstein", "role": "Truppführung", "status": "Im Trupp", "portrait_path": "", "portrait_id": "char_portrait_001", "fireteam_id": "ft1", "can_assign": false, "can_remove": true, "can_edit": true, "loadout": {"armor": "medium", "weapon_1": "rifle", "weapon_2": "none"}}
	var bravo: Dictionary = alpha.duplicate(true)
	bravo.merge({"id": "fixture_bravo", "name": "Bora", "portrait_id": "char_portrait_002", "role": "Sanität"}, true)
	var charlie: Dictionary = alpha.duplicate(true)
	charlie.merge({"id": "fixture_charlie", "name": "Chen", "portrait_id": "char_portrait_003", "role": "Technik"}, true)
	var reserve: Dictionary = alpha.duplicate(true)
	reserve.merge({"id": "fixture_reserve", "name": "Daria", "portrait_id": "char_portrait_004", "fireteam_id": "", "can_assign": true, "can_remove": false, "can_edit": false, "status": "Bereit"}, true)
	var second: Dictionary = _craft({"id": "fixture_second", "name": "Second actual craft"})
	return {"mode": "squad", "roster": [alpha, bravo, charlie, reserve], "focused_unit": alpha, "focused_fireteam_id": "ft1", "focused_fireteam": {"id": "ft1", "label": "ALPHA", "members": [alpha, bravo, charlie], "busy": false}, "fireteams": [{"id": "ft1", "label": "ALPHA"}, {"id": "ft2", "label": "BRAVO"}], "selected_craft": craft, "crafts": [craft, second] if not craft.is_empty() else [], "mission_id": "grid_sweep", "missions": [{"id": "grid_sweep", "label": "Operation: Grid Sweep"}, {"id": "other_mission", "label": "Other mission"}], "loadout_options": {"armor": [{"id": "medium", "label": "Medium"}, {"id": "heavy", "label": "Heavy"}], "weapon_1": [{"id": "rifle", "label": "Rifle"}, {"id": "smg", "label": "SMG"}], "weapon_2": [{"id": "none", "label": "None"}, {"id": "medictool", "label": "Medictool"}]}}


func _craft(overrides: Dictionary = {}) -> Dictionary:
	var result := {"id": "fixture_cutlass", "name": "Cutlass 1", "texture_path": REF03_PREVIEW, "pilot_id": "fixture_pilot", "pilot_options": [{"id": "fixture_pilot", "label": "Pilot"}, {"id": "fixture_second_pilot", "label": "Second pilot"}], "busy": false, "status": "Vorbereitung", "can_start": false, "can_board": true, "can_unboard": false, "has_payload": false, "progress": 0.0, "passenger_count": 0, "next_step": "Boarding starten"}
	result.merge(overrides, true)
	return result


func _check(ok: bool, message: String) -> void:
	if ok:
		_passed += 1
		print("PASS: ", message)
	else:
		_failed += 1
		print("FAIL: ", message)
