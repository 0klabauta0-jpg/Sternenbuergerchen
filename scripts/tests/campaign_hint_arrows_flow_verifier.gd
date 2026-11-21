extends SceneTree
## Hinweispfeile der Basis am echten Ablauf einer NEUEN Kampagne (Auftrag P3 "Tutorial-Pfeile", 21.11.2026).
## Reihenfolge: Pfeil 1 (Ausruesten) -> 2 (Tanken) -> 3 (Auftrag annehmen) -> 4 (Einschiffen) -> 5 (Abheben) -> kein Pfeil.
## Jeder Hinweis zeigt zuerst auf den Wegweiser (Navigationsknopf), solange sein Ziel nicht offen ist, dann auf das Ziel selbst.
## Ausserdem: Eingaben gehen durch den Pfeil, Modus "off" zeigt nie einen Pfeil, Fortsetzen mit angenommenem Auftrag zeigt
## die erledigten Hinweise nicht erneut.
## Abschlusszeile: CAMPAIGN_HINT_ARROWS_FLOW passed=%d failed=%d
## Braucht ein Wegwerfprofil (SB_REVIEW2_USER_DIR), sonst Abbruch ohne Schreiben.

const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const START = preload("res://scripts/meta/game_start_contract.gd")
const FLOW: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const SETTINGS = preload("res://scripts/ui/game_settings_contract.gd")
const TEST_CFG := "user://campaign_hint_arrows_flow_settings.cfg"
const JOB := "satellite_recovery"

