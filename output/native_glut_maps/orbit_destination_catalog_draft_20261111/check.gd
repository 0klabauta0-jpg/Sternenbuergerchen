extends SceneTree
const CATALOG = preload("res://scripts/mission/orbit_destination_catalog.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const LAYOUT = preload("res://scripts/mission/orbit_approach_layout.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("%s %s" % ["PASS" if ok else "FAIL",label])
func _init() -> void:
	var path := "res://data/singleplayer/star_system.json"
	var raw := FileAccess.get_file_as_string(path)
	var legacy: Dictionary = JSON.parse_string(raw)
	var original := legacy.duplicate(true)
	var result := CATALOG.build_v3_draft(legacy)
	check(result.get("ok",false) and legacy == original, "actual V2 compiles without source mutation: " + str(result.get("reason","")))
	if not result.get("ok",false): finish(); return
	var d: Dictionary = result.definition
	check(d.version == 3 and d.draft == true and d.orbits.size() == 6 and CATALOG.validate_v3_draft(d).ok, "six single-marker draft destinations")
	var preserved: bool = d.location_orbits == legacy.location_orbits
	for id: String in GRID.ORBITS:
		preserved = preserved and d.orbits[id].markers.size() == 1 and d.orbits[id].markers[0].id == "orbit_1" and d.orbits[id].markers[0].hex == legacy.orbits[id].markers[0].hex and d.orbits[id].position == legacy.orbits[id].position
	var bodies: Dictionary = d.bodies.duplicate(true)
	bodies.sun.orbit_id = ""
	check(preserved and bodies == legacy.bodies, "existing IDs, first markers, bodies and locations retained")
	var sun: Dictionary = d.orbits.sun_orbit
	check(sun.hex == [58,128] and GRID.HEX.distance(GRID.cell_from_record(d.bodies.sun),GRID.cell_from_record(sun)) == 6 and d.bodies.sun.surface_location_id == "" and not sun.has("location_id") and sun.name.begins_with("Glut"), "canonical sun radius-plus-one target without surface")
	check(not result.body_orbits.has("polisa") and not result.body_area_ids.has("polisa") and d.orbits.polisa_orbit.body_id == "glut_2" and d.location_orbits.polisa == "polisa_orbit", "station excluded and existing Polisa body binding retained")
	var areas: bool = GRID.pair(d.grid_size) == Vector2(256,256)
	for body: String in result.body_orbits:
		var orbit: Dictionary = d.orbits[result.body_orbits[body]]
		areas = areas and orbit.body_map_id == LAYOUT.build(body).body_map_id and orbit.local_grid_size == [512,256] and result.body_area_ids[body] == orbit.body_map_id
	check(areas, "local canonical areas512x256; strategic grid256 unchanged")
	var aliases: Dictionary = result.marker_aliases_v2_to_v3
	var migration: bool = result.marker_aliases_migration_only == true and aliases.size() == 5
	for id: String in GRID.ORBITS: migration = migration and aliases[id] == {"orbit_1":"orbit_1","orbit_2":"orbit_1","orbit_3":"orbit_1"}
	check(migration, "explicit migration-only aliases for old markers")
	var unknown := legacy.duplicate(true)
	unknown.bodies["unknown"] = unknown.bodies.planet.duplicate(true)
	unknown.bodies.unknown.id = "unknown"
	var malformed := legacy.duplicate(true)
	malformed.orbits.moon_orbit.markers[1].id = "orbit_1"
	check(not CATALOG.build_v3_draft(unknown).ok and not CATALOG.build_v3_draft(malformed).ok, "unknown nonstation and malformed legacy marker rejected")
	var collision := legacy.duplicate(true)
	collision.bodies.sun.hex = [112,139]
	var p := GRID.normalized(Vector2i(112,139))
	collision.bodies.sun.position = [p.x,p.y]
	var outside := legacy.duplicate(true)
	outside.bodies.sun.hex = [0,0]
	outside.bodies.sun.position = [0,0]
	check(CATALOG.build_v3_draft(collision).get("reason") == "sun_marker_collision" and CATALOG.build_v3_draft(outside).get("reason") == "sun_marker_out_of_bounds", "sun collision and bounds reject without relocation")
	var huge_cell := legacy.duplicate(true)
	huge_cell.bodies.sun.hex[0] += 4294967296
	var huge_size := legacy.duplicate(true)
	huge_size.grid_size[0] += 4294967296
	var huge_ring := legacy.duplicate(true)
	huge_ring.bodies.planet.ring_radius += 4294967296
	var huge_sun := d.duplicate(true)
	huge_sun.bodies.sun.radius += 4294967296
	check(not CATALOG.build_v3_draft(huge_cell).ok and not CATALOG.build_v3_draft(huge_size).ok and not CATALOG.build_v3_draft(huge_ring).ok and not CATALOG.validate_v3_draft(huge_sun).ok, "raw values cannot wrap into valid grid coordinates, sizes or radii")
	d.bodies.planet.hex[0] = 0
	result.body_orbits.planet = "bad"
	aliases.moon_orbit.orbit_1 = "bad"
	var rebuilt := CATALOG.build_v3_draft(legacy)
	check(rebuilt.ok and rebuilt.definition.bodies == original.bodies.merged({"sun":rebuilt.definition.bodies.sun}, true) and rebuilt.body_orbits.planet == "planet_orbit" and rebuilt.marker_aliases_v2_to_v3.moon_orbit.orbit_1 == "orbit_1" and legacy == original and raw == FileAccess.get_file_as_string(path), "outputs independently owned and file remains unchanged")
	finish()
func finish() -> void:
	print("ORBIT_DESTINATION_DRAFT_RESULT checks=%d failures=%d runtime_wired=false" % [checks,failures])
	quit(1 if failures else 0)


