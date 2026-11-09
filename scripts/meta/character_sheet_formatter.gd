class_name CharacterSheetFormatter
extends RefCounted

const UNIT_PROFILE_MATH_SCRIPT: GDScript = preload("res://scripts/npc/unit_profile_math.gd")
const UNIT_TRAIT_SCRIPT: GDScript = preload("res://scripts/npc/unit_trait.gd")
const WEAPON_DATA_SCRIPT: GDScript = preload("res://scripts/core/weapon_data.gd")
const ROSTER_RELATIONSHIP_MODEL_SCRIPT: GDScript = preload("res://scripts/meta/roster_relationship_model.gd")
const FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_behavior_resolver.gd")
const NPC_RANK_BADGE_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/npc_rank_badge_resolver.gd")
const COPY: GDScript = preload("res://scripts/meta/character_sheet_copy.gd")
const CORE_ORDER: Array = [
	["accuracy", "Accuracy"],
	["speed", "Speed"],
	["toughness", "Toughness"],
	["awareness", "Awareness"],
	["recognition", "Recognition"],
	["stealth", "Stealth"],
	["discipline", "Discipline"],
	["leadership", "Leadership"],
]
const BEHAVIOR_ORDER: Array = [
	["initiative", "Initiative"],
	["order_fidelity", "Order Fidelity"],
	["signature_control", "Signature Control"],
	["contact_stability", "Contact Stability"],
	["autonomy", "Autonomy"],
]
const COMMUNICATION_ORDER: Array = [
	["speech_quality", "Speech Quality"],
	["speech_quantity", "Speech Quantity"],
]
const PLATFORM_ORDER: Array = [
	["ground_vehicle_handling", "Ground Vehicle Handling"],
	["dropship_piloting", "Dropship Piloting"],
	["freighter_piloting", "Freighter Piloting"],
	["fighter_piloting", "Fighter Piloting"],
]
const METHOD_ORDER: Array = [
	["silent", "Silent"],
	["rapid", "Rapid"],
	["steady", "Steady"],
	["watchful", "Watchful"],
	["command", "Command"],
]
const FUNCTION_ORDER: Array = [
	["pathfinder", "Pathfinder"],
	["scout", "Scout"],
	["overwatch", "Overwatch"],
	["sentinel", "Sentinel"],
	["coordinator", "Coordinator"],
	["infiltrator", "Infiltrator"],
	["insertion_pilot", "Insertion Pilot"],
	["transport_pilot", "Transport Pilot"],
	["cargo_runner", "Cargo Runner"],
	["route_master", "Route Master"],
	["interceptor", "Interceptor"],
	["strike_pilot", "Strike Pilot"],
	["escort_pilot", "Escort Pilot"],
]

const VALUE_HELP_TEXTS: Dictionary = {
	"skill_values.accuracy": "Treffsicherheit beeinflusst die Trefferchance. Gespeicherte wirksame Werte enthalten bereits die berücksichtigten Eigenschaften.",
	"skill_values.speed": "Tempo beeinflusst Bewegung und Initiative sowie Aufklärung und Fahrzeugwerte.",
	"skill_values.toughness": "Belastbarkeit senkt den erlittenen Schaden und fließt in Ruhe im Kontakt und Sicherung ein.",
	"skill_values.awareness": "Wahrnehmung fließt in Initiative, Aufklärung, Fahrzeugwerte und mehrere Einsatzeignungen ein.",
	"skill_values.recognition": "Erkennen hilft beim Lesen von Kontakten. Es fließt in Befehlstreue, Selbstständigkeit und Koordination ein.",
	"skill_values.stealth": "Tarnung fließt in Unauffälligkeit, leise Arbeitsweise, Aufklärung und Infiltration ein.",
	"skill_values.discipline": "Disziplin fließt in Befehlstreue, Unauffälligkeit, Ruhe im Kontakt und Fahrzeugwerte ein.",
	"skill_values.leadership": "Führung fließt in Kommunikation, Initiative, Selbstständigkeit und Koordination ein.",
	"communication_values.speech_quality": "Meldequalität beschreibt verständliche Ansagen. Ohne Vorgabe wird sie aus Führung und Erkennen sowie Rollenanteilen abgeleitet.",
	"communication_values.speech_quantity": "Sprechhäufigkeit beschreibt, wie viel gemeldet wird. Weniger unterstützt eine leise Arbeitsweise.",
	"behavior_axes.initiative": "Ohne Vorgabe aus Tempo, Wahrnehmung und Führung abgeleitet; wirkt auf Bewegung und Fahrzeugwerte.",
	"behavior_axes.order_fidelity": "Ohne Vorgabe aus Disziplin, Erkennen und Meldequalität abgeleitet; fließt in die Befehlsausführung ein.",
	"behavior_axes.signature_control": "Ohne Vorgabe aus Tarnung, Disziplin und geringer Sprechhäufigkeit abgeleitet; beeinflusst Unauffälligkeit.",
	"behavior_axes.contact_stability": "Ohne Vorgabe aus Belastbarkeit, Disziplin und Wahrnehmung abgeleitet; stabilisiert Reaktionen im Kontakt.",
	"behavior_axes.autonomy": "Ohne Vorgabe aus Erkennen, Führung und Disziplin abgeleitet; beschreibt selbstständiges Arbeiten.",
	"platform_values.ground_vehicle_handling": "Bodenfahrzeugwert aus Tempo, Wahrnehmung, Erkennen, Disziplin und Verhalten, sofern keine Vorgabe gespeichert ist.",
	"platform_values.dropship_piloting": "Landefährenwert aus Wahrnehmung, Erkennen, Disziplin, Tempo, Kommunikation und Verhalten, sofern keine Vorgabe gespeichert ist.",
	"platform_values.freighter_piloting": "Frachterwert aus Belastbarkeit, Erkennen, Disziplin, Kommunikation und Verhalten, sofern keine Vorgabe gespeichert ist.",
	"platform_values.fighter_piloting": "Jägerwert aus Tempo, Treffsicherheit, Wahrnehmung, Disziplin und Verhalten, sofern keine Vorgabe gespeichert ist.",
}


