extends "res://scripts/tests/campaign_five_actual_sorties_verifier.gd"

func _run() -> void:
	if not OS.get_environment("APPDATA").contains("campaign-diagnostic-profiles"):
		printerr("Isolated campaign-diagnostic-profiles APPDATA required")
		quit(2)
		return
	Engine.time_scale = 4.0
	START.request_start(self, "campaign", "new")
	_flow = FLOW.instantiate()
	root.add_child(_flow)
	await process_frame
	_screen = _flow.get_node("HomebaseScreen")
	_runtime = _flow.get("_singleplayer_runtime")
	var operations: Dictionary = _screen.call("get_operations_snapshot")
	_craft_id = String(operations.selected_craft.id)
	for team: Dictionary in operations.fireteams:
		if not Array(team.members).is_empty():
			_team_id = String(team.id)
			break
	_dump_base("before")
	var result: Dictionary = _screen.call("request_operation", "base_board", {"craft_id":_craft_id,"fireteam_id":_team_id,"whole_fireteam":true})
	_check(bool(result.get("ok", false)), "Actual new campaign accepts complete crew walk")
	print("BOARD_REQUEST ", result)
	var started: int = Time.get_ticks_msec()
	var dumped_second: int = -1
	while Time.get_ticks_msec() - started < 20000:
		if _base_crew_ready():
			break
		var second: int = (Time.get_ticks_msec() - started) / 1000
		if second % 4 == 0 and second != dumped_second:
			_dump_base("second_%d" % second)
			dumped_second = second
		await process_frame
	_dump_base("final")
	_check(_base_crew_ready(), "Real people and payload complete boarding within bounded20s at4x")
	_flow.queue_free()
	await process_frame
	print("GAME_REVIEW_CAMPAIGN_DIAGNOSTIC passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

func _dump_base(label_text: String) -> void:
	var personnel: Node = _runtime.call("get_base_personnel_runtime")
	var simulation: Node = personnel.call("get_simulation_root")
	var people: Dictionary = personnel.call("get_snapshot")
	people.erase("layout")
	print("BASE_DIAGNOSTIC ", label_text, " ", var_to_str({
		"tick":simulation.call("get_tick"), "physics":simulation.is_physics_processing(),
		"paused":paused, "space":_space(), "personnel":people,
		"groups":personnel.get("_board_groups"), "queue":simulation.get("command_queue"),
		"payload":_screen.call("get_homebase_direct_staging_snapshot"),
	}))
