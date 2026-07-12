class_name PlayabilityTestHarness
extends RefCounted

const VALID_COVERAGE_STATUSES: Array[String] = [
	"automated",
	"manual",
	"blocked",
	"not_applicable",
]


static func instantiate_scene(scene_path: String, parent: Node) -> Node:
	if scene_path.strip_edges().is_empty() or parent == null:
		return null
	if not ResourceLoader.exists(scene_path):
		return null
	var packed_scene := ResourceLoader.load(scene_path) as PackedScene
	if packed_scene == null:
		return null
	var node := packed_scene.instantiate()
	parent.add_child(node)
	return node


static func collect_buttons(root: Node, include_hidden: bool = true) -> Array:
	var buttons: Array = []
	_collect_buttons_recursive(root, include_hidden, buttons)
	return buttons


static func find_buttons(root: Node, query: Dictionary) -> Array:
	var matches: Array = []
	for button_variant in collect_buttons(root, true):
		var button := button_variant as BaseButton
		if button == null:
			continue
		if _button_matches_query(button, query):
			matches.append(button)
	return matches


static func find_button(root: Node, query: Dictionary) -> BaseButton:
	var matches: Array = find_buttons(root, query)
	return matches[0] as BaseButton if not matches.is_empty() else null


static func describe_button(root: Node, button: BaseButton) -> Dictionary:
	if button == null:
		return {
			"exists": false,
			"visible": false,
			"enabled": false,
			"has_pressed_callback": false,
		}
	return {
		"exists": true,
		"name": button.name,
		"path": _relative_path(root, button),
		"text": button.text,
		"visible": _is_control_visible(button),
		"enabled": not button.disabled,
		"disabled": button.disabled,
		"has_pressed_callback": has_pressed_callback(button),
		"action_id": String(button.get_meta("action_id", "")),
		"route": String(button.get_meta("route", "")),
		"icon_id": String(button.get_meta("icon_id", button.get_meta("icon", ""))),
	}


static func has_pressed_callback(button: BaseButton) -> bool:
	return button != null and button.pressed.get_connections().size() > 0


static func has_signal_connection(control: Object, signal_name: String) -> bool:
	if control == null or signal_name.strip_edges().is_empty():
		return false
	match signal_name:
		"pressed":
			return control is BaseButton and (control as BaseButton).pressed.get_connections().size() > 0
		"toggled":
			return control is BaseButton and (control as BaseButton).toggled.get_connections().size() > 0
		"item_selected":
			return control is OptionButton and (control as OptionButton).item_selected.get_connections().size() > 0
		"value_changed":
			return control is Range and (control as Range).value_changed.get_connections().size() > 0
		"text_changed":
			return control is LineEdit and (control as LineEdit).text_changed.get_connections().size() > 0
		"text_submitted":
			return control is LineEdit and (control as LineEdit).text_submitted.get_connections().size() > 0
		_:
			return control.get_signal_connection_list(StringName(signal_name)).size() > 0


static func describe_control(root: Node, control: Control, signal_names: Array = []) -> Dictionary:
	if control == null:
		return {
			"exists": false,
			"visible": false,
			"enabled": false,
			"inside_viewport": false,
			"fully_covered": false,
			"signals": {},
		}
	var signal_snapshot: Dictionary = {}
	for signal_name_variant in signal_names:
		var signal_name: String = String(signal_name_variant)
		signal_snapshot[signal_name] = has_signal_connection(control, signal_name)
	return {
		"exists": true,
		"name": control.name,
		"path": _relative_path(root, control),
		"visible": _is_control_visible(control),
		"enabled": not bool(control.get("disabled")) if _has_property(control, "disabled") else true,
		"inside_viewport": is_control_inside_viewport(control, control.get_viewport_rect().size if control.is_inside_tree() else Vector2.ZERO),
		"fully_covered": is_control_fully_covered_by_later_control(root, control),
		"signals": signal_snapshot,
	}


static func press_button_for_test(button: BaseButton) -> Dictionary:
	if button == null:
		return {"pressed": false, "reason": "missing_button"}
	if button.disabled:
		return {"pressed": false, "reason": "disabled"}
	if not _is_control_visible(button):
		return {"pressed": false, "reason": "hidden"}
	button.pressed.emit()
	return {"pressed": true, "reason": "ok"}


static func is_control_inside_rect(control: Control, rect: Rect2, tolerance: float = 0.5) -> bool:
	if control == null:
		return false
	var control_rect := Rect2(control.global_position, control.size)
	var expanded := rect.grow(tolerance)
	return expanded.encloses(control_rect)


static func is_control_inside_viewport(control: Control, viewport_size: Vector2, tolerance: float = 0.5) -> bool:
	return is_control_inside_rect(control, Rect2(Vector2.ZERO, viewport_size), tolerance)


static func is_control_reachable_in_viewport(control: Control, viewport_size: Vector2, tolerance: float = 0.5) -> bool:
	if is_control_inside_viewport(control, viewport_size, tolerance):
		return true
	if control == null or not control.is_inside_tree():
		return false
	var viewport_rect := Rect2(Vector2.ZERO, viewport_size).grow(tolerance)
	var control_rect := control.get_global_rect()
	var ancestor := control.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer:
			var scroll := ancestor as ScrollContainer
			if not scroll.is_visible_in_tree() or not viewport_rect.intersects(scroll.get_global_rect(), true):
				return false
			var scroll_rect := scroll.get_global_rect().grow(tolerance)
			var horizontal_reachable := scroll_rect.position.x <= control_rect.position.x and scroll_rect.end.x >= control_rect.end.x
			var vertical_reachable := scroll_rect.position.y <= control_rect.position.y and scroll_rect.end.y >= control_rect.end.y
			if not horizontal_reachable:
				horizontal_reachable = scroll.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED
			if not vertical_reachable:
				vertical_reachable = scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED
			return horizontal_reachable and vertical_reachable
		ancestor = ancestor.get_parent()
	return false


