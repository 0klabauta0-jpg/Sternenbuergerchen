class_name MetaMapScreen
extends Control

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_RENDERER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_renderer.gd")
const META_UI_SKIN_SCRIPT: GDScript = preload("res://scripts/meta/meta_ui_skin.gd")
const DROPSHIP_NPC_CAPACITY := 6

var _map_file_path: String = "res://maps/test_mission.json"
var _mission_name: String = "Operation: FOB Transfer"
var _mission_slot_count: int = 3
var _selected_unit_ids: PackedStringArray = []
var _fob_overview: Dictionary = {}
var _terrain_renderer = null


func _ready() -> void:
	META_UI_SKIN_SCRIPT.apply_map(self)
	_configure_compact_layout()
	if _terrain_renderer == null:
		_terrain_renderer = TERRAIN_MAP_RENDERER_SCRIPT.new()
	var preview_clip := get_node("Panel/Margin/VBox/ContentRow/MapPanel/MapMargin/MapVBox/MapPreviewFrame/MapPreviewMargin/MapPreviewClip") as Control
	if preview_clip != null and not preview_clip.resized.is_connected(_on_map_preview_clip_resized):
		preview_clip.resized.connect(_on_map_preview_clip_resized)
	_ensure_mission_craft_card()
	call_deferred("_render")


func set_map_context(mission_name: String, map_file_path: String, selected_unit_ids: PackedStringArray, fob_overview: Dictionary, mission_slot_count: int = 3) -> void:
	_mission_name = mission_name.strip_edges() if not mission_name.strip_edges().is_empty() else _mission_name
	_map_file_path = map_file_path.strip_edges() if not map_file_path.strip_edges().is_empty() else _map_file_path
	_mission_slot_count = maxi(mission_slot_count, 1)
	_selected_unit_ids = selected_unit_ids.duplicate()
	_fob_overview = fob_overview.duplicate(true)
	if is_inside_tree():
		_render()


