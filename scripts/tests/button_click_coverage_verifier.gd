extends SceneTree
## Bedienung (Meldung 25.11.: "Auftrag annehmen" und andere Knoepfe greifen schwer, Klick nicht deckungsgleich mit dem Knopf).
## Kopflos, echte Heimatbasis (Spielstart Kampagne). Fuer jeden sichtbaren, freigegebenen Knopf der Heimatbasis-Ansichten
## (linke Leiste, Basis, Personal, Trupp & Ausruestung, Flugdeck, Smart Mobile mit aufgeklapptem Auftrag, Sternkarte)
## werden NEUN Punkte (Mitte, vier Ecken, vier Kantenmitten, je 15 % eingerueckt) angefahren; gefragt wird, welches
## Bedienelement die Maus dort bekommt (Viewport.gui_get_hovered_control nach einer echten Mausbewegung).
## Danach wird derselbe Knopf ueber 20 Aktualisierungs-Takte plus 1,5 s Wartezeit beobachtet: bleibt Knoten und Rechteck gleich?
## Rot nur, wenn ein Knopf weniger als 7 von 9 Punkten trifft (oder die Auftragskarten ohne Grund neu gebaut werden).
const START = preload("res://scripts/meta/game_start_contract.gd")
const FLOW: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const GRID: Array = [0.15, 0.5, 0.85]
const MIN_HITS := 7
const TICKS := 20
const MODES: Array = ["base", "personnel", "squad", "mission", "jobs", "jobs_open", "map"]
var passed := 0
var failed := 0
var _flagged: Array = []
var _seen: Dictionary = {}
var _total_probed := 0
var _unstable: Array = []


func _init() -> void:
	call_deferred("_run")


func _check(value: bool, label: String) -> void:
	if value:
		passed += 1
	else:
		failed += 1
	print(("PASS " if value else "FAIL ") + label)


func _collect(node: Node, result: Array) -> void:
	for child: Node in node.get_children():
		if child is BaseButton:
			result.append(child)
		_collect(child, result)


## Sichtbarer Teil eines Knopfes: Rechteck, beschnitten an allen Vorfahren, die ihren Inhalt abschneiden (Scroll-Behaelter).
func _clip_rect(control: Control) -> Rect2:
	var rect: Rect2 = control.get_global_rect()
	var parent: Node = control.get_parent()
	while parent != null:
		if parent is Control and (parent as Control).clip_contents:
			rect = rect.intersection((parent as Control).get_global_rect())
			if rect.size.x <= 0.0 or rect.size.y <= 0.0:
				return Rect2()
		parent = parent.get_parent()
	return rect


func _short_path(node: Node) -> String:
	var parts: PackedStringArray = String(node.get_path()).split("/")
	var start: int = maxi(0, parts.size() - 3)
	return "/".join(parts.slice(start))


func _describe(hit: Control) -> String:
	if hit == null:
		return "nichts (kein Element unter der Maus)"
	var script_name := ""
	var script: Variant = hit.get_script()
	if script is Script:
		script_name = (script as Script).resource_path.get_file()
	return "%s [%s %s filter %d]" % [_short_path(hit), hit.get_class(), script_name, hit.mouse_filter]


func _hover(point: Vector2) -> Control:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion)
	var hit: Control = root.gui_get_hovered_control()
	if hit == null:
		await process_frame
		hit = root.gui_get_hovered_control()
	return hit


func _probe(button: BaseButton, tag: String) -> void:
	var key: String = tag.get_slice(" ", 0) + "|" + String(button.get_path())
	if _seen.has(key):
		return
	_seen[key] = true
	var rect: Rect2 = _clip_rect(button)
	if rect.size.x < 8.0 or rect.size.y < 8.0:
		return
	_total_probed += 1
	var window_rect := Rect2(Vector2.ZERO, Vector2(root.size))
	var hits := 0
	var blockers: Dictionary = {}
	for fy: float in GRID:
		for fx: float in GRID:
			var point: Vector2 = rect.position + Vector2(rect.size.x * fx, rect.size.y * fy)
			if not window_rect.has_point(point):
				blockers["ausserhalb des Fensters"] = int(blockers.get("ausserhalb des Fensters", 0)) + 1
				continue
			var hit: Control = await _hover(point)
			if hit != null and (hit == button or button.is_ancestor_of(hit)):
				hits += 1
			else:
				var name_of_blocker: String = _describe(hit)
				blockers[name_of_blocker] = int(blockers.get(name_of_blocker, 0)) + 1
	if hits < 9:
		var line := "AUFFAELLIG %s %s \"%s\" Rechteck %s Treffer %d/9" % [tag, _short_path(button), (button as Button).text if button is Button else "", str(rect), hits]
		for name_of_blocker: String in blockers:
			line += " | faengt ab (%d): %s" % [int(blockers[name_of_blocker]), name_of_blocker]
		_flagged.append(line)
		print(line)
	# Karten-Markierungen (PlanetSite_*) sind kleine, bauartbedingt dicht liegende Punkte: nur aufgelistet, nicht rot.
	if hits < MIN_HITS and not String(button.name).begins_with("PlanetSite_"):
		_check(false, "%s: Knopf %s trifft nur %d von 9 Punkten (Mindest %d)" % [tag, _short_path(button), hits, MIN_HITS])


