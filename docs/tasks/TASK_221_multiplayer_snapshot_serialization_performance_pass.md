# TASK_221 - Multiplayer Snapshot Serialization Performance Pass

## Ziel
Multiplayer-Snapshots sollen auf Build-/Apply-Kosten, Groesse, Frequenz, Determinismus und Anzeigegrenzen geprueft werden. Neue Enemy-Taktik, Weapon/VFX, Bubbles, Badges und Mission-Status duerfen Snapshots nicht aufblasen.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_166 - Multiplayer Authority Command Contract
- TASK_168 - Multiplayer Snapshot Replication Contract
- TASK_169 - Multiplayer Two-Client Playability Smoke
- TASK_187 - NPC Minimum Spacing and Multiplayer Authority
- TASK_204 - Enemy Tactics Multiplayer Authority Snapshot Patch
- TASK_214 - Comic Bubble Feedback Playability Smoke
- TASK_215 - Performance Deep Pass Baseline and Research

## Kontext
Snapshots sind spaeter fuer Multiplayer entscheidend. Wenn sie zu gross werden oder pro Frame teure Dictionaries bauen, wird das System schwer skalierbar. Gleichzeitig muessen Clients genug sehen: Positionen, Facing, Security, Fire-Events, Bubbles und Status.

## Umfang
1. Snapshot-Messung:
   - Build time.
   - Apply time.
   - Dictionary-/Array-Groesse.
   - JSON-/PackedByteArray-Schaetzung, falls sinnvoll.
   - Unit-/Event-/Bubble-/VFX-Zaehler.
2. Frequenz:
   - Welche Felder muessen jedes Snapshot?
   - Welche Felder sind Event-/Delta-Kandidaten?
   - Keine Text-/Assetdaten wiederholt senden, wenn ID reicht.
3. Determinismus:
   - Stabile Sortierung nach Unit-ID/Event-ID.
   - Keine clientseitige Enemy-AI oder Combat-Entscheidung.
4. Viewer-Grenze:
   - Apply-Pfad zeigt nur Visuals.
   - Keine `SimulationRoot`-Commands/Effects beim Anzeigen.
   - Bubbles/VFX aus Snapshot duerfen nicht Combat neu ausloesen.
5. Netzwerkprofil:
   - Godot Network Profiler manuell einbeziehen, wenn Multiplayer-Test laeuft.
   - Headless-Zaehler fuer lokale Smoke-Werte.
6. Verifier:
   - Kleine und groessere Unit-Anzahl.
   - Snapshot mit Enemy-Tactics, Muzzle, Bubbles und Objective.
   - Budgets tolerant starten.

## Nicht-Ziele
- Keine echte Online-Lobby.
- Keine Lag Compensation.
- Keine Prediction.
- Kein Netzwerkprotokoll-Rewrite.

## Akzeptanzkriterien
- [x] Snapshot-Build und Apply haben Timing-Zaehler.
- [x] Snapshot-Groesse wird grob messbar und reportbar.
- [x] Asset-, Bubble- und VFX-Daten werden als IDs statt grosser Payloads transportiert.
- [x] Apply-Pfad erzeugt keine Gameplay-Commands oder AI-Entscheidungen.
- [x] Sortierung bleibt deterministisch.
- [x] Ein TASK_221-Verifier prueft Build/Apply/Groesse/Frequenz und Side-Effect-Grenzen.

## Erwartete Dateien
- `scripts/multiplayer/multiplayer_snapshot_contract.gd`
- `scripts/core/simulation_root.gd`
- `scripts/tests/multiplayer_snapshot_performance_harness.gd`
- `docs/performance/multiplayer_snapshot_performance_report.md`
- `scripts/tests/task_221_multiplayer_snapshot_serialization_performance_pass.gd`
- `docs/tasks/TASK_221_multiplayer_snapshot_serialization_performance_pass.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_221_multiplayer_snapshot_serialization_performance_pass.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_168_multiplayer_snapshot_contract_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_169_multiplayer_two_client_playability_smoke.gd`
- [ ] Manueller Network-Profiler-Check, falls Multiplayer-Lauf verfuegbar ist.
- [x] `git diff --check`

## Risiken
- Zu fruehe Delta-Kompression kann Komplexitaet aufbauen, bevor die Payload wirklich ein Problem ist.
- Snapshot-Optimierung darf keine Anzeigeinfos verlieren, die fuer Debug und Playability wichtig sind.

## Umsetzung
- `MultiplayerSnapshotContract` normalisiert Units, Vital-Updates, Contacts, Enemy-Security, Enemy-Team-Tactics, Fire-Events und Feedback-Bubbles stabil.
- Feedback-Bubbles koennen jetzt als ID-only Snapshotdaten (`bubble_id`, `text_key`, Unit/Team/Fireteam, Tick/Sequence) transportiert werden.
- `build_serialization_metrics()` liefert JSON-Byte-Schaetzung, Dictionary-/Array-/Scalar-Zaehler, Feldzaehler, ID-only-Offender und kanonischen JSON-Diagnosewert.
- `SimulationRoot.set_multiplayer_snapshot_context()` und `build_multiplayer_snapshot()` reichen `feedback_bubbles` als reine Anzeige-/Snapshotdaten weiter.
- `MultiplayerSnapshotPerformanceHarness` misst 8-, 32- und 96-Unit-Szenarien mit Build-/Apply-Zeit, Payloadgroesse, Determinismus und side-effect-freiem Apply.

## Naechster Schritt
TASK_222 fasst alles in ein Regression-Gate zusammen.
