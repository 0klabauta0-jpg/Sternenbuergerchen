extends RefCounted
## Deterministic extensions on the existing navigation grid. Called on roster/
## infrastructure changes, never per frame. Coordinates are fine-grid axial.
const NAV = preload("res://scripts/meta/base_interior_navigation.gd")
const MODULAR_GEOMETRY = preload("res://scripts/meta/modular_base_geometry.gd")

## Gepruefte Stellplaetze fuer Wohncontainer auf Hex-Boden. Ein Platz = ein Container; Wert = Versatz
## (Feingitter-Zellen) der ersten Habitat-Kopie gegenueber dem Original-Habitat, die zweite Kopie liegt
## HEX_CONTAINER_COPY_STEP Zellen (4,25 m) daneben. Geprueft mit scripts/tests/campaign_housing_site_probe.gd
## gegen die echte Basiskarte: alle Zellen samt 0,75 m Rand begehbar, Abstand zu Pads (3 m), Terminals,
## Spawn und Tank, Hexwege zu Betten, Terminals und Pads mit der echten Sperrmaske.
const HEX_CONTAINER_SITES: Array = [Vector2i(-40, 23), Vector2i(-44, 48), Vector2i(-56, 73), Vector2i(-24, 88)]
const HEX_CONTAINER_COPY_STEP := 17

## Habitat-Kopien eines Wohncontainers auf Hex-Boden: je Kopie zwei fest verbaute Betten.
## Gebaeude Nummer n steht auf Stellplatz n. Altbelege (zwei Betten) bekommen nur eine Kopie.
static func hex_container_housing(source: Dictionary, terrain: Node, infrastructure: Dictionary) -> Dictionary:
	var assets: Array = Array(source.get("assets", [])).duplicate(true)
	var houses: Array = []
	var beds: Array = []
	var habitat: Dictionary = {}
	for asset: Dictionary in assets:
		if asset.get("id") == "habitat_cutaway_01": habitat = asset; break
	var source_beds: Array = Array(source.get("beds", []))
	var kinds: Array = Array(infrastructure.get("campaign_housing_beds", []))
	for index in range(mini(int(infrastructure.get("campaign_housing", 0)), HEX_CONTAINER_SITES.size())):
		var container := index < kinds.size() and int(kinds[index]) >= 4
		for copy in range(2 if container else 1):
			if habitat.is_empty() or source_beds.size() < 2: return _hex_container_failure(source, index, "Habitat oder Quellbetten fehlen")
			var delta: Vector2i = Vector2i(HEX_CONTAINER_SITES[index]) + Vector2i(HEX_CONTAINER_COPY_STEP * copy, 0)
			var offset: Vector3 = NAV.plane_at_grid(delta)
			var building_id := "campaign_habitat_c%02d%s" % [index + 1, "ab"[copy]] if container else "campaign_habitat_%02d" % (index + 1)
			var translated: Array = []
			for bed_index in range(2):
				var original: Dictionary = source_beds[bed_index]
				var raw: Array = original.grid
				var grid := Vector2i(int(raw[0]), int(raw[1])) + delta
				if not terrain.is_walkable(grid): return _hex_container_failure(source, index, "Bettzelle %s nicht begehbar" % str(grid))
				var bed := original.duplicate(true)
				bed.id = "container_%02d_bed_%d" % [index + 1, copy * 2 + bed_index + 1] if container else "field_bed_%02d" % (index * 2 + bed_index + 1)
				bed.grid = [grid.x, grid.y]
				bed.room_id = building_id
				for key in ["sleep_plane", "rest_plane"]:
					bed[key] = [float(original[key][0]) + offset.x, float(original[key][1]) + offset.z]
				translated.append(bed)
			var building := habitat.duplicate(true)
			building.id = building_id
			building.plane = [float(habitat.plane[0]) + offset.x, float(habitat.plane[1]) + offset.z]
			building["nav_delta"] = [delta.x, delta.y]
			assets.append(building); houses.append(building)
			beds.append_array(translated)
	return {"assets":assets, "houses":houses, "beds":beds}

## Kein Teilergebnis: ein Stellplatz, auf dem etwas nicht passt, macht den ganzen Bau ungueltig ("failed": true,
## keine Gebaeude, keine Betten). Der Kauf lehnt dann ab (keine Abbuchung, Maske unveraendert).
static func _hex_container_failure(source: Dictionary, index: int, reason: String) -> Dictionary:
	push_error("Wohncontainer-Stellplatz %d ungueltig: %s" % [index + 1, reason])
	return {"failed":true, "assets":Array(source.get("assets", [])).duplicate(true), "houses":[], "beds":[]}

static func hex_container_site_count() -> int:
	return HEX_CONTAINER_SITES.size()

## Campaign free field bunks are automatic roster aids, not built capacity.
## Paid expansions count only beds actually placed on reachable terrain.
static func recruitment_bed_capacity(source: Dictionary, expanded: Dictionary, infrastructure: Dictionary) -> int:
	return recruitment_bed_ids(source, expanded, infrastructure).size()

