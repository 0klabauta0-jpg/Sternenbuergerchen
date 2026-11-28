extends SceneTree
## Paket 3 (Funk): Persoenlichkeit als Merkmal einer Person.
## Prueft Satzdatei und Persoenlichkeitsdatei, Startleute, "fehlendes Feld = profi", Rekruten und Gegner, Speichern und Laden,
## das Charakterblatt (Name und Beschreibung, auch bei 1280x720) und die Truppfuehrer-Blase (einzige Satzquelle funk_saetze.json,
## Persoenlichkeit waehlt den Satz, Funkguete kurz oder genau).

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")
const FUNK_SAETZE: GDScript = preload("res://scripts/tactical/funk_saetze.gd")
const PERSONALITY_CATALOG: GDScript = preload("res://scripts/meta/personality_catalog.gd")
const META_UNIT_PROFILE: GDScript = preload("res://scripts/meta/meta_unit_profile.gd")
const START_ROSTER_GENERATOR: GDScript = preload("res://scripts/meta/start_roster_generator.gd")
const PLAYER_ROSTER_STORE: GDScript = preload("res://scripts/meta/player_roster_store.gd")
const SKIRMISH_START_CONFIGURATION: GDScript = preload("res://scripts/meta/skirmish_start_configuration.gd")
const CAMPAIGN_START_CONFIGURATION: GDScript = preload("res://scripts/meta/campaign_start_configuration.gd")
const CHARACTER_SHEET_FORMATTER: GDScript = preload("res://scripts/meta/character_sheet_formatter.gd")
const CHARACTER_SHEET_VIEW: GDScript = preload("res://scripts/meta/character_sheet_view.gd")
const COMMUNICATION_COPY: GDScript = preload("res://scripts/tactical/tactical_communication_copy.gd")
const COMMUNICATION_RESOLVER: GDScript = preload("res://scripts/tactical/tactical_communication_resolver.gd")
const FEEDBACK_BUBBLE_RESOLVER: GDScript = preload("res://scripts/ui/fireteamleader_feedback_bubble_resolver.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const SATZ_PFAD: String = "res://data/comms/funk_saetze.json"
const COPY_PFAD: String = "res://data/tactical_communication_copy.json"
const PERSOENLICHKEIT_PFAD: String = "res://data/comms/persoenlichkeiten.json"
const SPEICHER_PFAD: String = "user://funk_persoenlichkeit_20261128/roster.json"
const ERWARTETE_ANLAESSE: PackedStringArray = [
	"befehl_verstanden", "unterwegs", "ziel_erreicht", "feindkontakt", "blockiert", "braucht_befehl", "getroffen", "liegt",
	"gerettet", "kamerad_faellt", "gegner_erledigt", "magazin_leer", "nachladen", "eingestiegen", "abgesetzt",
	"schiff_in_gefahr", "auftrag_erfuellt", "rueckzug", "angst", "mut",
]
## Anlaesse des Truppfuehrers (zehn) und die zusaetzlichen, auf die die Ausloeser der Blase zeigen.
const ANLAESSE_TRUPPFUEHRER: PackedStringArray = [
	"befehl_verstanden", "unterwegs", "ziel_erreicht", "feindkontakt", "blockiert", "braucht_befehl", "abgesetzt",
	"schiff_in_gefahr", "auftrag_erfuellt", "rueckzug",
]
const ERWARTETE_TYPEN: PackedStringArray = ["profi", "draufgaenger", "vorsichtig", "spassvogel", "brummbaer"]
const ERWARTETE_NAMEN: Dictionary = {"profi": "Profi", "draufgaenger": "Draufgänger", "vorsichtig": "Vorsichtig", "spassvogel": "Spaßvogel", "brummbaer": "Brummbär"}
const VERBOTENE_WORTSTAMMME_SS: PackedStringArray = ["fuss", "strass", "gross", "heiss", "weiss", "schliess", "gruss", "draussen", "ausser", "beiss", "spass", "stoss", "fliess"]
const ERLAUBTE_UE_WOERTER: PackedStringArray = ["neue", "neuen", "neues", "neuer", "neuem"]
const ENGLISCHE_WOERTER: PackedStringArray = [
	"air", "asset", "orders", "order", "block", "lz", "recovery", "contact", "objective", "roger", "copy", "over", "out", "down",
	"hit", "medic", "reload", "ammo", "enemy", "hostile", "status", "ok", "okay", "team", "fireteam", "dropship", "go", "sorry",
]
## Worte, die einen Witz ueber einen Gefallenen verraten wuerden.
const WITZ_MARKER: PackedStringArray = ["kaffee", "witz", "haha", "lustig", "lach", "spaß", "party", "wette", "lieferung"]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== Persoenlichkeit (Funk Paket 3) ===")
	_pruefe_persoenlichkeitsdatei()
	_pruefe_satzdatei()
	_pruefe_kamerad_faellt_ernst()
	_pruefe_startleute_und_fehlendes_feld()
	_pruefe_rekruten_und_gegner()
	_pruefe_speichern_und_laden()
	_pruefe_blase_aus_einer_quelle()
	_pruefe_zuordnung_der_anlaesse()
	_pruefe_zwei_truppfuehrer()
	_pruefe_farbnamen()
	await _pruefe_charakterblatt(Vector2i(1280, 720))
	await _pruefe_charakterblatt(Vector2i(1920, 1080))
	await _pruefe_mission()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


# ---------------------------------------------------------------- Dateien

func _pruefe_persoenlichkeitsdatei() -> void:
	PERSONALITY_CATALOG.call("clear_cache")
	var datei: Dictionary = _lies_json(PERSOENLICHKEIT_PFAD)
	_assert(not datei.is_empty(), "persoenlichkeiten.json ist lesbar")
	var typen: Dictionary = Dictionary(datei.get("typen", {}))
	_assert(typen.size() == 5, "genau fuenf Typen (%d)" % typen.size())
	var probleme: PackedStringArray = PackedStringArray()
	for typ in ERWARTETE_TYPEN:
		var eintrag: Dictionary = Dictionary(typen.get(typ, {}))
		if eintrag.is_empty():
			probleme.append("Typ %s fehlt" % typ)
			continue
		if String(eintrag.get("name", "")) != String(ERWARTETE_NAMEN[typ]):
			probleme.append("Name von %s ist '%s'" % [typ, String(eintrag.get("name", ""))])
		var beschreibung: String = String(eintrag.get("beschreibung", "")).strip_edges()
		if beschreibung.is_empty() or not beschreibung.ends_with(".") or beschreibung.substr(0, beschreibung.length() - 1).contains(". "):
			probleme.append("Beschreibung von %s ist kein Satz: '%s'" % [typ, beschreibung])
		_sammle_textfehler(beschreibung, probleme)
		_assert(String(PERSONALITY_CATALOG.call("display_name", typ)) == String(ERWARTETE_NAMEN[typ]), "display_name(%s) = %s" % [typ, ERWARTETE_NAMEN[typ]])
	_assert(probleme.is_empty(), "fuenf Typen mit deutschem Namen und einem Satz Beschreibung (Funde: %s)" % " | ".join(probleme))
	var katalog_typen: PackedStringArray = PERSONALITY_CATALOG.call("type_ids")
	_assert(Array(katalog_typen) == Array(ERWARTETE_TYPEN), "Typenreihenfolge der Datei = profi, draufgaenger, vorsichtig, spassvogel, brummbaer")
	_assert(Array(FUNK_SAETZE.PERSONALITIES) == Array(ERWARTETE_TYPEN), "FunkSaetze kennt dieselben Typen")
	var startleute: Dictionary = Dictionary(datei.get("startleute", {}))
	_assert(String(startleute.get("campaign_leader", "")) == "profi", "Startwert Truppfuehrer = profi")
	_assert(String(startleute.get("campaign_pilot", "")) == "spassvogel", "Startwert zweite Person = spassvogel")


func _pruefe_satzdatei() -> void:
	FUNK_SAETZE.call("clear_cache")
	var katalog: Dictionary = _lies_json(SATZ_PFAD)
	_assert(katalog.size() == ERWARTETE_ANLAESSE.size(), "funk_saetze.json hat %d Anlaesse (%d)" % [ERWARTETE_ANLAESSE.size(), katalog.size()])
	var voller_kontext: Dictionary = {"name": "Mara", "team": "Blau", "richtung": "Nordost", "ziel": "Schiff", "kamerad": "Jonas"}
	var probleme: PackedStringArray = PackedStringArray()
	for anlass in ERWARTETE_ANLAESSE:
		var typen: Dictionary = Dictionary(katalog.get(anlass, {}))
		for typ in ERWARTETE_TYPEN:
			for stufe in ["kurz", "genau"]:
				var liste: Array = Array(Dictionary(typen.get(typ, {})).get(stufe, []))
				if liste.is_empty():
					probleme.append("%s/%s/%s ohne Satz" % [anlass, typ, stufe])
				for satz_variant in liste:
					var satz: String = String(satz_variant)
					for kontext in [voller_kontext, {}]:
						var gefuellt: String = String(FUNK_SAETZE.call("fill", satz, kontext))
						if gefuellt.contains("{") or gefuellt.contains("}"):
							probleme.append("Platzhalter bleibt: %s" % satz)
						_sammle_textfehler(gefuellt, probleme)
					if ANLAESSE_TRUPPFUEHRER.has(anlass):
						var woerter: int = String(FUNK_SAETZE.call("fill", satz, voller_kontext)).split(" ", false).size()
						if woerter > 12:
							probleme.append("fuer die Blase zu lang (%d Woerter): %s" % [woerter, satz])
	_assert(probleme.is_empty(), "jeder Anlass hat fuer jeden Typ in kurz und genau Saetze; alle Platzhalter werden ersetzt; keine Ersatzumlaute, kein Englisch (Funde: %s)" % " | ".join(probleme))
	# Auswahl ohne Wert fuer {ziel}/{richtung}: eine Fassung ohne diese Platzhalter wird vorgezogen.
	var ohne_ziel: Array = FUNK_SAETZE.call("prefer_fillable", ["{team} ist unterwegs zu {ziel}.", "Wir bewegen uns Richtung {richtung}.", "Rücken vor."], {"team": "BLUE"})
	_assert(ohne_ziel == ["Rücken vor."], "Fassungen ohne verfuegbaren Platzhalterwert werden uebergangen (%s)" % str(ohne_ziel))


func _pruefe_kamerad_faellt_ernst() -> void:
	var katalog: Dictionary = _lies_json(SATZ_PFAD)
	var spassvogel: Dictionary = Dictionary(Dictionary(katalog.get("kamerad_faellt", {})).get("spassvogel", {}))
	var kurz: Array = Array(spassvogel.get("kurz", []))
	var genau: Array = Array(spassvogel.get("genau", []))
	_assert(kurz == ["Nein.", "Das nicht."], "Spassvogel bei kamerad_faellt (kurz) ist wortgleich der ernste, freigegebene Satz (%s)" % str(kurz))
	_assert(genau == ["Es tut mir leid, {kamerad}, ich habe dich gesehen.", "{kamerad} ist gefallen, ich sage nichts mehr dazu."], "Spassvogel bei kamerad_faellt (genau) ist wortgleich der ernste, freigegebene Satz")
	var probleme: PackedStringArray = PackedStringArray()
	for satz_variant in kurz + genau:
		var klein: String = String(satz_variant).to_lower()
		for marker in WITZ_MARKER:
			if klein.contains(marker):
				probleme.append("%s enthaelt '%s'" % [satz_variant, marker])
		if String(satz_variant).contains("!") or String(satz_variant).contains("?"):
			probleme.append("%s ist keine ruhige Aussage" % satz_variant)
	_assert(probleme.is_empty(), "Spassvogel scherzt bei kamerad_faellt nie (Funde: %s)" % " | ".join(probleme))


# ---------------------------------------------------------------- Merkmal

func _pruefe_startleute_und_fehlendes_feld() -> void:
	var roster: Array = CAMPAIGN_START_CONFIGURATION.new().call("_initial_roster")
	_assert(roster.size() >= 2, "Startleute der Kampagne: zwei Personen")
	var leiter: Dictionary = Dictionary(roster[0])
	var zweite: Dictionary = Dictionary(roster[1])
	_assert(String(leiter.get("unit_id", "")) == "campaign_leader" and String(leiter.get("personality", "")) == "profi", "Truppfuehrer der Startleute ist profi (%s)" % String(leiter.get("personality", "")))
	_assert(String(zweite.get("unit_id", "")) == "campaign_pilot" and String(zweite.get("personality", "")) == "spassvogel", "zweite Person der Startleute ist spassvogel (%s)" % String(zweite.get("personality", "")))
	var leer = META_UNIT_PROFILE.new({"unit_id": "ohne_feld", "display_name": "Ohne Feld"})
	_assert(String(leer.personality) == "profi", "fehlendes Feld personality gilt als profi (%s)" % String(leer.personality))
	_assert(String(Dictionary(leer.to_dict()).get("personality", "")) == "profi", "to_dict schreibt das Feld immer")
	var unbekannt = META_UNIT_PROFILE.new({"unit_id": "komisch", "personality": "kasperl"})
	_assert(String(unbekannt.personality) == "profi", "unbekannter Typ gilt als profi")
	var gross = META_UNIT_PROFILE.new({"unit_id": "gross", "personality": " Vorsichtig "})
	_assert(String(gross.personality) == "vorsichtig", "Typ wird bereinigt (Leerzeichen, Gross/Klein)")
	_assert(String(PERSONALITY_CATALOG.call("normalize", null)) == "profi" and String(PERSONALITY_CATALOG.call("normalize", "")) == "profi", "normalize(leer) = profi")
	_assert(String(FUNK_SAETZE.call("normalize_personality", "")) == "profi", "Funksaetze ohne Typ sprechen wie profi")
	var builder_profil = load("res://scripts/meta/meta_unit_profile_builder.gd").call("build_from_identity_config", {"unit_id": "b1", "display_name": "B Eins", "personality": "brummbaer"})
	_assert(String(builder_profil.personality) == "brummbaer", "Profilbauer reicht das Feld durch")
	var einheit = TEST_UNIT_SCRIPT.new()
	einheit.call("apply_identity_config", {"unit_id": "t1", "personality": "Draufgaenger"}, false)
	_assert(String(einheit.call("get_personality")) == "draufgaenger", "Einheit im Einsatz bekommt das Feld aus den Personendaten")
	einheit.free()


func _pruefe_rekruten_und_gegner() -> void:
	# Rekruten ueber den vorhandenen Weg der Rekrutenerzeugung (Startkader-Erzeuger, Startwert aus der Kennung).
	var zaehler: Dictionary = {}
	var ungueltig: int = 0
	var gesamt: int = 0
	for startwert in range(12):
		var kader: Dictionary = START_ROSTER_GENERATOR.call("generate_start_roster", "funk_p3_%d" % startwert, 24, "funk_test")
		for unit_variant in Array(kader.get("units", [])):
			var typ: String = String(Dictionary(unit_variant).get("personality", ""))
			gesamt += 1
			if not ERWARTETE_TYPEN.has(typ):
				ungueltig += 1
			zaehler[typ] = int(zaehler.get(typ, 0)) + 1
	var gleichmaessig: bool = true
	for typ in ERWARTETE_TYPEN:
		var anteil: float = float(zaehler.get(typ, 0)) / float(maxi(gesamt, 1))
		if anteil < 0.12 or anteil > 0.28:
			gleichmaessig = false
	print("INFO Rekruten-Verteilung (%d): %s" % [gesamt, str(zaehler)])
	_assert(ungueltig == 0 and gesamt >= 12 * 20, "jeder Rekrut hat einen gueltigen Typ (%d von %d)" % [gesamt - ungueltig, gesamt])
	_assert(gleichmaessig, "Rekruten sind ueber die fuenf Typen etwa gleich verteilt (%s)" % str(zaehler))
	var kader_a: Dictionary = START_ROSTER_GENERATOR.call("generate_start_roster", "funk_p3_wiederholung", 24, "funk_test")
	var kader_b: Dictionary = START_ROSTER_GENERATOR.call("generate_start_roster", "funk_p3_wiederholung", 24, "funk_test")
	var gleich: bool = true
	for index in range(Array(kader_a.units).size()):
		if String(Dictionary(kader_a.units[index]).get("personality", "")) != String(Dictionary(kader_b.units[index]).get("personality", "x")):
			gleich = false
	_assert(gleich, "gleicher Startwert ergibt dieselben Typen (kein neuer globaler Zufall)")
	# Rekruten der Polisa-Station / Gefechtseinkauf (build_points_person nutzt denselben Erzeuger).
	var einrichtung = SKIRMISH_START_CONFIGURATION.new()
	var typen_gesehen: Dictionary = {}
	for nummer in range(30):
		var profil: Dictionary = einrichtung.call("build_points_person", {"role": "operator", "experience": "junior", "armor": "suit", "weapon": "pistol"}, "funk_p3_rekrut_%d" % nummer, {})
		typen_gesehen[String(profil.get("personality", ""))] = true
	var alle_gueltig: bool = true
	for typ in typen_gesehen.keys():
		if not ERWARTETE_TYPEN.has(String(typ)):
			alle_gueltig = false
	_assert(alle_gueltig and typen_gesehen.size() >= 3, "gekaufte Rekruten tragen gueltige, gemischte Typen (%s)" % str(typen_gesehen.keys()))
	# Gegner und neutrale NPCs: fester Typ aus der Kennung.
	var kennungen: PackedStringArray = ["enemy_01", "enemy_02", "enemy_03", "enemy_04", "civilian_01", "civilian_02", "guard_7", "trader_3", "raider_12", "pirate_9"]
	var feste_typen: Dictionary = {}
	var stabil: bool = true
	for kennung in kennungen:
		var erst: String = String(PERSONALITY_CATALOG.call("from_id", kennung))
		var zweit: String = String(PERSONALITY_CATALOG.call("from_id", kennung))
		if erst != zweit or not ERWARTETE_TYPEN.has(erst):
			stabil = false
		feste_typen[erst] = true
	_assert(stabil and feste_typen.size() >= 3, "Gegner und Neutrale: Typ folgt fest aus der Kennung, mehrere Typen kommen vor (%s)" % str(feste_typen.keys()))


func _pruefe_speichern_und_laden() -> void:
	var kader: Dictionary = START_ROSTER_GENERATOR.call("generate_start_roster", "funk_p3_speichern", 24, "funk_test")
	var einheiten: Array = Array(kader.get("units", [])).duplicate(true)
	einheiten[0]["personality"] = "draufgaenger"
	einheiten[1]["personality"] = "brummbaer"
	einheiten[2]["personality"] = "vorsichtig"
	kader["units"] = einheiten
	var gespeichert: Dictionary = PLAYER_ROSTER_STORE.call("save_roster", kader, "funk_test", SPEICHER_PFAD)
	_assert(bool(gespeichert.get("ok", false)), "Kader laesst sich speichern (%s)" % str(gespeichert.get("diagnostics", "")))
	var geladen: Dictionary = PLAYER_ROSTER_STORE.call("load_roster", "funk_test", SPEICHER_PFAD)
	_assert(bool(geladen.get("ok", false)), "Kader laesst sich laden")
	var neu: Array = Array(Dictionary(geladen.get("roster", {})).get("units", []))
	var behalten: bool = neu.size() == einheiten.size()
	for index in range(mini(neu.size(), einheiten.size())):
		if String(Dictionary(neu[index]).get("personality", "")) != String(Dictionary(einheiten[index]).get("personality", "?")):
			behalten = false
	_assert(behalten, "Speichern und Laden behaelt personality bei allen %d Personen" % neu.size())
	var profil = META_UNIT_PROFILE.new(Dictionary(neu[0]))
	_assert(String(profil.personality) == "draufgaenger", "geladene Person liefert ihr Profil mit personality")
	# Kampagnenstand: die Startleute als JSON (so liegen sie im Speicherpunkt) und zurueck.
	var startleute_json: String = JSON.stringify(CAMPAIGN_START_CONFIGURATION.new().call("_initial_roster"))
	var zurueck: Array = JSON.parse_string(startleute_json)
	_assert(String(Dictionary(zurueck[0]).get("personality", "")) == "profi" and String(Dictionary(zurueck[1]).get("personality", "")) == "spassvogel", "Startleute behalten personality durch JSON (Speicherpunkt)")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SPEICHER_PFAD))


