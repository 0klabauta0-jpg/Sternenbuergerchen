extends SceneTree

const AUDIO_EVENT_BUS_SCRIPT: GDScript = preload("res://scripts/audio/audio_event_bus.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const CATALOG_PATH: String = "res://data/audio_sfx_catalog.json"
const COMBAT_AUDIO_IDS: Array = [
	"combat_blaster_small_01",
	"combat_blaster_small_02",
	"combat_smg_laser_01",
	"combat_smg_laser_02",
	"combat_heavy_laser_01",
	"combat_sniper_zap_01",
]
const MIN_VISIBLE_FIRE_EVENTS: int = 12
const MAX_COOLDOWN_MSEC: int = 25
const MIN_POLYPHONY: int = 12
const SHOT_COUNT: int = 12

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_catalog_entries()
	_test_visible_event_limit()
	await _test_six_shots_all_accepted()
	print("COMBAT_FIRE_FEEDBACK passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_catalog_entries() -> void:
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	_assert(file != null, "catalog file can be opened")
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	var entries: Array = []
	if parsed is Dictionary:
		for key in ["entries", "sounds", "sfx", "audio"]:
			if (parsed as Dictionary).get(key, null) is Array:
				entries = (parsed as Dictionary).get(key)
				break
	elif parsed is Array:
		entries = parsed
	var by_id: Dictionary = {}
	for entry in entries:
		if entry is Dictionary:
			by_id[String((entry as Dictionary).get("audio_id", ""))] = entry
	for audio_id in COMBAT_AUDIO_IDS:
		var entry: Dictionary = by_id.get(audio_id, {})
		_assert(not entry.is_empty(), "%s exists in catalog" % audio_id)
		if entry.is_empty():
			continue
		_assert(entry.has("spatial") and not bool(entry.get("spatial")), "%s is not spatial" % audio_id)
		_assert(int(entry.get("cooldown_msec", 9999)) <= MAX_COOLDOWN_MSEC, "%s cooldown_msec <= %d" % [audio_id, MAX_COOLDOWN_MSEC])
		_assert(int(entry.get("polyphony_limit", 0)) >= MIN_POLYPHONY, "%s polyphony_limit >= %d" % [audio_id, MIN_POLYPHONY])


func _test_visible_event_limit() -> void:
	var constants: Dictionary = TERRAIN_MAP_3D_VIEW_SCRIPT.get_script_constant_map()
	var limit: int = int(constants.get("WEAPON_FIRE_VISIBLE_EVENT_LIMIT", 0))
	_assert(limit >= MIN_VISIBLE_FIRE_EVENTS, "WEAPON_FIRE_VISIBLE_EVENT_LIMIT >= %d (is %d)" % [MIN_VISIBLE_FIRE_EVENTS, limit])


func _test_six_shots_all_accepted() -> void:
	var bus = AUDIO_EVENT_BUS_SCRIPT.new()
	root.add_child(bus)
	await process_frame
	bus.call("stop_all_for_tests")
	var accepted: int = 0
	for index in range(SHOT_COUNT):
		var result: Dictionary = bus.call("emit_weapon_fire", "rifle", {
			"position": Vector3(float(index), 0.0, 0.0),
			"now_msec": 10000 + index * 30,
			"dedupe_key": "fx_a_shot_%d" % index,
		})
		if bool(result.get("played", false)):
			accepted += 1
		else:
			print("  shot %d rejected: %s" % [index, String(result.get("reason", ""))])
	_assert(accepted == SHOT_COUNT, "%d rifle shots 30 ms apart are all accepted (%d)" % [SHOT_COUNT, accepted])
	bus.call("stop_all_for_tests")
	bus.queue_free()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		print("FAIL: %s" % message)
