extends SceneTree
## Playtest 14.11.2026, L04: every visible button of the homebase operations UI must
## receive the pointer across its whole visible surface at each target resolution.
## Reports which control intercepts the pointer instead, so the real cause is fixed.
const RESOLUTIONS: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(3440, 1440)]
const SAMPLE_UV: Array[Vector2] = [Vector2(0.08, 0.15), Vector2(0.92, 0.15), Vector2(0.08, 0.85), Vector2(0.92, 0.85), Vector2(0.5, 0.5)]
const MIN_HIT_SIZE := 28.0

var checks := 0
var failed := 0
var _failures: Dictionary = {}
var _small: Dictionary = {}
var _presenter: Node
var _overlay: Node


func _initialize() -> void:
	call_deferred("run")


func _collect(node: Node, out: Array[BaseButton]) -> void:
	for child: Node in node.get_children():
		if child is Viewport:
			continue
		if child is CanvasItem and not (child as CanvasItem).visible:
			continue
		if child is CanvasLayer and not (child as CanvasLayer).visible:
			continue
		if child is BaseButton and (child as BaseButton).mouse_filter != Control.MOUSE_FILTER_IGNORE:
			out.append(child as BaseButton)
		_collect(child, out)


func _visible_rect(control: Control) -> Rect2:
	var rect: Rect2 = control.get_global_rect().intersection(root.get_visible_rect())
	var parent: Node = control.get_parent()
	while parent != null and parent != root:
		if parent is Control and ((parent as Control).clip_contents or parent is ScrollContainer):
			rect = rect.intersection((parent as Control).get_global_rect())
		parent = parent.get_parent()
	return rect


func _is_modal(hit: Control) -> bool:
	var node: Node = hit
	while node != null and node != root:
		if node == _overlay or String(node.name) in ["BaseFlyoutBackdrop", "CharacterSheetPopup"]:
			return true
		node = node.get_parent()
	return false


func _short(node: Node) -> String:
	if node == null:
		return "nothing"
	var path := String(root.get_path_to(node))
	var parts := path.split("/")
	return "/".join(parts.slice(maxi(0, parts.size() - 4)))


func _audit(label: String) -> void:
	# The open side window is a deliberate overlay, like its backdrop.
	_overlay = _presenter.call("_workspace_flyout_panel") if bool(_presenter.call("is_workspace_flyout_open")) else null
	var buttons: Array[BaseButton] = []
	_collect(root, buttons)
	var tested := 0
	var before := failed
	for button: BaseButton in buttons:
		if not is_instance_valid(button) or not button.is_visible_in_tree():
			continue
		var rect := _visible_rect(button)
		if rect.size.x < 8.0 or rect.size.y < 8.0:
			continue
		var button_name := _short(button)
		if rect.size.x < MIN_HIT_SIZE or rect.size.y < MIN_HIT_SIZE:
			_small["%s | %s" % [label, button_name]] = rect.size
		tested += 1
		var blocked: PackedStringArray = PackedStringArray()
		var blocker := ""
		for uv: Vector2 in SAMPLE_UV:
			var point := rect.position + rect.size * uv
			var motion := InputEventMouseMotion.new()
			motion.position = point
			motion.global_position = point
			root.push_input(motion, true)
			await process_frame
			if not is_instance_valid(button) or not button.is_visible_in_tree():
				break
			checks += 1
			var hit: Control = root.gui_get_hovered_control()
			if hit == button or (hit != null and button.is_ancestor_of(hit)):
				continue
			if _is_modal(hit):
				# A deliberately modal layer (flyout backdrop, character sheet) may cover the rest.
				continue
			failed += 1
			blocked.append(str(uv))
			blocker = _short(hit)
		if not blocked.is_empty():
			var kind := "COVERED" if blocked.size() == SAMPLE_UV.size() else "PARTIAL"
			var text := (button as Button).text.replace("\n", " ") if button is Button else ""
			_failures["%s | %s \"%s\"" % [label, button_name, text]] = "%s by %s at %s" % [kind, blocker, ", ".join(blocked)]
	print("AUDIT %s: buttons=%d new_failures=%d" % [label, tested, failed - before])


func run() -> void:
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	load("res://scripts/meta/game_start_contract.gd").request_start(self, "campaign", "new")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	current_scene = flow
	for i in 24:
		await process_frame
	var screen: Node = flow.get_node("HomebaseScreen")
	var presenter: Node = screen.get("_operations_presenter")
	_presenter = presenter
	var board: Node = presenter.get("_job_board")
	for resolution: Vector2i in RESOLUTIONS:
		root.size = resolution
		root.content_scale_size = resolution
		var tag := "%dx%d" % [resolution.x, resolution.y]
		for mode: String in ["base", "personnel", "squad", "mission", "jobs"]:
			presenter.call("_navigate_from_sidebar", mode)
			await create_timer(0.4).timeout
			await _audit("%s %s" % [tag, mode])
		if not bool(board.get("_details_expanded")):
			board.call("_toggle_job_details", "satellite_recovery")
		await create_timer(0.4).timeout
		await _audit("%s jobs+details" % tag)
		for section: String in ["inventory", "ship"]:
			presenter.call("_open_base_management", section)
			await create_timer(0.4).timeout
			await _audit("%s flyout:%s" % [tag, section])
		presenter.call("_navigate_from_sidebar", "squad")
		await create_timer(0.3).timeout
		var unit: String = String(screen.call("get_operations_snapshot").focused_unit.id)
		screen.call("request_operation", "details", {"unit_id": unit})
		await create_timer(0.3).timeout
		await _audit("%s details-popup" % tag)
		screen.call("_on_close_sheet_button_pressed")
		await create_timer(0.2).timeout
	for key: String in _failures:
		printerr("FAIL: %s -> %s" % [key, _failures[key]])
	for key: String in _small:
		print("SMALL: %s size=%s" % [key, _small[key]])
	flow.queue_free()
	current_scene = null
	for i in 4:
		await process_frame
	print("HIT_AREA_AUDIT checks=%d failed=%d blocked_buttons=%d small_buttons=%d" % [checks, failed, _failures.size(), _small.size()])
	quit(1 if failed else 0)