# ---------------------------------------------------------------- Blase

func _pruefe_blase_aus_einer_quelle() -> void:
	COMMUNICATION_COPY.call("clear_cache")
	var copy: Dictionary = _lies_json(COPY_PFAD)
	var behalten: PackedStringArray = ["schema_version", "purpose", "timing", "direction_words", "events", "triggers", "command_occasions", "validation"]
	var fremd: PackedStringArray = PackedStringArray()
	for schluessel in copy.keys():
		if not behalten.has(String(schluessel)):
			fremd.append(String(schluessel))
	_assert(fremd.is_empty(), "tactical_communication_copy.json hat keine eigene Satzgruppe mehr (Fremdes: %s)" % ", ".join(fremd))
	var mit_saetzen: PackedStringArray = PackedStringArray()
	for gruppe in ["events", "triggers"]:
		for name in Dictionary(copy.get(gruppe, {})).keys():
			var eintrag: Dictionary = Dictionary(Dictionary(copy[gruppe]).get(name, {}))
			if eintrag.has("copy") or eintrag.has("short") or eintrag.has("detail"):
				mit_saetzen.append("%s.%s" % [gruppe, name])
	_assert(mit_saetzen.is_empty(), "Ereignisse und Ausloeser tragen nur Anlass, Dauer, Vorrang, Kartentext (Saetze gefunden: %s)" % ", ".join(mit_saetzen))
	var katalog: Dictionary = _lies_json(SATZ_PFAD)
	var unbekannt: PackedStringArray = PackedStringArray()
	for gruppe in ["events", "triggers"]:
		for name in Dictionary(copy.get(gruppe, {})).keys():
			var anlass: String = String(Dictionary(Dictionary(copy[gruppe]).get(name, {})).get("occasion", ""))
			if anlass.is_empty() or not katalog.has(anlass):
				unbekannt.append("%s.%s -> '%s'" % [gruppe, name, anlass])
	for schluessel in Dictionary(copy.get("command_occasions", {})).keys():
		var anlass2: String = String(Dictionary(copy["command_occasions"]).get(schluessel, ""))
		if not katalog.has(anlass2):
			unbekannt.append("command_occasions.%s -> '%s'" % [schluessel, anlass2])
	_assert(unbekannt.is_empty(), "jeder Ereignis-, Ausloeser- und Befehlsanlass zeigt auf einen Anlass in funk_saetze.json (Fehlende: %s)" % ", ".join(unbekannt))
	for fehler in ["select_tile_first", "no_los", "default"]:
		_assert(not String(COMMUNICATION_COPY.call("validation_text", fehler)).is_empty(), "Fehlermeldung %s bleibt in der Datei" % fehler)
	# Die Fehlermeldungen selbst: deutsch, ohne Ersatzumlaute.
	var probleme: PackedStringArray = PackedStringArray()
	for text in Dictionary(copy.get("validation", {})).values():
		_sammle_textfehler(String(text), probleme)
	_assert(probleme.is_empty(), "Fehlermeldungen der Befehlspruefung sind deutsch (Funde: %s)" % " | ".join(probleme))


