class_name EventRouter
extends Node

signal squad_command(squad, order)
signal unit_down(unit)
signal threat_detected(source, threat_data)
signal leader_changed(squad, leader)
signal flank_initiated(fireteam_id, leader, flank_data)
signal respawn_requested(unit, respawn_target)


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
