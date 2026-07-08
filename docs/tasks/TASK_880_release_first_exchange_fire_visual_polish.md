# TASK_880 - Release First Exchange Fire Visual Polish

## Ziel / Problem
TASK_879 hat im exportierten Runtime-Trace belegt, dass die TASK_876-Statusquelle im finalen First-Exchange-Sample aktiv ist: #17/#18/#19 lesen `CONTACT FIRE`, und keine finale `NO_LOS`-/`CONTACT_PRESSURE`-Ueberschreibung bleibt stehen.

Die verbleibende Reibung liegt damit nicht mehr im Statusquellenpfad, sondern in der Bildlesbarkeit: FireTrace, Impact und Target-Fokus muessen im ersten echten Feuerwechsel staerker lesbar sein, damit CONTACT FIRE nicht nur Text ist.

## Sinnhaftigkeit / Ursache
Der Spieler soll den ersten Feuerwechsel im Fenster sofort verstehen: Wer schiesst, wohin, wo ist der Treffer-/Impact-Punkt und welches Ziel ist relevant. Ein weiterer HUD-Text waere nach TASK_879 der falsche Hebel.

## Umfang
- Separater read-only Visual-Polish-Schalter fuer den belegten Release-First-Exchange.
- Staerkerer FireTrace, groesserer Impact, klarerer Target-Fokus und besser lesbares Fire-Statuslabel in Primary3D.
- Snapshot, der die aktive TASK_876-Statusquelle mit der sichtbaren Fire-VFX-Polish-Schiene verbindet.
- Regression gegen den bestehenden TASK_879-Trace und TASK_850-Focus-Visual-Pfad.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neuen Commands, FireEvents, DamageEvents oder Movement-Events.
- Keine neue UI- oder Gameplay-Wahrheit.
- Keine Multiplayer-Wahrheit und keine Shortcut-Aenderungen.
- Kein Screenshot-Sichtentscheid in diesem Task; der echte Recapture bleibt Folgearbeit.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_879_release_first_exchange_exported_status_source_trace.md`
- `docs/tasks/TASK_876_release_first_exchange_visible_status_source_reconciliation.md`
- `docs/tasks/TASK_850_release_fire_exchange_focused_visual_polish.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Akzeptanzkriterien
- Der TacticalController sendet den First-Exchange-Fire-Visual-Polish nur, wenn die TASK_876-First-Exchange-Statusquelle aktiv ist.
- Primary3D meldet `release_first_exchange_fire_visual_polish_active = true` mit stabilem TASK_880-Style.
- FireTrace, Impact und Target-Fokus sind im TASK_880-Modus groesser als im bestehenden TASK_850-Focus-Modus.
- Das sichtbare Fire-Statuslabel bleibt im TASK_880-Modus aktiv und groesser als der Basiswert.
- Der Snapshot bleibt read-only und erzeugt keine Commands, FireEvents, DamageEvents, Movement oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/task_880_release_first_exchange_fire_visual_polish.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_880_release_first_exchange_fire_visual_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_879_release_first_exchange_exported_status_source_trace.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_850_release_fire_exchange_focused_visual_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_880 verbessert und belegt die Visual-Parameter headless. Der naechste sinnvolle Schritt ist ein frischer exportierter Window-Handle-Recapture, der prueft, ob der menschliche Fensterblick FireTrace, Impact und Target-Fokus wirklich sofort versteht.
