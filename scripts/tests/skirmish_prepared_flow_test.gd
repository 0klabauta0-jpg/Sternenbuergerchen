extends SceneTree
const START = preload("res://scripts/meta/game_start_contract.gd")
const ROSTER = preload("res://scripts/meta/player_roster_store.gd")
var failures := 0
var checks := 0
func _init() -> void: call_deferred("_run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _run() -> void:
	var team_path: String = ROSTER.get_save_path()
	var team_existed := FileAccess.file_exists(team_path)
	var before := FileAccess.get_file_as_bytes(team_path) if team_existed else PackedByteArray()
	for id in ["early","mid","late"]:
		START.request_start(self,"skirmish","new",id)
		var flow = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
		root.add_child(flow)
		await process_frame
		var expected: int = {"early":8,"mid":20,"late":30}[id]
		var roster: Array = flow.get("_all_team_units")
		var crafts: Array = flow.get("_homebase_aircraft_definitions")
		check(roster.size() == expected,"Flow owns authored roster: " + id)
		check(crafts.size() == {"early":3,"mid":5,"late":6}[id],"Flow owns authored fleet: " + id)
		check(not flow.call("is_campaign_start"),"Preset is open Skirmish, not campaign")
		check(String(flow.get_meta("player_roster_source","")) == "skirmish_preset","No local_player roster bootstrap")
		flow.call("_show_homebase")
		check(Array(flow.get("_all_team_units")).size() == expected,"Opening base preserves authored roster")
		var screen: Node = flow.get_node("HomebaseScreen")
		for unit: Dictionary in roster:
			var loadout: Dictionary = screen.call("_get_member_loadout",String(unit.unit_id))
			if loadout.get("weapon_1") != "rifle" or loadout.get("armor") not in ["medium","heavy"]:
				print("LOADOUT_MISMATCH ",unit.unit_id," ",loadout)
			check(loadout.get("weapon_1") == "rifle" and loadout.get("armor") in ["medium","heavy"],"Actual equipped rifle/armor on " + String(unit.unit_id))
		var snapshot: Dictionary = flow.call("get_singleplayer_snapshot")
		check(Dictionary(snapshot.get("onboarding",{})).is_empty(),"No campaign progression lock")
		check(snapshot.base_personnel.units.size() == expected,"Real base actors for every person")
		check(snapshot.base_personnel.layout.beds.size() >= expected,"Enough physical bed targets")
		for craft: Dictionary in snapshot.crafts:
			check(not String(craft.get("landing_pad_id","")).is_empty(),"Actual pad assigned for every craft")
		flow.queue_free()
		await process_frame
	check(FileAccess.file_exists(team_path) == team_existed,"Preset loading does not create or remove menu team")
	if team_existed: check(FileAccess.get_file_as_bytes(team_path) == before,"Preset loading preserves menu team bytes")
	print("Prepared Skirmish flow: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
