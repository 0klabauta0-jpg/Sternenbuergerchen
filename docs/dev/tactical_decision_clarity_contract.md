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
