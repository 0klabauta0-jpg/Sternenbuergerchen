# TASK_1068 - Station Route First Playable Round Trace

## Ziel / Problem

Die Station Route ist aus Homebase waehlerbar und ihre Teilpfade sind
abgesichert. Fuer den Spieler fehlt jedoch ein einzelner Nachweis, der Start,
Dropship, Deboarding, sichtbares AA-Ziel, ersten Kontakt und Move-Preview vor
dem getrennten `GO` als zusammenhaengenden Spielmoment prueft.

## Ursache / Sinnhaftigkeit

Die vorhandenen Verifier pruefen diese Kanten jeweils isoliert. Bevor neue
Missionsmechanik oder weitere HUD-Politur entsteht, muss klar sein, ob der
echte Station-Route-Start die bereits vorhandenen Systeme zusammen lesbar
macht oder ob ein konkreter Handoff bricht.

## Umfang

- Realen Homebase-Katalogstart fuer Station Route verwenden.
- Bestehende Craft-Ankunft, LZ, Deboarding, ContactTracker und Move-Preview
  ausfuehren.
- Vor `GO` AA-Route-Cue, Contact, Ghost, Pfad und Risiko gemeinsam pruefen.
- Den Test als read-only Player-Flow-Trace dokumentieren.

## Nicht-Ziele

- Kein neues Combat-, Objective-, Retreat-, Debriefing- oder Multiplayer-
  System.
- Kein automatisches `GO`, keine kuenstliche Missionsergebnis-Mutation.
- Kein Ersetzen der vorhandenen Einzelregressionen.

## Relevante Contracts / Dokumente

- `docs/ARCHITECTURE.md`
- `docs/dev/homebase_direct_dropship_flow_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- TASK_1063, TASK_1059, TASK_1060, TASK_726, TASK_813

## Akzeptanzkriterien

- Station Route startet ueber den echten Homebase-Katalog mit ihrer Scenario-
  Datei.
- Nach Deboarding ist ein Ground-Fireteam aktiv und AA bleibt der erste Route-
  Schritt.
- Ein LOS-Kontakt und eine Move-Preview sind vor `GO` sichtbar.
- Ghost, Pfad, Risiko und Contact bleiben read-only; `GO` wurde nicht
  ausgefuehrt.

## Betroffene Dateien

- `scripts/tests/task_1068_station_route_first_playable_round_trace.gd`
- diese Task-Datei sowie Status, Roadmap und der aktuelle HTML-Bericht.

## Lokale Pruefung

- Neuer TASK-1068-Trace.
- TASK_1063, TASK_1059, TASK_1060, TASK_726, TASK_813.
- `git diff --check`.

## Risiken / offene Punkte

Der Headless-Trace beweist Datenfluss und Entscheidungsklarheit, nicht das
endgueltige Sichtgefuehl im Fenster. Falls der Trace gruen ist, folgt als
naechster Spiel-Task die sichtbare Vorstoss-gegen-Abbruch-Entscheidung statt
weiterer technischer Glue-Arbeit.

## Ergebnis

Implementiert im Arbeitsstand. Der Trace ist 16/16 gruen: Er waehlt Station
Route im realen Homebase-Katalog, loest den vorhandenen Dropship-Handoff aus,
setzt die LZ, deboardet ein Ground-Fireteam und erreicht den AA-Startschritt.
Ein bewusst vor `GO` gesetzter Move zeigt gleichzeitig LOS-Kontakt, Route-Cue,
Ghost, Pfad und Risiko. Die sichtbaren Route- und Contact-Snapshots bleiben
read-only; die Fireteam-Bewegung ist noch nicht in Ausfuehrung.

Die Anschlussregressionen sind ebenfalls gruen: TASK_1063 14/14, TASK_1059
10/10, TASK_1060 14/14, TASK_726 30/30 und TASK_813 43/43. TASK_1059 und
TASK_813 geben beim Headless-Exit weiter eine ObjectDB-Leak-Warnung aus. Ihre
Assertions und Prozess-Exit-Codes bleiben gruen; Cleanup-Diagnose ist ein
separater QA-Punkt und kein verdeckter Spielflow-Erfolg.
