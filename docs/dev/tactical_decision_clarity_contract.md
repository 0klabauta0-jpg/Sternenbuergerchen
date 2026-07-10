# Tactical Decision Clarity Contract

## Zweck
Dieser Contract beschreibt den read-only Planungsblick fuer Fireteam-Bewegungen vor `GO`.

Der Spieler soll vor dem Commit sehen:
- wohin das Fireteam voraussichtlich geht
- welchen Ghost-/Pfadverlauf der pending Waypoint erzeugt
- ob bekannte Kontakte die Zielposition als `safe`, `risky`, `suicidal` oder `unknown` bewerten
- welche LOS-/Friendly-Fire-/Overwatch-Gruende zur Bewertung beitragen

## Besitzgrenzen
- Gameplay-Wahrheit bleibt bei `SimulationRoot`, Runtime-Komponenten, Registries und Combat-/Contact-Systemen.
- `WaypointIntentPreviewResolver` baut nur einen Snapshot aus bestehenden Order-Plans, Fireteam-Ankern, Speed-Schaetzungen und optionalem Threat-Context.
- `TacticalDecisionThreatAnalyzer` mutiert keinen State. Er liest nur uebergebene Unit-/Contact-Eintraege, TerrainRegistry und `LineOfSightSystem`.
- `FireteamOrderVisualizer` und `TerrainMap3DView` zeichnen nur den fertigen Preview-Payload.

## Preview-Payload
Ein Preview-Eintrag enthaelt mindestens:
- `fireteam_id`
- `plan_id`
- `phase`
- `ghost_path_points`
- `ghost_path_segment_count`
- `ghost_ftl_position`
- `distance_world`
- `eta_seconds_estimate`
- `risk_state`
- `expected_exposure`
- `risk_reason`
- `line_of_fire_entries`
- `read_only = true`
- `ui_sets_gameplay_truth = false`

## Risk-States
- `unknown`: kein Contact-/Threat-Context vorhanden
- `safe`: keine bekannte freie Enemy-LOS/Friendly-Fire-Gefahr
- `risky`: einzelne bekannte Gefahr oder Gefahr mit Deckung
- `suicidal`: mehrere freie Enemy-Lines, Overwatch-Druck oder Friendly-Fire-Risiko ohne ausreichende Deckung

## Visual-Regeln
- Gruen: sicher / klare eigene Linie
- Gelb: riskant
- Rot: suizidal / Overwatch
- Grau: blockierte Linie
- Orange: Friendly-Fire-Risiko

## Performance-Regeln
- Keine neuen per-frame SceneTree-Vollscans im Preview-Analyzer.
- Threat-Kontext wird als Array/Snapshot uebergeben.
- Visuals nutzen den bestehenden Order-Payload und Render-Snapshot-Zaehler.

## Release First Decision Loop Two Player Loop Scenario First Contact Runtime Smoke (TASK_1034)
TASK_1034 prueft, ob der TASK_1033-First-Contact-Runtime-Hook als kleiner Entscheidungsmoment lesbar ist: CONTACT sichtbar, WHY begruendet, NEXT bleibt der naechste Griff, FEEDBACK fuehrt zurueck, und `GO separat` bleibt ein echter Commit statt Auto-Ausfuehrung.

Der Runtime-Smoke bleibt read-only. Er bewertet Trace-Evidence fuer echten Snapshot-Kontext, sichtbare CONTACT-/WHY-/NEXT-/GO-Hooks, First-Contact-/Engagement-/Combat-HUD-Gates, Feedback-zurueck-zu-NEXT, HUD-Wahrheitsgrenze, Multiplayer-Grenze und Performance-Budget. Ein bestandener Smoke routet zu `TASK_1035 - Release First Decision Loop Two Player Loop Scenario First Contact Player Feel Findings`; Reibung routet zu TASK_1034-Polish. Er erzeugt keine UI-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit.

## Release First Decision Loop Two Player Loop Scenario First Contact Player Feel Findings (TASK_1035)
TASK_1035 trennt den technischen TASK_1034-Smoke vom Spielerblick. Erwartet wird ein read-only Befund dazu, ob CONTACT sofort klar ist, WHY eine Handlung nahelegt, NEXT den naechsten Griff zeigt, `GO separat` sicher wirkt, Feedback zurueck zum naechsten Griff fuehrt, HUD und Performance ruhig bleiben, die Multiplayer-Grenze klar ist und der erste Kontakt sich taktisch anfuehlt.

Ohne Player-Feel-Notizen bleibt der Status `needs_first_contact_player_feel_review`. Belegte Reibung routet zu `TASK_1036 - Release First Decision Loop Two Player Loop Scenario First Contact Player Feel Polish`; ein sauberer Befund routet zu `TASK_1036 - Release First Decision Loop Two Player Loop Scenario First Contact Playability Slice`. TASK_1035 erzeugt keine UI-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit.

## Release First Decision Loop Two Player Loop Scenario First Contact Player Feel Polish (TASK_1036)
TASK_1036 uebersetzt TASK_1035-Reibung oder einen akzeptierten Befund in konkrete read-only Polishing-Flaechen fuer den ersten Kontakt. Erwartet sind sechs Surface-Specs: CONTACT fuer die Kontaktzeile, WHY fuer handlungsfaehige Begruendung, NEXT fuer den naechsten Griff, FEEDBACK fuer Rueckfuehrung, GO fuer die getrennte Ausfuehrungsgrenze und HUD/MP fuer ruhige Anzeige- und Multiplayer-Autoritaetsgrenzen.

Die Specs duerfen nur Rollen, Style-IDs, Akzente, Mindesthoehen, Textbudgets und kompakte Displaytexte festlegen. Sie erzeugen keine Controls, keine Commands, kein Movement, keine Combat-/Damage-Wirkung und keine Multiplayer-Wahrheit. Ein bereiter Snapshot routet zu `TASK_1037 - Release First Decision Loop Two Player Loop Scenario First Contact Playability Slice`.

## Release First Decision Loop Two Player Loop Scenario First Contact Playability Slice (TASK_1037)
TASK_1037 prueft, ob der gepolishte erste Kontakt als kleiner spielbarer Griff lesbar ist. Ein guter Trace bestaetigt: CONTACT gelesen, WHY verstanden, NEXT sichtbar, FIRE/WAIT als Wahl erkennbar, `GO separat`, Feedback fuehrt wieder zu NEXT, HUD bleibt ruhig, Performance fuehlt sich responsiv an, Multiplayer-Grenze bleibt klar und es wurde keine Gameplay-Wahrheit im HUD erzeugt.

Der Playability-Slice bleibt read-only. Ohne Trace bleibt er `needs_first_contact_playability_trace`; fehlende Checks werden als `first_contact_playability_regression_found` benannt; ein bestandener Trace routet zu `TASK_1038 - Release First Decision Loop Two Player Loop Scenario First Contact Real Window Capture`. Er erzeugt keine UI-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit.

## Release First Decision Loop Two Player Loop Scenario First Contact Real Window Capture (TASK_1038)
TASK_1038 legt den echten Fensterbeweis-Rahmen fuer den ersten Kontakt an. Erwartet werden im Capture sichtbare CONTACT-, WHY-, NEXT-, FIRE/WAIT-, FEEDBACK- und `GO separat`-Flaechen sowie ruhige HUD-/Multiplayer-Grenzen. Ein gutes Manifest ist erst `review_ready`; akzeptiert wird es nur nach erledigten Pflichtchecks und manueller Sichtpruefung.

Der Capture-Schnitt bleibt read-only. Er darf Screenshotpfade, Prozess-/Branch-Daten, Pflichtchecks und Review-Status halten, aber keine UI-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit erzeugen. Ein akzeptierter Capture routet zu `TASK_1039 - Release First Decision Loop Two Player Loop Scenario First Contact Visual Findings`.

## Release First Decision Loop Two Player Loop Micro Objective Round Loop Real Window Capture (TASK_1004)
TASK_1004 ist der read-only Fensterbeweis-Rahmen fuer den TASK_1003-Round-Loop-Polish. Er erwartet im echten Fenster sichtbare `ROUND`-, `NEXT`- und `GO separat`-Surfaces sowie kurze Selected-Fireteam-, Mission-Control- und Command-Feedback-Zeilen.

Ohne Capture-Manifest bleibt der Status offen. Ein trusted Manifest ohne erledigte manuelle Sichtabnahme wird nur `review_ready`; akzeptiert wird erst, wenn Fensterstart, korrekter Inhalt, Screenshotpfade, sichtbare Round-/Next-/GO-Grenze, HUD-read-only-Grenze und Multiplayer-Grenze bestaetigt sind. Der Snapshot erzeugt keine Gameplay-Wahrheit und routet danach zu TASK_1005 fuer konkrete Visual-Findings.

## Release First Decision Loop Two Player Loop Micro Objective Round Loop Visual Findings (TASK_1005)
TASK_1005 trennt technische TASK_1004-Capture-Evidence vom eigentlichen Spielerblick. Erwartet wird ein read-only Befund zu `ROUND`, `NEXT`, `GO separat`, Selected-Fireteam-Runtime-Zeile, Mission-Control-Runtime-Zeile, Command-Feedback-Runtime-Zeile und allgemeiner Spielerlesbarkeit.

Ohne Sichtnotizen bleibt der Status `needs_manual_review`. Belegte Reibung routet zu TASK_1006 fuer engen Visual Polish; ein sauberer Befund routet zu TASK_1007 fuer den Round-Loop-Playability-Slice. TASK_1005 erzeugt keine Commands, kein Movement, keine Combat-/Damage-Wirkung und keine Multiplayer-Wahrheit.

## Release First Decision Loop Two Player Loop Micro Objective Round Loop Visual Polish (TASK_1006)
TASK_1006 uebersetzt TASK_1005-Findings in konkrete read-only Surface-Specs. Erwartet sind sechs Polishing-Flaechen fuer `ROUND`, `NEXT`, `GO separat`, Selected-Fireteam-Runtime, Mission-Control-Runtime und Command-Feedback-Runtime.

