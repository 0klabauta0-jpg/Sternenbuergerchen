extends SceneTree

const PRESENTER := preload("res://scripts/ui/selected_fireteam_decision_presenter.gd")

var _checks := 0
var _failures: PackedStringArray = []


func _initialize() -> void:
	var raw := "NEXT LOS/RANGE KORRIGIEREN | WHY KEIN ZIEL"
	var snapshot: Dictionary = PRESENTER.build_mission_control_snapshot(raw)
	var visible_line := String(snapshot.get("visible_line", ""))
	_check(visible_line == "POSITION AENDERN | KEIN ZIEL", "Mission Control uses one compact German action line")
	_check(not _contains_word(visible_line, "NEXT"), "Mission Control hides NEXT")
	_check(not _contains_word(visible_line, "WHY"), "Mission Control hides WHY")
	_check(not visible_line.contains("NO FIRE"), "Mission Control does not promote NO FIRE debug language")
	_check(String(snapshot.get("raw_decision_line", "")) == raw, "Raw decision evidence stays unchanged")
	_check(bool(snapshot.get("read_only", false)), "Presenter is read-only")
	_check(not bool(snapshot.get("creates_command", true)), "Presenter creates no command")
	_check(not bool(snapshot.get("sets_multiplayer_truth", true)), "Presenter sets no multiplayer truth")
	_check(visible_line.length() <= 96, "Mission Control action line fits the bottom-dock budget")
	_check(PRESENTER.is_mission_control_action_line(visible_line), "New player action line keeps the readable Mission Control style")
	_check(not PRESENTER.is_mission_control_action_line("Kampf NO FIRE NO_LOS"), "Raw combat debug line does not claim player-action styling")
	_check(PRESENTER.is_raw_combat_diagnostic_line("Kampf NO FIRE NO_LOS | F4/E4 | COV OPEN RNG ?"), "Technical combat density line is recognized")
	_check(PRESENTER.is_raw_combat_diagnostic_line("F4/E4 | COV OPEN RNG ? LOS ? FLK ?"), "Token-only combat detail line is recognized")
	_check(not PRESENTER.is_raw_combat_diagnostic_line("Dropship wartet off-map"), "Mission state is not mistaken for combat diagnostics")

	if _failures.is_empty():
		print("TASK_1141 PASS (%d checks)" % _checks)
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _contains_word(text: String, word: String) -> bool:
	var regex := RegEx.new()
	regex.compile("(^|[^A-Za-z])%s([^A-Za-z]|$)" % word)
	return regex.search(text) != null


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
