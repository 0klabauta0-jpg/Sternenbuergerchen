extends RefCounted
## Deterministic extensions on the existing navigation grid. Called on roster/
## infrastructure changes, never per frame. Coordinates are fine-grid axial.
const NAV = preload("res://scripts/meta/base_interior_navigation.gd")

static func expand(source: Dictionary, terrain: Node, navigation: RefCounted, roster_size: int, infrastructure: Dictionary = {}) -> Dictionary:
	var result := source.duplicate(true)
	var paid := bool(infrastructure.get("paid", false))
	var desired_beds := int(infrastructure.get("beds", 0)) if paid else maxi(roster_size, int(infrastructure.get("beds", 2)))
	var desired_pads := int(infrastructure.get("pads", 0)) if paid else maxi(2, int(infrastructure.get("pads", 2)))
	var beds: Array = Array(result.get("beds", [])).duplicate(true)
	var pads: Array = Array(result.get("landing_pads", [])).duplicate(true)
	if paid:
		beds = beds.slice(0, 2 if int(infrastructure.get("habitat", 0)) > 0 else 0)
		pads = pads.slice(0, desired_pads)
		result["paid_infrastructure"] = infrastructure.duplicate(true)
		for asset: Dictionary in result.get("assets", []):
			if asset.id == "habitat_cutaway_01": asset["built"] = int(infrastructure.get("habitat", 0)) > 0
			if asset.id in ["freihafen_hall_01", "utility_fuel_01"]: asset["built"] = int(infrastructure.get("workshop", 0)) > 0
		for terminal: Dictionary in result.get("terminals", []):
			var building := "habitat" if terminal.id in ["personnel", "jobs"] else "workshop"
			terminal["enabled"] = int(infrastructure.get(building, 0)) > 0
			if terminal.id == "flightdeck": terminal.enabled = desired_pads > 0
	var spawn: Array = result.get("avatar_spawn_grid", [36, 40])
	var origin: Vector2 = terrain.grid_to_world(Vector2i(int(spawn[0]), int(spawn[1])))
	# Supplement the furnished habitat with a field-bunk annex west of the pads.
	# Wide row spacing leaves every interaction approach on real walkable terrain.
	for index in range(80):
		if beds.size() >= desired_beds: break
		var plane := Vector2(8.0 + float(index % 5) * 1.5, 10.5 + float(index / 5) * 2.5)
		var grid := _plane_grid(plane)
		if not terrain.is_walkable(grid): continue
		var target: Vector2 = terrain.grid_to_world(grid)
		if navigation.find_world_path(origin, target).is_empty(): continue
		var resolved_plane: Vector3 = NAV.plane_at_grid(grid)
		beds.append({"id":"field_bed_%02d" % [index + 1],"grid":[grid.x,grid.y],"room_id":"field_habitat_annex","sleep_plane":[resolved_plane.x,resolved_plane.z - 0.65],"rest_plane":[resolved_plane.x,resolved_plane.z],"sleep_y":0.48,"surface_y":0.3,"rotation_y":0.0,"visual_kind":"field_bunk"})
	for index in range(maxi(2, pads.size()), desired_pads):
		var plane := Vector2(44.0, 15.5884572681) if index == 2 else Vector2(22.0 + float((index - 3) % 3) * 11.0, 26.0 + float((index - 3) / 3) * 11.0)
		var grid := _plane_grid(plane)
		if not terrain.is_walkable(grid): continue
		if navigation.find_world_path(origin, terrain.grid_to_world(grid)).is_empty(): continue
		pads.append({"id":"homebase_pad_%02d" % [index + 1],"designation":"PAD %02d" % [index + 1],"grid":[grid.x,grid.y],"plane":[plane.x,plane.y],"size":[8.0,6.0],"surface_y":0.0})
	result["beds"] = beds
	result["landing_pads"] = pads
	result["capacity"] = {"beds":beds.size(),"pads":pads.size(),"required_beds":desired_beds,"required_pads":desired_pads}
	return result

static func _plane_grid(plane: Vector2) -> Vector2i:
	var row := roundi(plane.y * NAV.SCALE / (sqrt(3.0) * 0.5))
	return Vector2i(roundi(plane.x * NAV.SCALE - float(row) * 0.5), row)
