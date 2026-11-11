extends SceneTree
const OWNER=preload("res://scripts/core/singleplayer_campaign_state.gd")
const COMMANDS=preload("res://scripts/mission/singleplayer_campaign_command_contract.gd")
class NoSaveOwner extends "res://scripts/core/singleplayer_campaign_state.gd":
	func export_state() -> Dictionary: return {"forbidden_runtime_clone":true}
	func restore_state(_state: Dictionary) -> Dictionary: return {"ok":false,"reason":"save_is_not_runtime_clone"}
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1
	print("PASS " if ok else "FAIL ",label)
func owner(authority: Object,job: bool=false):
	var c=NoSaveOwner.new(); assert(c.configure({}, {}, false).ok)
	if authority!=null: assert(c.configure_departure_preparation_authority(authority).ok)
	if job:
		assert(c.apply_command(COMMANDS.build_accept_job_command("satellite_recovery","accept")).ok)
		assert(c.apply_command(COMMANDS.build_select_destination_command("satellite_crash","satellite_recovery","select")).ok)
	return c
func commands(job: bool=false,pad: String="homebase_pad_03",suffix: String="new") -> Array:
	var payload: Dictionary={"craft_id":"ship","origin_location_id":"homebase","destination_location_id":"satellite_crash" if job else "polisa","landing_pad_id":pad,"job_id":"satellite_recovery" if job else ""}
	return [COMMANDS.build_command("bind_departure",payload,"bind:"+suffix),COMMANDS.build_command("activate_job",{"craft_id":"ship","job_id":"satellite_recovery"},"activate:"+suffix) if job else {}]
func context(authority: Object,id: String="transaction") -> Dictionary:
	return {"authority":authority,"transaction_id":id,"built_home_pad_ids":["homebase_pad_03","homebase_pad_04","homebase_pad_05","homebase_pad_06"]}
func fingerprint(c) -> String:
	return JSON.stringify([c.get_campaign_snapshot(),c._requests,c._prepared_departure_receipts],"",true)
