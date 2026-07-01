# TASK_785 - Station Reentry Firefight Command Surface Visible Findings Refresh

## Ziel / Problem
TASK_784 erzeugt ein sichtbares Playtest-Paket fuer die polierte TASK_783-Command-Surface. Es fehlt noch die read-only Auswertung der echten sichtbaren Haken und Issue-Flags fuer genau diese polierte Surface.

## Sinnhaftigkeit / Ursache
Ohne Findings-Refresh bleibt unklar, ob Interaction-Line, Primary-Lane, Quick-Action-Rail, Guard-Line, No-Auto-Command und Existing-Buttons im Fenster wirklich lesbar sind oder ob wir nur das Paket bereitgestellt haben.

## Umfang
- Neuer read-only Service `StationReentryFirefightCommandSurfaceVisibleFindingsRefresh`.
- Auswertung von TASK_784-Paket plus optionalem HTML-/Workbench-Export.
- Status fuer:
  - fehlendes/ungueltiges TASK_784-Paket
  - offenen sichtbaren Review
  - unvollstaendige Pflichtchecks
  - konkrete Polish-/Host-Client-/Performance-Follow-ups
  - sauberen naechsten Station-Firefight-Schritt
- Manifestpfad `tmp/station_reentry_firefight_command_surface_visible_findings_refresh.json`.
- Status, Roadmap, Contract und HTML-Handbuch auf TASK_785 aktualisieren.

## Nicht-Ziele
- Kein automatischer Sichtentscheid und kein Screenshot-Parsing.
- Kein neues Command-UI-System.
- Kein Ausfuehren von HOLD/FLANK/SUP/HOLD FIRE.
- Keine Navigation, Commands, FireEvents, DamageEvents oder Gameplay-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_784_station_reentry_firefight_command_surface_playtest_packet_refresh.md`
- `docs/tasks/TASK_783_station_reentry_firefight_command_surface_polish.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- Der Snapshot nutzt Schema `sternenbuergerchen.station_reentry_firefight_command_surface_visible_findings_refresh.v1`.
- Fehlendes, falsches oder nicht bereites TASK_784-Paket blockiert und routet zur TASK_784-Reparatur.
- Offene sichtbare Reviews bleiben offen und werden nicht still als erledigt markiert.
- Pflichtchecks enthalten F6-Fenster, polierte Surface, Interaction-Line, Primary-Lane, Quick-Action-Rail, Guard-Line, No-Auto-Command, Existing-Buttons, Selected-Fireteam, Host/Client, Screenshot und Workbench-JSON.
- Issue-Flags routen gezielt zu TASK_783, TASK_547, TASK_770 oder TASK_769.
- Ein sauberer Review routet zu TASK_786 - Station Reentry Firefight Host Client Polished Surface Check.
- Der HTML-Bericht exportiert TASK_785-Manifestpfad, Haken und Issue-Flags.

## Betroffene Dateien
- `scripts/mission/station_reentry_firefight_command_surface_visible_findings_refresh.gd`
- `scripts/tests/task_785_station_reentry_firefight_command_surface_visible_findings_refresh.gd`
- `docs/tasks/TASK_785_station_reentry_firefight_command_surface_visible_findings_refresh.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_785_station_reentry_firefight_command_surface_visible_findings_refresh.gd`
- Regression: TASK_784, TASK_783, TASK_782
- Reentry-Block TASK_769 bis TASK_785
- `git diff --check`

## Risiken / offene Punkte
TASK_785 wertet die Haken und Workbench-Notizen aus, sieht aber weiterhin nicht selbst. Ohne echten Fensterlauf bleibt `needs_visible_polished_command_surface_review` korrekt offen. Naechster sinnvoller Schritt ist TASK_786 fuer den Host/Client-Abgleich der polierten Surface.
