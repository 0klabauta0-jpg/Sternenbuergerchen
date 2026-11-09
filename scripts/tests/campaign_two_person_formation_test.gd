extends SceneTree
const MOVEMENT = preload("res://scripts/tactical/fireteam_movement_controller.gd")
func _init() -> void:
	var movement = MOVEMENT.new()
	var failed := 0
	for command in ["take", "move", "operate", "defend"]:
		var anchor := Vector2(2116.595,797.7025)
		var records := [{"unit_id":"campaign_leader"},{"unit_id":"campaign_pilot"}]
		var targets: Dictionary = movement.call("_build_formation_targets", anchor, records, "campaign_leader", 1.0, true, {"command_type":command,"formation_leader_slot":"unit_4","center_partial_formation":true})
		var center := (Vector2(targets.campaign_leader)+Vector2(targets.campaign_pilot))*0.5
		var valid := center.distance_to(anchor)<1.0 and Vector2(targets.campaign_leader).distance_to(Vector2(targets.campaign_pilot))>1.0
		if not valid: failed += 1
		print("PASS: " if valid else "FAIL: ",command," two actual members retain spacing around Use anchor center=",center," anchor=",anchor)
		var full: Array = records + [{"unit_id":"legacy_three"},{"unit_id":"legacy_four"}]
		var legacy: Dictionary = movement.call("_build_formation_targets", anchor, full, "campaign_leader", 1.0, true, {"command_type":command})
		var campaign: Dictionary = movement.call("_build_formation_targets", anchor, full, "campaign_leader", 1.0, true, {"command_type":command,"center_partial_formation":true})
		if legacy != campaign: failed += 1
		print("PASS: " if legacy == campaign else "FAIL: ",command," full authored formation remains identical")
	print("CAMPAIGN_TWO_PERSON_FORMATION failed=",failed)
	quit(1 if failed else 0)
