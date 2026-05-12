extends SceneTree

const HOMEBASE_TEST_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")
const DROPSHIP_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png"

var _passed: int = 0
var _failed: int = 0
var _mission_start_signal_count: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_347 Homebase Direct Staging Start Guard ===")
	await _test_direct_payload_button_and_guard_match()
	await _test_empty_direct_payload_stays_blocked()
	await _test_existing_launch_ready_path_still_emits()

	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_347: FAILED")
		quit(1)
	else:
		print("TASK_347: ALL PASSED")
		quit(0)


func _test_direct_payload_button_and_guard_match() -> void:
	var screen: Control = _build_screen_with_fireteam_payload()
	await process_frame
	await process_frame

	var start_button := _get_start_button(screen)
	var snapshot: Dictionary = Dictionary(screen.call("get_homebase_direct_staging_snapshot"))
	_mission_start_signal_count = 0
	screen.connect("mission_start_requested", Callable(self, "_on_mission_start_requested"))
	screen.call("request_mission_start")

	_assert(start_button != null and not start_button.disabled, "Direct Homebase payload enables the Start button")
	_assert(bool(screen.call("can_request_mission_start")), "Direct Homebase payload passes the public start guard")
	_assert(bool(snapshot.get("can_request_mission_start", false)), "Direct staging snapshot exposes the same start guard truth")
	_assert(_mission_start_signal_count == 1, "request_mission_start emits for a ready direct Homebase payload")

	screen.queue_free()
	await process_frame


func _test_empty_direct_payload_stays_blocked() -> void:
	var screen: Control = HOMEBASE_TEST_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame

	var start_button := _get_start_button(screen)
	_mission_start_signal_count = 0
	screen.connect("mission_start_requested", Callable(self, "_on_mission_start_requested"))
	screen.call("request_mission_start")

	_assert(start_button != null and start_button.disabled, "Empty Homebase staging keeps the Start button disabled")
	_assert(not bool(screen.call("can_request_mission_start")), "Empty Homebase staging fails the public start guard")
	_assert(_mission_start_signal_count == 0, "request_mission_start does not emit without launch-ready state or direct payload")

	screen.queue_free()
	await process_frame


func _test_existing_launch_ready_path_still_emits() -> void:
	var screen: Control = HOMEBASE_TEST_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	screen.call("set_mission_launch_state", true, "FOB dropship ready")
	await process_frame

	var start_button := _get_start_button(screen)
	_mission_start_signal_count = 0
	screen.connect("mission_start_requested", Callable(self, "_on_mission_start_requested"))
	screen.call("request_mission_start")

	_assert(start_button != null and not start_button.disabled, "Existing mission launch-ready state still enables Start")
	_assert(bool(screen.call("can_request_mission_start")), "Existing mission launch-ready state still passes the guard")
	_assert(_mission_start_signal_count == 1, "request_mission_start still emits for existing mission launch-ready state")

	screen.queue_free()
	await process_frame


func _build_screen_with_fireteam_payload() -> Control:
	var screen: Control = HOMEBASE_TEST_SCENE.instantiate()
	root.add_child(screen)
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
		{"dropship_alpha": "unit_charlie"},
		[],
		[],
		{"dropship_alpha": "homebase"},
		{},
		{},
		[]
	)
	screen.call("_on_homebase_staging_fireteam_dropped", "ft1", "homebase_dropship")
	return screen


func _get_start_button(screen: Control) -> Button:
	return screen.get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/StartMissionButton") as Button


func _on_mission_start_requested() -> void:
	_mission_start_signal_count += 1


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		print("  FAIL: %s" % message)
