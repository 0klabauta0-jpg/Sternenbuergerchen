# TASK_1161 - 1280 Release Recapture and Primary HUD Balance

## Ziel / Problem
Nach TASK_1157 bis TASK_1160 sind Command Matrix, Selected-Fireteam-Member-Karten, Tactical Event Log und Mission Control einzeln fuer das 1280x720-Release lesbarer. Jetzt braucht der Spielerblick wieder einen gemeinsamen Release-Check: keine einzelne Flaeche darf fuer sich gut aussehen, waehrend das gesamte primaere HUD konkurriert, zu klein wirkt oder den First-Contact-Status widerspruechlich priorisiert.

## Sinnhaftigkeit / Ursache
Die letzten Tasks haben bewusst kleine, isolierte Readability-Slices gebaut. Ohne gemeinsamen Snapshot und echten Host/Client-Recapture entsteht sonst wieder Klein-Klein: Panel A wird groesser, Panel B wird enger, und niemand prueft das Bild als Spielerfluss.

## Umfang
- Kombinierten read-only Snapshot fuer die vier primaeren 1280-HUD-Flaechen bereitstellen.
- Bestehende Einzelvertraege von TASK_1157, TASK_1158, TASK_1159 und TASK_1160 zusammenfuehren, nicht ersetzen.
- Release-Capture-Erwartung auf den vorhandenen Host/Client-First-Contact-Harness dokumentieren.
- Nach Umsetzung echten 1280x720-Release-First-Contact-Recapture laufen lassen und Befund in Status/Roadmap festhalten.

## Nicht-Ziele
- Kein Umbau des gesamten HUD-Layouts.
- Keine neuen Commands, Effects, Combat-Regeln oder Multiplayer-State.
- Kein neuer Capture-Harness, solange `capture_release_host_client_entry_playtest.ps1 -FirstContact` reicht.
- Kein rein optisches Gross-Redesign ohne belegten Folgefund.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/TASK_ROADMAP.md`
- `docs/tasks/TASK_1157_command_matrix_1280_readability.md`
- `docs/tasks/TASK_1158_selected_fireteam_member_cards_1280_readability.md`
- `docs/tasks/TASK_1159_tactical_event_log_1280_readability.md`
- `docs/tasks/TASK_1160_mission_control_1280_readability.md`

## Akzeptanzkriterien
- `MissionTacticalSandboxController` liefert `get_primary_hud_1280_balance_snapshot()`.
- Der Snapshot nennt die vier primaeren HUD-Flaechen und ihre bestehenden Style-/Readability-Vertraege.
- Der Snapshot erklaert sich als read-only und meldet keine Gameplay-Wahrheit, Commands oder Effects.
- Release-Evidence verweist auf `scripts/tools/capture_release_host_client_entry_playtest.ps1 -FirstContact` mit 1280x720.
- Ein echter Release-First-Contact-Recapture laeuft nach Umsetzung und schreibt Host-/Client-Fensterbilder.
- Der naechste Folgefund wird aus dem gemeinsamen Bild abgeleitet, nicht aus einer isolierten Panel-Vermutung.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1161_1280_release_recapture_primary_hud_balance.gd`
- `docs/tasks/TASK_1161_1280_release_recapture_primary_hud_balance.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- Neuer Verifier: `scripts/tests/task_1161_1280_release_recapture_primary_hud_balance.gd`
- Regressionen: TASK_1157, TASK_1158, TASK_1159, TASK_1160, TASK_1109, TASK_1110, TASK_222.
- Release: `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_release_host_client_entry_playtest.ps1 -FirstContact -StopRunningReleaseProcesses`

## Risiken / offene Punkte
Der Snapshot beweist Struktur und automatische Mindestwerte, ersetzt aber nicht den menschlichen Blick auf das echte Release-Bild. Wenn der Recapture neue visuelle Konkurrenz zeigt, wird daraus der naechste kleine HUD-/Flow-Task geschnitten.
