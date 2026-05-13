extends SceneTree

const HOMEBASE_TEST_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/meta/drop_light_layout_contract.gd")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

const DROPSHIP_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_382 Homebase Direct Mission Flightdeck Display Verifier ===")
	await _test_homebase_loadout_window_is_retired()
	await _test_shipcard_shows_dropped_fireteam_and_dispatches_to_mission()
	await _test_shipcard_fob_toggle_keeps_legacy_transfer_send()

	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_382: FAILED")
		quit(1)
	else:
		print("TASK_382: ALL PASSED")
		quit(0)


func _test_homebase_loadout_window_is_retired() -> void:
	var screen: Control = await _build_screen()
	var layout: Dictionary = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_homebase_layout")
	var loadout_panel := screen.get_node("Panel/Margin/VBox/ContentRow/HomebaseLoadoutPanel") as Control
	var snapshot: Dictionary = Dictionary(screen.call("get_homebase_direct_staging_snapshot"))
	_assert(not layout.has("loadout"), "Homebase fixed layout no longer reserves #13 LOADOUT")
	_assert(not loadout_panel.visible and bool(loadout_panel.get_meta("homebase_loadout_window_retired", false)), "#13 LOADOUT is hidden as a retired compatibility node")
	_assert(not bool(snapshot.get("loadout_panel_visible", true)), "Homebase snapshot reports the retired loadout window hidden")

	screen.queue_free()
	await process_frame


func _test_shipcard_shows_dropped_fireteam_and_dispatches_to_mission() -> void:
	var screen: Control = await _build_screen()
	_drop_fireteam_on_shipcard(screen, "ft1", "dropship_alpha")
	await process_frame
	await process_frame
	screen.call("_debug_advance_homebase_direct_boarding", 9.2)
	await process_frame
	await process_frame

	var payload_panel := _find_shipcard_payload_panel(screen, "dropship_alpha")
	var payload_rows: Array = _find_shipcard_payload_rows(screen, "dropship_alpha")
	var toggle := _find_shipcard_dispatch_toggle(screen, "dropship_alpha")
	var send_button := _find_shipcard_send_button(screen, "dropship_alpha")
	var snapshot: Dictionary = Dictionary(screen.call("get_homebase_direct_staging_snapshot"))
	_assert(payload_panel != null, "Dropped fireteam is shown directly on the Dropship shipcard")
	_assert(payload_rows.size() == 1 and String((payload_rows[0] as Control).get_meta("fireteam_id", "")) == "ft1", "Shipcard payload row identifies the boarded fireteam")
	_assert(String(snapshot.get("payload_craft_id", "")).strip_edges() == "dropship_alpha", "Direct payload is bound to the dropship card that received the drop")
	_assert(toggle != null and toggle.button_pressed, "Shipcard destination checkbox defaults to straight-to-Mission after boarding")
	_assert(send_button != null and not send_button.disabled and String(send_button.get_meta("homebase_shipcard_send_target", "")) == "mission", "Shipcard Send targets Mission when the checkbox is active")

	var events := {"mission": 0, "transfer": 0}
	screen.mission_start_requested.connect(func(): events["mission"] = int(events["mission"]) + 1)
	screen.aircraft_pilot_transfer_requested.connect(func(_craft_id, _pilot_id): events["transfer"] = int(events["transfer"]) + 1)
	screen.call("_on_send_pilot_button_pressed", "dropship_alpha")
	await process_frame

	_assert(int(events["mission"]) == 1, "Mission-target Send emits mission_start_requested")
	_assert(int(events["transfer"]) == 0, "Mission-target Send does not send the craft to FOB")

	screen.queue_free()
	await process_frame