func _render() -> void:
	var mission_header_label := get_node("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionHeaderLabel") as Label
	var map_name_label := get_node("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/MapNameLabel") as Label
	var operator_count_label := get_node("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/OperatorCountLabel") as Label
	var fireteam_count_label := get_node("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/FireteamCountLabel") as Label
	var mission_summary_label := get_node("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionSummaryLabel") as Label
	var map_capacity_label := get_node("Panel/Margin/VBox/ContentRow/MapPanel/MapMargin/MapVBox/MapHeaderRow/MapCapacityLabel") as Label
	var marker_list_label := get_node("Panel/Margin/VBox/ContentRow/MapPanel/MapMargin/MapVBox/MarkerListLabel") as Label
	var map_data_label := get_node("Panel/Margin/VBox/ContentRow/MapPanel/MapMargin/MapVBox/MapDataLabel") as Label
	var map_help_label := get_node("Panel/Margin/VBox/ContentRow/MapPanel/MapMargin/MapVBox/MapHelpLabel") as Label
	var fireteam_overview_label := get_node("Panel/Margin/VBox/ContentRow/SummaryPanel/SummaryMargin/SummaryVBox/FireteamOverviewLabel") as Label
	var dropship_overview_label := get_node("Panel/Margin/VBox/ContentRow/SummaryPanel/SummaryMargin/SummaryVBox/DropshipOverviewLabel") as Label
	var respawn_overview_label := get_node("Panel/Margin/VBox/ContentRow/SummaryPanel/SummaryMargin/SummaryVBox/RespawnOverviewLabel") as Label

	var terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", _map_file_path)
	var map_name: String = _map_file_path.get_file().get_basename()
	var grid_size := Vector2i.ZERO
	var tile_count: int = 0
	var marker_summary_text: String = "Markers: none"
	var marker_detail_text: String = "Markers\n\nNo mission markers stored in the selected map."
	if terrain_map_data != null:
		if terrain_map_data.has_method("get_map_name"):
			map_name = String(terrain_map_data.call("get_map_name"))
		if terrain_map_data.has_method("get_grid_size"):
			grid_size = terrain_map_data.call("get_grid_size")
		if terrain_map_data.has_method("get_tiles"):
			tile_count = int((terrain_map_data.call("get_tiles") as Array).size())
		marker_summary_text = _build_marker_summary_text(terrain_map_data)
		marker_detail_text = _build_marker_detail_text(terrain_map_data)

	var fireteams: Array = _fob_overview.get("fireteams", [])
	var pilot_count: int = int(_fob_overview.get("pilot_count", 0))
	var slot_usage_count: int = int(_fob_overview.get("slot_usage_count", _selected_unit_ids.size() + pilot_count))
	mission_header_label.text = ""
	map_name_label.text = "Map: %s" % map_name
	operator_count_label.text = "Operators: %d | Pilots: %d" % [_selected_unit_ids.size(), pilot_count]
	fireteam_count_label.text = "Slots: %d / %d | Fireteams: %d" % [mini(slot_usage_count, _mission_slot_count), _mission_slot_count, fireteams.size()]
	mission_summary_label.text = "%s | %s" % [_mission_name, String(_fob_overview.get("dropship_status", "Dropship awaiting transfer"))]
	map_capacity_label.text = "Mission slots %d | Dropship %d NPC + pilot" % [_mission_slot_count, DROPSHIP_NPC_CAPACITY]
	marker_list_label.text = marker_detail_text
	map_data_label.text = "File: %s\nGrid: %d x %d\nTiles: %d\n%s" % [_map_file_path, grid_size.x, grid_size.y, tile_count, marker_summary_text]
	map_help_label.text = "Diese Ansicht verwendet dieselbe Kartenbasis wie Mission und Editor. Sie zeigt Marker, Kartenstruktur und den aktuellen FOB-Vorbereitungsstand ohne einen zweiten MissionMap-Begriff einzufuehren."
	fireteam_overview_label.text = _build_fireteam_overview_text(fireteams)
	dropship_overview_label.text = "Dropship\n\n%s\n%s" % [
		String(_fob_overview.get("dropship_status", "Dropship: waiting for active fireteams")),
		String(_fob_overview.get("dropship_queue", "Boarding queue: no active fireteams")),
	]
	respawn_overview_label.text = _build_respawn_overview_text(fireteams)
	_refresh_mission_craft_card(Dictionary(_fob_overview.get("mission_craft", {})))
	_render_map_preview(terrain_map_data)


func _configure_compact_layout() -> void:
	var panel := get_node_or_null("Panel") as Control
	var content_row := get_node_or_null("Panel/Margin/VBox/ContentRow") as Control
	var mission_panel := get_node_or_null("Panel/Margin/VBox/MissionPanel") as Control
	var mission_summary_label := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionSummaryLabel") as Control
	if panel != null:
		panel.visible = false
	if content_row != null:
		content_row.visible = false
	if mission_panel != null:
		mission_panel.custom_minimum_size = Vector2(0.0, 120.0)
	if mission_summary_label != null:
		mission_summary_label.visible = false


