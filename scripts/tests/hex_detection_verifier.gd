extends SceneTree
const PATH := "res://scripts/core/hex_detection_state.gd"
var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func _check(value: bool, label: String) -> void:
	if value:
		passed += 1
		print("PASS: ",label)
	else:
		failed += 1
		print("FAIL: ",label)

func _run() -> void:
	_check(ResourceLoader.exists(PATH),"HexDetectionState is implemented")
	if failed>0:
		_finish()
		return
	var state = load(PATH).new()
	_check(state.has_method("read_pair") and state.has_method("build_episode_snapshot"),"episode exposes read-only deadline projections")
	if failed>0:
		_finish()
		return
	var first: Dictionary = state.observe_pair("observer","target",true,10,4)
	_check(first.episode_started and first.ready_tick==14 and not first.detection_complete,"first sight starts one skill-dependent deadline")
	var repeat: Dictionary = state.observe_pair("observer","target",true,10,100)
	_check(state.read_pair("observer","target",10).ready_tick==14 and state.read_pair("missing","target",10).is_empty(),"read does not create or reschedule episodes")
	var projection: Array = state.build_episode_snapshot(11)
	_check(projection.size()==1 and projection[0].ticks_remaining==3,"snapshot derives remaining time from fixed deadline")
	projection[0].ready_tick=0
	_check(state.read_pair("observer","target",11).ready_tick==14,"snapshot mutation cannot change episode")
	_check(not repeat.episode_started and repeat.ready_tick==14,"same tick cannot start or reroll another episode")
	_check(not state.observe_pair("observer","target",true,13,0).detection_complete,"later changed delay cannot accelerate existing deadline")
	_check(state.observe_pair("observer","target",true,14,100).detection_complete,"deadline completes on simulation tick")
	_check(not state.observe_pair("observer","target",false,12,4).ok,"stale visibility cannot erase current knowledge")
	_check(state.observe_pair("observer","target",true,15,4).detection_complete,"stale update preserves completed episode")
	_check(state.observe_pair("observer","target",false,16,4).lost,"real sight loss ends episode")
	var resumed: Dictionary = state.observe_pair("observer","target",true,17,4)
	_check(resumed.episode_started and resumed.ready_tick==21 and not resumed.detection_complete,"reacquisition starts a fresh episode")
	state.clear()
	var left: Dictionary = state.observe_pair("a:b","c",true,1,3)
	var right: Dictionary = state.observe_pair("a","b:c",true,1,8)
	_check(left.ready_tick==4 and right.ready_tick==9 and state.observe_pair("a:b","c",true,2,8).ready_tick==4,"structured IDs avoid colon collisions")
	_check(state.observe_pair("instant","target",true,2,0).detection_complete,"zero delay can complete immediately")
	_check(not state.observe_pair("","target",true,2,1).ok,"empty observer rejected")
	_check(not state.observe_pair("observer","",true,2,1).ok,"empty target rejected")
	_check(not state.observe_pair("observer","target",true,2,-1).ok,"negative delay rejected")
	state.clear()
	state.observe_pair("a","t",true,5,2)
	state.observe_pair("b","a",true,5,2)
	state.observe_pair("c","d",true,5,2)
	state.forget_unit("a")
	_check(state.observe_pair("a","t",true,5,2).episode_started and state.observe_pair("b","a",true,5,2).episode_started,"removing unit clears observer and target references")
	_check(not state.observe_pair("c","d",true,5,2).episode_started,"unrelated episode retained")
	state.clear()
	_check(state.observe_pair("c","d",true,0,0).episode_started,"clear resets map and simulation clock context")
	var limit: int = 9223372036854775807
	state.clear()
	_check(state.observe_pair("edge","target",true,limit-1,1).ready_tick==limit,"last representable deadline preserved")
	_check(not state.observe_pair("edge","target",false,limit,1).ok,"overflowing timing rejected before sight loss")
	_check(not state.observe_pair("edge","target",false,-1,0).ok,"negative tick rejected before sight loss")
	_check(state.observe_pair("edge","target",true,limit,0).detection_complete,"invalid timings preserve existing episode")
	_finish()

func _finish() -> void:
	print("RESULTS: %d passed, %d failed" % [passed,failed])
	if failed==0: print("HEX_DETECTION_PASS")
	quit(0 if failed==0 else 1)