func _pruefe_zuordnung_der_anlaesse() -> void:
	var erwartet: Dictionary = {
		"move.accepted": "befehl_verstanden", "move.running": "unterwegs", "move.done": "ziel_erreicht",
		"engage.contact": "feindkontakt", "default.blocked": "blockiert",
	}
	for schluessel in erwartet.keys():
		var teile: PackedStringArray = String(schluessel).split(".")
		_assert(String(COMMUNICATION_COPY.call("occasion_for_command", teile[0], teile[1])) == String(erwartet[schluessel]), "Befehl %s -> %s" % [schluessel, erwartet[schluessel]])
	_assert(String(COMMUNICATION_COPY.call("occasion_for_event", "needs_orders", "")) == "braucht_befehl", "Ereignis needs_orders -> braucht_befehl")
	_assert(String(COMMUNICATION_COPY.call("occasion_for_event", "air_asset_threatened", "")) == "schiff_in_gefahr", "Ereignis air_asset_threatened -> schiff_in_gefahr")
	_assert(String(COMMUNICATION_COPY.call("occasion_for_event", "phase_completed", "inserted")) == "abgesetzt", "Ausloeser inserted geht vor der Ereignisart (abgesetzt)")
	_assert(String(COMMUNICATION_COPY.call("occasion_for_event", "objective_complete", "mission_complete")) == "auftrag_erfuellt", "Ausloeser mission_complete -> auftrag_erfuellt")
	_assert(String(COMMUNICATION_COPY.call("occasion_for_event", "phase_completed", "retreat")) == "rueckzug", "Ausloeser retreat -> rueckzug")
	var abgedeckt: Dictionary = {}
	var copy: Dictionary = _lies_json(COPY_PFAD)
	for gruppe in ["events", "triggers"]:
		for eintrag in Dictionary(copy.get(gruppe, {})).values():
			abgedeckt[String(Dictionary(eintrag).get("occasion", ""))] = true
	for schluessel in Dictionary(copy.get("command_occasions", {})).values():
		abgedeckt[String(schluessel)] = true
	var fehlt: PackedStringArray = PackedStringArray()
	for anlass in ANLAESSE_TRUPPFUEHRER:
		if not abgedeckt.has(anlass):
			fehlt.append(anlass)
	_assert(fehlt.is_empty(), "alle zehn Anlaesse des Truppfuehrers sind zugeordnet (fehlen: %s)" % ", ".join(fehlt))


