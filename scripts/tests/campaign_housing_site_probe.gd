extends SceneTree
## Pruefer fuer die Stellplaetze der Wohncontainer: laedt die ECHTE Basiskarte (feines Hexgitter,
## wie BasePersonnelRuntime.configure) und gibt Begehbarkeit und Bewertung der Kandidaten aus.
## Aufruf: --headless -s scripts/tests/campaign_housing_site_probe.gd   (Modus per Umgebungsvariable SB_PROBE=map|scan)
const NAV = preload("res://scripts/meta/base_interior_navigation.gd")
var terrain: Node
var layout: Dictionary

func _init() -> void: call_deferred("_run")

func _load() -> void:
	var base_path := "res://maps/campaign_intro_base.json"
	var map_data = NAV.load_map(base_path)
	layout = NAV.layout(base_path)
	terrain = load("res://scripts/terrain/terrain_registry.gd").new()
	root.add_child(terrain)
	var tile_size: Dictionary = map_data.get_tile_size()
	terrain.configure_iso_grid(map_data.get_grid_origin(), tile_size.half_width, tile_size.half_height, map_data.get_grid_topology())
	for tile in map_data.get_tiles(): terrain.register_tile(tile)

func _cell(plane_x: float, plane_z: float) -> Vector2i:
	var row := roundi(plane_z * NAV.SCALE / (sqrt(3.0) * 0.5))
	return Vector2i(roundi(plane_x * NAV.SCALE - float(row) * 0.5), row)

func _print_map(x0: float, x1: float, z0: float, z1: float) -> void:
	# Eine Zeile je Hexreihe, eine Spalte je 0,25 m. '#' = nicht begehbar, '.' = begehbar, ' ' = keine Kachel.
	var row0 := ceili(z0 * NAV.SCALE / (sqrt(3.0) * 0.5))
	var row1 := floori(z1 * NAV.SCALE / (sqrt(3.0) * 0.5))
	var header := "      x:"
	for step in range(int((x1 - x0) / 0.25)):
		var x := x0 + step * 0.25
		header += str(int(floor(x)) % 10) if absf(x - floor(x)) < 0.01 else " "
	print(header)
	for y in range(row0, row1 + 1):
		var line := ""
		for step in range(int((x1 - x0) / 0.25)):
			var x := x0 + step * 0.25
			var cell := Vector2i(roundi(x * NAV.SCALE - float(y) * 0.5), y)
			var tile = terrain.get_tile_at_grid(cell)
			line += " " if tile == null else ("." if terrain.is_walkable(cell) else "#")
		print("z%5.2f %s" % [float(y) * (sqrt(3.0) * 0.5) / NAV.SCALE, line])

const COPY_STEP := 17 ## Zellen zwischen den zwei Habitat-Kopien eines Containers (Modellbreite 4,24 m)
const MARGIN := 0.75

## Zellen des Quell-Habitats, die das Spiel als Sperre kopiert (gleiche Schleife wie NAV._apply_field_beds).
func _source_blocked() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for x in range(12, 59):
		for y in range(14, 43):
			var cell := Vector2i(x, y)
			var plane := NAV.plane_at_grid(cell)
			if not Rect2(9.0, 3.0, 7.0, 6.0).has_point(Vector2(plane.x, plane.z)): continue
			if not terrain.is_walkable(cell): result.append(cell)
	return result

func _bbox(cells: Array[Vector2i]) -> Rect2:
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	for cell in cells:
		var plane := NAV.plane_at_grid(cell)
		low = Vector2(minf(low.x, plane.x), minf(low.y, plane.z))
		high = Vector2(maxf(high.x, plane.x), maxf(high.y, plane.z))
	return Rect2(low, high - low)

func _cells_in(rect: Rect2) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var low_y := floori(rect.position.y * NAV.SCALE / (sqrt(3.0) * 0.5)) - 1
	var high_y := ceili(rect.end.y * NAV.SCALE / (sqrt(3.0) * 0.5)) + 1
	for y in range(low_y, high_y + 1):
		var low_x := floori(rect.position.x * NAV.SCALE - float(y) * 0.5) - 1
		var high_x := ceili(rect.end.x * NAV.SCALE - float(y) * 0.5) + 1
		for x in range(low_x, high_x + 1):
			var cell := Vector2i(x, y)
			var plane := NAV.plane_at_grid(cell)
			if rect.has_point(Vector2(plane.x, plane.z)): result.append(cell)
	return result

func _exclusions() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for pad: Dictionary in layout.landing_pads:
		var size := Vector2(float(pad.size[0]), float(pad.size[1]))
		var center := Vector2(float(pad.plane[0]), float(pad.plane[1]))
		rects.append(Rect2(center - size * 0.5 - Vector2(3, 3), size + Vector2(6, 6)))
	for terminal: Dictionary in layout.terminals:
		var plane := NAV.plane_at_grid(Vector2i(int(terminal.grid[0]), int(terminal.grid[1])))
		rects.append(Rect2(plane.x - 1.5, plane.z - 1.5, 3.0, 3.0))
	var spawn := NAV.plane_at_grid(Vector2i(int(layout.avatar_spawn_grid[0]), int(layout.avatar_spawn_grid[1])))
	rects.append(Rect2(spawn.x - 2.0, spawn.z - 2.0, 4.0, 4.0))
	rects.append(Rect2(13.5, 6.0, 4.0, 3.6)) ## Tankprop utility_fuel_01 samt Rand
	return rects

