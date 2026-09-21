extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
func run() -> void:
	check(ResourceLoader.exists("res://scripts/core/team_roster.gd"),"team authority exists")
	if failures:quit(1);return
	var roster=load("res://scripts/core/team_roster.gd").new()
	check(roster.team_for(1)==0,"host starts in team zero")
	for peer in range(2,9):check(roster.join(peer,0).is_empty(),"eight commanders fit in one team")
	check(not roster.join(9,0).is_empty(),"ninth commander rejected without spillover")
	for peer in range(9,17):check(roster.join(peer,1).is_empty(),"second team supports eight commanders")
	check(not roster.join(17,1).is_empty(),"full lobby rejects seventeenth player")
	check(roster.team_for(17)==-1,"rejected join grants no authority")
	check(not roster.assign(2,3,1).is_empty(),"guest cannot reassign another commander")
	roster.leave(16)
	check(roster.assign(1,8,1).is_empty(),"host can balance lobby before start")
	check(roster.team_for(8)==1,"assignment actually changes owning team")
	roster.locked=true
	check(not roster.assign(1,8,0).is_empty(),"running game cannot switch teams")
	check(not roster.join(18,0).is_empty(),"uninvited late join requires host lobby")
	check(roster.team_for(8)==1,"rejected switch preserves rights")
	print("TEAM_ROSTER ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