func _baue_truppfuehrer(unit_id: String, fireteam_id: String, personality: String):
	var einheit = TEST_UNIT_SCRIPT.new()
	var konfig: Dictionary = {"unit_id": unit_id, "display_name": unit_id, "fireteam_id": fireteam_id, "is_fireteam_lead": true}
	if not personality.is_empty():
		konfig["personality"] = personality
	einheit.call("apply_identity_config", konfig, false)
	return einheit


func _pruefe_zwei_truppfuehrer() -> void:
	COMMUNICATION_COPY.call("reset_counters")
	var profi = _baue_truppfuehrer("ftl_profi", "blue", "profi")
	var draufgaenger = _baue_truppfuehrer("ftl_draufgaenger", "gold", "draufgaenger")
	var spassvogel = _baue_truppfuehrer("ftl_spassvogel", "red", "spassvogel")
	var ohne_feld = _baue_truppfuehrer("ftl_ohne_feld", "green", "")
	var texte: Dictionary = {}
	for leiter in [profi, draufgaenger, spassvogel, ohne_feld]:
		var kennung: String = String(leiter.call("get_unit_id"))
		var fireteam_id: String = String(leiter.call("get_fireteam_id"))
		for klarheit in [0.2, 0.9]:
			var ereignis: Dictionary = COMMUNICATION_RESOLVER.call("build_event", "order_received", {
				"fireteam_id": fireteam_id, "unit_id": kennung, "team": fireteam_id.to_upper(), "communication_clarity": klarheit,
				"event_id": "persoenlichkeit_%s_%s" % [kennung, str(klarheit)],
			}, {"now_msec": 1000})
			var blase: Dictionary = COMMUNICATION_RESOLVER.call("build_bubble_payload", ereignis, leiter, Vector2(100.0, 100.0), {}, {"fireteam_id": fireteam_id, "unit_id": kennung})
			texte["%s/%s" % [kennung, str(klarheit)]] = String(blase.get("text", ""))
			_assert(bool(blase.get("ok", false)) and not String(blase.get("text", "")).is_empty(), "Blase von %s bei Funkguete %s hat einen Satz: '%s'" % [kennung, str(klarheit), String(blase.get("text", ""))])
			_assert(String(blase.get("text_source", "")) == "funk_saetze", "Satzquelle der Blase ist funk_saetze (%s)" % String(blase.get("text_source", "")))
	print("INFO Befehl 'verstanden' schlechte Funkguete: profi='%s' | draufgaenger='%s' | spassvogel='%s'" % [texte["ftl_profi/0.2"], texte["ftl_draufgaenger/0.2"], texte["ftl_spassvogel/0.2"]])
	print("INFO Befehl 'verstanden' gute Funkguete: profi='%s' | draufgaenger='%s' | spassvogel='%s'" % [texte["ftl_profi/0.9"], texte["ftl_draufgaenger/0.9"], texte["ftl_spassvogel/0.9"]])
	_assert(texte["ftl_profi/0.9"] != texte["ftl_draufgaenger/0.9"] and texte["ftl_profi/0.2"] != texte["ftl_draufgaenger/0.2"], "Profi und Draufgaenger antworten auf denselben Befehl verschieden")
	_assert(texte["ftl_spassvogel/0.9"] != texte["ftl_profi/0.9"] and texte["ftl_spassvogel/0.9"] != texte["ftl_draufgaenger/0.9"], "Spassvogel antwortet wieder anders")
	for kennung in ["ftl_profi", "ftl_draufgaenger", "ftl_spassvogel", "ftl_ohne_feld"]:
		var typ: String = {"ftl_profi": "profi", "ftl_draufgaenger": "draufgaenger", "ftl_spassvogel": "spassvogel", "ftl_ohne_feld": "profi"}[kennung]
		var erlaubt: Array = []
		for anlass in ["befehl_verstanden"]:
			erlaubt.append_array(_alle_fassungen(anlass, typ, "kurz"))
		_assert(_passt_auf_fassung(String(texte["%s/0.2" % kennung]), erlaubt), "schlechte Funkguete: %s spricht die kurze Fassung (%s)" % [kennung, String(texte["%s/0.2" % kennung])])
		var erlaubt_genau: Array = _alle_fassungen("befehl_verstanden", typ, "genau")
		_assert(_passt_auf_fassung(String(texte["%s/0.9" % kennung]), erlaubt_genau), "gute Funkguete: %s spricht die genaue Fassung (%s)" % [kennung, String(texte["%s/0.9" % kennung])])
	_assert(texte["ftl_ohne_feld/0.9"].length() > 0 and _passt_auf_fassung(String(texte["ftl_ohne_feld/0.9"]), _alle_fassungen("befehl_verstanden", "profi", "genau")), "Truppfuehrer ohne Feld spricht wie profi")
	# Befehlsrueckmeldung (Knopf/Befehl am Truppfuehrer) laeuft ueber dieselbe Quelle.
	COMMUNICATION_COPY.call("reset_counters")
	var befehl_profi: Dictionary = FEEDBACK_BUBBLE_RESOLVER.call("build_command_feedback", "move", "accepted", profi, Vector2(50.0, 50.0), {}, {"fireteam_id": "blue", "unit_id": "ftl_profi"})
	var befehl_dauf: Dictionary = FEEDBACK_BUBBLE_RESOLVER.call("build_command_feedback", "move", "accepted", draufgaenger, Vector2(50.0, 50.0), {}, {"fireteam_id": "gold", "unit_id": "ftl_draufgaenger"})
	_assert(String(befehl_profi.get("text", "")) != String(befehl_dauf.get("text", "")) and String(befehl_profi.get("text_source", "")) == "funk_saetze", "Befehlsrueckmeldung: Profi '%s' / Draufgaenger '%s'" % [String(befehl_profi.get("text", "")), String(befehl_dauf.get("text", ""))])
	# Kontakt mit Richtung: {richtung} kommt aus dem Ereigniskontext.
	var kontakt: Dictionary = COMMUNICATION_RESOLVER.call("build_event", "contact_report", {"fireteam_id": "blue", "unit_id": "ftl_profi", "direction_label": "Nordost", "communication_clarity": 0.9, "team": "BLUE", "event_id": "persoenlichkeit_kontakt"}, {"now_msec": 1000})
	var kontakt_blase: Dictionary = COMMUNICATION_RESOLVER.call("build_bubble_payload", kontakt, profi, Vector2(100.0, 100.0), {}, {"fireteam_id": "blue", "unit_id": "ftl_profi"})
	print("INFO Kontakt Nordost, gute Funkguete, Profi: '%s'" % String(kontakt_blase.get("text", "")))
	_assert(String(kontakt_blase.get("text", "")).contains("Nordost") or String(kontakt_blase.get("text", "")).begins_with("Kontakt") or String(kontakt_blase.get("text", "")).begins_with("Feindkontakt"), "Kontaktmeldung nutzt Richtung oder nennt den Kontakt ('%s')" % String(kontakt_blase.get("text", "")))
	_assert(not String(kontakt_blase.get("text", "")).contains("{"), "kein Platzhalter-Rest in der Blase")
	for leiter in [profi, draufgaenger, spassvogel, ohne_feld]:
		leiter.free()