func _test_shipcard_fob_toggle_keeps_legacy_transfer_send() -> void:
	var screen: Control = await _build_screen()
	_drop_fireteam_on_shipcard(screen, "ft1", "dropship_alpha")
	await process_frame
	screen.call("_debug_advance_homebase_direct_boarding", 9.2)
	await process_frame
	screen.call("_on_shipcard_dispatch_target_toggled", false, "dropship_alpha")
	await process_frame
	await process_frame

	var toggle := _find_shipcard_dispatch_toggle(screen, "dropship_alpha")
	var send_button := _find_shipcard_send_button(screen, "dropship_alpha")
	_assert(toggle != null and not toggle.button_pressed, "Turning off the checkbox selects FOB dispatch")
	_assert(send_button != null and not send_button.disabled and String(send_button.get_meta("homebase_shipcard_send_target", "")) == "fob", "Shipcard Send targets FOB when the checkbox is off")

	var events := {"mission": 0, "transfer": 0}
	screen.mission_start_requested.connect(func(): events["mission"] = int(events["mission"]) + 1)
	screen.aircraft_pilot_transfer_requested.connect(func(_craft_id, _pilot_id): events["transfer"] = int(events["transfer"]) + 1)
	screen.call("_on_send_pilot_button_pressed", "dropship_alpha")
	await process_frame

	_assert(int(events["mission"]) == 0, "FOB-target Send does not start the mission")
	_assert(int(events["transfer"]) == 1, "FOB-target Send keeps the existing aircraft transfer signal")

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
				"display_name": "Dropship",
				"texture_path": DROPSHIP_TEXTURE_PATH,
				"supports_cargo": false,
				"cargo_options": [],
			}
		],
		{"dropship_alpha": "unit_delta"},
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
	for node in _collect_nodes(screen.get_node("Panel/Margin/VBox/ContentRow/AircraftPanel")):
		if node is Control \
			and bool((node as Control).get_meta("homebase_fireteam_drop_target", false)) \
			and String((node as Control).get_meta("homebase_fireteam_drop_target_id", "")).strip_edges() == craft_id:
			return node as Control
	return null


func _find_shipcard_payload_panel(screen: Control, craft_id: String) -> Control:
	for node in _collect_nodes(screen.get_node("Panel/Margin/VBox/ContentRow/AircraftPanel")):
		if node is Control \
			and bool((node as Control).get_meta("homebase_shipcard_payload_panel", false)) \
			and String((node as Control).get_meta("craft_id", "")).strip_edges() == craft_id:
			return node as Control
	return null


func _find_shipcard_payload_rows(screen: Control, craft_id: String) -> Array:
	var rows: Array = []
	for node in _collect_nodes(screen.get_node("Panel/Margin/VBox/ContentRow/AircraftPanel")):
		if node is Control \
			and bool((node as Control).get_meta("homebase_shipcard_payload_row", false)) \
			and String((node as Control).get_meta("craft_id", "")).strip_edges() == craft_id:
			rows.append(node)
	return rows


func _find_shipcard_dispatch_toggle(screen: Control, craft_id: String) -> CheckBox:
	for node in _collect_nodes(screen.get_node("Panel/Margin/VBox/ContentRow/AircraftPanel")):
		if node is CheckBox \
			and bool((node as CheckBox).get_meta("homebase_shipcard_dispatch_toggle", false)) \
			and String((node as CheckBox).get_meta("craft_id", "")).strip_edges() == craft_id:
			return node as CheckBox
	return null


func _find_shipcard_send_button(screen: Control, craft_id: String) -> Button:
	for node in _collect_nodes(screen.get_node("Panel/Margin/VBox/ContentRow/AircraftPanel")):
		if node is Button \
			and String((node as Button).get_meta("homebase_shipcard_send_target", "")).strip_edges() in ["mission", "fob"]:
			var parent := (node as Button).get_parent()
			if parent != null and _node_tree_has_craft_id(parent, craft_id):
				return node as Button
	return null


func _node_tree_has_craft_id(node: Node, craft_id: String) -> bool:
	var current := node
	while current != null:
		if current is Control and String((current as Control).get_meta("homebase_fireteam_drop_target_id", "")).strip_edges() == craft_id:
			return true
		current = current.get_parent()
	return false


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
