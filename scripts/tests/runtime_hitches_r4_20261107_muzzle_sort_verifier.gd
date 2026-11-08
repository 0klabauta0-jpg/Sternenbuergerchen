extends "res://scripts/tests/runtime_hitches_r4_20261107_muzzle_source_order_verifier.gd"
## Additional QA of ordinary shuffled feeds; does not rewrite the earlier RED.

func run() -> void:
	var view: Node = VIEW.new()
	root.add_child(view)
	view.call("configure_from_map", MAP.call("create_empty", "r4_source_sort", Vector2i(8, 8), Vector2.ZERO, 64.0, 32.0, 2))
	await frames(4)
	var newest: Dictionary = event("fire_00000100_0001_alpha_target", "alpha", 100)
	var older: Dictionary = event("fire_00000098_0004_alpha_target", "alpha", 98)
	var other: Dictionary = event("fire_00000099_0001_bravo_target", "bravo", 99)
	view.call("set_order_visual_payload", {"fire_event_dicts": [newest, other, older]})
	await frames(2)
	var sample: Dictionary = source_sample(view, "alpha")
	check(String(sample.get("event_id", "")) == String(newest.event_id), "Shuffled ordinary events choose the newer tick even when an older row is last")
	check(int(Dictionary(view.call("get_weapon_fire_feedback_snapshot")).get("active_pulse_count", 0)) == 2, "Shuffled ordinary feed retains one pulse per source")
	var sequence9: Dictionary = event("fire_00000120_0009_alpha_target", "alpha", 120)
	var sequence1: Dictionary = event("fire_00000120_0001_alpha_target", "alpha", 120)
	var sequence8: Dictionary = event("fire_00000120_0008_alpha_target", "alpha", 120)
	view.call("set_order_visual_payload", {"fire_event_dicts": [sequence9, sequence1, sequence8]})
	await frames(2)
	sample = source_sample(view, "alpha")
	check(String(sample.get("event_id", "")) == String(sequence9.event_id), "Same-tick real Driver padded sequence selects the newest sequence deterministically")
	var original_instance: int = int(sample.get("pulse_instance_id", 0))
	view.call("set_order_visual_payload", {"fire_event_dicts": [sequence8, sequence9, sequence1]})
	await frames(2)
	sample = source_sample(view, "alpha")
	check(String(sample.get("event_id", "")) == String(sequence9.event_id) and int(sample.get("pulse_instance_id", -1)) == original_instance, "Reordering the same source snapshot never changes or replays the chosen pulse")
	view.queue_free()
	await frames(2)
	print("R4_MUZZLE_SORT: %d passed, %d failed" % [passed, failed])
	if failed == 0:
		print("R4_MUZZLE_SORT_PASS")
	quit(1 if failed else 0)

func source_sample(view: Node, source: String) -> Dictionary:
	for item in Array(Dictionary(view.call("get_weapon_fire_feedback_snapshot")).get("entries", [])):
		if String(Dictionary(item).get("attacker_unit_id", "")) == source:
			return Dictionary(item)
	return {}
