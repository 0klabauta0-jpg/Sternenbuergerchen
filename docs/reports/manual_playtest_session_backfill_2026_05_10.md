# Manual Playtest Session Backfill - 2026-05-10

## Zweck
Diese Notiz fasst den manuellen Playtest-Arbeitsblock der letzten Stunden zusammen und ordnet die Aenderungen nachtraeglich als Tasks ein. Der Block entstand aus direktem Playtest-Feedback und nicht aus einer vorab geschnittenen Roadmap-Phase.

## Task-Zuordnung
- `TASK_317`: Mission-Fireteams uebernehmen FOB-Payload, Leader-Portrait und Bubble-Layout.
- `TASK_318`: Mission Debrief Background und Teamliste im Hauptmenue.
- `TASK_319`: FOB-Zuweisung fuer zweites Dropship und Shipcard-Scale.
- `TASK_320`: Per-Craft Dropship-Karten, Dispatch, Drop und Rueckflug.
- `TASK_321`: Station-Floor als Boden, Layering, Undo und Floor-Top-Hoehe.
- `TASK_322`: Map-Editor Asset-Import, Rotation, Kontextmenue und Preview/Help-Politur.
- `TASK_323`: Mission Command Visuals, tile-aligned Fire Sector und Dropship-Auswahl.
- `TASK_324`: Team-Editor und Character-Overlay-Usability.
- `TASK_325`: Diese Dokumentations-/Roadmap-Nachpflege.

## Fachliche Leitplanken
- UI zeigt und delegiert; Gameplay-Wahrheit bleibt nicht in UI-Skripten.
- Dropship- und Fireteam-Zustand wird pro Craft/Fireteam nachvollziehbar gemacht, aber nicht als zweite SimulationRoot-Wahrheit dupliziert.
- Map-Editor-Assets bleiben projektlokal und muessen per `res://...` referenziert werden.
- Dicke Bodenmodelle duerfen visuell eine andere Modelloberkante haben als die Gameplay-`surface_y`, solange der Snapshot diese Trennung dokumentiert.
- Team-/Character-Editor ist ein Authoring-/Roster-Werkzeug, noch kein finales Progressions- oder Multiplayer-Team-System.

## Noch manuell zu pruefen
- FullHD-Sichtcheck fuer FOB/Homebase/Mission-Dropship-Karten.
- Bubble-Spacing und Fireteam-Minikarten im Live-Missionsfenster.
- Editor-Preview-Qualitaet fuer alle neu importierten Assetgruppen.
- Team-Editor-Bedienfluss mit bestehenden und neu generierten Teams.
- Fire-Sector/Facing-Lesbarkeit in einer laengeren Mission mit mehreren Fireteams.

## Git-Hinweis
Dieser Backfill dokumentiert den aktuellen Branch-Arbeitsstand. Er ist nicht als Commit- oder Push-Bestaetigung zu lesen.
