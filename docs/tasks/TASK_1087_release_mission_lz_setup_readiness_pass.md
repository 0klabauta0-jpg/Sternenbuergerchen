# TASK_1087 - Release Mission/LZ Setup Readiness Pass

## Ziel / Problem
Nach TASK_1086 ist der Aufbau von `deeplink_requested` bis `mission_runtime_nodes_ready` mit 10.400 ms der groesste verbleibende Abschnitt des echten Release-Direkteinstiegs. Dieser Block soll entlang der realen Homebase-, Missions-, Transfer-, LZ-, Drop- und Preview-Grenzen zerlegt und am dominanten Teil reduziert werden.

## Ursache / Sinnhaftigkeit
Der aktuelle Trace fasst den gesamten LZ-/Drop-/Preview-Pfad in einer Stufe zusammen. Innerhalb dieses Pfads existieren noch mehrere feste Frame-Wartefenster. Ohne feinere Evidenz waere unklar, ob sie legitime Runtime-Bereitschaft abwarten oder nur historische Sicherheitsabstaende sind.

## Umfang
- Zusätzliche Trace-Stufen fuer Missionsstart, Transferankunft, LZ-Platzierung, Deboarding und Move-Preview.
- Begrenzte zustandsbasierte Readiness-Pruefung fuer den belegten dominanten Unterabschnitt.
- Normaler Homebase-/Dropship-/Mission-Handoff und bestehende Controller-Commands bleiben erhalten.
- Frischer Godot-4.6.2-Release-Capture als Endabnahme.

## Nicht-Ziele
- Kein direkter Spawn von Fireteams aus dem Meta-Layer.
- Kein Ueberspringen von MissionSetup, Dropship-Payload, LZ oder Deboarding.
- Kein UI-, Combat-, Pathfinding- oder Multiplayer-Rewrite.
- Keine Optimierung nur fuer Headless-Wandzeit.

## Relevante Contracts / Dokumente
- `docs/dev/homebase_direct_dropship_flow_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_1086_release_mission_ready_time_performance_pass.md`
- `docs/tasks/TASK_1057_controlled_dropship_inbound_to_deboard_trace.md`

## Akzeptanzkriterien
- TASK_1087-Verifier scheitert vor der Implementierung an fehlenden Setup-Stufen und/oder blinden Wartefenstern.
- Trace weist Missionstart, Transfer, LZ, Deboard und Preview mit Delta-/Gesamtdauer aus.
- Der optimierte Pfad wartet auf reale Runtime-Snapshots mit harter Obergrenze und explizitem Blocker.
- Fireteam-/Payload-Zuordnung und deboardete Runtime-Units bleiben korrekt.
- TASK_1086, TASK_1085, TASK_396 und TASK_503 bleiben gruen.
- TASK_1082/TASK_1083 bleiben fuer Multiplayer-Autoritaet und Zwei-Instanz-Replikation gruen.
- Der frische 4.6.2-Release erreicht denselben sichtbaren First-Exchange-Endzustand schneller als 31.363 ms.

## Betroffene Dateien
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/task_1087_release_mission_lz_setup_readiness_pass.gd`
- Status-, Roadmap-, Contract- und HTML-Berichtsdokumentation

## Lokale Pruefung
- TASK_1087 Red/Green
- TASK_1086, TASK_1085, TASK_1084
- TASK_396, TASK_503, TASK_1057-nahe Handoff-Pruefungen
- TASK_1082, TASK_1083
- Godot-4.6.2-Export, Provenance-Startcheck und echter Window-Capture
- HTML-Inline-JavaScript und `git diff --check`

## Risiken / offene Punkte
Ein Teil der Dauer kann echte Szeneninstanziierung, Asset-/Terrain-Aufbau oder notwendige UI-Initialisierung sein. Solche Kosten werden nicht durch Testabkuerzungen verdeckt, sondern als eigener Folgeengpass dokumentiert.

## Ergebnis
Der vergleichbare direkte Headless-LZ-Trace sank von 12.814 auf 5.774 ms. Der volle First-Exchange-Trace endet im aktuellen Arbeitsstand nach 27.722 ms; groesster Restabschnitt ist Kontaktaufbau bis echte FireEvent-Evidence mit 11.823 ms. TASK_1088 setzt dort an.
