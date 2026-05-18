# TASK_480 - Mission UI Hotpath Feedback Guard

## Ziel / Problem

Die Review zu Dropship-Feedback, Event-Log-Kopplung und Fireteam-Mini-Card-Lead soll als kleiner UI-Hotpath-Pass umgesetzt werden.

Aktuell koennen parallele Dropship-Bewegungsframes zu haeufig den vollen UI-/Planning-Feedback-Pfad ausloesen. Ausserdem haengen mehrere Runtime-HUD-Refreshes hinter dem optionalen Event-Log-Panel-Guard. Die Mini-Card bekommt den konfigurierten Lead korrekt, ueberschreibt diesen Text aber anschliessend mit Live-Status.

## Sinnhaftigkeit / Ursache

- Runtime-Bewegungsfeedback darf keine Planning-/HUD-Vollrebuilds pro Bewegungsframe erzwingen.
- Ein optionales Panel wie das Event-Log darf keine fachfremden HUD-Bereiche stale halten.
- Der Fireteam-Lead ist stabile Identitaetsinformation und darf nicht durch Statuszeilen verschwinden.

## Umfang

- Parallel-Dropship-Bewegungsframes aktualisieren Welt-Overlay und Dropship-Panel leichtgewichtig, ohne Planning-Emit/Voll-`_update_ui()` pro Frame.
- Event-Log-Refresh und Runtime-HUD-Surfaces werden in getrennte Funktionen geschnitten.
- Fireteam-Mini-Cards behalten den Lead-Summary-Text und zeigen darunter weiter den Live-Status.
- Veraltete Loadout-Doku wird fuer `rail_gun` korrigiert.

## Nicht-Ziele

- Kein grosser Mission-UI-Refactor.
- Kein Fireteam-Unit-Cache fuer alle verbleibenden SceneTree-Helfer.
- Kein neues Dropship-Datenmodell.

## Relevante Contracts / Dokumente

- `AGENTS.md`
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/loadout_playability_rules.md`

## Akzeptanzkriterien

- `task_399_dropship_flow_contract_performance_pass.gd` ist gruen.
- `bugfix_mission_fireteam_fob_payload_and_bubbles.gd` ist gruen.
- Event-Log-Panel darf fehlen, ohne World Overlays, Dynamic Buttons, Selected Cards oder Mini Cards zu blockieren.
- Mini-Card-MemberLabel enthaelt weiter den konfigurierten Lead und den Live-Status.
- Loadout-Doku nennt `rail_gun` als selektierbare kanonische Weapon-ID.

## Betroffene Dateien

- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `docs/dev/loadout_playability_rules.md`
- `docs/tasks/TASK_480_mission_ui_hotpath_feedback_guard.md`
- `docs/TASK_ROADMAP.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung

- `godot_console.exe --headless --path . --script scripts/tests/task_399_dropship_flow_contract_performance_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/bugfix_mission_fireteam_fob_payload_and_bubbles.gd`
- relevante Regressionen: TASK_479 und `git diff --check`

## Risiken / offene Punkte

- Die verbleibenden Mission-UI-SceneTree-Helper sollten spaeter in einem eigenen Cache-/Registry-Slice bereinigt werden.
- Dropship-Panel-Refresh ist jetzt fuer parallele Bewegungsframes leichter, aber noch kein differenzielles Card-Patch-System.