func _ensure_mission_craft_card() -> PanelContainer:
	var card := get_node_or_null("MissionCraftCard") as PanelContainer
	if card != null:
		return card
	card = PanelContainer.new()
	card.name = "MissionCraftCard"
	card.visible = false
	card.custom_minimum_size = Vector2(320.0, 84.0)
	card.anchor_left = 1.0
	card.anchor_top = 0.0
	card.anchor_right = 1.0
	card.anchor_bottom = 0.0
	card.offset_left = -344.0
	card.offset_top = 144.0
	card.offset_right = -24.0
	card.offset_bottom = 228.0
	add_child(card)

	var margin := MarginContainer.new()
	margin.name = "CardMargin"
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	card.add_child(margin)

	var row := HBoxContainer.new()
	row.name = "CardRow"
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)

	var ship_texture := TextureRect.new()
	ship_texture.name = "ShipTexture"
	ship_texture.custom_minimum_size = Vector2(84.0, 44.0)
	ship_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ship_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(ship_texture)

	var text_vbox := VBoxContainer.new()
	text_vbox.name = "TextVBox"
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.add_theme_constant_override("separation", 2)
	row.add_child(text_vbox)

	var title_label := Label.new()
	title_label.name = "TitleLabel"
	title_label.add_theme_font_size_override("font_size", 10)
	text_vbox.add_child(title_label)

	var status_label := Label.new()
	status_label.name = "StatusLabel"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 9)
	text_vbox.add_child(status_label)

	var progress_bar := ProgressBar.new()
	progress_bar.name = "ProgressBar"
	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0
	progress_bar.custom_minimum_size = Vector2(0.0, 8.0)
	text_vbox.add_child(progress_bar)

	var pilot_vbox := VBoxContainer.new()
	pilot_vbox.name = "PilotVBox"
	pilot_vbox.custom_minimum_size = Vector2(56.0, 0.0)
	pilot_vbox.add_theme_constant_override("separation", 2)
	row.add_child(pilot_vbox)

	var pilot_texture := TextureRect.new()
	pilot_texture.name = "PilotTexture"
	pilot_texture.custom_minimum_size = Vector2(42.0, 42.0)
	pilot_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pilot_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pilot_vbox.add_child(pilot_texture)

	var passenger_label := Label.new()
	passenger_label.name = "PassengerLabel"
	passenger_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	passenger_label.add_theme_font_size_override("font_size", 8)
	pilot_vbox.add_child(passenger_label)
	return card


func _refresh_mission_craft_card(mission_craft: Dictionary) -> void:
	var card := _ensure_mission_craft_card()
	if card == null:
		return
	var show_card: bool = not mission_craft.is_empty()
	card.visible = show_card
	if not show_card:
		return
	var ship_texture := card.get_node_or_null("CardMargin/CardRow/ShipTexture") as TextureRect
	var title_label := card.get_node_or_null("CardMargin/CardRow/TextVBox/TitleLabel") as Label
	var status_label := card.get_node_or_null("CardMargin/CardRow/TextVBox/StatusLabel") as Label
	var progress_bar := card.get_node_or_null("CardMargin/CardRow/TextVBox/ProgressBar") as ProgressBar
	var pilot_texture := card.get_node_or_null("CardMargin/CardRow/PilotVBox/PilotTexture") as TextureRect
	var passenger_label := card.get_node_or_null("CardMargin/CardRow/PilotVBox/PassengerLabel") as Label
	var is_transit: bool = bool(mission_craft.get("mission_transit_to_map", false)) or bool(mission_craft.get("mission_transit_to_fob", false))
	var card_alpha: float = 0.56 if is_transit else 0.74
	card.modulate = Color(1.0, 1.0, 1.0, card_alpha)
	if ship_texture != null:
		ship_texture.texture = _load_texture(String(mission_craft.get("texture_path", "")).strip_edges())
	if title_label != null:
		title_label.text = String(mission_craft.get("display_name", "Dropship")).strip_edges()
	if status_label != null:
		status_label.text = _build_mission_craft_status_text(mission_craft)
	if progress_bar != null:
		progress_bar.visible = is_transit
		progress_bar.value = clampf(float(mission_craft.get("transfer_progress", 0.0)), 0.0, 100.0)
	if pilot_texture != null:
		pilot_texture.texture = _load_texture(String(mission_craft.get("pilot_portrait_path", "")).strip_edges())
	if passenger_label != null:
		passenger_label.text = "%d pax" % maxi(int(mission_craft.get("passenger_count", 0)), 0)


