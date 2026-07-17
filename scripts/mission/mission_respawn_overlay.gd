extends VBoxContainer

@export var respawn_manager_path: NodePath


func _ready() -> void:
	add_theme_constant_override("separation", 4)
	_refresh()


func _process(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	var respawn_manager = get_node_or_null(respawn_manager_path)
	if respawn_manager == null or not respawn_manager.has_method("get_pending_respawns"):
		visible = false
		_clear_labels()
		return

	var pending_respawns: Dictionary = respawn_manager.call("get_pending_respawns")
	if pending_respawns.is_empty():
		visible = false
		_clear_labels()
		return

	var unit_ids: Array = pending_respawns.keys()
	unit_ids.sort()
	visible = true

	var index: int = 0
	for unit_id_variant in unit_ids:
		var unit_id: String = String(unit_id_variant)
		var remaining_seconds: int = maxi(int(ceili(float(pending_respawns.get(unit_id, 0.0)))), 0)
		var label: Label = _get_or_create_label(index)
		label.text = "[%s] RESPAWN in %ds" % [unit_id.to_upper(), remaining_seconds]
		label.modulate = Color(0.78, 0.94, 1.0, 1.0)
		index += 1

	_trim_labels(index)


func _get_or_create_label(index: int) -> Label:
	if index < get_child_count():
		return get_child(index) as Label

	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
	add_child(label)
	return label


func _trim_labels(visible_count: int) -> void:
	for index in range(get_child_count() - 1, visible_count - 1, -1):
		var child: Node = get_child(index)
		remove_child(child)
		child.queue_free()


func _clear_labels() -> void:
	_trim_labels(0)
