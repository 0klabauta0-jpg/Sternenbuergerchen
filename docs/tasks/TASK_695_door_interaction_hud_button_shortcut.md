# TASK_695 - Door Interaction HUD Button/Shortcut

## Ziel / Problem
TASK_694 hat den sicheren Door-Use/Breach-Hook gebaut, aber der Spieler kann ihn noch nicht sichtbar im Missions-HUD bedienen. Die Door bleibt damit technisch nutzbar, aber im Spielgefuehl zu implizit.

## Sinnhaftigkeit / Ursache
Der aktuelle Weg ist ein Controller-/Verifier-Pfad. Fuer einen angenehmen Missionsflow braucht der Spieler einen sichtbaren Button und einen schnellen Tastaturpfad, die keine neue Gameplay-Wahrheit setzen, sondern nur den bestehenden Hook ausloesen.

## Umfang
- Dynamischer Command-Matrix-Button `DoorBreachButton` im bestehenden Grid.
- Shortcut `B` fuer Door Breach.
- Button wird nur aktiv, wenn der bestehende Mission-Interaction-Feedback-Snapshot eine nutzbare Door fuer die aktuelle Auswahl meldet.
- Button/Shortcut rufen `create_selected_mission_interaction_door_use_breach_command_hook()` auf.
- Command-Control-/Hierarchy-Snapshots exportieren den Button fuer UI- und Regressionstests.

## Nicht-Ziele
- Keine Door-Animation.
- Kein Sofort-Oeffnen ohne GO-/Runtime-Pfad.
- Kein neues Door-State-System.
- Kein grosses UI-Layout-Redesign.
- Kein Multiplayer-Authority-Rewrite.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_694_door_use_breach_command_hook.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Akzeptanzkriterien
- Der Button existiert im CommandGrid, ist sichtbar und hat eine lesbare Beschriftung/Tooltip.
- Der Button ist bei einer nutzbaren Door aktiv und ohne nutzbare Door blockiert.
- Button und Shortcut loesen denselben Door-Use/Breach-Hook aus.
- Der Hook bleibt `requires_go = true`; UI setzt keine Door- oder Terrain-Wahrheit.
- Command-Feedback exportiert Buttonzustand und Hook-Ergebnis.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/ui/mission_command_hierarchy_contract.gd`
- `scripts/tests/task_695_door_interaction_hud_button_shortcut.gd`
- `docs/tasks/TASK_695_door_interaction_hud_button_shortcut.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_695_door_interaction_hud_button_shortcut.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_694_door_use_breach_command_hook.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die Bedienung ist sichtbar, aber noch nicht animiert.
- Der echte FullHD-Sichtlauf bleibt separat offen.