func _alle_fassungen(anlass: String, typ: String, stufe: String) -> Array:
	var ergebnis: Array = []
	for fassung in Array(FUNK_SAETZE.call("variants", anlass, typ, stufe)):
		ergebnis.append(String(FUNK_SAETZE.call("fill", String(fassung), {"team": "", "richtung": "", "ziel": "", "name": "", "kamerad": ""})))
		ergebnis.append(String(fassung))
	return ergebnis


## Passt der Satz auf eine Fassung (mit beliebigem Wert statt Platzhalter, z. B. Truppname)?
func _passt_auf_fassung(satz: String, fassungen: Array) -> bool:
	var platzhalter := RegEx.new()
	platzhalter.compile("\\{[a-z]+\\}")
	for fassung_variant in fassungen:
		var fassung: String = String(fassung_variant)
		if fassung == satz:
			return true
		if not fassung.contains("{"):
			continue
		var regex_text: String = "^"
		var position: int = 0
		for treffer in platzhalter.search_all(fassung):
			regex_text += _regex_maskiert(fassung.substr(position, treffer.get_start() - position)) + ".+"
			position = treffer.get_end()
		regex_text += _regex_maskiert(fassung.substr(position)) + "$"
		var regex := RegEx.new()
		if regex.compile(regex_text) == OK and regex.search(satz) != null:
			return true
	return false


