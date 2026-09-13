extends SceneTree

const SessionScript = preload("res://scripts/network/session_gateway.gd")
var simulation: Node
var session: Node
var role: String = "host"
var output_dir: String = "user://network-probe"
var port: int = 27991
var phase: String = "connect"
var started_ms: int
var checks: Array[Dictionary] = []
var receipts: Dictionary = {}
var serial: int = 0
var phase_started_ms: int = 0
var paused_time: float = 0.0
var initial_credits: int = 0
var guest_first_id: int = 0
var received_snapshots: int = 0
var done: bool = false
var visual: bool = false
var game: Node
var _capture_pending: bool = false
var _captured: Dictionary = {}
var _saved_target: Array = []
var _restored_revision: int = -1
var _radar_checked: bool = false
func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--role="): role = argument.trim_prefix("--role=")
		if argument.begins_with("--output="): output_dir = argument.trim_prefix("--output=")
		if argument.begins_with("--port="): port = int(argument.trim_prefix("--port="))
		if argument == "--visual": visual = true
	call_deferred("_start")

func _start() -> void:
	started_ms = Time.get_ticks_msec()
	DirAccess.make_dir_recursive_absolute(output_dir)
	if visual:
		var game_scene: PackedScene = load("res://scenes/game.tscn")
		game = game_scene.instantiate()
		game.name = "Game"
		game.load_on_start = false
		game.simulation_seed = 3
		game.save_path = output_dir.path_join(role + "-isolated-campaign.json")
		root.add_child(game)
		simulation = game.simulation
		session = game.session
		DisplayServer.window_set_title("Sternenbürgerchen · N2 ENet " + role.to_upper())
		game.hud.choose_unit("jaro" if role == "guest" else "ida", false)
	else:
		game = Node.new()
		game.name = "Game"
		root.add_child(game)
		var core_script: Script = load("res://scripts/core/simulation_root.gd")
		simulation = core_script.new(3)
		simulation.name = "Simulation"
		game.add_child(simulation)
		session = SessionScript.new()
		session.name = "Session"
		game.add_child(session)
		session.setup(simulation)
	session.command_result.connect(_record_result)
	session.snapshot_received.connect(_record_snapshot)
	if role == "host":
		_check(session.start_host(port) == OK, "ENet host starts")
		# Real commands and core advancement; only test time runs at 20x.
		# ENet delivery and session snapshot cadence remain real wall-clock time.
		simulation.auto_tick = false
		initial_credits = int(simulation.snapshot().credits)
		_write("host_stage", {"stage":"ready"})
	else:
		_check(session.join_host("127.0.0.1", port) == OK, "ENet guest connects")
		_check(not simulation.auto_tick, "guest simulation cannot tick independently")

func _process(delta: float) -> bool:
	if done or simulation == null: return false
	if Time.get_ticks_msec() - started_ms > 55000:
		_check(false, "timeout in phase " + phase)
		_finish()
		return false
	if _capture_pending: return false
	if role == "host":
		simulation.advance(delta * 20.0)
		_host_step()
	else:
		_guest_step()
	return false

