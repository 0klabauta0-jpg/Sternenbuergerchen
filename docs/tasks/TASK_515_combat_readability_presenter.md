# TASK_515 - Combat Readability Presenter

## Ziel / Problem
Der `MissionCombatLoopDriver` enthaelt nach TASK_514 weiterhin Anzeige- und Readability-Code fuer Legacy-Combat-Overlays: Statuslabel, Eventlabel, Winnerlabel und Kontaktlinie. Das ist keine Gameplay-Wahrheit, haengt aber im autoritativen Tick-Orchestrator.

## Sinnhaftigkeit / Ursache
Die Review-Grenze aus `combat_loop_authority_contract.md` nennt Readability-Labels, Kontaktlinie und Eventtexte als naechsten Extraktionspunkt. Diese UI-/Visual-Aufgaben sollen nicht im Combat-Driver wachsen, damit Multiplayer-Authority, Snapshot-Vertrag und sichtbare Darstellung getrennt bleiben.

## Umfang
- `CombatReadabilityPresenter` unter `scripts/tactical/` anlegen.
- Legacy-Readability-Nodes, Overlay-Sichtbarkeit, Eventlabel-, Winnerlabel-, Statuslabel-Formatierung und Kontaktlinie an den Presenter delegieren.
- Driver behaelt Gameplay-State, Unit-Kontaktstatus, Remote-Event-Broadcast und Snapshot-Wahrheit.
- Fokussierten Verifier fuer Presenter, Driver-Anbindung und Doku anlegen.

## Nicht-Ziele
- Keine neue HUD-Optik.
- Keine Aenderung an Combat-, Damage-, LOS- oder Movement-Logik.
- Keine Snapshot-Key-Umbenennung.
- Kein Umbau des taktischen Event-Logs.
- Keine Verschiebung von Unit-`set_contact_state` in den Presenter.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/dev/runtime_script_layout_contract.md`
- `docs/dev/combat_loop_authority_contract.md`
- `docs/tasks/TASK_495_mission_combat_driver_boundary_review.md`
- `docs/tasks/TASK_514_enemy_behavior_orchestrator.md`

## Akzeptanzkriterien
- Legacy-Readability-Node-Erzeugung und Label-Formatierung liegen in `CombatReadabilityPresenter`.
- Der Presenter enqueued keine Commands/Effects und referenziert keine `SimulationRoot`-Authority.
- Preview-Mode entfernt/verbirgt Legacy-Readability-Nodes weiter.
- Kontaktlinie bleibt rein visuell; Unit-Kontaktstatus bleibt beim Driver.
- Bestehende Gameflow-, Combat- und Overlay-Regressionen bleiben gruen.

## Betroffene Dateien
- `scripts/tactical/combat_readability_presenter.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tests/task_515_combat_readability_presenter.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_515_combat_readability_presenter.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_192_mission_map_npc_behavior_playability_smoke.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_500_gameflow_spine_hardening.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der grosse Combat-Driver bleibt weiterhin Legacy-Bridge fuer Combat-State, Unit-Signale, Remote-Events und Tick-Reihenfolge.
- Spaetere UI-Politur sollte den modernen Tactical-Event-Log-/PrimaryView-Pfad staerken, statt die Legacy-Overlays wieder auszubauen.
