class_name AudioEventPlayerPool
extends Node

signal voice_finished(player: Node)

const DEFAULT_MAX_2D_PLAYERS: int = 16
const DEFAULT_MAX_3D_PLAYERS: int = 12

var max_2d_players: int = DEFAULT_MAX_2D_PLAYERS
var max_3d_players: int = DEFAULT_MAX_3D_PLAYERS
var _players_2d: Array = []
var _players_3d: Array = []
var _suppressed_pool_limit_count: int = 0


func configure(max_2d: int = DEFAULT_MAX_2D_PLAYERS, max_3d: int = DEFAULT_MAX_3D_PLAYERS) -> void:
	max_2d_players = maxi(max_2d, 1)
	max_3d_players = maxi(max_3d, 1)


func play_stream(stream: AudioStream, entry: Dictionary, bus_name: String, volume_db: float, pitch_scale: float, position: Vector3 = Vector3.ZERO) -> Dictionary:
	if stream == null:
		return {"played": false, "reason": "missing_stream"}
	var spatial: bool = bool(entry.get("spatial", false))
	var player: Node = _acquire_player(spatial)
	if player == null:
		_suppressed_pool_limit_count += 1
		return {"played": false, "reason": "pool_limit", "spatial": spatial}
	var audio_id: String = String(entry.get("audio_id", ""))
	var event_key: String = String(entry.get("planned_event", audio_id))
	_apply_player_state(player, stream, bus_name, volume_db, pitch_scale, position, audio_id, event_key, spatial)
	if DisplayServer.get_name() == "headless":
		return {
			"played": true,
			"reason": "headless_simulated_playback",
			"spatial": spatial,
			"audio_id": audio_id,
			"event_key": event_key,
			"bus_name": bus_name,
		}
	if player is AudioStreamPlayer3D:
		(player as AudioStreamPlayer3D).play()
	elif player is AudioStreamPlayer:
		(player as AudioStreamPlayer).play()
	return {
		"played": true,
		"reason": "played",
		"spatial": spatial,
		"audio_id": audio_id,
		"event_key": event_key,
		"bus_name": bus_name,
	}


func get_active_voice_count(event_key: String = "") -> int:
	var active_count: int = 0
	for player in _players_2d:
		if _is_player_active(player) and (event_key.is_empty() or String((player as Node).get_meta("audio_event_key", "")) == event_key):
			active_count += 1
	for player in _players_3d:
		if _is_player_active(player) and (event_key.is_empty() or String((player as Node).get_meta("audio_event_key", "")) == event_key):
			active_count += 1
	return active_count


func get_pool_snapshot() -> Dictionary:
	return {
		"max_2d_players": max_2d_players,
		"max_3d_players": max_3d_players,
		"pooled_2d_count": _players_2d.size(),
		"pooled_3d_count": _players_3d.size(),
		"active_2d_voice_count": _count_active_in(_players_2d),
		"active_3d_voice_count": _count_active_in(_players_3d),
		"active_voice_count": get_active_voice_count(),
		"suppressed_pool_limit_count": _suppressed_pool_limit_count,
		"bounded_pool": true,
	}


func stop_all_for_tests() -> void:
	for player in _players_2d:
		_stop_and_clear_player(player)
	for player in _players_3d:
		_stop_and_clear_player(player)


func _acquire_player(spatial: bool) -> Node:
	var players: Array = _players_3d if spatial else _players_2d
	for player in players:
		if not _is_player_active(player):
			return player
	var max_count: int = max_3d_players if spatial else max_2d_players
	if players.size() >= max_count:
		return null
	var player: Node = _create_player(spatial)
	add_child(player)
	players.append(player)
	if spatial:
		_players_3d = players
	else:
		_players_2d = players
	return player


func _create_player(spatial: bool) -> Node:
	var player: Node
	if spatial:
		player = AudioStreamPlayer3D.new()
		player.name = "AudioEventPlayer3D_%02d" % (_players_3d.size() + 1)
	else:
		player = AudioStreamPlayer.new()
		player.name = "AudioEventPlayer2D_%02d" % (_players_2d.size() + 1)
	if player.has_signal("finished"):
		player.connect("finished", Callable(self, "_on_player_finished").bind(player))
	return player


func _apply_player_state(player: Node, stream: AudioStream, bus_name: String, volume_db: float, pitch_scale: float, position: Vector3, audio_id: String, event_key: String, spatial: bool) -> void:
	if spatial and player is AudioStreamPlayer3D:
		var player_3d := player as AudioStreamPlayer3D
		player_3d.stream = stream
		player_3d.bus = bus_name
		player_3d.volume_db = volume_db
		player_3d.pitch_scale = pitch_scale
		player_3d.global_position = position
	elif player is AudioStreamPlayer:
		var player_2d := player as AudioStreamPlayer
		player_2d.stream = stream
		player_2d.bus = bus_name
		player_2d.volume_db = volume_db
		player_2d.pitch_scale = pitch_scale
	player.set_meta("pool_active", true)
	player.set_meta("audio_id", audio_id)
	player.set_meta("audio_event_key", event_key)
	player.set_meta("spatial", spatial)
	player.set_meta("started_msec", Time.get_ticks_msec())


func _is_player_active(player: Node) -> bool:
	if player == null:
		return false
	if not bool(player.get_meta("pool_active", false)):
		return false
	if player is AudioStreamPlayer3D:
		return bool((player as AudioStreamPlayer3D).playing) or bool(player.get_meta("pool_active", false))
	if player is AudioStreamPlayer:
		return bool((player as AudioStreamPlayer).playing) or bool(player.get_meta("pool_active", false))
	return false


func _count_active_in(players: Array) -> int:
	var active_count: int = 0
	for player in players:
		if _is_player_active(player):
			active_count += 1
	return active_count


func _stop_and_clear_player(player: Node) -> void:
	if player == null:
		return
	if player is AudioStreamPlayer3D:
		(player as AudioStreamPlayer3D).stop()
		(player as AudioStreamPlayer3D).stream = null
	elif player is AudioStreamPlayer:
		(player as AudioStreamPlayer).stop()
		(player as AudioStreamPlayer).stream = null
	_clear_player_meta(player)


func _clear_player_meta(player: Node) -> void:
	for key in ["pool_active", "audio_id", "audio_event_key", "spatial", "started_msec"]:
		if player.has_meta(key):
			player.remove_meta(key)


func _on_player_finished(player: Node) -> void:
	_clear_player_meta(player)
	voice_finished.emit(player)
