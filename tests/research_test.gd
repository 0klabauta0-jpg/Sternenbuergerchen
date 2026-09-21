extends SceneTree
var failures:=0
var checks:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
func run() -> void:
	var sim:Node=load("res://scripts/core/simulation_root.gd").new(3);sim.auto_tick=false;root.add_child(sim)
	# Focused research fixture after an earned bench upgrade; transactions are real commands.
	sim._state.base.workbench_tier=2
	check(sim.submit({"type":"toggle_sender","request_id":"research-power"}).ok,"free starter power for research")
	var before:int=sim.snapshot().inventory.parts
	var command:Dictionary={"type":"assign_work","unit_id":"ida","recipe_id":"research_materials","request_id":"research"}
	var result:Dictionary=sim.submit(command)
	check(result.ok,"research can start at tier two bench")
	if not result.ok:print("RESEARCH ",checks," checks, ",failures," failures");quit(1);return
	check(sim.submit(command)==result,"retry returns original receipt")
	check(sim.snapshot().inventory.parts==before-2,"cost reserved once")
	check(sim.save_game("res://output/n7-research-save.json").ok,"research reservation saves")
	check(sim.load_game("res://output/n7-research-save.json").ok,"research reservation restores")
	sim.advance(90)
	check("refine_alloy" in sim.snapshot().blueprints,"completion unlocks actual recipe")
	check("research_medicine" in sim.snapshot().blueprints,"completion unlocks next branch")
	check(not sim.submit({"type":"assign_work","unit_id":"ida","recipe_id":"research_materials","request_id":"again"}).ok,"finished research cannot charge again")
	check(sim.save_game("res://output/n7-research-save.json").ok,"unlocks validate")
	print("RESEARCH ",checks," checks, ",failures," failures");quit(1 if failures else 0)