Die Specs duerfen nur Rollen, Style-IDs, Mindesthoehen, Textbudgets und kompakte Displaytexte festlegen. Sie erzeugen keine Controls, keine Commands, kein Movement, keine Combat-/Damage-Wirkung und keine Multiplayer-Wahrheit. Der naechste Schritt ist TASK_1007, der daraus einen spielbaren Round-Loop-Playability-Slice macht.

## Release First Decision Loop Two Player Loop Micro Objective Round Loop Playability Slice (TASK_1007)
TASK_1007 prueft, ob der gepolishte Round-Loop als kleiner Spielergriff lesbar ist. Ein guter Trace bestaetigt: `ROUND` gelesen, `NEXT` verstanden, Confirm verfuegbar, `GO` bleibt separat, kein Command vor Confirm, kein Auto-GO, Feedback fuehrt wieder zu `NEXT`, Runtime-Zeilen bleiben lesbar und HUD-/Multiplayer-Grenzen bleiben unangetastet.

Der Round-Loop-Playability-Slice bleibt read-only. Ohne Trace bleibt er `needs_round_loop_playability_trace`; fehlende Checks werden als Regression benannt; ein bestandener Trace routet zu `TASK_1008 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Integrated Playtest`. Er erzeugt keine UI-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit.

## Release First Decision Loop Two Player Loop Micro Objective Round Loop Integrated Playtest (TASK_1008)
TASK_1008 prueft, ob der bestandene Round-Loop im integrierten Release-/Mission-Kontext zusammenhaelt. Ein guter Trace bestaetigt Entry-Kontext, sichtbares Command-Feedback, gelesene `ROUND`-/`NEXT`-Flaechen, wiederverwendete Confirm-/GO-Pfade, Post-GO-Feedback, Rueckkehr zu `NEXT`, Performance-Budget sowie HUD-/Multiplayer-Grenzen.

Der Integrated-Playtest-Slice bleibt read-only. Ohne Trace bleibt er `needs_round_loop_integrated_playtest_trace`; fehlende Checks werden als Regression benannt; ein bestandener Trace routet zu `TASK_1009 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Player Feel Findings`. Er erzeugt keine UI-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit.

## Release First Decision Loop Two Player Loop Micro Objective Round Loop Player Feel Findings (TASK_1009)
TASK_1009 trennt den technischen Integrated-Playtest vom eigentlichen Spielerblick. Erwartet wird ein read-only Befund dazu, ob Entry, `ROUND`, `NEXT`, getrenntes `GO`, Feedback, naechster Griff, HUD-Ruhe, Performance-Gefuehl und Multiplayer-Grenze im Ablauf rund wirken.

Ohne Player-Feel-Notizen bleibt der Status `needs_player_feel_review`. Belegte Reibung routet zu `TASK_1010 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Player Feel Polish`; ein sauberer Befund routet zu `TASK_1010 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Acceptance Slice`. TASK_1009 erzeugt keine UI-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit.

## Release First Decision Loop Two Player Loop Micro Objective Round Loop Player Feel Polish (TASK_1010)
TASK_1010 uebersetzt TASK_1009-Findings in eine konkrete Player-Feel-Leseschicht. Erwartet werden sechs kurze, stabile Surface-Specs fuer `START`, `ROUND/NEXT/GO`, Feedback, `GO`-Grenze, HUD-Ruhe und Multiplayer-/Wahrheitsgrenze plus eine kompakte `FEEL | NEXT | GO`-Zeile.

Der Player-Feel-Polish bleibt read-only. Er darf dem HUD sagen, welche Texte, Rollen, Akzente und Budgets fuer den runden kleinen Loop gelten, aber keine UI-Baeume bauen, keine Commands erzeugen, kein Movement starten und keine Multiplayer-Wahrheit setzen. Der naechste Schritt ist `TASK_1011 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Acceptance Slice`.

## Release First Decision Loop Two Player Loop Micro Objective Round Loop Acceptance Slice (TASK_1011)
TASK_1011 prueft, ob sich der TASK_1010-Polish als kleiner Spielergriff akzeptieren laesst. Ein guter Trace bestaetigt sichtbares `FEEL/NEXT/GO`, klaren Start, lesbaren Round-/Next-/GO-Rhythmus, Feedback-zurueck-zu-NEXT, klare `GO separat`-Grenze, ruhiges HUD, responsives Gefuehl und erhaltene Multiplayer-/Wahrheitsgrenze.

Der Acceptance-Slice bleibt read-only. Ohne Trace bleibt er `needs_round_loop_acceptance_trace`; fehlende Checks werden als Regression benannt; ein bestandener Trace routet zu `TASK_1012 - Release First Decision Loop Two Player Loop Scenario Stitch`. Er erzeugt keine UI-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit.

## Release First Decision Loop Two Player Loop Scenario Stitch (TASK_1012)
TASK_1012 prueft, ob der akzeptierte Round-Loop als kleiner Szenario-Moment lesbar ist. Ein guter Trace bestaetigt FOB-Einstieg, Mission-Objective, NPC-Druck, zwei Spielerrollen, mindestens fuenf Beats von Entry bis Exit, eingebetteten FEEL/NEXT/GO-Rhythmus, Feedback-zurueck-zu-NEXT und erhaltene Multiplayer-/Wahrheitsgrenzen.

Der Scenario-Stitch bleibt read-only. Ohne Trace bleibt er `needs_scenario_stitch_trace`; fehlende Checks werden als Regression benannt; ein bestandener Trace routet zu `TASK_1013 - Release First Decision Loop Two Player Loop Scenario Runtime Hook`. Er erzeugt keine UI-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit.

## Release First Decision Loop Two Player Loop Scenario Runtime Hook (TASK_1013)
TASK_1013 macht den Scenario-Stitch als kleinen Runtime-Griff sichtbar. Ein guter Snapshot zeigt den aktuellen Beat, FOB/Objective, Alpha- oder Bravo-Rolle, eine ausgewaehlte Runtime-Choice, `NEXT`, `CONFIRM` und `GO separat`.

Der Runtime-Hook bleibt read-only. Er darf Command-Matrix-Hooks und HUD-Zeilen beschreiben, aber keine UI-Baeume bauen, keine Commands erzeugen, kein Movement starten und keine Multiplayer-Wahrheit setzen. Ein bestandener Hook routet zu `TASK_1014 - Release First Decision Loop Two Player Loop Scenario Runtime Smoke`.

## Release First Decision Loop Two Player Loop Scenario Runtime Smoke (TASK_1014)
TASK_1014 prueft, ob der TASK_1013-Runtime-Hook als kleiner Spielgriff traegt: `ENTRY -> NEXT -> CONFIRM -> GO -> FEEDBACK -> NEXT/EXIT`.

Der Smoke bleibt read-only. Er bewertet Trace-Evidence fuer sichtbaren Entry, NEXT, Runtime-Choice, Confirm, GO separat, Feedback-zurueck-zu-NEXT, HUD-Ruhe und Multiplayer-Grenze. Ein bestandener Smoke routet zu `TASK_1015 - Release First Decision Loop Two Player Loop Scenario Player Feel Findings`.

## Release First Decision Loop Two Player Loop Scenario Player Feel Findings (TASK_1015)
TASK_1015 trennt den technischen TASK_1014-Smoke vom Spielerblick. Erwartet wird ein read-only Befund dazu, ob FOB-Entry, Objective, Alpha-/Bravo-Rollen, NEXT/CONFIRM/GO, Feedback, HUD-Ruhe, Responsiveness und Multiplayer-Grenze als kleiner Szenario-Griff rund wirken.

Ohne Player-Feel-Notizen bleibt der Status `needs_scenario_player_feel_review`. Belegte Reibung routet zu `TASK_1016 - Release First Decision Loop Two Player Loop Scenario Player Feel Polish`; ein sauberer Befund routet zu `TASK_1016 - Release First Decision Loop Two Player Loop Scenario Playability Slice`. TASK_1015 erzeugt keine UI-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit.

## Release First Decision Loop Two Player Loop Scenario Player Feel Polish (TASK_1016)
TASK_1016 uebersetzt TASK_1015-Findings in konkrete read-only Surface-Specs. Erwartet sind sieben Polishing-Flaechen fuer FOB-Entry, Objective, Alpha/Bravo-Rollen, NEXT/CONFIRM/GO-Flow, Feedback, GO-Grenze und Multiplayer-Grenze.

Die Specs duerfen nur Rollen, Style-IDs, Mindesthoehen, Textbudgets und kompakte Displaytexte festlegen. Sie erzeugen keine Controls, keine Commands, kein Movement, keine Combat-/Damage-Wirkung und keine Multiplayer-Wahrheit. Der naechste Schritt ist `TASK_1017 - Release First Decision Loop Two Player Loop Scenario Playability Slice`.

## Release First Decision Loop Two Player Loop Scenario Playability Slice (TASK_1017)
TASK_1017 prueft, ob die TASK_1016-Surfaces als kleiner Szenario-Griff lesbar sind. Ein guter Trace bestaetigt: FOB-Entry gelesen, Objective verstanden, Alpha/Bravo-Rollen lesbar, NEXT/CONFIRM/GO als ruhiger Ablauf erkennbar, GO bleibt separat, Feedback fuehrt wieder zu NEXT, HUD bleibt ruhig, Responsiveness fuehlt sich schnell an und Multiplayer-/Gameplay-Wahrheit bleibt unberuehrt.

Der Scenario-Playability-Slice bleibt read-only. Ohne Trace bleibt er `needs_scenario_playability_trace`; fehlende Checks werden als Regression benannt; ein bestandener Trace routet zu `TASK_1018 - Release First Decision Loop Two Player Loop Scenario Real Window Capture`. Er erzeugt keine UI-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit.

## Release First Decision Loop Two Player Loop Scenario Real Window Capture (TASK_1018)
TASK_1018 legt den read-only Fensterbeweis-Rahmen fuer den TASK_1017-Szenario-Griff an. Erwartet wird ein Release-Fenster mit sichtbarem FOB-Entry, Objective, Alpha/Bravo-Rollen, NEXT/CONFIRM/GO-Flow, GO-Grenze, Feedback-Zeile und ruhiger HUD-Fuehrung.