func _regex_maskiert(text: String) -> String:
	var ergebnis: String = text.replace("\\", "\\\\")
	for zeichen in [".", "+", "*", "?", "[", "]", "^", "$", "(", ")", "{", "}", "|"]:
		ergebnis = ergebnis.replace(zeichen, "\\" + zeichen)
	return ergebnis


# ---------------------------------------------------------------- Charakterblatt

func _pruefe_charakterblatt(fenster: Vector2i) -> void:
	var praefix: String = "[%dx%d] " % [fenster.x, fenster.y]
	root.size = fenster
	var typ_profil = META_UNIT_PROFILE.new({"unit_id": "blatt_1", "display_name": "Mara Seidel", "personality": "spassvogel", "role_name": "Sanitaeter"})
	var modell: Dictionary = CHARACTER_SHEET_FORMATTER.call("build_sheet_view_model", typ_profil, {})
	_assert(String(modell.get("personality_text", "")) == "Persönlichkeit: Spaßvogel", praefix + "Charakterblatt-Modell: 'Persönlichkeit: Spaßvogel' (%s)" % String(modell.get("personality_text", "")))
	_assert(String(modell.get("personality_description", "")) == String(PERSONALITY_CATALOG.call("description", "spassvogel")) and not String(modell.get("personality_description", "")).is_empty(), praefix + "Charakterblatt-Modell: Beschreibungssatz steht dabei")
	var ohne_feld = META_UNIT_PROFILE.new({"unit_id": "blatt_2", "display_name": "Ohne Feld"})
	_assert(String(CHARACTER_SHEET_FORMATTER.call("build_personality_text", ohne_feld)) == "Persönlichkeit: Profi", praefix + "Person ohne Feld zeigt 'Persönlichkeit: Profi'")
	for kompakt in [true, false]:
		var traeger := Control.new()
		traeger.size = Vector2(fenster)
		root.add_child(traeger)
		var scroll := ScrollContainer.new()
		scroll.size = Vector2(fenster)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		traeger.add_child(scroll)
		var host := VBoxContainer.new()
		host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(host)
		CHARACTER_SHEET_VIEW.call("render", host, typ_profil, {"compact_read_only": kompakt, "compact_sheet_width": 520})
		for _frame in range(4):
			await process_frame
		var beschriftung := host.find_child("CharacterPersonality", true, false) as Label
		var beschreibung := host.find_child("CharacterPersonalityDescription", true, false) as Label
		var art: String = "kompakt" if kompakt else "gross"
		_assert(beschriftung != null and beschriftung.text == "Persönlichkeit: Spaßvogel", praefix + "Blatt (%s) zeigt 'Persönlichkeit: Spaßvogel'" % art)
		_assert(beschreibung != null and beschreibung.text == String(PERSONALITY_CATALOG.call("description", "spassvogel")), praefix + "Blatt (%s) zeigt den Beschreibungssatz" % art)
		if beschriftung != null and beschreibung != null:
			var rect: Rect2 = beschriftung.get_global_rect()
			_assert(rect.size.x > 40.0 and rect.size.y > 8.0 and rect.end.x <= float(fenster.x) + 1.0, praefix + "Blatt (%s): Persoenlichkeit liegt im Bild (%s)" % [art, str(rect)])
			_assert(not beschriftung.get_global_rect().intersects(beschreibung.get_global_rect()), praefix + "Blatt (%s): Name und Beschreibung ueberdecken sich nicht" % art)
		traeger.queue_free()
		await process_frame


