extends "res://scripts/tools/generate_station_outpost_192x192.gd"

const AUTHORING = preload("res://scripts/editor/building_layout_authoring.gd")

# Override the production entry point: exercise the generator entirely in memory.
func _run() -> void:
	var failed := 0
	var source = TERRAIN_MAP_DATA_SCRIPT.load_from_file(SOURCE_MAP_PATH)
	var target = TERRAIN_MAP_DATA_SCRIPT.create_empty("generator_probe", MAP_SIZE, Vector2.ZERO)
	var lookup: Dictionary = _build_tile_lookup(target)
	for sector in SECTOR_ROTATIONS:
		_stamp_sector(source.get_tiles(), lookup, sector, float(SECTOR_ROTATIONS[sector]))
	_copy_building_presentations(source, target)
	var presentation: Dictionary = target.get_place_presentation()
	var baselines: Dictionary = presentation.building_authoring.base_tiles
	var clean_tiles: Array = []
	for key in source.get_place_presentation().building_authoring.base_tiles:
		var cell: Vector2i = AUTHORING.grid_at(key)
		var clean_tile = TERRAIN_TILE_DATA_SCRIPT.from_dict(source.get_tile_at_grid(cell).to_dict())
		AUTHORING.set_fields(clean_tile, source.get_place_presentation().building_authoring.base_tiles[key])
		clean_tiles.append(clean_tile)
	var clean_target = TERRAIN_MAP_DATA_SCRIPT.create_empty("clean_probe", MAP_SIZE, Vector2.ZERO)
	var clean_lookup: Dictionary = _build_tile_lookup(clean_target)
	for sector in SECTOR_ROTATIONS:
		_stamp_sector(clean_tiles, clean_lookup, sector, float(SECTOR_ROTATIONS[sector]))
	var ids: Dictionary = {}
	for prop in presentation.props:
		if ids.has(prop.building_id): failed += 1
		ids[prop.building_id] = true
	if ids.size() != 18: failed += 1
	var restored := 0
	for sector in SECTOR_ROTATIONS:
		var yaw: float = SECTOR_ROTATIONS[sector]
		for key in source.get_place_presentation().building_authoring.base_tiles:
			var cell: Vector2i = AUTHORING.grid_at(key)
			var moved: Vector2i = _rotate_local_grid(cell, yaw) + Vector2i(sector) * SOURCE_SIZE
			# Compare metadata against the normal terrain stamping path, without props.
			var clean_tile = clean_target.get_tile_at_grid(moved)
			if AUTHORING.fields(clean_tile) != baselines.get(AUTHORING.key_at(moved), {}):
				failed += 1
			restored += 1
	for prop in Array(presentation.props).duplicate(true):
		var transaction: Dictionary = AUTHORING.plan(target, "remove", {"building_id": prop.building_id})
		if not transaction.get("ok", false): failed += 1
		else: AUTHORING.apply(target, transaction)
	for key in baselines:
		if AUTHORING.fields(target.get_tile_at_grid(AUTHORING.grid_at(key))) != baselines[key]: failed += 1
	print("EDITOR_BUILDING_GENERATOR ids=%d substrate_checks=%d failed=%d" % [ids.size(), restored, failed])
	quit(1 if failed else 0)
