extends SceneTree
var failures:=0
var checks:=0
var serial:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
func send(sim:Node,kind:String,data:Dictionary={},peer:int=1) -> Dictionary:
	serial+=1;var c:=data.duplicate(true);c.type=kind;c.request_id="integrity-%d"%serial;return sim.submit(c,peer)
func fresh() -> Node:
	var sim:Node=load("res://scripts/core/team_campaign.gd").new(3);sim.auto_tick=false;root.add_child(sim);return sim
func run() -> void:
	var sim:=fresh();sim.set_guest(7)
	check(send(sim,"assign_team",{"peer_id":1,"team":1}).ok,"host changes team")
	check(send(sim,"start_match").ok,"match starts")
	check(sim.save_game("res://output/n7-world-integrity.json").ok,"save host on team two")
	var restored:=fresh()
	check(restored.load_game("res://output/n7-world-integrity.json").ok,"fresh process state reloads")
	check(restored.snapshot().campaign.team==1,"host team survives new instance")
	check(send(sim,"open_lobby").ok,"lobby opens")
	check(not send(sim,"toggle_pause",{},7).ok,"guest cannot unpause open lobby")
	var time:float=sim.snapshot().time;sim.advance(2)
	check(sim.snapshot().time==time,"open lobby simulation remains frozen")
	check(sim.has_method("_bind_world"),"planet state owner exists")
	if not sim.has_method("_bind_world"):print("TEAM_WORLD ",checks," checks, ",failures," failures");quit(1);return
	# Isolated world ownership fixture: exhaust one planet, then switch bindings.
	sim._cores[0]._state.resources.mining_site.remaining=0
	sim._bind_world(0,"ice")
	check(sim._cores[0]._state.resources.mining_site.remaining>0,"other planet has independent stock")
	sim._cores[0]._state.resources.mining_site.remaining=3
	check(sim._cores[1]._state.resources.mining_site.remaining==3,"co-located opponents share finite stock")
	sim._cores[0]._state.ground.enemies.bunker_surface.surface_guard.health=0
	sim._cores[0]._state.ground.enemies.bunker_surface.surface_guard.defeated=true
	check(sim._cores[1]._state.ground.enemies.bunker_surface.surface_guard.defeated,"guard death shared between teams")
	sim._bind_world(0,"rust")
	check(sim._cores[0]._state.resources.mining_site.remaining==0,"return preserves depleted original stock")
	check(sim.save_game("res://output/n7-world-integrity.json").ok,"shared world stocks save")
	var loaded:=fresh();check(loaded.load_game("res://output/n7-world-integrity.json").ok,"shared world stocks reload")
	loaded._bind_world(0,"ice")
	check(loaded._cores[0]._state.resources.mining_site.remaining==3,"other planet stock persists across process")
	check(loaded._cores[0]._state.ground.enemies.bunker_surface.surface_guard.defeated,"other planet NPC death persists")
	var bot:=fresh();check(send(bot,"set_team_ai",{"team":1,"enabled":true}).ok,"host enables initial economic AI")
	check(send(bot,"start_match").ok,"AI occupies opposing start without human guest")
	bot.advance(2);bot.advance(2)
	check(bot._cores[1]._state.work.active,"AI starts real repair transaction")
	bot.advance(30)
	check(bot._cores[1]._state.ship.condition>72 and bot._cores[1]._state.inventory.scrap<8,"AI earns repair by consuming own materials")
	print("TEAM_WORLD ",checks," checks, ",failures," failures");quit(1 if failures else 0)