# ---------------------------------------------------------------- Einsatz

func _pruefe_mission() -> void:
	root.size = Vector2i(1280, 720)
	var prefix: String = "[Einsatz] "
	var mission: Node = MISSION_SCENE.instantiate()
	root.add_child(mission)
	for _frame in range(14):
		await process_frame
	var controller: Node = mission.get_node("TacticalController")
	COMMUNICATION_COPY.call("reset_counters")
	var blau = controller.call("_resolve_fireteam_leader_for_behavior", "blue")
	var gold = controller.call("_resolve_fireteam_leader_for_behavior", "gold")
	_assert(blau != null and gold != null, prefix + "beide Truppfuehrer sind da")
	if blau == null or gold == null:
		mission.queue_free()
		return
	blau.set("personality", "draufgaenger")
	gold.set("personality", "profi")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue", "gold"]), false)
	controller.call("create_area_order_for_fireteams_from_world_rect", PackedStringArray(["blue", "gold"]), Vector2(880.0, 880.0), Vector2(1020.0, 1000.0), "take")
	controller.call("_refresh_order_visuals")
	for _frame in range(10):
		await process_frame
	var blasen: Array = Array(controller.call("get_fireteamleader_feedback_bubble_snapshot"))
	var text_blau: String = ""
	var text_gold: String = ""
	for blase_variant in blasen:
		var blase: Dictionary = Dictionary(blase_variant)
		if String(blase.get("fireteam_id", "")) == "blue":
			text_blau = String(blase.get("text", ""))
		elif String(blase.get("fireteam_id", "")) == "gold":
			text_gold = String(blase.get("text", ""))
	print("INFO Einsatz, gleicher Befehl: FT blau (Draufgaenger) '%s' | FT gold (Profi) '%s'" % [text_blau, text_gold])
	_assert(not text_blau.is_empty() and not text_gold.is_empty(), prefix + "beide Trupps sprechen")
	_assert(text_blau != text_gold, prefix + "zwei Trupps mit Profi und Draufgaenger antworten auf denselben Befehl verschieden")
	var draufgaenger_saetze: Array = []
	var profi_saetze: Array = []
	for anlass in ANLAESSE_TRUPPFUEHRER:
		for stufe in ["kurz", "genau"]:
			draufgaenger_saetze.append_array(_alle_fassungen(anlass, "draufgaenger", stufe))
			profi_saetze.append_array(_alle_fassungen(anlass, "profi", stufe))
	_assert(_passt_auf_fassung(text_blau, draufgaenger_saetze), prefix + "Satz von blau stammt aus den Draufgaenger-Saetzen in funk_saetze.json")
	_assert(_passt_auf_fassung(text_gold, profi_saetze), prefix + "Satz von gold stammt aus den Profi-Saetzen in funk_saetze.json")
	# Meldungsfenster: deutsche Farbnamen statt BLUE/GOLD.
	var log_panel := mission.get_node_or_null("TacticalUI/TacticalEventLogPanel") as Control
	var zeilen: PackedStringArray = PackedStringArray()
	if log_panel != null:
		for knoten in log_panel.find_children("EventTextLabel", "Label", true, false):
			zeilen.append((knoten as Label).text)
	print("INFO Meldungsfenster: %s" % " | ".join(zeilen))
	var hat_alt: bool = false
	var hat_farbe: bool = false
	for zeile in zeilen:
		if zeile.contains("BLUE") or zeile.contains("GOLD"):
			hat_alt = true
		if zeile.begins_with("Blau") or zeile.begins_with("Gold"):
			hat_farbe = true
	_assert(not zeilen.is_empty() and hat_farbe and not hat_alt, prefix + "Meldungsfenster zeigt Blau/Gold statt BLUE/GOLD")
	mission.queue_free()
	await process_frame