static func build_sheet_blocks(profile, options: Dictionary = {}) -> Dictionary:
	if profile == null:
		return {
			"name": "No operator selected",
			"identity": "No profile loaded",
			"role": "Role: unavailable\nPrimary: unavailable",
			"status": "Status: waiting for selection",
			"skills": "Core: unavailable",
			"traits": "Behavior: unavailable",
			"loadout": "Loadout: unavailable",
			"bio": "Bio: unavailable",
		}

	var status_text: String = String(options.get("status_text", profile.status_text)).strip_edges()
	var loadout_text: String = String(options.get("loadout_text", profile.loadout_summary)).strip_edges()
	var identity_lines: PackedStringArray = []
	if not String(profile.short_description).strip_edges().is_empty():
		identity_lines.append(String(profile.short_description).strip_edges())
	if not String(profile.callsign).strip_edges().is_empty():
		identity_lines.append("Callsign: %s" % String(profile.callsign).strip_edges())
	var origin_bits: PackedStringArray = []
	if not String(profile.homeworld).strip_edges().is_empty():
		origin_bits.append(String(profile.homeworld).strip_edges())
	if int(profile.age_years) > 0:
		origin_bits.append("Age %d" % int(profile.age_years))
	if not origin_bits.is_empty():
		identity_lines.append(" | ".join(origin_bits))
	if identity_lines.is_empty():
		identity_lines.append("No profile notes recorded.")

	var role_lines: PackedStringArray = []
	role_lines.append("Role: %s" % _optional_text(String(profile.role_name), "Operator"))
	role_lines.append("Primary: %s" % _optional_text(String(profile.primary_specialty), _optional_text(String(profile.specialty_text), "Generalist")))
	if not String(profile.secondary_specialty).strip_edges().is_empty():
		role_lines.append("Secondary: %s" % String(profile.secondary_specialty).strip_edges())
	role_lines.append("Methods: %s" % _optional_text(String(profile.method_summary_text), "No method profile"))
	role_lines.append("Functions: %s" % _optional_text(String(profile.function_summary_text), "No role fit"))

	var status_lines: PackedStringArray = []
	status_lines.append("Status: %s" % _optional_text(status_text, "standing by"))
	status_lines.append("Effects: %s" % _optional_text(String(profile.combat_effect_summary_text), "Move +0% | Aim +0% | Conceal +0% | Stability +0%"))

	var skill_parts: PackedStringArray = []
	var skill_values: Dictionary = Dictionary(profile.skill_values)
	for entry in CORE_ORDER:
		var key: String = String(entry[0])
		var label: String = COPY.label(key)
		var value: float = float(skill_values.get(key, 0.0))
		skill_parts.append("%s %.2f %s" % [label, value, UNIT_PROFILE_MATH_SCRIPT.describe_value(value)])
	var skill_lines: PackedStringArray = ["Core: %s" % " | ".join(skill_parts.slice(0, 4))]
	if skill_parts.size() > 4:
		skill_lines.append("      %s" % " | ".join(skill_parts.slice(4, skill_parts.size())))

	var behavior_parts: PackedStringArray = []
	var behavior_axes: Dictionary = Dictionary(profile.behavior_axes)
	for entry in BEHAVIOR_ORDER:
		var key: String = String(entry[0])
		var label: String = COPY.label(key)
		behavior_parts.append("%s %.2f" % [label, float(behavior_axes.get(key, 0.0))])
	var trait_lines: PackedStringArray = []
	trait_lines.append("Traits: %s" % _optional_text(String(profile.trait_summary_text), "none"))
	trait_lines.append("Behavior: %s" % " | ".join(behavior_parts))

	var communication_values: Dictionary = Dictionary(profile.communication_values)
	var platform_values: Dictionary = Dictionary(profile.platform_values)
	var support_lines: PackedStringArray = []
	support_lines.append(
		"Comms: Quality %.2f | Volume %.2f" % [
			float(communication_values.get("speech_quality", 0.0)),
			float(communication_values.get("speech_quantity", 0.0)),
		]
	)
	var platform_parts: PackedStringArray = []
	for entry in PLATFORM_ORDER:
		var key: String = String(entry[0])
		var label: String = COPY.label(key)
		var value: float = float(platform_values.get(key, UNIT_PROFILE_MATH_SCRIPT.NOT_APPLICABLE))
		if value < 0.0:
			platform_parts.append("%s n/a" % label)
		else:
			platform_parts.append("%s %.2f" % [label, value])
	support_lines.append("Platform: %s" % " | ".join(platform_parts))
	support_lines.append("Loadout: %s" % _optional_text(loadout_text, "standard kit"))

	var bio_lines: PackedStringArray = []
	if not String(profile.biography_text).strip_edges().is_empty():
		bio_lines.append(String(profile.biography_text).strip_edges())
	else:
		bio_lines.append("No biography recorded.")
	if not String(profile.secondary_text).strip_edges().is_empty():
		bio_lines.append(String(profile.secondary_text).strip_edges())

	return {
		"name": String(profile.display_name),
		"identity": "\n".join(identity_lines),
		"role": "\n".join(role_lines),
		"status": "\n".join(status_lines),
		"skills": "\n".join(skill_lines),
		"traits": "\n".join(trait_lines),
		"loadout": "\n".join(support_lines),
		"bio": "Bio: %s" % "\n".join(bio_lines),
	}


