extends SceneTree
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var map = load("res://scripts/terrain/terrain_map_data.gd").load_from_file("res://maps/polisa_station.json")
	if map == null: printerr("FAIL: station map"); quit(1); return
	var terrain = load("res://scripts/terrain/terrain_registry.gd").new()
	root.add_child(terrain)
	var size: Dictionary = map.get_tile_size()
	terrain.configure_iso_grid(map.get_grid_origin(), size.half_width, size.half_height, map.get_grid_topology())
	for tile in map.get_tiles(): terrain.register_tile(tile)
	var facts: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/polisar_r09_20261114/layout_compiled.json"))
	var globe: Dictionary = {}
	for item: Dictionary in facts.furniture:
		if item.get("id") == "globe": globe = item
	if globe.is_empty(): printerr("FAIL: authored globe missing"); quit(1); return
	var rect: Array = globe.rect
	var plane := Vector2((float(rect[0])+float(rect[2]))/2.0, (float(rect[1])+float(rect[3]))/2.0-70.0)
	var hex = load("res://scripts/terrain/hex_grid.gd")
	var grid: Vector2i = hex.round_axial(hex.plane_to_axial(plane))
	if grid != Vector2i(35,-69): printerr("FAIL: controller globe coordinate drift"); quit(1); return
	var ground := {"units_by_id":{},"occupant_by_grid":{},"terrain_revision":terrain.get_revision()}
	var access = load("res://scripts/mission/polisa_globe_access.gd")
	var result: Dictionary = access.resolve("polisa", grid, [{"unit_id":"local", "grid":grid, "fit":true}], terrain, ground)
	if not result.ok or not terrain.is_walkable(result.spawn_grid): printerr("FAIL: no legal nearby spawn"); quit(1); return
	terrain.free()
	print("PASS: authored globe and walkable recruit spawn")
	quit(0)