var _passed := 0
var _failed := 0
var _flow: Node = null
var _screen: Control = null
var _presenter: Control = null
var _adapter: Node = null
var _tut: Control = null
var _arrows: RefCounted = null
var _arrow: Control = null
var _craft := ""


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var verdict: Dictionary = GUARD.verdict_from_environment()
	if not bool(verdict.get("ok", false)):
		print("CAMPAIGN_HINT_ARROWS_FLOW refused: needs a throwaway profile (SB_REVIEW2_USER_DIR), nothing written. Reason: %s" % str(verdict.get("reason", "")))
		quit(2)
		return
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	root.size = Vector2i(1920, 1080)
	SETTINGS.save_settings({"contextual_help_mode": "compact"}, TEST_CFG)
	await _part_a_full_order()
	await _part_b_mode_off()
	await _part_c_resume_with_accepted_job()
	await _part_d_accept_first()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_CFG))
	print("CAMPAIGN_HINT_ARROWS_FLOW passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)


func _open_flow(kind: String) -> bool:
	START.request_start(self, "campaign", kind)
	_flow = FLOW.instantiate()
	root.add_child(_flow)
	for i in 12:
		await process_frame
	_screen = _flow.get_node("HomebaseScreen")
	_presenter = _screen.get("_operations_presenter")
	_adapter = _flow.get("_singleplayer_runtime")
	_tut = _flow.get("_campaign_tutorial")
	_craft = String(_flow.get_meta("singleplayer_bootstrap_craft_id", ""))
	if _tut == null:
		return _check(false, "Kampagnenkarte vorhanden")
	_arrows = _tut.call("get_hint_arrows")
	_arrow = _tut.call("get_hint_arrow")
	_arrows.set("settings_path", TEST_CFG)
	_arrows.set("poll_interval_msec", 0)
	return true


func _close_flow() -> void:
	if _flow != null:
		_flow.queue_free()
		_flow = null
	await process_frame
	await process_frame


func _active() -> String:
	return String(_arrows.call("get_active_hint_id"))


func _showing() -> bool:
	return bool(_arrow.call("is_showing"))


## Wartet, bis der Hinweis `id` aktiv ist und der Pfeil gezeigt wird.
func _wait_hint(id: String, seconds: float = 8.0) -> bool:
	var end := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < end:
		_tut.call("refresh")
		await process_frame
		if _active() == id and _showing():
			return true
	return false


## Wartet, bis kein Hinweis mehr aktiv ist und kein Pfeil gezeigt wird.
func _wait_none(seconds: float = 8.0) -> bool:
	var end := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < end:
		_tut.call("refresh")
		await process_frame
		if _active().is_empty() and not _showing():
			return true
	return false


## Wartet, bis `condition` wahr ist (Zeit statt Bilder: Seitenfenster fahren animiert ein).
func _wait_until(condition: Callable, seconds: float = 6.0) -> bool:
	var end := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < end:
		_tut.call("refresh")
		await process_frame
		if bool(condition.call()):
			return true
	return false


## Fehlersuche: gibt die Bedingungswoerter und den aktiven Hinweis aus (nur Information, keine Pruefung).
func _explain(label: String) -> void:
	var facts: Dictionary = _tut.get("_hint_facts")
	var words := ["weapon_carried", "pistol_in_store", "job_open:" + JOB, "job_taken:" + JOB, "fuel_full", "crew_boarded", "boarding_underway", "launch_ready", "craft_away"]
	var parts: Array = []
	for word: String in words:
		parts.append("%s=%s" % [word, str(_arrows.call("_holds", word, facts))])
	print("INFO %s: aktiv='%s' gezeigt=%s stage=%s view=%s %s" % [label, _active(), str(_showing()), str(facts.get("stage")), str(facts.get("view")), " ".join(parts)])
	var craft: Dictionary = Dictionary(Dictionary(facts.get("operations", {})).get("selected_craft", {}))
	print("INFO %s: Schiff has_payload=%s pilot_aboard=%s aboard=%s/%s can_start=%s busy=%s" % [label, str(craft.get("has_payload")), str(craft.get("pilot_aboard")), str(craft.get("aboard_count")), str(craft.get("passenger_count")), str(craft.get("can_start")), str(craft.get("busy"))])


func _wait_frames(count: int) -> void:
	for i in count:
		_tut.call("refresh")
		await process_frame


## Zeigt die Pfeilspitze auf den Knoten? (Spitze knapp ausserhalb des Zielrechtecks.)
func _points_at(target: Control, label: String) -> bool:
	if target == null or not is_instance_valid(target):
		return _check(false, label + ": Zielknoten vorhanden")
	var snap: Dictionary = _arrow.call("get_layout_snapshot")
	if snap.is_empty():
		_explain(label)
		return _check(false, label + ": Pfeil hat ein Layout")
	var tip: Vector2 = snap["tip"]
	var rect: Rect2 = target.get_global_rect()
	var near: bool = rect.grow(10.0).has_point(tip) and not rect.has_point(tip)
	return _check(near, "%s: Pfeilspitze %s liegt knapp am Ziel %s" % [label, str(tip), str(rect)])


func _node(name: String) -> Control:
	return _screen.find_child(name, true, false) as Control


## Knoten `name` unterhalb von `within` (Name wie im Hinweis: "within" + "node"), gesucht ab der Szene.
func _in(within: String, name: String) -> Control:
	var scope: Node = _flow.find_child(within, true, false)
	return scope.find_child(name, true, false) as Control if scope != null else null


func _slot() -> Control:
	return _presenter.get("_inventory_panel").get("_slots").get_node_or_null("InventorySlot_weapon_1") as Control


func _supply() -> Dictionary:
	return Dictionary(_adapter.call("get_snapshot")).get("supply", {})


func _job_status() -> String:
	return String(Dictionary(Dictionary(Dictionary(_adapter.call("get_snapshot")).get("campaign", {})).get("jobs", {})).get(JOB, {}).get("status", ""))


func _fuel_full() -> bool:
	var supply: Dictionary = _supply()
	return float(Dictionary(supply.get("fuel_by_craft_id", {})).get(_craft, 0.0)) >= float(supply.get("fuel_capacity", 1.0)) - 0.001


func _boarded() -> bool:
	var runtime: Node = _adapter.call("get_base_personnel_runtime")
	if runtime == null or not bool(runtime.call("is_pilot_aboard", _craft)):
		return false
	for person: Dictionary in runtime.call("get_snapshot").get("units", []):
		if String(person.get("status", "")) != "aboard":
			return false
	return true


func _part_a_full_order() -> void:
	if not await _open_flow("new"):
		return
	var runtime: Node = _adapter.call("get_base_personnel_runtime")
	var sim: Node = runtime.call("get_simulation_root")

	# --- 1: Ausruesten. Wegweiser, dann der Platz.
	_screen.call("request_operation", "navigate", {"mode": "base"})
	_check(await _wait_hint("equip_weapon"), "A1: Hinweis 'equip_weapon' wird gezeigt (Start, Pistole im Lager, niemand bewaffnet)")
	_points_at(_node("Navigate_squad"), "A1 Wegweiser")
	_node("Navigate_squad").pressed.emit()
	_check(await _wait_hint("equip_weapon"), "A1: Hinweis bleibt, nachdem die Ausruestungsansicht offen ist")
	await _wait_frames(6)
	var slot: Control = _slot()
	_check(slot != null and slot.is_visible_in_tree(), "A1: Waffenplatz 1 der gewaehlten Person ist sichtbar")
	_points_at(slot, "A1 Platz")
	_check(_active() == "equip_weapon", "A1: weiter Hinweis 'equip_weapon'")
	await _check_click_through()
	# Anlegen ueber das echte Ziehen-Signal des Platzes (wie der Mausweg).
	slot = _slot()
	slot.payload_dropped.emit({"source_container_id": "base:homebase", "item_id": "pistol"})

	# --- 2: Tanken. Wegweiser Tankservice, dann RefuelCraft.
	_check(await _wait_hint("refuel_ship"), "A2: nach dem Ausruesten kommt 'refuel_ship'")
	_check(not _fuel_full(), "A2: der Tank des Startschiffs ist wirklich nicht voll")
	_points_at(_node("OpenBaseServices"), "A2 Wegweiser")
	_node("OpenBaseServices").pressed.emit()
	_check(await _wait_hint("refuel_ship"), "A2: Hinweis bleibt, nachdem das Tankfenster offen ist")
	await _wait_frames(30)
	# Im Tankfenster ist zuerst das Schiff zu waehlen ("Serviceschiff auswaehlen"); erst dann geht Auftanken.
	var chooser := _in("BaseServices", "ServiceCraftSelector") as OptionButton
	_check(chooser != null and chooser.is_visible_in_tree() and chooser.selected == 0, "A2: im Tankfenster ist noch kein Serviceschiff gewaehlt")
	_points_at(chooser, "A2 Schiffswahl")
	_check(_active() == "refuel_ship", "A2: Hinweis bleibt 'refuel_ship' bei der Schiffswahl")
	# Das Schiff waehlt der Spieler in der Auswahl IM Tankfenster (W2: homebase_screen leitet die Wahl jetzt weiter).
	chooser.select(1)
	chooser.item_selected.emit(1)
	await _wait_frames(30)
	_check(await _wait_hint("refuel_ship"), "A2: Hinweis bleibt, nachdem das Schiff gewaehlt ist")
	var refuel: Control = _in("MissionServices", "RefuelCraft")
	if refuel == null or not refuel.is_visible_in_tree():
		refuel = _in("BaseServices", "RefuelCraft")
	_check(refuel != null and refuel.is_visible_in_tree(), "A2: RefuelCraft ist sichtbar")
	_points_at(refuel, "A2 Tankknopf")
	for i in 40:
		if _fuel_full():
			break
		(refuel as Button).pressed.emit()
		await _wait_frames(4)
	_check(_fuel_full(), "A2: Tank ist nach dem Tanken voll")

	# --- 3: Auftrag annehmen.
	_check(await _wait_hint("accept_job"), "A3: nach dem Tanken kommt 'accept_job'")
	_points_at(_node("Navigate_jobs"), "A3 Wegweiser")
	_node("Navigate_jobs").pressed.emit()
	_check(await _wait_hint("accept_job"), "A3: Hinweis bleibt, nachdem die Auftragstafel offen ist")
	# Die Auftragstafel zeigt die Annehmen-Schaltflaeche erst, wenn die Auftragskarte aufgeklappt ist (Klick auf die Karte).
	# Bis dahin zeigt der Pfeil auf die Karte (Knotenname JobCard_<Auftrag>), danach auf AcceptJob.
	await _wait_until(func(): return _node("JobCard_" + JOB) != null and _node("JobCard_" + JOB).is_visible_in_tree())
	await _wait_frames(10)
	var card: Control = _node("JobCard_" + JOB)
	_check(card != null and card.is_visible_in_tree(), "A3: die Auftragskarte des Satellitenauftrags (JobCard_) ist sichtbar")
	_check(_node("AcceptJob") == null or not _node("AcceptJob").is_visible_in_tree(), "A3: AcceptJob ist vor dem Aufklappen noch nicht sichtbar")
	_points_at(card, "A3 Auftragskarte")
	_check(_active() == "accept_job", "A3: Hinweis bleibt 'accept_job' bei der Karte")
	if card != null:
		(card as Button).pressed.emit()
	await _wait_until(func(): return _node("AcceptJob") != null and _node("AcceptJob").is_visible_in_tree())
	await _wait_frames(10)
	var accept: Control = _node("AcceptJob")
	_check(accept != null and accept.is_visible_in_tree(), "A3: AcceptJob ist sichtbar")
	_points_at(accept, "A3 Annehmen")
	_check(_job_status() in ["offered", "failed"], "A3: Satellitenauftrag ist noch nicht angenommen: " + _job_status())
	(accept as Button).pressed.emit()
	await _wait_frames(6)
	_check(_job_status() in ["accepted", "active"], "A3: Satellitenauftrag ist angenommen: " + _job_status())

	# --- 4: Einschiffen.
	_check(await _wait_hint("board_ship"), "A4: nach dem Annehmen kommt 'board_ship'")
	_points_at(_node("Navigate_mission"), "A4 Wegweiser")
	_node("Navigate_mission").pressed.emit()
	_check(await _wait_hint("board_ship"), "A4: Hinweis bleibt, nachdem das Flugdeck offen ist")
	await _wait_until(func(): return _node("BoardFireteam") != null and _node("BoardFireteam").is_visible_in_tree())
	await _wait_frames(10)
	var board: Control = _node("BoardFireteam")
	_check(board != null and board.is_visible_in_tree(), "A4: 'Boarding starten' hat den Knotennamen BoardFireteam und ist sichtbar")
	_points_at(board, "A4 Boarding")
	(board as Button).pressed.emit()

	# --- 5: Abheben, sobald alle wirklich an Bord sind.
	for i in 4000:
		sim.call("_physics_process", 0.05)
		_screen.call("_debug_advance_homebase_direct_boarding", 0.05)
		if _boarded():
			break
	_check(_boarded(), "A5: Pilot und Trupp sind wirklich an Bord")
	var take_off_shown: bool = await _wait_hint("take_off")
	if not take_off_shown:
		_explain("A5")
	_check(take_off_shown, "A5: nach dem Einschiffen kommt 'take_off'")
	await _wait_frames(6)
	_points_at(_node("StartMission"), "A5 Abheben")
	(_node("StartMission") as Button).pressed.emit()
	_check(await _wait_none(), "A5: nach dem Abheben bleibt kein Pfeil zurueck")
	await _wait_frames(30)
	_check(_active().is_empty() and not _showing(), "A5: auch eine halbe Sekunde spaeter kein Pfeil (Aktiv: '%s')" % _active())
	await _close_flow()


func _part_b_mode_off() -> void:
	SETTINGS.save_settings({"contextual_help_mode": "off"}, TEST_CFG)
	if not await _open_flow("new"):
		return
	_screen.call("request_operation", "navigate", {"mode": "squad"})
	var seen := false
	for i in 90:
		_tut.call("refresh")
		await process_frame
		if _showing() or not _active().is_empty():
			seen = true
	_check(not seen, "B: Modus 'off' zeigt nie einen Pfeil (Pistole im Lager, nichts ausgeruestet)")
	await _close_flow()
	SETTINGS.save_settings({"contextual_help_mode": "compact"}, TEST_CFG)


func _part_c_resume_with_accepted_job() -> void:
	if not await _open_flow("new"):
		return
	var accepted: Dictionary = _screen.call("request_operation", "accept_job", {"job_id": JOB})
	_check(bool(accepted.get("ok", false)), "C: Satellitenauftrag im neuen Stand angenommen: " + str(accepted))
	await _equip()
	var saved: Dictionary = _flow.get("_campaign_start").call("save_home_checkpoint", _flow, _adapter, true)
	_check(bool(saved.get("ok", false)), "C: Stand gespeichert: " + str(saved))
	await _close_flow()
	if not await _open_flow("continue"):
		return
	_check(_job_status() in ["accepted", "active"], "C: Fortsetzen: Auftrag ist weiter angenommen: " + _job_status())
	var seen: Dictionary = {}
	for i in 120:
		_tut.call("refresh")
		await process_frame
		if not _active().is_empty():
			seen[_active()] = true
	_check(not seen.has("equip_weapon") and not seen.has("accept_job"), "C: Fortsetzen (ausgeruestet, Auftrag angenommen) zeigt weder 'equip_weapon' noch 'accept_job' erneut: " + str(seen.keys()))
	_check(seen.has("refuel_ship"), "C: nach dem Fortsetzen steht der naechste offene Hinweis 'refuel_ship' an (Tank nicht voll): " + str(seen.keys()))
	await _close_flow()


## W1: Wer den Auftrag zuerst annimmt, sieht trotzdem 10 (Ausruesten), dann 20 (Tanken), dann 40 (Einschiffen).
func _part_d_accept_first() -> void:
	if not await _open_flow("new"):
		return
	var accepted: Dictionary = _screen.call("request_operation", "accept_job", {"job_id": JOB})
	_check(bool(accepted.get("ok", false)), "D: Satellitenauftrag zuerst angenommen: " + str(accepted))
	_screen.call("request_operation", "navigate", {"mode": "base"})
	_check(await _wait_hint("equip_weapon"), "D: trotz angenommenem Auftrag erscheint Pfeil 'equip_weapon'")
	await _equip()
	_check(await _wait_hint("refuel_ship"), "D: danach 'refuel_ship'")
	_node("OpenBaseServices").pressed.emit()
	await _wait_frames(30)
	var chooser := _in("BaseServices", "ServiceCraftSelector") as OptionButton
	if chooser != null:
		chooser.select(1)
		chooser.item_selected.emit(1)
	await _wait_frames(30)
	var refuel: Control = _in("MissionServices", "RefuelCraft")
	if refuel == null or not refuel.is_visible_in_tree():
		refuel = _in("BaseServices", "RefuelCraft")
	for i in 40:
		if refuel == null or _fuel_full():
			break
		(refuel as Button).pressed.emit()
		await _wait_frames(4)
	_check(_fuel_full(), "D: Tank voll")
	_check(await _wait_hint("board_ship"), "D: danach 'board_ship' (accept_job entfaellt, der Auftrag ist angenommen)")
	await _close_flow()


## Rüstet die erste Person mit der Pistole aus dem Lager aus (echtes Ziehen-Signal des Platzes).
func _equip() -> void:
	_screen.call("request_operation", "navigate", {"mode": "squad"})
	await _wait_frames(30)
	var slot: Control = _slot()
	if slot != null:
		slot.payload_dropped.emit({"source_container_id": "base:homebase", "item_id": "pistol"})
	await _wait_frames(10)


## Der Pfeil faengt nichts: Unter seinem Kasten wird dasselbe Steuerelement getroffen wie ohne Pfeil.
func _check_click_through() -> void:
	var rect: Rect2 = _arrow.call("get_arrow_rect")
	var point: Vector2 = rect.get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion)
	await process_frame
	await process_frame
	var with_arrow: Control = root.gui_get_hovered_control()
	_check(with_arrow != _arrow and (with_arrow == null or not _arrow.is_ancestor_of(with_arrow)), "A1: unter dem Pfeil wird nicht der Pfeil getroffen: " + str(with_arrow))
	_arrows.call("set_enabled", false)
	await process_frame
	root.push_input(motion)
	await process_frame
	await process_frame
	var without_arrow: Control = root.gui_get_hovered_control()
	_arrows.call("set_enabled", true)
	_check(with_arrow == without_arrow, "A1: mit und ohne Pfeil wird dasselbe Steuerelement getroffen (%s / %s)" % [str(with_arrow), str(without_arrow)])
	_check(with_arrow != null, "A1: unter dem Pfeil liegt ein echtes Steuerelement (Eingabe geht hindurch)")
	await _wait_hint("equip_weapon")


func _check(value: bool, label: String) -> bool:
	if value:
		_passed += 1
		print("PASS: ", label)
	else:
		_failed += 1
		printerr("FAIL: ", label)
	return value