static func build_sheet_view_model(profile, options: Dictionary = {}) -> Dictionary:
	if profile == null:
		return {
			"name": "No operator selected",
			"trait_text": "Keine Eigenschaften hinterlegt.",
			"trait_rows": [],
			"short_description": "Keine Kurzbeschreibung verfuegbar.",
			"core_rows": _build_scored_rows({}, CORE_ORDER, "skill_values", "character_sheet.core"),
			"communication_rows": _build_value_rows({}, COMMUNICATION_ORDER, "communication_values", "character_sheet"),
			"platform_rows": [],
			"role_loadout_rows": [],
			"status_rows": [],
			"relationship_rows": [],
			"post_mission_rows": [],
			"progress_rows": [],
			"derived_rows": [
				{"label": "Method Tags", "value_text": "n/a", "detail_text": "Setzt sich aus Kernwerten, Verhalten und Traits zusammen."},
				{"label": "Function Scores", "value_text": "n/a", "detail_text": "Rollen-Fit aus Skills, Plattformwerten und Trait-Kontext."},
				{"label": "Primary Specialty", "value_text": "n/a", "detail_text": "Hoher Function Score plus Rollen- und Trait-Kontext."},
				{"label": "Secondary Specialty", "value_text": "n/a", "detail_text": "Naechststaerkerer Fit, falls vorhanden."},
			],
			"behavior_rows": _build_value_rows({}, BEHAVIOR_ORDER, "behavior_axes", "character_sheet"),
		}

	var trait_text: String = _build_expanded_trait_text(profile)

	var short_description: String = String(profile.short_description)
	if short_description.strip_edges().is_empty():
		short_description = String(profile.biography_text)
		if short_description.strip_edges().is_empty():
			short_description = "Keine Kurzbeschreibung hinterlegt."
	short_description = COPY.stock_biography(short_description, profile)
	var suitability_rows: Array = _build_suitability_rows(profile)
	var relationship_entries: Array = _build_relationship_entries(profile, options)

	return {
		"name": _optional_text(String(profile.display_name), "Unbekannte Person"),
		"start_role_text": _start_role_text(profile),
		"current_assignment_text": _optional_text(String(options.get("current_assignment_text", "")), "Im Profil nicht belegt"),
		"suitability_rows": suitability_rows,
		"primary_suitability_reason": String(suitability_rows[0].get("reason", "")) if not suitability_rows.is_empty() else "Noch keine Eignung berechnet.",
		"relationship_entries": relationship_entries,
		"relationship_overview_rows": _relationship_highlights(relationship_entries),
		"relationship_empty_text": "Noch keine Beziehung bekannt.",
		"overview_status_text": format_status_text(String(options.get("status_text", profile.availability_status))),
		"pilot_explanation": _build_pilot_explanation(profile),
		"trait_text": trait_text,
		"trait_rows": _build_trait_rows(profile),
		"short_description": short_description,
		"core_rows": _build_scored_rows(Dictionary(profile.skill_values), CORE_ORDER, "skill_values", "character_sheet.core"),
		"communication_rows": _build_value_rows(Dictionary(profile.communication_values), COMMUNICATION_ORDER, "communication_values", "character_sheet"),
		"platform_rows": _build_platform_value_rows(Dictionary(profile.platform_values), bool(options.get("show_all_platform_rows", false))),
		"role_loadout_rows": _build_role_loadout_rows(profile, options),
		"status_rows": _build_status_rows(profile, options),
		"relationship_rows": _build_relationship_rows(profile, options),
		"post_mission_rows": _build_post_mission_rows(options),
		"progress_rows": _build_progress_rows(profile, options),
		"derived_rows": _build_derived_rows(profile),
		"behavior_rows": _build_value_rows(Dictionary(profile.behavior_axes), BEHAVIOR_ORDER, "behavior_axes", "character_sheet"),
	}


static func build_loadout_text_from_member_loadout(member_loadout: Dictionary, fallback: String = "standard kit") -> String:
	if member_loadout.is_empty():
		return fallback
	return build_loadout_text_from_ids(
		String(member_loadout.get("armor", "medium")),
		String(member_loadout.get("weapon_1", member_loadout.get("weapon", "rifle"))),
		String(member_loadout.get("weapon_2", "rifle")),
		fallback
	)


static func _build_role_loadout_rows(profile, options: Dictionary = {}) -> Array:
	var loadout_text: String = String(options.get("loadout_text", "")).strip_edges()
	return [
		{"label": "Startrolle", "value_text": _start_role_text(profile), "help_id": "character_sheet.role_category", "detail_text": "Gespeicherte Ausgangsrolle. Sie ist weder ein Leistungsnachweis noch eine aktuelle Schiffszuteilung."},
		{"label": "Aktuelle Aufgabe", "value_text": _optional_text(String(options.get("current_assignment_text", "")), "Im Profil nicht belegt"), "help_id": "character_sheet.fireteam_assignment"},
		{"label": "Berechnete Eignung", "value_text": _build_role_fit_text(profile), "help_id": "character_sheet.role", "detail_text": _build_role_fit_detail_text(profile)},
		{"label": "Trupp", "value_text": _optional_text(String(options.get("fireteam_text", "")), _optional_text(String(profile.fireteam_id).to_upper(), "Nicht zugewiesen")), "help_id": "character_sheet.fireteam_assignment"},
		{"label": "Ausrüstung", "value_text": _optional_text(loadout_text, _build_profile_loadout_text(profile)), "help_id": "character_sheet.loadout_summary"},
	]


