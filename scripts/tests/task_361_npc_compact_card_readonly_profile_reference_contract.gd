extends SceneTree

const HOMEBASE_TEST_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const FOB_TEST_SCENE: PackedScene = preload("res://scenes/meta/fob_test_screen.tscn")
const META_UNIT_PROFILE_SCRIPT: GDScript = preload("res://scripts/meta/meta_unit_profile.gd")
const NPC_COMPACT_CARD_SCRIPT: GDScript = preload("res://scripts/meta/npc_compact_card.gd")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

const DROPSHIP_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png"

var _passed: int = 0
var _failed: int = 0
var _last_pressed_unit_id: String = ""
var _last_pressed_source_context: String = ""
var _last_pressed_profile = null
var _last_opened_unit_id: String = ""
var _last_opened_source_context: String = ""
var _last_opened_profile = null


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_361 NPCCompactCard Readonly Profile Reference Contract ===")
	await _test_copy_mode_remains_default_and_safe()
	await _test_readonly_mode_references_without_mutating()
	await _test_signal_and_drag_payloads_stay_safe()
	await _test_homebase_display_cards_opt_into_readonly_references()
	await _test_fob_display_cards_opt_into_readonly_references()

	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_361: FAILED")
		quit(1)
	else:
		print("TASK_361: ALL PASSED")
		quit(0)


func _test_copy_mode_remains_default_and_safe() -> void:
	var profile = _build_profile("task361_copy", "Copy Mode Alpha", "Original secondary")
	var card: Control = NPC_COMPACT_CARD_SCRIPT.new()
	root.add_child(card)
	card.call("setup_from_profile", profile, {"source_context": "copy_mode", "compact_mode": true})
	await process_frame

	var snapshot: Dictionary = Dictionary(card.call("get_profile_reference_contract_snapshot"))
	profile.display_name = "Mutated original"
	var card_profile = card.call("get_profile")
	card_profile.secondary_text = "Mutated external copy"
	var second_card_profile = card.call("get_profile")

	_assert(not bool(snapshot.get("uses_readonly_profile_reference", true)), "Default setup still copies incoming profile")
	_assert(String(second_card_profile.display_name) == "Copy Mode Alpha", "Copy-mode card ignores later original-profile mutation")
	_assert(String(second_card_profile.secondary_text) == "Original secondary", "get_profile returns an external copy in copy mode")

	card.queue_free()
	await process_frame


func _test_readonly_mode_references_without_mutating() -> void:
	var profile = _build_profile("task361_readonly", "Readonly Bravo", "Original secondary")
	var card: Control = NPC_COMPACT_CARD_SCRIPT.new()
	root.add_child(card)
	card.call(
		"setup_from_profile",
		profile,
		{
			"source_context": "homebase_loadout",
			"copy_profile": false,
			"secondary_text_override": "Lead",
			"compact_mode": true,
		}
	)
	await process_frame

	var snapshot: Dictionary = Dictionary(card.call("get_profile_reference_contract_snapshot"))
	var reference = card.call("get_profile_reference_for_readonly_display")
	var data_b_label := card.get_node("Margin/HBox/TextVBox/DataBLabel") as Label
	var external_profile = card.call("get_profile")
	external_profile.display_name = "External mutation"
	external_profile.secondary_text = "External secondary mutation"

	_assert(bool(snapshot.get("uses_readonly_profile_reference", false)), "Readonly setup stores the display reference")
	_assert(bool(snapshot.get("external_get_profile_returns_copy", false)), "Readonly contract keeps get_profile copy-safe")
	_assert(String(snapshot.get("secondary_text_override", "")) == "Lead", "Readonly setup records secondary-text override")
	_assert(reference == profile, "Readonly reference getter returns the original profile object")
	_assert(String(profile.secondary_text) == "Original secondary", "Readonly setup does not mutate source secondary text")
	_assert(data_b_label != null and data_b_label.text == "Lead", "Readonly card renders secondary-text override without profile mutation")
	_assert(String(card.call("get_profile").display_name) == "Readonly Bravo", "Mutating external get_profile result cannot mutate card reference")

	card.queue_free()
	await process_frame


