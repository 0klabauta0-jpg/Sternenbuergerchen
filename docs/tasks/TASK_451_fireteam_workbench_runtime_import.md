# TASK_451 - Fireteam Workbench Runtime Import

## Ziel / Problem

Die in der Formation-Workbench gespeicherten C/N/A-Werte, Formationen und Zielerfassungswerte sollen nicht nur HTML-/JSON-Stand sein, sondern im Mission-Tactical-Runtime-Pfad sichtbar wirken.

## Sinnhaftigkeit / Ursache

Die Workbench-Exporte aus `_05` sind aktuell der Playtest-Baseline-Stand. Ohne Runtime-Uebernahme prueft das Spiel weiterhin aeltere Konstanten, waehrend die Workbench schon andere Werte zeigt.

## Umfang

- Globale C/N/A-Stance-Grundwerte aus `_05` in `FireteamMovementController` uebernehmen.
- Gespeicherte Formationsslots fuer Move C/N/A, Engage C/N/A und Take A als Runtime-Baseline nutzen.
- `contact_initiative_seconds`, `aim_readiness_percent` und `team_target_support_percent` in UnitCommands transportieren.
- Team-Zielhilfe im Combat-Fire-Resolver als ersten Hit-Chance-Hook anwenden.
- Kontakt-Initiative im Mission-Combat-Loop als Detektionszeit-Modifikator anwenden.

## Nicht-Ziele

- Keine finale Skill-Skalierung.
- Keine Defend-Formation, solange sie nicht in der Workbench gespeichert ist.
- Keine Sequenzlogik fuer raupenartig/ueberschlagend.
- Keine neue KI- oder Behavior-Tree-Schicht.

## Relevante Contracts / Dokumente

- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/tasks/TASK_446_fireteam_workbench_spacing_runtime_pass.md`
- `docs/tasks/TASK_447_fireteam_contact_initiative_rules.md`
- `docs/tasks/TASK_450_fireteam_stance_command_preset_workbench.md`
- `docs/reports/fireteam_formation_tuning_2026-05-17T08-46-56-746Z_05.json`

## Akzeptanzkriterien

- Runtime-Modifikatoren zeigen C/N/A-Werte aus `_05`: C 35/100/75/75/-0.3/+5, N 65/80/45/30/+0.3/0, A 100/50/20/35/0/-3.
- UnitCommand-Dictionaries enthalten Kontakt-Initiative, Aim-Bereitschaft und Team-Zielhilfe.
- Combat-Fire-Resolver addiert Team-Zielhilfe auf die erste Hit-Chance-Baseline.
- Detection-Delay liest Kontakt-Initiative aus dem aktuellen UnitCommand.
- Movement-Snapshot zeigt den genutzten Workbench-Preset-Key und die Quelle der Formation.
- Tests pruefen Runtime-Import, Command-Felder und Combat-Hook.

## Betroffene Dateien

- `scripts/tactical/fireteam_movement_controller.gd`
- `scripts/tactical/combat_fire_decision_resolver.gd`
- `scripts/npc/unit_command.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tests/task_451_fireteam_workbench_runtime_import.gd`
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/TASK_ROADMAP.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung

- `godot_console.exe --headless --path . --script scripts/tests/task_451_fireteam_workbench_runtime_import.gd`
- Relevante TASK_429/TASK_446-Regressionen
- `git diff --check`

## Risiken / offene Punkte

- Die Formationen bilden nur gespeicherte `_05`-Kombinationen ab. Fehlende Take C/N und Defend C/N/A bleiben Preset-/Fallback-Logik.
- Kontakt-Initiative ist ein erster Modifikator auf bestehende Detection-Ticks; finale Sekundenbalance braucht Playtest.
