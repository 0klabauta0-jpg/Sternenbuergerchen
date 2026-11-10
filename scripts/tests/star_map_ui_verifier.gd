extends SceneTree
## Catches accidental jump-on-selection, unavailable actions and hidden load boundaries.

var checks := 0
var failed := 0
var _calls: Array = []
var _reject_next := false
class EmbeddedOwner:
	extends Control
	var runtime: Dictionary
	func get_operations_snapshot() -> Dictionary:
		return {"singleplayer": runtime.duplicate(true)}
	func request_operation(_operation: String, _payload: Dictionary = {}) -> Dictionary:
		return {"ok": true}
var _runtime: Dictionary = {
	"mode": "campaign", "onboarding": {"stage_index": 1},
	"campaign": {
		"selected_location_id": "homebase", "selected_job_id": "",
		"locations": {"homebase": {"name": "Mondbasis"}, "satellite_crash": {"name": "Satelliten-Absturzstelle"}, "trade_outpost": {"name": "Handelsposten"}},
		"jobs": {"satellite_recovery": {"location_id": "satellite_crash", "status": "accepted", "title": "Satellitenbergung"},"outpost_recovery":{"location_id":"trade_outpost","status":"offered","title":"Außenposten","prerequisite_job_id":"satellite_recovery"}}
	},
	"space_travel": {"phase": "grounded", "craft_id": "dropship_1", "orbit_id": "moon_orbit", "position": [0.25, 0.62], "target_orbit_id": "", "origin_position": [0.25, 0.62], "progress": 0.0, "elapsed_seconds": 0.0, "duration_seconds": 3.0}
}

func _init() -> void:
	call_deferred("_run")

func _snapshot() -> Dictionary:
	return _runtime.duplicate(true)

func _command(operation: String, payload: Dictionary = {}) -> Dictionary:
	_calls.append({"operation": operation, "payload": payload.duplicate(true)})
	if _reject_next:
		_reject_next = false
		return {"ok": false, "message": "Kein freies Landepad", "reason": "pad_busy"}
	if operation == "select_destination":
		_runtime.campaign.selected_location_id = String(payload.get("location_id", ""))
		_runtime.campaign.selected_job_id = String(payload.get("job_id", ""))
	return {"ok": true}

func _check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failed += 1
		printerr("FAIL: " + label)