func _test_signal_and_drag_payloads_stay_safe() -> void:
	_last_pressed_unit_id = ""
	_last_pressed_source_context = ""
	_last_pressed_profile = null
	_last_opened_unit_id = ""
	_last_opened_source_context = ""
	_last_opened_profile = null

	var profile = _build_profile("task361_signal", "Signal Charlie", "Original signal secondary")
	var card: Control = NPC_COMPACT_CARD_SCRIPT.new()
	root.add_child(card)
	card.call(
		"setup_from_profile",
		profile,
		{
			"source_context": "fob_fireteam",
			"copy_profile": false,
			"secondary_text_override": "Fireteam slot",
			"compact_mode": true,
			"drag_enabled": true,
		}
	)
	card.card_pressed.connect(_on_card_pressed)
	card.card_open_requested.connect(_on_card_open_requested)
	await process_frame

	var click_event := InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	card.call("_gui_input", click_event)

	_assert(_last_pressed_unit_id == "task361_signal", "Click signal carries unit id")
	_assert(_last_pressed_source_context == "fob_fireteam", "Click signal carries source context")
	_assert(_last_pressed_profile != null and String(_last_pressed_profile.display_name) == "Signal Charlie", "Click signal carries a profile copy")
	if _last_pressed_profile != null:
		_last_pressed_profile.display_name = "Pressed payload mutation"
	_assert(String(profile.display_name) == "Signal Charlie", "Mutating click payload cannot mutate readonly source profile")

	var double_click_event := InputEventMouseButton.new()
	double_click_event.button_index = MOUSE_BUTTON_LEFT
	double_click_event.pressed = true
	double_click_event.double_click = true
	card.call("_gui_input", double_click_event)

	_assert(_last_opened_unit_id == "task361_signal", "Double-click signal carries unit id for character sheet")
	_assert(_last_opened_source_context == "fob_fireteam", "Double-click signal carries source context")
	if _last_opened_profile != null:
		_last_opened_profile.secondary_text = "Opened payload mutation"
	_assert(String(profile.secondary_text) == "Original signal secondary", "Mutating double-click payload cannot mutate readonly source profile")

	var drag_payload: Dictionary = Dictionary(card.call("_get_drag_data", Vector2.ZERO))
	_assert(String(drag_payload.get("type", "")) == "homebase_unit_card", "Drag payload keeps compact-card drag type")
	_assert(String(drag_payload.get("unit_id", "")) == "task361_signal", "Drag payload carries unit id")
	_assert(String(drag_payload.get("source_context", "")) == "fob_fireteam", "Drag payload carries source context")
	_assert(not drag_payload.has("profile"), "Drag payload does not expose a mutable profile object")

	card.queue_free()
	await process_frame


