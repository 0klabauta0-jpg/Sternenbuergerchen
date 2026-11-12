extends SceneTree
const CONFIG = preload("res://scripts/meta/campaign_start_configuration.gd")
func _initialize() -> void:
 var old := {"schema_version":1, "craft":{"id":"c"}}
 var first: Dictionary = CONFIG.resolve_checkpoint_run_id(old, false)
 var again: Dictionary = CONFIG.resolve_checkpoint_run_id(old.duplicate(true), false)
 assert(first.ok and first.id == again.id and first.id.length() == 64)
 var changed := old.duplicate(true)
 changed.craft.id = "other"
 assert(CONFIG.resolve_checkpoint_run_id(changed,false).id != first.id)
 var one: Dictionary = CONFIG.resolve_checkpoint_run_id({}, true)
 var two: Dictionary = CONFIG.resolve_checkpoint_run_id({}, true)
 assert(one.ok and two.ok and one.id != two.id)
 assert(CONFIG.resolve_checkpoint_run_id({"campaign_run_id":one.id},false).id == one.id)
 assert(not CONFIG.resolve_checkpoint_run_id({"campaign_run_id":"bad"},false).ok)
 print("CAMPAIGN_CHECKPOINT_RUN_ID_PASS")
 quit(0)