func _scan() -> Array:
	var source := _source_blocked()
	var box := _bbox(source)
	print("SOURCE blocked=", source.size(), " bbox=", box, " beds=", layout.beds.map(func(b): return b.grid))
	var origin_plane := Vector2(box.position.x, box.position.y)
	var exclusions := _exclusions()
	var habitat_box := box.grow(1.5)
	var found: Array = []
	for dy in range(-12, 330, 5):
		for dx in range(-60, 340, 4):
			var offset := NAV.plane_at_grid(Vector2i(dx, dy))
			var union := Rect2(box.position.x + offset.x, box.position.y + offset.z, box.size.x + float(COPY_STEP) / NAV.SCALE, box.size.y)
			var wide := union.grow(MARGIN)
			if wide.position.x < 1.0 or wide.position.y < 1.0 or wide.end.x > 94.0 or wide.end.y > 82.0: continue
			var blocked := false
			for rect in exclusions:
				if rect.intersects(union.grow(0.5)): blocked = true; break
			if blocked or habitat_box.intersects(union): continue
			var free := true
			for cell in _cells_in(wide):
				if not terrain.is_walkable(cell): free = false; break
			if not free: continue
			found.append({"delta":Vector2i(dx, dy), "union":union, "distance":(union.get_center() - Vector2(12.5, 6.06)).length()})
	found.sort_custom(func(a, b): return a.distance < b.distance)
	return found

## Baut Sperrmaske mit allen Containern (wie das Spiel ueber set_campaign_housing) und plant echte Hexwege.
func _check(sites: Array) -> void:
	var nav = NAV.new()
	nav.configure_graph(terrain)
	var houses: Array = []
	for site: Vector2i in sites:
		houses.append({"nav_delta":[site.x, site.y]})
		houses.append({"nav_delta":[site.x + COPY_STEP, site.y]})
	nav.set_campaign_housing(houses)
	var mask: Dictionary = nav.get_ground_clearance_mask()
	var blocked := {}
	for cell in mask.blocked_cells: blocked[cell] = true
	print("MASK cells=", blocked.size())
	var pathfinder = load("res://scripts/terrain/terrain_pathfinder.gd").new()
	var spawn := Vector2i(int(layout.avatar_spawn_grid[0]), int(layout.avatar_spawn_grid[1]))
	var targets: Array = []
	for bed: Dictionary in layout.beds: targets.append(["alt " + String(bed.id), Vector2i(int(bed.grid[0]), int(bed.grid[1]))])
	for terminal: Dictionary in layout.terminals: targets.append(["terminal " + String(terminal.id), Vector2i(int(terminal.grid[0]), int(terminal.grid[1]))])
	for pad: Dictionary in layout.landing_pads: targets.append(["pad " + String(pad.id), Vector2i(int(pad.grid[0]), int(pad.grid[1]))])
	var index := 0
	for site: Vector2i in sites:
		index += 1
		for copy in range(2):
			for bed: Dictionary in layout.beds:
				targets.append(["container %d kopie %d %s" % [index, copy, String(bed.id)], Vector2i(int(bed.grid[0]), int(bed.grid[1])) + site + Vector2i(COPY_STEP * copy, 0)])
	for entry in targets:
		var to: Vector2i = entry[1]
		var in_mask: bool = blocked.has(to)
		var started := Time.get_ticks_msec()
		var path: Array = pathfinder.find_path_with_options(spawn, to, terrain, {"blocked_grids":blocked})
		var reached: bool = not path.is_empty() and path[-1] == to
		print("WEG %-40s ziel=%s in_maske=%s erreicht=%s laenge=%d ms=%d" % [entry[0], str(to), str(in_mask), str(reached), path.size(), Time.get_ticks_msec() - started])

func _run() -> void:
	_load()
	var mode := OS.get_environment("SB_PROBE")
	print("PROBE mode=", mode, " tiles=", terrain.get_all_tiles().size(), " spawn=", layout.get("avatar_spawn_grid"))
	if mode == "map":
		_print_map(5.0, 19.0, 2.0, 10.0)
	if mode == "check":
		var sites: Array = []
		for part in OS.get_environment("SB_SITES").split(";", false):
			var pair := part.split(",")
			sites.append(Vector2i(int(pair[0]), int(pair[1])))
		_check(sites)
	if mode == "scan":
		var found := _scan()
		print("CANDIDATES ", found.size())
		var chosen: Array = []
		for entry in found:
			var clear := true
			for other in chosen:
				if (entry.union as Rect2).grow(1.5).intersects(other.union): clear = false; break
			if clear: chosen.append(entry)
			if chosen.size() >= 8: break
		for entry in chosen: print("SITE delta=", entry.delta, " union=", entry.union, " dist=%.1f" % entry.distance)
	quit(0)