func _run() -> void:
	var path := "res://scripts/ui/star_map_screen.gd"
	_check(FileAccess.file_exists(path), "Star map view exists")
	if not FileAccess.file_exists(path):
		print("STAR_MAP_UI checks=%d failed=%d" % [checks, failed])
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var view = load(path).new()
	root.add_child(view)
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.configure(_snapshot, _command)
	await process_frame
	var moon: Button = view.find_child("MoonOrbit", true, false)
	var planet: Button = view.find_child("PlanetOrbit", true, false)
	var abort: Button = view.find_child("AbortQuantum", true, false)
	var satellite: Button = view.find_child("SatelliteDestination", true, false)
	var trade: Button = view.find_child("TradeDestination", true, false)
	var approach: Button = view.find_child("BeginApproach", true, false)
	var land: Button = view.find_child("LandHomebase", true, false)
	_check(moon != null and planet != null, "Two celestial bodies have keyboard-accessible actions")
	_check(moon.disabled and planet.disabled, "Grounded preview cannot jump")
	_check(satellite.disabled and trade.disabled, "Surface destinations cannot be selected from the base")
	_check(not abort.visible and not approach.visible and not land.visible, "Grounded preview has no in-flight actions")
	_check(String(view.get_ui_snapshot().status).contains("Flightdeck"), "Grounded preview explains how to take off")
	_runtime.space_travel.phase = "orbit"
	view.refresh()
	_check(moon.disabled and not planet.disabled, "Moon orbit permits planet jump, not same-orbit jump")
	_check(land.visible and not land.disabled, "Moon orbit offers base landing")
	planet.pressed.emit()
	_check(_calls.back() == {"operation": "space_start_quantum", "payload": {"craft_id": "dropship_1", "target_orbit_id": "planet_orbit"}}, "Planet click requests actual quantum jump")
	view.find_child("PlanetBody", true, false).pressed.emit()
	_check(_calls.back().payload.target_orbit_id == "planet_orbit", "Planet graphic itself is a clickable travel target")
	_runtime.space_travel.merge({"phase": "quantum", "target_orbit_id": "planet_orbit", "progress": 0.4, "position": [0.438, 0.532]}, true)
	view.refresh()
	_check(abort.visible and not abort.disabled and moon.disabled and planet.disabled, "Active jump exposes abort and prevents accidental retarget")
	abort.pressed.emit()
	_check(_calls.back().operation == "space_abort_quantum", "Abort sends command without moving local owner")
	_check(_runtime.space_travel.phase == "quantum", "UI does not manufacture abort completion")
	_runtime.space_travel.merge({"phase": "stopped", "orbit_id": "", "target_orbit_id": ""}, true)
	view.refresh()
	_check(not moon.disabled and not planet.disabled, "Stopped ship can resume toward either orbit")
	_check(satellite.disabled and trade.disabled, "Stopped ship cannot bypass orbit for approach")
	view.find_child("MoonBody", true, false).pressed.emit()
	_check(_calls.back().payload.target_orbit_id == "moon_orbit", "Stopped ship can retarget to the actual moon graphic")
	planet.pressed.emit()
	_check(_calls.back().operation == "space_start_quantum", "Same planet can be requested again after abort")
	_runtime.space_travel.merge({"phase": "orbit", "orbit_id": "planet_orbit", "position": [0.72, 0.40], "target_orbit_id": "", "progress": 1.0}, true)
	view.refresh()
	_check(not satellite.disabled and trade.disabled, "Campaign planet orbit respects real tutorial locks")
	_check(not String(view.get_ui_snapshot().trade_reason).is_empty(), "Locked trade has a visible reason")
	satellite.pressed.emit()
	_check(_calls.back() == {"operation": "select_destination", "payload": {"location_id": "satellite_crash", "job_id": "satellite_recovery"}}, "Location selection retains accepted job binding")
	_check(approach.visible and not approach.disabled, "Selecting reachable site enables explicit approach")
	_check(String(view.get_ui_snapshot().load_boundary).contains("Sternkarte") and String(view.get_ui_snapshot().load_boundary).contains("Ortskarte"), "Approach explains the coming scene boundary")
	_check(_calls.filter(func(call: Dictionary): return call.operation == "space_begin_approach").is_empty(), "Location selection never loads a map")
	_reject_next = true
	approach.pressed.emit()
	_check(_calls.back() == {"operation": "space_begin_approach", "payload": {"craft_id": "dropship_1", "location_id": "satellite_crash"}}, "Explicit approach uses selected location and real craft")
	_check(String(view.get_ui_snapshot().error).contains("Landepad"), "Runtime rejection is readable")
	view.refresh()
	_check(String(view.get_ui_snapshot().error).contains("Landepad"), "Periodic refresh does not erase action rejection")
	_runtime.onboarding.stage_index = 3
	_runtime.campaign.jobs.satellite_recovery.status = "completed"
	view.refresh()
	_check(not trade.disabled, "Completed introduction permits both planet sites")
	trade.pressed.emit()
	_check(_calls.back().payload.job_id == "", "Trade visit does not invent a combat job")
	_runtime.onboarding.stage_index = 1
	_runtime.campaign.jobs.satellite_recovery.status = "accepted"
	_runtime.campaign.selected_location_id = "satellite_crash"
	_runtime.campaign.selected_job_id = "satellite_recovery"
	view.refresh()
	for dimensions in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		await process_frame
		await process_frame
		_check_layout(view, "standalone %s" % str(dimensions))
	var embedded_owner := EmbeddedOwner.new()
	embedded_owner.runtime = _snapshot()
	embedded_owner.size = Vector2(800, 650)
	root.add_child(embedded_owner)
	var region = load("res://scripts/meta/singleplayer_region_map_presenter.gd").new()
	embedded_owner.add_child(region)
	region.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	region.configure(embedded_owner)
	await process_frame
	await process_frame
	_check_layout(region.get("_map"), "embedded 800x650")
	embedded_owner.free()
	var before: Dictionary = _snapshot()
	var children: int = view.get_child_count()
	for repeat in range(20):
		view.refresh()
	_check(_snapshot() == before, "Repeated presentation reads preserve runtime state")
	_check(view.get_child_count() == children, "Refresh preserves existing control tree")
	_reject_next = true
	approach.pressed.emit()
	_check(not String(view.get_ui_snapshot().error).is_empty(), "A new rejected approach remains associated with the current phase")
	_runtime.space_travel.phase = "approach"
	view.refresh()
	_check(moon.disabled and planet.disabled and satellite.disabled and trade.disabled, "Approach locks travel and selection while map handoff occurs")
	_check(String(view.get_ui_snapshot().status).contains("geladen"), "Map-loading phase is explicit")
	_check(String(view.get_ui_snapshot().error).is_empty(), "Phase change clears obsolete rejection")
	view.free()
	print("STAR_MAP_UI checks=%d failed=%d" % [checks, failed])
	quit(1 if failed else 0)

func _check_layout(view: Control, label: String) -> void:
	var bounds: Rect2 = view.get_global_rect().grow(1)
	for node_name in ["MoonOrbit", "PlanetOrbit", "TravelStatus", "SatelliteDestination", "TradeDestination", "LocationLocks", "SelectedDestination", "BeginApproach", "LoadBoundary"]:
		var control: Control = view.find_child(node_name, true, false)
		if control != null and control.is_visible_in_tree():
			_check(bounds.encloses(control.get_global_rect()), "%s keeps %s in the visible frame: %s within %s" % [label, node_name, str(control.get_global_rect()), str(bounds)])
	var canvas: Control = view.find_child("SystemMap", true, false)
	var details: Control = view.find_child("DetailsPanel", true, false)
	_check(details != null, label + " provides a compact right-side destination panel")
	if details == null:
		return
	_check(canvas.get_global_rect().end.x <= details.get_global_rect().position.x + 1, label + " keeps the system map left of its details")
	_check(canvas.size.x >= 350 and details.size.x >= 240 and details.size.x <= 320, label + " preserves usable map and compact detail widths")
	var status: Control = view.find_child("TravelStatus", true, false)
	var satellite: Control = view.find_child("SatelliteDestination", true, false)
	var approach: Control = view.find_child("BeginApproach", true, false)
	var boundary: Control = view.find_child("LoadBoundary", true, false)
	_check(details.get_global_rect().grow(1).encloses(status.get_global_rect()), label + " keeps travel status inside the detail panel")
	_check(status.get_global_rect().end.y <= satellite.get_global_rect().position.y + 1, label + " separates status from destination selection")
	_check(satellite.get_global_rect().end.y <= approach.get_global_rect().position.y + 1, label + " separates selection from approach")
	_check(approach.get_global_rect().end.y <= boundary.get_global_rect().position.y + 1, label + " separates approach from load explanation")
	for control in [satellite, view.find_child("TradeDestination", true, false), approach]:
		_check(control.size.x <= 300, label + " uses compact natural-width actions")
