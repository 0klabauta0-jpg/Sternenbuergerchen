extends SceneTree
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const CATALOG = preload("res://scripts/mission/orbit_destination_catalog.gd")
const SCREEN = preload("res://scripts/ui/star_map_screen.gd")
var checks := 0
var failures := 0
var runtime: Dictionary = {}
var commands: Array = []
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("%s %s" % ["PASS" if ok else "FAIL",label])
func read_runtime() -> Dictionary: return runtime.duplicate(true)
func command(op: String,payload: Dictionary) -> Dictionary:
	commands.append([op,payload.duplicate(true)])
	return {"ok":true}
func travel_for(definition: Dictionary) -> Dictionary:
	return {"system_version":definition.version,"phase":"orbit","orbit_id":"sun_orbit" if definition.version == 3 else "planet_orbit","orbit_marker_id":"orbit_1","craft_id":"cutlass","bodies":definition.bodies.duplicate(true),"orbits":definition.orbits.duplicate(true),"location_orbits":definition.location_orbits.duplicate(true),"position":[0.5,0.5]}
func _init() -> void: call_deferred("run")
func run() -> void:
	var raw := FileAccess.get_file_as_string("res://data/singleplayer/star_system.json")
	var legacy: Dictionary = JSON.parse_string(raw)
	var original := legacy.duplicate(true)
	var copy := GRID.orbits_for_version(2)
	copy.clear()
	check(GRID.ORBITS.size() == 5 and GRID.ORBIT_MARKER_IDS == ["orbit_1","orbit_2","orbit_3"] and GRID.orbits_for_version(2).size() == 5 and GRID.orbits_for_version(3).sun_orbit == "sun" and GRID.orbits_for_version(99).is_empty(),"version maps are pure copies; V2 constants untouched")
	var draft := CATALOG.build_v3_draft(legacy)
	check(draft.ok and CATALOG.validate_v3_draft(draft.definition).ok and not CATALOG.validate_v3_product(draft.definition).ok and draft.marker_aliases_migration_only and legacy == original,"strict existing draft path remains separate and source immutable")
	var product := CATALOG.build_v3_product(legacy)
	var geometry: Dictionary = draft.definition.duplicate(true)
	geometry.erase("draft")
	check(product.ok and CATALOG.validate_v3_product(product.definition).ok and not CATALOG.validate_v3_draft(product.definition).ok and product.definition == geometry and not product.has("marker_aliases_v2_to_v3") and not product.definition.has("draft"),"explicit product uses same six-target geometry without draft or aliases")
	var false_draft: Dictionary = product.definition.duplicate(true)
	false_draft.draft = false
	var alias_product: Dictionary = product.definition.duplicate(true)
	alias_product.marker_aliases_v2_to_v3 = {}
	var huge := legacy.duplicate(true)
	huge.bodies.sun.hex[0] += 4294967296
	check(not CATALOG.validate_v3_product(false_draft).ok and not CATALOG.validate_v3_product(alias_product).ok and not CATALOG.build_v3_product(huge).ok,"product rejects draft marker, migration data and raw coordinate wrapping")
	runtime = {"space_travel":travel_for(legacy),"crafts":[{"craft_id":"cutlass","display_name":"Cutlass"}],"campaign":{"selected_location_id":"fortified_outpost","locations":{"fortified_outpost":{"name":"C"}},"jobs":{}},"space_wings":{}}
	var screen := SCREEN.new()
	root.add_child(screen)
	screen.configure(read_runtime,command)
	screen.set_process(false)
	var ids: Array = []
	for button in screen._orbit_target_buttons:
		var id: String = button.get_meta("orbit_id")
		if not ids.has(id): ids.append(id)
	check(screen._orbit_target_buttons.size() == 15 and ids == ["planet_orbit","glut_1a_orbit","glut_1b_orbit","moon_orbit","polisa_orbit"] and screen._canvas._orbits.planet_orbit.markers == legacy.orbits.planet_orbit.markers,"V2 three-marker coordinates and four-row order retained; real Polisa gap closed")
	runtime.space_travel = travel_for(product.definition)
	screen.refresh()
	check(screen._orbit_target_buttons.size() == 6 and screen._canvas._body_labels.size() == 6 and screen._canvas._body_labels.has("sun_orbit") and screen._canvas._orbits.polisa_orbit.body_id == "glut_2" and not screen._canvas._body_labels.has("polisa"),"V3 list and Canvas derive all bodies including Sun and Glut2; station gets no extra orbit")
	check(not screen._approach.visible and not screen._land.visible and screen._canvas._body_for_location("").is_empty() and product.definition.bodies.sun.surface_location_id == "","Sun target has no approach or landing action")
	var polisa: Button
	for button in screen._orbit_target_buttons:
		if button.get_meta("orbit_id") == "polisa_orbit": polisa = button
	polisa.pressed.emit()
	check(commands.back() == ["space_start_quantum",{"craft_id":"cutlass","target_orbit_id":"polisa_orbit","target_orbit_marker_id":"orbit_1"}],"generic target keeps existing command IDs and semantics")
	var first: Button = screen._orbit_target_buttons[0]
	var definitions: Dictionary = screen._canvas.get_orbit_definitions()
	definitions.clear()
	screen.refresh()
	check(screen._orbit_target_buttons[0] == first and screen._canvas.get_orbit_definitions().size() == 6,"unchanged catalog retains controls and returns copied definitions")
	runtime.space_travel.draft = true
	screen.refresh()
	var rejected: bool = screen._orbit_target_buttons.is_empty() and screen._canvas._body_labels.is_empty()
	runtime.space_travel = travel_for(legacy)
	screen.refresh()
	check(rejected and screen._orbit_target_buttons.size() == 15 and not screen._canvas._body_labels.has("sun_orbit") and FileAccess.get_file_as_string("res://data/singleplayer/star_system.json") == raw and legacy == original,"Draft display fails closed; switching back restores untouched V2")
	screen.queue_free()
	print("ORBIT_CATALOG_DISPLAY_RESULT checks=%d failures=%d live_catalog_switched=false" % [checks,failures])
	quit(1 if failures else 0)

