# TASK_780 - Station Reentry Firefight Interaction Polish

## Ziel / Problem
Nach TASK_779 ist der Firefight sichtbar auswertbar. Der Spieler braucht jetzt nach dem ersten Feuerwechsel eine kurze, klare Antwort auf die Frage: Was mache ich als Commander als Naechstes?

## Sinnhaftigkeit / Ursache
Ein Feuerwechsel ist spielerisch nur dann angenehm, wenn Ergebnis, Risiko und naechste Griffe zusammen lesbar sind. Bisher sind FireEvent, Tension, Metriken und Visual-Findings getrennt pruefbar; TASK_780 verbindet sie als read-only Follow-up-Surface.

## Umfang
- `StationReentryFirefightInteractionPolish` als Mission-Contract/Presenter.
- Input:
  - TASK_779 Visual-Findings-Snapshot
  - TASK_777 Firefight-Tension-Snapshot
  - bestehender Combat-HUD-Next-Decision-Text aus TASK_777/TASK_546
- Output:
  - kompakte Firefight-Folgezeile
  - primaerer Folgegriff
  - Quick-Actions fuer bestehende Oberflaechen: Hold/Defend, Flank, Suppress, Move/Retreat/Hold Fire je nach Lage
  - Gates fuer Lesbarkeit, Zeilenlaenge und read-only-Grenzen

## Nicht-Ziele
- Keine neue Command-Ausfuehrung.
- Kein neuer Combat-Resolver.
- Keine Damage-, FireEvent-, Navigation- oder KI-Mutation.
- Keine echte Suppression-/Ammo-/Morale-Wirkung.
- Keine neue UI-Architektur; der Snapshot beschreibt die Oberflaeche und kann spaeter sichtbar angeschlossen werden.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_779_station_reentry_firefight_visual_findings.md`
- `docs/tasks/TASK_777_station_reentry_firefight_tension_feel_pass.md`
- `docs/tasks/TASK_546_mission_combat_feedback_hud_density_polish.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- Der Snapshot blockiert, wenn TASK_779-Findings oder TASK_777-Tension nicht bereit sind.
- Bei gruener Quelle entsteht eine kompakte `interaction_line` unter 96 Zeichen.
- Mindestens drei Quick-Actions sind sichtbar.
- Ein primaerer Folgegriff ist hervorgehoben und aus Tension/Metriken ableitbar.
- Friendly-Fire-Risiko fuegt `HOLD FIRE` als lesbaren Follow-up hinzu.
- Casualty-Pressure priorisiert `RETREAT`.
- Der Snapshot nutzt bestehende Command-Surfaces und erzeugt keine Commands.

## Betroffene Dateien
- `scripts/mission/station_reentry_firefight_interaction_polish.gd`
- `scripts/tests/task_780_station_reentry_firefight_interaction_polish.gd`
- `docs/tasks/TASK_780_station_reentry_firefight_interaction_polish.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_780_station_reentry_firefight_interaction_polish.gd`
- Regression: TASK_779, TASK_778, TASK_777
- `git diff --check`

## Risiken / offene Punkte
TASK_780 erzeugt die Contract-/Presenter-Schicht. Der echte sichtbare Command-Surface-Recapture bleibt Folgearbeit, damit keine UI-Architektur im Vorbeigehen umgebaut wird.
