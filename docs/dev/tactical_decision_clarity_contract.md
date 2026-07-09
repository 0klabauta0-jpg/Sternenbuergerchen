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
