extends SceneTree
const BINDING: GDScript = preload("res://scripts/mission/mission_interaction_point_binding.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
var passed := 0
var failed := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		print("FAIL: ", label)

func write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()

func oracle(path: String, map, context: Dictionary) -> Dictionary:
	var scenario: Dictionary = {}
	if FileAccess.file_exists(path):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary:
			scenario = parsed
	var result: Dictionary = BINDING.build_snapshot(scenario, map, context)
	result["source_path"] = path
	return result

func stats() -> Dictionary:
	return BINDING.call("get_scenario_parse_cache_diagnostics") if BINDING.has_method("get_scenario_parse_cache_diagnostics") else {}

func _run() -> void:
	var map = MAP.load_from_file("res://maps/Ground_Mission01_32x32.json")
	var path := "user://r5_scenario_parse.json"
	var other := "user://r5_scenario_other.json"
	var scenario := {"scenario_id": "r5", "interaction_points": [{"interaction_id": "door", "interaction_type": "door", "marker_id": "spawn_alpha", "required_order": "take", "radius_world": 64, "duration_seconds": 3, "step_id": "door_step"}]}
	var text := JSON.stringify(scenario)
	write_text(path, text)
	var context := {"interaction_states": {"door": {"state": "in_progress", "progress": 0.25}}}
	var before := stats()
	for iteration in range(6):
		var actual: Dictionary = BINDING.load_snapshot_from_file(path, map, context)
		check(actual == oracle(path, map, context), "Repeated complete snapshot matches uncached oracle %d" % iteration)
	var after := stats()
	check(not after.is_empty(), "Content parse cache exposes bounded diagnostic counters")
	if not after.is_empty():
		check(int(after.parse_count) - int(before.get("parse_count", 0)) == 1, "Identical file bytes are parsed only once")
		check(int(after.hit_count) - int(before.get("hit_count", 0)) == 5, "All repeated exact-text reads reuse parsing")
	var defensive: Dictionary = BINDING.load_snapshot_from_file(path, map, context)
	defensive.bindings[0]["display_name"] = "EXTERNAL"
	check(BINDING.load_snapshot_from_file(path, map, context) == oracle(path, map, context), "Caller mutation cannot poison cached raw configuration")
	context.interaction_states.door["progress"] = 0.75
	check(BINDING.load_snapshot_from_file(path, map, context) == oracle(path, map, context), "Live runtime update is rebuilt on cache hit")
	check(float(BINDING.load_snapshot_from_file(path, map, context).bindings[0].progress) == 0.75, "New runtime progress is actually visible")
	# A different marker is a direct live input; validation must not be cached.
	var invalid_map = MAP.new()
	var invalid: Dictionary = BINDING.load_snapshot_from_file(path, invalid_map, context)
	check(invalid == oracle(path, invalid_map, context) and not bool(invalid.valid), "Changed map validation remains live")
	var changed := text.replace('"r5"', '"s5"')
	check(changed.length() == text.length(), "Same-length edit fixture is real")
	write_text(path, changed)
	var edited: Dictionary = BINDING.load_snapshot_from_file(path, map, context)
	check(edited == oracle(path, map, context) and edited.scenario_id == "s5", "Same-path same-length edit is read without mtime assumptions")
	write_text(other, text)
	check(BINDING.load_snapshot_from_file(other, map, context) == oracle(other, map, context), "Different path preserves source path and new contents")
	write_text(path, "null")
	check(BINDING.load_snapshot_from_file(path, map, context) == oracle(path, map, context), "Non-object JSON preserves empty-scenario behavior")
	var missing := "user://r5_never_created.json"
	check(not FileAccess.file_exists(missing), "Missing file fixture is actually absent")
	check(BINDING.load_snapshot_from_file(missing, map, context) == oracle(missing, map, context), "Absent file never replays prior configuration")
	var huge := JSON.stringify({"scenario_id": "large", "notes": "x".repeat(1048577)})
	write_text(path, huge)
	before = stats()
	for iteration in range(2):
		check(BINDING.load_snapshot_from_file(path, map, context) == oracle(path, map, context), "Large uncached input preserves semantics")
	after = stats()
	if not after.is_empty():
		check(int(after.parse_count) - int(before.get("parse_count", 0)) == 2, "Oversized input bypasses retention")
		check(int(after.entry_count) <= 1 and int(after.retained_text_bytes) <= 1048576, "Retention stays within one entry and one MiB")
	write_text(path, JSON.stringify({"notes": "雪".repeat(360000)}))
	check(BINDING.load_snapshot_from_file(path, map, context) == oracle(path, map, context), "Multibyte capacity fixture preserves complete output")
	if not stats().is_empty():
		check(int(stats().entry_count) == 0, "UTF-8 byte cap also rejects fewer-than-one-MiB multibyte characters")
	write_text(path, "{}")
	before = stats()
	for iteration in range(2):
		check(BINDING.load_snapshot_from_file(path, map, context) == oracle(path, map, context), "Empty dictionary remains a valid parsed configuration")
	after = stats()
	if not after.is_empty():
		check(int(after.parse_count) - int(before.get("parse_count", 0)) == 1 and int(after.entry_count) == 1, "Empty dictionary is cached without an empty-result ambiguity")
	print("R5_SCENARIO_PARSE_DONE ", JSON.stringify({"passed": passed, "failed": failed, "cache": after}))
	quit(0 if failed == 0 else 1)
