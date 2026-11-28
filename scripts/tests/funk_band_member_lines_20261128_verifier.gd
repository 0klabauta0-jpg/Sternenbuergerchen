extends SceneTree
## Paket 2 (Funk): Die Mitglieder des ausgewaehlten Fireteams sprechen im Band (Bilderstreifen der Truppkarte).
## Prueft Satzdatei, Auswahl, Bremse, Lage der Zeilen an den Bildern (1280x720 und 1920x1080), den Truppfuehrer,
## "nichts ohne Auswahl", die Zeile im Meldungsfenster fuer wichtige Saetze und die Gedanken im Band.

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")
const FUNK_SAETZE: GDScript = preload("res://scripts/tactical/funk_saetze.gd")
const FUNK_BAND_LINES: GDScript = preload("res://scripts/tactical/funk_band_lines.gd")
const SATZ_PFAD: String = "res://data/comms/funk_saetze.json"
const BAND_PFAD: String = "TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/A5TeamPortraits"
const PANEL_PFAD: String = "TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel"
const LOG_PFAD: String = "TacticalUI/TacticalEventLogPanel"
const ERWARTETE_ANLAESSE: PackedStringArray = [
	"befehl_verstanden", "unterwegs", "ziel_erreicht", "feindkontakt", "blockiert", "braucht_befehl", "getroffen", "liegt",
	"gerettet", "kamerad_faellt", "gegner_erledigt", "magazin_leer", "nachladen", "eingestiegen", "abgesetzt",
	"schiff_in_gefahr", "auftrag_erfuellt", "rueckzug", "angst", "mut",
]
const ERWARTETE_TYPEN: PackedStringArray = ["profi", "draufgaenger", "vorsichtig", "spassvogel", "brummbaer"]
## Ersatzschreibung statt Umlaut und Abkuerzungen/englische Woerter, die in Saetzen nicht stehen duerfen.
const VERBOTENE_WORTSTAMMME_SS: PackedStringArray = ["fuss", "strass", "gross", "heiss", "weiss", "schliess", "gruss", "draussen", "ausser", "beiss", "spass", "stoss", "fliess"]
const ERLAUBTE_UE_WOERTER: PackedStringArray = ["neue", "neuen", "neues", "neuer", "neuem"]
const ENGLISCHE_WOERTER: PackedStringArray = [
	"air", "asset", "orders", "order", "block", "lz", "recovery", "contact", "objective", "roger", "copy", "over", "out", "down",
	"hit", "medic", "reload", "ammo", "enemy", "hostile", "status", "ok", "okay", "team", "fireteam", "dropship", "go", "sorry",
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== Mitglieder sprechen im Band (Funk Paket 2) ===")
	_pruefe_satzdatei()
	_pruefe_auswahl()
	_pruefe_bremse()
	await _pruefe_mission(Vector2i(1280, 720))
	await _pruefe_mission(Vector2i(1920, 1080))
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


# ---------------------------------------------------------------- Satzdatei

func _pruefe_satzdatei() -> void:
	FUNK_SAETZE.call("clear_cache")
	var katalog: Dictionary = _lies_json(SATZ_PFAD)
	_assert(not katalog.is_empty(), "funk_saetze.json ist lesbar")
	_assert(katalog.size() == ERWARTETE_ANLAESSE.size(), "genau %d Anlaesse (%d)" % [ERWARTETE_ANLAESSE.size(), katalog.size()])
	var voller_kontext: Dictionary = {"name": "Mara", "team": "Blau", "richtung": "Nordost", "ziel": "Schiff", "kamerad": "Jonas"}
	var alle_saetze: int = 0
	var probleme: PackedStringArray = PackedStringArray()
	for anlass in ERWARTETE_ANLAESSE:
		_assert(katalog.has(anlass), "Anlass %s ist da" % anlass)
		var typen: Dictionary = Dictionary(katalog.get(anlass, {}))
		for typ in ERWARTETE_TYPEN:
			var eintrag: Dictionary = Dictionary(typen.get(typ, {}))
			for stufe in ["kurz", "genau"]:
				var liste: Array = Array(eintrag.get(stufe, []))
				if liste.is_empty():
					probleme.append("%s/%s/%s leer" % [anlass, typ, stufe])
					continue
				for satz_variant in liste:
					var satz: String = String(satz_variant)
					alle_saetze += 1
					var gefuellt: String = String(FUNK_SAETZE.call("fill", satz, voller_kontext))
					var gefuellt_leer: String = String(FUNK_SAETZE.call("fill", satz, {}))
					if gefuellt.contains("{") or gefuellt.contains("}") or gefuellt_leer.contains("{") or gefuellt_leer.contains("}"):
						probleme.append("Platzhalter bleibt: %s" % satz)
					if gefuellt.strip_edges().is_empty():
						probleme.append("leer: %s/%s/%s" % [anlass, typ, stufe])
					_sammle_textfehler(gefuellt, probleme)
					if stufe == "kurz" and gefuellt_leer.split(" ", false).size() > 4:
						probleme.append("kurz ist zu lang: %s" % satz)
					if stufe == "genau" and gefuellt.split(" ", false).size() > 12:
						probleme.append("genau ist zu lang: %s" % satz)
		for typ in typen.keys():
			if not ERWARTETE_TYPEN.has(String(typ)):
				probleme.append("unbekannter Typ %s in %s" % [typ, anlass])
	_assert(alle_saetze >= 20 * 5 * 2 * 2, "Satzdatei enthaelt alle Saetze des freigegebenen Entwurfs (%d)" % alle_saetze)
	_assert(probleme.is_empty(), "jeder Anlass hat jeden Typ in kurz und genau, ohne Platzhalter-Reste, Ersatzumlaute oder Englisch (Funde: %s)" % " | ".join(probleme))
	# Wortlaut-Stichproben aus dem freigegebenen Entwurf.
	_assert(Array(FUNK_SAETZE.call("variants", "liegt", "profi", "genau")).has("Ich liege, ich brauche einen Sanitäter."), "Stichprobe liegt/profi/genau wortgetreu")
	_assert(Array(FUNK_SAETZE.call("variants", "kamerad_faellt", "spassvogel", "genau")).has("{kamerad} ist gefallen, ich sage nichts mehr dazu."), "Stichprobe kamerad_faellt/spassvogel/genau wortgetreu (ernst)")
	_assert(Array(FUNK_SAETZE.call("variants", "magazin_leer", "brummbaer", "kurz")).has("Schon wieder."), "Stichprobe magazin_leer/brummbaer/kurz wortgetreu")


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
		# "ue" nach einem Selbstlaut ist echtes Deutsch (gedauert, genaue, neue); Ersatz fuer ü steht nach Mitlaut oder am Wortanfang.
		var ue_regex := RegEx.new()
		ue_regex.compile("(^|[^aeiouäöü])ue")
		if ue_regex.search(klein) != null and not ERLAUBTE_UE_WOERTER.has(klein):
			probleme.append("Ersatzumlaut '%s' in: %s" % [wort, text])
		for stamm in VERBOTENE_WORTSTAMMME_SS:
			if klein.contains(stamm):
				probleme.append("ss statt ß '%s' in: %s" % [wort, text])


# ---------------------------------------------------------------- Auswahl

func _pruefe_auswahl() -> void:
	var kontext: Dictionary = {"kamerad": "Jonas", "richtung": "Nord", "ziel": "Schiff", "team": "Blau"}
	var a1: String = String(FUNK_SAETZE.call("pick", "getroffen", "profi", 0.8, "unit_a", 0, kontext))
	var a2: String = String(FUNK_SAETZE.call("pick", "getroffen", "profi", 0.8, "unit_a", 0, kontext))
	_assert(not a1.is_empty() and a1 == a2, "gleiche Eingaben ergeben denselben Satz (kein globaler Zufall): '%s'" % a1)
	var keine_wiederholung: bool = true
	for anlass in ERWARTETE_ANLAESSE:
		for typ in ERWARTETE_TYPEN:
			for stufe_klarheit in [0.2, 0.9]:
				var vorher: String = ""
				for zaehler in range(8):
					var satz: String = String(FUNK_SAETZE.call("pick", anlass, typ, stufe_klarheit, "unit_x", zaehler, kontext))
					if satz.is_empty() or (zaehler > 0 and satz == vorher):
						keine_wiederholung = false
					vorher = satz
	_assert(keine_wiederholung, "keine direkte Wiederholung desselben Satzes (alle Anlaesse, Typen, beide Stufen)")
	var ohne_typ: String = String(FUNK_SAETZE.call("pick", "liegt", "", 0.8, "unit_a", 0, kontext))
	var profi: String = String(FUNK_SAETZE.call("pick", "liegt", "profi", 0.8, "unit_a", 0, kontext))
	var unbekannt: String = String(FUNK_SAETZE.call("pick", "liegt", "gibtsnicht", 0.8, "unit_a", 0, kontext))
	_assert(ohne_typ == profi and unbekannt == profi and not profi.is_empty(), "fehlende oder unbekannte Persoenlichkeit = profi")
	var kurz_ok: bool = Array(FUNK_SAETZE.call("variants", "liegt", "profi", "kurz")).has(String(FUNK_SAETZE.call("pick", "liegt", "profi", 0.1, "u", 0, {})))
	var genau_ok: bool = Array(FUNK_SAETZE.call("variants", "liegt", "profi", "genau")).has(String(FUNK_SAETZE.call("pick", "liegt", "profi", 0.9, "u", 0, {})))
	_assert(kurz_ok and genau_ok, "schlechte Funkguete waehlt die kurze, gute die genaue Fassung")
	var mit_namen: String = String(FUNK_SAETZE.call("pick", "kamerad_faellt", "profi", 0.9, "u", 0, {"kamerad": "Jonas Weber"}))
	_assert(mit_namen.contains("Jonas Weber") and not mit_namen.contains("{"), "{kamerad} wird ersetzt: '%s'" % mit_namen)
	_assert(String(FUNK_SAETZE.call("compass_label", Vector2(0, 0), Vector2(0, -10))) == "Nord" and String(FUNK_SAETZE.call("compass_label", Vector2(0, 0), Vector2(10, 0))) == "Ost", "Himmelsrichtung: oben = Nord, rechts = Ost")


# ---------------------------------------------------------------- Bremse (Zustand ohne Szene)

func _person(unit_id: String, fireteam: String = "blue") -> Dictionary:
	return {"unit_id": unit_id, "fireteam_id": fireteam, "name": "Name " + unit_id, "personality": "profi", "clarity": 0.8, "is_leader": false}


func _pruefe_bremse() -> void:
	var zeilen: RefCounted = FUNK_BAND_LINES.new()
	var t0: int = 100000
	var erste: Dictionary = Dictionary(zeilen.call("offer", _person("u1"), "getroffen", {}, t0))
	_assert(not erste.is_empty(), "erster Satz einer Person kommt durch")
	var dauer: int = int(erste.get("end_msec", 0)) - int(erste.get("start_msec", 0))
	_assert(dauer >= 3000 and dauer <= 5000, "Zeile steht 3 bis 5 Sekunden (%d ms)" % dauer)
	_assert(Dictionary(zeilen.call("offer", _person("u1"), "nachladen", {}, t0 + 1500)).is_empty(), "je Person hoechstens ein Satz alle 4 Sekunden")
	_assert(not Dictionary(zeilen.call("offer", _person("u1"), "nachladen", {}, t0 + 4100)).is_empty(), "nach 4 Sekunden darf dieselbe Person wieder")
	var band: RefCounted = FUNK_BAND_LINES.new()
	var t1: int = 200000
	var angenommen: int = 0
	for index in range(5):
		if not Dictionary(band.call("offer", _person("v%d" % index), "getroffen", {}, t1 + index * 50)).is_empty():
			angenommen += 1
	_assert(angenommen == 2, "im ganzen Band hoechstens 2 neue Saetze je Sekunde (%d)" % angenommen)
	_assert(not Dictionary(band.call("offer", _person("v9"), "liegt", {}, t1 + 300)).is_empty(), "ein wichtiger Satz (liegt) draengelt vor")
	_assert(not Dictionary(band.call("offer", _person("v0"), "liegt", {}, t1 + 400)).is_empty(), "wichtig: wer gerade getroffen meldete, darf trotzdem 'liegt' melden")
	_assert(Dictionary(band.call("offer", _person("v0"), "liegt", {}, t1 + 450)).is_empty(), "derselbe wichtige Anlass wird nicht doppelt gesprochen")
	_assert(not Dictionary(band.call("offer", _person("v20"), "getroffen", {}, t1 + 1500)).is_empty(), "nach einer Sekunde sind wieder neue Saetze moeglich")
	var aktiv: Array = Array(band.call("get_active_lines", t1 + 1000))
	_assert(aktiv.size() >= 3, "laufende Zeilen werden gefuehrt (%d)" % aktiv.size())
	var nach_ende: Array = Array(band.call("get_active_lines", t1 + 9000))
	_assert(nach_ende.is_empty(), "nach 5 Sekunden sind alle Zeilen verschwunden")
	var zeile: Dictionary = {"end_msec": 5000}
	_assert(float(FUNK_BAND_LINES.call("alpha_for", zeile, 1000)) == 1.0 and float(FUNK_BAND_LINES.call("alpha_for", zeile, 4800)) < 1.0 and float(FUNK_BAND_LINES.call("alpha_for", zeile, 5000)) == 0.0, "Zeile verblasst am Ende")


# ---------------------------------------------------------------- Mission

func _pruefe_mission(fenster: Vector2i) -> void:
	var vorsatz := "%dx%d: " % [fenster.x, fenster.y]
	root.size = fenster
	var mission: Node = MISSION_SCENE.instantiate()
	root.add_child(mission)
	for _frame in range(14):
		await process_frame
	var controller: Node = mission.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	for _frame in range(8):
		await process_frame
	var reihe := mission.get_node_or_null(BAND_PFAD) as Control
	_assert(reihe != null, vorsatz + "Band (A5TeamPortraits) ist da")
	if reihe == null:
		mission.queue_free()
		await process_frame
		return
	var bilder: Array = _sichtbare_bilder(reihe)
	_assert(bilder.size() >= 2, vorsatz + "Band zeigt die Mitglieder des ausgewaehlten Fireteams (%d)" % bilder.size())
	var breite_vorher: float = reihe.size.x
	var mindest_vorher: Vector2 = reihe.get_combined_minimum_size()
	var kinder_vorher: int = reihe.get_child_count()
	var panel := mission.get_node_or_null(PANEL_PFAD) as Control
	var panel_vorher: Vector2 = panel.size if panel != null else Vector2.ZERO
	var zeilen: RefCounted = controller.call("get_funk_band_lines")
	zeilen.call("reset")

	# Truppfuehrer und Mitglieder unterscheiden.
	var einheiten: Array = controller.call("_get_units_for_fireteam", "blue")
	var fuehrer = null
	var mitglieder: Array = []
	for einheit in einheiten:
		if einheit == null or not einheit.has_method("get_unit_id"):
			continue
		if bool(controller.call("_is_unit_current_fireteam_lead", einheit)):
			fuehrer = einheit
		else:
			mitglieder.append(einheit)
	_assert(fuehrer != null and mitglieder.size() >= 2, vorsatz + "BLUE hat Truppfuehrer und mindestens zwei Mitglieder (%d)" % mitglieder.size())
	if fuehrer == null or mitglieder.size() < 2:
		mission.queue_free()
		await process_frame
		return

	# Echte Ereignisse aus dem Spielcode: Treffer (nicht toedlich) und Niederlage.
	var treffer_einheit = mitglieder[0]
	var liegt_einheit = mitglieder[1]
	var treffer_id: String = String(treffer_einheit.call("get_unit_id"))
	var liegt_id: String = String(liegt_einheit.call("get_unit_id"))
	treffer_einheit.call("apply_damage", 1, {})
	for _frame in range(2):
		await process_frame
	var jetzt: int = Time.get_ticks_msec()
	var aktiv: Array = Array(zeilen.call("get_active_lines", jetzt))
	var treffer_zeile: Dictionary = _zeile_von(aktiv, treffer_id)
	_assert(String(treffer_zeile.get("occasion", "")) in ["getroffen", "angst"], vorsatz + "Treffer im Spiel loest 'getroffen' (oder 'angst' bei niedriger Moral) aus (%s)" % String(treffer_zeile.get("occasion", "")))
	var liegt_leben: int = int(liegt_einheit.call("get_health"))
	liegt_einheit.call("apply_damage", maxi(liegt_leben, 1), {})
	for _frame in range(2):
		await process_frame
	jetzt = Time.get_ticks_msec()
	aktiv = Array(zeilen.call("get_active_lines", jetzt))
	var liegt_zeile: Dictionary = _zeile_von(aktiv, liegt_id)
	_assert(String(liegt_zeile.get("occasion", "")) == "liegt", vorsatz + "Niederlage im Spiel loest 'liegt' aus (%s)" % String(liegt_zeile.get("occasion", "")))

	# Zeilen am richtigen Bild, nicht beim Truppfuehrer.
	var fuehrer_zeile: Dictionary = Dictionary(controller.call("report_member_funk_event", fuehrer, "getroffen", {}, jetzt + 20000))
	_assert(not fuehrer_zeile.is_empty() and bool(fuehrer_zeile.get("is_leader", false)), vorsatz + "Truppfuehrer wird als solcher erkannt")
	var angezeigt: Array = Array(controller.call("apply_funk_band_visuals", jetzt + 100, false))
	var gezeigte_ids: PackedStringArray = PackedStringArray()
	for eintrag_variant in angezeigt:
		gezeigte_ids.append(String(Dictionary(eintrag_variant).get("unit_id", "")))
	_assert(gezeigte_ids.has(treffer_id) and gezeigte_ids.has(liegt_id), vorsatz + "beide Mitglieder haben eine Zeile im Band (%s)" % ", ".join(gezeigte_ids))
	var fuehrer_id: String = String(fuehrer.call("get_unit_id"))
	_assert(not gezeigte_ids.has(fuehrer_id), vorsatz + "der Truppfuehrer steht im Band nicht doppelt")
	var panel_rect: Rect2 = reihe.get_global_rect()
	var zeilen_rects: Array = []
	for bild in _sichtbare_bilder(reihe):
		var bild_id: String = String(bild.get_meta("funk_band_unit_id", ""))
		var etikett := bild.get_node_or_null("FunkLine") as Label
		if bild_id == fuehrer_id:
			_assert(etikett == null or not etikett.visible, vorsatz + "am Bild des Truppfuehrers steht keine Zeile")
			continue
		if gezeigte_ids.has(bild_id):
			_assert(etikett != null and etikett.visible and not etikett.text.strip_edges().is_empty(), vorsatz + "Zeile steht am Bild von %s" % bild_id)
			if etikett != null and etikett.visible:
				var rect: Rect2 = etikett.get_global_rect()
				zeilen_rects.append(rect)
				_assert(rect.position.y >= panel_rect.position.y - 1.0 and rect.end.y <= panel_rect.end.y + 1.0, vorsatz + "Zeile von %s liegt im Hoehenbereich des Bands (%s in %s)" % [bild_id, str(rect), str(panel_rect)])
				_assert(rect.position.x >= panel_rect.position.x - 1.0 and rect.end.x <= panel_rect.end.x + 1.0, vorsatz + "Zeile von %s liegt im Breitenbereich des Bands" % bild_id)
				var bild_rect: Rect2 = bild.get_global_rect()
				_assert(rect.position.y >= bild_rect.position.y - 1.0 and rect.end.y <= bild_rect.end.y + 1.0, vorsatz + "Zeile von %s sitzt auf dem Bild (Hoehe)" % bild_id)
				_assert(rect.position.x <= bild_rect.end.x and rect.end.x >= bild_rect.position.x, vorsatz + "Zeile von %s beruehrt das eigene Bild (Breite)" % bild_id)
	# Zwei Zeilen duerfen sich nicht ueberlagern.
	for i in range(zeilen_rects.size()):
		for j in range(i + 1, zeilen_rects.size()):
			_assert(not Rect2(zeilen_rects[i]).intersects(Rect2(zeilen_rects[j])), vorsatz + "Zeilen ueberlagern sich nicht")
	# Keine Knoepfe verdeckt.
	var ueberdeckt: PackedStringArray = PackedStringArray()
	for knopf in _alle_knoepfe(mission.get_node("TacticalUI")):
		if not knopf.is_visible_in_tree():
			continue
		var knopf_rect: Rect2 = knopf.get_global_rect()
		if knopf_rect.size.x <= 0.0 or knopf_rect.size.y <= 0.0:
			continue
		for rect in zeilen_rects:
			if knopf_rect.intersects(Rect2(rect)):
				ueberdeckt.append(str(knopf.get_path()))
	_assert(ueberdeckt.is_empty(), vorsatz + "keine Zeile verdeckt einen Knopf (Funde: %s)" % ", ".join(ueberdeckt))
	# Band nicht breiter.
	_assert(is_equal_approx(reihe.size.x, breite_vorher) and reihe.get_combined_minimum_size().is_equal_approx(mindest_vorher) and reihe.get_child_count() == kinder_vorher, vorsatz + "Band wird durch die Zeilen nicht breiter (Breite %.0f, Mindestgroesse %s, Kinder %d)" % [reihe.size.x, str(reihe.get_combined_minimum_size()), reihe.get_child_count()])
	_assert(panel == null or panel.size.is_equal_approx(panel_vorher), vorsatz + "die Truppkarte aendert ihre Groesse nicht")
	# Lesbar: Schriftgroesse.
	for bild in _sichtbare_bilder(reihe):
		var etikett2 := bild.get_node_or_null("FunkLine") as Label
		if etikett2 != null and etikett2.visible:
			_assert(etikett2.get_theme_font_size("font_size") >= 11, vorsatz + "Schrift der Zeile ist mindestens 11 (%d)" % etikett2.get_theme_font_size("font_size"))
			break
	# Verblassen und Verschwinden.
	var letzte: Dictionary = treffer_zeile
	var ende: int = int(letzte.get("end_msec", jetzt + 3000))
	controller.call("apply_funk_band_visuals", ende - 300, false)
	var bild_treffer: Control = _bild_von(reihe, treffer_id)
	var etikett_treffer := bild_treffer.get_node_or_null("FunkLine") as Label if bild_treffer != null else null
	_assert(etikett_treffer != null and etikett_treffer.visible and etikett_treffer.modulate.a < 1.0 and etikett_treffer.modulate.a > 0.0, vorsatz + "die Zeile verblasst am Ende")
	controller.call("apply_funk_band_visuals", ende + 10, false)
	_assert(etikett_treffer == null or not etikett_treffer.visible, vorsatz + "danach ist die Zeile weg")

	# Bremse im Spiel: dieselbe Person sofort noch einmal, und viele Personen auf einmal.
	zeilen.call("reset")
	var t_start: int = Time.get_ticks_msec()
	var eins: Dictionary = Dictionary(controller.call("report_member_funk_event", mitglieder[0], "nachladen", {}, t_start))
	var zwei: Dictionary = Dictionary(controller.call("report_member_funk_event", mitglieder[0], "magazin_leer", {}, t_start + 500))
	_assert(not eins.is_empty() and zwei.is_empty(), vorsatz + "dieselbe Person: zweiter Satz nach 0,5 s wird gebremst")
	var neue: int = 0
	for index in range(1, mitglieder.size()):
		if not Dictionary(controller.call("report_member_funk_event", mitglieder[index], "nachladen", {}, t_start + 600)).is_empty():
			neue += 1
	_assert(neue + 1 <= 2, vorsatz + "im Band hoechstens 2 neue Saetze je Sekunde (%d)" % (neue + 1))

	# Ohne Auswahl zeigt das Band nichts; ein wichtiger Satz steht trotzdem im Meldungsfenster, mit Namen.
	zeilen.call("reset")
	controller.call("_set_selected_fireteams", PackedStringArray(), false)
	for _frame in range(6):
		await process_frame
	var t_ohne: int = Time.get_ticks_msec() + 30000
	var wichtig: Dictionary = Dictionary(controller.call("report_member_funk_event", mitglieder[0], "liegt", {}, t_ohne))
	var angezeigt_ohne: Array = Array(controller.call("apply_funk_band_visuals", t_ohne + 100, false))
	_assert(angezeigt_ohne.is_empty(), vorsatz + "ohne ausgewaehltes Fireteam zeigt das Band nichts")
	for _frame in range(4):
		await process_frame
	var eintraege: Array = Array(controller.call("get_tactical_event_log_snapshot"))
	var gefunden: bool = false
	var name_der_person: String = String(wichtig.get("name", ""))
	for eintrag_variant in eintraege:
		var eintrag: Dictionary = Dictionary(eintrag_variant)
		if String(eintrag.get("short_text", "")).begins_with(name_der_person + ": ") and String(eintrag.get("short_text", "")).contains(String(wichtig.get("text", "x"))):
			gefunden = true
	_assert(not wichtig.is_empty() and gefunden, vorsatz + "wichtiger Satz 'liegt' steht im Meldungsfenster mit dem Namen der Person ('%s')" % name_der_person)
	var log_panel := mission.get_node_or_null(LOG_PFAD) as Control
	var im_fenster: bool = false
	var fenster_text: String = ""
	if log_panel != null:
		for etikett_log in _alle_etiketten(log_panel):
			if etikett_log.name == "EventTextLabel" and etikett_log.text.contains(name_der_person + ": "):
				im_fenster = true
				fenster_text = etikett_log.text
	_assert(im_fenster, vorsatz + "die Zeile wird im Meldungsfenster angezeigt ('%s')" % fenster_text)
	var unwichtig: Dictionary = Dictionary(controller.call("report_member_funk_event", mitglieder[1], "nachladen", {}, t_ohne))
	var unwichtig_im_log: bool = false
	for eintrag_variant in Array(controller.call("get_tactical_event_log_snapshot")):
		if String(Dictionary(eintrag_variant).get("short_text", "")).contains(String(unwichtig.get("text", "x"))):
			unwichtig_im_log = true
	_assert(not unwichtig.is_empty() and not unwichtig_im_log, vorsatz + "unwichtige Saetze (Nachladen) stehen nicht im Meldungsfenster")

	# Gedanken (Taste V) im Band, nicht ueber den Figuren.
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	for _frame in range(8):
		await process_frame
	zeilen.call("reset")
	controller.call("set_npc_thought_peek_override", true)
	for _frame in range(3):
		await process_frame
	var gedanken: Array = Array(controller.call("apply_funk_band_visuals", Time.get_ticks_msec(), true))
	_assert(not gedanken.is_empty() and String(Dictionary(gedanken[0]).get("kind", "")) == "thought", vorsatz + "Taste V zeigt die Gedanken im Band (%d)" % gedanken.size())
	var gedanken_ok: bool = true
	for eintrag_variant in gedanken:
		var gedanke_bild: Control = _bild_von(reihe, String(Dictionary(eintrag_variant).get("unit_id", "")))
		var gedanke_etikett := gedanke_bild.get_node_or_null("FunkLine") as Label if gedanke_bild != null else null
		if gedanke_etikett == null or not gedanke_etikett.visible or gedanke_etikett.text.strip_edges().is_empty():
			gedanken_ok = false
		else:
			var g_rect: Rect2 = gedanke_etikett.get_global_rect()
			if g_rect.position.y < reihe.get_global_rect().position.y - 1.0 or g_rect.end.y > reihe.get_global_rect().end.y + 1.0:
				gedanken_ok = false
	_assert(gedanken_ok, vorsatz + "Gedanken stehen lesbar im Bereich des Bands")
	var welt: Array = Array(controller.call("get_comic_bubble_visual_payload_snapshot", false))
	var gedanken_in_welt: int = 0
	for blase_variant in welt:
		if String(Dictionary(blase_variant).get("category", "")) == "npc_thought_peek":
			gedanken_in_welt += 1
	_assert(gedanken_in_welt == 0, vorsatz + "keine Gedankenblasen ueber den Figuren auf der Karte (%d)" % gedanken_in_welt)
	controller.call("clear_npc_thought_peek_override")
	for _frame in range(2):
		await process_frame
	controller.call("apply_funk_band_visuals", Time.get_ticks_msec(), false)
	var noch_da: bool = false
	for bild in _sichtbare_bilder(reihe):
		var rest := bild.get_node_or_null("FunkLine") as Label
		if rest != null and rest.visible:
			noch_da = true
	_assert(not noch_da, vorsatz + "nach dem Loslassen von V sind die Gedanken weg")

	mission.queue_free()
	await process_frame


func _sichtbare_bilder(reihe: Control) -> Array:
	var result: Array = []
	for kind in reihe.get_children():
		var bild := kind as Control
		if bild != null and bild.visible and not String(bild.get_meta("funk_band_unit_id", "")).is_empty():
			result.append(bild)
	return result


func _bild_von(reihe: Control, unit_id: String) -> Control:
	for bild in _sichtbare_bilder(reihe):
		if String(bild.get_meta("funk_band_unit_id", "")) == unit_id:
			return bild
	return null


func _zeile_von(aktiv: Array, unit_id: String) -> Dictionary:
	for zeile_variant in aktiv:
		if String(Dictionary(zeile_variant).get("unit_id", "")) == unit_id:
			return Dictionary(zeile_variant)
	return {}


func _alle_knoepfe(wurzel: Node) -> Array:
	var result: Array = []
	for kind in wurzel.get_children():
		if kind is BaseButton:
			result.append(kind)
		result.append_array(_alle_knoepfe(kind))
	return result


func _alle_etiketten(wurzel: Node) -> Array:
	var result: Array = []
	for kind in wurzel.get_children():
		if kind is Label:
			result.append(kind)
		result.append_array(_alle_etiketten(kind))
	return result


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
