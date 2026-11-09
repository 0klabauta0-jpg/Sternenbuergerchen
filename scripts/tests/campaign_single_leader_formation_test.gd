extends SceneTree
const MOVEMENT = preload("res://scripts/tactical/fireteam_movement_controller.gd")
var failed := 0
func _init() -> void:
	var movement = MOVEMENT.new()
	var target := Vector2(2116.595, 797.7025)
	var records: Array = [{"unit_id": "campaign_leader"}]
	for command in ["take", "move", "operate", "defend"]:
		var state := {"command_type": command, "formation_preset_key": command + ":normal", "formation_leader_slot": "unit_4"}
		var result: Dictionary = movement.call("_build_formation_targets", target, records, "campaign_leader", 1.0, true, state)
		var centered := result.size() == 1 and Vector2(result.get("campaign_leader", Vector2.INF)).is_equal_approx(target)
		if not centered:
			failed += 1
		print("PASS: " if centered else "FAIL: ", command, " singleton uses exact anchor ", result)
	print("SINGLE_LEADER_FORMATION failed=", failed)
	quit(1 if failed else 0)