static func fixed_rect_matches(control: Control, expected: Rect2, tolerance: float = 0.5) -> bool:
	if control == null:
		return false
	return absf(control.global_position.x - expected.position.x) <= tolerance \
		and absf(control.global_position.y - expected.position.y) <= tolerance \
		and absf(control.size.x - expected.size.x) <= tolerance \
		and absf(control.size.y - expected.size.y) <= tolerance


static func collect_scroll_containers(root: Node) -> Array:
	var containers: Array = []
	_collect_scroll_containers_recursive(root, containers)
	return containers


static func has_scroll_container(root: Node) -> bool:
	return not collect_scroll_containers(root).is_empty()


static func collect_clipped_controls(root: Node, viewport_size: Vector2, include_hidden: bool = false) -> Array:
	var clipped: Array = []
	_collect_clipped_controls_recursive(root, Rect2(Vector2.ZERO, viewport_size), include_hidden, clipped)
	return clipped


static func is_control_fully_covered_by_later_control(root: Node, control: Control) -> bool:
	if root == null or control == null or not _is_control_visible(control):
		return false
	var controls: Array = []
	_collect_controls_recursive(root, controls)
	var seen_target: bool = false
	var control_rect := Rect2(control.global_position, control.size)
	for candidate_variant in controls:
		var candidate := candidate_variant as Control
		if candidate == null:
			continue
		if candidate == control:
			seen_target = true
			continue
		if not seen_target:
			continue
		if candidate.is_ancestor_of(control) or control.is_ancestor_of(candidate):
			continue
		if not _is_control_visible(candidate) or candidate.mouse_filter == Control.MOUSE_FILTER_IGNORE:
			continue
		if Rect2(candidate.global_position, candidate.size).encloses(control_rect):
			return true
	return false


static func build_screen_report(screen_id: String, failures: Array, warnings: Array = [], manual_items: Array = []) -> Dictionary:
	return {
		"screen_id": screen_id,
		"status": "failed" if not failures.is_empty() else "passed",
		"failure_count": failures.size(),
		"warning_count": warnings.size(),
		"manual_item_count": manual_items.size(),
		"failures": failures.duplicate(true),
		"warnings": warnings.duplicate(true),
		"manual_items": manual_items.duplicate(true),
	}


static func coverage_status_is_valid(status: String) -> bool:
	return VALID_COVERAGE_STATUSES.has(status.strip_edges())


static func _collect_buttons_recursive(node: Node, include_hidden: bool, buttons: Array) -> void:
	if node == null:
		return
	if node is BaseButton:
		var button := node as BaseButton
		if include_hidden or _is_control_visible(button):
			buttons.append(button)
	for child in node.get_children():
		_collect_buttons_recursive(child, include_hidden, buttons)


static func _collect_scroll_containers_recursive(node: Node, containers: Array) -> void:
	if node == null:
		return
	if node is ScrollContainer:
		containers.append(node)
	for child in node.get_children():
		_collect_scroll_containers_recursive(child, containers)


static func _collect_controls_recursive(node: Node, controls: Array) -> void:
	if node == null:
		return
	if node is Control:
		controls.append(node)
	for child in node.get_children():
		_collect_controls_recursive(child, controls)


static func _collect_clipped_controls_recursive(node: Node, viewport_rect: Rect2, include_hidden: bool, clipped: Array) -> void:
	if node == null:
		return
	if node is Control:
		var control := node as Control
		if (include_hidden or _is_control_visible(control)) and not is_control_inside_rect(control, viewport_rect):
			clipped.append({
				"name": control.name,
				"path": _relative_path(node.get_tree().root if node.is_inside_tree() else node, control),
				"rect": Rect2(control.global_position, control.size),
			})
	for child in node.get_children():
		_collect_clipped_controls_recursive(child, viewport_rect, include_hidden, clipped)


static func _button_matches_query(button: BaseButton, query: Dictionary) -> bool:
	var node_name: String = String(query.get("name", "")).strip_edges()
	if not node_name.is_empty() and button.name != node_name:
		return false
	var text: String = String(query.get("text", "")).strip_edges()
	if not text.is_empty() and button.text != text:
		return false
	var text_contains: String = String(query.get("text_contains", "")).strip_edges().to_lower()
	if not text_contains.is_empty() and not button.text.to_lower().contains(text_contains):
		return false
	for meta_key in ["action_id", "route", "icon_id", "icon", "roster_action"]:
		if not query.has(meta_key):
			continue
		var expected: String = String(query.get(meta_key, "")).strip_edges()
		var actual: String = String(button.get_meta(meta_key, "")).strip_edges()
		if actual != expected:
			return false
	return true


static func _is_control_visible(control: Control) -> bool:
	if control == null or not control.visible:
		return false
	return control.is_visible_in_tree() if control.is_inside_tree() else true


static func _has_property(object: Object, property_name: String) -> bool:
	if object == null:
		return false
	for property in object.get_property_list():
		if String(Dictionary(property).get("name", "")) == property_name:
			return true
	return false


static func _relative_path(root: Node, node: Node) -> String:
	if root == null or node == null:
		return ""
	if root == node:
		return "."
	if root.is_ancestor_of(node):
		return String(root.get_path_to(node))
	return String(node.get_path())
