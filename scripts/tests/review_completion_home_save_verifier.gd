extends "res://scripts/tests/campaign_intro_loop_smoke.gd"
const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")

func _run() -> void:
	if not GUARD.require_isolated_user_data(): return
	_configure_entry()
	_flow = FLOW.instantiate()
	root.add_child(_flow)
	current_scene = _flow
	await process_frame
	_screen = _flow.get_node("HomebaseScreen")
	_runtime = _flow.get("_singleplayer_runtime")
	var automatic: Dictionary = STORE.load_checkpoint()
	print("HOME_AUTOMATIC_BEFORE_FORCE ", {"ok":automatic.get("ok",false),"reason":automatic.get("reason","")}, " flow_result=",_flow.get_meta("campaign_checkpoint_result",{}).get("reason","ok"))
	_check(automatic.get("ok",false),"normal new campaign persists a valid initial home checkpoint before any test save")
	_probe_home_save("initial")
	if _failed == 0: _test_failed_explicit_retry()
	if _failed == 0:
		await _prepare_initial_base()
		_probe_home_save("aboard")
	if is_instance_valid(_flow): _flow.queue_free()
	await process_frame
	print("REVIEW_COMPLETION_HOME_SAVE passed=%d failed=%d" % [_passed,_failed])
	quit(1 if _failed else 0)

func _test_failed_explicit_retry() -> void:
	var start: RefCounted = _flow.get("_campaign_start")
	var original_bytes := FileAccess.get_file_as_bytes(STORE.DEFAULT_PATH)
	var base: Node = _runtime.get_base_personnel_runtime()
	var id: String = _flow.get("_all_team_units")[0].unit_id
	var enabled: bool = not bool(base._states[id].auto_rest_enabled)
	_check(base.request_operation("base_auto_rest",{"unit_id":id,"enabled":enabled}).get("ok",false),"real Base preference changes after a successful home save")
	# Synchronous fault injection at the actual runtime export boundary. No
	# owner ticks run with this flag changed, and no player file is replaced.
	_runtime.set("_campaign_mode",false)
	var rejected: Dictionary = start.save_home_checkpoint(_flow,_runtime,true)
	_runtime.set("_campaign_mode",true)
	_check(rejected.get("reason")=="runtime_unavailable" and FileAccess.get_file_as_bytes(STORE.DEFAULT_PATH)==original_bytes,"later forced export failure preserves the actual previous checkpoint")
	var retry: Dictionary = start.save_home_checkpoint(_flow,_runtime)
	_check(not retry.get("ok",true) and retry.get("retry_pending",false) and not retry.get("throttled",false),"older successful autosave interval cannot hide a newer explicit failure")
	start._hex_failed_msec = Time.get_ticks_msec()-start.HEX_AUTOSAVE_RETRY_MSEC
	var recovered: Dictionary = start.save_home_checkpoint(_flow,_runtime)
	var saved: Dictionary = STORE.load_checkpoint()
	_check(recovered.get("ok",false) and saved.get("ok",false) and saved.payload.hex_tactical.base_personnel.units[id].auto_rest_enabled==enabled,"ordinary short retry persists the real changed Base owner")

func _probe_home_save(stage: String) -> void:
	var start: RefCounted = _flow.get("_campaign_start")
	var sim: Node = _runtime.get("_simulation")
	var exported: Dictionary = sim.export_hex_checkpoint_state()
	print("HOME_HEX_EXPORT ", stage, " ", {"ok":exported.get("ok",false),"reason":exported.get("reason","")})
	_check(exported.get("ok",false), stage+" actual Root can export home Hex state")
	var captured: Dictionary = start.capture_home_checkpoint(_flow,_runtime)
	print("HOME_CAPTURE ",stage," ",{"ok":captured.get("ok",false),"reason":captured.get("reason","")})
	_check(captured.get("ok",false), stage+" actual home owners capture")
	if captured.get("ok",false):
		var validation: Dictionary = STORE.validate_payload(captured.payload)
		print("HOME_VALIDATION ",stage," ",validation)
		_check(validation.get("ok",false),stage+" actual home payload validates before write")
	var saved: Dictionary = start.save_home_checkpoint(_flow,_runtime,true)
	print("HOME_SAVE ",stage," ",{"ok":saved.get("ok",false),"reason":saved.get("reason",""),"throttled":saved.get("throttled",false)})
	_check(saved.get("ok",false),stage+" actual forced home save succeeds")
	var loaded: Dictionary = STORE.load_checkpoint()
	print("HOME_LOAD ",stage," ",{"ok":loaded.get("ok",false),"reason":loaded.get("reason","")})
	_check(loaded.get("ok",false),stage+" actual persisted home artifact reloads")
	if loaded.get("ok",false):
		var live_before: Dictionary = sim.get_hex_ground_planning_snapshot()
		var preflight: Dictionary = load("res://scripts/meta/singleplayer_runtime_adapter.gd").preflight_campaign_hex_checkpoint(_flow,loaded.payload)
		print("HOME_PREFLIGHT ",stage," ",{"ok":preflight.get("ok",false),"reason":preflight.get("reason","")})
		_check(preflight.get("ok",false),stage+" persisted Home prepares with actual detached adapter and craft clearance")
		_check(sim.get_hex_ground_planning_snapshot()==live_before,stage+" detached Home preflight leaves live Ground unchanged")
