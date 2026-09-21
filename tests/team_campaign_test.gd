extends SceneTree
var checks:=0
var failures:=0
var sequence:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
func command(sim:Node,type:String,payload:Dictionary={},peer:int=1) -> Dictionary:
	sequence+=1;var c:=payload.duplicate(true);c.type=type;c.request_id="campaign-%d"%sequence
	return sim.submit(c,peer)
func run() -> void:
	check(ResourceLoader.exists("res://scripts/core/team_campaign.gd"),"campaign authority exists")
	if failures:quit(1);return
	var sim:Node=load("res://scripts/core/team_campaign.gd").new(3);sim.auto_tick=false;root.add_child(sim)
	sim.set_guest(7);sim.set_guest(8);sim.set_guest(9)
	check(command(sim,"assign_team",{"peer_id":8,"team":1}).ok,"host assigns first opponent")
	check(command(sim,"assign_team",{"peer_id":9,"team":1}).ok,"host assigns opponent co-commander")
	check(not command(sim,"assign_team",{"peer_id":7,"team":1},8).ok,"guest cannot grant another team's ownership")
	check(command(sim,"start_match").ok,"two cooperative teams start together")
	check(command(sim,"accept_contract",{},7).ok,"ally commands shared team career")
	check(sim.snapshot_for(1).contract.status=="active","host sees ally's accepted mission")
	check(sim.snapshot_for(8).contract.status=="available","opponent's mission remains independent")
	check(command(sim,"assign_work",{"unit_id":"ida","recipe_id":"toolkit"},9).ok,"second opponent controls own team crew")
	check(not sim.snapshot_for(1).work.active,"opponent cannot spend allied inventory")
	check(sim.snapshot_for(8).work.active,"teammate sees opponent work")
	check(not command(sim,"move",{"unit_id":"t0_ida","position":[0,0]},8).ok,"foreign unit reference rejected")
	check(not command(sim,"accept_contract",{},55).ok,"unknown peer rejected")
	check(command(sim,"toggle_pause",{},8).ok,"shared pause available to other team")
	var held:Dictionary=sim.snapshot_for(1);sim.advance(3)
	check(sim.snapshot_for(1).time==held.time and sim.snapshot_for(8).paused,"pause holds both teams")
	check(command(sim,"toggle_pause").ok,"shared pause resumes")
	var before:Dictionary=sim.snapshot_for(8);sim.advance(40)
	check(sim.snapshot_for(8).inventory.toolkit==before.inventory.toolkit+1,"other team's work advances without local camera")
	var path:="res://output/n7-team-save.json"
	check(sim.save_game(path).ok,"atomic team save")
	var saved:Dictionary=sim.snapshot_for(8)
	check(sim.load_game(path).ok,"team save restores")
	check(sim.snapshot_for(8).inventory==saved.inventory,"load preserves other team's inventory")
	check(sim.snapshot_for(1).campaign.home!=sim.snapshot_for(8).campaign.home,"separate planetary home bases")
	print("TEAM_CAMPAIGN ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