func _host_step() -> void:
	var state: Dictionary = session.current_snapshot()
	var guest_stage: String = str(_read("guest_stage").get("stage", ""))
	match phase:
		"connect":
			if int(state.crew.jaro.owner) == 1: return
			guest_first_id = int(state.crew.jaro.owner)
			_check(state.crew.size() == 2 and int(state.crew.ida.owner) == 1, "exactly two crew and split ownership")
			_check(not _command("move", {"unit_id":"jaro","position":[2,2]}).ok, "host cannot command guest crew")
			_check(_command("accept_contract").ok, "host accepts real contract")
			_check(_command("assign_work", {"unit_id":"ida","recipe_id":"toolkit"}).ok, "host assigns real toolkit work")
			_check(_command("toggle_pause").ok, "host pauses shared simulation")
			_saved_target = simulation.snapshot().crew.jaro.target.duplicate()
			_check(simulation.save_game(output_dir.path_join("host-paused-save.json")).ok, "save paused shared state before guest command")
			phase = "pause"
			_write("host_stage", {"stage":"paused","revision":int(simulation.snapshot().revision)})
		"pause":
			if guest_stage != "paused_checked": return
			if not _ensure_capture("paused"): return
			_check(bool(state.paused) and int(state.inventory.toolkit) == 0, "paused host work does not finish")
			_check(state.crew.jaro.target == [4,3], "guest move delivered through ENet")
			var live_revision: int = int(state.revision)
			_check(simulation.load_game(output_dir.path_join("host-paused-save.json")).ok, "host loads older paused save while guest connected")
			var restored: Dictionary = simulation.snapshot()
			_restored_revision = int(restored.revision)
			var target_distance: float = Vector2(restored.crew.jaro.target[0],restored.crew.jaro.target[1]).distance_to(Vector2(_saved_target[0],_saved_target[1]))
			_check(_restored_revision > live_revision and target_distance < 0.0001, "load restores old target using greater live revision")
			_write("host_stage", {"stage":"restored","revision":_restored_revision,"target":_saved_target})
			phase = "restore_wait"
		"restore_wait":
			if guest_stage != "restored_checked": return
			_check(_command("toggle_pause").ok, "host resumes shared simulation")
			phase = "craft"
		"craft":
			if int(state.inventory.toolkit) != 1: return
			_check(_command("travel", {"destination":"rust"}).ok, "host starts real outbound travel")
			phase = "outbound"
		"outbound":
			if str(state.region) != "rust" or bool(state.travel.active): return
			_check(not state.discovery.satellite_found,"new mission starts with unknown satellite")
			_check(_command("launch").ok,"host begins actual search-flight boarding")
			phase="launch"
		"launch":
			if state.ship.mode!="flying":return
			_check(_command("radar_scan").ok,"host scans from airborne shuttle")
			var radar: Dictionary=simulation.snapshot()
			_check(radar.discovery.signals.size()==3 and not JSON.stringify(radar.discovery.signals).contains("satellite"),"radar exposes anonymous contacts only")
			_write("host_stage",{"stage":"radar_ready","revision":int(radar.revision)})
			phase="radar_wait"
		"radar_wait":
			if guest_stage!="radar_checked":return
			_check(_command("ship_move",{"position":[145,-125]}).ok,"host pilots pointclick approach to radar contact")
			phase="search"
		"search":
			if not state.discovery.satellite_found:return
			_check(_command("land").ok,"nearby contact identified and actual ship landed")
			_check(simulation.snapshot().crew.jaro.assignment=="idle","guest exits landed ship for foot work")
			_write("host_stage",{"stage":"salvage","revision":int(simulation.snapshot().revision)})
			phase="salvage"
		"salvage":
			if str(state.contract.status) != "recovered": return
			_check(int(state.cargo.blackbox) == 1 and int(state.wreck_remaining) < 8, "guest work produces real finite salvage")
			_check(_command("travel", {"destination":"base"}).ok, "host starts return travel")
			phase = "return"
		"return":
			if str(state.region) != "base" or bool(state.travel.active): return
			var payload: Dictionary = {"type":"claim_contract","request_id":"host-claim-once"}
			_check(session.dispatch(payload).ok, "host claims delivered blackbox")
			var credits: int = int(session.current_snapshot().credits)
			_check(session.dispatch(payload).ok and int(session.current_snapshot().credits) == credits, "same payout request is idempotent")
			_check(not _command("claim_contract").ok and int(session.current_snapshot().credits) == credits, "second payout request refused")
			_check(credits == initial_credits + int(state.contract.reward), "reward paid exactly once")
			_write("host_stage", {"stage":"reward","credits":credits})
			phase = "reward_wait"
		"reward_wait":
			if guest_stage!="reward_checked":return
			_check(_command("travel",{"destination":"station"}).ok,"host accepts station route with saved random decision")
			_check(simulation.snapshot().travel.encounter_roll<35,"seeded real station roll produces pirate contact")
			phase="station_route"
		"station_route":
			if state.region!="space":return
			_check(state.encounter.active and state.ship.roles.pilot=="ida" and state.ship.roles.gunner=="jaro","independent contact map has explicit pilot and turret roles")
			_check(not _command("fire_turret",{"target_id":"pirate"}).ok,"host cannot commandeer guest turret")
			_check(_command("toggle_pause").ok,"host pauses contact for joint role check")
			_write("host_stage",{"stage":"contact","revision":int(simulation.snapshot().revision)})
			phase="contact_wait"
		"contact_wait":
			if guest_stage!="contact_checked":return
			if not _ensure_capture("contact"):return
			_check(state.encounter.turret_target=="pirate","guest turret order confirmed by authoritative host")
			_check(simulation.save_game(output_dir.path_join("host-contact.json")).ok,"shared paused combat snapshot saved")
			_check(simulation.load_game(output_dir.path_join("host-contact.json")).ok,"shared combat snapshot restored preserving guest")
			_check(_command("toggle_pause").ok,"shared contact resumes")
			phase="combat"
		"combat":
			if state.region!="station":return
			_check(state.encounter.status=="won" and state.encounter.enemy.hull==0,"guest turret defeats weak pirate and reaches original station destination")
			_write("host_stage",{"stage":"won","credits":int(state.credits),"revision":int(state.revision)})
			phase="won_wait"
		"won_wait":
			if guest_stage!="won_checked":return
			_check(_command("travel",{"destination":"base"}).ok,"host returns from station after encounter")
			phase="return_for_disconnect"
		"return_for_disconnect":
			if state.region!="base" or state.travel.active:return
			_write("host_stage",{"stage":"disconnect_now","credits":int(state.credits)})
			phase="disconnect"
		"disconnect":
			if guest_stage != "disconnected" or int(state.crew.jaro.owner) != 1: return
			_check(bool(state.paused) and state.crew.size() == 2, "disconnect pauses and returns guest seat")
			_check(_command("move", {"unit_id":"jaro","position":[3,2]}).ok, "host regains guest crew after disconnect")
			_write("host_stage", {"stage":"reconnect"})
			phase = "reconnect"
		"reconnect":
			if int(state.crew.jaro.owner) == 1: return
			if not _ensure_capture("reconnected"): return
			_check(state.crew.size() == 2 and bool(state.paused), "reconnect reuses existing paused crew")
			_check(int(state.credits) == initial_credits + int(state.contract.reward), "reconnect preserves once-only reward")
			_check(not _command("move", {"unit_id":"jaro","position":[2,2]}).ok, "reconnect restores guest authority")
			_write("host_stage", {"stage":"reconnected","credits":int(state.credits)})
			phase = "finish"
		"finish":
			if guest_stage != "done": return
			_check(received_snapshots > 5, "host publishes live revisions throughout mission")
			_finish()

