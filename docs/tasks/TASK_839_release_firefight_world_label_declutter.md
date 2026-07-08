# TASK_839 - Release Firefight World Label Declutter

## Ziel / Problem
Der echte TASK_838-Fensterbefund hat den ersten Firefight lesbarer gemacht, aber die Weltlabels im Kartenbild bleiben dicht: Fire-Status-Texte, Unit-Badges und Feedback-Bubbles konkurrieren mit HUD, Event-Log und Command-Matrix.

Ziel ist ein kleiner visueller Declutter-Schnitt fuer den Release-Firefight: Die Karte soll Schusslinien, Impact, Friendly-Fire-Warnung und kritische Unit-Zustaende zeigen, aber redundante Routine-Texte wie `HIT`, `MISS`, `CONTACT`, `MOVE` oder Welt-Feedback-Bubbles daempfen.

## Sinnhaftigkeit / Ursache
Der Spieler soll im ersten Feuerwechsel sofort lesen koennen, was passiert, ohne dass jede einzelne Runtime-Rueckmeldung als Welttext auf der Karte steht. HUD und Event-Log tragen bereits die Detailerklaerung; die 3D-Karte soll die Lage zeigen.

## Umfang
- Primary3D bekommt einen visuellen `world_label_density_mode`.
- Im `release_firefight_declutter`-Modus werden redundante Fire-Status-Labels und Welt-Feedback-Bubbles unterdrueckt.
- Routine-Unit-Badges wie `CONTACT`, `MOVE`, `ENGAGE`, `DEF`, `READY` werden unterdrueckt; kritische Badges wie `DOWN`, `BLEEDOUT`, `RESPAWN` und HP bleiben sichtbar.
- Render-Snapshot meldet Modus, Style-ID, unterdrueckte Labels und erhaltene Renderpfade.
- MetaLayer und TacticalController exponieren einen read-only TASK_839-Snapshot.

## Nicht-Ziele
- Kein neues Combat-, Contact- oder Fire-Event-Verhalten.
- Kein Entfernen von HUD-/Event-Log-Informationen.
- Kein permanenter Global-Declutter fuer Editor, Homebase, Station-Route oder normale Missionsansichten.
- Kein finaler menschlicher Fenster-Sichtentscheid; ein Recapture bleibt Folgearbeit.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_837_release_first_go_firefight_real_window_review.md`
- `docs/tasks/TASK_838_release_firefight_real_window_findings_polish.md`

## Akzeptanzkriterien
- Release-Firefight setzt `world_label_density_mode = release_firefight_declutter`.
- Redundante Weltlabels werden gezaehlt unterdrueckt.
- Friendly-Fire-Warnung und Fire-VFX bleiben sichtbar.
- Snapshot ist read-only und erzeugt keine Commands, Fire-Events, Damage-Events oder Gameplay-Wahrheit.
- TASK_838-Regression bleibt gruen.

## Betroffene Dateien
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/task_839_release_firefight_world_label_declutter.gd`
- `docs/tasks/TASK_839_release_firefight_world_label_declutter.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_839_release_firefight_world_label_declutter.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_838_release_firefight_real_window_findings_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
Der Task beweist den Rendervertrag und die Release-Firefight-Aktivierung headless. Ob das echte Fensterbild optisch angenehm genug ist, bleibt ein Folge-Recapture.
