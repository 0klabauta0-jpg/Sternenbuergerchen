extends SceneTree

const HOMEBASE_TEST_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

const DROPSHIP_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_386 Homebase Flightdeck Member Portraits Verifier ===")
	await _test_payload_member_rows_render_portraits_next_to_names()

	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_386: FAILED")
		quit(1)
	else:
		print("TASK_386: ALL PASSED")
		quit(0)


func _test_payload_member_rows_render_portraits_next_to_names() -> void:
	var screen: Control = await _build_screen()
	_drop_fireteam_on_shipcard(screen, "ft1", "dropship_alpha")
	await process_frame
	await process_frame

	var payload_card := _find_payload_fireteam_card(screen, "ft1")
	_assert(payload_card != null, "Dropship renders the Flightdeck fireteam card")
	_assert(_count_payload_mini_portraits(payload_card) == 2, "Payload card keeps one mini portrait per operator")
	_assert(not _has_payload_portrait_strip(payload_card), "Payload card no longer uses a separate portrait strip above the names")
	_assert(_member_row_has_left_portrait(payload_card, "unit_alpha", "Anja Voss"), "Alpha row shows the portrait directly left of the name")
	_assert(_member_row_has_left_portrait(payload_card, "unit_bravo", "Milo Saren"), "Bravo row shows the portrait directly left of the name")

	screen.queue_free()
	await process_frame


func _build_screen() -> Control:
	var screen: Control = HOMEBASE_TEST_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	var roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	screen.call("setup_roster", roster, PackedStringArray(["unit_alpha", "unit_bravo"]))
	screen.call(
		"set_fireteam_context",
		PackedStringArray(["ft1", "ft1"]),
		[
			{
				"id": "ft1",
				"label": "ALPHA",
				"lead_unit_id": "unit_alpha",
				"loadout": "medium",
				"respawn_enabled": false,
			}
		]
	)
	screen.call(
		"set_transport_state",
		[
			{
				"craft_id": "dropship_alpha",
				"craft_type": "dropship",
				"display_name": "Dropship Alpha",
				"texture_path": DROPSHIP_TEXTURE_PATH,
				"supports_cargo": false,
				"cargo_options": [],
			}
		],
		{"dropship_alpha": "unit_charlie"},
		[],
		[],
		{"dropship_alpha": "homebase"},
		{},
		{},
		[]
	)
	await process_frame
	await process_frame
	return screen


func _drop_fireteam_on_shipcard(screen: Control, fireteam_id: String, craft_id: String) -> void:
	var target := _find_shipcard_drop_target(screen, craft_id)
	if target == null:
		return
	target.call("_drop_data", Vector2.ZERO, {"type": "fob_fireteam_card", "fireteam_id": fireteam_id})


func _find_shipcard_drop_target(screen: Control, craft_id: String) -> Control:
	var aircraft_panel := screen.get_node("Panel/Margin/VBox/ContentRow/AircraftPanel") as Control
	for node in _collect_nodes(aircraft_panel):
		if node is Control \
			and bool((node as Control).get_meta("homebase_fireteam_drop_target", false)) \
			and String((node as Control).get_meta("homebase_fireteam_drop_target_id", "")).strip_edges() == craft_id:
			return node as Control
	return null


func _find_payload_fireteam_card(screen: Control, fireteam_id: String) -> Control:
	var aircraft_panel := screen.get_node_or_null("Panel/Margin/VBox/ContentRow/AircraftPanel") as Control
	if aircraft_panel == null:
		return null
	for node in _collect_nodes(aircraft_panel):
		if node is Control \
			and bool((node as Control).get_meta("homebase_shipcard_payload_fireteam_card", false)) \
			and String((node as Control).get_meta("fireteam_id", "")).strip_edges() == fireteam_id:
			return node as Control
	return null


func _count_payload_mini_portraits(payload_card: Control) -> int:
	var count := 0
	for node in _collect_nodes(payload_card):
		if node is TextureRect and bool((node as TextureRect).get_meta("homebase_shipcard_payload_mini_portrait", false)):
			count += 1
	return count


func _has_payload_portrait_strip(payload_card: Control) -> bool:
	for node in _collect_nodes(payload_card):
		if node is Control and bool((node as Control).get_meta("homebase_shipcard_payload_portrait_strip", false)):
			return true
	return false


func _member_row_has_left_portrait(payload_card: Control, unit_id: String, display_name: String) -> bool:
	var row := _find_member_row(payload_card, unit_id)
	if row == null or row.get_child_count() < 2:
		return false
	var portrait := row.get_child(0) as TextureRect
	var name_label := row.get_child(1) as Label
	if portrait == null or name_label == null:
		return false
	if not bool(portrait.get_meta("homebase_shipcard_payload_member_portrait", false)):
		return false
	if String(portrait.get_meta("unit_id", "")).strip_edges() != unit_id:
		return false
	if portrait.custom_minimum_size.x > 20.0 or portrait.custom_minimum_size.y > 20.0:
		return false
	return name_label.text == display_name


func _find_member_row(payload_card: Control, unit_id: String) -> HBoxContainer:
	for node in _collect_nodes(payload_card):
		var row := node as HBoxContainer
		if row != null \
			and bool(row.get_meta("homebase_shipcard_payload_member_row", false)) \
			and String(row.get_meta("unit_id", "")).strip_edges() == unit_id:
			return row
	return null


func _collect_nodes(root_node: Node) -> Array:
	var nodes: Array = []
	if root_node == null:
		return nodes
	nodes.append(root_node)
	for child in root_node.get_children():
		nodes.append_array(_collect_nodes(child))
	return nodes


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		print("  FAIL: %s" % message)