Ohne Capture-Manifest bleibt der Status offen. Ein trusted Manifest ohne erledigte manuelle Sichtabnahme wird nur `review_ready`; akzeptiert wird erst, wenn Fensterstart, korrekter Inhalt, Screenshotpfade, sichtbare Szenario-Flaechen, HUD-read-only-Grenze und Multiplayer-Grenze bestaetigt sind. Der Snapshot erzeugt keine Gameplay-Wahrheit und routet danach zu TASK_1019 fuer konkrete Scenario Visual Findings.

## Release First Decision Loop Two Player Loop Scenario Visual Findings (TASK_1019)
TASK_1019 trennt die technische TASK_1018-Capture-Evidence vom eigentlichen Spielerblick. Erwartet wird ein read-only Befund dazu, ob FOB-Entry, Objective, Alpha-/Bravo-Rollen, NEXT/CONFIRM/GO, GO-Grenze, Feedback, HUD-Ruhe, Scenario-Playability-Zeile, Spielerlesbarkeit und Multiplayer-Grenze im echten Fenster tragen.

Ohne Sichtnotizen bleibt der Status `needs_manual_review`. Belegte Reibung routet zu `TASK_1020 - Release First Decision Loop Two Player Loop Scenario Visual Polish`; ein sauberer Befund routet zu `TASK_1020 - Release First Decision Loop Two Player Loop Scenario Acceptance Slice`. TASK_1019 erzeugt keine UI-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit.

## Release First Decision Loop Two Player Loop Scenario Acceptance Slice (TASK_1020)
TASK_1020 prueft, ob der akzeptierte TASK_1019-Befund als kleiner FOB-Szenario-Griff traegt. Ein guter Trace bestaetigt: FOB-Entry gelesen, Objective verstanden, Alpha/Bravo-Rollen lesbar, NEXT/CONFIRM/GO klar, Feedback fuehrt wieder zu NEXT, GO bleibt separat, HUD bleibt ruhig, Responsiveness fuehlt sich schnell an und Multiplayer-/Gameplay-Wahrheit bleibt unberuehrt.

Der Scenario-Acceptance-Slice bleibt read-only. Ohne Trace bleibt er `needs_scenario_acceptance_trace`; fehlende Checks werden als Regression benannt; ein bestandener Trace routet zu `TASK_1021 - Release First Decision Loop Two Player Loop Scenario Integrated Playtest`. Er erzeugt keine UI-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit.

## Release First Decision Loop Two Player Loop Scenario Integrated Playtest (TASK_1021)
TASK_1021 prueft, ob der bestandene TASK_1020-Slice im integrierten Release-/Mission-Kontext weiter lesbar bleibt. Ein guter Trace bestaetigt: Release-/Mission-Entry erreicht, Command-Feedback enthaelt den Acceptance-Slice, FOB/Objective/Rollen sind im Kontext lesbar, NEXT/CONFIRM/GO laufen im selben Griff, GO bleibt separat, Post-GO-Feedback erscheint, der Flow kehrt zu NEXT zurueck, HUD bleibt read-only, Multiplayer-Grenze bleibt erhalten und das Performance-Budget ist gruen.

Der Scenario-Integrated-Playtest bleibt read-only. Ohne Trace bleibt er `needs_scenario_integrated_playtest_trace`; fehlende Checks werden als Regression benannt; ein bestandener Trace routet zu `TASK_1022 - Release First Decision Loop Two Player Loop Scenario Player Feel Findings`. Er erzeugt keine UI-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit.

## Release First Decision Loop Two Player Loop Scenario Player Feel Findings (TASK_1022)
TASK_1022 schneidet aus dem bestandenen TASK_1021-Trace den menschlichen Player-Feel-Befund: Fuehlt sich der Entry klar an, greift der FOB-Moment rund, bleibt NEXT/CONFIRM/GO getrennt, fuehrt Post-GO-Feedback angenehm zum naechsten Griff, kehrt der Loop ohne Verwirrung zu NEXT zurueck, bleibt das HUD ruhig, reagiert der Ablauf schnell, ist der Zwei-Spieler-Kontext klar und bleibt die Multiplayer-/Wahrheitsgrenze sichtbar?

## Release First Decision Loop Two Player Loop Scenario Small Game Acceptance Slice (TASK_1023)
TASK_1023 akzeptiert einen sauberen TASK_1022-Befund nur mit eigenem Acceptance-Trace. Der Trace muss belegen, dass FOB/NEXT sichtbar sind, Objective und Alpha/Bravo-Rollen verstanden werden, NEXT/CONFIRM/GO als Vorbereitung lesbar bleiben, GO separat bleibt, Post-GO-Feedback wieder zu NEXT fuehrt, HUD und Performance ruhig bleiben, Zwei-Spieler-Kontext und Multiplayer-Grenze erhalten sind und das HUD keine Gameplay-Wahrheit setzt.

Der Small-Game-Acceptance-Slice bleibt read-only. Ohne Trace bleibt er `needs_small_game_acceptance_trace`; fehlende Checks werden als `small_game_acceptance_regression_found` gemeldet; ein bestandener Trace setzt `small_game_acceptance_slice_passed` und routet zu `TASK_1024 - Release First Decision Loop Two Player Loop Scenario Release Candidate Playtest`. Er erzeugt keine UI-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit.

## Release First Decision Loop Two Player Loop Scenario Release Candidate Playtest (TASK_1024)
TASK_1024 prueft den akzeptierten kleinen Spielmoment gegen ein Release-Candidate-Playtest-Manifest. Der Trace muss belegen, dass die Release-Exe gestartet wurde, Singleplayer in den FOB-Flow fuehrt, Alpha/Bravo-Kontext sichtbar bleibt, NEXT/CONFIRM/GO wirklich benutzt wird, GO einmal ausgefuehrt wurde, Post-GO-Feedback sichtbar ist, der Loop zu NEXT zurueckkehrt, kein Input-Dead-End entsteht, Performance responsiv bleibt und HUD-/Multiplayer-Wahrheitsgrenzen erhalten sind.

Der Release-Candidate-Playtest bleibt read-only. Ohne Manifest bleibt er `needs_release_candidate_playtest_manifest`; offene Checks bleiben `needs_release_candidate_playtest_completion`; echte Reibung wird `release_candidate_playtest_regression_found`; ein sauberer Manifest-Trace setzt `release_candidate_playtest_passed` und `ready_for_release_candidate_acceptance`. Er erzeugt keine UI-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit.

## Release First Decision Loop Two Player Loop Scenario Release Candidate Acceptance (TASK_1025)
TASK_1025 macht aus einem bestandenen TASK_1024-Playtest eine explizite Acceptance-Entscheidung. Die Review muss bestaetigen, dass der RC-Playtest bestanden ist, der Release-Build vorhanden ist, keine sichtbaren Spielerblocker oder Regressionen bleiben, keine Input-Sackgasse existiert, Performance akzeptabel ist, Multiplayer- und HUD-Wahrheitsgrenzen erhalten sind und Ship-Readiness-Notizen fuer den naechsten Schritt vorliegen.

Die Release-Candidate-Acceptance bleibt read-only. Ohne Review bleibt sie `needs_release_candidate_acceptance_review`; fehlende Gates werden `release_candidate_acceptance_regression_found`; ein sauberer Review setzt `release_candidate_accepted` und `ready_for_ship_readiness_review`. Sie erzeugt keine UI-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit.

## Release First Decision Loop Two Player Loop Scenario Ship Readiness Review (TASK_1026)
TASK_1026 prueft nach einer akzeptierten TASK_1025-Acceptance, ob der kleine FOB/NEXT/GO/FEEDBACK-Spielmoment fuer einen sichtbaren EXE-/Ship-Smoke uebergabebereit ist. Pflichtdaten sind Release-EXE, PCK, Szenario-ID, Testerhinweise, Operator-Ziel, bekannte Risiken, Uebergabe-Items, Multiplayer-Grenze, HUD-Wahrheit und ein abgeschlossener Ship-Readiness-Review.

Die Ship-Readiness-Review bleibt read-only. Ohne Paket bleibt sie `needs_ship_readiness_packet`; fehlende Daten werden `ship_readiness_incomplete`; ein sauberes Paket setzt `ship_readiness_ready` und `ready_for_visible_ship_smoke`. Sie erzeugt keine UI-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit und setzt keine neue Spielwahrheit.

## Release First Decision Loop Two Player Loop Scenario Visible Ship Smoke (TASK_1027)
TASK_1027 prueft nach einer bereiten TASK_1026-Ship-Readiness, ob der kleine Spielmoment in der sichtbaren Release-EXE wirklich lesbar ist: frischer Release-Ordner, EXE-Start, Einzelspieler, FOB, NEXT, GO, FEEDBACK, keine Input-Sackgasse, responsive Bedienung, keine stale Taskbar-/Build-Verwechslung und exportierte Smoke-Notizen.

Der Visible-Ship-Smoke bleibt read-only. Ohne Notizen bleibt er `needs_visible_ship_smoke`; fehlende Pflichtchecks werden `needs_visible_ship_smoke_completion`; konkrete Reibung wird `visible_ship_smoke_regression_found`; ein sauberer Smoke setzt `visible_ship_smoke_passed` und `ready_for_delivery_review`. Er erzeugt keine UI-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit.

## Release First Decision Loop Two Player Loop Scenario Delivery Review (TASK_1028)
TASK_1028 prueft nach einem bestandenen sichtbaren Smoke, ob der kleine Release-Spielmoment als Paket weitergegeben werden darf: sichtbarer Smoke, benannte Release-Dateien, klare Startanweisung, bekannte Risiken, Risikoannahme, Shortcut-Warnung, Multiplayer-Grenze, HUD-Wahrheit und naechster Handoff.

Der Delivery-Review bleibt read-only. Ohne Review bleibt er `needs_delivery_review`; fehlende Pflichtchecks werden `needs_delivery_review_completion`; konkrete Issue-Flags werden `delivery_review_regression_found`; ein sauberer Review setzt `delivery_review_ready` und `ready_for_handoff_packet`. Er erzeugt keine UI-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit und aendert keine Shortcuts.