func _build_mission_craft_status_text(mission_craft: Dictionary) -> String:
	var pilot_name: String = String(mission_craft.get("pilot_display_name", "")).strip_edges()
	var pilot_text: String = pilot_name if not pilot_name.is_empty() else "unassigned"
	if bool(mission_craft.get("mission_transit_to_map", false)):
		return "Pilot %s | En route to mission map | ETA %ds" % [pilot_text, maxi(int(mission_craft.get("transfer_eta_seconds", 0)), 0)]
	if bool(mission_craft.get("mission_transit_to_fob", false)):
		return "Pilot %s | Returning to FOB | ETA %ds" % [pilot_text, maxi(int(mission_craft.get("transfer_eta_seconds", 0)), 0)]
	return "Pilot %s | Holding on mission map" % pilot_text


func _load_texture(resource_path: String) -> Texture2D:
	if resource_path.is_empty():
		return null
	var resource: Resource = load(resource_path)
	return resource as Texture2D


func _build_fireteam_overview_text(fireteams: Array) -> String:
	if fireteams.is_empty():
		return "Fireteams\n\nNo FOB fireteams prepared yet."

	var lines: PackedStringArray = ["Fireteams", ""]
	for fireteam_variant in fireteams:
		if typeof(fireteam_variant) != TYPE_DICTIONARY:
			continue
		var fireteam: Dictionary = fireteam_variant
		var member_names: PackedStringArray = fireteam.get("member_names", PackedStringArray())
		lines.append("%s: %s | %s" % [
			"%s (Lead %s)" % [String(fireteam.get("label", "FT")), String(fireteam.get("lead_name", "none"))],
			"none" if member_names.is_empty() else ", ".join(member_names),
			String(fireteam.get("loadout", "medium")).to_upper(),
		])
	return "\n".join(lines)


func _build_marker_summary_text(terrain_map_data) -> String:
	if terrain_map_data == null or not terrain_map_data.has_method("get_markers"):
		return "Markers: none"

	var markers: Dictionary = terrain_map_data.call("get_markers")
	if markers.is_empty():
		return "Markers: none"

	var ordered_marker_ids: PackedStringArray = []
	for marker_id_variant in markers.keys():
		ordered_marker_ids.append(String(marker_id_variant))
	ordered_marker_ids.sort()

	var marker_parts: PackedStringArray = []
	for marker_id in ordered_marker_ids:
		var marker_position: Vector2 = terrain_map_data.call("get_marker_position", marker_id, Vector2.ZERO)
		marker_parts.append("%s %d,%d" % [marker_id, int(round(marker_position.x)), int(round(marker_position.y))])

	return "Markers: %s" % " | ".join(marker_parts)


func _build_marker_detail_text(terrain_map_data) -> String:
	if terrain_map_data == null or not terrain_map_data.has_method("get_markers"):
		return "Markers\n\nNo mission markers stored in the selected map."

	var markers: Dictionary = terrain_map_data.call("get_markers")
	if markers.is_empty():
		return "Markers\n\nNo mission markers stored in the selected map."

	var ordered_marker_ids: PackedStringArray = []
	for marker_id_variant in markers.keys():
		ordered_marker_ids.append(String(marker_id_variant))
	ordered_marker_ids.sort()

	var lines: PackedStringArray = ["Markers", ""]
	for marker_id in ordered_marker_ids:
		var marker_position: Vector2 = terrain_map_data.call("get_marker_position", marker_id, Vector2.ZERO)
		lines.append("%s -> x %d | y %d" % [marker_id, int(round(marker_position.x)), int(round(marker_position.y))])
	return "\n".join(lines)


func _build_respawn_overview_text(fireteams: Array) -> String:
	if fireteams.is_empty():
		return "Respawn + Loadout\n\nNo focused FOB staging available."

	var lines: PackedStringArray = ["Respawn + Loadout", ""]
	for fireteam_variant in fireteams:
		if typeof(fireteam_variant) != TYPE_DICTIONARY:
			continue
		var fireteam: Dictionary = fireteam_variant
		lines.append("%s: Respawn %s | Loadout %s" % [
			String(fireteam.get("label", "FT")),
			"FOB" if bool(fireteam.get("respawn_enabled", false)) else "off",
			String(fireteam.get("loadout", "medium")).to_upper(),
		])
	return "\n".join(lines)


