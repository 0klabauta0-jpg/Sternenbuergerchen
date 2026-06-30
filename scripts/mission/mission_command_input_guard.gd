class_name MissionCommandInputGuard
extends RefCounted


func can_issue_local_commands(simulation_root: Node, multiplayer_api: MultiplayerAPI) -> bool:
	if simulation_root == null:
		return true
	if simulation_root.get("is_server_authoritative") != true:
		return true
	if multiplayer_api == null:
		return true
	var peer: MultiplayerPeer = multiplayer_api.multiplayer_peer
	if peer == null or peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		return true
	if multiplayer_api.is_server():
		return true
	if not simulation_root.has_method("get_peer_role"):
		return false
	var role_id: String = String(simulation_root.call("get_peer_role", multiplayer_api.get_unique_id())).strip_edges().to_lower()
	return role_id == "host" or role_id == "commander" or role_id == "fireteam"


func can_edit_planning(preview_mode: bool, simulation_root: Node, multiplayer_api: MultiplayerAPI) -> bool:
	if preview_mode:
		return true
	return can_issue_local_commands(simulation_root, multiplayer_api)