## Release First Decision Loop Two Player Loop Scenario Handoff Packet (TASK_1029)
TASK_1029 schneidet aus einer bereiten Delivery-Review ein kleines Tester-Handoff: Release-Dateien, Startanweisung, Shortcut-Warnung, Risiko-Zusammenfassung, naechste Tester-Aktion, Multiplayer-Grenze, HUD-Wahrheit und konkrete read-only Tester-Schritte fuer den FOB/NEXT/GO/FEEDBACK-Spielmoment.

Das Handoff-Packet bleibt read-only. Ohne Paket bleibt es `needs_handoff_packet`; fehlende Items werden `needs_handoff_packet_completion`; konkrete Reibung wird `handoff_packet_regression_found`; ein sauberes Paket setzt `handoff_packet_ready` und `ready_for_tester_run`. Es erzeugt keine UI-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit und aendert keine Shortcuts.

## Release First Decision Loop Two Player Loop Scenario Tester Run (TASK_1030)
TASK_1030 haelt fest, ob der kleine FOB/NEXT/GO/FEEDBACK-Spielmoment aus dem Handoff frisch getestet wurde: Handoff genutzt, frische EXE gestartet, Singleplayer/Homebase handlungsfaehig, FOB/NEXT/GO/FEEDBACK sichtbar, erster Loop reagiert, keine Input-Sackgasse, Performance schnell genug, HUD blockiert nicht, Multiplayer-Grenze erhalten und Tester-Notizen exportiert.

Der Tester-Run bleibt read-only. Ohne Notizen bleibt er `needs_tester_run`; fehlende Checks werden `needs_tester_run_completion`; konkrete Reibung wird `tester_run_regression_found`; ein sauberer Run setzt `tester_run_ready` und `ready_for_acceptance_review`. Er erzeugt keine UI-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit und aendert keine Shortcuts.

## Release First Decision Loop Two Player Loop Scenario Tester Run Acceptance (TASK_1031)
TASK_1031 nimmt einen bereiten TASK_1030-Tester-Run und entscheidet, ob der kleine FOB/NEXT/GO/FEEDBACK-Spielmoment als akzeptierter Release-Griff fuer den naechsten spielbaren Slice gilt.

Die Acceptance bleibt read-only. Ohne Review bleibt sie `needs_acceptance_review`; fehlende Checks bleiben `needs_acceptance_review_completion`; Issue-Flags routen zu TASK_1031-Polish; ein sauberer Review setzt `tester_run_accepted` und `ready_for_next_playable_slice`. Geprueft werden Tester-Run, Release-Dateien, Singleplayer-Pfad, FOB/NEXT/GO/FEEDBACK, Performance, HUD-Grenze, Multiplayer-Grenze, bekannte Risiken und ein benannter naechster spielbarer Slice. Sie erzeugt keine UI-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit und routet danach zu TASK_1032 Next Playable Slice Plan.

## Release First Decision Loop Two Player Loop Scenario Next Playable Slice Plan (TASK_1032)
TASK_1032 nimmt eine akzeptierte TASK_1031-Quelle und legt den naechsten kleinen spielbaren Slice fest: erster Kontakt mit lesbarer CONTACT/COVER/LOS/FIRE-WAIT/FEEDBACK-Entscheidung.

Der Plan bleibt read-only. Ohne akzeptierte TASK_1031-Quelle bleibt er `blocked_until_tester_run_acceptance`; ohne Plan bleibt er `needs_next_playable_slice_plan`; fehlende Pflichtitems bleiben `needs_next_playable_slice_plan_completion`; Issue-Flags routen zu TASK_1032-Polish; ein sauberer Plan setzt `next_playable_slice_plan_ready` und `ready_for_first_contact_runtime_hook`. Er erzeugt keine UI-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit und routet danach zu `TASK_1033 - Release First Decision Loop Two Player Loop Scenario First Contact Runtime Hook`.

## Release First Decision Loop Two Player Loop Scenario First Contact Runtime Hook (TASK_1033)
TASK_1033 macht den ersten Kontakt als Runtime-Hook lesbar: CONTACT, COVER, LOS, FIRE/WAIT, FEEDBACK und `GO separat` werden aus bestehenden Snapshots zusammengefuehrt.

Der Hook bleibt read-only. Ohne bereiten TASK_1032-Plan bleibt er `blocked_until_next_playable_slice_plan`; ohne First-Contact-/Engagement-/Fire-Cover-/Combat-HUD-Kontext bleibt er `needs_first_contact_runtime_hook_context`; unvollstaendige Kontexte routen zu TASK_1033-Review; ein sauberer Kontext setzt `first_contact_runtime_hook_ready`. Er beantwortet die Spielerfragen `Wer sieht wen?`, `Warum ist das sicher oder gefaehrlich?`, `Warum schiesst das Fireteam oder wartet es?` und `Was ist der naechste Griff?`, erzeugt aber keine UI-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit. Der naechste Beweis ist `TASK_1034 - Release First Decision Loop Two Player Loop Scenario First Contact Runtime Smoke`.

Der Integrated-Player-Feel-Befund bleibt read-only. Ohne Notizen bleibt er `needs_scenario_integrated_player_feel_review`; belegte Reibung routet zu `TASK_1023 - Release First Decision Loop Two Player Loop Scenario Player Feel Polish`; ein sauberer Befund routet zu `TASK_1023 - Release First Decision Loop Two Player Loop Scenario Small Game Acceptance Slice`. Er erzeugt keine UI-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit.

## Scenario Return (TASK_948)
TASK_948 stoppt die reine First-Exchange-Polish-Schleife, wenn TASK_947 nicht sauber in einen First-Exchange-Smoke routet. Der Return ist kein neues Gameplay-System: Er fasst die vorhandenen Bausteine aus TASK_506 bis TASK_510 als naechsten kleinen Playability-Stack zusammen.

Erwartete Spielerfragen fuer den naechsten Slice:
- `where_will_the_fireteam_go`
- `who_can_see_the_destination`
- `why_is_the_move_safe_risky_or_suicidal`
- `what_happens_only_after_go`

Der naechste konkrete Slice ist `TASK_949 - Order Preview Threat Overlay Playtest Scenario`. Er soll Ghost, Pfad, Risk-State und Line-of-Fire in einer kleinen 3v3-Entscheidungssituation sichtbar machen, ohne vor `GO` Commands, Movement, Combat, Damage oder Multiplayer-Wahrheit zu erzeugen.

## Playtest Scenario (TASK_949)
TASK_949 baut aus den vorhandenen Preview-/Threat-Bausteinen einen kleinen read-only Szenario-Payload fuer die naechste sichtbare F6-Verdrahtung. Erwartet sind drei Move-Choices: `covered_push` als `safe`, `exposed_crossing` als `risky` und `kill_zone_dash` als `suicidal`.

Jede Choice muss Ghost, Pfad, ETA, Risk-State, Risk-Farbe und Line-of-Fire-Zaehler aus `WaypointIntentPreviewResolver` und `TacticalDecisionThreatAnalyzer` enthalten. Die Overlay-Summary zaehlt Ghosts, Path-Lines, Threat-Lines und Risk-Farben. Der Snapshot darf weiterhin kein `GO`, keine Movement-/Combat-/Damage-Wirkung und keine Multiplayer-Wahrheit erzeugen.

## F6 Mission HUD Wiring (TASK_950)
TASK_950 verdrahtet den TASK_949-Payload in das bestehende F6-Missions-HUD, ohne daraus Gameplay-Wahrheit zu machen. Erwartet ist ein `order_preview_threat_overlay_f6_hud`-Snapshot mit drei sichtbaren Choice-Karten, einer kompakten Mission-Control-Zeile und einer empfohlenen sicheren Wahl.

Die Mission-Control-Zeile muss `SAFE`, `RISKY` und `SUICIDAL` nennen und kurz genug fuer das bestehende Strategic-Status-Fenster bleiben. `get_command_feedback_snapshot()` muss denselben Snapshot exportieren, damit Tests und spaetere Sichtchecks die sichtbare Preview gegen denselben Contract lesen. Der Snapshot bleibt read-only und erzeugt keine Commands, Movement-, Fire-, Damage- oder Multiplayer-Wahrheit.

## Decision Overlay Real F6 Visual Review (TASK_951)
TASK_951 ist die automatische Vorpruefung fuer den echten F6-Sichtcheck. Die Mission-Control-Zeile darf keine rohen internen Choice-IDs mehr zeigen, sondern nutzt spielernahe Labels wie `SAFE Gedeckt`, `RISKY Querung` und `SUICIDAL Killzone`.

Der Snapshot `decision_overlay_real_f6_visual_review` prueft Textlaenge, Risk-Token, Display-Texte und Read-only-Grenzen. Er darf `manual_review_required = true` setzen und `manual_review_done = false` lassen; eine echte Screenshot- oder Fensterabnahme wird dadurch nicht ersetzt.

## Decision Overlay F6 Visual Polish (TASK_952)
TASK_952 bereitet die Decision-Preview fuer den echten Fensterbeweis als kompakte Badge-Struktur vor. Erwartet sind drei Segmente in stabiler Reihenfolge: `safe/green/OK`, `risky/yellow/!`, `suicidal/red/!!`.

Der Polish-Snapshot bleibt auf der vorhandenen Mission-Control-Flaeche, nutzt maximal eine Zeile und darf keine UI-Baeume rebuilden. Labels und Microcopy duerfen keine internen Choice-IDs zeigen. Auch dieser Snapshot ist read-only und ersetzt keine manuelle Sichtabnahme.

## Decision Overlay Real Window Recapture (TASK_953)
TASK_953 stellt den read-only Real-Window-Recapture-Rahmen fuer den TASK_952-Polish bereit. Erwartet sind Manifest-Felder fuer TASK_952-Source-Schema, Style, Window-/Desktop-Screenshotpfade, Capture-Prozess, `window_handle_print` und Pflichtchecks.

