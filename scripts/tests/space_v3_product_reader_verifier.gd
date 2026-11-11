extends SceneTree
## Run only in an isolated project: this probe replaces its copied system JSON.
const TRAVEL = preload("res://scripts/core/singleplayer_space_travel_state.gd")
const CATALOG = preload("res://scripts/mission/orbit_destination_catalog.gd")
const PATH := "res://data/singleplayer/star_system.json"

func _initialize() -> void:
	if not ProjectSettings.get_setting("space_reader_probe/isolated", false):
		push_error("This verifier requires a private project copy")
		quit(1)
		return
	var legacy: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	assert(TRAVEL.new().configure("ship").ok)
	var compiled: Dictionary = CATALOG.build_v3_product(legacy)
	assert(compiled.ok)
	var product: Dictionary = compiled.definition
	_write(product)
	var travel = TRAVEL.new()
	assert(travel.configure("ship").ok)
	var snapshot: Dictionary = travel.get_snapshot()
	assert(snapshot.system_version == 3 and snapshot.orbits.size() == 6)
	for orbit_id in legacy.orbits:
		assert(snapshot.orbits[orbit_id].hex == legacy.orbits[orbit_id].hex)
	assert(snapshot.location_orbits == legacy.location_orbits)
	assert(_command(travel, "launch_to_orbit", {"craft_id":"ship"}).ok)
	assert(not _command(travel, "start_quantum", {"craft_id":"ship", "target_orbit_id":"sun_orbit", "target_orbit_marker_id":"orbit_2"}).ok)
	assert(_command(travel, "start_quantum", {"craft_id":"ship", "target_orbit_id":"sun_orbit"}).ok)
	assert(_command(travel, "advance", {"delta_seconds":60.0}).ok)
	assert(travel.get_snapshot().orbit_id == "sun_orbit")
	assert(not _command(travel, "begin_approach", {"craft_id":"ship", "location_id":"sun"}).ok)
	var bad: Dictionary = product.duplicate(true)
	bad["draft"] = true
	_rejected(bad)
	bad = product.duplicate(true); bad["marker_aliases_v2_to_v3"] = {}; _rejected(bad)
	bad = product.duplicate(true); bad.version = 4; _rejected(bad)
	bad = product.duplicate(true); bad.orbits.sun_orbit.markers[0].id = "orbit_2"; _rejected(bad)
	bad = product.duplicate(true); bad.location_orbits["sun"] = "sun_orbit"; _rejected(bad)
	assert(not travel.configure("ship").ok)
	assert(not _command(travel, "start_quantum", {"craft_id":"ship", "target_orbit_id":"planet_orbit"}).ok)
	print("V2 and strict V3 cold reader, Sun warp and rejection checks passed")
	quit(0)

func _rejected(data: Dictionary) -> void:
	_write(data)
	assert(not TRAVEL.new().configure("ship").ok)

func _write(data: Dictionary) -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	assert(file != null)
	file.store_string(JSON.stringify(data))
	file.close()

func _command(travel: RefCounted, operation: String, payload: Dictionary) -> Dictionary:
	return travel.apply_command({"contract_category":"singleplayer_space_travel", "operation":operation, "payload":payload}, {"runtime_authorized":true})
