extends SceneTree
const START = preload("res://scripts/meta/game_start_contract.gd")
const STORE = preload("res://scripts/meta/campaign_checkpoint_store.gd")
var failed := 0
func check(value: bool, label: String) -> void:
	print(("PASS: " if value else "FAIL: ") + label)
	if not value: failed += 1
func _init() -> void: call_deferred("run")
func run() -> void:
	START.request_start(self, "campaign", "new")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate(); root.add_child(flow)
	await process_frame
	var adapter: Node = flow.get("_singleplayer_runtime")
	var saved: Dictionary = flow.get("_campaign_start").save_home_checkpoint(flow, adapter)
	check(saved.get("ok", false), "fresh checkpoint saved")
	var loaded: Dictionary = STORE.load_checkpoint()
	if not loaded.get("ok", false): check(false, "fresh checkpoint readable"); flow.queue_free(); await process_frame; quit(1); return
	var payload: Dictionary = loaded.payload
	var signature := JSON.stringify({"operation":"campaign_build_bed","payload":{}}, "", true)
	payload.supply.requests["old-bed-1"] = {"signature":signature,"result":{"ok":true,"operation":"campaign_build_bed","request_id":"old-bed-1","bed_count":3,"cost":100}}
	var sleeper: Dictionary = payload.base_personnel.units.campaign_leader
	sleeper.status = "sleeping"; sleeper.bed_id = "field_bed_01"
	var modified: Dictionary = STORE.save_checkpoint(payload)
	check(modified.get("ok", false), "legacy bed checkpoint accepted")
	flow.queue_free(); await process_frame
	START.request_start(self, "campaign", "continue")
	flow = load("res://scenes/meta/meta_layer_test.tscn").instantiate(); root.add_child(flow)
	await process_frame
	adapter = flow.get("_singleplayer_runtime")
	var base: Node = adapter.get_base_personnel_runtime()
	check(adapter._supply.get_campaign_housing_count() == 1 and adapter._supply.get_campaign_bed_count() == 4, "old purchase gains housing without another charge")
	check(base.get_snapshot().bed_occupants.get("field_bed_01") == "campaign_leader", "old sleeper is moved to equivalent indoor bed")
	flow.queue_free(); await process_frame
	if failed == 0: print("CAMPAIGN_HOUSING_LEGACY_PASS")
	quit(0 if failed == 0 else 1)
