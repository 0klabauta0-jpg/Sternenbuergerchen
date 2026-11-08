extends "res://scripts/tests/runtime_hitches_r4_20261107_muzzle_context_verifier.gd"
## A rejected/hidden receipt cannot replay when visibility returns before TTL.

func run() -> void:
	var view: Node = VIEW.new()
	root.add_child(view)
	view.call("configure_from_map", map_data("r4_admission_unknown"))
	await frames(4)
	var hidden: Dictionary = fire_event("r4_admission_hidden", "enemy_hidden_r4", "team_bravo")
	view.call("set_fog_of_war_state", fog([]))
	view.call("set_order_visual_payload", {"fire_event_dicts": [hidden]})
	await create_timer(0.06).timeout
	view.call("set_fog_of_war_state", fog(["enemy_hidden_r4"]))
	view.call("set_order_visual_payload", {"fire_event_dicts": [hidden]})
	await frames(2)
	check(pulse_count(view) == 0, "A source rejected on first receipt never replays the same key after 60ms visibility gain")
	view.queue_free()
	await frames(2)
	view = VIEW.new()
	root.add_child(view)
	view.call("configure_from_map", map_data("r4_admission_return"))
	await frames(4)
	var known: Dictionary = fire_event("r4_admission_known", "enemy_known_r4", "team_bravo")
	view.call("set_fog_of_war_state", fog(["enemy_known_r4"]))
	view.call("set_order_visual_payload", {"fire_event_dicts": [known]})
	await frames(2)
	check(pulse_count(view) == 1, "A new currently known source is admitted normally")
	view.call("set_fog_of_war_state", fog([]))
	await frames(2)
	check(pulse_count(view) == 0, "Source loss immediately hides its active pulse")
	await create_timer(0.06).timeout
	view.call("set_fog_of_war_state", fog(["enemy_known_r4"]))
	view.call("set_order_visual_payload", {"fire_event_dicts": [known]})
	await frames(2)
	check(pulse_count(view) == 0, "Sight loss then return within TTL never restarts a consumed key")
	known["event_id"] = "r4_admission_new_real_event"
	known["tick"] = 8
	view.call("set_order_visual_payload", {"fire_event_dicts": [known]})
	await frames(2)
	check(pulse_count(view) == 1, "A genuinely new event after regained source visibility is admitted")
	view.queue_free()
	await frames(2)
	print("R4_MUZZLE_ADMISSION: %d passed, %d failed" % [passed, failed])
	if failed == 0:
		print("R4_MUZZLE_ADMISSION_PASS")
	quit(1 if failed else 0)
