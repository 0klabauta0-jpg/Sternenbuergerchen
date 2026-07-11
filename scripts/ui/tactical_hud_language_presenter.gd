class_name TacticalHudLanguagePresenter
extends RefCounted


static func mission_header(badge_text: String) -> String:
	var badge := badge_text.strip_edges()
	return "#15 EINSATZLAGE" if badge.is_empty() else "#15 EINSATZLAGE | %s" % badge


static func event_log_header() -> String:
	return "#19 EREIGNISSE"


static func selected_filter_label() -> String:
	return "AUSW."


static func identity_snapshot(raw_text: String) -> Dictionary:
	var display := raw_text.strip_edges()
	display = display.replace("Realtime insertion feed", "Einsatzdaten in Echtzeit")
	display = display.replace("live fireteam deployment", "Fireteam im Einsatz")
	display = display.replace("CUE WAIT:", "NAECHSTER SCHRITT:")
	display = display.replace("CUE DONE:", "ROUTE FERTIG:")
	display = display.replace("CUE USE:", "AKTION:")
	display = display.replace(" | NEXT ", " | WEITER ")
	return {
		"display_text": display,
		"raw_text": raw_text,
		"read_only": true,
		"sets_gameplay_truth": false,
	}


static func event_text_snapshot(raw_text: String) -> Dictionary:
	var display := raw_text.strip_edges()
	display = display.replace("CONTACT PRESSURE:", "KONTAKTDRUCK:")
	display = display.replace("CONTACT FIRE:", "FEUERKONTAKT:")
	if display.begins_with("CONTACT:"):
		display = display.replace("CONTACT:", "KONTAKT:")
	display = display.replace("FIREFIGHT STATUS", "GEFECHTSLAGE")
	return {
		"display_text": display,
		"raw_text": raw_text,
		"read_only": true,
		"mutates_event": false,
		"sets_gameplay_truth": false,
	}


static func stance_mode_text(mode_text: String, is_live: bool) -> String:
	return "%s AKTIV" % mode_text.strip_edges() if is_live else mode_text.strip_edges()
