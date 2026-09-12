extends SceneTree
## Bounded rendered probe on this machine; records actual frame intervals.
var game: Node
var frames: Array[float] = []
var physics_times: Array[float] = []
var phase := 0
var elapsed := 0.0
var measurements: Array[Dictionary] = []
var load_ms := 0.0
var ready_for_measurement := false
var last_frame_usec := 0

func _initialize() -> void:
	call_deferred("_start")

func _start() -> void:
	root.size=Vector2i(2560,1440)
	var start: int=Time.get_ticks_usec()
	game=load("res://scenes/game.tscn").instantiate()
	game.load_on_start=false
	game.save_path="res://output/performance-unused-save.json"
	root.add_child(game)
	load_ms=float(Time.get_ticks_usec()-start)/1000.0
	last_frame_usec=Time.get_ticks_usec()
	ready_for_measurement=true

func _process(delta: float) -> bool:
	if not ready_for_measurement: return false
	var now: int=Time.get_ticks_usec()
	var wall_frame_ms: float=float(now-last_frame_usec)/1000.0
	last_frame_usec=now
	elapsed+=delta
	if elapsed>2.0:
		frames.append(wall_frame_ms)
		physics_times.append(float(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS))*1000.0)
	if elapsed>=8.0:
		ready_for_measurement=false
		_finish_phase.call_deferred()
	return false

func _finish_phase() -> void:
	frames.sort()
	physics_times.sort()
	var row: Dictionary={"region":game.simulation.snapshot().region,"logical_ui":str(root.get_visible_rect().size),"window_size":str(DisplayServer.window_get_size()),"render_texture_size":str(root.get_texture().get_size()),"rendering_method":RenderingServer.get_current_rendering_method(),"frames":frames.size(),"load_ms":load_ms,"frame_ms_p50":frames[int(frames.size()*0.50)],"frame_ms_p95":frames[int(frames.size()*0.95)],"physics_ms_p95":physics_times[int(physics_times.size()*0.95)],"static_memory_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"objects":Performance.get_monitor(Performance.OBJECT_COUNT),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)}
	measurements.append(row)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://output/performance-"+str(row.region)+"-1440p.png")
	if phase==0:
		game.simulation.submit({"type":"accept_contract","request_id":"perf-accept"})
		game.simulation.submit({"type":"travel","destination":"rust","request_id":"perf-travel"})
		game.simulation.advance(30.0)
		var start: int=Time.get_ticks_usec()
		game.world.present(game.simulation.snapshot())
		game.world.focus_object("satellite")
		load_ms=float(Time.get_ticks_usec()-start)/1000.0
		phase=1
		frames.clear();physics_times.clear();elapsed=0.0
		ready_for_measurement=true
	else:
		var report: Dictionary={"engine":Engine.get_version_info().string,"hardware":"Ryzen 7 7800X3D / RTX 4070 Ti SUPER","conditions":"Local 2560x1440 renderer; two-second warmup then six-second sample per region. Other desktop tasks may run; no exclusive hardware or final game budget claim.","measurements":measurements}
		var file:=FileAccess.open("res://output/window-performance.json",FileAccess.WRITE)
		file.store_string(JSON.stringify(report,"\t"));file.close()
		print("WINDOW_PERFORMANCE ",JSON.stringify(report))
		quit()