func _guest_step() -> void:
	var state: Dictionary = session.current_snapshot()
	if state.is_empty(): return
	var host: Dictionary = _read("host_stage")
	var host_stage: String = str(host.get("stage", ""))
	match phase:
		"connect":
			if host_stage != "paused" or not bool(state.paused) or int(state.revision) < int(host.revision): return
			_check(state.crew.size() == 2 and int(state.crew.jaro.owner) == session.multiplayer.get_unique_id(), "guest receives own assigned seat")
			paused_time = float(state.time)
			_send_named("foreign", "move", {"unit_id":"ida","position":[0,0],"sender_id":1,"owner":1})
			_send_named("pause", "toggle_pause")
			_send_named("travel", "travel", {"destination":"rust"})
			_send_named("trade", "trade", {"side":"buy","item":"parts","amount":1})
			_send_named("move", "move", {"unit_id":"jaro","position":[4,3]})
			phase_started_ms = Time.get_ticks_msec()
			phase = "pause"
		"pause":
			if receipts.size() < 5 or Time.get_ticks_msec() - phase_started_ms < 500: return
			if not _ensure_capture("paused"): return
			_check(not receipts["foreign"].ok, "forged sender cannot control foreign crew")
			_check(not receipts["pause"].ok and not receipts["travel"].ok and not receipts["trade"].ok, "guest cannot pause travel or trade")
			_check(receipts["move"].ok and state.crew.jaro.target == [4,3], "own crew command confirmed in host snapshot")
			_check(bool(state.paused) and is_equal_approx(float(state.time), paused_time), "shared pause freezes simulation while RPC continues")
			_check(not simulation.auto_tick and int(simulation.snapshot().revision) == 0, "guest core remains untouched by replicated world")
			_write("guest_stage", {"stage":"paused_checked"})
			phase = "restore_wait"
		"restore_wait":
			if host_stage != "restored" or int(state.revision) < int(host.revision): return
			_check(state.crew.jaro.target == host.target and bool(state.paused), "guest receives restored target despite paused older-save load")
			_check(int(state.crew.jaro.owner) == session.multiplayer.get_unique_id(), "loading preserves connected guest ownership")
			_check(is_equal_approx(float(state.time), paused_time), "load and replication leave saved pause time unchanged")
			_write("guest_stage", {"stage":"restored_checked"})
			phase = "salvage_wait"
		"salvage_wait":
			if not _radar_checked and host_stage=="radar_ready" and state.region=="rust" and int(state.revision)>=int(host.revision):
				_check(state.ship.mode=="flying" and state.discovery.signals.size()==3 and not state.discovery.satellite_found,"guest receives same anonymous airborne radar")
				_send_named("pilot_forbidden","ship_move",{"position":[0,0],"sender_id":1})
				_send_named("radar_forbidden","radar_scan")
				_send_named("land_forbidden","land")
				phase="radar_check"
				return
			if host_stage != "salvage" or str(state.region) != "rust" or int(state.revision)<int(host.revision): return
			_check(state.discovery.satellite_found and state.ship.mode=="landed","guest sees proximity discovery and landed ship")
			_check(not bool(state.paused) and int(state.inventory.toolkit) == 1, "guest sees completed crafting and shared travel")
			_send_named("salvage", "salvage", {"unit_id":"jaro"})
			phase = "reward"
		"radar_check":
			if not receipts.has("pilot_forbidden") or not receipts.has("radar_forbidden") or not receipts.has("land_forbidden"):return
			_check(not receipts.pilot_forbidden.ok and not receipts.radar_forbidden.ok and not receipts.land_forbidden.ok,"guest cannot spoof pilot radar or landing authority")
			_radar_checked=true
			_write("guest_stage",{"stage":"radar_checked"})
			phase="salvage_wait"
		"reward":
			if host_stage != "reward" or str(state.contract.status) != "claimed": return
			_check(receipts.has("salvage") and receipts["salvage"].ok, "guest salvage accepted remotely")
			_check(int(state.credits) == int(host.credits) and state.blueprints.count("cutter") == 1, "guest sees identical one-time reward")
			_write("guest_stage",{"stage":"reward_checked"})
			phase="contact_wait"
		"contact_wait":
			if host_stage!="contact" or state.region!="space" or int(state.revision)<int(host.revision):return
			_check(state.encounter.active and state.paused,"guest receives same paused pirate contact")
			_send_named("pilot_space_forbidden","ship_move",{"position":[-150,0]})
			_send_named("turret","fire_turret",{"target_id":"pirate"})
			phase="contact_check"
		"contact_check":
			if not receipts.has("pilot_space_forbidden") or not receipts.has("turret") or state.encounter.turret_target!="pirate":return
			if not _ensure_capture("contact"):return
			_check(not receipts.pilot_space_forbidden.ok and receipts.turret.ok,"guest turret works while pilot remains host-only")
			_write("guest_stage",{"stage":"contact_checked"})
			phase="won_wait"
		"won_wait":
			if host_stage!="won" or state.region!="station" or int(state.revision)<int(host.revision):return
			_check(state.encounter.status=="won" and state.encounter.enemy.hull==0,"guest sees actual turret victory and continued station route")
			_check(int(state.credits)==int(host.credits),"combat introduces no duplicate contract reward")
			_write("guest_stage",{"stage":"won_checked"})
			phase="disconnect_wait"
		"disconnect_wait":
			if host_stage!="disconnect_now" or state.region!="base":return
			session.disconnect_session()
			_write("guest_stage", {"stage":"disconnected"})
			phase = "reconnect_wait"
		"reconnect_wait":
			if host_stage != "reconnect": return
			_check(session.join_host("127.0.0.1", port) == OK, "same guest reconnects through new ENet connection")
			phase = "reconnected"
		"reconnected":
			if host_stage != "reconnected" or int(state.crew.jaro.owner) != session.multiplayer.get_unique_id(): return
			if not _ensure_capture("reconnected"): return
			_check(bool(state.paused) and state.crew.size() == 2, "reconnected guest receives same two paused crew")
			_check(int(state.credits) == int(host.credits) and state.blueprints.count("cutter") == 1, "reward unchanged on reconnect")
			_send_named("again_foreign", "move", {"unit_id":"ida","position":[0,0]})
			_send_named("again_own", "move", {"unit_id":"jaro","position":[1,1]})
			phase = "finish"
		"finish":
			if not receipts.has("again_foreign") or not receipts.has("again_own"): return
			_check(not receipts.again_foreign.ok and receipts.again_own.ok, "reconnected guest retains correct command rights")
			_check(received_snapshots > 5, "guest receives live reliable snapshots")
			_write("guest_stage", {"stage":"done"})
			_finish()

