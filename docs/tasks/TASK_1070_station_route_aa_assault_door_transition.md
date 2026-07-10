# TASK_1070 - Station Route AA Assault and Door Transition

## Ziel / Problem

Die Station Route hat einen autoritativen allgemeinen Interaction-Intent fuer
AA, Door, Computer und Cargo. Im sichtbaren CommandGrid ist aber nur die
Door als eigener Bedienpfad vorhanden. Damit ist der erste echte
Erfolgsschritt `AA ausschalten` fuer Spieler nicht direkt ausfuehrbar, obwohl
das Szenario ihn beschreibt.

## Ursache / Sinnhaftigkeit

`create_selected_mission_interaction_use_intent()` plant den richtigen
Waypoint und meldet Runtime-Fortschritt erst nach `GO`. Der vorhandene
`DoorBreachButton` filtert jedoch ausschliesslich auf eine nutzbare Door.
Die AA-Zone bleibt daher eine lesbare Cue statt einer klaren Spieleraktion.

## Umfang

- Den bestehenden Slot `16.8` als kontextuelle Interaction-Aktion verwenden.
- Door-Verhalten, Button-ID, Shortcut `B` und bestehende Door-Authority-Checks
  kompatibel behalten, wenn die naechste nutzbare Interaction eine Door ist.
- Fuer AA, Computer und Cargo den vorhandenen allgemeinen Use-Intent erzeugen;
  der Button darf nur planen und fordert weiterhin ein separates `GO`.
- Einen Station-Route-Trace von sichtbarer AA-Aktion ueber `GO` bis zur
  autoritativen AA-Completion und Door-Cue absichern.

## Nicht-Ziele

- Kein neuer Gate-, Combat-, Movement-, Door- oder Multiplayer-Authority-Pfad.
- Kein Auto-GO, kein automatisches Bewegen zur Interaction und kein UI-State
  fuer Missionsfortschritt.
- Kein Door-Visual-/Collision-Rewrite.

## Relevante Contracts / Dokumente

- `docs/ARCHITECTURE.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_1068_station_route_first_playable_round_trace.md`
- `docs/tasks/TASK_1069_station_route_evac_abort_outcome.md`

## Akzeptanzkriterien

- Die erste nutzbare AA-Interaction wird im Slot `16.8` als klare Aktion
  sichtbar und bleibt ausser Reichweite deaktiviert.
- Der Button erstellt fuer AA nur einen `take`-Intent mit `requires_go`.
- Erst `GO` erreicht den vorhandenen Runtime-Progress-Pfad und setzt den
  Scenario-Step `disable_air_defense = aa_disabled`.
- Nach AA-Completion zeigt der Route-Gate-Snapshot `open_station_door` als
  naechsten Schritt; die Mission ist dabei noch nicht aufgeloest.
- Eine Door im selben Slot bleibt mit dem bestehenden `DoorBreachButton` und
  `B`-Pfad kompatibel.

## Betroffene Dateien

- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1070_station_route_aa_assault_door_transition.gd`
- `docs/dev/mission_interaction_point_contract.md`
- diese Task-Datei sowie Status, Roadmap und aktueller HTML-Bericht

## Lokale Pruefung

- Neuer TASK-1070-Trace.
- TASK_1068, TASK_1069, TASK_695, TASK_726 und TASK_813.
- `git diff --check`.

## Risiken / offene Punkte

Der Slice belegt den ersten Erfolgsuebergang, nicht den gesamten Missionssieg.
Ein echter sichtbarer F6-Lauf mit NPC-Druck bleibt die naechste Playtestarbeit;
die Runtime- und Authority-Grenzen werden hier bewusst nicht verbreitert.

## Ergebnis

Implementiert im Arbeitsstand. TASK_1070 ist 23/23 gruen. Der bestehende
Slot `16.8` folgt jetzt dem datengetriebenen naechsten Objective-Gate: Die
erste Station-Route-Aktion zeigt `AA`, bleibt ausser Reichweite sichtbar und
wird im Shutdown-Kreis als `AA->GO` aktiv. Der Klick erzeugt ausschliesslich
den vorhandenen `take`-Intent. Erst GO durchlaeuft die bestehende
Fireteam-Movement-/Runtime-Progress-Kette, setzt `aa_disabled` und zeigt
anschliessend `open_station_door` als naechste Route.
