extends "res://scripts/tests/hex_ground_lifecycle_verifier.gd"

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
	_check(rig.sim.embark_hex_ground_actor_group(PackedStringArray(["target"])).ok, "target leaves ground owner")
	var departed := event.duplicate(); departed.event_id = "impact-3"
	_check(rig.sim._commit_air_ground_impact(departed).unit_id == "" and target.health == after, "unboarded position is not a ghost target")
	rig.scene.free()
	print("AIR_GROUND_IMPACT passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)
