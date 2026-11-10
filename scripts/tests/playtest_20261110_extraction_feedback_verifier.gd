extends SceneTree
## Product-facing extraction controls, actual projection and interaction wording.
const PRESENTER = preload("res://scripts/ui/mission_a5_dropship_presenter.gd")
const VISUAL = preload("res://scripts/mission/mission_interaction_visual_state.gd")
var failed := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var mission: Node = load("res://scenes/tests/mission_reactivity_test.tscn").instantiate()
	root.add_child(mission)
	await process_frame
	await process_frame
	var controller: Node = mission.get_node("TacticalController")
	PRESENTER.ensure(controller)
	var actions: Node = mission.get_node("TacticalUI/MissionDropshipPanel/CompactCard/Contents/Actions")
	_check(actions.has_node("board"), "Compact craft card exposes crew return and boarding")
	_check(actions.has_node("return"), "Compact craft card exposes takeoff without Details")
	_check(controller.has_method("request_campaign_extraction"), "One product extraction action walks then boards without teleporting")
	_check(controller.has_method("select_landed_craft_at_screen_position"), "Landed craft can be selected from map")
	var state: Dictionary = VISUAL.build_snapshot({"interactions":[{"interaction_id":"satellite_data", "display_name":"Satellitendaten sichern", "interaction_type":"computer", "marker_position":Vector2(100,100), "runtime_use_status":"blocked"}]}, {"next_interaction_id":"satellite_data"})
	var entry: Dictionary = state.entries[0]
	_check(String(entry.get("player_label", "")).contains("Satellitendaten sichern"), "Player label names the satellite instead of COM")
	_check(not String(entry.get("player_label", "")).contains("BLOCKED"), "Player label uses readable German state")
	mission.queue_free()
	await process_frame
	print("EXTRACTION_FEEDBACK failed=", failed)
	quit(1 if failed else 0)

func _check(value: bool, message: String) -> void:
	if not value: failed += 1
	print("PASS: " if value else "FAIL: ", message)
