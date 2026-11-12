extends "res://scripts/tests/hex_ground_lifecycle_verifier.gd"
const EQUIPMENT = preload("res://scripts/core/singleplayer_ship_equipment_state.gd")
const DISPERSION = preload("res://scripts/mission/air_support_dispersion.gd")
class PilotActor extends Actor:
	var dropship_skill := 1.0
	var fighter_skill := 0.0
	func get_character_profile_bundle() -> Dictionary:
		return {"platform_values":{"dropship_piloting":dropship_skill, "fighter_piloting":fighter_skill}}

func _run() -> void:
	var rig: Dictionary = _admission_rig([Vector2i.ZERO, Vector2i(1, 0)])
	var target = _add_admission_actor(rig, "target")
	_add_admission_actor(rig, "pilot")
	var placements: Array[Dictionary] = [{"unit_id":"target", "grid":Vector2i.ZERO}]
	_check(rig.sim.admit_hex_ground_units(placements).ok, "real ground owner admits target")
	var event := {"event_id":"impact-1", "impact_hex":Vector2i.ZERO, "pilot_id":"pilot", "team_id":"blue", "damage":20}
	var initial: int = target.health
	var hit: Dictionary = rig.sim._commit_air_ground_impact(event)
	_check(hit.ok and hit.unit_id == "target" and target.health < initial, "committed occupied hex uses existing damage owner including friendly fire")
	var after: int = target.health
	_check(rig.sim._commit_air_ground_impact(event).replayed and target.health == after, "replayed impact cannot deal damage twice")
	var changed := event.duplicate(); changed.damage = 30
	_check(rig.sim._commit_air_ground_impact(changed).reason == "event_id_conflict" and target.health == after, "conflicting event leaves target unchanged")
	var miss := event.duplicate(); miss.event_id = "impact-2"; miss.impact_hex = Vector2i(1, 0)
	_check(rig.sim._commit_air_ground_impact(miss).unit_id == "" and target.health == after, "empty hex is a miss")
	var profile_pilot = PilotActor.new(); profile_pilot.unit_id = "profile_pilot"
	rig.scene.add_child(profile_pilot); rig.units.register_unit("profile_pilot", profile_pilot); rig.sim.register_known_unit("profile_pilot", profile_pilot)
	var equipment = EQUIPMENT.new(); _check(equipment.configure([{"craft_id":"drop", "model_id":"cutlass"}, {"craft_id":"fighter", "model_id":"buccaneer"}]).ok, "real equipment owner configured")
	rig.sim.configure_ship_equipment(equipment)
	var seed := -1
	for candidate in range(100):
		if DISPERSION.resolve(Vector2i.ZERO, 1.0, candidate).impact_hex == Vector2i.ZERO: seed = candidate; break
	var piloted := {"event_id":"piloted-1", "craft_id":"drop", "pilot_id":"profile_pilot", "team_id":"blue", "aim_hex":Vector2i.ZERO, "seed":seed, "damage":5}
	var piloted_result: Dictionary = rig.sim._commit_piloted_air_ground_impact(piloted)
	_check(seed >= 0 and piloted_result.ok and piloted_result.radius == 1 and piloted_result.unit_id == "target" and target.health < after, "actual dropship skill scatters and damages actual occupant")
	var after_piloted: int = target.health
	profile_pilot.dropship_skill = 0.0
	_check(rig.sim._commit_piloted_air_ground_impact(piloted).replayed and target.health == after_piloted, "replay retains original skill outcome and never applies twice")
	var fighter := piloted.duplicate(); fighter.event_id = "piloted-2"; fighter.craft_id = "fighter"
	_check(rig.sim._commit_piloted_air_ground_impact(fighter).radius == 10, "fighter uses fighter skill, not dropship skill")
	var invalid := piloted.duplicate(); invalid.event_id = "piloted-3"; profile_pilot.dropship_skill = -1.0
	_check(not rig.sim._commit_piloted_air_ground_impact(invalid).ok, "unavailable pilot skill fails closed")
	after = target.health
	_check(rig.sim.embark_hex_ground_actor_group(PackedStringArray(["target"])).ok, "target leaves ground owner")
	var departed := event.duplicate(); departed.event_id = "impact-3"
	_check(rig.sim._commit_air_ground_impact(departed).unit_id == "" and target.health == after, "unboarded position is not a ghost target")
	rig.scene.free()
	print("AIR_GROUND_IMPACT passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)
