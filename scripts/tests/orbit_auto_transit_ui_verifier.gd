extends SceneTree
const SCREEN = preload("res://scripts/ui/star_map_screen.gd")
var calls: Array = []
var runtime := {"mode":"campaign", "onboarding":{"stage_index":1}, "campaign":{"selected_location_id":"homebase", "selected_job_id":"", "locations":{}, "jobs":{}}, "space_travel":{"phase":"grounded", "craft_id":"ship", "orbit_id":"moon_orbit", "position":[0.25,0.62], "target_orbit_id":"", "origin_position":[0.25,0.62], "progress":0.0, "elapsed_seconds":0.0, "duration_seconds":3.0, "orbit_transit_automatic":true, "orbit_transit_available":true}}

func _init() -> void: call_deferred("_run")
func _snapshot() -> Dictionary: return runtime.duplicate(true)
func _command(operation: String, payload: Dictionary = {}) -> Dictionary:
	calls.append({"operation":operation, "payload":payload.duplicate(true)})
	if operation == "space_set_orbit_automatic": runtime.space_travel.orbit_transit_automatic = payload.enabled
	return {"ok":true}

func _run() -> void:
	var view = SCREEN.new(); root.add_child(view); view.configure(_snapshot, _command)
	await process_frame
	var button: Button = view.find_child("OrbitAutomatic", true, false)
	assert(button != null and not button.disabled and button.text == "Durchflug: an")
	button.pressed.emit()
	assert(calls.size() == 1 and calls[0].operation == "space_set_orbit_automatic" and calls[0].payload == {"craft_id":"ship", "enabled":false})
	assert(button.text == "Durchflug: aus")
	runtime.space_travel.orbit_transit_available = false
	view.refresh()
	assert(button.disabled)
	view.queue_free(); await process_frame
	print("ORBIT_AUTO_TRANSIT_UI passed")
	quit()
