extends SceneTree
const ENCOUNTER=preload("res://scripts/core/campaign_space_encounter.gd")
var failures:=0
func _initialize() -> void:
	var owner=ENCOUNTER.new()
	check(owner.start_encounter("dropship_1").ok,"arrival starts encounter")
	check(not owner.apply_command(cmd("rescue")).ok,"no rescue before defeat")
	check(not owner.apply_command(cmd("engage",{"target_id":"buccaneer"})).ok,"neutral cannot be enemy target")
	check(not owner.apply_command(cmd("advance",{"delta_seconds":1})).ok,"untrusted damage rejected")
	check(owner.apply_command(cmd("engage")).ok,"player engages hostile Cutlass")
	for tick in range(8): owner.apply_command(cmd("advance",{"delta_seconds":1}),{"runtime_authorized":true})
	check(owner.get_snapshot().phase=="rescue_ready","combat tick actually destroys Cutlass")
	check(owner.get_snapshot().buccaneer_hull>0,"Buccaneer survives timely intervention")
	check(owner.apply_command(cmd("rescue")).ok,"rescue after combat")
	check(owner.get_completed_result().result=="victory","real victory evidence")
	check(owner.get_completed_result().is_empty(),"completion evidence emitted once")
	var loss=ENCOUNTER.new(); loss.start_encounter("other")
	for tick in range(18): loss.apply_command(cmd("advance",{"delta_seconds":1}),{"runtime_authorized":true})
	check(loss.get_completed_result().result=="defeat","ignoring distress loses neutral")
	print("SPACE_ENCOUNTER failures=",failures); quit(1 if failures else 0)
func cmd(op:String,payload:Dictionary={}) -> Dictionary:
	return {"contract_category":"campaign_space","operation":op,"payload":payload}
func check(value:bool,label:String)->void:
	if not value: failures+=1; push_error(label)
