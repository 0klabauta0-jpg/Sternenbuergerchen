extends RefCounted
## Entscheidungen der Rueckfrage vor dem Rueckzug (Kampagnenauftrag, Knopf "Abheben" / "Zur Heimatbasis"). Reine statische Hilfen ohne
## Zustand, damit sie ohne Szene pruefbar sind (scripts/tests/campaign_return_prompt_verifier.gd); der Missions-Controller benutzt sie.
const FALLBACK_STEP_NAME := "ein weiterer Auftragsschritt"


## Ein Name ist lesbar, wenn er nicht leer ist, keine rohe Kennung mit Unterstrich traegt und nicht nur die Schrittkennung wiederholt.
static func is_readable_name(name: String, step_id: String = "") -> bool:
	var text: String = name.strip_edges()
	return not text.is_empty() and not text.contains("_") and text != step_id


## Anzeigename eines Auftragsschritts fuer Rueckfrage und Meldungen, nie eine rohe Kennung wie "clear_outpost".
## Reihenfolge: 1. Anzeigename der Benutzen-Stelle des Schritts (binding_name), 2. Schritt mit Wache: "<Wachenname> ausschalten",
## 3. Ziel des Briefings mit der Schrittkennung oder dem Zielmarker des Schritts (ohne freiwillige Ziele), 4. deutscher Ersatztext.
## scenario: Woerterbuch mit enemy_groups, briefing, vertical_slice (Felder des MissionScenarioData).
static func step_display_name(step_id: String, binding_name: String, scenario: Dictionary) -> String:
	if is_readable_name(binding_name, step_id):
		return binding_name.strip_edges()
	var flow_step: Dictionary = {}
	for entry in Array(Dictionary(scenario.get("vertical_slice", {})).get("flow_steps", [])):
		if String(Dictionary(entry).get("step_id", "")) == step_id:
			flow_step = Dictionary(entry)
			break
	var group_id: String = String(flow_step.get("enemy_group_id", ""))
	if not group_id.is_empty():
		for group in Array(scenario.get("enemy_groups", [])):
			if String(Dictionary(group).get("group_id", "")) == group_id:
				var group_name: String = String(Dictionary(group).get("display_name", "")).strip_edges()
				if is_readable_name(group_name):
					return "%s ausschalten" % group_name
	var objectives: Array = Array(Dictionary(scenario.get("briefing", {})).get("objectives", []))
	for key in [step_id, String(flow_step.get("target_marker_id", ""))]:
		if String(key).is_empty():
			continue
		for objective in objectives:
			var text: String = String(Dictionary(objective).get("text", "")).strip_edges()
			if String(Dictionary(objective).get("target_id", "")) == String(key) and is_readable_name(text) and not text.begins_with("Freiwillig"):
				return text
	return FALLBACK_STEP_NAME


## Nur das Schiff des Auftrags (identity.craft_id) darf den Rueckkehr-Schritt setzen; ein anderes Schiff hebt ab, ohne den Auftrag zu beruehren.
## Ohne Schiffskennung im Auftrag bleibt das alte Verhalten (jedes Schiff); ohne gedrueckte Kennung ist es nie das Auftragsschiff.
static func is_job_craft(identity: Dictionary, craft_id: String) -> bool:
	if craft_id.strip_edges().is_empty():
		return false
	var job_craft: String = String(identity.get("craft_id", "")).strip_edges()
	return job_craft.is_empty() or job_craft == craft_id.strip_edges()


## Kennzeichen der offenen Schritte; aendern sie sich zwischen zwei Druecken, beginnt die Rueckfrage neu.
static func open_signature(open_step_ids: Array) -> String:
	var parts := PackedStringArray()
	for id in open_step_ids:
		parts.append(String(id))
	return "|".join(parts)
