extends SceneTree

func _init() -> void:
	call_deferred("_test")

func _test() -> void:
	var script = load("res://scripts/meta/polisa_recruit_offers.gd")
	if script == null:
		printerr("FAIL: recruit offer generator missing")
		quit(1)
		return
	var low: Dictionary = {"unit_id":"agent", "skill_values":{"leadership":0.0}, "communication_values":{"speech_quality":0.0}}
	var high: Dictionary = {"unit_id":"agent", "skill_values":{"leadership":1.0}, "communication_values":{"speech_quality":1.0}}
	var a: Array = script.build_offers("batch-1", low, {})
	var b: Array = script.build_offers("batch-1", high, {})
	if a.size() != 4 or b.size() != 4 or a != script.build_offers("batch-1", low, {}):
		printerr("FAIL: offer count or stability")
		quit(1)
		return
	for i in range(4):
		if int(a[i].price) < 200 or float(b[i].quality) < float(a[i].quality) or String(a[i].profile.unit_id).is_empty() or String(a[i].role).is_empty():
			printerr("FAIL: price, skill effect, identity or role")
			quit(1)
			return
	print("PASS: deterministic offers, skill effect, prices and identities")
	quit(0)
