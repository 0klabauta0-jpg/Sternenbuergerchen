# Code Review Commit Report - 2026-05-10

## Scope
Review vor Commit/Push fuer den aktuellen `task/better-ui`-Stand. Geprueft wurden vor allem Mission-HUD, FOB-/Dropship-/Fireteam-Staging, taktische Kommunikation, 360-Sicherung, Terrain-/Hill-Editor und die neuen Task-/Verifier-Anker.

## Review-Ergebnis
Keine offenen P0/P1-Blocker im automatisiert geprueften Scope.

Direkt im Review behoben:
- `TASK_316` hatte einen Verifier, aber kein Task-Dokument und keinen Roadmap-/Status-Anker.
- `SEC 360` und `OVW` konnten im Map-Visualizer textlich uebereinander liegen.
- `task_275` pruefte noch den alten 3-Spalten-Vertrag, obwohl `#16` inzwischen die gewuenschte 5x4-Command-Matrix ist.
- `CommanderIntent` serialisierte Default-`security_mode`/`cover_priority` wie explizite Spielerwahl; dadurch war `take -> sector` als FTL-Fallback verdeckt.

## Wichtige Rest-Risiken
- Vollstaendiger manueller Playtest wurde nicht behauptet und nicht ersetzt. FullHD-Klick-/Drag-/Sichtgefuehl, mehrminuetiges NPC-Verhalten und kompletter Meta->FOB->Mission-Lauf brauchen weiter echte Sichtpruefung.
- `task_316_fob_fireteam_staging_migration.gd` besteht fachlich, meldet beim Headless-Exit aber Godot RID/ObjectDB-Leaks. Das sieht nach Test-/Engine-Cleanup-Risiko aus, nicht nach Assertion-Fehler.
- `maps/new_map.json` ist jetzt deutlich kleiner (64x64 -> 16x16). Das passt zur aktuellen Hill-/Terrain-Arbeit, sollte aber bei der naechsten manuellen Kartenrunde bewusst bestaetigt werden.
- `scripts/tests/mission_tactical_sandbox_controller.gd` bleibt ein sehr grosses Integrationsskript. Die Aenderungen sind verifiziert, aber langfristig ist das weiter ein Architektur-Risiko.

## Lokale Pruefung
Gruen gelaufen:
- `git diff --check`
- `task_180_mission_drop_light_fixed_hud_layout_verifier.gd`
- `task_214_comic_bubble_feedback_playability_smoke.gd`
- `task_270_commander_to_fireteam_leader_delegation_contract.gd`
- `task_271_tactical_command_modes_roe_fire_rules.gd`
- `task_274_tactical_communication_feedback_layer.gd`
- `task_275_command_button_hierarchy_arrangement_overhaul.gd`
- `task_281_tactical_command_multiplayer_authority_snapshot.gd`
- `task_285_tactical_decision_branch_integrity_review.gd`
- `task_289_final_sneaky_code_review_patch_queue.gd`
- `task_291` bis `task_298` Editor-/Terrain-Verifier
- `task_299` bis `task_314` Meta-/FOB-/Dropship-Verifier
- `task_315_mission_grid_tile_selection_command_gate.gd`
- `task_316_fob_fireteam_staging_migration.gd`
- `hill_mechanics_16x16_testmap_verifier.gd`
- `editor_height_edge_surface_anchor_verifier.gd`

Zusatz: `task_258`, `task_259` und `task_267` liefen erneut ohne Fehlercode.

## Nicht vollstaendig geprueft
- Kein vollstaendiger manueller Playtest.
- Kein Zwei-Instanzen-Multiplayer/LAN-Smoke.
- Kein finaler Screenshot-Abgleich aller markierten UI-Stellen nach FullHD-Art-Direction.