func _render_map_preview(terrain_map_data) -> void:
	var preview_clip := get_node("Panel/Margin/VBox/ContentRow/MapPanel/MapMargin/MapVBox/MapPreviewFrame/MapPreviewMargin/MapPreviewClip") as Control
	var preview_root := get_node("Panel/Margin/VBox/ContentRow/MapPanel/MapMargin/MapVBox/MapPreviewFrame/MapPreviewMargin/MapPreviewClip/MapPreviewRoot") as Node2D
	if preview_clip == null or preview_root == null:
		return

	preview_root.position = Vector2.ZERO
	preview_root.scale = Vector2.ONE
	if preview_clip.size.x <= 8.0 or preview_clip.size.y <= 8.0:
		return

	if terrain_map_data == null:
		_clear_map_preview(preview_root)
		return

	if _terrain_renderer == null:
		_terrain_renderer = TERRAIN_MAP_RENDERER_SCRIPT.new()

	var render_result: Dictionary = _terrain_renderer.render_map(terrain_map_data, preview_root)
	var bounds: Rect2 = _build_map_preview_bounds(render_result)
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		return

	var available_size: Vector2 = preview_clip.size - Vector2(24.0, 24.0)
	var preview_scale: float = clampf(minf(available_size.x / bounds.size.x, available_size.y / bounds.size.y), 0.08, 1.0)
	preview_root.scale = Vector2(preview_scale, preview_scale)
	var scaled_size: Vector2 = Vector2(bounds.size.x * preview_scale, bounds.size.y * preview_scale)
	preview_root.position = Vector2(
		(preview_clip.size.x - scaled_size.x) * 0.5 - bounds.position.x * preview_scale,
		(preview_clip.size.y - scaled_size.y) * 0.5 - bounds.position.y * preview_scale
	)


func _build_map_preview_bounds(render_result: Dictionary) -> Rect2:
	var bounds_state: Dictionary = {
		"min": Vector2(INF, INF),
		"max": Vector2(-INF, -INF),
	}
	for bucket_key in ["tiles", "cliffs", "walls"]:
		var bucket_variant = render_result.get(bucket_key, {})
		if typeof(bucket_variant) != TYPE_DICTIONARY:
			continue
		for item_variant in (bucket_variant as Dictionary).values():
			_register_preview_bounds(bounds_state, item_variant)

	var min_point: Vector2 = bounds_state.get("min", Vector2.ZERO)
	var max_point: Vector2 = bounds_state.get("max", Vector2.ZERO)
	if min_point.x == INF or min_point.y == INF:
		return Rect2(Vector2.ZERO, Vector2.ZERO)
	return Rect2(min_point, max_point - min_point)


func _register_preview_bounds(bounds_state: Dictionary, item_variant) -> void:
	if item_variant is Array:
		for nested_variant in item_variant:
			_register_preview_bounds(bounds_state, nested_variant)
		return

	var canvas_item := item_variant as CanvasItem
	if canvas_item == null:
		return

	var item_position: Vector2 = canvas_item.position
	var item_size := Vector2(64.0, 32.0)
	if canvas_item is Sprite2D:
		var sprite := canvas_item as Sprite2D
		if sprite.texture != null:
			item_size = sprite.texture.get_size() * sprite.scale.abs()
	elif canvas_item is Control:
		item_size = (canvas_item as Control).size

	var min_point: Vector2 = bounds_state.get("min", Vector2(INF, INF))
	var max_point: Vector2 = bounds_state.get("max", Vector2(-INF, -INF))
	bounds_state["min"] = Vector2(min(min_point.x, item_position.x), min(min_point.y, item_position.y))
	bounds_state["max"] = Vector2(max(max_point.x, item_position.x + item_size.x), max(max_point.y, item_position.y + item_size.y))


func _clear_map_preview(preview_root: Node) -> void:
	for child in preview_root.get_children():
		child.queue_free()


func _on_map_preview_clip_resized() -> void:
	if not is_inside_tree():
		return
	call_deferred("_render")
