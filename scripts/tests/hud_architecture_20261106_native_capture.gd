extends "res://scripts/tests/playtest_20261105_motion_order_capture.gd"
## Same native route, with a read-only audit of camera actions and camera changes.
## Does not handle events, reset the camera, or change simulation/render settings.

class CameraInputAudit extends Node:
	const CAMERA_ACTIONS: Array[StringName] = [
		&"tactical_camera_pan_up", &"tactical_camera_pan_down",
		&"tactical_camera_pan_left", &"tactical_camera_pan_right",
		&"tactical_camera_rotate_left", &"tactical_camera_rotate_right",
		&"tactical_camera_rotate_drag", &"tactical_camera_zoom_in",
		&"tactical_camera_zoom_out",
	]
	var events: Array = []
	var started_usec := 0
	func _input(event: InputEvent) -> void:
		if not (event is InputEventMouseButton or event is InputEventKey or event is InputEventAction):
			return
		for action in CAMERA_ACTIONS:
			if event.is_action_pressed(action) or event.is_action_released(action):
				if events.size() < 512:
					events.append({"audit_elapsed_usec": Time.get_ticks_usec() - started_usec, "action": String(action), "pressed": event.is_action_pressed(action), "frame": Engine.get_process_frames()})
		# Deliberately no set_input_as_handled and no raw key/text recording.

var _camera_audit_active := false
var _camera_audit_samples: Array = []


func _profile_normal_movement(view: Node) -> void:
	var audit := CameraInputAudit.new()
	audit.started_usec = Time.get_ticks_usec()
	root.add_child(audit)
	_camera_audit_active = true
	_camera_audit_samples.clear()
	call_deferred("_collect_camera_audit", view, audit.started_usec)
	await super._profile_normal_movement(view)
	_camera_audit_active = false
	var evidence := {"schema": "sternenbuergerchen.hud_camera_input_audit.v1", "read_only": true, "handles_input": false, "changes_camera": false, "changes_simulation": false, "sample_interval_usec": 250000, "input_actions": audit.events.duplicate(true), "camera_changes": _camera_audit_samples.duplicate(true)}
	audit.queue_free()
	var path := _output.get_basename() + "_camera_audit.json"
	if not _check(not FileAccess.file_exists(path), "Camera audit evidence target is new"):
		return
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not _check(file != null, "Read-only camera audit evidence opens"):
		return
	file.store_string(JSON.stringify(evidence))
	file.close()
	print("HUD_CAMERA_AUDIT_DONE ", path)


func _collect_camera_audit(view: Node, started_usec: int) -> void:
	var last_sample_usec := 0
	var last_camera: Dictionary = {}
	while _camera_audit_active and is_instance_valid(view):
		await process_frame
		if not _camera_audit_active or not is_instance_valid(view):
			break
		var now_usec := Time.get_ticks_usec()
		if now_usec - last_sample_usec < 250000:
			continue
		last_sample_usec = now_usec
		var camera := _camera_facts(view)
		if camera != last_camera:
			_camera_audit_samples.append({"audit_elapsed_usec": now_usec - started_usec, "profile_elapsed_usec": now_usec - _profile_start_usec if _profile_start_usec > 0 else -1, "camera": camera})
			last_camera = camera
