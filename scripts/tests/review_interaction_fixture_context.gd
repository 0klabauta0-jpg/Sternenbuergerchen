extends RefCounted
## Real mission fixtures bind the same declared map/session as the product lobby.
static func bind_pair(host: Node, client: Node, fixture_id: String) -> bool:
	var host_path := String(host.get_node("MissionSetup").get("_loaded_terrain_map_path"))
	var client_path := String(client.get_node("MissionSetup").get("_loaded_terrain_map_path"))
	if host_path.is_empty() or host_path != client_path or not FileAccess.file_exists(host_path): return false
	var context := {"schema":"multiplayer.runtime_context.v1", "runtime_token":fixture_id.md5_text(), "map_id":host_path.get_file().get_basename(), "map_hash":FileAccess.get_sha256(host_path), "scenario_hash":fixture_id.sha256_text()}
	for scene: Node in [host, client]:
		var result: Dictionary = scene.get_node("SimulationRoot").call("bind_multiplayer_runtime_context", context, "team_alpha")
		if not result.get("ok", false): return false
	return true

static func ground_position(scene: Node, unit_id: String) -> Vector2:
	var state: Dictionary = scene.get_node("SimulationRoot").call("get_hex_unit_state", unit_id)
	var terrain = scene.get_node("MissionSetup").get("_loaded_terrain_map_data")
	if state.is_empty() or terrain == null: return Vector2.INF
	return terrain.call("_grid_to_world", Vector2i(state.grid))