func _snapshot(list: Array) -> Dictionary:
	var result: Dictionary = {}
	for button: BaseButton in list:
		result[button.get_instance_id()] = {"path": _short_path(button), "rect": button.get_global_rect()}
	return result


func _compare(before: Dictionary, phase: String, tag: String) -> void:
	for id: int in before:
		var entry: Dictionary = before[id]
		var now: Object = instance_from_id(id)
		var problem := ""
		if now == null or not is_instance_valid(now):
			problem = "Knoten wurde freigegeben/neu gebaut"
		elif (now as Node).is_queued_for_deletion() or not (now as Node).is_inside_tree():
			problem = "Knoten wurde aus dem Baum genommen"
		else:
			var rect_now: Rect2 = (now as Control).get_global_rect()
			var rect_then: Rect2 = entry.rect
			if rect_now.position.distance_to(rect_then.position) > 0.5 or rect_now.size.distance_to(rect_then.size) > 0.5:
				problem = "Rechteck %s -> %s" % [str(rect_then), str(rect_now)]
		if not problem.is_empty():
			var line := "INSTABIL %s %s (%s): %s" % [tag, String(entry.path), phase, problem]
			_unstable.append(line)
			print(line)


func _settle(seconds: float) -> void:
	await create_timer(seconds).timeout
	for i in 3:
		await process_frame


func _enter_mode(presenter: Control, screen: Node, mode: String) -> void:
	if mode == "jobs_open":
		var board: Control = presenter.get("_job_board")
		var ids: Array = Array(board.get("_visible_job_ids"))
		if not ids.is_empty() and not bool(board.get("_details_expanded")):
			board.call("_toggle_job_details", String(ids[0]))
		await _settle(0.4)
		return
	presenter.call("_navigate_from_sidebar", mode)
	await _settle(0.5)


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = Vector2i(1920, 1080)
	START.request_start(self, "campaign", "new")
	var flow: Node = FLOW.instantiate()
	root.add_child(flow)
	for i in 10:
		await process_frame
	var screen: Node = flow.get_node("HomebaseScreen")
	var presenter: Control = screen.get("_operations_presenter")
	presenter.call("set_interface_settings_path_for_tests", "user://nav_groups_fixture_click_coverage.cfg")
	presenter.call("set_nav_group_open", "base", true)
	presenter.call("set_nav_group_open", "mission", true)
	var board: Control = presenter.get("_job_board")
	for resolution: Vector2i in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		root.size = resolution
		root.content_scale_size = resolution
		for i in 10:
			await process_frame
		for mode: String in MODES:
			var tag := "%dx%d %s" % [resolution.x, resolution.y, mode]
			await _enter_mode(presenter, screen, mode)
			var buttons: Array = []
			_collect(screen, buttons)
			var live: Array = []
			var ignored := 0
			for button: BaseButton in buttons:
				if not button.is_visible_in_tree() or button.disabled:
					continue
				if button.mouse_filter == Control.MOUSE_FILTER_IGNORE:
					ignored += 1
					continue
				live.append(button)
			var before_count := _total_probed
			for button: BaseButton in live:
				await _probe(button, tag)
			print("MODUS %s: %d sichtbare freigegebene Knoepfe, %d geprueft (neu), %d mit mouse_filter IGNORE" % [tag, live.size(), _total_probed - before_count, ignored])
			if mode == "jobs_open":
				var accept: Button = board.get("_accept")
				var accept_visible: bool = accept != null and accept.is_visible_in_tree()
				_check(accept_visible, "%s: AcceptJob ist sichtbar (Auftrag aufgeklappt)" % tag)
				if accept_visible:
					var dock := Rect2()
					var base_node: Object = presenter.get("_base")
					if base_node != null and base_node.has_method("get_command_dock_rect"):
						dock = base_node.call("get_command_dock_rect")
					print("ACCEPT %s Rechteck %s, Fenster %s, Kommandoleiste %s, Smart-Mobile-Tafel %s" % [tag, str(accept.get_global_rect()), str(Vector2(root.size)), str(dock), str(board.get_global_rect())])
			# Beobachtung ueber Aktualisierungs-Takte.
			var before: Dictionary = _snapshot(live)
			var rebuilds_before: int = int(board.get("_job_list_rebuilds"))
			for i in TICKS:
				presenter.call("refresh")
				await process_frame
			_compare(before, "nach %d Takten" % TICKS, tag)
			await _settle(1.5)
			_compare(before, "nach 1,5 s Wartezeit", tag)
			var rebuilds: int = int(board.get("_job_list_rebuilds")) - rebuilds_before
			if mode.begins_with("jobs"):
				print("TAKT %s: Auftragskarten %d-mal neu gebaut" % [tag, rebuilds])
				_check(rebuilds == 0, "%s: Auftragskarten werden ohne Aenderung der Daten nicht neu gebaut (%d)" % [tag, rebuilds])
			_check(not live.is_empty() or mode == "map", "%s: es gibt pruefbare Knoepfe (%d)" % [tag, live.size()])
	print("ZUSAMMENFASSUNG: %d Knoepfe (je Aufloesung und Ansicht einmal) geprueft, %d unter 9/9, %d instabile Beobachtungen" % [_total_probed, _flagged.size(), _unstable.size()])
	for line: String in _flagged:
		print("LISTE " + line)
	for line: String in _unstable:
		print("LISTE " + line)
	flow.queue_free()
	await process_frame
	print("BUTTON_CLICK_COVERAGE passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)