static func _start_role_text(profile) -> String:
	var category: String = String(profile.roster_role_category).strip_edges()
	return COPY.label(category) if not category.is_empty() else _optional_text(COPY.text(String(profile.role_name)), "Im Profil nicht belegt")


## Display translation only; never changes the saved role or its scoring input.
static func format_role_name(role_name: String) -> String:
	return COPY.text(role_name)


static func format_status_text(status_text: String) -> String:
	var known: String = COPY.text(status_text.to_lower())
	return status_text if known == status_text.to_lower() else known


static func _build_suitability_rows(profile) -> Array:
	var rows: Array = []
	for badge: Dictionary in NPC_RANK_BADGE_RESOLVER_SCRIPT.get_badge_progress_for_profile(profile):
		var key: String = String(badge.get("badge_key", ""))
		if key == "enemy":
			continue
		rows.append({"label": COPY.label(key), "value_text": "%s / %s" % [COPY.decimal(float(badge.get("score", 0.0))), COPY.decimal(NPC_RANK_BADGE_RESOLVER_SCRIPT.MIN_SCORE)], "badge_key": key, "reason": String(badge.get("reason", "")), "help_id": String(badge.get("help_id", "character_sheet.role")), "detail_text": _build_pilot_explanation(profile) if key == "pilot" else "%s\n%s" % [String(badge.get("reason", "")), String(badge.get("detail_text", ""))]})
	return rows


static func _build_pilot_explanation(profile) -> String:
	var breakdown: Dictionary = NPC_RANK_BADGE_RESOLVER_SCRIPT.get_pilot_score_breakdown(profile)
	var parts: PackedStringArray = []
	for factor: Dictionary in breakdown.factors:
		parts.append("%s %s × %d %%" % [COPY.label(String(factor.value_key)), COPY.decimal(float(factor.value)), roundi(float(factor.weight) * 100.0)])
	parts.append("Rollen-/Beschreibungskontext: +%s" % COPY.decimal(float(breakdown.role_bonus)))
	return "Piloteneignung %s; Schwelle %s.\n%s\nDer beste Fahrzeugwert schließt Bodenfahrzeuge ein. Eignung weist niemanden einem Schiff zu. Eine Berufslaufbahn ist im Profil nicht belegt." % [COPY.decimal(float(breakdown.score)), COPY.decimal(float(breakdown.threshold)), "; ".join(parts)]


static func _build_role_fit_text(profile) -> String:
	var progress: Array = Array(NPC_RANK_BADGE_RESOLVER_SCRIPT.call("get_badge_progress_for_profile", profile, 0, false))
	var achieved_parts: PackedStringArray = PackedStringArray()
	var next_parts: PackedStringArray = PackedStringArray()
	for badge_variant in progress:
		if typeof(badge_variant) != TYPE_DICTIONARY:
			continue
		var badge: Dictionary = Dictionary(badge_variant)
		if String(badge.get("badge_key", "")).strip_edges() == "enemy":
			continue
		var part: String = "%s %s" % [COPY.label(String(badge.get("badge_key", ""))), COPY.decimal(float(badge.get("score", 0.0)))]
		if bool(badge.get("achieved", false)):
			achieved_parts.append(part)
		elif next_parts.size() < 2:
			next_parts.append(part)
	if not achieved_parts.is_empty():
		return " | ".join(achieved_parts)
	if not next_parts.is_empty():
		return "Noch offen; nahe dran: %s" % " | ".join(next_parts)
	return "Noch kein Rollen-Fit"


static func _build_role_fit_detail_text(profile) -> String:
	var progress: Array = Array(NPC_RANK_BADGE_RESOLVER_SCRIPT.call("get_badge_progress_for_profile", profile, 0, false))
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Eignung wird aus aktuellen Profilwerten und vorhandenem Rollen-/Ausrüstungskontext berechnet. Das ist keine automatische Aufgabe.")
	for badge_variant in progress:
		if typeof(badge_variant) != TYPE_DICTIONARY:
			continue
		var badge: Dictionary = Dictionary(badge_variant)
		if bool(badge.get("achieved", false)):
			lines.append("%s erreicht: %s" % [COPY.label(String(badge.get("badge_key", ""))), COPY.decimal(float(badge.get("score", 0.0)))])
		elif lines.size() < 4:
			lines.append("%s: %s; Schwelle %s" % [COPY.label(String(badge.get("badge_key", ""))), COPY.decimal(float(badge.get("score", 0.0))), COPY.decimal(NPC_RANK_BADGE_RESOLVER_SCRIPT.MIN_SCORE)])
	if profile != null and not String(profile.role_name).strip_edges().is_empty():
		lines.append("Gespeicherter Starttext: %s" % COPY.text(String(profile.role_name).strip_edges()))
	return "\n".join(lines)


static func _build_status_rows(profile, options: Dictionary = {}) -> Array:
	var status_text: String = String(options.get("status_text", profile.status_text)).strip_edges()
	var recovery_text: String = _format_recovery_state(Dictionary(profile.recovery_state))
	var progression: Dictionary = Dictionary(profile.progression)
	var morale_row: Dictionary = {"label": "Moral", "value_text": _format_fraction_or_na(progression.get("morale", "n/a")), "help_id": "character_sheet.morale"}
	_apply_fraction_row_metadata(morale_row, progression.get("morale", "n/a"), "progression", "morale")
	var frustration_row: Dictionary = {"label": "Frustration", "value_text": _format_fraction_or_na(progression.get("frustration", "n/a")), "help_id": "character_sheet.frustration"}
	_apply_fraction_row_metadata(frustration_row, progression.get("frustration", "n/a"), "progression", "frustration")
	return [
		{"label": "Status", "value_text": COPY.text(_optional_text(status_text, _optional_text(String(profile.availability_status), "active"))), "help_id": "character_sheet.status"},
		{"label": "Erholung", "value_text": recovery_text, "help_id": "character_sheet.recovery"},
		morale_row,
		frustration_row,
	]