Der Recapture-Snapshot darf erst `accepted` werden, wenn die manuellen Pflichtchecks abgeschlossen sind. Ohne manuelle Sichtabnahme bleibt er `review_ready`. Er setzt keine Gameplay-, Movement-, Combat- oder Multiplayer-Wahrheit.

## Decision Overlay Real Window Visual Findings (TASK_954)
TASK_954 schneidet aus einem TASK_953-Recapture-Snapshot und optionalen manuellen Sichtnotizen einen read-only Findings-Snapshot. Er prueft, ob die Quelle wirklich TASK_953 ist, ob sie auf dem TASK_952-Polish-Style basiert und ob sie review-ready ist.

Ohne manuelle Sichtnotizen bleibt der Status `needs_manual_review`. Belegte visuelle Reibungen wie konkurrierende Badge-Farben, laute Mission-Control-Zeile oder verdeckte Command-Surfaces routen zu `TASK_955 - Decision Overlay Real Window Polish Followup`. Ein sauberer Sichtbefund routet zu `TASK_955 - Decision Overlay Playability Smoke`. TASK_954 setzt keine Gameplay-, Movement-, Combat- oder Multiplayer-Wahrheit.

## Decision Overlay Playability Smoke (TASK_955)
TASK_955 ist der kleine Rueckweg von Sichtbefund zu Spielbarkeit. Er akzeptiert nur TASK_954-Findings mit `accepted_for_decision_overlay_playability_smoke` und wertet danach einen Playthrough-Trace aus.

Der Trace muss belegen, dass der Spieler vor `GO` Ziel, Pfad, Risiko, Line-of-Fire-Gruende und beste Wahl lesen kann, dass vor `GO` kein Command erzeugt wird, dass `GO` bestaetigbar bleibt und dass danach sichtbares Feedback erscheint. Der Snapshot bleibt read-only und erzeugt keine Gameplay-, Movement-, Combat- oder Multiplayer-Wahrheit.

## First Decision Micro Scenario Polish (TASK_956)
TASK_956 uebersetzt den bestandenen Decision-Overlay-Smoke in eine konkrete, kurze Spielerlesung fuer den ersten Griff. Erwartet sind eine `NEXT ... -> GO`-Zeile, eine `WHY`-Zeile, eine Vor-GO-Grenze und eine Nach-GO-Feedback-Zeile.

Die empfohlene sichere Choice steht zuerst; risky und suicidal bleiben als Alternativen sichtbar. Alle Zeilen muessen spielernahe Labels nutzen und interne Choice-IDs verstecken. Der Snapshot bleibt read-only, nutzt vorhandene TASK_950-/TASK_952-Daten und erzeugt keine Gameplay-, Movement-, Combat- oder Multiplayer-Wahrheit.

## First Decision Real Playthrough Capture (TASK_957)
TASK_957 legt den echten Fenster-Capture-Rahmen fuer den ersten Decision-Playthrough nach TASK_956 an. Erwartet ist ein Manifest mit TASK_956-Source, `--release-singleplayer-lz-drop-preview`, Window-/Desktop-Screenshotpfaden, `window_handle_print`, Prozessmetadaten und manuellen Pflichtchecks.

Der Capture darf erst `accepted` werden, wenn `NEXT`, `WHY`, Choice-Zeilen, Preview-Grenze, Command-Surface/GO, kein Command vor GO und keine neue HUD-Gameplay-Wahrheit manuell bestaetigt wurden. Ohne diese Sichtabnahme bleibt der Status `review_ready`.

## First Decision Real Playthrough Visual Findings (TASK_958)
TASK_958 trennt technische TASK_957-Capture-Evidence vom eigentlichen Spielerblick. Ein guter Capture ohne Review-Notizen bleibt `needs_manual_review`; belegte Reibungen wie fehlende `NEXT`-Zeile, unklare Preview-vor-GO-Grenze oder schwache Empfehlung routen zu einem engen Polish-Followup.

Ein sauberer Befund darf erst zum First-Decision-Playability-Smoke routen, wenn `NEXT`, `WHY`, Choice-Zeilen, Empfehlung, Preview-Grenze, GO-Bedienbarkeit, kein Command vor GO und die read-only HUD-Grenze manuell bestaetigt sind. Der Findings-Snapshot bleibt read-only und erzeugt keine Commands, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit.

## First Decision Playability Smoke (TASK_959)
TASK_959 verbindet den akzeptierten Fensterbefund mit einem Ablauf-Trace. Der Smoke muss belegen, dass der Spieler vor `GO` den naechsten Griff, die Begruendung, Ziel/Pfad, Risk-/Line-of-Fire-Gruende und die Preview-Grenze lesen kann, dass `GO` bedienbar bleibt und nach `GO` sichtbares Feedback erscheint.

Der Smoke bleibt ein Gate: ohne akzeptierten TASK_958-Befund bleibt er blockiert, ohne Trace bleibt er `needs_smoke_run`, und bei fehlenden Pflichtchecks meldet er `smoke_regression_found`. Auch dieser Schritt erzeugt keine Commands, keine Movement-, Combat-, Damage- oder Multiplayer-Wahrheit.

## First Decision Release Playable Slice (TASK_960)
TASK_960 spannt die erste Entscheidung ueber den Release-Spine: Homebase bereit, Fireteam und Flightdeck bereit, Dropship-Payload, Mission geladen, LZ gesetzt, Drop abgeschlossen, Fireteam deployed, Preview sichtbar, `GO` bestaetigt und Post-GO-Feedback lesbar.

Der Slice darf nur Trace-Evidence bewerten. Er ist kein Export, kein neuer Mission-Flow und kein Gameplay-Mutator. Die Multiplayer-Vorbereitung bleibt als Grenze sichtbar: Der Slice muss `multiplayer_snapshot_boundary_preserved` belegen, setzt aber keine Peer- oder Team-Wahrheit.

## Release First Decision Integrated Playtest (TASK_961)
TASK_961 bindet den Slice an einen echten Release-Playtest-Beleg. Das Manifest muss Release-EXE-Start, Deep-Link, korrekten Fensterinhalt, Homebase-bis-Mission, Dropship/LZ/Drop, First-Decision-Preview, `GO`, Post-GO-Feedback, Performance und Multiplayer-Snapshot-Grenze dokumentieren.

Der Playtest-Rahmen darf keine Erfolgsmeldung automatisch setzen. `manual_playtest_done` bleibt im Tool false, bis ein echter Sicht-/Bedienbefund vorliegt. Der Analyzer ist read-only und routet offene oder regressierende Evidence zu TASK_962-Findings.

## Release First Decision Playtest Findings (TASK_962)
TASK_962 bewertet den TASK_961-Stand als Spielerbefund: korrektes Fenster, Homebase-bis-Mission, Dropship/LZ/Drop, First-Decision-Preview, `GO`, Post-GO-Feedback, Performance, HUD-Read-only-Grenze, Multiplayer-Grenze und allgemeine Spielerlesbarkeit.

Der Findings-Schnitt darf Akzeptanz nicht faken. Ohne manuelle Review bleibt er `needs_manual_review`; bei belegter Reibung routet er zu `TASK_963 - Release First Decision Integrated Polish Followup`; bei sauberer Review darf er zu `TASK_963 - Release First Decision Next Playable Loop` fuehren. Er erzeugt keine Commands, Movement-, Combat-, Damage-, UI- oder Multiplayer-Wahrheit.

## Release First Decision Next Playable Loop (TASK_963)
TASK_963 macht aus dem ersten `Preview -> GO -> Feedback`-Griff eine zweite kleine Entscheidung. Der Spieler soll nach dem ersten Kontakt nicht nur Feedback sehen, sondern einen klaren Folgegriff lesen: `HOLD` Winkel halten, `ADV` gedeckt nachsetzen oder `BACK` neu sammeln.

Der Loop ist read-only und erzeugt keine zweite Gameplay-Wahrheit. Ohne echte TASK_962-Akzeptanz darf er als Live-Preview sichtbar sein, muss aber `preview_available_needs_task_962_acceptance` melden. Mit akzeptierten TASK_962-Findings wird er `ready_for_second_decision_loop` und routet zu `TASK_964 - Release First Decision Loop Two Playtest`.

## Release First Decision Loop Two Playtest (TASK_964)
TASK_964 prueft den zweiten Griff als sichtbaren HUD-Playtest. Die TASK_963-Zeile muss in Selected Fireteam, Mission Control und Command Feedback lesbar sein, bevor der naechste echte zweite Spielzug gebaut wird.

Der Analyzer bleibt read-only: Er bewertet `selected_fireteam_shows_loop_line`, `mission_control_shows_loop_line`, `command_feedback_exports_loop_line`, `hold_advance_back_visible` und `manual_acceptance_state_visible`. Bei Erfolg meldet er `gate = loop_two_playtest_passed`; bei Reibung routet er zu `TASK_965 - Release First Decision Loop Two Polish`. Er erzeugt keine Commands, keine Movement-, Fire-, Damage- oder Multiplayer-Wahrheit.

## Release First Decision Loop Two Polish (TASK_965)
TASK_965 uebersetzt den sichtbaren zweiten Griff in klare Intent-Bedeutung: `HOLD Defend`, `ADV Move`, `BACK Return`. Der Spieler soll verstehen, welcher Befehl gemeint ist, ohne dass der HUD-Pfad den Befehl ausfuehrt.

Der Snapshot bleibt read-only und setzt fuer jeden zweiten Intent `execution_boundary = requires_go`. Erwartet sind drei stabile Intents fuer `hold_angle`, `advance_cover` und `fallback_regroup`; sichtbare Zeilen duerfen keine rohen Choice-IDs zeigen. Bei Erfolg routet TASK_965 zu `TASK_966 - Release First Decision Loop Two Execution Hook`.

## Release First Decision Loop Two Execution Hook (TASK_966)
TASK_966 macht die zweite Entscheidung anschlussfaehig an vorhandene Bedienpfade. Aus einem ausgewaehlten Intent wird ein Command-Draft, der zeigt, welcher Controller-Pfad beim Bestaetigen genutzt werden soll.