func _command(kind: String, data: Dictionary = {}) -> Dictionary:
	serial += 1
	var command: Dictionary = data.duplicate(true)
	command.type = kind
	command.request_id = "host-%d" % serial
	return session.dispatch(command)

func _send_named(id: String, kind: String, data: Dictionary = {}) -> void:
	var command: Dictionary = data.duplicate(true)
	command.type = kind
	command.request_id = id
	session.dispatch(command)

func _record_result(result: Dictionary) -> void:
	receipts[str(result.get("request_id", ""))] = result

func _record_snapshot(_state: Dictionary) -> void:
	received_snapshots += 1

func _ensure_capture(label: String) -> bool:
	if not visual or _captured.has(label): return true
	if not _capture_pending:
		_capture_pending = true
		_capture_viewport(label)
	return false

func _capture_viewport(label: String) -> void:
	game.hud.select_object("object", "shuttle" if label=="contact" else ("workbench" if label == "paused" else "contracts"))
	game.world.focus_home()
	game._refresh()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var shot: Image = root.get_texture().get_image()
	var filename: String = role + "-" + label + ".png"
	var error: Error = shot.save_png(output_dir.path_join(filename))
	_check(error == OK and shot.get_width() > 0 and shot.get_height() > 0, "real game viewport captured: " + label)
	_write(role + "-" + label + "-capture", {"file":filename,"role":role,"phase":phase,"status":session.status_text(),"width":shot.get_width(),"height":shot.get_height(),"snapshot":session.current_snapshot()})
	_captured[label] = filename
	_capture_pending = false

func _check(passed: bool, message: String) -> void:
	checks.append({"passed":passed,"message":message})
	print("%s %s: %s" % [role.to_upper(), "PASS" if passed else "FAIL", message])

func _write(name: String, payload: Dictionary) -> void:
	var file: FileAccess = FileAccess.open(output_dir.path_join(name + ".json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(payload))

func _read(name: String) -> Dictionary:
	var path: String = output_dir.path_join(name + ".json")
	if not FileAccess.file_exists(path): return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

func _finish() -> void:
	done = true
	var failed: int = checks.filter(func(item: Dictionary) -> bool: return not item.passed).size()
	_write(role + "_result", {"role":role,"visual":visual,"captures":_captured,"checks":checks,"failed":failed,"received_snapshots":received_snapshots,"elapsed_ms":Time.get_ticks_msec()-started_ms})
	print("NETWORK_%s_RESULT checks=%d failed=%d" % [role.to_upper(), checks.size(), failed])
	quit(0 if failed == 0 else 1)
