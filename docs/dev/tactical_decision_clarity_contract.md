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