Der Hook bleibt read-only: `auto_confirms = false`, `auto_executes_go = false`, keine Commands und keine Movement-Mutation. HOLD/ADV/BACK muessen auf bestehende Pfade zeigen und GO sichtbar halten. Der naechste Beweis ist `TASK_967 - Release First Decision Loop Two GO Smoke`.

## Release First Decision Loop Two GO Smoke (TASK_967)
TASK_967 prueft den zweiten Griff als Smoke-Evidence: Der Spielerpfad muss Confirm und GO als getrennte Schritte belegen, die vorhandenen Controller-Pfade nutzen und nach GO sichtbares Feedback erzeugen.

Der Smoke-Snapshot bleibt read-only. Ohne Trace ist der Zustand bewusst `needs_loop_two_go_smoke`; bestandene Evidence routet zu `TASK_968 - Release First Decision Loop Two Runtime Button`, damit der belegte Pfad danach aus der sichtbaren Runtime-Bedienung erreichbar wird.

## Release First Decision Loop Two Runtime Button (TASK_968)
TASK_968 macht die zweite Entscheidung als `2ND`-Button in der Command-Matrix erreichbar. Der Button bestaetigt den zweiten Intent und laesst `GO` sichtbar als separaten Schritt.

Der Button nutzt `CommandSlot07` und bestehende Controller-Pfade: `_issue_command(...)` fuer HOLD/ADV oder `return_selected_fireteams_to_plan()` fuer BACK. Er darf kein automatisches `execute_selected_fireteam_orders()` ausloesen. Der naechste Beweis ist ein Real-Window-Capture in TASK_969.

## Release First Decision Loop Two Real Window Capture (TASK_969)
TASK_969 prueft nicht noch mehr Theorie, sondern den echten Fensterblick: Ist `2ND` sichtbar, lesbar, bestaetigbar, bleibt `GO` separat, und ist Post-Confirm-Feedback erkennbar? Das Manifest muss diese Punkte als Pflichtchecks fuehren.

Der Capture-Schnitt bleibt read-only. Ohne Manifest meldet er `needs_real_window_capture`; mit reviewbarem Manifest routet er zu `TASK_970 - Release First Decision Loop Two Visual Findings`; erst manuell erledigte Pflichtchecks akzeptieren den Capture. Keine Shortcut-, UI-, Command-, Movement-, Fire-, Damage- oder Multiplayer-Wahrheit wird erzeugt.

## Release First Decision Loop Two Visual Findings (TASK_970)
TASK_970 macht aus dem zweiten echten Fensterblick einen konkreten Spielerbefund. Bewertet werden `2ND`-Sichtbarkeit, Lesbarkeit, Confirm-Beobachtung, klare `GO`-Trennung, Post-Confirm-Feedback, Pre-GO-Grenze und Read-only-HUD-Grenze.

Der Findings-Schnitt bleibt read-only. Ohne manuelle Review bleibt er `needs_manual_review`; bei Reibung routet er zu `TASK_971 - Release First Decision Loop Two Visual Polish`; bei sauberem Befund zu `TASK_971 - Release First Decision Loop Two Playability Smoke`. Er erzeugt keine UI-, Command-, Movement-, Fire-, Damage- oder Multiplayer-Wahrheit.

## Release First Decision Loop Two Visual Polish (TASK_971)
TASK_971 poliert die Lesbarkeit des zweiten Griffs: `2ND` bleibt kompakt, der Tooltip erklaert den zweiten Griff, die HUD-/Command-Feedback-Zeile nennt `GO separat`, und Post-Confirm-Feedback sagt dem Spieler den naechsten Griff.

Der Polish-Snapshot bleibt read-only. Er darf Button-Metadaten, Mindestgroesse, Tooltip und Feedback-Zeilen liefern, aber keine Commands erzeugen und kein `GO` ausloesen. Der naechste Beweis ist `TASK_972 - Release First Decision Loop Two Playability Smoke`.

## Release First Decision Loop Two Playability Smoke (TASK_972)
TASK_972 prueft den zweiten Griff als kleinen Ablauf: `2ND` sichtbar, zweiter Griff bestaetigt, `GO` bleibt separat, `GO` wird erst danach ausgefuehrt, und Post-GO-Feedback ist sichtbar.

Der Smoke-Snapshot bleibt read-only. Er darf Trace-Evidence bewerten und eine Statuszeile liefern, aber keine Commands erzeugen und keine Gameplay- oder Multiplayer-Wahrheit setzen. Bei Erfolg routet er zu `TASK_973 - Release First Decision Loop Two Real Window Recapture`.

## Release First Decision Loop Two Real Window Recapture (TASK_973)
TASK_973 legt den echten Fenster-Recapture-Rahmen nach dem bestandenen TASK_972-Smoke an. Erwartet sind Manifest-Felder fuer TASK_972-Source-Schema, Launch-Argument, Window-/Desktop-Screenshotpfade, Prozessmetadaten, `window_handle_print` und Pflichtchecks fuer `2ND`, getrenntes `GO`, Post-GO-Feedback und sichtbare Smoke-Zeile.

Der Recapture-Snapshot bleibt read-only und darf erst `accepted` werden, wenn die manuellen Pflichtchecks abgeschlossen sind. Ohne Sichtabnahme bleibt er `review_ready`; ohne Manifest bleibt er `needs_real_window_recapture`. Er erzeugt keine Commands, kein Movement, keine Combat-/Damage-Ereignisse und keine Multiplayer-Wahrheit.

## Release First Decision Loop Two Recapture Visual Findings (TASK_974)
TASK_974 trennt technische Recapture-Evidence vom eigentlichen Spielerblick. Ein guter TASK_973-Recapture ohne Review-Notizen bleibt `needs_manual_review`; belegte Reibungen wie fehlende Smoke-Zeile, schwaches Post-GO-Feedback, unklare `GO`-Trennung oder fehlende Multiplayer-/HUD-Grenzbestaetigung routen zu `TASK_975 - Release First Decision Loop Two Recapture Visual Polish`.

Ein sauberer Sichtbefund darf erst zum Acceptance-Slice routen, wenn `2ND`, Confirm, getrenntes `GO`, GO-Ausfuehrung, Post-GO-Feedback, Smoke-Zeile, HUD-read-only-Grenze, Multiplayer-Grenze und Spielerlesbarkeit manuell bestaetigt sind. Der Findings-Snapshot bleibt read-only und erzeugt keine Commands, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit.

## Release First Decision Loop Two Acceptance Slice (TASK_975)
TASK_975 verbindet akzeptierte TASK_974-Findings mit einem Ablauf-Trace. Der Slice muss belegen, dass der Release-Kontext erhalten bleibt, `2ND` sichtbar und bestaetigt ist, `GO` separat bleibt und erst danach ausgefuehrt wird, Post-GO-Feedback sichtbar ist und die Spielerfragen zum zweiten Griff beantwortet sind.

Der Acceptance-Snapshot bleibt read-only. Ohne Trace bleibt er `needs_acceptance_slice_trace`; bei regressiver Evidence routet er zu einem engen Recapture-Polish; bei voller Evidence meldet er `loop_two_acceptance_slice_passed` und fuehrt zu `TASK_976 - Release First Decision Loop Two Player Loop Extension`. Er erzeugt keine Commands, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit.

## Release First Decision Loop Two Player Loop Extension (TASK_976)
TASK_976 macht aus dem akzeptierten zweiten Griff wieder eine naechste Spielerentscheidung. Erwartet sind vier read-only Choices: `SECURE Bereich sichern`, `PUSH Ziel druecken`, `FLANK Druck drehen` und `RESET neu sammeln`.

Der Extension-Snapshot liefert `NEXT/WHY`-Zeilen und eine Empfehlung aus kleinem taktischem Kontext, erzeugt aber keine Commands, kein Movement und keine Multiplayer-Wahrheit. Der naechste Schritt ist HUD-Wiring in TASK_977, damit diese Choices sichtbar werden.

## Release First Decision Loop Two Player Loop HUD Wiring (TASK_977)
TASK_977 macht die TASK_976-Choices in den bestehenden HUD-/Command-Feedback-Snapshots sichtbar. Erwartet sind kurze read-only Zeilen fuer Selected Fireteam, Mission Control und Command Feedback sowie vier Choice-Chips fuer `SECURE`, `PUSH`, `FLANK` und `RESET`.

Das Wiring darf keine Choice ausfuehren und kein `GO` bestaetigen. Ohne aktive TASK_976-Quelle bleibt der Snapshot blockiert; mit aktiver Quelle liefert er nur Anzeige- und Sichtbarkeitsdaten. Der naechste Schritt ist ein Choice-Hook in TASK_978.

## Release First Decision Loop Two Player Loop Choice Hook (TASK_978)
TASK_978 macht die sichtbaren TASK_977-Choice-Chips anschlussfaehig, ohne sie auszufuehren. Der Hook uebersetzt `SECURE`, `PUSH`, `FLANK` und `RESET` in read-only Command-Drafts fuer vorhandene Befehlswege.

Der Hook darf nur `confirm_action`, `execute_action`, Command-Typ und eine kurze Hook-Zeile beschreiben. `GO` bleibt separat, `auto_confirms` und `auto_executes_go` bleiben false. Runtime-Buttons oder echte Bestätigung sind Folgearbeit in TASK_979.

## Release First Decision Loop Two Player Loop Runtime Choice Buttons (TASK_979)
TASK_979 macht aus dem TASK_978-Hook stabile Runtime-Button-Spezifikationen. `SECURE`, `PUSH`, `FLANK` und `RESET` liegen auf `CommandSlot08` bis `CommandSlot11` und tragen Choice-ID, Tooltip, Press-Action und `GO separat`.

Der Snapshot bleibt Anzeige-/Bedienvertrag: Er darf Button-Nodes markieren, aber keine bestaetigte Order, kein Movement und kein `GO` erzeugen. Der naechste Beweis ist ein Choice-Confirm-Smoke in TASK_980.

