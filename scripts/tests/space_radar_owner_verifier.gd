extends SceneTree
const ROOT = preload("res://scripts/core/simulation_root.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const FLIGHT = preload("res://scripts/core/space_flight_state.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")

func _admit(combat: RefCounted, id: String, flight: RefCounted, area: String, cell: Vector2i, faction: String, domain: String) -> void:
	var proposal := {"expected_revision":flight.get_snapshot().revision, "coordinate_frame":"local", "space_area_id":area, "position_plane":GRID.HEX.axial_to_plane(Vector2(cell)), "motion_mode":"tactical", "assist_mode":"coupled"}
	var movement: Dictionary = flight.validate_area_transition(proposal, 1)
	var admission: Dictionary = combat.validate_new_local_admission({"craft_id":id, "faction_id":faction, "control_domain":domain, "footprint_hexes":[Vector2i.ZERO]}, flight, proposal, 1)
	assert(movement.ok and admission.ok)
	flight._publish_area_transition(movement); combat._publish_new_local_admission(admission)

func _initialize() -> void:
	var sim := ROOT.new(); root.add_child(sim)
	var fleet := FLEET.new(); assert(fleet.configure().ok); fleet.register_craft("ship")
	sim.configure_singleplayer_owners(null, null, null, fleet)
	var wings: RefCounted = sim.get("_space_wing_state")
	assert(wings.ensure_flying_wings("singleplayer", ["ship"], ["ship"], {"ship":"pilot"}).ok)
	var combat: RefCounted = sim.get("_space_combat_state")
	var own: RefCounted = fleet.get_flight_state("ship")
	_admit(combat, "ship", own, "atmosphere:test", Vector2i(10,10), "blue", "player")
	var close := FLIGHT.new(); assert(close.configure("close", {"position_plane":Vector2.ZERO}).ok)
	_admit(combat, "close", close, "atmosphere:test", Vector2i(13,10), "red", "enemy")
	var far := FLIGHT.new(); assert(far.configure("far", {"position_plane":Vector2.ZERO}).ok)
	_admit(combat, "far", far, "atmosphere:test", Vector2i(35,10), "red", "enemy")
	var other := FLIGHT.new(); assert(other.configure("other", {"position_plane":Vector2.ZERO}).ok)
	_admit(combat, "other", other, "atmosphere:other", Vector2i(13,10), "red", "enemy")
	var contacts: Dictionary = sim.get_space_radar_contacts("ship")
	assert(contacts.ok and contacts.contacts == ["close"] and is_equal_approx(contacts.range, 12.0))
	assert(not sim.get_space_radar_contacts("close").ok)
	var projection: Dictionary = sim.get_space_area_snapshot("atmosphere:test", "singleplayer")
	assert(projection.ok and projection.actors.size() == 2)
	var enemy: Dictionary = projection.actors.filter(func(actor: Dictionary): return actor.craft_id == "close")[0]
	assert(enemy.radar_contact and not enemy.has("systems"))
	sim.free()
	print("SPACE_RADAR_OWNER passed")
	quit()
