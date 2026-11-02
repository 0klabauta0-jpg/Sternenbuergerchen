extends SceneTree

# UI identity/preview regression only; does not stage a gameplay actor or flight.
const VISUALS: GDScript = preload("res://scripts/terrain/frontier_ship_visuals.gd")
const MODEL := "res://Assets/curated/frontier_illustrated_20261101/ships_pass05_astra_ultra/refinement_03/cutlass_01.glb"
const PREVIEW := "res://Assets/curated/ui_native_r4/cutlass_ref03_preview.png"
const METADATA := "res://Assets/curated/ui_native_r4/cutlass_ref03_preview.json"
var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		push_error("FAIL: " + label)

func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var craft := {"craft_id": "dropship_1", "craft_type": "dropship", "display_name": "Dropship 1", "texture_path": "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png"}
	var before := JSON.stringify(craft)
	var flow: Node = load("res://scripts/meta/meta_layer_flow.gd").new()
	var actual_default: Dictionary = flow.call("_build_homebase_aircraft_definition", "dropship", 1)
	_check(String(actual_default.get("craft_id", "")) == "dropship_1" and String(actual_default.get("craft_type", "")) == "dropship", "actual first-player factory retains its stable craft ID and type")
	_check(not actual_default.has("texture"), "actual first-player factory uses a declared texture path, not a hidden direct Speeder override")
	flow.free()
	var identity: Dictionary = VISUALS.get_ui_identity(craft)
	_check(String(identity.get("asset_id", "")) == "cutlass_01", "declared dropship role resolves the actual Cutlass identity")
	_check(String(identity.get("model_path", "")) == MODEL, "UI identity points at the active exact Ref03 GLB")
	_check(String(identity.get("sha256", "")) == FileAccess.get_sha256(MODEL), "active model bytes match the visual catalog")
	var metadata_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(METADATA))
	var metadata: Dictionary = metadata_value if metadata_value is Dictionary else {}
	_check(String(metadata.get("kind", "")) == "native_exact_model_ui_preview", "preview is documented as a native exact-model capture")
	_check(String(metadata.get("source_model", "")) == MODEL and String(metadata.get("source_sha256", "")) == FileAccess.get_sha256(MODEL), "native preview provenance pins the exact model bytes")
	_check(not bool(metadata.get("geometry_material_override", true)), "preview does not alter model geometry or materials")
	var preview: Texture2D = VISUALS.get_ui_preview_texture(craft)
	_check(preview != null and preview.resource_path == PREVIEW, "Cutlass preview replaces the generic Speeder resource")
	if preview != null:
		var pixels: Image = preview.get_image()
		_check(pixels != null and pixels.get_pixel(0, 0).a < 0.05, "model preview retains a transparent background")
		_check(preview == VISUALS.get_ui_preview_texture(craft), "same native UI preview resource is cached and reused")
	_check(VISUALS.get_ui_display_name(craft) == "Cutlass 1", "default first-ship label visibly names the Cutlass class")
	var named := craft.duplicate(true)
	named["display_name"] = "Nachtigall ÄÖÜ"
	var named_before := JSON.stringify(named)
	_check(VISUALS.get_ui_display_name(named) == "Cutlass · Nachtigall ÄÖÜ", "player-selected ship names remain verbatim beside the class")
	_check(VISUALS.decorate_ui_title("#19 Nachtigall ÄÖÜ · FOB", named) == "#19 Cutlass · Nachtigall ÄÖÜ · FOB", "class projection retains order number, custom name and context")
	_check(JSON.stringify(named) == named_before and JSON.stringify(craft) == before, "UI projection never changes craft IDs, names, texture paths or state")
	var cargo := {"craft_id": "cargo_1", "craft_type": "craft_cargoB", "display_name": "Frachter"}
	_check(VISUALS.get_ui_identity(cargo).is_empty() and VISUALS.get_ui_preview_texture(cargo) == null, "other craft classes are not relabeled or pictured as Cutlass")
	_check(VISUALS.get_ui_display_name(cargo) == "Frachter", "non-dropship label remains unchanged")
	_check(VISUALS.get_ui_preview_texture({"visual_asset_id": "unknown_ship", "craft_type": "dropship"}) == null, "explicit unknown visual identity does not impersonate the default Cutlass")
	_check(VISUALS.get_ui_preview_texture({"visual_asset_id": "buccaneer_01", "craft_type": "dropship"}) == null, "a different known model without this preview cannot borrow the Cutlass picture")
	var home: Control = load("res://scenes/meta/homebase_test_screen.tscn").instantiate()
	root.add_child(home)
	await process_frame
	_check(home.call("_get_aircraft_texture", craft) == preview, "Homebase shipcards use the exact native Cutlass preview")
	_check(home.call("_get_aircraft_texture", actual_default) == preview, "actual first-player definition reaches the exact preview in Homebase")
	var direct_legacy := craft.duplicate(true)
	direct_legacy["texture"] = load(String(craft["texture_path"])) as Texture2D
	_check(home.call("_get_aircraft_texture", direct_legacy) == preview, "an obsolete direct Speeder texture cannot override the declared Cutlass visual model")
	var card: Control = home.call("_build_shipcard", craft)
	# The outer MarginContainer is deliberately unnamed in production and gets
	# an engine-generated name while detached. Only the preview has a stable name.
	var texture: TextureRect = card.find_child("ShipTexture", true, false) as TextureRect
	if texture != null:
		print("CUTLASS_HOMEBASE_PREVIEW_GEOMETRY position=%s size=%s minimum=%s" % [texture.position, texture.size, texture.get_combined_minimum_size()])
	_check(texture != null and texture.texture == preview and bool(texture.get_meta("frontier_model_preview", false)), "Homebase card records actual model-preview identity")
	_check(texture != null and texture.position == Vector2.ZERO and texture.size == Vector2(94, 62), "old Speeder crop cannot clip the complete Cutlass silhouette")
	_check(texture != null and texture.get_meta("homebase_shipcard_visual_offset") == texture.position and not bool(texture.get_meta("homebase_shipcard_visual_crop_compensates_transparency", true)), "Homebase geometry metadata describes the actual uncropped model preview")
	card.free()
	home.queue_free()
	await process_frame
	var fob: Control = load("res://scenes/meta/fob_test_screen.tscn").instantiate()
	root.add_child(fob)
	await process_frame
	for phase in ["parked", "mission_transit_to_map", "mission_transit_to_fob", "is_in_transit"]:
		var state := craft.duplicate(true)
		if phase != "parked":
			state[phase] = true
		_check(fob.call("_get_transport_craft_texture", state) == preview, "FOB retains the actual Cutlass preview during " + phase)
	_check(String(fob.call("_build_transport_craft_title", named)).contains("Cutlass · Nachtigall ÄÖÜ"), "FOB title projects class without overwriting the custom name")
	fob.queue_free()
	await process_frame
	var scene: Node = load("res://scenes/tests/mission_reactivity_test.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var controller: Node = scene.get_node("TacticalController")
	_check(controller.call("_get_mission_dropship_card_texture", craft) == preview, "mission card uses the exact model preview")
	_check(controller.call("_get_dropship_texture_for_angle", "SE") != preview, "static UI preview is never substituted for a directional world sprite")
	_check(String(controller.call("_build_mission_dropship_title_text", named)).contains("Cutlass · Nachtigall ÄÖÜ"), "mission title preserves custom identity with the Cutlass class")
	scene.queue_free()
	for index in range(3):
		await process_frame
	print("RESULTS: %d passed, %d failed" % [passed, failed])
	if failed == 0:
		print("PASS: native R4 Cutlass identity")
	quit(0 if failed == 0 else 1)