## Release First Decision Loop Two Player Loop Choice Confirm Smoke (TASK_980)
TASK_980 belegt die vier Runtime-Choices als kleinen Bedien-Smoke. Ein Choice-Button darf eine vorhandene Command-Vorbereitung bestaetigen und sichtbares Feedback erzeugen; `GO` muss danach weiterhin als separater Schritt erkennbar bleiben.

Der Smoke-Snapshot bleibt read-only und bewertet Trace-Evidence fuer Button-Press, vorhandenen Press-/Confirm-/Execute-Pfad, Confirm-Erfolg, getrenntes `GO`, Post-Confirm-Feedback und Command-Queue-Lifecycle. Auto-GO, fehlendes Feedback oder Gameplay-/Multiplayer-Wahrheit im UI sind Regressionen. Der naechste Beweis ist `TASK_981 - Release First Decision Loop Two Player Loop Real Window Capture`.

## Release First Decision Loop Two Player Loop Real Window Capture (TASK_981)
TASK_981 prueft den echten Runtime-Blick auf den neuen Spielerloop. Erwartet sind sichtbare und lesbare `SECURE`, `PUSH`, `FLANK` und `RESET`-Buttons, ein beobachteter Choice-Confirm, sichtbares Feedback, klare `GO`-Trennung und eine sichtbare Smoke-Zeile.

Der Capture-Snapshot bleibt read-only und akzeptiert erst nach manueller Sichtabnahme aller Pflichtchecks. Ohne Manifest bleibt er `needs_real_window_capture`; mit gueltigem Manifest wird er `review_ready`. Er erzeugt keine UI-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit. Der naechste Schritt ist `TASK_982 - Release First Decision Loop Two Player Loop Visual Findings`.

## Release First Decision Loop Two Player Loop Visual Findings (TASK_982)
TASK_982 trennt den technischen TASK_981-Capture vom eigentlichen Spielerblick. Bewertet werden sichtbare/lesbare `SECURE/PUSH/FLANK/RESET`-Buttons, beobachteter Choice-Confirm, lesbares Confirm-Feedback, getrenntes `GO`, keine Ausfuehrung vor `GO`, sichtbare Smoke-Zeile, HUD-read-only-Grenze, Multiplayer-Grenze und Gesamtlesbarkeit.

Der Findings-Snapshot bleibt read-only. Ohne manuelle Review bleibt er `needs_manual_review`; bei Reibung routet er zu `TASK_983 - Release First Decision Loop Two Player Loop Visual Polish`; bei sauberem Befund zu `TASK_983 - Release First Decision Loop Two Player Loop Acceptance Slice`. Er erzeugt keine UI-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit.

## Release First Decision Loop Two Player Loop Visual Polish (TASK_983)
TASK_983 macht die vier Runtime-Choices lesbarer, ohne neue Befehlslogik einzufuehren. Aus TASK_982-Findings und TASK_979-Button-Specs entstehen Mindestgroessen, Tooltips, Style-IDs, Gruppenlinie und Confirm-Feedback-Zeile fuer `SECURE/PUSH/FLANK/RESET`.

Der Snapshot bleibt read-only. Die Buttons duerfen visuell ruhiger und lesbarer werden und Metadaten tragen, aber keine Commands, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit erzeugen. Der naechste Beweis ist `TASK_984 - Release First Decision Loop Two Player Loop Acceptance Slice`.

## Release First Decision Loop Two Player Loop Acceptance Slice (TASK_984)
TASK_984 akzeptiert den gepolishen Vier-Choice-Loop nur mit Trace-Evidence. Bewertet werden sichtbare und lesbare `SECURE/PUSH/FLANK/RESET`-Choices, Tooltips mit `GO`-Grenze, Confirm-Feedback, getrenntes `GO`, keine Auto-Ausfuehrung, Order-Vorbereitung, Spielerlesbarkeit, HUD-read-only und Multiplayer-Grenze.

Der Acceptance-Snapshot bleibt read-only. Ohne Trace bleibt er `needs_player_loop_acceptance_trace`; bei Reibung routet er zurueck zu TASK_983; bei voller Evidence fuehrt er zu `TASK_985 - Release First Decision Loop Two Player Loop Scenario Outcome Slice`. Er erzeugt keine UI-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit.

## Release First Decision Loop Two Player Loop Scenario Outcome Slice (TASK_985)
TASK_985 macht aus dem akzeptierten Vier-Choice-Loop ein kleines Szenario-Ergebnis. Bewertet werden gewaehlte Choice, sichtbare Outcome-Zeile, Mini-Zielzustand, naechster Griff, Spielerlesbarkeit, HUD-read-only und Multiplayer-Grenze.

Der Outcome-Snapshot bleibt read-only. Ohne Outcome-Trace bleibt er `needs_player_loop_outcome_trace`; bei Reibung bleibt er in TASK_985; bei voller Evidence fuehrt er zu `TASK_986 - Release First Decision Loop Two Player Loop Outcome Real Window Capture`. Er erzeugt keine UI-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit.

## Release First Decision Loop Two Player Loop Outcome Real Window Capture (TASK_986)
TASK_986 legt den echten Fensterrahmen fuer das TASK_985-Outcome fest. Bewertet werden Outcome-Zeile, Mini-Zielzustand, naechster Griff, Spielerlesbarkeit, Screenshotpfade, manuelle Pflichtchecks, HUD-read-only und Multiplayer-Grenze.

Der Capture-Snapshot bleibt read-only und setzt `manual_review_done` nicht automatisch. Ohne Manifest bleibt er `needs_outcome_real_window_capture`; ein gueltiges Manifest wird `review_ready`; vollstaendige manuelle Checks akzeptieren ihn fuer `TASK_987 - Release First Decision Loop Two Player Loop Outcome Visual Findings`. Er erzeugt keine UI-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit.

## Release First Decision Loop Two Player Loop Outcome Visual Findings (TASK_987)
TASK_987 trennt den technischen TASK_986-Outcome-Capture vom eigentlichen Spielerblick. Bewertet werden sichtbare Outcome-Zeile, Mini-Zielzustand, Next-Step-Zeile, Ergebnislesbarkeit, HUD-read-only-Grenze, Multiplayer-Grenze und korrektes Release-Fenster.

Der Findings-Snapshot bleibt read-only. Ohne manuelle Review bleibt er `needs_manual_review`; bei Reibung routet er zu `TASK_988 - Release First Decision Loop Two Player Loop Outcome Visual Polish`; bei sauberem Befund zu `TASK_988 - Release First Decision Loop Two Player Loop Outcome Playability Slice`. Er erzeugt keine UI-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit.

## Release First Decision Loop Two Player Loop Outcome Visual Polish (TASK_988)
TASK_988 macht aus dem Outcome-Befund einen konkreten Lesbarkeitsvertrag. Erwartet sind drei getrennte Surfaces fuer `RESULT`, `OBJ` und `NEXT`, damit Ergebnis, Mini-Zielzustand und naechster Griff schnell erfassbar werden.

Der Polish-Snapshot bleibt read-only. Er darf Surface-Specs, Style-IDs, Mindesthoehen, Autowrap und eine kompakte `RESULT | OBJ | NEXT`-Zeile liefern, erzeugt aber keine Commands, kein Movement, keine Combat-/Damage-Ereignisse und keine Multiplayer-Wahrheit. Der naechste Beweis ist `TASK_989 - Release First Decision Loop Two Player Loop Outcome Playability Slice`.

## Release First Decision Loop Two Player Loop Outcome Playability Slice (TASK_989)
TASK_989 bewertet den TASK_988-Outcome-Polish gegen einen kleinen Playability-Trace. Der Spieler muss nach der Choice lesen koennen, was passiert ist, was sich am Ziel geaendert hat und welcher naechste Griff sinnvoll ist.

Der Slice bleibt read-only. Ohne Trace meldet er `needs_outcome_playability_trace`; fehlende RESULT-/OBJ-/NEXT-Lesbarkeit, fehlendes Spieler-Verstaendnis, HUD-State-Mutation oder gebrochene Multiplayer-Grenze melden `outcome_playability_regression_found`. Erst ein vollstaendiger Trace setzt `outcome_playability_slice_passed` und routet zu `TASK_990 - Release First Decision Loop Two Player Loop Next Micro Objective`.

## Release First Decision Loop Two Player Loop Next Micro Objective (TASK_990)
TASK_990 macht aus dem bestandenen Outcome wieder einen naechsten kleinen Auftrag. Erwartet sind drei read-only Micro-Objective-Karten: `SICHERN`, `DRUECKEN` und `SAMMELN`.

Der Snapshot bleibt Anzeige-/Planungsvertrag: Er darf eine Empfehlung, kurze Spielerzeilen, Warum-Zeilen, Confirm-/Execute-Pfadnamen und `GO separat` liefern, aber keine Commands erzeugen und kein Objective-State setzen. Der naechste Schritt ist `TASK_991 - Release First Decision Loop Two Player Loop Micro Objective HUD Wiring`.

## Release First Decision Loop Two Player Loop Micro Objective HUD Wiring (TASK_991)
TASK_991 macht die TASK_990-Karten in bestehenden HUD-/Command-Feedback-Flaechen lesbar. Erwartet sind drei read-only Chips fuer `SICHERN`, `DRUECKEN` und `SAMMELN` plus kurze Zeilen fuer Selected Fireteam, Mission Control und Command Feedback.

Der Snapshot bleibt eine Leseschicht: Er darf Fokus, Empfehlung, Tooltip-Texte, Chip-Zeile und `GO separat` liefern, aber keine Commands erzeugen, kein Movement starten und keine Multiplayer-Wahrheit setzen. Der naechste Schritt ist `TASK_992 - Release First Decision Loop Two Player Loop Micro Objective Choice Hook`.

## Release First Decision Loop Two Player Loop Micro Objective Choice Hook (TASK_992)
TASK_992 macht aus dem fokussierten Micro-Objective einen vorbereitenden Command-Draft. `SICHERN`, `DRUECKEN` und `SAMMELN` mappen auf bestehende Command-Typen und bleiben an die vorhandenen Confirm-/GO-Pfade gebunden.