static func recruitment_bed_ids(source: Dictionary, expanded: Dictionary, infrastructure: Dictionary) -> Array[String]:
	var layout := expanded if bool(infrastructure.get("paid", false)) or infrastructure.has("campaign_beds") else source
	var ids: Array[String] = []
	var modular_ids: Array[String] = []
	for bed: Dictionary in Array(layout.get("beds", [])):
		var id := String(bed.get("id", ""))
		if id.is_empty(): continue
		if String(bed.get("visual_kind", "")) == "modular_bed":
			if not modular_ids.has(id): modular_ids.append(id)
		elif not ids.has(id): ids.append(id)
	if infrastructure.has("campaign_beds") and not bool(infrastructure.get("paid", false)):
		ids = ids.slice(0, maxi(0, int(infrastructure.campaign_beds)))
	ids.append_array(modular_ids)
	return ids

static func apply_modular_base(layout: Dictionary, modular: Dictionary) -> Dictionary:
	var result := layout.duplicate(true)
	var rooms: Array = Array(modular.get("rooms", [])).duplicate(true)
	var beds: Array = Array(result.get("beds", [])).duplicate(true)
	for record: Dictionary in Array(modular.get("beds", [])):
		for room: Dictionary in rooms:
			if String(room.get("id", "")) != String(record.get("room_id", "")): continue
			beds.append(MODULAR_GEOMETRY.bed_geometry(room, record))
			break
	result["modular_rooms"] = rooms
	result["modular_base"] = modular.duplicate(true)
	result["beds"] = beds
	var capacity: Dictionary = Dictionary(result.get("capacity", {})).duplicate(true)
	capacity["beds"] = beds.size()
	result["capacity"] = capacity
	return result

static func expand(source: Dictionary, terrain: Node, navigation: RefCounted, roster_size: int, infrastructure: Dictionary = {}) -> Dictionary:
	var result := source.duplicate(true)
	var paid := bool(infrastructure.get("paid", false))
	var desired_beds := int(infrastructure.get("beds", 0)) if paid else maxi(roster_size, int(infrastructure.get("beds", 2)))
	if not paid and infrastructure.has("campaign_beds"): desired_beds = maxi(2, int(infrastructure.campaign_beds))
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
	if navigation.has_method("nearest_available_world"): origin = navigation.call("nearest_available_world", origin)
	if not paid and infrastructure.has("campaign_housing") and bool(infrastructure.get("hex_containers", false)):
		var containers := hex_container_housing(source, terrain, infrastructure)
		result["assets"] = containers.assets
		result["campaign_housing"] = containers.houses
		result["campaign_housing_failed"] = bool(containers.get("failed", false))
		result["interiors"] = Array(result.get("interiors", [])).duplicate(true)
		beds.append_array(containers.beds)
	elif not paid and infrastructure.has("campaign_housing"):
		var houses: Array = []
		var assets: Array = Array(result.get("assets", [])).duplicate(true)
		var interiors: Array = Array(result.get("interiors", [])).duplicate(true)
		var source_beds: Array = Array(source.get("beds", []))
		var habitat: Dictionary = {}
		for asset: Dictionary in assets:
			if asset.get("id") == "habitat_cutaway_01": habitat = asset; break
		for index in range(int(infrastructure.campaign_housing)):
			if habitat.is_empty() or source_beds.size() < 2: break
			var delta := Vector2i((index % 5) * 40, 120 + (index / 5) * 40)
			var offset: Vector3 = NAV.plane_at_grid(delta)
			var translated: Array = []
			for bed_index in range(2):
				var original: Dictionary = source_beds[bed_index]
				var raw: Array = original.grid
				var grid := Vector2i(int(raw[0]), int(raw[1])) + delta
				if not terrain.is_walkable(grid) or navigation.find_world_path(origin, terrain.grid_to_world(grid)).is_empty(): break
				var bed := original.duplicate(true)
				bed.id = "field_bed_%02d" % (index * 2 + bed_index + 1)
				bed.grid = [grid.x, grid.y]
				bed.room_id = "campaign_habitat_%02d" % (index + 1)
				for key in ["sleep_plane", "rest_plane"]:
					bed[key] = [float(original[key][0]) + offset.x, float(original[key][1]) + offset.z]
				translated.append(bed)
			if translated.size() != 2: break
			var building := habitat.duplicate(true)
			building.id = "campaign_habitat_%02d" % (index + 1)
			building.plane = [float(habitat.plane[0]) + offset.x, float(habitat.plane[1]) + offset.z]
			building["nav_delta"] = [delta.x, delta.y]
			assets.append(building); houses.append(building)
			beds.append_array(translated)
		result["assets"] = assets
		result["campaign_housing"] = houses
		result["interiors"] = interiors
	# Supplement the furnished habitat with a field-bunk annex west of the pads.
	# Wide row spacing leaves every interaction approach on real walkable terrain.
	for index in range(80):
		if infrastructure.has("campaign_housing"): break
		if beds.size() >= desired_beds: break
		var plane := Vector2(8.0 + float(index % 5) * 1.5, 10.5 + float(index / 5) * 2.5)
		var grid := _plane_grid(plane)
		if not terrain.is_walkable(grid): continue
		var target: Vector2 = terrain.grid_to_world(grid)
		if navigation.find_world_path(origin, target).is_empty(): continue
		var resolved_plane: Vector3 = NAV.plane_at_grid(grid)
		beds.append({"id":"field_bed_%02d" % [index + 1],"grid":[grid.x,grid.y],"room_id":"field_habitat_annex","sleep_plane":[resolved_plane.x,resolved_plane.z - 1.25],"rest_plane":[resolved_plane.x,resolved_plane.z],"sleep_y":0.48,"surface_y":0.3,"rotation_y":0.0,"visual_kind":"field_bunk"})
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
