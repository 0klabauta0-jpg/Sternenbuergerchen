extends "res://scripts/tests/review_completion_graphics_capture.gd"
## Same public preview interface on original and revised product sources.
const PORTRAITS = preload("res://scripts/meta/portrait_identity_catalog.gd")
const PREVIEW = preload("res://scripts/ui/components/personnel_body_preview.gd")

func run() -> void:
	output = OS.get_environment("SB_REVIEW_COMPLETION_CAPTURE_DIR")
	if output.is_empty() or OS.get_environment("SB_REVIEW2_USER_DIR").is_empty() or DisplayServer.get_name() == "headless":
		quit(2)
		return
	check(OS.get_user_data_dir().replace("\\", "/") == OS.get_environment("SB_REVIEW2_USER_DIR").replace("\\", "/"), "private profile")
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	START.request_start(self, "campaign", "new")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	current_scene = flow
	await frames(24)
	var screen: Node = flow.get_node("HomebaseScreen")
	var presenter: Node = screen.get("_operations_presenter")
	presenter.call("_act", "navigate", {"mode": "base"})
	await frames()
	var runtime: Node = flow.get("_singleplayer_runtime")
	var personnel: Node = runtime.call("get_base_personnel_runtime")
	var people: Array = personnel.call("get_snapshot").get("units", [])
	check(people.size() == 2, "actual campaign starts with both authored people")
	for index in people.size():
		var id := String(people[index].unit_id)
		screen.call("request_operation", "details", {"unit_id": id})
		await frames()
		var popup: Control = screen.get_node("CharacterSheetPopup")
		var preview: Node = popup.find_child("PersonnelBodyPreview", true, false)
		check(popup.is_visible_in_tree() and preview != null and preview.get_meta("preview_uses_existing_model", false), "actual start person uses real preview " + id)
		var base: Node = presenter.get("_base")
		var card: Button = base.find_child("SelectPerson_" + id.validate_node_name(), true, false)
		var detail: Label = popup.find_child("IdentityName", true, false)
		var name_edit: LineEdit = base.get("_person_name")
		var dock_name: String = name_edit.text if String(base.get("_selected_person_id")) == id else (card.text if card != null else "<missing>")
		var names := {"owner":String(people[index].name),"profile":String(screen.get("_profiles_by_id")[id].display_name),"detail":detail.text if detail != null else "<missing>","dock":dock_name}
		check(names.owner == names.profile and names.owner == names.detail and names.owner == names.dock, "native visible labels preserve the exact canonical person name " + id)
		await capture("personnel_start_%02d" % (index + 1), {"unit_id": id, "name": people[index].name, "name_projection":names, "portrait_path": screen.call("_get_profile_portrait_path", id)})
	flow.queue_free()
	current_scene = null
	await frames()
	var entries: Array = PORTRAITS.load_catalog().get("entries", [])
	check(entries.size() == 46, "all active canonical portraits represented")
	for start in range(0, entries.size(), 4):
		var host := Control.new()
		root.add_child(host)
		host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var backdrop := ColorRect.new()
		backdrop.color = Color("102b35")
		host.add_child(backdrop)
		backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var actors: Array[Node] = []
		var shown: Array = []
		for index in range(start, mini(start + 4, entries.size())):
			var entry: Dictionary = entries[index]
			var column := Control.new()
			host.add_child(column)
			column.position = Vector2(8 + (index - start) * 318, 8)
			column.size = Vector2(310, 704)
			var label := Label.new()
			label.text = String(entry.id)
			label.position = Vector2(30, 0)
			label.add_theme_font_size_override("font_size", 18)
			column.add_child(label)
			var portrait := TextureRect.new()
			portrait.texture = load(String(entry.path))
			portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			column.add_child(portrait)
			portrait.position = Vector2(55, 30)
			portrait.size = Vector2(200, 200)
			var actor: Node = load("res://scripts/npc/test_unit.gd").new()
			actor.unit_id = "catalog_pose"
			actor.team_id = "team_alpha"
			actor.armor_id = "suit"
			actor.portrait_path = String(entry.path)
			root.add_child(actor)
			actor.position = Vector2(-10000, -10000)
			actor.process_mode = Node.PROCESS_MODE_DISABLED
			actors.append(actor)
			var preview: Control = PREVIEW.new()
			column.add_child(preview)
			preview.position = Vector2(16, 234)
			preview.size = Vector2(278, 460)
			# Deliberately two arguments: works on the original source snapshot.
			preview.call("update_actor", actor, {"armor": "suit"})
			check(preview.get_meta("preview_uses_existing_model", false), "native catalog body " + String(entry.id))
			shown.append({"portrait_id": entry.id, "portrait_path": entry.path, "same_actor_slot": "catalog_pose", "appearance": preview.get("_model").get_meta("portrait_appearance", "original")})
		await capture("personnel_catalog_%02d" % (start / 4 + 1), {"portraits": shown, "camera": "unchanged PersonnelBodyPreview bounds/idle/lights"})
		host.queue_free()
		for actor in actors: actor.queue_free()
		await frames()
	var file := FileAccess.open(output.path_join("capture_manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	print("REVIEW_PERSONNEL_CAPTURE passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)
