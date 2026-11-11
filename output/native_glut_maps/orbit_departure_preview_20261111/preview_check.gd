extends SceneTree

class OnboardingProbe extends RefCounted:
	func get_snapshot() -> Dictionary:
		return {"stage_index":0}

class CampaignProbe extends RefCounted:
	func get_campaign_snapshot() -> Dictionary:
		return {"selected_location_id":"homebase","selected_job_id":"","jobs":{},"locations":{"homebase":{}}}

class PilotProbe extends Node:
	func is_pilot_aboard(_craft_id: String) -> bool:
		return false

class AdapterProbe extends "res://scripts/meta/singleplayer_runtime_adapter.gd":
	var observations := 0
	func observe_campaign_progress() -> void:
		observations += 1
	func get_space_travel_snapshot(_craft_id: String = "") -> Dictionary:
		return {}
	func _selected_destination_is_free_visit() -> bool:
		return false

var failures := 0
func check(condition: bool, label: String) -> void:
	if not condition: failures += 1
	print("PASS " if condition else "FAIL ", label)

func _initialize() -> void:
	var adapter := AdapterProbe.new()
	adapter._campaign_mode = true
	adapter._onboarding = OnboardingProbe.new()
	adapter._campaign = CampaignProbe.new()
	var preview: Dictionary = adapter.preview_departure("ship")
	check(preview.get("reason") == "preparation_incomplete" and adapter.observations == 0,
		"campaign preview preserves tutorial gate without recovery/onboarding observation")
	var legacy: Dictionary = adapter.validate_departure("ship")
	check(legacy.get("reason") == preview.get("reason") and adapter.observations == 1,
		"existing validation retains its observation before tutorial gate")
	var pilot := PilotProbe.new()
	adapter.add_child(pilot)
	adapter._base_personnel = pilot
	var blocked: Dictionary = adapter.validate_departure("ship")
	check(blocked.get("reason") == "pilot_not_aboard" and adapter.observations == 1,
		"existing pilot gate still precedes observation")
	adapter._base_personnel = null
	adapter._campaign_mode = false
	var plain_preview: Dictionary = adapter.preview_departure("ship")
	var plain_validation: Dictionary = adapter.validate_departure("ship")
	check(plain_preview.get("reason") == "destination_missing" and plain_preview == plain_validation and adapter.observations == 1,
		"noncampaign preview and validation retain the same destination gate")
	adapter.free()
	print("DEPARTURE_PREVIEW_RESULT checks=4 failures=", failures, " runtime_wired=false")
	quit(1 if failures else 0)
