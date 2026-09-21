extends SceneTree
const Journey=preload("res://tests/n4_test_journey.gd")
class Commander extends Node:
	var campaign:Node
	var peer:int
	func submit(command:Dictionary) -> Dictionary:return campaign.submit(command,peer)
	func snapshot() -> Dictionary:return campaign.snapshot_for(peer)
	func advance(delta:float) -> void:campaign.advance(delta)
var failed:=0
var checks:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failed+=1;printerr("FAIL ",label)
func run() -> void:
	var campaign:Node=load("res://scripts/core/team_campaign.gd").new(3);campaign.auto_tick=false;root.add_child(campaign)
	campaign.set_guest(7)
	var a:=Commander.new();a.campaign=campaign;a.peer=1;root.add_child(a)
	var b:=Commander.new();b.campaign=campaign;b.peer=7;root.add_child(b)
	check(Journey.command(a,"assign_team",{"peer_id":7,"team":1}).ok,"assign opponent")
	check(Journey.command(a,"start_match").ok,"start opponents")
	# Shared orbital station is reachable from either home using ordinary travel commands.
	check(Journey.trip(a,"station"),"team one boards, flies, handles encounter and lands")
	check(Journey.trip(b,"station"),"team two travels independently to same station")
	check(a.snapshot().ground.enemies.station.has("team1:jaro"),"opponent projected at shared station")
	check(Journey.command(a,"attack",{"unit_id":"ida","target_id":"team1:jaro"}).ok,"real enemy crew target accepted")
	for tick in 80:
		campaign.advance(0.5)
		if b.snapshot().crew.jaro.health<100:break
	check(b.snapshot().crew.jaro.health<100,"opponent projection receives actual damage after ordinary journeys")
	check(campaign.save_game("res://output/n7-pvp-journey.json").ok,"active PvP orders and both teams save")
	check(campaign.load_game("res://output/n7-pvp-journey.json").ok,"active PvP orders restore")
	print("TEAM_PVP_JOURNEY ",checks," checks, ",failed," failures");quit(1 if failed else 0)
