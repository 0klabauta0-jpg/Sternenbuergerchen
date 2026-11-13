extends "res://scripts/tests/campaign_five_actual_sorties_verifier.gd"
## Exact saved third home milestone. This run owns TWO remaining home returns.
const REPRO_GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const SOURCE_PATH = "res://docs/qa/review_completion_20261113/post_benit_source/checkpoint_v1.json"
const SOURCE_SHA = "354a4a9f6841b51a8d906878c2b263e6cbb55136cbd9939dfdac7ca038c5e789"

func _run() -> void:
	if not REPRO_GUARD.require_isolated_user_data(): return
	Engine.time_scale=4.0
	ROSTER.ensure_roster("campaign-profile-isolation")
	_skirmish_bytes=FileAccess.get_file_as_bytes(ROSTER.get_save_path())
	if not _check(FileAccess.get_sha256(SOURCE_PATH)==SOURCE_SHA,"exact genuine third-home source bytes are available"): await _finish(); return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(STORE.DEFAULT_PATH).get_base_dir())
	var file := FileAccess.open(STORE.DEFAULT_PATH,FileAccess.WRITE)
	file.store_buffer(FileAccess.get_file_as_bytes(SOURCE_PATH)); file.close()
	var loaded: Dictionary = STORE.load_checkpoint()
	if not _check(loaded.get("ok",false),"genuine Benit checkpoint loads in this isolated profile"): await _finish(); return
	_check(["satellite_recovery","outpost_recovery","benit_delivery"].all(func(id):return loaded.payload.campaign.jobs[id].status=="completed") and loaded.payload.roster.size()==3,"source has exactly the three actual completed missions and recruited roster")
	START.request_start(self,"campaign","continue")
	_flow=FLOW.instantiate();root.add_child(_flow);current_scene=_flow
	await process_frame
	_screen=_flow.get_node("HomebaseScreen");_runtime=_flow.get("_singleplayer_runtime")
	if not _check(is_instance_valid(_runtime),"normal Continue publishes actual campaign owners"): await _finish(); return
	_craft_id=String(loaded.payload.craft.definition.craft_id)
	_pilot_id=String(Dictionary(_flow.get("_assigned_aircraft_pilot_by_craft")).get(_craft_id,""))
	var teams: PackedStringArray = _screen.call("_get_homebase_direct_payload_fireteam_ids_for_craft_raw",_craft_id)
	if not _check(not teams.is_empty() and not _pilot_id.is_empty(),"Continue reconstructs exact pilot and loaded ground squad"):await _finish();return
	_team_id=teams[0]
	_crew_ids.assign(_screen.call("_get_member_unit_ids_for_fireteam",_team_id))
	_check(_crew_ids.has("campaign_outpost_recruit") and _runtime.get_base_personnel_runtime()._checkpoint_craft_member("campaign_outpost_recruit",_craft_id),"actual Continue preserves recruited aboard membership before departure")
	await _remaining_missions()
	await _finish()

func _expected_physical_return_count() -> int:
	return 2

func _finish() -> void:
	_check(FileAccess.get_sha256(SOURCE_PATH)==SOURCE_SHA,"genuine source checkpoint remains byte-for-byte unchanged")
	_check(FileAccess.get_file_as_bytes(ROSTER.get_save_path())==_skirmish_bytes,"remaining campaign sorties preserve isolated Skirmish profile")
	if _failed==0: _check(_insertion_guard_checked,"actual remaining sortie exercised inbound deployment guard")
	if is_instance_valid(_flow):_flow.queue_free()
	await process_frame
	print("CAMPAIGN_POST_BENIT_CONTINUE returns=%d passed=%d failed=%d" % [_return_number,_passed,_failed])
	quit(1 if _failed else 0)
