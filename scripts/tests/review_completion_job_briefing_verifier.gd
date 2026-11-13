extends SceneTree
## Read-only projections from real Campaign/Travel owners, plus actual card text.
const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const DISPLAY = preload("res://scripts/mission/campaign_display_catalog.gd")
const JOBS = preload("res://scripts/mission/singleplayer_job_contract.gd")
const CAMPAIGN = preload("res://scripts/core/singleplayer_campaign_state.gd")
const TRAVEL = preload("res://scripts/core/singleplayer_space_travel_state.gd")
const BOARD = preload("res://scripts/meta/singleplayer_job_board_presenter.gd")
const SKIN = preload("res://scripts/ui/smart_mobile_theme.gd")
const SATELLITE_IMAGE := "res://Assets/curated/mission_illustrations_20261113/satellite_recovery.png"
var passed: int = 0
var failed: int = 0

class SnapshotScreen extends Control:
	var snapshot: Dictionary = {}
	var commands: Array = []
	func get_operations_snapshot() -> Dictionary: return {"singleplayer":snapshot}
	func request_operation(operation: String, payload: Dictionary) -> Dictionary:
		commands.append([operation, payload])
		return {"ok":false, "reason":"read_only_fixture"}

func _init() -> void:
	if GUARD.require_isolated_user_data(): call_deferred("_run")

func _check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failed += 1
	print(("PASS " if value else "FAIL ") + label)

func _run() -> void:
	var campaign_owner := CAMPAIGN.new()
	var travel_owner := TRAVEL.new()
	_check(campaign_owner.configure().get("ok",false) and travel_owner.configure("briefing_craft").get("ok",false), "actual campaign and travel definitions configure")
	var campaign: Dictionary = campaign_owner.get_campaign_snapshot()
	var travel: Dictionary = travel_owner.get_snapshot()
	var before: String = JSON.stringify([campaign,travel],"",true)
	var expected := {"satellite_recovery":["glut_1a","Mond"], "outpost_recovery":["glut_1b","Mond"], "benit_delivery":["glut_1a","Mond"], "outpost_chip_recovery":["planet","Planet"], "buccaneer_rescue":["planet","Planet"]}
	var authored: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/job_briefings.json"))
	_check(campaign.jobs.size() == 5 and expected.size() == campaign.jobs.size(), "all five actual campaign jobs are covered")
	for id: String in expected:
		var briefing: Dictionary = JOBS.get_briefing(id,campaign,travel)
		var location_id: String = String(campaign.jobs[id].location_id)
		var orbit_id: String = String(travel.location_orbits[location_id])
		_check(briefing.body_id == expected[id][0] and briefing.body_kind == expected[id][1], id + " resolves its actual moon or planet")
		_check(briefing.location_id == location_id and briefing.orbit_id == orbit_id and briefing.body_id == travel.orbits[orbit_id].body_id and briefing.body_name == DISPLAY.body_name(briefing.body_id, travel.bodies[briefing.body_id]), id + " agrees with the authoritative star-map route")
		_check(briefing.site_label == DISPLAY.location_name(location_id, campaign.locations[location_id]) and not briefing.site_label.contains("Glut"), id + " uses the current location label without a stale body name")
		_check(briefing.objectives == authored[id].objectives and authored[id].size() == 1, id + " preserves all objectives without a duplicate location assignment")
		_check(JOBS.get_briefing(id) == briefing, id + " catalog-only inspection matches actual owner snapshots")
		print("JOB_BRIEFING ", id, " ", JSON.stringify(briefing))
	_check(JSON.stringify([campaign,travel],"",true) == before and campaign_owner.get_campaign_snapshot() == campaign and travel_owner.get_snapshot() == travel, "briefing reads never mutate either gameplay owner or supplied snapshots")
	_check(JOBS.get_briefing("unknown_job",campaign,travel).is_empty(), "unknown jobs do not invent a destination")
	# Projection-only alternate labels prove current owner snapshots beat caches;
	# no live gameplay definition or save file is modified by this test.
	var renamed_campaign: Dictionary = campaign.duplicate(true)
	var renamed_travel: Dictionary = travel.duplicate(true)
	renamed_campaign.locations.satellite_crash.name = "Testort aus aktuellem Owner"
	renamed_travel.bodies.glut_1a.name = "Testmond aus aktuellem Owner"
	var renamed: Dictionary = JOBS.get_briefing("satellite_recovery",renamed_campaign,renamed_travel)
	_check(renamed.site_label == renamed_campaign.locations.satellite_crash.name and renamed.body_name == renamed_travel.bodies.glut_1a.name, "supplied current owner labels override cached catalog names")
	renamed_travel.location_orbits.erase("satellite_crash")
	_check(JOBS.get_briefing("satellite_recovery",campaign,renamed_travel).body_name.is_empty(), "missing current route does not fall back to a fabricated planet")
	var screen := SnapshotScreen.new()
	screen.snapshot = {"mode":"campaign", "campaign":campaign.duplicate(true), "space_travel":travel}
	screen.snapshot.campaign["job_availability"] = campaign_owner.get_job_availability(true)
	root.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var board := BOARD.new()
	screen.add_child(board)
	board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board.configure(screen)
	board.refresh()
	board.get("_card_buttons").satellite_recovery.pressed.emit()
	var picture: TextureRect = board.get("_picture")
	_check(picture.texture != null and picture.texture.resource_path == SATELLITE_IMAGE and picture.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "actual satellite card binds the requested full wreck illustration without cropping dish or panels")
	for id: String in expected:
		var texture: Texture2D = SKIN.job_picture(id, String(campaign.jobs[id].location_id))
		_check(texture != null and ((texture.resource_path == SATELLITE_IMAGE) == (id == "satellite_recovery")), id + " retains its own illustration binding")
	_check(SKIN.job_picture("other_job", "satellite_crash") != SKIN.job_picture("satellite_recovery", "satellite_crash"), "another job at the same location never inherits the satellite-specific illustration")
	_check(SKIN.location_picture("satellite_crash") == picture.texture, "star-map satellite location uses the same cached illustration")
	var details: Label = board.get("_details")
	_check(details.text.contains("Himmelskörper: Neralis (Mond)") and details.text.contains("Einsatzgebiet: Aschental") and not details.text.contains("Glut"), "actual satellite card renders the same moon and location as the star map")
	for dimensions: Vector2i in [Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size = dimensions; root.content_scale_size = dimensions
		board._layout_device()
		for frame in range(5): await process_frame
		var objectives: Label = board.get("_objectives")
		_check(picture.get_global_rect().end.x <= details.global_position.x and absf(picture.global_position.y - details.global_position.y) < 2 and objectives.global_position.y >= picture.get_global_rect().end.y, "illustration and goals stay left with top-aligned facts " + str(dimensions))
		_check(not board.get("_summary").visible and not details.text.contains("Bestätigten Fortschritt") and objectives.text.contains("Satellitendaten bergen"), "dossier removes filler while retaining actual objectives " + str(dimensions))
	screen.snapshot.space_travel = renamed_travel.duplicate(true)
	screen.snapshot.space_travel.location_orbits.satellite_crash = "glut_1a_orbit"
	board.refresh()
	_check(details.text.contains("Testmond aus aktuellem Owner") and screen.commands.is_empty(), "actual presenter passes current travel snapshot without issuing gameplay commands")
	screen.queue_free()
	await process_frame
	print("REVIEW_COMPLETION_JOB_BRIEFING passed=%d failed=%d" % [passed,failed])
	quit(1 if failed else 0)
