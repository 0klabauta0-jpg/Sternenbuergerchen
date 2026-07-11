class_name SelectedFireteamDecisionPresenter
extends RefCounted


static func build_snapshot(
	raw_decision_line: String,
	raw_loop_line: String = "",
	raw_polish_line: String = "",
	raw_combat_line: String = ""
) -> Dictionary:
	var decision_line := raw_decision_line.strip_edges()
	var next_text := _extract_segment(decision_line, "NEXT", "WHY")
	var reason_text := _extract_segment(decision_line, "WHY", "")
	var visible_lines := PackedStringArray()
	if not next_text.is_empty():
		visible_lines.append("NAECHSTER GRIFF: %s" % _player_phrase(next_text))
	if not reason_text.is_empty():
		visible_lines.append("GRUND: %s" % _player_phrase(reason_text))
	if _contains_action_choices(raw_loop_line) or _contains_action_choices(raw_polish_line):
		visible_lines.append("OPTIONEN: Halten | Vorruecken | Zurueck")
	elif visible_lines.is_empty() and not raw_loop_line.strip_edges().is_empty():
		visible_lines.append(_player_phrase(raw_loop_line))
	if visible_lines.size() > 3:
		visible_lines.resize(3)
	return {
		"read_only": true,
		"creates_navigation": false,
		"creates_command": false,
		"sets_gameplay_truth": false,
		"visible_lines": visible_lines,
		"raw_decision_line": raw_decision_line,
		"raw_loop_line": raw_loop_line,
		"raw_polish_line": raw_polish_line,
		"raw_combat_line": raw_combat_line,
	}


static func build_detail_tooltip(snapshot: Dictionary) -> String:
	var raw_lines := PackedStringArray()
	for key in ["raw_decision_line", "raw_loop_line", "raw_polish_line", "raw_combat_line"]:
		var line := String(snapshot.get(key, "")).strip_edges()
		if not line.is_empty() and not raw_lines.has(line):
			raw_lines.append(line)
	if raw_lines.is_empty():
		return ""
	return "Diagnose\n%s" % "\n".join(raw_lines)


static func _extract_segment(line: String, marker: String, end_marker: String) -> String:
	var marker_with_space := "%s " % marker
	var start := line.find(marker_with_space)
	if start < 0:
		return ""
	start += marker_with_space.length()
	var end := line.length()
	if not end_marker.is_empty():
		var separator := " | %s " % end_marker
		var found_end := line.find(separator, start)
		if found_end >= 0:
			end = found_end
	return line.substr(start, end - start).strip_edges()


static func _contains_action_choices(line: String) -> bool:
	var padded := " %s " % line
	return padded.contains(" HOLD ") or padded.contains(" ADV ") or padded.contains(" BACK ")


static func _player_phrase(raw_phrase: String) -> String:
	var phrase := raw_phrase.strip_edges()
	var replacements := {
		"LOS/RANGE KORRIGIEREN": "LOS/Reichweite korrigieren",
		"HIT LESEN / DEFEND": "Treffer auswerten / halten",
		"HALTEN / FLANKE": "Halten / Flanke vorbereiten",
		"HALTEN ODER NEU PLANEN": "Halten oder neu planen",
		"KEIN ZIEL": "Kein Ziel erfasst",
		"COOLDOWN": "Waffe noch nicht bereit",
		"FRIENDLY FIRE": "Eigenbeschuss-Risiko",
		"NO FIRE": "Kein Feuer moeglich",
	}
	if replacements.has(phrase):
		return String(replacements[phrase])
	phrase = phrase.replace("2ND ", "Danach: ")
	phrase = phrase.replace("HOLD", "Halten")
	phrase = phrase.replace("ADV", "Vorruecken")
	phrase = phrase.replace("BACK", "Zurueck")
	phrase = phrase.replace("Defend", "Halten")
	phrase = phrase.replace("Move", "Bewegen")
	phrase = phrase.replace("Return", "Zurueck")
	phrase = phrase.replace("GO bestaetigen", "mit GO bestaetigen")
	return phrase
