# TASK_836 - Release Firefight Command Matrix Visual Polish

## Ziel / Problem
Der erste Firefight ist nach TASK_833 bis TASK_835 im Statusbereich besser lesbar, aber #16 Command Matrix bleibt im sichtbaren Release-Fenster zu gleichfoermig. GO, aktive Fire-Rule und echte Befehle muessen schneller erkennbar sein, ohne die bestehende Befehlsarchitektur zu veraendern.

## Sinnhaftigkeit / Ursache
Der Spieler soll nach dem ersten GO nicht in einem Raster aus optisch gleichwertigen Buttons suchen muessen. Die Matrix soll zeigen:
- welche Buttons echte taktische Befehle sind
- welche Fire-Rule aktuell gilt
- ob GO der naechste Commit-Schritt ist
- welche Slots nur Reserve/Filler sind

## Umfang
- Vorhandene Command-Matrix-Buttons visuell markieren.
- GO kontrastreicher und groesser gewichten.
- Move/Take/Hold/Flank/Target lesbar und mit klaren Tooltips halten.
- Aktive Fire-Rule als genau eine aktive ROE sichtbar machen.
- Reserve-Slots ruhiger markieren.
- Read-only Snapshot fuer MetaLayer und Headless-Verifier bereitstellen.

## Nicht-Ziele
- Kein neues Command-System.
- Kein neues ROE-/Combat-Verhalten.
- Kein Gameplay-State im HUD.
- Kein kompletter Bottom-Dock-Layout-Umbau.
- Kein Ersatz fuer den menschlichen Release-Sichttest.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_835_release_firefight_bottom_dock_density_polish.md`
- `docs/tasks/TASK_832_release_first_go_firefight_deeplink_evidence.md`

## Akzeptanzkriterien
- `get_release_firefight_command_matrix_visual_polish_snapshot()` meldet ein gruenes Gate.
- GO traegt `task_836_release_firefight_command_matrix_visual_v1`, ist prominent und nutzt groessere Schrift.
- Mindestens Move, Take, Hold, Flank und Target sind als Primaerbefehle lesbar.
- Bei eindeutiger Fireteam-Auswahl ist genau eine Fire-Rule aktiv sichtbar.
- Placeholder-/Reserve-Slots sind als ruhig markiert.
- Snapshot und UI-Polish erzeugen keine Commands, FireEvents, DamageEvents oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/task_836_release_firefight_command_matrix_visual_polish.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_836_release_firefight_command_matrix_visual_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_835_release_firefight_bottom_dock_density_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_832_release_first_go_firefight_deeplink_evidence.gd`
- `git diff --check`

## Risiken / offene Punkte
Der Headless-Verifier prueft Struktur, Style-Metadaten und lesbare Button-Daten. Der echte Fensterblick bleibt danach sinnvoll, weil Ultrawide, Skalierung und Kontrast am Spielerbildschirm final beurteilt werden muessen.
