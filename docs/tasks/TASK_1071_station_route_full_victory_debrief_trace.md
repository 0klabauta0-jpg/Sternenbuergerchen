# TASK_1071 - Station Route Full Victory Debrief Trace

## Ziel / Problem

Nach TASK_1070 ist AA als sichtbare `AA->GO`-Aktion spielbar. Die restliche
Route Door -> Computer -> Cargo ist zwar einzeln als Gate-/Smoke-Logik
vorhanden, aber nicht als zusammenhaengender Spielerpfad ueber den sichtbaren
Context-Slot bis zum echten Victory-/Debrief-Handoff abgesichert.

## Ursache / Sinnhaftigkeit

Einzelverifier duerfen Steps direkt fortschreiben und pruefen damit nicht, ob
der Spieler bei jeder Route-Stufe die richtige Aktion sieht, plant, mit GO
ausfuehrt und den naechsten Schritt erhaelt. Gerade am letzten Cargo-Gate
waere ein stiller Handoff-Fehler sonst erst im Fenster sichtbar.

## Umfang

- Station Route vom Homebase-Katalog ueber Drop/Deboarding starten.
- Die vier realen Interactions AA, Door, Computer und Cargo nacheinander am
  Context-Slot `16.8` vorbereiten und mit separatem GO ausfuehren.
- Die bestehenden Formation-/Movement-Ziele im Verifier nur zeitbeschleunigt
  ansteuern; Runtime-Progress, Gate-Completion, Result und Debrief bleiben
  unveraenderte produktive Pfade.
- Den Victory-/Debrief-Handoff mit Result `victory` und
  `mission_outcome = won` pruefen.

## Nicht-Ziele

- Kein neuer MissionResult-, Gate-, Cargo-, Door- oder Debrief-Code ohne
  nachgewiesenen Handoff-Fehler.
- Kein Auto-GO oder Auto-Completion im Spiel.
- Kein Combat-/NPC-/Multiplayer-Rewrite.

## Relevante Contracts / Dokumente

- `docs/ARCHITECTURE.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/dev/homebase_direct_dropship_flow_contract.md`
- `docs/tasks/TASK_1070_station_route_aa_assault_door_transition.md`
- `docs/tasks/TASK_586_debrief_return_homebase_handoff.md`
- `docs/tasks/TASK_726_one_screen_multiplayer_station_scenario_drill.md`

## Akzeptanzkriterien

- Der Context-Slot zeigt nacheinander AA, Door, COM und CARGO als aktive
  Route-Aktion, statt einen spaeteren Blocker vorzuziehen.
- Jeder Klick erzeugt nur einen Intent; jede Completion braucht ein eigenes
  GO und erreicht den vorhandenen Runtime-Progress.
- Computer- und Cargo-Hold uebernehmen ihre vorhandenen 18- bzw. 12-Sekunden-
  Anforderungen.
- Cargo-Completion loest den vorhandenen Victory-Result- und Debrief-Pfad aus.
- Der Verifier setzt weder Gates noch MissionResult direkt.

## Betroffene Dateien

- `scripts/tests/task_1071_station_route_full_victory_debrief_trace.gd`
- diese Task-Datei sowie Status, Roadmap und aktueller HTML-Arbeitsbericht
- nur bei nachgewiesenem Fehler die konkrete bestehende Runtime-Bruecke

## Lokale Pruefung

- Neuer TASK-1071-Trace.
- TASK_1070, TASK_1069, TASK_695, TASK_726, TASK_586 und TASK_813.
- `git diff --check`.

## Risiken / offene Punkte

Der Headless-Trace ist ein kompletter Datenfluss- und Bediennachweis, aber
noch kein menschlicher Balance-/Bild-/NPC-Druck-Befund. Sichtbares F6-Playtest
und Host/Client-Synchronisation bleiben die folgenden Abnahmen.

## Ergebnis

Implementiert im Arbeitsstand. TASK_1071 ist 47/47 gruen. Der Spielerpfad
folgt im realen Mission-Control-Slot nacheinander `AA`, `B->GO` fuer Door,
`COM` und `CARGO`. Jede Aktion erzeugt ausschliesslich ihren Intent; GO
startet den vorhandenen Formation-/Movement-/Interaction-Progress. Cargo
komplettiert die vier Scenario-Gates, der Combat-Driver erzeugt `victory / won`
und MetaLayerFlow uebergibt dieses Resultat an Debrief.

Der Verifier beschleunigt nach einem echten GO nur die vom bestehenden
Movement-Controller berechneten Staffelziele und liest den finalen Result-Stand
nach der Mission-Freigabe aus MetaLayer/Debrief. Er setzt weder Gates noch
MissionResult direkt.
