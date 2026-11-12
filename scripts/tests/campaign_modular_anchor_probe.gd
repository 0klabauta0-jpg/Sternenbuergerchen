extends SceneTree
const START = preload("res://scripts/meta/game_start_contract.gd")
func _init() -> void: call_deferred("run")
func run() -> void:
	START.request_start(self,"campaign","new")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate(); root.add_child(flow)
	await process_frame
	var base: Node = flow.get("_singleplayer_runtime").get_base_personnel_runtime()
	for origin in [Vector2i(0,0)]:
		for direction in [Vector2i.RIGHT,Vector2i.DOWN]:
			var rooms: Array = []
			for index in range(3):
				var point: Vector2i = origin + direction * index
				rooms.append({"id":"probe%d" % index,"type":["sleep","corridor","storage"][index],"x":point.x,"y":point.y,"rotation":0})
			var result: Dictionary = base.call("validate_modular_base", {"rooms":rooms,"beds":[]})
			print("ANCHOR ", origin, " dir ", direction, " ", result)
	flow.queue_free(); await process_frame; quit()