func _pruefe_farbnamen() -> void:
	var farben: GDScript = load("res://scripts/tactical/trupp_farben.gd")
	farben.call("clear_cache")
	_assert(String(farben.call("display_name", "blue")) == "Blau" and String(farben.call("display_name", "BLUE")) == "Blau", "Kennung blue wird als Blau angezeigt")
	_assert(String(farben.call("display_name", "red")) == "Rot" and String(farben.call("display_name", "green")) == "Grün" and String(farben.call("display_name", "yellow")) == "Gelb", "Rot, Grün, Gelb")
	_assert(String(farben.call("display_name", "ft7")) == "FT7", "nicht zugeordnete Kennung bleibt wie bisher (FT7)")
	_assert(String(farben.call("display_name", "ft7", "Pioniertrupp")) == "Pioniertrupp", "nicht zugeordnete Kennung nimmt die Ersatzanzeige")
	var text: String = String(COMMUNICATION_RESOLVER.call("build_selected_fireteam_text", [{"event_id": "farbe_1", "event_type": "order_received", "fireteam_id": "blue", "priority": 50, "channels": PackedStringArray(["selected_fireteam"]), "short_text": "Verstanden."}], PackedStringArray(["blue"]), 2))
	_assert(text == "Blau: Verstanden.", "Meldungstext der Auswahl beginnt mit 'Blau:' (%s)" % text)
	var satz: String = String(COMMUNICATION_COPY.call("leader_text", "befehl_verstanden", "profi", "high", "farbe_test", {"team": "BLUE"}, false))
	_assert(not satz.contains("BLUE"), "{team} in Saetzen nennt den Farbnamen (%s)" % satz)


# ---------------------------------------------------------------- Hilfen

func _sammle_textfehler(text: String, probleme: PackedStringArray) -> void:
	var wort_regex := RegEx.new()
	wort_regex.compile("[A-Za-zÄÖÜäöüß]+")
	for treffer in wort_regex.search_all(text):
		var wort: String = treffer.get_string()
		var klein: String = wort.to_lower()
		if ENGLISCHE_WOERTER.has(klein):
			probleme.append("Englisch '%s' in: %s" % [wort, text])
		if klein.contains("ae") or klein.contains("oe"):
			probleme.append("Ersatzumlaut '%s' in: %s" % [wort, text])
		var ue_regex := RegEx.new()
		ue_regex.compile("(^|[^aeiouäöü])ue")
		if ue_regex.search(klein) != null and not ERLAUBTE_UE_WOERTER.has(klein):
			probleme.append("Ersatzumlaut '%s' in: %s" % [wort, text])
		for stamm in VERBOTENE_WORTSTAMMME_SS:
			if klein.contains(stamm):
				probleme.append("ss statt ß '%s' in: %s" % [wort, text])


func _lies_json(pfad: String) -> Dictionary:
	if not FileAccess.file_exists(pfad):
		return {}
	var datei := FileAccess.open(pfad, FileAccess.READ)
	if datei == null:
		return {}
	var geparst: Variant = JSON.parse_string(datei.get_as_text())
	datei.close()
	return Dictionary(geparst) if typeof(geparst) == TYPE_DICTIONARY else {}


func _assert(bedingung: bool, nachricht: String) -> void:
	if bedingung:
		_passed += 1
		print("PASS: %s" % nachricht)
		return
	_failed += 1
	print("FAIL: %s" % nachricht)
