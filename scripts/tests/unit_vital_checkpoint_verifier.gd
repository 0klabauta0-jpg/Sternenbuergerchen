extends SceneTree
const VITAL = preload("res://scripts/npc/unit_vital_status.gd")
func _initialize() -> void:
 var incoming := {"state":"down", "health_points":0, "bleedout_ticks":42}
 var restored: Dictionary = VITAL.prepare_checkpoint_value(incoming, 100)
 assert(restored.ok and restored.model.to_dict() == incoming)
 var bad := incoming.duplicate()
 bad.health_points = 101
 assert(not VITAL.prepare_checkpoint_value(bad, 100).ok)
 bad.health_points = -1
 assert(not VITAL.prepare_checkpoint_value(bad, 100).ok)
 bad = incoming.duplicate()
 bad.bleedout_ticks = 1.5
 assert(not VITAL.prepare_checkpoint_value(bad, 100).ok)
 bad = incoming.duplicate()
 bad.state = "unknown"
 assert(not VITAL.prepare_checkpoint_value(bad, 100).ok)
 print("UNIT_VITAL_CHECKPOINT_PASS")
 quit(0)
