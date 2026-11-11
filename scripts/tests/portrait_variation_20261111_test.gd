extends SceneTree

const CATALOG = preload("res://scripts/meta/portrait_identity_catalog.gd")
const PROFILE = preload("res://scripts/meta/meta_unit_profile.gd")
const SHEET = preload("res://scripts/meta/character_sheet_view.gd")
const CARD = preload("res://scripts/meta/npc_compact_card.gd")
const GENERATOR = preload("res://scripts/meta/start_roster_generator.gd")

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var surface := ColorRect.new()
	surface.color = Color("102c36")
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(surface)
	var columns := HBoxContainer.new()
	columns.position = Vector2(28, 28)
	columns.size = Vector2(1864, 1024)
	columns.add_theme_constant_override("separation", 20)
	surface.add_child(columns)
	var catalog := CATALOG.load_catalog()
	_check(catalog.entries.size() == 46, "42 original and four additional identities")
	var old_catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/portraits_20261105/catalog_before_refresh.json"))
	for old: Dictionary in old_catalog.entries:
		_check(catalog.entries_by_id.has(old.id), "Original identity retained %s" % old.id)
	var generated_ids := {}
	for seed_index in range(12):
		var roster := GENERATOR.generate_start_roster("portrait_variants_%d" % seed_index, 30, "portrait_test")
		for unit: Dictionary in roster.units:
			generated_ids[unit.portrait_id] = true
	var names := ["Anja · Bildvariante", "Samira · Bildvariante", "Tomas · Bildvariante", "Erik · Bildvariante"]
	var sheets: Array[VBoxContainer] = []
	for index in range(4):
		var id := "char_portrait_%03d" % (45 + index)
		var texture := CATALOG.load_texture(id)
		_check(texture is AtlasTexture and texture.get_size() == Vector2(512, 768), "Bounded texture loads %s" % id)
		_check(generated_ids.has(id), "Normal recruitment generator reaches %s" % id)
		var profile = PROFILE.new({"unit_id": id, "display_name": names[index], "portrait_id": id,
			"portrait_path": CATALOG.resolve_path(id), "role_name": "Rifle Operator",
			"roster_role_category": "operator", "callsign": "TEST",
			"skill_values": {"accuracy": 0.55, "speed": 0.55, "toughness": 0.55}})
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		columns.add_child(column)
		var hero := TextureRect.new()
		hero.texture = texture
		hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hero.custom_minimum_size = Vector2(400, 740)
		column.add_child(hero)
		var card = CARD.new()
		column.add_child(card)
		card.setup_from_profile(profile, {"compact_mode": true})
		var sheet := VBoxContainer.new()
		surface.add_child(sheet)
		sheet.position = Vector2(28, 1100)
		sheet.size = Vector2(900, 1000)
		sheets.append(sheet)
		SHEET.render(sheet, profile, {"editable_metrics": false})
		await process_frame
		var portrait := sheet.find_child("PortraitRect", true, false) as TextureRect
		_check(portrait != null and portrait.texture == texture, "Actual character sheet resolves %s" % id)
		var compact := card.get_node("Margin/HBox/PortraitRect") as TextureRect
		_check(compact.texture == texture, "Actual compact roster card resolves %s" % id)
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://output/native_glut_maps/portrait_variation_native.png")
		columns.hide()
		for index in range(sheets.size()):
			sheets[index].position = Vector2(28, 28)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://output/native_glut_maps/portrait_sheet_%d.png" % index)
			sheets[index].hide()
	surface.queue_free()
	await process_frame
	print("PORTRAIT_VARIATION_RESULTS %d passed, %d failed" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _check(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		push_error(message)
