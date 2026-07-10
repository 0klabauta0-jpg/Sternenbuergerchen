# TASK_1088 - Release Contact/Fire Ready-Time Pass

## Ziel / Problem
Nach TASK_1087 ist der Abschnitt von `after_contact_setup` bis `after_immediate_exchange_evidence` mit 7.996 ms der groesste verbleibende Block im echten Release-Trace. Dieser Abschnitt soll entlang von Setup-Command, Detection/ContactTracker, LOS/Combat-Decision, FireEvent und sichtbarer Evidence zerlegt und am dominanten Teil reduziert werden.

## Ursache / Sinnhaftigkeit
Der aktuelle Trace fasst mehrere autoritative und read-only Schritte zusammen. Ohne feinere Grenzen ist nicht klar, ob Detection-Timer, wiederholtes Contact-Scanning, LOS, Combat-Aufloesung oder der anschliessende Evidence-/HUD-Snapshot dominiert.

## Umfang
- Leichte Trace-Stufen fuer Engagement-Setup, Contact-Tracking, Combat-Decision/FireEvent und Evidence-Snapshot.
- Bestehende Methodenaufrufe und deren Kosten getrennt messen.
- Nur den belegten dominanten Unterabschnitt optimieren.
- Echte FireEvent-, Damage-, Friendly-Fire-, ROE- und Multiplayer-Autoritaet erhalten.

## Nicht-Ziele
- Keine direkte FireEvent-Erzeugung im Meta-Layer.
- Kein festes Trefferergebnis oder Gameplay-RNG-Override.
- Kein Combat-, LOS-, ContactTracker- oder KI-Rewrite.
- Keine Aenderung normaler Spieler-Kampfregeln fuer einen schnelleren Testpfad.

## Relevante Contracts / Dokumente
- `docs/dev/combat_loop_authority_contract.md`
- `docs/dev/contact_report_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_1087_release_mission_lz_setup_readiness_pass.md`
- `docs/tasks/TASK_1084_release_deeplink_runtime_authority_repair.md`

## Akzeptanzkriterien
- TASK_1088-Verifier scheitert vor der Implementierung an fehlenden Contact-/Fire-Trace-Stufen.
- Trace trennt Setup-Command, Contact-Tracking, Fire-Decision/Event und Evidence-Aufbau.
- Der optimierte Pfad nutzt weiterhin echte Combat-Resolver- und SimulationRoot-Grenzen.
- #17/#18/#19 behalten dieselbe echte FireEvent-Quelle und `CONTACT FIRE`.
- LOS-, Damage-, ROE- und Friendly-Fire-Regressionen bleiben gruen.
- TASK_1087, TASK_1086, TASK_1085 und TASK_1084 bleiben gruen.
- TASK_1082/TASK_1083 bleiben fuer Multiplayer-Autoritaet und Replikation gruen.
- Ein frischer Godot-4.6.2-Release erreicht denselben sichtbaren Endzustand schneller als 25.732 ms.

## Betroffene Dateien
- `scripts/meta/meta_layer_flow.gd`
- bei belegtem Hotpath der eng zustaendige Combat-/Contact-Service
- `scripts/tests/task_1088_release_contact_fire_ready_time_pass.gd`
- Status-, Roadmap-, Contract- und HTML-Berichtsdokumentation

## Lokale Pruefung
- TASK_1088 Red/Green
- TASK_868 und relevante LOS-/Combat-Verifier
- TASK_1087, TASK_1086, TASK_1085, TASK_1084
- TASK_1082, TASK_1083
- Godot-4.6.2-Export, Provenance-Startcheck und echter Window-Capture
- HTML-Inline-JavaScript und `git diff --check`

## Risiken / offene Punkte
Ein Teil der Dauer kann aus echten Detection-Ticks oder umfangreichen read-only Snapshot-Aufbauten stammen. Autoritative Spielzeit wird nicht fuer den Release-Test verkuerzt; ein UI-/Evidence-Hotpath wird getrennt von Combat behandelt.

## Ergebnis
- Der neue Trace trennt Engagement-Commands, autoritativen Tick, Contact-Tracking, FireEvent, visuelles Feedback und Evidence-Aufbau.
- Der dominante Befund lag nicht in Detection, LOS oder Combat: `engagement_evidence_ready` benoetigte 11.068 ms, weil der Direkteinstieg zwei ueberlappende historische Review-Snapshot-Ketten inklusive tiefer Dictionary-Kopien aufbaute.
- `MissionTacticalSandboxController.get_release_first_exchange_immediate_evidence_snapshot()` liest jetzt nur vorhandene FireEvents und Contact-Decision-Diagnostik. Der Meta-Layer verpackt diese kompakte Wahrheit in denselben TASK-844-Handoff-Vertrag.
- Der ausfuehrliche historische TASK-844-Snapshot bleibt fuer Reports und Verifier unveraendert verfuegbar. Gameplay-, LOS-, Damage-, ROE- und Multiplayer-Autoritaet wurden nicht verschoben.
- Im vergleichbaren TASK-1088-Headless-Lauf sank die Evidence-Stufe von 11.068 ms auf 2 ms und der komplette Deep-Link von 20.641 ms auf 11.527 ms.

## Abschlusspruefung
- TASK_1088: 21/21 gruen.
- TASK_844: 36/36, TASK_847: 38/38, TASK_868: 41/41, TASK_873: 53/53 gruen.
- TASK_1082: 21/21, TASK_1083: 24/24, TASK_1084: 12/12, TASK_1085: 15/15, TASK_1086: 16/16, TASK_1087: 19/19 gruen.
- Naechster messbarer Kandidat ist der read-only Sichtbarkeits-/HUD-Readback nach dem Evidence-Aufbau; er soll nur mit frischem Release-Trace angefasst werden.
- Godot 4.6.2 exportiert den Merge-Stand erfolgreich; der Provenance-Startcheck ist gruen.
- Der direkte echte Release-Trace erreicht `deeplink_final / applied` nach 9.702 ms. Contact-Tracking benoetigt 2 ms, FireEvent 9 ms, visuelles Feedback 129 ms und Immediate Evidence 1 ms.
- Der echte Window-Capture zeigt `CONTACT FIRE` weiterhin als Primaerlesung in #17 Selected Fireteam, #18 Mission Control und #19 Event Log.
- Bekannter Harness-Befund: Der historische TASK-879-Wrapper reichte die Trace-Umgebungsvariable in seiner verschachtelten Capture-Kette nicht bis zum Release-Prozess durch (`runtime_trace_missing`). Der direkte Start desselben Exports schrieb 24 Samples bis `deeplink_final`; Gameplay und Export waren davon nicht betroffen.
