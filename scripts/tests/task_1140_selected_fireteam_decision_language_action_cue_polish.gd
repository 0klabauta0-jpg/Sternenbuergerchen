extends SceneTree

const PRESENTER := preload("res://scripts/ui/selected_fireteam_decision_presenter.gd")

var _checks := 0
var _failures: PackedStringArray = []


func _initialize() -> void:
	var raw_decision := "NEXT LOS/RANGE KORRIGIEREN | WHY KEIN ZIEL"
	var raw_loop := "NEXT LOS/RANGE KORRIGIEREN -> HOLD / ADV / BACK"
	var raw_polish := "2ND HOLD Defend | ADV Move | BACK Return | GO bestaetigen"
	var snapshot: Dictionary = PRESENTER.build_snapshot(raw_decision, raw_loop, raw_polish, "")
	var lines: PackedStringArray = PackedStringArray(snapshot.get("visible_lines", PackedStringArray()))
	var visible_text := "\n".join(lines)

	_check(bool(snapshot.get("read_only", false)), "Presenter is explicitly read-only")
	_check(not bool(snapshot.get("creates_navigation", true)), "Presenter creates no navigation")
	_check(not bool(snapshot.get("creates_command", true)), "Presenter creates no command")
	_check(not bool(snapshot.get("sets_gameplay_truth", true)), "Presenter sets no gameplay truth")
	_check(lines.size() <= 3, "Visible decision block uses at most three lines")
	_check(visible_text.contains("NAECHSTER GRIFF:"), "Visible decision names the next player action")
	_check(visible_text.contains("GRUND:"), "Visible decision explains the reason")
	_check(visible_text.contains("OPTIONEN:"), "Visible decision exposes follow-up choices")
	for raw_token in ["NEXT", "WHY", "HOLD", "ADV", "BACK", "2ND", "Defend", "Move", "Return"]:
		_check(not _contains_word(visible_text, raw_token), "Visible decision hides raw token %s" % raw_token)
	_check(String(snapshot.get("raw_decision_line", "")) == raw_decision, "Raw NEXT/WHY evidence stays unchanged")
	_check(String(snapshot.get("raw_loop_line", "")) == raw_loop, "Raw loop evidence stays unchanged")
	_check(String(snapshot.get("raw_polish_line", "")) == raw_polish, "Raw polish evidence stays unchanged")
	var tooltip := PRESENTER.build_detail_tooltip(snapshot)
	_check(tooltip.contains(raw_decision), "Tooltip retains raw decision evidence")
	_check(tooltip.contains(raw_loop), "Tooltip retains raw loop evidence")

	if _failures.is_empty():
		print("TASK_1140 PASS (%d checks)" % _checks)
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
