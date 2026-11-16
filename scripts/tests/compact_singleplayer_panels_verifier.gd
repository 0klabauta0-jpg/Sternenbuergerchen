extends SceneTree
## Real presenter geometry and operation routing; labels must not expose IDs.

var _passed: int = 0
var _failed: int = 0

func _init() -> void:
	call_deferred("_run")

func _check(value: bool, label: String) -> void:
	if value:
		_passed += 1
	else:
		_failed += 1
		printerr("FAIL: ", label)

func _run() -> void:
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	await process_frame
	var screen: Control = flow.get_node("HomebaseScreen")
	var runtime: Node = flow.get("_singleplayer_runtime")
	var host := Control.new()
	root.add_child(host)
	host.size = Vector2(1100, 700)
	var jobs: Control = load("res://scripts/meta/singleplayer_job_board_presenter.gd").new()
	jobs.call("configure", screen)
	host.add_child(jobs)
	jobs.size = Vector2(1100, 600)
	jobs.call("refresh")
	for frame in range(3):
		await process_frame
	var accept: Button = jobs.find_child("AcceptJob", true, false)
	var show_map: Button = jobs.find_child("ShowOnMap", true, false)
	var abandon: Button = jobs.find_child("AbandonJob", true, false)
	_check(accept != null and show_map != null and abandon != null, "All actual job actions remain available")
	if accept != null and show_map != null and abandon != null:
		_check(accept.size.x < 360 and show_map.size.x < 360 and abandon.size.x < 360, "Wide desktop viewport keeps job buttons at compact natural widths")
		_check(accept.get_global_rect().end.x <= jobs.global_position.x + 680 and show_map.get_global_rect().end.x <= jobs.global_position.x + 680 and abandon.get_global_rect().end.x <= jobs.global_position.x + 680, "Job actions occupy a bounded device-sized area")
		accept.pressed.emit()
		var campaign: Dictionary = runtime.call("get_snapshot").campaign
		_check(campaign.jobs.satellite_recovery.status == "accepted", "Compact accept button still commits real campaign command")
		show_map.pressed.emit()
		_check(String(runtime.call("get_snapshot").campaign.selected_location_id) == "satellite_crash", "Compact map action still routes the same real location identity")
		jobs.size = Vector2(500, 600)
		for frame in range(3):
			await process_frame
		_check(accept.get_global_rect().end.x <= jobs.global_position.x + jobs.size.x and show_map.get_global_rect().end.x <= jobs.global_position.x + jobs.size.x and abandon.get_global_rect().end.x <= jobs.global_position.x + jobs.size.x, "Actions reflow within narrower device area")
	jobs.hide()
	var services: Control = load("res://scripts/meta/singleplayer_services_presenter.gd").new()
	host.add_child(services)
	services.size = Vector2(1000, 600)
	services.call("configure", Callable(runtime, "get_snapshot"), Callable(screen, "request_operation"))
	for frame in range(3):
		await process_frame
	var buy: Button = services.find_child("BuySupply", true, false)
	var refuel: Button = services.find_child("RefuelCraft", true, false)
	_check(buy != null and refuel != null and buy.size.x < 400 and refuel.size.x < 400, "Supply actions keep natural widths in a wide area")
	var selector: OptionButton = services.find_child("ServiceCraftSelector", true, false)
	var snapshot: Dictionary = runtime.call("get_snapshot")
	var actual_id: String = String(snapshot.crafts[0].craft_id)
	# Seit a4d5948c5 steht an Position 0 der Platzhalter "Serviceschiff auswaehlen" (selection_required, ohne Schiffs-ID); die Schiffe beginnen bei 1.
	_check(selector != null and selector.item_count >= 2 and String(selector.get_item_metadata(0)).is_empty() and String(selector.get_item_metadata(0)) != actual_id and selector.get_item_text(0) != actual_id, "Craft selector starts with a placeholder entry that carries no craft ID")
	_check(selector != null and selector.item_count >= 2 and String(selector.get_item_metadata(1)) == actual_id and selector.get_item_text(1) != actual_id and not selector.get_item_text(1).is_empty(), "Craft selector shows a display name while preserving actual craft ID")
	flow.queue_free()
	host.queue_free()
	await process_frame
	print("COMPACT_SINGLEPLAYER_PANELS passed=", _passed, " failed=", _failed)
	quit(0 if _failed == 0 else 1)