Der Snapshot bleibt read-only: Er darf `micro_objective_command_draft`, Hook-Zeile, `confirm_action = _issue_command`, `execute_action = execute_selected_fireteam_orders` und `GO separat` liefern, aber keine Commands bestaetigen, kein Movement starten und keine Multiplayer-Wahrheit setzen. Der naechste Schritt ist `TASK_993 - Release First Decision Loop Two Player Loop Micro Objective Runtime Buttons`.

## Release First Decision Loop Two Player Loop Micro Objective Runtime Buttons (TASK_993)
TASK_993 macht die drei Micro-Objectives als stabile Runtime-Button-Specs greifbar. Erwartet sind kompakte Buttons fuer `SICHERN`, `DRUECKEN` und `SAMMELN` auf stabilen Command-Slots.

Der Snapshot bleibt read-only: Er darf Button-Slots, Texte, Tooltips, `press_action = confirm_release_first_decision_loop_two_player_loop_micro_objective_button`, `execute_action = execute_selected_fireteam_orders` und `GO separat` liefern, aber keinen Button-Press simulieren, keine Commands bestaetigen, kein Movement starten und keine Multiplayer-Wahrheit setzen. Der naechste Schritt ist `TASK_994 - Release First Decision Loop Two Player Loop Micro Objective Confirm Smoke`.

## Release First Decision Loop Two Player Loop Micro Objective Confirm Smoke (TASK_994)
TASK_994 prueft den ersten Micro-Objective-Klick als kleinen Smoke. Erwartet ist, dass ein Button wie `SICHERN` den vorhandenen Confirm-Pfad vorbereitet, eine kurze Rueckmeldung erzeugt und den getrennten `GO`-Schritt weiter sichtbar laesst.

Der Snapshot bleibt read-only: Er darf Trace-Evidence, Confirm-Zeile, Feedback-Zeile, `confirm_action = confirm_release_first_decision_loop_two_player_loop_micro_objective_button`, `draft_confirm_action = _issue_command`, `execute_action = execute_selected_fireteam_orders` und `GO separat` liefern, aber selbst keine Movement-, Fire-, Damage- oder Multiplayer-Wahrheit setzen. Der naechste Schritt ist `TASK_995 - Release First Decision Loop Two Player Loop Micro Objective Acceptance Slice`.

## Release First Decision Loop Two Player Loop Micro Objective Acceptance Slice (TASK_995)
TASK_995 nimmt den bestandenen Micro-Objective-Confirm-Smoke und prueft, ob daraus ein kleiner lesbarer Spielergriff wird. Erwartet sind sichtbare und lesbare `SICHERN`, `DRUECKEN`, `SAMMELN`, bestaetigte Auswahl, sichtbares Feedback, vorbereitete Order und weiterhin getrenntes `GO`.

Der Snapshot bleibt read-only: Er darf Acceptance-Evidence, beantwortete Spielerfragen, Status-/Gate-Werte und eine kompakte `SICHERN / DRUECKEN / SAMMELN | ... | GO separat`-Zeile liefern, aber keinen Outcome setzen, kein Movement starten und keine Multiplayer-Wahrheit erzeugen. Der naechste Schritt ist `TASK_996 - Release First Decision Loop Two Player Loop Micro Objective Outcome Slice`.

## Release First Decision Loop Two Player Loop Micro Objective Outcome Slice (TASK_996)
TASK_996 nimmt den akzeptierten Micro-Objective-Griff und prueft, ob daraus eine kleine Ergebnis-Rueckmeldung wird. Erwartet sind gewaehlte Micro-Objective, Outcome-Zeile, Mini-Zielzustand, naechster Griff und eine fuer den Spieler lesbare Rueckmeldung.

Der Snapshot bleibt read-only: Er darf Outcome-Evidence, Status-/Gate-Werte, `outcome_line`, `mini_objective_state` und `next_step_line` liefern, aber keinen Objective-State setzen, kein Movement starten, kein Feuer/Damage ausloesen und keine Multiplayer-Wahrheit erzeugen. Der naechste Schritt ist `TASK_997 - Release First Decision Loop Two Player Loop Micro Objective Real Window Capture`.

## Release First Decision Loop Two Player Loop Micro Objective Real Window Capture (TASK_997)
TASK_997 trennt den Micro-Objective-Outcome-Snapshot vom echten Fensterbeweis. Erwartet ist ein Manifest, das das Release-Fenster, Screenshotpfade, sichtbare Outcome-Zeile, Mini-Zielzustand, naechsten Griff, Spielerlesbarkeit und HUD-/Multiplayer-Grenze reviewbar macht.

Der Capture-Snapshot bleibt read-only und setzt `manual_review_done` nicht automatisch. Ohne Manifest bleibt er `needs_micro_objective_real_window_capture`; ein gueltiges Manifest wird `review_ready`; vollstaendige manuelle Checks akzeptieren ihn fuer `TASK_998 - Release First Decision Loop Two Player Loop Micro Objective Visual Findings`. Er erzeugt keine UI-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit.

## Release First Decision Loop Two Player Loop Micro Objective Visual Findings (TASK_998)
TASK_998 trennt den technischen TASK_997-Capture vom eigentlichen Spielerblick. Bewertet werden sichtbare Micro-Objective-Outcome-Zeile, Mini-Zielzustand, Next-Step-Zeile, Ergebnislesbarkeit, HUD-read-only-Grenze, Multiplayer-Grenze und korrektes Release-Fenster.

Der Findings-Snapshot bleibt read-only. Ohne manuelle Review bleibt er `needs_manual_review`; bei Reibung routet er zu `TASK_999 - Release First Decision Loop Two Player Loop Micro Objective Visual Polish`; bei sauberem Befund zu `TASK_999 - Release First Decision Loop Two Player Loop Micro Objective Playability Slice`. Er erzeugt keine UI-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit.

## Release First Decision Loop Two Player Loop Micro Objective Visual Polish (TASK_999)
TASK_999 definiert die sichtbare Leseflaeche nach einem Micro-Objective-Ausgang. Erwartet werden drei getrennte read-only Surfaces fuer `OUTCOME`, `OBJ` und `NEXT`, damit der Spieler nach einem kleinen Griff sofort versteht, was passiert ist, welches Mini-Ziel gilt und was als naechster Griff angeboten wird.

Der Polish-Snapshot bleibt read-only. Ein falscher oder nicht polishbarer TASK_998-Befund blockiert mit expliziten Blockern; ein polishbarer Befund routet zu `TASK_1000 - Release First Decision Loop Two Player Loop Micro Objective Playability Slice`. Er erzeugt keine UI-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit.

## Release First Decision Loop Two Player Loop Micro Objective Playability Slice (TASK_1000)
TASK_1000 prueft, ob die TASK_999-Flaechen als Spielergriff funktionieren. Ein guter Trace bestaetigt sichtbares `OUTCOME`, `OBJ` und `NEXT`, verstandenen Micro-Objective-Ausgang, verstandenen naechsten Griff, sichtbares Post-Objective-Feedback, erhaltene GO-Grenze und unveraenderte HUD-/Multiplayer-Grenzen.

Der Playability-Snapshot bleibt read-only. Ohne Trace bleibt er `needs_micro_objective_playability_trace`; fehlende Checks werden als Regression benannt; ein bestandener Trace routet zu `TASK_1001 - Release First Decision Loop Two Player Loop Micro Objective Round Trip Smoke`. Er erzeugt keine UI-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit.

## Release First Decision Loop Two Player Loop Micro Objective Round Trip Smoke (TASK_1001)
TASK_1001 prueft, ob der bestandene Micro-Objective-Griff wieder in den naechsten Griff zurueckfuehrt. Ein guter Trace bestaetigt sichtbare naechste Micro-Objective-Optionen, Confirm, sichtbares Confirm-Feedback, weiterhin separates `GO`, keine Auto-Ausfuehrung nach Confirm, Post-Round-Trip-Feedback, Rueckkehr in den Entscheidungszustand, wiederverwendeten Command-Pfad sowie HUD-/Multiplayer-Grenzen.

Der Round-Trip-Smoke bleibt read-only. Ohne Trace bleibt er `needs_micro_objective_round_trip_trace`; fehlende Checks werden als Regression benannt; ein bestandener Trace routet zu `TASK_1002 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Playtest Slice`. Er erzeugt keine UI-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit.

## Release First Decision Loop Two Player Loop Micro Objective Round Loop Playtest Slice (TASK_1002)
TASK_1002 prueft, ob aus dem bestandenen Round-Trip ein wiederholbarer kleiner Spielgriff wird. Ein guter Trace bestaetigt zwei lesbare Micro-Objective-Runden, sichtbare zweite NEXT-Optionen, Confirm, getrenntes `GO`, Post-Feedback, erneuten NEXT-Zustand, kein Feedback-Dead-End, stabile HUD-Surfaces, wiederverwendeten Command-Pfad und erhaltene Multiplayer-Grenze.

Der Round-Loop-Playtest-Slice bleibt read-only. Ohne Trace bleibt er `needs_micro_objective_round_loop_playtest_trace`; fehlende Checks werden als Regression benannt; ein bestandener Trace routet zu `TASK_1003 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Runtime Polish`. Er erzeugt keine UI-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit.

## Release First Decision Loop Two Player Loop Micro Objective Round Loop Runtime Polish (TASK_1003)
TASK_1003 uebersetzt den bestandenen Zwei-Runden-Slice in kurze Runtime-Leseflaechen. Erwartet werden Surface-Specs fuer `ROUND`, `NEXT` und `GO`, eine Selected-Fireteam-Zeile, eine Mission-Control-Zeile und eine Command-Feedback-Zeile. Die Texte muessen spielernahe Tokens nutzen, die `GO separat`-Grenze sichtbar halten und rohe interne Check-IDs verstecken.

Der Runtime-Polish bleibt read-only. Ein bestandener Source-Slice routet zu `TASK_1004 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Real Window Capture`. Er erzeugt keine UI-Baeume, keine Commands, kein Movement, keine Combat-/Damage-Ereignisse und keine Multiplayer-Wahrheit.
