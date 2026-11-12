extends SceneTree
const PATH = "res://scripts/multiplayer/multiplayer_visible_snapshot_projection.gd"
const V1 = preload("res://scripts/multiplayer/multiplayer_snapshot_contract.gd")
var passed := 0
var failed := 0
func check(ok: bool,label: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("PASS " if ok else "FAIL ",label)
func _init() -> void: call_deferred("run")
func run() -> void:
	check(ResourceLoader.exists(PATH),"pure visible projection helper exists")
	if failed: finish(); return
	var helper = load(PATH).new()
	var dto := {"schema_version":1,"snapshot_type":"state","transfer_mode":"unreliable","tick":7,
		"units":[{"unit_id":"own","team_id":"blue","fireteam_id":"ft_blue","position":Vector2(1,2),"health":100,"target_position":Vector2(9,9),"active_command_type":"move"},{"unit_id":"seen","team_id":"red","fireteam_id":"ft_red","position":Vector2(3,4),"health":80,"target_position":Vector2(30,40),"active_command_type":"ambush","enemy_tactic_profile_id":"secret"},{"unit_id":"hidden","team_id":"red","position":Vector2(99,99)}],
		"vital_updates":[{"unit_id":"own","health":100},{"unit_id":"seen","health":80},{"unit_id":"hidden","health":50}],
		"contacts":[{"fireteam_id":"ft_blue","unit_id":"seen","team_id":"red","last_known_position":Vector2(3,4)},{"fireteam_id":"ft_red","unit_id":"own","team_id":"blue"},{"fireteam_id":"ft_blue","unit_id":"hidden","team_id":"red","last_known_position":Vector2(99,99)}],
		"commander_intents":[{"command_id":"free_area","team_id":"blue","fireteam_id":"ft_blue","target_position":Vector2(50,50)},{"command_id":"track","team_id":"blue","fireteam_id":"ft_blue","target_unit_id":"hidden","target_position":Vector2(99,99)},{"command_id":"enemy_plan","team_id":"red","fireteam_id":"ft_red","target_position":Vector2(8,8)}],
		"fire_events":[{"event_id":"fire1","attacker_unit_id":"own","attacker_position":Vector2(1,2),"target_unit_id":"hidden","target_position":Vector2(99,99)}],
		"character_gameplay":[{"fireteam_id":"ft_blue","cohesion_percent":80},{"fireteam_id":"ft_red","cohesion_percent":90}],
		"dropship":{"team_id":"blue","position":Vector2(4,5),"mission_drop_cards":[{"craft_id":"ours","pilot_unit_id":"own","embarked_unit_ids":["own","hidden"]},{"craft_id":"theirs","pilot_unit_id":"hidden","dropship_position":Vector2(99,99)}]},
		"air_asset_status":[{"asset_id":"our_air","position":Vector2(7,8),"locked_by_unit_id":"hidden","threat_weapon_id":"secret","last_reason":"secret"},{"asset_id":"enemy_air","position":Vector2(99,99)}]}
	dto.mission_result={"result":"victory","team_states":[{"unit_id":"own","display_name":"Own","vital_state":"fit","health_points":100},{"unit_id":"hidden","display_name":"Secret","vital_state":"fit","health_points":50}]}
	dto.enemy_security=[{"security_group_id":"own_security","team_id":"blue","fireteam_id":"ft_blue","unit_ids":["own"],"watched_unit_ids":["seen","hidden"],"anchor_position":Vector2(1,2),"focus_position":Vector2(99,99),"member_assignments":[{"unit_id":"own","weapon_id":"rifle"},{"unit_id":"hidden","weapon_id":"secret"}]},{"security_group_id":"red_security","team_id":"red","unit_ids":["seen"]}]
	dto.enemy_team_tactics=[{"security_group_id":"own_tactics","team_id":"blue","unit_ids":["own"],"target_positions_by_unit_id":{"own":Vector2(9,9),"hidden":Vector2(99,99)},"role_by_unit_id":{"own":"point","hidden":"secret"}},{"security_group_id":"red_tactics","team_id":"red","unit_ids":["seen"],"profile_id":"secret"}]
	for key in ["fireteam_tactical","fireteam_plan_status","tactical_rules","breakout_states","communication_events","feedback_bubbles"]:
		dto[key]=[{"unit_id":"own","fireteam_id":"ft_blue","team_id":"blue","plan_id":"p1","event_id":"e1","bubble_id":"b1","breakout_id":"break1","target_position":Vector2(10,10)},{"unit_id":"seen","fireteam_id":"ft_red","team_id":"red","plan_id":"p2","event_id":"e2","bubble_id":"b2","breakout_id":"break2","target_position":Vector2(30,40)}]
	var context := {"reference_provenance":"host_raw","own_unit_ids":["own"],"visible_unit_ids":["seen"],"fireteam_team_ids":{"ft_blue":"blue","ft_red":"red"},"asset_team_ids":{"our_air":"blue","enemy_air":"red"},"craft_team_ids":{"ours":"blue","theirs":"red"}}
	var before := dto.duplicate(true)
	var result: Dictionary=helper.project_state(dto,"blue",context)
	check(result.get("ok",false),"valid two-team Host facts accepted")
	if not result.get("ok",false): print(result); finish(); return
	var out: Dictionary=result.snapshot
	check(out.units.size()==2 and out.units[0].unit_id=="own" and out.units[0].target_position==Vector2(9,9) and out.units[1].unit_id=="seen" and not out.units[1].has("target_position") and not out.units[1].has("active_command_type") and not out.units[1].has("enemy_tactic_profile_id"),"own intent retained; visible enemy display only; hidden unit absent")
	check(out.contacts.size()==1 and out.contacts[0].unit_id=="seen" and out.contacts[0].team_id=="red","contacts route by observing fireteam, not target team")
	check(out.commander_intents.size()==2 and out.commander_intents[0].target_position==Vector2(50,50) and not out.commander_intents[1].has("target_position") and out.character_gameplay.size()==1,"own free target area and skills retained; hidden target position and enemy plan omitted")
	check(out.fire_events.size()==1 and not out.fire_events[0].has("target_unit_id") and not out.fire_events[0].has("target_position") and out.fire_events[0].attacker_position==Vector2(1,2),"fire event removes hidden target and coupled position without losing own muzzle activity")
	check(out.dropship.mission_drop_cards.size()==1 and Array(out.dropship.mission_drop_cards[0].embarked_unit_ids)==["own"] and out.dropship.position==Vector2(4,5) and out.air_asset_status.size()==1 and not out.air_asset_status[0].has("locked_by_unit_id") and not out.air_asset_status[0].has("threat_weapon_id"),"owned transport/air UI survives with hidden crossreferences removed")
	var reliable: Dictionary=helper.project_reliable_vitals(dto.vital_updates,dto,"blue",context)
	check(reliable.get("ok",false) and reliable.vital_updates.size()==2 and out.vital_updates==reliable.vital_updates,"reliable and unreliable vitals use the identical visibility filter")
	check(result.get("projection_scope")=="full_recipient_state" and not V1.new().validate_for_apply(result,-1).get("accepted",false),"full projection envelope cannot masquerade as legacy partial snapshot")
	check(out.mission_result.team_states.size()==1 and out.mission_result.team_states[0].unit_id=="own","actual Driver unit-shaped team_states retain own debrief without enemy IDs")
	check(out.enemy_security.size()==1 and Array(out.enemy_security[0].watched_unit_ids)==["seen"] and not out.enemy_security[0].has("focus_position") and out.enemy_security[0].member_assignments.size()==1 and out.enemy_team_tactics.size()==1 and out.enemy_team_tactics[0].target_positions_by_unit_id.size()==1 and out.enemy_team_tactics[0].role_by_unit_id.size()==1,"security assignments and tactics maps preserve own data while removing hidden keys and coupled focus")
	var own_lists := true
	for key in ["fireteam_tactical","fireteam_plan_status","tactical_rules","breakout_states","communication_events","feedback_bubbles"]: own_lists=own_lists and out[key].size()==1
	check(own_lists,"every existing plan/rule/communication/breakout/bubble list preserves own row and omits enemy internals")
	out.units[0].position=Vector2.ZERO
	check(dto==before and context.own_unit_ids==["own"],"projection is detached and inputs unchanged")
	var bad := dto.duplicate(true); bad.schema_version=2
	check(not helper.project_state(bad,"blue",context).get("ok",false) and not helper.project_state(dto,"spectator",context).get("ok",false) and not helper.project_state(dto,"blue",{}).get("ok",false),"unknown version/team/missing proof fails closed")
	var lossy := context.duplicate(true); lossy.erase("reference_provenance")
	check(not helper.project_state(dto,"blue",lossy).get("ok",false),"missing original Host reference provenance rejects lossy DTO input")
	var mixed := dto.duplicate(true)
	mixed.enemy_security[0].member_assignments.append({"unit_id":"seen","weapon_id":"private_assignment"})
	mixed.enemy_team_tactics[0].role_by_unit_id.seen="private_role"
	var mixed_result: Dictionary=helper.project_state(mixed,"blue",context)
	check(mixed_result.ok and mixed_result.snapshot.enemy_security[0].member_assignments.size()==1 and not mixed_result.snapshot.enemy_team_tactics[0].role_by_unit_id.has("seen"),"visible enemy cannot inherit private per-unit plans through an owned group row")
	var uncrewed := dto.duplicate(true)
	uncrewed.dropship.mission_drop_cards=[{"craft_id":"ours","embarked_unit_ids":[]},{"craft_id":"theirs","pilot_unit_id":"own"},{"craft_id":"unknown","dropship_position":Vector2(99,99)}]
	uncrewed.dropship.erase("team_id")
	uncrewed.dropship.mission_drop_cards[1].team_id="blue"
	var asset_result: Dictionary=helper.project_state(uncrewed,"blue",context)
	check(asset_result.ok and asset_result.snapshot.dropship.mission_drop_cards.size()==1 and asset_result.snapshot.dropship.mission_drop_cards[0].craft_id=="ours" and not asset_result.snapshot.dropship.has("position"),"explicit own uncrewed craft survives; conflicting or unknown provenance cannot infer top ship geometry")
	var ft_only := dto.duplicate(true)
	ft_only.fireteam_tactical=[{"unit_id":"","fireteam_id":"ft_blue","plan_quality":0.75}]
	ft_only.enemy_security=[{"security_group_id":"own_members","unit_ids":PackedStringArray(["own"]),"watched_unit_ids":PackedStringArray(["seen"])}]
	var ft_result: Dictionary=helper.project_state(ft_only,"blue",context)
	check(ft_result.ok and ft_result.snapshot.fireteam_tactical.size()==1 and ft_result.snapshot.fireteam_tactical[0].plan_quality==0.75 and ft_result.snapshot.enemy_security.size()==1,"own fireteam-only readout and packed own membership survive optional missing identities")
	var effects := dto.duplicate(true)
	effects.air_asset_status[0].vfx_events=[{"event_id":"coupled","asset_id":"our_air","target_unit_id":"hidden","position":Vector2(99,99)},{"event_id":"free_effect","asset_id":"our_air","position":Vector2(7,8)}]
	effects.air_asset_status[0].sfx_events=[{"event_id":"coupled_sound","asset_id":"our_air","attacker_unit_id":"hidden","position":Vector2(99,99)},{"event_id":"free_sound","asset_id":"our_air","position":Vector2(7,8)}]
	var effects_result: Dictionary=helper.project_state(effects,"blue",context)
	check(effects_result.ok and effects_result.snapshot.air_asset_status[0].vfx_events.size()==1 and effects_result.snapshot.air_asset_status[0].vfx_events[0].position==Vector2(7,8) and effects_result.snapshot.air_asset_status[0].sfx_events.size()==1 and effects_result.snapshot.air_asset_status[0].sfx_events[0].position==Vector2(7,8),"actual V1 status-event position cannot survive hidden target/attacker while unlinked own effects remain")
	var display := dto.duplicate(true)
	display.units[1].runtime_state="moving"; display.units[1].fire_mode="return"
	display.units[1].tactical_stance="defensive"; display.units[1].tactical_stance_revision=3
	var display_result: Dictionary=helper.project_state(display,"blue",context)
	var enemy: Dictionary=display_result.snapshot.units[1] if display_result.ok else {}
	check(display_result.ok and enemy.get("runtime_state")=="moving" and enemy.get("fire_mode")=="return" and enemy.get("tactical_stance")=="defensive" and enemy.get("tactical_stance_revision")==3 and not enemy.has("active_command_type") and not enemy.has("source_command_type") and not enemy.has("target_position") and not enemy.has("enemy_tactic_profile_id"),"visible enemy preserves actual TestUnit scalar display reader fields without private intent or profile")
	finish()
func finish() -> void:
	print("MULTIPLAYER_VISIBLE_PROJECTION passed=%d failed=%d wired=false"%[passed,failed])
	quit(1 if failed else 0)
