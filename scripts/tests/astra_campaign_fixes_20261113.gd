extends "res://scripts/tests/campaign_legacy_satellite_boarding_verifier.gd"
## Real deployed save -> ordinary Continue -> casualty -> actual debrief rollback.
## Corrupt-file and interrupted archival fixtures use private user:// only.
const ACTIVE = preload("res://scripts/meta/campaign_active_checkpoint_store.gd")
const CONFIG = preload("res://scripts/meta/campaign_start_configuration.gd")

func _run() -> void:
	if OS.get_environment("SB_REVIEW2_USER_DIR").is_empty() or not OS.get_user_data_dir().contains("SB-Codex-Review2-"):
		printerr("ASTRA_CAMPAIGN_FIXES_REFUSED: private review2 profile required")
		quit(2); return
	_configure_entry()
	await _new_flow()
	if not await _prepare_initial_base(): await _finish(); return
	_pilot_id = "campaign_pilot"
	_crew_ids = ["campaign_leader"]
	_check(_screen.call("request_operation", "accept_job", {"job_id":"satellite_recovery", "request_id":"astra-fix:accept"}).get("ok", false), "actual campaign job accepted")
	_check(_screen.call("request_operation", "select_destination", {"location_id":"satellite_crash", "job_id":"satellite_recovery", "request_id":"astra-fix:destination"}).get("ok", false), "actual mission selected")
	if not await _launch_and_land("satellite_recovery", "res://maps/satellite_crash_site.json"): await _finish(); return
	# Real Hex unloading queues the final admission/security movement. Wait for
	# their owners to become saveable instead of freezing or cancelling them.
	var capture = load("res://scripts/mission/campaign_active_mission_capture.gd")
	var capture_ready: Dictionary = capture.capture_components(_flow,_runtime)
	var capture_deadline := Time.get_ticks_msec()+30000
	while not capture_ready.get("ok",false) and Time.get_ticks_msec()<capture_deadline and String(capture_ready.get("reason","")) in ["checkpoint_pending_work","checkpoint_clock_unsynced","checkpoint_pending_setup","mission_lifecycle_busy","mission_movement_pending","transport_transition_pending"]:
		await create_timer(0.1).timeout
		capture_ready = capture.capture_components(_flow,_runtime)
	if not _check(capture_ready.get("ok",false),"real deployment and security movement reach a stable save boundary"): print("CAPTURE_FAILURE ",capture_ready); await _finish(); return
	var home_before := FileAccess.get_file_as_bytes(STORE.DEFAULT_PATH)
	var saved: Dictionary = _flow.call("request_campaign_save")
	if not _check(saved.get("ok", false), "deployed mission saves through actual owner"): print(saved); await _finish(); return
	var active_before := FileAccess.get_file_as_bytes(ACTIVE.DEFAULT_PATH)
	var active_sha := FileAccess.get_sha256(ACTIVE.DEFAULT_PATH)
	await _reload("continue")
	if not await _wait(func(): return _flow.has_meta("campaign_active_restore_complete") or _flow.has_meta("campaign_active_restore_error"), 60000, "ordinary Continue reaches actual restore result"): await _finish(); return
	if not _check(bool(_flow.get_meta("campaign_active_restore_complete", false)) and is_instance_valid(_flow.get("_active_mission")) and _space().phase == "surface", "ordinary Continue restores valid active mission"): await _finish(); return
	_check(FileAccess.get_file_as_bytes(ACTIVE.DEFAULT_PATH) == active_before and FileAccess.get_file_as_bytes(STORE.DEFAULT_PATH) == home_before, "ordinary Continue preserves both original files")
	var mission: Node = _flow.get("_active_mission")
	var controller: Node = mission.get_node("TacticalController")
	for id in ["campaign_leader", "campaign_pilot"]:
		controller.call("_get_campaign_sortie_unit", id).call("apply_damage", 10000)
	mission.get_node("CombatLoopDriver").call("_resolve_combat", "defeat", "enemy")
	await process_frame
	if not _check(bool(Dictionary(_flow.get("_last_mission_result")).get("campaign_checkpoint_retry_required", false)), "actual casualty exposes safe-home rollback"): await _finish(); return
	_check(FileAccess.get_file_as_bytes(STORE.DEFAULT_PATH) == home_before, "failed extraction never overwrites safe home")
	var button: Button = _flow.get_node("DebriefScreen/Panel/Margin/VBox/ButtonRow/ReturnToHomebaseButton")
	_check(button.text.contains("Checkpoint") and not button.disabled, "real debrief action describes checkpoint")
	button.pressed.emit()
	await process_frame
	await process_frame
	_flow = current_scene
	if not _check(is_instance_valid(_flow) and _flow.get("_singleplayer_runtime") != null, "debrief creates actual replacement flow"): await _finish(); return
	_screen = _flow.get_node("HomebaseScreen")
	_runtime = _flow.get("_singleplayer_runtime")
	_check(_flow.get("_game_start_request").action == "continue_home", "debrief carries explicit home intent")
	_check(_flow.get("_active_mission") == null and not _flow.get("_campaign_start").active_restore_in_progress and _space().phase == "grounded", "saved active mission cannot override explicit safe-home rollback")
	_check(FileAccess.get_file_as_bytes(_archive_path(active_sha)) == active_before and not FileAccess.file_exists(ACTIVE.DEFAULT_PATH), "rollback archives valid active bytes without deleting them")
	# Seit ad3428128 (Paket 3a, Aufgabe 5b; Vertrag docs/dev/campaign_casualty_retreat_contract.md, Regel 7) wendet das Laden des Basisstands den
	# Totalverlust-Malus an und schreibt den Basisstand sofort neu: Rettungsgebuehr, leichte Verwundung, Moral. Frueher pruefte diese Zeile
	# Byte-Gleichheit ("der Rollback schreibt den Basisstand nicht neu"); das gilt nur noch fuer alles ausser dem Malus.
	var loss_rules: Dictionary = Dictionary(load("res://scripts/core/campaign_casualty_rules.gd").call("load_rules")).get("total_loss", {})
	var payload_before: Dictionary = JSON.parse_string(home_before.get_string_from_utf8())
	var home_after: Dictionary = STORE.load_checkpoint()
	var payload_after: Dictionary = Dictionary(home_after.get("payload", {})).duplicate(true)
	var credits_before := int(Dictionary(payload_before.get("supply", {})).get("credits", 0))
	var fee := mini(maxi(roundi(float(credits_before) * float(loss_rules.get("rescue_fee_fraction", 0.0))), int(loss_rules.get("rescue_fee_minimum", 0))), credits_before)
	_check(home_after.get("ok", false) and fee > 0 and int(Dictionary(payload_after.get("supply", {})).get("credits", -1)) == credits_before - fee, "explicit rollback charges the rescue fee from the rules file exactly once")
	var penalty_ok := true
	for penalized_id in ["campaign_leader", "campaign_pilot"]:
		var unit_before := _roster_unit(payload_before, penalized_id)
		var unit_after := _roster_unit(payload_after, penalized_id)
		var morale_before := float(Dictionary(unit_before.get("progression", {})).get("morale", 0.50))
		var morale_expected := clampf(morale_before + float(loss_rules.get("morale_delta", 0.0)), 0.0, 1.0)
		var morale_after := float(Dictionary(unit_after.get("progression", {})).get("morale", -1.0))
		penalty_ok = penalty_ok and not unit_before.is_empty() and String(unit_after.get("availability_status", "")) == "wounded" and String(Dictionary(unit_after.get("recovery_state", {})).get("severity", "")) == String(loss_rules.get("wound_severity", "")) and absf(morale_after - morale_expected) < 0.0001 and morale_after < morale_before
		# Nur die Felder des Malus zurueckdrehen; danach muss der Rest des Basisstands dem alten gleichen.
		for i in range(Array(payload_after.get("roster", [])).size()):
			if typeof(payload_after.roster[i]) == TYPE_DICTIONARY and String(payload_after.roster[i].get("unit_id", "")) == penalized_id:
				for key in ["availability_status", "recovery_state", "status_text", "progression"]:
					if unit_before.has(key): payload_after.roster[i][key] = unit_before[key]
					else: payload_after.roster[i].erase(key)
	_check(penalty_ok, "explicit rollback wounds both downed crew lightly and lowers their morale by the rules value")
	if payload_after.has("supply") and payload_before.has("supply"):
		payload_after["supply"]["credits"] = payload_before["supply"]["credits"]
		payload_after["supply"]["revision"] = payload_before["supply"].get("revision", 0)
	_check(payload_after == payload_before, "explicit rollback changes nothing in home except the total-loss penalty")
	await _reload("continue")
	_check(_flow.get("_active_mission") == null and _space().phase == "grounded", "subsequent ordinary Continue stays at chosen home")
	# Deliberately malformed old file: a new campaign supersedes it atomically.
	var corrupt := "{ malformed active checkpoint from previous run".to_utf8_buffer()
	_write(ACTIVE.DEFAULT_PATH, corrupt)
	var corrupt_sha := FileAccess.get_sha256(ACTIVE.DEFAULT_PATH)
	var old_home := FileAccess.get_file_as_bytes(STORE.DEFAULT_PATH)
	_check(not STORE.save_checkpoint({"schema_version":1}).get("ok", false), "invalid new home cannot publish")
	_check(FileAccess.get_file_as_bytes(STORE.DEFAULT_PATH) == old_home and FileAccess.get_file_as_bytes(ACTIVE.DEFAULT_PATH) == corrupt, "failed home validation preserves both prior artifacts")
	_check(not ACTIVE.archive_checkpoint("f".repeat(64)).get("ok", false) and FileAccess.get_file_as_bytes(ACTIVE.DEFAULT_PATH) == corrupt, "stale archive request cannot retire changed active file")
	await _reload("new")
	var fresh: Dictionary = _flow.call("request_campaign_save")
	_check(fresh.get("ok", false) and STORE.load_checkpoint().get("ok", false), "actual new campaign writes valid safe home")
	_check(not FileAccess.file_exists(ACTIVE.DEFAULT_PATH) and FileAccess.get_file_as_bytes(_archive_path(corrupt_sha)) == corrupt, "new campaign archives malformed artifact byte for byte")
	var new_run := String(_flow.get("_campaign_start").campaign_run_id)
	await _reload("continue")
	_check(_flow.get("_campaign_start").error_message.is_empty() and _flow.get("_campaign_start").campaign_run_id == new_run and _space().phase == "grounded", "old corruption cannot block continuing new campaign")
	# Same-run corruption remains an explicit error, not a silent home fallback.
	_write(ACTIVE.DEFAULT_PATH, corrupt)
	old_home = FileAccess.get_file_as_bytes(STORE.DEFAULT_PATH)
	# Use a different digest from the already retired one in the new home.
	var changed := "{ different corrupt active checkpoint".to_utf8_buffer()
	_write(ACTIVE.DEFAULT_PATH, changed)
	var changed_sha := FileAccess.get_sha256(ACTIVE.DEFAULT_PATH)
	var rejected = CONFIG.new()
	var dummy := Node.new()
	# The real detached Home preflight requires a live tree for its disposable
	# candidate subtree. Reach that boundary before testing the corrupt Active.
	root.add_child(dummy)
	rejected.configure(dummy, {"mode":"campaign", "action":"continue"})
	if not rejected.error_message.contains("Basisstand"): print("CORRUPT_ACTIVE_GUIDANCE_DIAGNOSTIC ", rejected.error_message)
	_check(not rejected.error_message.is_empty() and rejected.error_message.contains("Basisstand"), "unretired corrupt active produces explicit recovery guidance")
	_check(FileAccess.get_file_as_bytes(ACTIVE.DEFAULT_PATH) == changed and FileAccess.get_file_as_bytes(STORE.DEFAULT_PATH) == old_home, "rejected normal Continue preserves home and corrupt artifact")
	dummy.free()
	await _reload("continue_home")
	_check(_flow.get("_campaign_start").error_message.is_empty() and _space().phase == "grounded" and FileAccess.get_file_as_bytes(_archive_path(changed_sha)) == changed, "explicit recovery restores actual safe home and preserves corrupt artifact")
	# Archive conflict simulates failure after the new atomic home publication.
	var interrupted := "{ archive rename cannot finish".to_utf8_buffer()
	_write(ACTIVE.DEFAULT_PATH, interrupted)
	var interrupted_sha := FileAccess.get_sha256(ACTIVE.DEFAULT_PATH)
	_write(_archive_path(interrupted_sha), "existing unrelated artifact".to_utf8_buffer())
	await _reload("new")
	fresh = _flow.call("request_campaign_save")
	_check(fresh.get("ok", false), "new home remains committed despite archival conflict")
	_check(STORE.load_checkpoint().payload.get("retired_active_checkpoint_sha256") == interrupted_sha and FileAccess.get_file_as_bytes(ACTIVE.DEFAULT_PATH) == interrupted, "committed retirement binds only the exact superseded artifact")
	await _reload("continue")
	_check(_flow.get("_campaign_start").error_message.is_empty() and _space().phase == "grounded", "interrupted archival cannot re-block new campaign Continue")
	_check(FileAccess.get_file_as_bytes(ACTIVE.DEFAULT_PATH) == interrupted, "retired corrupt source remains recoverable after archive failure")
	# A fresh run also preserves a valid previous active checkpoint as an archive.
	_write(ACTIVE.DEFAULT_PATH, active_before)
	await _reload("new")
	fresh = _flow.call("request_campaign_save")
	_check(fresh.get("ok", false) and FileAccess.get_file_as_bytes(_archive_path(active_sha)) == active_before and not FileAccess.file_exists(ACTIVE.DEFAULT_PATH), "new run retires valid old active checkpoint without losing its bytes")
	_check(not START.request_start(self, "skirmish", "continue_home").get("ok", false), "home recovery intent cannot enter Skirmish")
	_check(FileAccess.get_file_as_bytes(ROSTER.get_save_path()) == _skirmish_bytes, "all save recovery paths preserve Skirmish profile")
	await _finish()

func _new_flow() -> void:
	_flow = FLOW.instantiate()
	root.add_child(_flow)
	current_scene = _flow
	await process_frame
	_screen = _flow.get_node("HomebaseScreen")
	_runtime = _flow.get("_singleplayer_runtime")

func _reload(action: String) -> void:
	if is_instance_valid(_flow): _flow.queue_free()
	await process_frame
	_check(START.request_start(self, "campaign", action).get("ok", false), "start intent " + action)
	await _new_flow()

func _archive_path(digest: String) -> String:
	return ACTIVE.DEFAULT_PATH.trim_suffix(".json") + ".retired-" + digest + ".json"

func _roster_unit(payload: Dictionary, unit_id: String) -> Dictionary:
	for raw in Array(payload.get("roster", [])):
		if typeof(raw) == TYPE_DICTIONARY and String(raw.get("unit_id", "")) == unit_id:
			return raw
	return {}

func _write(path: String, bytes: PackedByteArray) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_check(false, "private fixture file writable")
		return
	file.store_buffer(bytes)
	file.close()

func _finish() -> void:
	if is_instance_valid(_flow): _flow.queue_free()
	await process_frame
	print("ASTRA_CAMPAIGN_FIXES passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)
