extends SceneTree
## Count observer work and preserve fresh evidence; no scene/UI/profile fixture.
class CampaignProbe:
	extends RefCounted
	var reads := 0
	var data := {"jobs": {"satellite_recovery":{"status":"accepted"},
		"outpost_recovery":{"status":"completed"},"benit_delivery":{"status":"active"},
		"outpost_chip_recovery":{"status":"completed"},"buccaneer_rescue":{"status":"offered"}},
		"departures_by_craft_id":{},"progress":{"recruited_outpost":true,"crate_loaded":true,
		"recruited_pilot":false,"second_pad_built":false}}
	func get_campaign_snapshot() -> Dictionary:
		reads += 1
		return data.duplicate(true)
class ScreenProbe:
	extends Control
	var reads := 0
	var pilot := "pilot"
	var payload_ready := true
	func get_operations_snapshot(_include_runtime: bool = true) -> Dictionary:
		reads += 1
		return {"selected_craft":{"id":"craft"}}
	func _has_homebase_direct_launch_payload_for_craft(_id: String) -> bool:
		return payload_ready
	func _get_assigned_pilot_id(_id: String) -> String:
		return pilot
class FlowProbe:
	extends Node
	var _active_mission: Node
	var _pending_mission_craft_transfers: Array = []
	var _aircraft_location_by_craft := {"craft":"homebase"}
class PresenceProbe:
	extends Node
	var pilot_aboard := true
	var payload_aboard := true
	func is_pilot_aboard(_id: String) -> bool:
		return pilot_aboard
	func get_payload_presence(_id: String) -> Dictionary:
		return {"all_aboard":payload_aboard}
class AdapterProbe:
	extends "res://scripts/meta/singleplayer_runtime_adapter.gd"
	var recoveries := 0
	var services := 0
	var observations := 0
	var evidence := {}
	var recover_completes_satellite := false
	func _recover_secured_campaign_chips() -> void:
		recoveries += 1
		if recover_completes_satellite:
			_campaign.get("data").jobs.satellite_recovery.status = "completed"
	func _service_context(_craft_id: String) -> Dictionary:
		services += 1
		return {}
	func _observe(value: Dictionary) -> void:
		observations += 1
		evidence = value.duplicate(true)
var checks := 0
var failures := 0
func _init() -> void:
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("PASS: " if ok else "FAIL: ", label)
func run() -> void:
	var campaign := CampaignProbe.new()
	var screen := ScreenProbe.new()
	var flow := FlowProbe.new()
	var presence := PresenceProbe.new()
	var adapter := AdapterProbe.new()
	adapter.set("_campaign",campaign)
	adapter.set("_screen",screen)
	adapter.set("_flow",flow)
	adapter.set("_base_personnel",presence)
	adapter.set("_campaign_mode",true)
	adapter.observe_campaign_progress()
	var expected := {"base_ready":true,"satellite_uploaded":false,"outpost_completed":true,
		"outpost_recruited":true,"crate_loaded":true,"delivery_completed":false,
		"outpost_chip_uploaded":true,"rescue_completed":false,"pilot_recruited":false,"second_pad_built":false}
	check(adapter.evidence == expected,"All ten owner facts match physical home readiness and job states")
	check(campaign.reads == 1,"One fresh progress projection after chip recovery")
	check(adapter.services == 0,"Unused service context is not built")
	check(screen.reads == 1,"Accepted first mission at home still reads real launch readiness")
	check(adapter.recoveries == 1,"Chip recovery remains before progress observation")
	var mission := Node.new()
	flow.add_child(mission)
	flow._active_mission = mission
	screen.reads = 0
	adapter.observe_campaign_progress()
	check(not adapter.evidence.base_ready and screen.reads == 0,"Active mission skips home-only UI projection")
	flow._active_mission = null
	flow._pending_mission_craft_transfers = [{"craft_id":"craft"}]
	screen.reads = 0
	adapter.observe_campaign_progress()
	check(not adapter.evidence.base_ready and screen.reads == 0,"Transit skips impossible home readiness")
	flow._pending_mission_craft_transfers = []
	flow._aircraft_location_by_craft.craft = "mission"
	screen.reads = 0
	adapter.observe_campaign_progress()
	check(not adapter.evidence.base_ready and screen.reads == 0,"A craft away from home skips readiness even without an active scene")
	flow._aircraft_location_by_craft.craft = "homebase"
	presence.payload_aboard = false
	adapter.observe_campaign_progress()
	check(not adapter.evidence.base_ready,"Assigned payload is not sufficient without physical boarding")
	presence.payload_aboard = true
	presence.pilot_aboard = false
	adapter.observe_campaign_progress()
	check(not adapter.evidence.base_ready,"Assigned pilot must physically be aboard")
	presence.pilot_aboard = true
	screen.pilot = ""
	adapter.observe_campaign_progress()
	check(not adapter.evidence.base_ready,"A pilot assignment is still required")
	screen.pilot = "pilot"
	screen.payload_ready = false
	adapter.observe_campaign_progress()
	check(not adapter.evidence.base_ready,"Existing launch payload gate remains required")
	screen.payload_ready = true
	adapter.observe_campaign_progress()
	check(adapter.evidence.base_ready,"Readiness changes are visible immediately without a retained cache")
	adapter.recover_completes_satellite = true
	screen.reads = 0
	adapter.observe_campaign_progress()
	check(adapter.evidence.satellite_uploaded and not adapter.evidence.base_ready and screen.reads == 0,"Progress reads mutations from recovery and skips irrelevant readiness")
	campaign.data.jobs.benit_delivery.status = "completed"
	campaign.data.jobs.buccaneer_rescue.status = "completed"
	campaign.data.progress.recruited_pilot = true
	campaign.data.progress.second_pad_built = true
	adapter.observe_campaign_progress()
	check(adapter.evidence.delivery_completed and adapter.evidence.rescue_completed and adapter.evidence.pilot_recruited and adapter.evidence.second_pad_built,"Later job and progression changes reach the next observation")
	adapter.set("_campaign_mode",false)
	var before := [campaign.reads,screen.reads,adapter.recoveries,adapter.observations]
	adapter.observe_campaign_progress()
	check(before == [campaign.reads,screen.reads,adapter.recoveries,adapter.observations],"Non-campaign path performs no observation work")
	adapter.free()
	presence.free()
	flow.free()
	screen.free()
	print("CAMPAIGN_OBSERVE_PROJECTION checks=",checks," failures=",failures)
	quit(0 if failures == 0 else 1)
