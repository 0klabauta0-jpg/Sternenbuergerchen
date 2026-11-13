extends SceneTree
const PRESENTER=preload("res://scripts/meta/campaign_space_encounter_presenter.gd")
const ADAPTER=preload("res://scripts/meta/singleplayer_runtime_adapter.gd")
const ENCOUNTER=preload("res://scripts/core/campaign_space_encounter.gd")
const ISOLATION=preload("res://scripts/tests/review2_isolated_user_guard.gd")
var passed:=0
var failed:=0

class RuntimeSpy extends Node:
	var full_reads:=0
	var encounter_reads:=0
	var encounter=ENCOUNTER.new()
	var feedback:Dictionary={}
	var commands:Array=[]
	func get_snapshot()->Dictionary:
		full_reads+=1
		return {"space_encounter":encounter.get_snapshot()}
	func get_space_encounter_snapshot()->Dictionary:
		encounter_reads+=1
		return encounter.get_snapshot()
	func get_campaign_entry_feedback()->Dictionary:return feedback.duplicate(true)
	func request_operation(operation:String,payload:Dictionary)->Dictionary:
		commands.append({"operation":operation,"payload":payload.duplicate(true)})
		return {"ok":true}

func _init()->void:
	if ISOLATION.require_isolated_user_data():call_deferred("_run")
func check(value:bool,label:String)->void:
	if value:passed+=1
	else:failed+=1
	print("PASS " if value else "FAIL ",label)
func _run()->void:
	var runtime:=RuntimeSpy.new()
	root.add_child(runtime)
	var panel=PRESENTER.new()
	root.add_child(panel)
	panel.set_process(false)
	# Exercise the actual polling/refresh/button methods without configuring
	# ship GLBs/SubViewports; those are unchanged and outside this CPUread task.
	var box:=VBoxContainer.new()
	panel.add_child(box)
	panel._status=Label.new()
	box.add_child(panel._status)
	panel._attack=panel._button(box,"attack","campaign_space_engage")
	panel._rescue=panel._button(box,"rescue","campaign_space_rescue")
	panel._retreat=panel._button(box,"retreat","campaign_space_retreat")
	panel._runtime=runtime
	for i in range(10):panel._process(0.15)
	check(not panel.visible and runtime.full_reads==0 and runtime.encounter_reads==10,"ten hidden idle polls use only the narrow encounter read")
	runtime.encounter.start_encounter("craft_one",true)
	panel.refresh()
	check(panel.visible and panel._attack.disabled and panel._rescue.disabled and not panel._retreat.disabled and panel._status.text.contains("vorbereitet"),"entering retains preparation status and retreat-only actions")
	runtime.feedback={"ok":false}
	panel.refresh()
	check(panel._status.text.contains("noch nicht bereit"),"entering preserves owning preparation failure feedback")
	runtime.encounter._state.phase="combat"
	panel.refresh()
	check(not panel._attack.disabled and panel._rescue.disabled and not panel._retreat.disabled and panel._status.text.contains("FEINDLICH"),"combat preserves hull labels and attack availability")
	runtime.encounter._state.engaging=true
	panel.refresh()
	check(panel._attack.disabled and panel._status.text.contains("Feuergefecht"),"active combat disables repeated engage")
	runtime.encounter._state.phase="rescue_ready"
	panel.refresh()
	check(panel._attack.disabled and not panel._rescue.disabled and panel._status.text.contains("Pilot kontaktieren"),"rescue ready exposes original rescue action")
	panel._rescue.pressed.emit()
	check(runtime.commands.size()==1 and runtime.commands[0].operation=="campaign_space_rescue","existing button signal delegates to the same runtime command owner")
	for phase in ["victory","defeat","aborted"]:
		runtime.encounter._state.phase=phase
		panel.refresh()
		check(not panel.visible,"terminal phase hides panel: "+phase)
	check(runtime.full_reads==0 and runtime.encounter_reads>10,"visible and terminal refreshes never request a full meta snapshot")
	var replacement:=RuntimeSpy.new()
	root.add_child(replacement)
	replacement.encounter.start_encounter("craft_two")
	replacement.encounter._state.player_hull=111.0
	var old_reads:int=runtime.encounter_reads
	panel._runtime=replacement
	panel.refresh()
	check(panel.visible and panel._status.text.contains("111") and replacement.encounter_reads==1 and runtime.encounter_reads==old_reads,"runtime replacement immediately reads the new encounter owner")
	panel._runtime=null
	panel.refresh()
	check(not panel.visible,"null runtime hides stale encounter projection")
	var actual=ADAPTER.new()
	var has_narrow:bool=actual.has_method("get_space_encounter_snapshot")
	check(has_narrow,"actual runtime adapter exposes the narrow readonly API")
	if has_narrow:
		check(actual.call("get_space_encounter_snapshot").is_empty(),"unconfigured adapter narrow read is empty")
		actual._space_encounter=ENCOUNTER.new()
		actual._space_encounter.start_encounter("actual_owner")
		var snapshot:Dictionary=actual.call("get_space_encounter_snapshot")
		check(snapshot==actual._space_encounter.get_snapshot(),"actual adapter delegates exact owner state")
		snapshot.player_hull=-1.0
		check(actual.call("get_space_encounter_snapshot").player_hull==240.0,"narrow read cannot mutate the encounter owner")
		panel._runtime=replacement
		replacement.free()
		panel.refresh()
		check(not panel.visible,"freed runtime is never called during teardown")
	else:replacement.free() # Missing API already fails above; no invalid-call noise in RED.
	actual.free()
	panel.free()
	runtime.free()
	await process_frame
	print("PERFORMANCE_ENCOUNTER_READ passed=%d failed=%d"%[passed,failed])
	if failed==0:print("PERFORMANCE_ENCOUNTER_READ_PASS")
	quit(0 if failed==0 else 1)
