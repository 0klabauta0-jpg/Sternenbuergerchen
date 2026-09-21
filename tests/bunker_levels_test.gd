extends SceneTree
var failures:=0
var count:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	count+=1
	if not ok:failures+=1;printerr("FAIL ",label)
func run() -> void:
	var sim:Node=load("res://scripts/core/simulation_root.gd").new(3);sim.auto_tick=false;root.add_child(sim)
	# Isolated site fixture: legitimate surface elevator coordinates, both actors idle.
	var catalog=load("res://scripts/core/catalog.gd")
	sim._state.region="bunker_surface"
	sim._state.ship.position=catalog.landmarks("bunker_surface").shuttle.duplicate()
	sim._state.ship.target=sim._state.ship.position.duplicate()
	for unit in sim._state.crew.values():
		unit.position=catalog.landmarks("bunker_surface").bunker_entry.duplicate();unit.target=unit.position.duplicate()
	var before:Dictionary=sim.snapshot()
	var result:Dictionary=sim.submit({"type":"use_elevator","unit_ids":["ida"],"request_id":"down"})
	check(result.ok,"selected crew can use elevator")
	var state:Dictionary=sim.snapshot()
	check(state.region=="bunker_surface","site stays canonical surface")
	check(state.crew.ida.get("level_region","")=="bunker_depths","Ida enters lower level")
	check(state.crew.jaro.position==before.crew.jaro.position,"Jaro remains above")
	check(state.ship.position==before.ship.position,"ship stays outside")
	check(not sim.submit({"type":"board","unit_id":"ida","request_id":"board"}).ok,"cannot board through floors")
	check(not sim.submit({"type":"move","unit_id":"ida","view_region":"bunker_surface","position":[0,0],"request_id":"wrong"}).ok,"camera mismatch rejected")
	check(sim.save_game("res://output/n7-levels-save.json").ok,"split levels save validates")
	check(sim.load_game("res://output/n7-levels-save.json").ok,"split levels restore")
	check(sim.snapshot().crew.ida.get("level_region","")=="bunker_depths","restore preserves floor")
	print("BUNKER_LEVELS ",count," checks, ",failures," failures")
	quit(1 if failures else 0)
