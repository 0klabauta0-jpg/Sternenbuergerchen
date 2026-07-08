# TASK_892 - Release First Exchange Fire Direction And Impact Clarity Polish

## Ziel / Problem
TASK_891 hat den TASK_890-Fensterblick als Fortschritt bewertet: CONTACT FIRE ist sichtbar, aber Schussrichtung, Impact und Zielbezug lesen sich noch nicht sofort als eine klare Aktion.

## Sinnhaftigkeit / Ursache
Der First-Exchange-Statuspfad ist inzwischen belegt und synchron. Weitere CONTACT-FIRE-Texte wuerden das eigentliche Problem nicht loesen. Der naechste sinnvolle Schritt ist ein enger Weltbild-Polish: Quelle -> Schussrichtung -> Ziel -> Treffer muss visuell schneller verstanden werden.

## Umfang
- Bestehenden TASK_889-HUD-Density-/Fire-Visual-Pfad erweitern, nicht ersetzen.
- Primary3D bekommt fuer den bestaetigten CONTACT-FIRE-Moment einen eigenen TASK_892-Schalter.
- FireTrace, Impact, Target-Fokus und eine Ziel-End-Markierung/Direction-Anchor werden im Render-Snapshot messbar staerker.
- Controller liefert einen read-only TASK_892-Snapshot fuer Headless-Verifier.
- Status, Roadmap, Contract und Zwischenbericht aktualisieren.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neue FireEvent-, Damage-, Contact-, Movement-, Command-, UI- oder Multiplayer-Wahrheit.
- Kein neuer Capture in diesem Task.
- Kein erneutes CONTACT-FIRE-Text-Stapeln.
- Kein Editor-/Mapbuilder-Polish.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_891_release_first_exchange_hud_density_visual_findings.md`
- `docs/tasks/TASK_889_release_first_exchange_hud_density_and_fire_visual_polish.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_09.html`

## Akzeptanzkriterien
- `TerrainMap3DView.get_render_snapshot()` meldet den TASK_892-Style nur, wenn der bestehende TASK_889-Pfad aktiv ist.
- FireTrace, Impact und Target-Fokus sind staerker als TASK_889.
- Jedes Weapon-Fire-VFX-Entry meldet im TASK_892-Pfad sichtbare Direction-/Impact-Relationship-Metadaten.
- `get_release_first_exchange_fire_direction_impact_clarity_polish_snapshot()` meldet Gate `pass`, wenn TASK_889 aktiv ist und die TASK_892-Visual-Metadaten im Render-Snapshot ankommen.
- Der Verifier prueft read-only-Grenzen: keine Commands, FireEvents, DamageEvents, Movement- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `docs/tasks/TASK_892_release_first_exchange_fire_direction_impact_clarity_polish.md`
- `scripts/mission/release_first_exchange_fire_direction_impact_clarity_polish.gd`
- `scripts/tests/task_892_release_first_exchange_fire_direction_impact_clarity_polish.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_09.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_892_release_first_exchange_fire_direction_impact_clarity_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_891_release_first_exchange_hud_density_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_889_release_first_exchange_hud_density_and_fire_visual_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_892 ist ein Headless-/Runtime-Visual-Polish. Ein echter neuer Fensterblick bleibt Folgearbeit, damit wir nicht behaupten, dass die Optik im Spielerfenster final schoen ist, bevor sie erneut gecaptured wurde.

## Naechster Schritt
TASK_893 - Release First Exchange Fire Direction Impact Real Window Recapture.