static func _build_relationship_entries(profile, options: Dictionary = {}) -> Array:
	var data: Dictionary = profile.call("to_dict") if profile != null and profile.has_method("to_dict") else {}
	var names: Dictionary = {}
	for id in Dictionary(options.get("roster_names_by_id", {})):
		names[ROSTER_RELATIONSHIP_MODEL_SCRIPT.normalize_unit_id(String(id))] = String(options.roster_names_by_id[id]).strip_edges()
	# Normalization owns identity, signs, duplicate targets and ordering. Keep
	# custom stored prose verbatim rather than deriving reasons from traits.
	var reasons: Dictionary = {}
	for raw: Dictionary in Array(data.get("relationship_links", [])):
		var id: String = ROSTER_RELATIONSHIP_MODEL_SCRIPT.normalize_unit_id(String(raw.get("target_unit_id", raw.get("unit_id", ""))))
		if not reasons.has(id):
			reasons[id] = String(raw.get("reason", ""))
	var entries: Array = []
	for link: Dictionary in ROSTER_RELATIONSHIP_MODEL_SCRIPT.normalize_links_for_unit(data):
		var id: String = String(link.target_unit_id)
		var name_text: String = String(names.get(id, ""))
		if name_text.is_empty():
			name_text = String(link.get("target_name", ""))
			if name_text.is_empty() or name_text.to_lower() == id:
				name_text = "Person ohne hinterlegten Namen"
		var tags: PackedStringArray = []
		for tag in PackedStringArray(link.get("tags", [])):
			tags.append(COPY.label(tag))
		var value: float = float(link.affinity)
		entries.append({"label": name_text, "value_text": COPY.signed_decimal(value) + (" · " + ", ".join(tags) if not tags.is_empty() else ""), "detail_text": COPY.relationship_reason(String(reasons.get(id, link.get("reason", "")))), "help_id": "character_sheet.relationship_links", "target_unit_id": id, "affinity": value})
	return entries


static func _relationship_highlights(entries: Array) -> Array:
	var highlights: Array = []
	for sign_value in [1.0, -1.0]:
		for entry: Dictionary in entries:
			if float(entry.affinity) * sign_value > 0.0:
				highlights.append(entry.duplicate(true))
				break
	for entry: Dictionary in entries:
		if highlights.size() >= 2:
			break
		if not highlights.any(func(highlight: Dictionary): return highlight.target_unit_id == entry.target_unit_id):
			highlights.append(entry.duplicate(true))
	return highlights


static func _build_relationship_rows(profile, options: Dictionary = {}) -> Array:
	var entries: Array = _build_relationship_entries(profile, options)
	var best: Dictionary = {}
	var worst: Dictionary = {}
	for entry: Dictionary in entries:
		if float(entry.affinity) > 0.0 and best.is_empty():
			best = entry
		if float(entry.affinity) < 0.0 and worst.is_empty():
			worst = entry
	var relationship_summary: String = String(profile.relationship_summary_text)
	if relationship_summary.strip_edges().is_empty():
		relationship_summary = "%d gespeicherte Beziehungen" % entries.size() if not entries.is_empty() else "Noch keine Beziehung bekannt."
	var names: PackedStringArray = []
	for entry: Dictionary in entries:
		names.append("%s %s" % [entry.label, COPY.signed_decimal(float(entry.affinity))])
	return [
		{"label": "Teamfit", "value_text": _optional_text(relationship_summary, "Noch keine Beziehungsauswertung."), "help_id": "character_sheet.teamfit"},
		{"label": "Gute Zusammenarbeit", "value_text": "%s %s" % [best.label, best.value_text] if not best.is_empty() else "Noch keine", "detail_text": String(best.get("detail_text", "")), "help_id": "character_sheet.best_fit"},
		{"label": "Spannungen", "value_text": "%s %s" % [worst.label, worst.value_text] if not worst.is_empty() else "Noch keine", "detail_text": String(worst.get("detail_text", "")), "help_id": "character_sheet.tension"},
		{"label": "Beziehungen", "value_text": "; ".join(names) if not names.is_empty() else "Noch keine Beziehung bekannt.", "help_id": "character_sheet.relationship_links"},
	]


static func _build_progress_rows(profile, options: Dictionary = {}) -> Array:
	var progression: Dictionary = Dictionary(profile.progression)
	return [
		{"label": "XP", "value_text": str(int(progression.get("xp", 0))), "help_id": "character_sheet.xp"},
		{"label": "Einsätze", "value_text": str(int(progression.get("missions_completed", Array(profile.mission_history).size()))), "help_id": "character_sheet.missions"},
		{"label": "Führungswirkung", "value_text": _format_ftl_tactical_impact(profile), "help_id": "character_sheet.ftl_tactical_impact"},
		{"label": "Letzter Einsatz", "value_text": _format_last_history(Array(profile.mission_history), "mission_id"), "help_id": "character_sheet.last_mission"},
		{"label": "Truppverlauf", "value_text": _format_last_history(Array(profile.fireteam_history), "fireteam_id"), "help_id": "character_sheet.fireteam_history"},
	]


static func _build_post_mission_rows(options: Dictionary = {}) -> Array:
	var post_mission_row: Dictionary = _build_post_mission_skill_delta_row(options)
	if not post_mission_row.is_empty():
		return [post_mission_row]
	return []


