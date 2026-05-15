# TASK_428 - Fireteam Behavior Control List

## Ziel / Problem

Die Fireteam-Verhalten sollen nach dem stabilisierten `Move`-Pfad kontrolliert neu geordnet werden. Fuer `Engage`, `Take` und `Defend` braucht es eine pruefbare Liste, welche Absicht der Befehl hat, wie sich `C`, `N` und `A` unterscheiden und welche Abhaengigkeiten spaeter Code- oder Balancing-Aenderungen steuern duerfen.

## Sinnhaftigkeit / Ursache

Die sichtbaren Mission-Fireteam-Befehle sind inzwischen an den Mission-Tactical-Pfad gebunden. Bevor weitere Behaviors umgesetzt werden, soll die gewuenschte Semantik explizit und reviewbar sein:

- `Take` bedeutet Besitz/Kontrolle eines Punkts oder einer Area.
- `Engage` bedeutet Angriff/Kampf gegen Ziel, Kontakt oder Zielraum ohne Besitzpflicht.
- `Defend` bedeutet von einem Punkt oder einer Area nach aussen sichern und halten.
- `Flank` wird fuer diese Runde bewusst ausgeklammert.
- `OVW`/Overwatch soll im sichtbaren Basisverhalten nicht weiter als eigener Status gefuehrt werden; Security wird als `DEF`-Status beschrieben.

## Umfang

- HTML-Reviewliste fuer `Engage`, `Take`, `Defend`.
- C/N/A-Wirkungsmatrix mit Tempo, Sicht, Haltung, Bonus/Malus und Risiko.
- Tile-vs-Area-Unterscheidung pro Befehl.
- Buddy-Team- und Abstandsprinzipien fuer Vierer-Fireteams.
- Entscheidungs- und offene Reviewfragen fuer die naechsten Implementierungs-Tasks.

## Nicht-Ziele

- Keine Gameplay-Code-Aenderung.
- Kein Balancing-Vertrag mit finalen Zahlen.
- Kein neuer Pathfinding-, Combat- oder Objective-Algorithmus.
- Kein `Flank`-Verhalten.
- Kein Entfernen interner Legacy-/Recovery-Pfade.

## Relevante Contracts / Dokumente

- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/fireteam_runtime_execution_path_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_421_move_stance_posture_speed_sight.md`
- `docs/tasks/TASK_423_normal_move_parallel_spacing.md`
- `docs/tasks/TASK_427_fireteam_decision_feedback_aim_pose.md`

## Akzeptanzkriterien

- Es gibt eine HTML-Datei unter `docs/reports/`, die als Review-Grundlage im Browser lesbar ist.
- Die Datei trennt klar `Take`, `Engage` und `Defend`.
- Die Datei dokumentiert `C`, `N` und `A` fuer alle drei Befehle mit Tempo, Sicht, Haltung, Bonus/Malus und Risiko.
- Die Datei benennt Tile-vs-Area-Unterschiede.
- Die Datei haelt fest, dass `Flank` vorerst nicht Teil dieses Passes ist.
- Die Datei beschreibt `DEF` statt `OVW` als sichtbaren Security-/Defense-Status.
- Buddy-Team-Bildung und Abstandsprinzipien sind als pruefbare Regeln enthalten.

## Betroffene Dateien

- `docs/tasks/TASK_428_fireteam_behavior_control_list.md`
- `docs/reports/fireteam_behavior_control_checklist.html`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung

- `git diff --check`

## Risiken / offene Punkte

- Die Prozentwerte sind bewusst Review-Werte und noch keine finalen Runtime-Konstanten.
- `Take` braucht spaeter eine klare Control-Definition: Mindestanzahl Units, Contest-Regel, Objective-/Area-Fortschritt.
- `Engage` braucht spaeter eine klare Ende-Bedingung: Kontakt vernichtet, Kontakt verloren, Suppression erreicht oder Commander-GO.
- `Defend` braucht spaeter eine klare Default-Facing-Regel: Marschrichtung, ausgewaehlte Richtung oder `DEF 360`.
