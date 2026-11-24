extends SceneTree

class StationController extends "res://scripts/tests/mission_tactical_sandbox_controller.gd":
	var test_map
	var test_registry
	var test_view
	func _ready() -> void: pass
	func _process(_delta: float) -> void: pass
	func _get_active_mission_terrain_map_data_for_readability(): return test_map
	func _get_terrain_registry(): return test_registry
	func _get_primary_3d_view(): return test_view

## Attrappe des Hex-Besitzers: Seit b5227ab21 (14.11.) misst das Einsteigen gegen den Ausstiegsanker (get_campaign_ground_ship_access), und den
## liefert der Controller nur mit lebendem Hex-Besitzer (SimulationRoot). Die Attrappe reicht nur dieselbe Hex-Karte weiter; Anker, Rumpfmasken und
## Boarding-Messung bleiben der echte Controllercode.
class HexOwner extends Node:
	var registry
	func is_hex_ground_runtime_active() -> bool: return true
	func is_hex_ground_runtime_required() -> bool: return true
	func get_hex_ground_terrain_registry(): return registry
	func is_air_support_craft_airborne(_id: String) -> bool: return false

var failures := 0
func _initialize() -> void: call_deferred("_run")
func check(value: bool, label: String) -> void:
	print("%s: %s" % ["PASS" if value else "FAIL", label])
	if not value: failures += 1

func _run() -> void:
	var map = load("res://scripts/terrain/terrain_map_data.gd").load_from_file("res://maps/polisa_station.json")
	var registry = load("res://scripts/terrain/terrain_registry.gd").new()
	var size: Dictionary = map.get_tile_size()
	registry.configure_iso_grid(map.get_grid_origin(), size.half_width, size.half_height, map.get_grid_topology())
	for tile in map.get_tiles(): registry.register_tile(tile)
	var station := Node.new(); station.set_meta("location_id", "polisa"); root.add_child(station)
	# Ein Polisa-Besuch der Kampagne traegt die Kennung des Bodenpiloten; erst damit gilt ein gelandetes Schiff als geparkt (_should_keep_campaign_dropship_landed).
	station.set_meta("campaign_ground_pilot_id", "collision-test-pilot")
	station.add_child(registry)
	var view = load("res://scripts/terrain/terrain_map_3d_view.gd").new()
	var hex_owner := HexOwner.new(); hex_owner.name = "SimulationRoot"; hex_owner.registry = registry; station.add_child(hex_owner)
	var controller := StationController.new(); controller.test_map=map; controller.test_registry=registry; controller.test_view=view; station.add_child(controller)
	var craft := {"craft_id":"collision-test-shuttle", "model_id":"cutlass", "craft_type":"dropship", "crew_capacity":8}
	var projection: Dictionary = view.get_station_craft_body_projection(craft)
	check(projection.get("ok", false), "actual Cutlass renderer model and bounds load")
	var pads: Array = load("res://scripts/mission/polisa_station_craft_runtime.gd").station_pads(map)
	check(pads.size()==7, "all seven authored station pads loaded")
	for pad: Dictionary in pads:
		var admission: Dictionary = controller.preview_station_craft_admission(craft, pad.pad_id)
		if not admission.get("ok", false): print("ADMISSION: ", pad.pad_id, " ", admission)
		check(admission.get("ok", false), "%s accepts actual Cutlass body" % pad.pad_id)
		if not admission.get("ok",false): continue
		var raster: Dictionary = load("res://scripts/mission/hex_ground_ship_footprint.gd").new().cells_for_body(registry,craft,admission.position,admission.ground_body_profile)
		if not raster.get("ok",false): print("RASTER_REJECT: ", pad.pad_id, " ", raster)
		check(raster.get("ok",false) and not raster.get("blocked_cells",[]).is_empty(), "%s yields nonempty actual ship mask" % pad.pad_id)
		var body: Dictionary = load("res://scripts/mission/polisa_station_craft_runtime.gd").projected_body(admission.position, admission.ground_body_profile)
		var conflict: Dictionary = load("res://scripts/mission/polisa_station_craft_runtime.gd").preview_admission(craft, [pad], admission.ground_body_profile, [{"pad_id":pad.pad_id,"footprint":body.footprint}], pad.pad_id)
		check(not conflict.get("ok",false), "%s rejects occupied ship footprint" % pad.pad_id)
		controller._mission_drop_cards = [craft.duplicate(true)]
		controller._parallel_drop_sequences_by_craft[craft.craft_id] = {"craft_id":craft.craft_id,"phase":"complete","lz_position":admission.position,"position":admission.position}
		controller._field_landing_by_craft[craft.craft_id] = {"ground_body_profile":admission.ground_body_profile,"resolved_lz_position":admission.position}
		# Seit b5227ab21 (14.11., "Einstieg sucht ab dem Ausstiegsanker statt ab der Rumpfmitte") misst das Einsteigen im Hex-Besuch gegen den Ausstiegsanker
		# (get_campaign_ground_ship_access, ausserhalb des Rumpfs) mit CAMPAIGN_BOARDING_RADIUS, nicht gegen ein Mass am Rumpfrand. Gleiche Aussage wie vorher
		# (neben dem Rumpf angenommen, entfernt abgelehnt), jetzt am Anker festgemacht und auf 0,1 Einheiten genau an der Radiusgrenze.
		var access: Dictionary = controller.get_campaign_ground_ship_access(craft.craft_id)
		if not access.get("ok",false): print("ACCESS_REJECT: ", pad.pad_id, " ", access)
		var anchor: Vector2 = Vector2(access.get("position", Vector2.INF))
		var radius: float = controller.CAMPAIGN_BOARDING_RADIUS
		check(controller._campaign_unit_near_boarding_ship(craft.craft_id,anchor + Vector2(radius - 0.1, 0.0),admission.position), "%s boarding accepts position beside hull" % pad.pad_id)
		check(access.get("ok",false) and not controller._campaign_unit_near_boarding_ship(craft.craft_id,anchor + Vector2(radius + 0.1, 0.0),admission.position), "%s boarding rejects remote position" % pad.pad_id)
		var mask: Dictionary = controller.get_ground_ship_blocked_cells()
		check(access.get("ok",false) and mask.get("ok",false) and not mask.get("blocked_cells",[]).has(access.get("grid",Vector2i(2147483647,2147483647))), "%s boarding anchor lies outside the actual hull mask" % pad.pad_id)
		var own: Dictionary = controller.get_ground_ship_blocked_cells(craft.craft_id)
		check(mask.get("ok",false) and mask.get("blocked_cells",[]).size()==raster.blocked_cells.size(), "%s controller uses actual footprint" % pad.pad_id)
		check(own.get("ok",false) and own.get("blocked_cells",[]).is_empty(), "%s boarding ignores own hull only" % pad.pad_id)
		var other := {"craft_id":"second-ship", "model_id":"cutlass", "craft_type":"dropship", "crew_capacity":8}
		var real_conflict: Dictionary = controller.preview_station_craft_admission(other, pad.pad_id)
		check(not real_conflict.get("ok",false), "%s controller blocks second ship" % pad.pad_id)
		controller._mission_drop_cards.clear(); controller._parallel_drop_sequences_by_craft.clear(); controller._field_landing_by_craft.clear()
	view.free(); station.free()
	print("RESULT: %d failures" % failures)
	if failures==0: print("POLISA_ACTUAL_STATION_COLLISION_PASS")
	quit(0 if failures==0 else 1)
