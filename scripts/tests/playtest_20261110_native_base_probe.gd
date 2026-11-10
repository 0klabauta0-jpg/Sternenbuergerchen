extends SceneTree
var samples: Array[float] = []
func _init() -> void: call_deferred("_run")
func _run() -> void:
	load("res://scripts/meta/game_start_contract.gd").request_start(self,"campaign","new")
	var started := Time.get_ticks_usec()
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	await process_frame
	var screen: Node = flow.get_node("HomebaseScreen")
	screen.call("request_operation","navigate",{"mode":"base"})
	for index in range(12): await process_frame
	print("NATIVE_BASE_READY_MS ",(Time.get_ticks_usec()-started)/1000.0)
	var end := Time.get_ticks_msec()+90000
	var previous := Time.get_ticks_usec()
	while Time.get_ticks_msec()<end:
		await process_frame
		var now := Time.get_ticks_usec()
		samples.append((now-previous)/1000.0)
		previous=now
	var path := ProjectSettings.globalize_path("res://output/playtest_20261110/native")
	DirAccess.make_dir_recursive_absolute(path)
	root.get_texture().get_image().save_png(path+"/base.png")
	samples.sort()
	print("NATIVE_BASE_FRAME_MS samples=",samples.size()," p95=",samples[int(samples.size()*.95)]," p99=",samples[int(samples.size()*.99)]," max=",samples.back()," memory=",Performance.get_monitor(Performance.MEMORY_STATIC))
	flow.queue_free()
	await process_frame
	quit()
