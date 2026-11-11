extends RefCounted
## Pure, UNWIRED V2 -> V3 draft/product compilers. Never remaps live commands.
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const LAYOUT = preload("res://scripts/mission/orbit_approach_layout.gd")
const SUN_ORBIT := "sun_orbit"

static func build_v3_draft(legacy_definition: Dictionary) -> Dictionary:
	var valid := _validate_definition(legacy_definition, 2)
	if not valid.get("ok", false): return valid
	var definition := legacy_definition.duplicate(true)
	definition["version"] = 3
	definition["draft"] = true
	var aliases := {}
	var used_legacy_cells := {}
	for orbit_id: String in GRID.ORBITS:
		var legacy: Dictionary = legacy_definition.orbits[orbit_id]
		aliases[orbit_id] = {}
		for marker: Dictionary in legacy.markers:
			aliases[orbit_id][String(marker.id)] = "orbit_1"
			used_legacy_cells[GRID.cell_from_record(marker)] = true
		var first: Dictionary = Dictionary(legacy.markers[0]).duplicate(true)
		first["position"] = _position_record(GRID.cell_from_record(first))
		definition.orbits[orbit_id]["markers"] = [first]
	var sun: Dictionary = definition.bodies.sun
	var radius := ceili(float(sun.radius)) + 1
	var sun_cell := GRID.cell_from_record(sun) + Vector2i(-radius, 0)
	if not GRID.contains(sun_cell): return _reject("sun_marker_out_of_bounds")
	if GRID.HEX.distance(GRID.cell_from_record(sun), sun_cell) != radius: return _reject("sun_marker_radius_mismatch")
	if used_legacy_cells.has(sun_cell): return _reject("sun_marker_collision")
	definition.bodies.sun["orbit_id"] = SUN_ORBIT
	definition.orbits[SUN_ORBIT] = {"id":SUN_ORBIT,"name":String(sun.name) + " · Sternorbit","body_id":"sun",
		"hex":[sun_cell.x,sun_cell.y],"position":_position_record(sun_cell),
		"markers":[{"id":"orbit_1","hex":[sun_cell.x,sun_cell.y],"position":_position_record(sun_cell)}]}
	var body_orbits := _physical_body_orbits()
	var body_areas := {}
	for body_id: String in body_orbits:
		var layout: Dictionary = LAYOUT.build(body_id)
		if not layout.get("ok", false): return _reject("invalid_body_layout")
		body_areas[body_id] = String(layout.body_map_id)
		var orbit_id: String = body_orbits[body_id]
		definition.orbits[orbit_id]["body_map_id"] = String(layout.body_map_id)
		definition.orbits[orbit_id]["local_grid_size"] = [layout.map_bounds.size.x,layout.map_bounds.size.y]
	valid = validate_v3_draft(definition)
	if not valid.get("ok", false): return valid
	return {"ok":true,"draft":true,"source_version":2,"definition":definition,
		"marker_aliases_v2_to_v3":aliases,"marker_aliases_migration_only":true,
		"body_orbits":body_orbits,"body_area_ids":body_areas}

static func validate_v3_draft(definition: Dictionary) -> Dictionary:
	return _validate_definition(definition, 3, true)

## Explicit opt-in product preparation, never selected by the draft API.
static func build_v3_product(legacy_definition: Dictionary) -> Dictionary:
	var draft := build_v3_draft(legacy_definition)
	if not draft.get("ok",false): return draft
	var definition: Dictionary = draft.definition
	definition.erase("draft")
	var valid := validate_v3_product(definition)
	if not valid.get("ok",false): return valid
	return {"ok":true,"source_version":2,"definition":definition,
		"body_orbits":draft.body_orbits,"body_area_ids":draft.body_area_ids}

static func validate_v3_product(definition: Dictionary) -> Dictionary:
	return _validate_definition(definition, 3, false)

static func _physical_body_orbits() -> Dictionary:
	var result := {}
	var orbits := GRID.orbits_for_version(3)
	for orbit_id: String in orbits:
		result[String(orbits[orbit_id])] = orbit_id
	return result

