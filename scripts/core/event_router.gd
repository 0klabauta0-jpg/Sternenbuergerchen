class_name EventRouter
extends Node

signal squad_command(squad, order)
signal unit_down(unit)
signal threat_detected(source, threat_data)
signal leader_changed(squad, leader)
signal flank_initiated(fireteam_id, leader, flank_data)
signal respawn_requested(unit, respawn_target)
signal suppression_changed(fireteam_id, suppression_data)
signal return_to_plan_requested(fireteam_id, reason)
signal fireteam_coordination_requested(coordination_data)
signal fireteam_ready_to_advance(fireteam_id, coordination_id)
signal leader_initiated_flank(fireteam_id, leader, flank_data)


# The router only validates lightweight contracts and forwards signals.
func route_squad_command(squad: Node, order: Dictionary) -> void:
	if squad == null:
		push_warning("EventRouter.route_squad_command expects a squad Node.")
		return

	squad_command.emit(squad, order)


func notify_unit_down(unit: Node) -> void:
	if unit == null:
		push_warning("EventRouter.notify_unit_down expects a unit Node.")
		return

	unit_down.emit(unit)


func notify_threat_detected(source: Node, threat_data: Dictionary) -> void:
	if source == null:
		push_warning("EventRouter.notify_threat_detected expects a source Node.")
		return

	threat_detected.emit(source, threat_data)


func notify_leader_changed(squad: Node, leader: Node) -> void:
	if squad == null:
		push_warning("EventRouter.notify_leader_changed expects a squad Node.")
		return

	if leader == null:
		push_warning("EventRouter.notify_leader_changed expects a leader Node.")
		return

	leader_changed.emit(squad, leader)


func notify_flank_initiated(fireteam_id: String, leader: Node, flank_data: Dictionary) -> void:
	if fireteam_id.strip_edges().is_empty():
		push_warning("EventRouter.notify_flank_initiated expects a non-empty fireteam_id.")
		return

	if leader == null:
		push_warning("EventRouter.notify_flank_initiated expects a leader Node.")
		return

	flank_initiated.emit(fireteam_id.strip_edges().to_lower(), leader, flank_data.duplicate(true))


func request_respawn(unit: Node, respawn_target: String) -> void:
	if unit == null:
		push_warning("EventRouter.request_respawn expects a unit Node.")
		return

	if respawn_target.is_empty():
		push_warning("EventRouter.request_respawn expects a non-empty respawn target.")
		return

	respawn_requested.emit(unit, respawn_target)


func notify_suppression_changed(fireteam_id: String, suppression_data: Dictionary) -> void:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		push_warning("EventRouter.notify_suppression_changed expects a non-empty fireteam_id.")
		return
	suppression_changed.emit(normalized_fireteam_id, suppression_data.duplicate(true))


func request_return_to_plan(fireteam_id: String, reason: String = "manual") -> void:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		push_warning("EventRouter.request_return_to_plan expects a non-empty fireteam_id.")
		return
	return_to_plan_requested.emit(normalized_fireteam_id, reason.strip_edges().to_lower())


func request_fireteam_coordination(coordination_data: Dictionary) -> void:
	if coordination_data.is_empty():
		push_warning("EventRouter.request_fireteam_coordination expects a non-empty payload.")
		return
	fireteam_coordination_requested.emit(coordination_data.duplicate(true))


func notify_fireteam_ready_to_advance(fireteam_id: String, coordination_id: String) -> void:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		push_warning("EventRouter.notify_fireteam_ready_to_advance expects a non-empty fireteam_id.")
		return
	fireteam_ready_to_advance.emit(normalized_fireteam_id, coordination_id.strip_edges())


func notify_leader_initiated_flank(fireteam_id: String, leader: Node, flank_data: Dictionary) -> void:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		push_warning("EventRouter.notify_leader_initiated_flank expects a non-empty fireteam_id.")
		return
	if leader == null:
		push_warning("EventRouter.notify_leader_initiated_flank expects a leader Node.")
		return
	leader_initiated_flank.emit(normalized_fireteam_id, leader, flank_data.duplicate(true))