func _test_homebase_display_cards_opt_into_readonly_references() -> void:
	var screen: Control = HOMEBASE_TEST_SCENE.instantiate()
	root.add_child(screen)
	await _wait_frames(2)

	var selected_ids := PackedStringArray(["unit_alpha", "unit_bravo", "unit_charlie"])
	var roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	screen.call("setup_roster", roster, selected_ids)
	screen.call(
		"set_fireteam_context",
		PackedStringArray(["ft1", "ft1", "ft1"]),
		[
			{
				"id": "ft1",
				"label": "FT1",
				"lead_unit_id": "unit_alpha",
				"member_unit_ids": selected_ids,
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
	screen.call("_on_homebase_staging_fireteam_dropped", "ft1", "loadout")
	await _wait_frames(4)

	var by_context: Dictionary = _collect_readonly_context_counts(screen)
	_assert(int(by_context.get("roster", 0)) > 0, "Homebase roster cards render")
	_assert(int(by_context.get("staged", 0)) > 0, "Homebase staged cards render")
	_assert(int(by_context.get("homebase_fireteam", 0)) > 0, "Homebase #10 fireteam member cards render")
	_assert(int(by_context.get("homebase_loadout", 0)) > 0, "Homebase #13 loadout member cards render")
	_assert(int(by_context.get("aircraft_shipcard", 0)) > 0, "Homebase Flightdeck pilot card renders")
	_assert(_all_contexts_are_readonly(screen, ["roster", "staged", "homebase_fireteam", "homebase_loadout", "aircraft_shipcard"]), "Homebase display card contexts opt into readonly references")

	screen.queue_free()
	await process_frame


func _test_fob_display_cards_opt_into_readonly_references() -> void:
	var screen: Control = FOB_TEST_SCENE.instantiate()
	root.add_child(screen)
	await _wait_frames(2)

	screen.call("set_available_units", [
		{"unit_id": "unit_a", "display_name": "Anja", "role_name": "Lead"},
		{"unit_id": "unit_b", "display_name": "Milo", "role_name": "Medic"},
		{"unit_id": "unit_c", "display_name": "Nora", "role_name": "Rifleman"},
	])
	screen.call(
		"configure_transfer",
		PackedStringArray(["unit_a", "unit_b", "unit_c"]),
		PackedStringArray(["ft1", "ft1", ""]),
		[{"id": "ft1", "label": "FT1", "lead_unit_id": "unit_a", "member_unit_ids": PackedStringArray(["unit_a", "unit_b"])}]
	)
	await _wait_frames(4)

	var initial_by_context: Dictionary = _collect_readonly_context_counts(screen)
	_assert(int(initial_by_context.get("fob_available", 0)) > 0, "FOB available operator cards render")
	_assert(int(initial_by_context.get("fob_fireteam", 0)) > 0, "FOB fireteam member cards render")
	_assert(_all_contexts_are_readonly(screen, ["fob_available", "fob_fireteam"]), "FOB available and fireteam cards opt into readonly references")

	screen.call("_on_staging_fireteam_dropped", "ft1", "loadout")
	await _wait_frames(4)

	var loadout_by_context: Dictionary = _collect_readonly_context_counts(screen)
	_assert(int(loadout_by_context.get("loadout_staging", 0)) > 0, "FOB loadout member cards render")
	_assert(_all_contexts_are_readonly(screen, ["loadout_staging"]), "FOB loadout cards opt into readonly references")

	screen.queue_free()
	await process_frame


func _build_profile(unit_id: String, display_name: String, secondary_text: String):
	return META_UNIT_PROFILE_SCRIPT.new({
		"unit_id": unit_id,
		"display_name": display_name,
		"role_name": "Rifleman",
		"callsign": "T361",
		"secondary_text": secondary_text,
		"rank_badges": [{"label": "P1", "tooltip": "Task 361"}],
	})


func _collect_readonly_context_counts(root_node: Node) -> Dictionary:
	var counts: Dictionary = {}
	for node in _collect_nodes(root_node):
		if not node.has_method("get_profile_reference_contract_snapshot"):
			continue
		var snapshot: Dictionary = Dictionary(node.call("get_profile_reference_contract_snapshot"))
		if not bool(snapshot.get("uses_readonly_profile_reference", false)):
			continue
		var source_context: String = String(snapshot.get("source_context", "")).strip_edges()
		counts[source_context] = int(counts.get(source_context, 0)) + 1
	return counts


func _all_contexts_are_readonly(root_node: Node, contexts: Array) -> bool:
	var found_counts: Dictionary = {}
	for node in _collect_nodes(root_node):
		if not node.has_method("get_profile_reference_contract_snapshot"):
			continue
		var snapshot: Dictionary = Dictionary(node.call("get_profile_reference_contract_snapshot"))
		var source_context: String = String(snapshot.get("source_context", "")).strip_edges()
		if not contexts.has(source_context):
			continue
		found_counts[source_context] = int(found_counts.get(source_context, 0)) + 1
		if not bool(snapshot.get("uses_readonly_profile_reference", false)):
			return false
	for context_variant in contexts:
		if int(found_counts.get(String(context_variant), 0)) <= 0:
			return false
	return true


func _collect_nodes(root_node: Node) -> Array:
	var result: Array = []
	if root_node == null:
		return result
	result.append(root_node)
	for child in root_node.get_children():
		result.append_array(_collect_nodes(child))
	return result


func _on_card_pressed(unit_id: String, profile, source_context: String) -> void:
	_last_pressed_unit_id = unit_id
	_last_pressed_profile = profile
	_last_pressed_source_context = source_context


func _on_card_open_requested(unit_id: String, profile, source_context: String) -> void:
	_last_opened_unit_id = unit_id
	_last_opened_profile = profile
	_last_opened_source_context = source_context


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
