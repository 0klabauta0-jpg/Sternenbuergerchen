# TASK_1089 - Release Trace Observer-Effect Guard

## Ziel / Problem
Der echte TASK-1088-Release erreicht `deeplink_final / applied` nach 9.702 ms. Mehrere erfolgreiche Trace-Stufen lesen dabei erneut den vollstaendigen Command-Feedback- und Visible-Status-Snapshot des Missionscontrollers. Die Diagnose verlaengert damit den gemessenen Pfad selbst.

## Ursache / Sinnhaftigkeit
`_build_release_first_exchange_exported_status_trace_sample()` ruft bei jedem nicht-null Controller zwei breite Snapshot-Ketten auf. Nach dem ersten FireEvent liegen die benoetigten CONTACT-FIRE-, HUD- und Read-only-Felder bereits in der Readability-/Visibility-Evidence vor und muessen nicht erneut aus dem gesamten Controller aufgebaut werden.

## Umfang
- Erfolgreiche Trace-Stufen verwenden kompakte, bereits berechnete Evidence.
- Hoechstens ein voller Controller-Snapshot im erfolgreichen First-GO-/First-Exchange-Trace.
- Fehler-/Blocked-Stufen duerfen fuer Diagnose weiterhin einen Controller lesen.
- Trace behaelt CONTACT FIRE fuer #17/#18/#19, FireEvent-ID, Read-only-Grenzen und finalen Applied-State.

## Nicht-Ziele
- Keine Aenderung an SimulationRoot, Combat, LOS, Detection, ROE oder Multiplayer-Autoritaet.
- Kein Entfernen der ausfuehrlichen Controller-Snapshots aus ihren regulaeren Review-APIs.
- Keine kosmetische HUD-Aenderung.

## Akzeptanzkriterien
- Red-Verifier belegt mehr als einen Controller-Vollsnapshot im bisherigen Erfolgs-Trace.
- Der neue Erfolgs-Trace meldet `controller_snapshot_count <= 1`.
- Finaler Trace zeigt weiterhin `CONTACT FIRE` in Selected Fireteam, Mission Control und Event Log.
- First-Exchange-Source referenziert weiterhin ein reales FireEvent.
- TASK_1088, TASK_1087, TASK_1086, TASK_1085, TASK_1084 und Multiplayer-ROE bleiben gruen.
- Frischer Godot-4.6.2-Release und Provenance-Startcheck sind gruen.

## Betroffene Dateien
- `scripts/meta/meta_layer_flow.gd`
- `scripts/mission/release_first_exchange_exported_status_source_trace.gd`
- `scripts/tests/task_1089_release_trace_observer_effect_guard.gd`
- Status-, Roadmap- und HTML-Berichtsdokumentation

## Lokale Pruefung
- TASK_1089 Red/Green
- TASK_1088, TASK_1087, TASK_1086, TASK_1085, TASK_1084
- TASK_1083 und TASK_1082
- HTML-Inline-JavaScript, `git diff --check`
- Godot-4.6.2-Export, Provenance-Startcheck und direkter Runtime-Trace

## Risiken / offene Punkte
Kompakte Trace-Daten duerfen keine neue Gameplay-Wahrheit bilden. Sie werden nur aus bereits aufgebauter read-only Evidence kopiert. Blocked-Pfade behalten reichere Diagnose, auch wenn sie dadurch langsamer sind.

## Ergebnis
- Der erfolgreiche Trace liest nur noch beim Pre-GO-Pruefpunkt den vollen Controller-Snapshot. Mission-Runtime, GO-Ready, Contact-Setup und alle Post-Fire-Stufen schreiben kompakte, bereits vorhandene Evidence.
- CONTACT FIRE bleibt in Selected Fireteam, Mission Control und Event Log erhalten; der Visible-Status-Source verweist weiter auf ein echtes FireEvent.
- Der TASK-879-Analyzer akzeptiert fehlgeschlagene Capture-Manifeste mit `runtime_trace: null`, ohne `Dictionary(null)`-Scriptfehler. Die fehlende Trace bleibt weiterhin ein sauberer Blocker.
- Der vergleichbare TASK-1088-Headless-Lauf sank von 11.527 ms auf 8.856 ms. TASK_1089 selbst ist 8/8 gruen.

## Abschlusspruefung
- TASK_879 63/63, TASK_1088 21/21, TASK_1087 19/19, TASK_1086 16/16, TASK_1085 15/15 und TASK_1084 12/12 gruen.
- TASK_1083 24/24 und TASK_1082 21/21 gruen; Host-Autoritaet, Ownership, Kompression, Packetisierung und Client-Read-only-State bleiben erhalten.
- Naechster Schritt nach dem echten Releasevergleich: spielnaher Zwei-Spieler-Station-Route-Playtest statt weiterer synthetischer Trace-Politur.
- Godot 4.6.2 exportiert den Merge-Stand erfolgreich; Provenance-Startcheck ist gruen.
- Im echten Release sinkt `deeplink_final / applied` von 9.702 ms auf 7.545 ms, rund 22 Prozent. Der 24-Sample-Trace enthaelt exakt einen Controller-Vollsnapshot.
- Finaler Release-Trace: Selected Fireteam, Mission Control und Event Log behalten CONTACT FIRE.
- Empfohlener Follow-up: TASK_1090 - Two-Player Station Route Decision Playtest. Zwei reale Instanzen sollen Deployment, Fireteam-Ownership, ersten Kontakt, getrennte Befehle und sichtbare Konsequenzen durchspielen.
