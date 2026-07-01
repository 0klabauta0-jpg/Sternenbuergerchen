# TASK_718 - Station Route Door/GO/Reject Visual Polish

## Ziel / Problem
TASK_717 zeigt, dass der echte Host/Client-Capture und die Route-Line technisch auswertbar sind. Der naechste Reibungspunkt ist sichtbar: Die Door-Authority-Zeile ist zwar kompakt, aber mit Standard-Token doppelt (`DOOR DOOR B->GO`) und der Button sagt im wichtigsten Zustand weiter nur `Breach`.

## Sinnhaftigkeit / Ursache
Der Spieler soll im kleinen Stationslauf ohne Suchen verstehen: Door ist nutzbar, `B` bereitet den Befehl vor, `GO` bestaetigt, Wrong-Team-Reject ist ein Berechtigungsproblem und Open bedeutet Runtime/LOS frei. Das ist Visual-/Text-Polish an bestehenden read-only Feedbackdaten, kein neuer Gameplay-Pfad.

## Umfang
- Door-Authority-Compact-Line entfernt doppelte Standard-Token.
- Ready/Open/Host/Blocked-Zeilen bleiben kurz: `DOOR B->GO`, `DOOR OPEN`, `DOOR HOST OK`, `DOOR BLOCKED ...`.
- `DoorBreachButton` zeigt im Ready-Zustand `B->GO`, damit die GO-Pflicht vor dem Klick lesbar ist.
- Capture-Runbook-Erwartungen werden auf die neue sichtbare Door-Zeile aktualisiert.
- Regressionen fuer alte Door-Authority-Polish-Tasks werden angepasst und ein TASK_718-Verifier belegt den neuen sichtbaren Standard.

## Nicht-Ziele
- Kein neuer Door-Command.
- Kein automatisches Oeffnen ohne GO.
- Keine Aenderung an `SimulationRoot`, Multiplayer-Authority, Runtime-Progress oder TerrainRegistry.
- Kein grosses Command-Panel-Redesign.
- Kein abgeschlossener menschlicher Host/Client-Klickbefund.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_717_station_route_real_click_findings.md`
- `docs/tasks/TASK_702_door_authority_compact_hud_surface.md`
- `docs/tasks/TASK_701_door_authority_feedback_polish.md`

## Akzeptanzkriterien
- `MissionInteractionDoorMultiplayerAuthority.build_ui_feedback()` liefert fuer Standard-DOOR keine Doppelung mehr.
- Ready-Compact-Line ist exakt `DOOR B->GO`.
- Open-Compact-Line ist exakt `DOOR OPEN`.
- Wrong-Team-Reject beginnt mit `DOOR BLOCKED` und behaelt die lesbare Team-Begruendung.
- Der sichtbare Door-Button zeigt bei nutzbarer Door `B->GO`.
- Alle neuen Felder bleiben read-only und setzen keine Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/mission/mission_interaction_door_multiplayer_authority.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_718_station_route_door_go_reject_visual_polish.gd`
- `scripts/tests/task_701_door_authority_feedback_polish.gd`
- `scripts/tests/task_702_door_authority_compact_hud_surface.gd`
- `scripts/tests/task_705_host_client_door_real_click_manual_run_packet.gd`
- `scripts/tools/capture_host_client_two_window_real_run.ps1`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_refresh_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_718_station_route_door_go_reject_visual_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_702_door_authority_compact_hud_surface.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_701_door_authority_feedback_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_717_station_route_real_click_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
Der Text-/Button-Polish macht den vorhandenen Klickpfad lesbarer, ersetzt aber weiter keinen echten menschlichen Host/Client-Fensterentscheid. Nach TASK_718 bleibt ein echter Sichtlauf oder weiterer Layout-Polish sinnvoll.