static func _build_post_mission_skill_delta_row(options: Dictionary) -> Dictionary:
	var award: Dictionary = Dictionary(options.get("post_mission_skill_delta", {}))
	if award.is_empty():
		return {}
	var value_text: String = String(options.get("post_mission_skill_delta_text", "")).strip_edges()
	if value_text.is_empty():
		var parts: PackedStringArray = PackedStringArray()
		var xp_delta: int = int(award.get("xp_delta", 0))
		if xp_delta > 0:
			parts.append("XP +%d" % xp_delta)
		var skill_gain_count: int = int(award.get("skill_gain_count", 0))
		if skill_gain_count > 0:
			parts.append("Werte +%d" % skill_gain_count)
		var ftl_gain: float = float(award.get("ftl_tactical_gain", 0.0))
		if ftl_gain > 0.0:
			parts.append(("Führung +%.3f" % ftl_gain).replace(".", ","))
		value_text = " | ".join(parts)
	if value_text.is_empty():
		value_text = "Kein Zuwachs"
	return {
		"label": "Letzter Zuwachs",
		"value_text": COPY.award_text(value_text),
		"help_id": "character_sheet.post_mission_skill_delta",
		"detail_text": "Bestätigter Zuwachs aus dem letzten Einsatzergebnis. Diese Anzeige vergibt keine weiteren Punkte.",
		"style_key": "post_mission_award",
		"style_id": "homebase_progression_delta_v1",
		"badge_text": "MISSION GAIN",
		"read_only": true,
		"source": "progression_award_summary",
	}


static func _build_derived_rows(profile) -> Array:
	return [
		{"label": "Arbeitsweise", "value_text": _format_score_summary(Dictionary(profile.method_scores), "—"), "help_id": "character_sheet.method_tags", "detail_text": "Gewichtete Kernwerte und Kommunikation bestimmen Arbeitsweisen wie leise, schnell oder wachsam. Eigenschaften wirken über die Profilwerte."},
		{"label": "Einsatzeignung", "value_text": _format_score_summary(Dictionary(profile.function_scores), "—"), "help_id": "character_sheet.function_scores", "detail_text": "Funktionswerte aus Kernwerten, Kommunikation und passenden Fahrzeugwerten. Diese Werte erteilen keine Aufgabe."},
		{"label": "Spezialisierung", "value_text": COPY.text(_optional_text(String(profile.primary_specialty), _optional_text(String(profile.specialty_text), "—"))), "help_id": "character_sheet.primary_specialty", "detail_text": "Beste Kombination aus zugelassener Rollenfunktion und Arbeitsweise. Der gespeicherte Rollenrahmen begrenzt die Auswahl."},
		{"label": "Weitere Stärke", "value_text": COPY.text(_optional_text(String(profile.secondary_specialty), "—")), "help_id": "character_sheet.secondary_specialty", "detail_text": "Zweite Kombination, wenn sie die vorhandenen Mindest- und Abstandsregeln erfüllt."},
	]


static func _format_ftl_tactical_impact(profile) -> String:
	if profile == null:
		return "n/a"
	var explicit_text: String = String(profile.ftl_tactical_effect_text).strip_edges()
	if not explicit_text.is_empty():
		return COPY.tactical_text(explicit_text)
	var snapshot: Dictionary = Dictionary(profile.ftl_tactical_progression)
	if snapshot.is_empty():
		snapshot = Dictionary(Dictionary(profile.progression).get("ftl_tactical_snapshot", {}))
	if not snapshot.is_empty():
		return COPY.tactical_text(String(FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT.call("build_tactical_effect_text", snapshot)))
	if not bool(profile.is_fireteam_lead):
		return "Keine Truppführung"
	var leader_data: Dictionary = profile.call("to_dict") if profile != null and profile.has_method("to_dict") else {}
	var derived_snapshot: Dictionary = FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT.call("build_leader_tactical_skill_snapshot", leader_data, {"fireteam_id": String(profile.fireteam_id)})
	return COPY.tactical_text(String(FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT.call("build_tactical_effect_text", derived_snapshot)))


static func build_loadout_text_from_ids(armor_id: String, weapon_1_id: String, weapon_2_id: String, fallback: String = "standard kit") -> String:
	var normalized_armor_id: String = _normalize_armor_id(armor_id)
	var normalized_weapon_1_id: String = _normalize_weapon_id(weapon_1_id)
	var normalized_weapon_2_id: String = _normalize_weapon_id(weapon_2_id)
	if normalized_armor_id.is_empty() and normalized_weapon_1_id.is_empty() and normalized_weapon_2_id.is_empty():
		return fallback
	return "%s | %s | %s" % [
		COPY.armor(_normalize_armor_id(normalized_armor_id)),
		WEAPON_DATA_SCRIPT.get_display_name(normalized_weapon_1_id),
		WEAPON_DATA_SCRIPT.get_display_name(normalized_weapon_2_id),
	]


static func format_fireteam_label(fireteam_id: String) -> String:
	var normalized_fireteam_id: String = fireteam_id.strip_edges()
	if normalized_fireteam_id.is_empty():
		return "Nicht zugewiesen"
	return normalized_fireteam_id.replace("_", " ").to_upper()


static func _build_expanded_trait_text(profile) -> String:
	if profile == null:
		return "Keine Eigenschaften hinterlegt."

	var trait_names: PackedStringArray = []
	if profile.trait_ids is PackedStringArray:
		for trait_id_variant in profile.trait_ids:
			var unit_trait = UNIT_TRAIT_SCRIPT.from_id(String(trait_id_variant))
			if unit_trait == null:
				continue
			trait_names.append(String(unit_trait.display_name))

	if not trait_names.is_empty():
		return ", ".join(trait_names)

	var trait_text: String = String(profile.trait_summary_text).strip_edges()
	if trait_text.is_empty() and profile.trait_tags is PackedStringArray and not (profile.trait_tags as PackedStringArray).is_empty():
		trait_text = " ".join(profile.trait_tags)
	return _optional_text(trait_text, "Keine markanten Eigenschaften hinterlegt.")


