extends SceneTree
const CODEC = preload("res://scripts/mission/checkpoint_value_codec.gd")
const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
var passed := 0
var failed := 0
func _initialize() -> void:
	if not GUARD.require_isolated_user_data(): return
	var actual := {"version":2,"sequence":0,"poll_seconds":0.05,"grid_frame":{"q":[16.0,8.0]},"units":{"pilot":{"status":"aboard","auto_rest_enabled":true,"idle_seconds":0.0}}}
	var wire: Dictionary = JSON.parse_string(JSON.stringify(actual,"",true,true))
	print("RAW_CHECKPOINT_DICTIONARY_EQUAL ",actual==wire)
	check(CODEC.equal_json_values(actual,wire),"exact persisted numeric domain accepts v2 Base integers read as JSON floats")
	for change in [["sequence",1],["sequence",0.25],["sequence","0"],["version",true],["poll_seconds",0.05000000000000001]]:
		var corrupt: Dictionary = wire.duplicate(true)
		corrupt[change[0]] = change[1]
		check(not CODEC.equal_json_values(actual,corrupt),"different value or nonnumeric type remains rejected: "+str(change))
	var corrupt := wire.duplicate(true)
	corrupt.units.pilot.status = "outside"
	check(not CODEC.equal_json_values(actual,corrupt),"nested ownership status is never normalized away")
	corrupt = wire.duplicate(true); corrupt.erase("sequence")
	check(not CODEC.equal_json_values(actual,corrupt),"missing checkpoint field is rejected")
	corrupt = wire.duplicate(true); corrupt.extra = 0
	check(not CODEC.equal_json_values(actual,corrupt),"additional checkpoint field is rejected")
	check(not CODEC.equal_json_values([1,2],[2.0,1.0]),"array ordering remains authoritative")
	check(not CODEC.equal_json_values(NAN,NAN) and not CODEC.equal_json_values(INF,INF),"nonfinite numeric states never compare as valid")
	check(not CODEC.equal_json_values(9007199254740993,9007199254740992.0),"unsafe integer conversion cannot conceal a changed value")
	check(CODEC.equal_json_values(actual,actual.duplicate(true)),"comparison preserves exact native values")
	print("REVIEW_COMPLETION_CHECKPOINT_NUMBERS passed=%d failed=%d" % [passed,failed])
	quit(1 if failed else 0)
func check(ok: bool, label: String) -> void:
	if ok: passed+=1; print("PASS: ",label)
	else: failed+=1; print("FAIL: ",label)
