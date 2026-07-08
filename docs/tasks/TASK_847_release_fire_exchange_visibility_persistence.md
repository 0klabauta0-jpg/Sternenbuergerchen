# TASK_847 - Release Fire Exchange Visibility Persistence

## Ziel / Problem
TASK_846 hat den echten Fensterbefund festgehalten: TASK_844 beweist headless einen ersten Fire-Exchange, aber im sichtbaren Release-Fenster fallen #17 Selected Fireteam, #18 Mission Control und #19 Event Log zu schnell wieder auf `CONTACT PRESSURE` / `NO FIRE` / LOS-Korrektur zurueck.

Ziel dieses Tasks ist eine kurze read-only Sichtbarkeits-Persistenz fuer vorhandene Fire-Exchange-Evidence. Der Spieler soll den ersten Feuerwechsel im Fenster noch lesen koennen, auch wenn der aktuelle Combat-Readout kurz danach wieder einen blockierten oder wartenden Zustand meldet.

## Sinnhaftigkeit / Ursache
Der Combat-Pfad ist nicht das Hauptproblem. Der echte Schusswechsel wird erzeugt, aber die sichtbaren HUD-Surfaces priorisieren spaetere Diagnostics staerker als den gerade erzeugten FireEvent. Fuer den Spieler wirkt der erste Feuerwechsel dadurch widerspruechlich: technisch passiert Feuer, sichtbar steht aber wieder `NO FIRE`.

## Umfang
- Bestehende FireEvent-/Combat-HUD-Evidence kurz als Anzeige-Snapshot persistieren.
- #17 Selected Fireteam und #18 Mission Control duerfen waehrend des Persistenzfensters `NEXT HIT LESEN / DEFEND | WHY FEUER` und `Kampf FIRE ...` zeigen.
- #19 Event Log darf einen read-only Fallback `CONTACT FIRE: Feuerwechsel lesen` anzeigen.
- Neuer TacticalController-Snapshot `get_release_fire_exchange_visibility_persistence_snapshot()`.
- MetaLayer-Wrapper fuer den bestehenden Release-/QA-Pfad.
- Verifier unter `scripts/tests/`.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neuen FireEvents.
- Keine neuen DamageEvents.
- Keine Command-, Movement-, Contact- oder Multiplayer-Mutation.
- Kein automatischer Pixelentscheid und kein Ersatz fuer den naechsten echten Recapture.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_846_release_first_exchange_visual_findings.md`
- `docs/tasks/TASK_845_release_first_exchange_real_window_recapture.md`
- `docs/tasks/TASK_844_release_first_exchange_tension_tuning.md`
- `docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html`

## Akzeptanzkriterien
- Snapshot nennt Schema `sternenbuergerchen.release_fire_exchange_visibility_persistence.v1`, `task_id = TASK_847` und Style-ID `task_847_release_fire_exchange_visibility_persistence_v1`.
- Persistenz ist nur aktiv, wenn vorher echte FireEvent-/`fired`-Evidence aus den vorhandenen Snapshots sichtbar war.
- Persistierte Anzeige setzt `read_only = true`, `ui_sets_gameplay_truth = false`, `creates_command = false`, `creates_fire_event = false`, `creates_damage_event = false` und `sets_multiplayer_truth = false`.
- `combat_hud_density` kann waehrend des Fensters `FIRE` statt spaeterem `NO FIRE` anzeigen, markiert dies aber als `visibility_persistence_active`.
- Release-Decision-Line zeigt waehrend des Fensters `NEXT HIT LESEN / DEFEND | WHY FEUER`.
- Event-Log-Fallback zeigt waehrend des Fensters `CONTACT FIRE: Feuerwechsel lesen`.
- Bestehende TASK_844-/TASK_845-/TASK_846-Pfade bleiben gruen.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/task_847_release_fire_exchange_visibility_persistence.gd`
- `docs/tasks/TASK_847_release_fire_exchange_visibility_persistence.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_847_release_fire_exchange_visibility_persistence.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_844_release_first_exchange_tension_tuning.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_846_release_first_exchange_visual_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_847 macht den vorhandenen ersten Feuerwechsel lesbarer, ersetzt aber nicht den anschliessenden echten Release-Fenster-Recapture. Wenn der naechste Screenshot weiterhin zu wenig FireTrace/Impact zeigt, braucht es danach einen engeren Visual-VFX-Polish statt noch mehr Text.
