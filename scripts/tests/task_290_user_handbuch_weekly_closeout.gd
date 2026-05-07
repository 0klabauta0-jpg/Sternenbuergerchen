extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_290_user_handbuch_weekly_closeout.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const MANUAL_PATH: String = "res://docs/User-Handbuch.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_290 User Handbuch Weekly Closeout ===")
	_test_task_status_docs()
	_test_manual_required_sections()
	_test_manual_player_facing_scope()
	_test_confirmed_gameplay_topics()
	_test_known_limitations_are_explicit()
	_test_markdown_links_resolve()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_task_status_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "Task file marks TASK_290 implemented")
	_assert(not task_text.contains("- [ ]"), "Task checklist is complete")
	_assert(status_text.contains("### TASK_290 - User Handbuch Weekly Closeout") and status_text.contains("- Status: implementiert"), "Implementation status marks TASK_290 implemented")
	_assert(roadmap_text.contains("TASK_290 - User Handbuch Weekly Closeout (implementiert)"), "Roadmap marks TASK_290 implemented")
	_assert(FileAccess.file_exists(MANUAL_PATH), "User manual exists")


func _test_manual_required_sections() -> void:
	var manual_text: String = _read_text(MANUAL_PATH)
	for heading in [
		"# SternenBuergerchen - User-Handbuch",
		"## Kurzueberblick",
		"## Hauptmenue",
		"## Erster Start und Roster",
		"## Homebase, FOB und Dropship",
		"## Mission Map und Missionsstart",
		"## Kamera und Auswahl",
		"## Befehle und Fireteam Leader",
		"## Bewegungsstile",
		"## NPCs, Gegner und Gefechtsverhalten",
		"## Waffen, Ausruestung und Gewicht",
		"## Spezialrollen und Medic-Regeln",
		"## Terrain, Hoehen und Deckung",
		"## Fog of War und Sichtmodi",
		"## Feedback, Bubbles und Gedanken",
		"## Help-Popups",
		"## Audio und visuelle Rueckmeldungen",
		"## Multiplayer",
		"## Editor",
		"## Einstellungen",
		"## Troubleshooting",
		"## Noch in Arbeit / bekannte Einschraenkungen",
		"## Glossar",
		"## Pflegehinweise",
	]:
		_assert(manual_text.contains(heading), "Manual contains heading %s" % heading)


func _test_manual_player_facing_scope() -> void:
	var manual_text: String = _read_text(MANUAL_PATH)
	_assert(manual_text.length() > 12000, "Manual is substantial enough for a user handbook")
	_assert(manual_text.contains("aus Spielersicht"), "Manual states player-facing scope")
	_assert(manual_text.contains("Die UI zeigt") and manual_text.contains("nicht die Gameplay-Wahrheit"), "Manual does not make UI state authoritative")
	_assert(not manual_text.contains("TASK_"), "Manual does not require internal task IDs")
	_assert(not manual_text.to_lower().contains("todo"), "Manual has no TODO placeholder")
	_assert(not manual_text.to_lower().contains("tbd"), "Manual has no TBD placeholder")
	_assert(not manual_text.contains("UI entscheidet"), "Manual does not describe UI as decision maker")


func _test_confirmed_gameplay_topics() -> void:
	var manual_text: String = _read_text(MANUAL_PATH)
	for token in [
		"Einzelspieler",
		"Multiplayer",
		"Host/Join",
		"Editor",
		"Einstellungen",
		"local_player",
		"Move",
		"Take",
		"Defend",
		"Fireteam Leader",
		"Rush",
		"Bounding",
		"Caterpillar",
		"Mindestabstand",
		"LOS",
		"Deckung",
		"smg",
		"rifle",
		"sniper",
		"rocket_launcher",
		"medictool",
		"tile_range",
		"orthogonal benachbarten Terrain-Tile",
		"height_level",
		"object_height",
		"slope",
		"cliff",
		"sand",
		"known_terrain",
		"unexplored_blackout",
		"Sprechblasen",
		"Help-Modi",
		"Audio",
		"Air Asset",
		"Map-Download",
		"Consent",
	]:
		_assert(manual_text.contains(token), "Manual covers %s" % token)


func _test_known_limitations_are_explicit() -> void:
	var manual_text: String = _read_text(MANUAL_PATH)
	var limitation_section: String = _section_text(manual_text, "## Noch in Arbeit / bekannte Einschraenkungen", "## Glossar")
	_assert(not limitation_section.is_empty(), "Known limitations section can be extracted")
	for token in [
		"Zwei-Instanzen-LAN",
		"Full-HD",
		"AirAsset-Fairness",
		"Bubble-Laerm",
		"Audio/VFX-Gefuehl",
		"Drag-and-drop-Feeling",
		"Cover-/Security-Defaults",
		"Breakout-Diagnosen",
		"Runtime-APIs",
	]:
		_assert(limitation_section.contains(token), "Known limitations mention %s" % token)
	_assert(limitation_section.contains("nicht als final poliert versprochen"), "Limitations are clearly not final promises")


func _test_markdown_links_resolve() -> void:
	var manual_text: String = _read_text(MANUAL_PATH)
	var link_regex := RegEx.new()
	var compile_error := link_regex.compile("\\[[^\\]]+\\]\\(([^)]+)\\)")
	_assert(compile_error == OK, "Markdown link regex compiles")
	var checked_links: int = 0
	for result in link_regex.search_all(manual_text):
		var target: String = String(result.get_string(1)).strip_edges()
		if target.begins_with("#") or target.begins_with("http://") or target.begins_with("https://") or target.begins_with("mailto:"):
			continue
		var path_without_anchor: String = target.split("#")[0]
		var resolved_path: String = "res://docs/%s" % path_without_anchor
		checked_links += 1
		_assert(FileAccess.file_exists(resolved_path), "Manual markdown link resolves: %s" % target)
	_assert(checked_links >= 5, "Manual maintenance links are checked")


func _section_text(text: String, start_heading: String, next_heading: String) -> String:
	var start_index: int = text.find(start_heading)
	if start_index < 0:
		return ""
	var end_index: int = text.find(next_heading, start_index + start_heading.length())
	if end_index < 0:
		return text.substr(start_index)
	return text.substr(start_index, end_index - start_index)


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
