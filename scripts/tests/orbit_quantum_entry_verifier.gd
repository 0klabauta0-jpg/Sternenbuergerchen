extends SceneTree
## The actual grounded star-map button must expose travel in Skirmish too;
## legacy navigation cannot load a campaign map before authorized approach.
var _failed := 0
var _passed := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	await process_frame
	var screen: Control = flow.get_node("HomebaseScreen")
	var runtime: Node = flow.get("_singleplayer_runtime")
	_check(not runtime.call("is_campaign_mission"), "Ordinary Skirmish initially keeps its existing mission path")
	screen.call("request_operation", "navigate", {"mode": "map"})
	await process_frame
	var region: Control = screen.get("_operations_presenter").get("_region_map")
	if region == null:
		region = screen.find_child("RegionMap", true, false)
	var prepare: Button = region.find_child("CloseStarMap", true, false) if region != null else null
	_check(prepare != null, "Real grounded region view exposes preparation action")
	if prepare != null:
		prepare.pressed.emit()
	_check(runtime.call("is_campaign_mission"), "Grounded star-map preparation actually selects orbital travel")
	var craft: Dictionary = screen.call("get_operations_snapshot").selected_craft
	screen.call("_debug_advance_homebase_direct_boarding", 30.0)
	var launch: Dictionary = screen.call("request_operation", "start", {"craft_id": String(craft.id)})
	_check(launch.get("ok", false) and String(runtime.call("get_snapshot").get("space_travel", {}).get("orbit_id", "")) == "moon_orbit", "Prepared Skirmish travel reaches moon without a hidden destination command")
	_check(flow.get("_active_mission") == null, "Prepared Skirmish liftoff does not load default combat map")
	var opened: Dictionary = runtime.call("request_operation", "space_open_operations", {})
	_check(opened.get("ok", false) and String(flow.get("_current_meta_view")) == "homebase" and String(screen.get("_operations_mode")) == "squad", "Trupp and equipment remain reachable during orbital travel")
	_check(String(runtime.call("get_snapshot").space_travel.orbit_id) == "moon_orbit" and String(Dictionary(flow.get("_aircraft_location_by_craft")).get(String(craft.id), "")) == "starmap", "Opening operations does not fabricate home arrival")
	_check(bool(Dictionary(screen.call("get_operations_snapshot").get("selected_craft", {})).get("busy", false)), "Remote operations keeps pilot and payload locked")
	var landed: Dictionary = runtime.call("request_operation", "space_land_homebase", {"craft_id": String(craft.id)})
	_check(landed.get("ok", false), "Cancelled orbital outing can land back at its moonbase")
	screen.call("request_operation", "mission", {"mission_id": "grid_sweep"})
	_check(not runtime.call("is_campaign_mission"), "After landing an ordinary Skirmish mission leaves travel preparation mode")
	screen.call("request_operation", "navigate", {"mode": "mission"})
	await process_frame
	var presenter: Control = screen.get("_operations_presenter")
	var actual_start: Button = presenter.get("_start")
	_check(actual_start.is_visible_in_tree() and not actual_start.disabled, "Ordinary Skirmish has a visible actionable start button after orbital return")
	_check(presenter.get("_mission_selector").is_visible_in_tree(), "Ordinary Skirmish retains its actual mission selector")
	var regular_start: Dictionary = screen.call("request_operation", "start", {"craft_id": String(craft.id)})
	_check(regular_start.get("ok", false) and flow.get("_active_mission") != null, "Ordinary Skirmish starts its selected combat map after a cancelled orbit outing")
	flow.queue_free()
	await process_frame
	load("res://scripts/meta/game_start_contract.gd").request_start(self, "campaign", "new")
	flow = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	await process_frame
	flow.call("_show_map")
	_check(flow.get("_active_mission") == null and int(flow.get("_active_mission_started_at_msec")) == 0, "Legacy campaign map navigation cannot bypass orbital approach")
	flow.queue_free()
	await process_frame
	print("ORBIT_QUANTUM_ENTRY passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

func _check(value: bool, label: String) -> void:
	if value:
		_passed += 1
		print("PASS: ", label)
	else:
		_failed += 1
		printerr("FAIL: ", label)
