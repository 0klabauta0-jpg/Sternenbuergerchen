extends SceneTree
const STORE_PATH := "user://campaigns/test/active_checkpoint.json"
func validate(value: Dictionary) -> Dictionary:
 return {"ok":true} if value.get("schema") == "active_test" and value.get("owner") == "actual" else {"ok":false,"reason":"incomplete"}
func _initialize() -> void:
 var script = load("res://scripts/meta/campaign_active_checkpoint_store.gd")
 if script == null:
  printerr("active store absent")
  quit(1)
  return
 assert(not script.save_checkpoint({"schema":"active_test"},Callable(self,"validate"),STORE_PATH).ok)
 var data := {"schema":"active_test", "owner":"actual", "precise":1.2345678901234567}
 assert(script.save_checkpoint(data,Callable(self,"validate"),STORE_PATH).ok)
 var before := FileAccess.get_file_as_bytes(STORE_PATH)
 assert(not script.save_checkpoint({"schema":"active_test","owner":"invalid"},Callable(self,"validate"),STORE_PATH).ok)
 assert(FileAccess.get_file_as_bytes(STORE_PATH) == before)
 var nonportable := data.duplicate(true)
 nonportable["position"] = Vector2(1,2)
 assert(not script.save_checkpoint(nonportable,Callable(self,"validate"),STORE_PATH).ok)
 assert(FileAccess.get_file_as_bytes(STORE_PATH) == before)
 assert(not script.save_checkpoint(data,Callable(self,"validate"),"user://campaigns/introduction/checkpoint_v1.json").ok)
 assert(not script.save_checkpoint(data,Callable(self,"validate"),"user://campaigns/introduction/./checkpoint_v1.json").ok)
 assert(not script.save_checkpoint(data,Callable(self,"validate"),"user://campaigns/introduction/CHECKPOINT_V1.JSON").ok)
 var loaded: Dictionary = script.load_checkpoint(Callable(self,"validate"),STORE_PATH)
 assert(loaded.ok and loaded.payload.schema == data.schema and loaded.payload.owner == data.owner)
 assert(absf(float(loaded.payload.precise) - float(data.precise)) < 0.000000000000001)
 assert(not script.load_checkpoint(Callable(),STORE_PATH).ok)
 assert(not script.save_checkpoint(data,Callable(self,"validate"),"user://outside.json").ok)
 print("CAMPAIGN_ACTIVE_STORE_PASS")
 quit(0)
