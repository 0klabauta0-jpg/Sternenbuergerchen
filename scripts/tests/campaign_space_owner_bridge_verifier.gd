extends SceneTree
const ENCOUNTER = preload("res://scripts/core/campaign_space_encounter.gd")
const COMBAT = preload("res://scripts/core/space_combat_state.gd")
const FLIGHT = preload("res://scripts/core/space_flight_state.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const CATALOG = preload("res://scripts/mission/space_component_catalog.gd")

func _initialize() -> void:
	var combat = COMBAT.new()
	var ids := {"player":"space_fixture_player", "hostile":"space_fixture_hostile", "neutral":"space_fixture_neutral"}
	for role in ["player", "hostile", "neutral"]:
		var cell := Vector2i(10 + ["player", "hostile", "neutral"].find(role) * 3, 10)
		var flight = FLIGHT.new()
		assert(flight.configure(ids[role], {"position_plane":GRID.HEX.axial_to_plane(Vector2(cell)), "coordinate_frame":"local", "space_area_id":"fixture_arena", "motion_mode":"tactical"}).ok)
		assert(combat.admit_actor({"craft_id":ids[role], "faction_id":role, "control_domain":"enemy" if role == "hostile" else role, "start_hex":cell, "footprint_hexes":[Vector2i.ZERO]}, flight, true).ok)
		assert(combat.bind_ship_systems(ids[role], CATALOG.effective_stats("buccaneer", CATALOG.default_loadout("buccaneer")), 8.0).ok)
	var encounter = ENCOUNTER.new()
	assert(encounter.start_encounter(ids.player).ok)
	assert(not encounter.bind_combat_owner(combat, {"player":ids.player, "hostile":ids.neutral, "neutral":ids.hostile}).ok)
	assert(encounter.bind_combat_owner(combat, ids).ok)
	assert(encounter.apply_command(_cmd("engage"), {}).ok)
	assert(encounter.apply_command(_cmd("advance"), {"runtime_authorized":true}).ok)
	assert(encounter.get_snapshot().cutlass_hull == 8.0)
	for shot in range(8):
		var event := {"id":"fixture-shot-%d" % shot, "shooter_id":ids.player, "hit_craft_id":ids.hostile, "weapon_slot":"weapon_1", "damage":4.0}
		assert(combat._commit_ship_impact(event).ok)
		assert(combat.advance_ship_systems(1.0).ok)
	assert(encounter.apply_command(_cmd("advance"), {"runtime_authorized":true}).ok)
	assert(encounter.get_snapshot().phase == "rescue_ready")
	assert(encounter.apply_command(_cmd("rescue"), {}).ok)
	assert(encounter.get_completed_result().result == "victory")
	print("CAMPAIGN_SPACE_OWNER_BRIDGE passed")
	quit()

func _cmd(operation: String) -> Dictionary:
	return {"contract_category":"campaign_space", "operation":operation, "payload":{"delta_seconds":1.0}}
