extends SceneTree
var failures := 0
var checks := 0
var calls: Array = []
var runtime: Dictionary
func _init() -> void: call_deferred("_run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func snapshot() -> Dictionary: return runtime.duplicate(true)
func command(operation: String, payload: Dictionary = {}) -> Dictionary:
	calls.append({"operation":operation,"payload":payload.duplicate(true)})
	if operation == "select_destination":
		runtime.campaign.selected_location_id = payload.location_id
		runtime.campaign.selected_job_id = payload.job_id
	return {"ok":true}
func _run() -> void:
	var campaign = load("res://scripts/core/singleplayer_campaign_state.gd").new()
	check(campaign.configure().ok,"Current authored content configures")
	runtime = {"mode":"campaign","campaign":campaign.get_campaign_snapshot(),"onboarding":{"stage_index":2},"space_travel":{"phase":"orbit","orbit_id":"planet_orbit","craft_id":"dropship_1"}}
	var view = load("res://scripts/ui/star_map_screen.gd").new()
	root.size = Vector2i(1280,720)
	root.add_child(view)
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.configure(snapshot,command)
	await process_frame
	check(view.find_child("FortifiedDestination",true,false) != null,"Fourth mission location is visible in actual UI")
	check(view.find_child("DistressDestination",true,false) != null,"Space rescue location is visible in actual UI")
	var sites: Dictionary = view.get("_sites")
	for location_id in ["satellite_crash", "trade_outpost", "fortified_outpost", "distress_orbit", "polisa"]:
		check(sites.has(location_id), "Existing or new destination rendered: " + location_id)
	check(sites.size() == 5, "Only the four Main destinations and the added station are rendered")
	if sites.has("polisa"):
		check(not sites.polisa.disabled, "Polisa is available as a free visit")
		sites.polisa.pressed.emit()
		check(not calls.is_empty() and calls.back().payload.location_id == "polisa" and calls.back().payload.job_id == "", "Actual UI selects Polisa without fabricating a job")
	check(view.find_child("TradeDestination",true,false).disabled,"Future outpost locked by real prerequisite")
	check(not view.find_child("SatelliteDestination",true,false).disabled,"First location available despite obsolete stage2 hint")
	runtime.campaign.jobs.satellite_recovery.status = "completed"
	runtime.campaign.jobs.outpost_recovery.status = "completed"
	runtime.campaign.jobs.outpost_recovery.locked = false
	runtime.campaign.jobs.benit_delivery.locked = false
	runtime.campaign.jobs.benit_delivery.status = "accepted"
	runtime.campaign.selected_job_id = "benit_delivery"
	view.refresh()
	view.find_child("SatelliteDestination",true,false).pressed.emit()
	check(calls.back().payload.job_id == "benit_delivery","Third mission can revisit A with delivery binding")
	check(view.find_child("BeginApproach",true,false).visible and not view.find_child("BeginApproach",true,false).disabled,"Delivery revisit can actually approach")
	for pair in [["outpost_chip_recovery","fortified_outpost","FortifiedDestination"],["buccaneer_rescue","distress_orbit","DistressDestination"]]:
		runtime.campaign.jobs[pair[0]].locked = false
		runtime.campaign.jobs[pair[0]].status = "accepted"
		runtime.campaign.selected_job_id = pair[0]
		view.refresh()
		var button: Button = view.find_child(pair[2],true,false)
		if button != null:
			button.pressed.emit()
			check(calls.back().payload.location_id == pair[1],"Actual UI selects " + pair[1])
			var approach: Button = view.find_child("BeginApproach",true,false)
			check(approach.visible and not approach.disabled,"Actual UI exposes approach for " + pair[1])
			approach.pressed.emit()
			check(calls.back().operation == "space_begin_approach" and calls.back().payload.location_id == pair[1],"Approach routes actual selected external place")
	var canvas: Node = view.find_child("SystemMap",true,false)
	var points := {}
	for id in ["satellite_crash","trade_outpost","fortified_outpost","distress_orbit"]:
		var point: Vector2 = canvas.location_map_point(id)
		check(not points.has(point),"Location marker has distinct coordinate: " + id)
		points[point] = true
	runtime.campaign.locations["future_region"] = {"name":"Weiteres Gebiet","region_position":[0.25,0.5]}
	view.refresh()
	check(Dictionary(view.get("_sites")).has("future_region"),"New authored fifth destination appears without code changes")
	check(canvas.get("_location_buttons").has("future_region"),"New authored destination gets actual map marker")
	runtime.mode = "skirmish"
	view.refresh()
	for button: Button in Dictionary(view.get("_sites")).values(): check(not button.disabled,"Skirmish external place stays open")
	var before := Dictionary(view.get("_sites")).duplicate()
	view.refresh()
	check(before == Dictionary(view.get("_sites")),"Refresh reuses unchanged destination controls")
	view.free()
	print("Campaign star map: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