static func _validate_definition(data: Dictionary, version: int, draft_mode: bool = false) -> Dictionary:
	if not _plain_data(data) or not _integer(data.get("version")) or int(data.version) != version or not _size_pair(data.get("grid_size"), Vector2i(256,256)): return _reject("invalid_catalog_header")
	if typeof(data.get("id")) != TYPE_STRING or String(data.id).is_empty() or typeof(data.get("jump_duration_seconds")) not in [TYPE_INT,TYPE_FLOAT] or float(data.jump_duration_seconds) <= 0.0 or float(data.jump_duration_seconds) > 60.0: return _reject("invalid_catalog_header")
	if not data.get("bodies") is Dictionary or not data.get("orbits") is Dictionary or not data.get("location_orbits") is Dictionary: return _reject("invalid_catalog_tables")
	if version == 3:
		if draft_mode and data.get("draft") != true: return _reject("not_a_draft")
		if not draft_mode and data.has("draft"): return _reject("draft_not_product")
		for key in ["marker_aliases_v2_to_v3","marker_aliases_migration_only"]:
			if data.has(key): return _reject("migration_data_not_catalog")
	var expected := _physical_body_orbits()
	var orbit_count: int = GRID.ORBITS.size() + (1 if version == 3 else 0)
	if data.orbits.size() != orbit_count: return _reject("unexpected_orbit_count")
	for body_id: String in data.bodies:
		var body: Variant = data.bodies[body_id]
		if not body is Dictionary or body.get("id") != body_id or typeof(body.get("name")) != TYPE_STRING or not _cell_record(body) or not _position_matches_cell(body): return _reject("invalid_body")
		if typeof(body.get("radius")) not in [TYPE_INT,TYPE_FLOAT] or float(body.radius) < 0.0 or float(body.radius) > max(GRID.SIZE.x,GRID.SIZE.y): return _reject("invalid_body_radius")
		if String(body.get("kind", "")) == "station":
			if not String(body.get("orbit_id", "")).is_empty() or expected.has(body_id): return _reject("station_has_body_orbit")
			continue
		if not expected.has(body_id): return _reject("unbound_nonstation_body")
		var required: String = "" if body_id == "sun" and version == 2 else String(expected[body_id])
		if String(body.get("orbit_id", "")) != required: return _reject("body_orbit_mismatch")
	for body_id: String in expected:
		if not data.bodies.has(body_id) or String(data.bodies[body_id].get("kind", "")) == "station": return _reject("missing_physical_body")
	if not String(data.bodies.sun.get("surface_location_id", "")).is_empty(): return _reject("sun_has_surface")
	var used_cells := {}
	for body_id: String in expected:
		if body_id == "sun" and version == 2: continue
		var orbit_id: String = expected[body_id]
		var orbit: Variant = data.orbits.get(orbit_id)
		if not orbit is Dictionary or orbit.get("id") != orbit_id or orbit.get("body_id") != body_id or not _cell_record(orbit) or not _position_matches_cell(orbit): return _reject("invalid_orbit")
		var body: Dictionary = data.bodies[body_id]
		var markers: Variant = orbit.get("markers")
		var marker_count: int = 3 if version == 2 else 1
		if not markers is Array or markers.size() != marker_count: return _reject("invalid_marker_count")
		var corners: Array[Vector2i] = []
		if version == 2:
			if not _integer(body.get("ring_radius")) or float(body.ring_radius) <= 0.0 or float(body.ring_radius) > max(GRID.SIZE.x,GRID.SIZE.y): return _reject("invalid_legacy_ring")
			for direction in GRID.HEX.DIRECTIONS: corners.append(GRID.cell_from_record(body) + direction * int(body.ring_radius))
		for index in markers.size():
			var marker: Variant = markers[index]
			var expected_id := "orbit_%d" % (index + 1)
			if not marker is Dictionary or marker.get("id") != expected_id or not _cell_record(marker): return _reject("invalid_marker")
			var cell := GRID.cell_from_record(marker)
			if used_cells.has(cell) or (version == 2 and cell not in corners): return _reject("marker_collision_or_ring")
			if (version == 3 or marker.has("position")) and not _position_matches_cell(marker): return _reject("marker_position_mismatch")
			used_cells[cell] = true
		if GRID.cell_from_record(markers[0]) != GRID.cell_from_record(orbit): return _reject("orbit_anchor_mismatch")
		if version == 3:
			var layout: Dictionary = LAYOUT.build(body_id)
			if orbit.get("body_map_id") != layout.body_map_id or not _size_pair(orbit.get("local_grid_size"), Vector2i(512,256)): return _reject("body_area_mismatch")
		if body_id == "sun":
			var sun_cell := GRID.cell_from_record(body) + Vector2i(-(ceili(float(body.radius)) + 1),0)
			if GRID.cell_from_record(orbit) != sun_cell or not String(orbit.get("location_id", "")).is_empty(): return _reject("invalid_sun_orbit")
		else:
			var location := String(orbit.get("location_id", body.get("surface_location_id", "")))
			if String(data.location_orbits.get(location, "")) != orbit_id: return _reject("orbit_location_mismatch")
	for location: String in data.location_orbits:
		var orbit_id: Variant = data.location_orbits[location]
		if location.is_empty() or not orbit_id is String or not data.orbits.has(orbit_id) or orbit_id == SUN_ORBIT: return _reject("invalid_location_orbit")
	if data.location_orbits.get("homebase") != "moon_orbit": return _reject("home_orbit_mismatch")
	return {"ok":true}

static func _cell_record(record: Dictionary) -> bool:
	var pair: Variant = record.get("hex")
	if not pair is Array or pair.size() != 2 or not _integer(pair[0]) or not _integer(pair[1]): return false
	# Reject raw values before any 32-bit Vector2i cast can wrap them.
	var row := float(pair[1])
	var column := float(pair[0])
	if row < 0.0 or row >= GRID.SIZE.y: return false
	var offset_column: float = column + floor(row * 0.5)
	return offset_column >= 0.0 and offset_column < GRID.SIZE.x

static func _size_pair(value: Variant, expected: Vector2i) -> bool:
	return value is Array and value.size() == 2 and _integer(value[0]) and _integer(value[1]) and float(value[0]) == expected.x and float(value[1]) == expected.y

static func _integer(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(value)) and float(value) == floor(float(value))

static func _position_record(cell: Vector2i) -> Array:
	var normalized := GRID.normalized(cell)
	return [normalized.x,normalized.y]

static func _position_matches_cell(record: Dictionary) -> bool:
	var point: Variant = record.get("position")
	if not point is Array or point.size() != 2: return false
	for value in point:
		if typeof(value) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(value)) or float(value) < 0.0 or float(value) > 1.0: return false
	return Vector2(float(point[0]),float(point[1])).is_equal_approx(GRID.normalized(GRID.cell_from_record(record)))

static func _plain_data(value: Variant) -> bool:
	if typeof(value) == TYPE_FLOAT: return is_finite(float(value))
	if value is Dictionary:
		for key in value:
			if not key is String or not _plain_data(value[key]): return false
		return true
	if value is Array:
		for item in value:
			if not _plain_data(item): return false
		return true
	return typeof(value) in [TYPE_NIL,TYPE_BOOL,TYPE_INT,TYPE_STRING]

static func _reject(reason: String) -> Dictionary:
	return {"ok":false,"reason":reason}