static func _build_trait_rows(profile) -> Array:
	var rows: Array = []
	if profile == null:
		return rows
	var seen_trait_ids: Dictionary = {}
	if profile.trait_ids is PackedStringArray:
		for trait_id_variant in profile.trait_ids:
			var trait_id: String = String(trait_id_variant).strip_edges().to_lower()
			if trait_id.is_empty() or seen_trait_ids.has(trait_id):
				continue
			seen_trait_ids[trait_id] = true
			var unit_trait = UNIT_TRAIT_SCRIPT.from_id(trait_id)
			if unit_trait == null:
				rows.append({
					"label": trait_id.capitalize(),
					"value_text": trait_id.to_upper(),
					"trait_id": trait_id,
					"help_id": "character_sheet.traits",
					"detail_text": "Unbekannte Eigenschaft aus dem gespeicherten Profil.",
				})
				continue
			rows.append({
				"label": String(unit_trait.display_name),
				"value_text": String(unit_trait.short_tag),
				"trait_id": trait_id,
				"help_id": "character_sheet.trait.%s" % trait_id,
				"detail_text": _format_trait_modifier_text(Dictionary(unit_trait.skill_modifiers)),
			})
	if rows.is_empty() and profile.trait_tags is PackedStringArray:
		for trait_tag_variant in profile.trait_tags:
			var trait_tag: String = String(trait_tag_variant).strip_edges()
			if trait_tag.is_empty():
				continue
			rows.append({
				"label": trait_tag,
				"value_text": "TAG",
				"trait_id": trait_tag.to_lower(),
				"help_id": "character_sheet.traits",
				"detail_text": "Eigenschaft aus dem Profil ohne hinterlegte Rechenregel.",
			})
	return rows


static func _format_trait_modifier_text(skill_modifiers: Dictionary) -> String:
	if skill_modifiers.is_empty():
		return "Diese Eigenschaft beschreibt Verhalten ohne direkten Wertemodifikator."
	var keys: Array = skill_modifiers.keys()
	keys.sort()
	var parts: PackedStringArray = PackedStringArray()
	for key_variant in keys:
		var key: String = String(key_variant)
		parts.append("%s %s" % [COPY.label(key), ("%+.2f" % float(skill_modifiers.get(key_variant, 0.0))).replace(".", ",")])
	return "Wirkung auf Werte: %s" % " · ".join(parts)


static func _build_profile_loadout_text(profile) -> String:
	if profile == null:
		return "standard kit"
	return build_loadout_text_from_ids(
		String(profile.armor_id),
		String(profile.weapon_1_id),
		String(profile.weapon_2_id),
		"standard kit"
	)


static func _normalize_armor_id(armor_id: String) -> String:
	var normalized_armor_id: String = armor_id.strip_edges().to_lower()
	if normalized_armor_id == "light" or normalized_armor_id == "medium" or normalized_armor_id == "heavy":
		return normalized_armor_id
	return "medium"


static func _normalize_weapon_id(weapon_id: String) -> String:
	var normalized_weapon_id: String = weapon_id.strip_edges().to_lower()
	if normalized_weapon_id.is_empty():
		return "rifle"
	return normalized_weapon_id


static func _build_scored_rows(source_values: Dictionary, order: Array, value_group: String = "", help_prefix: String = "character_sheet") -> Array:
	var rows: Array = []
	for entry in order:
		var key: String = String(entry[0])
		var label: String = COPY.label(key)
		var value: float = float(source_values.get(key, 0.0))
		rows.append(
			{
				"label": label,
				"value": clampf(value, 0.0, 1.0),
				"value_text": _format_decimal_comma(value),
				"value_group": value_group,
				"value_key": key,
				"help_id": "%s.%s" % [help_prefix, key],
				"detail_text": _value_help_text(value_group, key),
			}
		)
	return rows


static func _build_platform_rows(platform_values: Dictionary) -> Array:
	var rows: Array = []
	for entry in PLATFORM_ORDER:
		var key: String = String(entry[0])
		var label: String = COPY.label(key)
		var value: float = float(platform_values.get(key, UNIT_PROFILE_MATH_SCRIPT.NOT_APPLICABLE))
		rows.append(
			{
				"label": label,
				"value_text": "n/a" if value < 0.0 else _format_decimal_comma(value),
				"help_id": "character_sheet.platform.%s" % key,
			}
		)
	return rows


static func _build_platform_value_rows(platform_values: Dictionary, include_not_applicable: bool = false) -> Array:
	var rows: Array = []
	for entry in PLATFORM_ORDER:
		var key: String = String(entry[0])
		var label: String = COPY.label(key)
		var value: float = float(platform_values.get(key, UNIT_PROFILE_MATH_SCRIPT.NOT_APPLICABLE))
		if value < 0.0 and not include_not_applicable:
			continue
		var editable_value: float = 0.0 if value < 0.0 else value
		rows.append(
			{
				"label": label,
				"value": clampf(editable_value, 0.0, 1.0),
				"value_text": _format_decimal_comma(editable_value),
				"value_group": "platform_values",
				"value_key": key,
				"help_id": "character_sheet.platform.%s" % key,
				"detail_text": "%s %s" % [_value_help_text("platform_values", key), "Der gespeicherte Fahrzeugwert kann als Vorgabe vorliegen; seine ursprüngliche Herleitung ist nicht im Profil protokolliert."],
			}
		)
	return rows


