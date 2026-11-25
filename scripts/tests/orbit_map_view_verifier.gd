extends SceneTree
## Kopflos: Orbit-Karte (Vorgabe Handflug, Hintergrund, Schiffsgroessen, freier Orbit-Besuch am Notruf-Ort).
const CANVAS = preload("res://scripts/ui/orbit_area_canvas.gd")
const SPRITES = preload("res://scripts/ui/orbit_ship_sprites.gd")
const CAMPAIGN = preload("res://scripts/core/singleplayer_campaign_state.gd")
const ADAPTER = preload("res://scripts/meta/singleplayer_runtime_adapter.gd")
var passed := 0
var failed := 0

func check(ok: bool, text: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		print("FAIL: ", text)

func _initialize() -> void:
	var adapter := ADAPTER.new()
	check(not adapter._surface_orbit_manual_default and not adapter._orbit_auto_off("x"), "Ohne Oberflaeche bleibt die bisherige Vorgabe (automatisch)")
	adapter._surface_orbit_manual_default = true
	check(adapter._orbit_auto_off("x"), "Spieler-Oberflaeche: ohne gespeicherte Wahl Handflug")
	adapter._surface_orbit_auto_disabled["x"] = false
	check(not adapter._orbit_auto_off("x"), "Ausdruecklich gewaehlte Automatik bleibt automatisch")
	adapter.free()
	var flow_source := FileAccess.get_file_as_string("res://scripts/meta/meta_layer_flow.gd")
	check(flow_source.contains("_surface_orbit_manual_default\",true"), "Die Spieler-Oberflaeche setzt die Vorgabe Handflug")
	check(CANVAS.BACKGROUND_PLANET_EDGE == "top" and FileAccess.file_exists(CANVAS.BACKGROUND_PATH), "Hintergrunddatei vorhanden, Planet oben")
	var image := Image.load_from_file(ProjectSettings.globalize_path(CANVAS.BACKGROUND_PATH))
	check(image != null and image.get_width() <= 4096 and image.get_height() <= 4096, "Hintergrund hoechstens 4096 Pixel")
	var layout := load("res://scripts/mission/orbit_approach_layout.gd")
	var built: Dictionary = layout.build("planet")
	var mean_body_row := 0.0
	for cell: Vector2i in built.body_cells: mean_body_row += cell.y
	check(mean_body_row / maxf(1.0, built.body_cells.size()) < layout.MAP_SIZE.y * 0.25 and layout.ENTRY_BAND.position.y > layout.MAP_SIZE.y * 0.5, "Planetenbogen der Karte oben, Eintrittsband unten (passt zu BACKGROUND_PLANET_EDGE=top)")
	check(SPRITES.fields_for("cutlass") == 1 and SPRITES.fields_for("buccaneer") == 1 and SPRITES.fields_for("unbekannt") == 0, "Feldgroesse: Cutlass 1, Buccaneer 1, unbekannt 0 (altes Zeichen)")
	check(is_equal_approx(SPRITES.length_units("cutlass"), SPRITES.HEX_LENGTH_UNITS) and SPRITES.length_units("buccaneer") < SPRITES.HEX_LENGTH_UNITS, "Ein Feld = Laenge der Cutlass (16), Buccaneer kuerzer")
	var campaign := CAMPAIGN.new()
	campaign.configure()
	check(bool(campaign.validate_location_visit("distress_orbit").get("ok", false)), "distress_orbit ohne Auftrag anfliegbar")
	check(not bool(campaign.get_job_availability()["buccaneer_rescue"].can_accept), "Rettungsauftrag bleibt vor seiner Zeit nicht annehmbar")
	check(not campaign.has_open_job_at("distress_orbit"), "Ohne angenommenen Auftrag keine Begegnung (has_open_job_at=false)")
	print("ORBIT_MAP_VIEW passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)
