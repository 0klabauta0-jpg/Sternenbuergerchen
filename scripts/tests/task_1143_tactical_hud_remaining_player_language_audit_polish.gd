extends SceneTree

const PRESENTER := preload("res://scripts/ui/tactical_hud_language_presenter.gd")

var _checks := 0
var _failures: PackedStringArray = []


func _initialize() -> void:
	_check(PRESENTER.mission_header("") == "#15 EINSATZLAGE", "Mission header uses German player language")
	_check(PRESENTER.event_log_header() == "#19 EREIGNISSE", "Event log header uses German player language")
	_check(PRESENTER.selected_filter_label() == "AUSW.", "Selected-only filter uses German abbreviation")

	var identity_raw := "CUE WAIT: Route pruefen | live fireteam deployment"
	var identity: Dictionary = PRESENTER.identity_snapshot(identity_raw)
	var identity_text := String(identity.get("display_text", ""))
	_check(identity_text == "NAECHSTER SCHRITT: Route pruefen | Fireteam im Einsatz", "Identity body translates cue and deployment")
	_check(String(identity.get("raw_text", "")) == identity_raw, "Identity raw text stays unchanged")

	var pressure_raw := "CONTACT PRESSURE: Position korrigieren"
	var pressure: Dictionary = PRESENTER.event_text_snapshot(pressure_raw)
	_check(String(pressure.get("display_text", "")) == "KONTAKTDRUCK: Position korrigieren", "Contact pressure uses player language")
	_check(String(pressure.get("raw_text", "")) == pressure_raw, "Contact pressure raw text stays unchanged")
	_check(String(PRESENTER.event_text_snapshot("CONTACT FIRE: Treffer").get("display_text", "")) == "FEUERKONTAKT: Treffer", "Contact fire uses player language")

	_check(PRESENTER.stance_mode_text("OFF", true) == "OFF AKTIV", "Live stance uses AKTIV")
	_check(PRESENTER.stance_mode_text("VORS", false) == "VORS", "Inactive stance keeps its mode")
	for forbidden in ["LIVE TACTICAL GRID", "Realtime insertion feed", "live fireteam deployment", "EVENT LOG", "CONTACT PRESSURE", "OFF LIVE"]:
		var visible := "%s\n%s\n%s\n%s" % [PRESENTER.mission_header(""), identity_text, PRESENTER.event_log_header(), PRESENTER.stance_mode_text("OFF", true)]
		_check(not visible.contains(forbidden), "Visible HUD hides %s" % forbidden)
	_check(bool(identity.get("read_only", false)) and bool(pressure.get("read_only", false)), "Language snapshots are read-only")
	_check(not bool(pressure.get("mutates_event", true)) and not bool(pressure.get("sets_gameplay_truth", true)), "Event presenter does not mutate event or gameplay truth")

	if _failures.is_empty():
		print("TASK_1143 PASS (%d checks)" % _checks)
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