static func _build_ordered_score_rows(source_values: Dictionary, order: Array) -> Array:
	var rows: Array = []
	for entry in order:
		var key: String = String(entry[0])
		var label: String = COPY.label(key)
		rows.append(
			{
				"label": label,
				"value": clampf(float(source_values.get(key, 0.0)), 0.0, 1.0),
				"value_text": _format_decimal_comma(float(source_values.get(key, 0.0))),
				"value_key": key,
				"help_id": "character_sheet.%s" % key,
			}
		)
	return rows


static func _build_value_rows(source_values: Dictionary, order: Array, value_group: String = "", help_prefix: String = "character_sheet") -> Array:
	var rows: Array = []
	for entry in order:
		var key: String = String(entry[0])
		var label: String = COPY.label(key)
		var value: float = float(source_values.get(key, 0.0))
		rows.append(
			{
				"label": label,
				"value": clampf(value, 0.0, 1.0),
				"value_text": _format_decimal_comma(value),
				"value_group": value_group,
				"value_key": key,
				"help_id": "%s.%s" % [help_prefix, key],
				"detail_text": _value_help_text(value_group, key),
			}
		)
	return rows


static func _value_help_text(value_group: String, value_key: String) -> String:
	var key: String = "%s.%s" % [value_group.strip_edges(), value_key.strip_edges()]
	return String(VALUE_HELP_TEXTS.get(key, "Dieser Wert ist Profil- oder Ableitungsdaten und wird von bestehenden Resolversystemen gelesen."))


static func _apply_fraction_row_metadata(row: Dictionary, raw_value: Variant, value_group: String, value_key: String) -> void:
	if typeof(raw_value) == TYPE_STRING and String(raw_value) == "n/a":
		return
	row["value"] = clampf(float(raw_value), 0.0, 1.0)
	row["value_group"] = value_group
	row["value_key"] = value_key


static func _format_score_summary(scores: Dictionary, fallback: String) -> String:
	var normalized_fallback: String = fallback.strip_edges()
	if scores.is_empty():
		return _optional_text(normalized_fallback, "n/a")

	var sorted_keys: Array = scores.keys()
	sorted_keys.sort_custom(func(a, b):
		return float(scores.get(a, 0.0)) > float(scores.get(b, 0.0))
	)
	var summary_parts: PackedStringArray = []
	for key_variant in sorted_keys:
		var key: String = String(key_variant)
		summary_parts.append("%s %s" % [_humanize_key(key), _format_decimal_comma(float(scores.get(key_variant, 0.0)))])
	return " | ".join(summary_parts)


static func _format_recovery_state(recovery_state: Dictionary) -> String:
	if recovery_state.is_empty():
		return "Keine"
	var state: String = String(recovery_state.get("state", recovery_state.get("status", "recovering"))).strip_edges()
	var turns_remaining: int = int(recovery_state.get("turns_remaining", recovery_state.get("days_remaining", -1)))
	if turns_remaining >= 0:
		return "%s | %d verbleibend" % [COPY.text(_optional_text(state, "recovering")), turns_remaining]
	return COPY.text(_optional_text(state, "recovering"))


static func _format_relationship_links(links: Array) -> String:
	if links.is_empty():
		return "Noch keine"
	var parts: PackedStringArray = PackedStringArray()
	for index in range(mini(links.size(), 2)):
		if typeof(links[index]) != TYPE_DICTIONARY:
			continue
		var link: Dictionary = Dictionary(links[index])
		var target: String = _optional_text(String(link.get("target_name", link.get("target_unit_id", ""))), "unknown")
		var value: float = float(link.get("affinity", 0.0))
		parts.append("%s %+.2f" % [target, value])
	if parts.is_empty():
		return "Noch keine"
	if links.size() > 2:
		parts.append("+%d" % (links.size() - 2))
	return " | ".join(parts)


static func _format_relationship_link_summary(link: Dictionary, fallback: String) -> String:
	if link.is_empty():
		return fallback
	var target: String = _optional_text(String(link.get("target_name", link.get("target_unit_id", ""))), "unknown")
	var tags: PackedStringArray = PackedStringArray(link.get("tags", PackedStringArray()))
	var tag_text: String = ""
	if not tags.is_empty():
		tag_text = " %s" % "/".join(tags)
	return "%s %+.2f%s" % [target, float(link.get("affinity", 0.0)), tag_text]


static func _format_last_history(history: Array, id_key: String) -> String:
	if history.is_empty():
		return "Noch keine"
	var entry: Dictionary = Dictionary(history[history.size() - 1]) if typeof(history[history.size() - 1]) == TYPE_DICTIONARY else {}
	if entry.is_empty():
		return "Noch keine"
	var id_text: String = String(entry.get(id_key, "")).strip_edges()
	var result_text: String = String(entry.get("result", "")).strip_edges()
	if result_text.is_empty():
		return _optional_text(id_text, "recorded")
	return "%s | %s" % [_optional_text(id_text, "Erfasst"), COPY.text(result_text)]


static func _format_fraction_or_na(value: Variant) -> String:
	if typeof(value) == TYPE_STRING and String(value) == "n/a":
		return "—"
	return _format_decimal_comma(float(value))


static func _humanize_key(value: String) -> String:
	var normalized: String = value.strip_edges().replace("_", " ")
	if normalized.is_empty():
		return "n/a"
	var parts: PackedStringArray = normalized.split(" ", false)
	for index in range(parts.size()):
		parts[index] = String(parts[index]).capitalize()
	return " ".join(parts)


static func _format_decimal_comma(value: float) -> String:
	return ("%.2f" % clampf(value, 0.0, 1.0)).replace(".", ",")


static func _optional_text(value: String, fallback: String) -> String:
	var normalized: String = value.strip_edges()
	if normalized.is_empty():
		return fallback
	return normalized