func prepare(c, pair: Array, ctx: Dictionary) -> Dictionary: return c.prepare_departure(pair[0],pair[1],ctx)
func _initialize() -> void:
	var authority:=RefCounted.new(); var foreign:=RefCounted.new()
	var c=owner(null); var pair:=commands(); var trusted:=context(authority)
	check(not prepare(c,pair,{"departure_authorized":true}).ok and c.configure_departure_preparation_authority(authority).ok and not c.configure_departure_preparation_authority(foreign).ok and not prepare(c,pair,context(foreign)).ok,"explicit object authority required; bool and takeover do not authorize")
	var before:=fingerprint(c); var staged:=prepare(c,pair,trusted)
	check(staged.ok and fingerprint(c)==before and not staged.patch.has("job_patch") and staged.patch.receipts.size()==1,"no-job private prepare is read-only and has no phantom activation")
	var legacy=owner(null); var legacy_result: Dictionary=legacy.apply_command(pair[0],{"departure_authorized":true,"built_home_pad_ids":trusted.built_home_pad_ids})
	var committed: Dictionary=c.commit_prepared_departure(staged,trusted)
	staged.patch.binding.destination_location_id="forged_after_commit"
	check(committed.ok and legacy_result.ok and c._requests==legacy._requests and c._departures_by_craft_id==legacy._departures_by_craft_id and c._revision==legacy._revision,"silent patch preserves legacy subreceipt shape and detaches caller data")
	var replay_before:=fingerprint(c); var replay: Dictionary=c.commit_prepared_departure(prepare(c,pair,trusted),trusted)
	var changed_pair:=commands(false,"homebase_pad_04")
	check(replay.get("replayed",false) and fingerprint(c)==replay_before and not prepare(c,changed_pair,trusted).ok,"own complete group replays once and changed command under same transaction rejects")
	var j=owner(authority,true); var jp:=commands(true); var jc:=context(authority,"job-group"); var job_before:=fingerprint(j); var job_candidate:=prepare(j,jp,jc)
	var job_result: Dictionary=j.commit_prepared_departure(job_candidate,jc)
	check(job_candidate.ok and job_result.ok and job_before!=fingerprint(j) and j._jobs.satellite_recovery.status=="active" and j._jobs.satellite_recovery.craft_id=="ship" and j._requests.has("bind:new") and j._requests.has("activate:new"),"actual accepted job binding and activation publish together")
	var invalid=owner(authority,true); var mismatch:=commands(true); mismatch[1].payload.craft_id="other"; before=fingerprint(invalid)
	var missing: Dictionary=invalid.prepare_departure(commands(true)[0],{},context(authority,"missing"))
	check(not prepare(invalid,mismatch,context(authority,"mismatch")).ok and not missing.ok and fingerprint(invalid)==before,"mismatched or absent activation rejects without half binding")
	var stale=owner(authority,true); var sp:=commands(true); var sc:=context(authority,"stale"); var candidate:=prepare(stale,sp,sc)
	var old_selection: String=stale._selected_location_id; stale._selected_location_id="polisa"; var selection_rejected: bool=not stale.validate_prepared_departure(candidate,sc).ok; stale._selected_location_id=old_selection
	stale._jobs.satellite_recovery.status="offered"; var job_rejected: bool=not stale.validate_prepared_departure(candidate,sc).ok; stale._jobs.satellite_recovery.status="accepted"
	stale._departures_by_craft_id.ship={"unrelated_fixture_binding":true}; var binding_rejected: bool=not stale.validate_prepared_departure(candidate,sc).ok; stale._departures_by_craft_id.erase("ship")
	var changed_context:=context(authority,"stale"); changed_context.built_home_pad_ids=["homebase_pad_03"]
	check(selection_rejected and job_rejected and binding_rejected and not stale.validate_prepared_departure(candidate,changed_context).ok,"relevant selection/job/binding/pad inputs revalidate beyond revision")
	var forged: Dictionary=candidate.duplicate(true); forged.patch.binding.destination_location_id="polisa"
	var other=owner(authority,true)
	check(not stale.commit_prepared_departure(forged,sc).ok and not other.commit_prepared_departure(candidate,sc).ok,"tampered patch and different owner cannot consume candidate")
	var active=owner(authority,true); var old_pair:=commands(true,"homebase_pad_01","old")
	assert(active.apply_command(old_pair[0],{"departure_authorized":true}).ok); assert(active.apply_command(old_pair[1],{"departure_authorized":true}).ok)
	var fresh_pair:=commands(true,"homebase_pad_01","fresh"); var active_ctx:=context(authority,"already-active"); var active_candidate:=prepare(active,fresh_pair,active_ctx); var rev: int=active._revision
	var noop: Dictionary=active.apply_command(fresh_pair[1],{"departure_authorized":true})
	check(active_candidate.ok and noop.get("already_active",false) and active._revision==rev and not active.commit_prepared_departure(active_candidate,active_ctx).ok,"real already_active receipt key write invalidates candidate without revision change")
	var partial=owner(authority,true); var pp:=commands(true,"homebase_pad_01","legacy")
	assert(partial.apply_command(pp[0],{"departure_authorized":true}).ok); before=fingerprint(partial)
	var rejected:=prepare(partial,pp,context(authority,"partial"))
	check(not rejected.ok and rejected.reason=="ambiguous_partial_departure" and fingerprint(partial)==before,"legacy partial subreceipt is rejected rather than guessed complete")
	var pads_ok:=true
	for pad_id in ["homebase_pad_03","homebase_pad_04","homebase_pad_05","homebase_pad_06"]:
		var pad_owner=owner(authority); var pad_candidate:=prepare(pad_owner,commands(false,pad_id,pad_id),context(authority,pad_id))
		pads_ok=pads_ok and pad_candidate.get("ok",false) and pad_candidate.patch.binding.landing_pad_id==pad_id
	check(pads_ok,"legitimate built runtime pads03-06 prepare without save/restore cloning")
	var resetting=owner(authority,true); var reset_ctx:=context(authority,"reset"); var reset_candidate:=prepare(resetting,commands(true),reset_ctx)
	seed(7654321); var expected:=randf(); seed(7654321); resetting.configure({}, {}, false); var observed:=randf()
	check(expected==observed and not resetting.commit_prepared_departure(reset_candidate,reset_ctx).ok,"lifecycle reset invalidates candidate/authority and new seals consume no combat RNG")
	print("PREPARED_CAMPAIGN_RESULT checks=",checks," failures=",failures," runtime_wired=false")
	quit(1 if failures else 0)
