extends SceneTree
const NORMALIZER = preload("res://scripts/mission/campaign_active_json_normalizer.gd")
func _initialize() -> void:
	var original := {"inventory": {&"kind": &"medic", &"amount": 3}}
	var result: Dictionary = NORMALIZER.normalize(original)
	if not result.get("ok",false) or result.value != {"inventory":{"kind":"medic","amount":3}} or typeof(result.value.inventory.keys()[0])!=TYPE_STRING:
		printerr("NORMALIZER_FAIL: StringName inventory data")
		quit(1); return
	var invalid: Dictionary = NORMALIZER.normalize({"bad": Vector3(1,2,3)})
	if invalid.get("ok",false):
		printerr("NORMALIZER_FAIL: unsupported object silently converted")
		quit(1); return
	print("ACTIVE_JSON_NORMALIZER_PASS")
	quit(0)
