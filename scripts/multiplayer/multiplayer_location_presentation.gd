extends RefCounted
## Local presentation suspension, following MetaLayerFlow's existing owner APIs.
## Never disables mission/SimulationRoot/Controller gameplay processing.
var _mission: WeakRef
var _suspended := false
var _saved: Dictionary = {}
var _controller_ui := true

func configure(mission: Node) -> void:
	_mission = weakref(mission)
	_watch_children(mission)

func set_active(active: bool) -> void:
	var mission: Node = _mission.get_ref() if _mission != null else null
	if mission == null or active == (not _suspended): return
	_suspended = not active
	var controller: Node = mission.get_node_or_null("TacticalController")
	if not active:
		if controller != null:
			_controller_ui = bool(controller.get("_tactical_ui_visible"))
			controller.call("set_tactical_ui_visible", false)
		_suspend_branch(mission)
	else:
		for record: Dictionary in _saved.values():
			var node: Node = record.node.get_ref()
			if node == null: continue
			node.set_process_input(record.input[0])
			node.set_process_unhandled_input(record.input[1])
			node.set_process_unhandled_key_input(record.input[2])
			node.set_process_shortcut_input(record.input[3])
			if record.has("visible"): node.set("visible", record.visible)
			if record.has("process_mode"): node.process_mode = record.process_mode
			if record.has("camera_enabled"): node.set("enabled", record.camera_enabled)
			if node is SubViewport:
				node.gui_disable_input = record.gui_disabled
				node.render_target_update_mode = record.update_mode
		_saved.clear()
		if controller != null: controller.call("set_tactical_ui_visible", _controller_ui)
		var view: Node = mission.get_node_or_null("Primary3DView")
		if view != null and view.has_method("_request_viewport_redraw"): view.call("_request_viewport_redraw", true)

func _suspend_branch(branch: Node) -> void:
	var pending: Array[Node] = [branch]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		var id: int = node.get_instance_id()
		if not _saved.has(id):
			var record: Dictionary = {"node":weakref(node), "input":[node.is_processing_input(), node.is_processing_unhandled_input(), node.is_processing_unhandled_key_input(), node.is_processing_shortcut_input()]}
			if node is CanvasLayer or node == _mission.get_ref(): record.visible = node.get("visible")
			if node.name == "Primary3DView" or node.name == "MissionCamera": record.process_mode = node.process_mode
			if node is Camera2D: record.camera_enabled = node.enabled
			if node is SubViewport:
				record.update_mode = node.render_target_update_mode
				record.gui_disabled = node.gui_disable_input
			_saved[id] = record
			node.set_process_input(false)
			node.set_process_unhandled_input(false)
			node.set_process_unhandled_key_input(false)
			node.set_process_shortcut_input(false)
			if record.has("visible"): node.set("visible", false)
			if record.has("process_mode"): node.process_mode = Node.PROCESS_MODE_DISABLED
			if node is Camera2D: node.enabled = false
			if node is SubViewport:
				node.gui_disable_input = true
				node.render_target_update_mode = SubViewport.UPDATE_DISABLED
			if node.has_method("cancel_modal_input"): node.call("cancel_modal_input")
		if node is CanvasLayer: _watch_children(node)
		pending.append_array(node.get_children())

func _watch_children(node: Node) -> void:
	if not node.child_entered_tree.is_connected(_on_child_entered): node.child_entered_tree.connect(_on_child_entered)

func _on_child_entered(child: Node) -> void:
	# MissionSetup adds Primary3DView deferred; wait for its normal ready/configure.
	_suspend_late_branch.call_deferred(weakref(child))

func _suspend_late_branch(reference: WeakRef) -> void:
	var node: Node = reference.get_ref()
	if _suspended and node != null: _suspend_branch(node)
