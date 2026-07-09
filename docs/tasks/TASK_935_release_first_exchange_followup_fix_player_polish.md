# TASK_935 - Release First Exchange Followup Fix Player Polish

## Ziel / Problem
TASK_934 zeigt: CONTACT FIRE ist technisch und in #17/#18/#19 sichtbar, aber der Spielerblick ist noch nicht akzeptiert. Die Follow-up-Fix-Fire-Lane liest noch nicht sicher als erste Weltbewegung; FIRE/CONTACT-Text, Zielhalo und Cluster konkurrieren weiter.

## Sinnhaftigkeit / Ursache
Ein Playability-Smoke waere ohne akzeptierten Sichtbefund verfrueht. TASK_935 setzt deshalb nur den belegten Restbefund aus TASK_934 als kleinen Presentation-Polish um: Lane/Core minimal klarer, Text/Halo/Grid/Weltlinien leiser, Source-/Target-Anker tragender.

## Umfang
- TASK_934-Findings als Quelle pruefen.
- TASK_932-Follow-up-Fix als Baseline behalten.
- Primary3D-Renderstil `task_935_release_first_exchange_followup_fix_player_polish_v1` bereitstellen.
- Fire-Lane/Core als erste Weltbewegung staerken.
- FIRE/CONTACT-Weltlabel, Target-Halo, Grid und Weltlinien weiter zuruecknehmen.
- Source-/Target-Anker leicht staerken, aber unter der Scheiben-Grenze halten.
- Controller-Snapshot und Render-Snapshot read-only absichern.

## Nicht-Ziele
- Kein Smoke-Run.
- Kein neuer Capture.
- Kein Combat-, Damage-, Contact-, Movement- oder Command-Rewrite.
- Keine neue HUD-, UI-, Multiplayer- oder Gameplay-Wahrheit.
- Keine Shortcut-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_934_release_first_exchange_followup_fix_visual_findings.md`
- `docs/tasks/TASK_932_release_first_exchange_final_readability_followup_fix.md`
- `docs/reports/spielstand_zwischenbericht_task932_ausblick_2026_07_09.html`

## Akzeptanzkriterien
- `ReleaseFirstExchangeFollowupFixPlayerPolish.build_snapshot()` akzeptiert nur TASK_934-Findings plus passierenden TASK_932-Follow-up-Fix.
- `TerrainMap3DView` meldet und rendert `release_first_exchange_followup_fix_player_polish_active` mit stabiler Style-ID.
- Lane/Core sind staerker als TASK_932, waehrend Label, Target-Halo, Grid und Weltlinien weiter zuruecktreten.
- Source-/Target-Anker tragen Richtung, bleiben aber unter der Disc-Grenze.
- Snapshot bleibt read-only und meldet keine Commands, FireEvents, DamageEvents, Movement-, Shortcut- oder Multiplayer-Mutationen.

## Betroffene Dateien
- `docs/tasks/TASK_935_release_first_exchange_followup_fix_player_polish.md`
- `scripts/mission/release_first_exchange_followup_fix_player_polish.gd`
- `scripts/tests/task_935_release_first_exchange_followup_fix_player_polish.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_task932_ausblick_2026_07_09.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_935_release_first_exchange_followup_fix_player_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_934_release_first_exchange_followup_fix_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_932_release_first_exchange_final_readability_followup_fix.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_935 ist wieder nur ein enger Presentation-Fix. Er ersetzt keinen echten Fensterbeweis. Nach dem Fix braucht es einen frischen Recapture, bevor ein Playability-Smoke wirklich fair ist.

## Naechster Schritt
TASK_936 - Release First Exchange Followup Fix Player Polish Recapture.
