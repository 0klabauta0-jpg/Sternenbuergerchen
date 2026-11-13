extends SceneTree

const LOBBY_SCENE := preload("res://scenes/ui/multiplayer_lobby.tscn")

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_1105 Coop Lobby Active and Spectator Role Readability ===")
	var lobby: Node = LOBBY_SCENE.instantiate()
	root.add_child(lobby)
	await process_frame

	var coop_snapshot := _build_snapshot(2, "coop", [
		_peer(1, "Host", "team_alpha", "host", ["blue"], true),
		_peer(2, "Mara", "team_alpha", "commander", ["gold"], true),
		_peer(3, "Kai", "team_alpha", "spectator", [], false),
	])
	lobby.call("_apply_session_snapshot", coop_snapshot)
	var ui: Dictionary = Dictionary(lobby.call("get_lobby_ui_snapshot"))
	var peer_text: String = String(ui.get("peer_text", ""))
	var assignment_text: String = String(ui.get("assignment_text", ""))
	var readability: Dictionary = Dictionary(ui.get("role_readability", {}))
	_assert(peer_text.contains("EINSATZROLLEN"), "Lobby names the player-facing role block")
	_assert(peer_text.contains("DU | Mara | AKTIV / GOLD | BEREIT"), "Local active player sees own Gold role")
	_assert(peer_text.contains("Host | HOST / BLUE | BEREIT"), "Host role and Blue Fireteam stay visible")
	_assert(peer_text.contains("Kai | ZUSCHAUER | NICHT BEREIT"), "Waiting peer is visibly a spectator")
	_assert(not peer_text.contains("#1") and not peer_text.contains("team_alpha") and not peer_text.contains("ready="), "Role block hides internal peer, team and readiness codes")
	_assert(assignment_text.contains("COOP | 2 AKTIV | 1 ZUSCHAUER"), "Coop summary counts active and spectator seats")
	_assert(not assignment_text.contains("Fireteam frei"), "Explicit spectators are not promised promotion through nonexistent exclusive slots")
	_assert(int(readability.get("active_count", -1)) == 2 and int(readability.get("spectator_count", -1)) == 1, "Readability snapshot exposes compact seat counts")
	_assert(String(readability.get("local_role_label", "")) == "AKTIV / GOLD", "Readability snapshot exposes the local role label")
	_assert(not bool(readability.get("ui_sets_gameplay_truth", true)), "Role readability remains read-only UI data")

	var promoted_snapshot := _build_snapshot(3, "coop", [
		_peer(1, "Host", "team_alpha", "host", ["blue"], true),
		_peer(3, "Kai", "team_alpha", "commander", ["gold"], true),
	])
	lobby.call("_apply_session_snapshot", promoted_snapshot)
	ui = Dictionary(lobby.call("get_lobby_ui_snapshot"))
	peer_text = String(ui.get("peer_text", ""))
	assignment_text = String(ui.get("assignment_text", ""))
	_assert(peer_text.contains("DU | Kai | AKTIV / GOLD | BEREIT"), "Promoted spectator becomes visibly active on Gold")
	_assert(assignment_text.contains("COOP | 2 AKTIV | 0 ZUSCHAUER"), "Promotion removes the waiting spectator count")
	_assert(not assignment_text.contains("Fireteam frei"), "Promotion hint disappears when nobody is waiting")

	var versus_snapshot := _build_snapshot(1, "versus", [
		_peer(1, "Host", "team_alpha", "host", ["blue", "gold"], true),
		_peer(2, "Rival", "team_bravo", "commander", ["red"], true),
		_peer(3, "Observer", "team_bravo", "spectator", [], true),
	])
	lobby.call("_apply_session_snapshot", versus_snapshot)
	ui = Dictionary(lobby.call("get_lobby_ui_snapshot"))
	peer_text = String(ui.get("peer_text", ""))
	assignment_text = String(ui.get("assignment_text", ""))
	_assert(peer_text.contains("HOST / BLUE + GOLD") and peer_text.contains("AKTIV / RED"), "Versus roles expose both active sides")
	_assert(assignment_text.contains("VERSUS | 2 AKTIV | 1 ZUSCHAUER"), "Versus summary keeps active and spectator counts")
	_assert(not assignment_text.contains("Fireteam frei"), "Versus does not show the Coop promotion promise")

	lobby.queue_free()
	await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _build_snapshot(local_peer_id: int, mode: String, peers: Array) -> Dictionary:
	var peer_teams := {}
	var peer_roles := {}
	var peer_fireteams := {}
	for peer_variant in peers:
		var peer: Dictionary = Dictionary(peer_variant)
		var peer_id: int = int(peer.get("peer_id", 0))
		peer_teams[peer_id] = String(peer.get("team_id", ""))
		peer_roles[peer_id] = String(peer.get("role_id", ""))
		peer_fireteams[peer_id] = PackedStringArray(peer.get("fireteam_ids", []))
	return {
		"status_text": "Connected.",
		"local_peer_id": local_peer_id,
		"has_active_peer": true,
		"can_toggle_ready": true,
		"can_disconnect": true,
		"is_host": local_peer_id == 1,
		"local_ready": true,
		"mission_started": false,
		"peers": peers,
		"assignments": {
			"team_play_mode": mode,
			"peer_teams": peer_teams,
			"peer_roles": peer_roles,
			"peer_fireteams": peer_fireteams,
		},
	}


func _peer(peer_id: int, display_name: String, team_id: String, role_id: String, fireteam_ids: Array, ready: bool) -> Dictionary:
	return {
		"peer_id": peer_id,
		"display_name": display_name,
		"team_id": team_id,
		"role_id": role_id,
		"fireteam_ids": fireteam_ids,
		"ready": ready,
	}


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
