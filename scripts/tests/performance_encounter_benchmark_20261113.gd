extends SceneTree
## Compare the former presenter expression against the new narrow read on one
## actually configured campaign. Startup and scene teardown are outside timing.
const START=preload("res://scripts/meta/game_start_contract.gd")
const FLOW=preload("res://scenes/meta/meta_layer_test.tscn")
const ISOLATION=preload("res://scripts/tests/review2_isolated_user_guard.gd")
const SAMPLES:=30
const CALLS:=20
var passed:=0
var failed:=0

func _init()->void:
	if ISOLATION.require_isolated_user_data():call_deferred("_run")
func check(value:bool,label:String)->void:
	if value:passed+=1
	else:failed+=1
	print("PASS " if value else "FAIL ",label)
func _read(adapter:Node,optimized:bool)->Dictionary:
	return adapter.call("get_space_encounter_snapshot") if optimized else Dictionary(adapter.call("get_snapshot").get("space_encounter",{}))
func _witness(adapter:Node)->Dictionary:
	var sim:Node=adapter.get("_simulation")
	var base:Node=adapter.get("_base_personnel")
	return {"tick":sim.get("tick_counter"),"rng_state":str(sim.get("_combat_rng").state),
		"encounter":adapter.get("_space_encounter").get_snapshot(),
		"travel":adapter.get("_travel").get_snapshot(),
		"base":base.export_state(),"campaign":adapter.get("_campaign").get_campaign_snapshot(),
		"supply":adapter.get("_supply").get_supply_snapshot()}
func _measure(adapter:Node,phase:String)->void:
	var owner:RefCounted=adapter.get("_space_encounter")
	var expected:Dictionary=owner.get_snapshot()
	var before:Dictionary=_witness(adapter)
	var equivalent:=true
	# Thirty warmup reads of each variant, same scene and same logical state.
	for i in range(30):
		equivalent=equivalent and _read(adapter,false)==expected
		equivalent=equivalent and _read(adapter,true)==expected
	var baseline:Array[int]=[]
	var optimized:Array[int]=[]
	for sample in range(SAMPLES):
		# Alternate first-run ordering to reduce temperature/order bias.
		for optimized_variant in [sample%2==1,sample%2==0]:
			var started:int=Time.get_ticks_usec()
			var last:Dictionary={}
			for i in range(CALLS):last=_read(adapter,optimized_variant)
			var elapsed:int=Time.get_ticks_usec()-started
			if optimized_variant:optimized.append(elapsed)
			else:baseline.append(elapsed)
			equivalent=equivalent and last==expected
	check(equivalent,"both actual adapter paths return the identical "+phase+" encounter")
	check(_witness(adapter)==before,"both read paths preserve RNG/tick/owner gameplay state: "+phase)
	for variant in ["baseline","optimized"]:
		print("PERF_SAMPLE ",JSON.stringify({"metric":"encounter_read_"+phase+"_20_calls_cpu","unit":"usec",
			"samples":baseline if variant=="baseline" else optimized,"variant":variant,"calls_per_sample":CALLS,
			"warmup_calls_per_variant":30,"sample_count":SAMPLES,"fixture":"actual_new_campaign",
			"phase":phase,"renderer":"headless","startup_in_timing":false,"tick_advanced":false}))
func _run()->void:
	var source_hashes:Dictionary={}
	for path in ["res://scripts/meta/singleplayer_runtime_adapter.gd","res://scripts/meta/campaign_space_encounter_presenter.gd"]:source_hashes[path]=FileAccess.get_sha256(path)
	START.request_start(self,"campaign","new")
	var flow:Node=FLOW.instantiate()
	root.add_child(flow)
	await process_frame
	# Stop regular updates for both variants together. This does not replace any
	# actual runtime owner, snapshot method or configuration with a fake.
	flow.process_mode=Node.PROCESS_MODE_DISABLED
	var adapter:Node=flow.get("_singleplayer_runtime")
	var valid:bool=is_instance_valid(adapter) and adapter.has_method("get_space_encounter_snapshot") and is_instance_valid(adapter.get("_simulation")) and is_instance_valid(adapter.get("_base_personnel"))
	check(valid,"actual campaign created configured runtime, Root and Base owners")
	if valid:
		var actual:Dictionary=adapter.call("get_snapshot")
		check(actual.get("mode")=="campaign" and actual.get("base_personnel",{}).get("units",[]).size()==2 and actual.get("crafts",[]).size()>0,"benchmark uses actual starting roster and craft definitions")
		check(adapter.get("_space_encounter").get_snapshot().is_empty(),"idle case is the actual hidden empty encounter")
		_measure(adapter,"hidden_idle")
		var craft:String=String(flow.get_meta("singleplayer_bootstrap_craft_id"))
		var start:Dictionary=adapter.get("_space_encounter").start_encounter(craft)
		check(start.get("ok",false),"same real encounter owner prepares the visible combat-state read fixture")
		_measure(adapter,"visible_combat")
	var unchanged:=true
	for path in source_hashes:unchanged=unchanged and FileAccess.get_sha256(path)==source_hashes[path]
	check(unchanged,"owning product source bytes remain unchanged throughout measurements")
	flow.queue_free()
	await process_frame
	await process_frame
	print("PERFORMANCE_REVIEW passed=%d failed=%d"%[passed,failed])
	quit(0 if failed==0 else 1)
