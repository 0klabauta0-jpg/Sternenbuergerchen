# TASK_164 - UI Theme and Component Library

## Ziel
Homebase, FOB und Mission bekommen eine gemeinsame, kleine UI-Komponenten- und Theme-Basis. Kenney-UI-Assets werden kuratiert eingebunden, ohne die bestehenden Screens fachlich umzubauen.

## Status: IMPLEMENTIERT

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Lies `docs/tasks/TASK_076_meta_ui_kenney_grau.md`
- Lies `docs/tasks/TASK_081_meta_ui_harmonisierung_fob_homebase_loadout.md`
- Lies `docs/reviews/strategic_review_ui_assets_multiplayer_2026_05_03.md`
- Pruefe den Git-Status

## Kontext
- Meta-Screens bauen viele Panels, Karten, Buttons und Statuszeilen direkt im jeweiligen Skript.
- Lokale Assets enthalten `kenney_ui-pack`, `kenney_ui-pack-space-expansion`, `kenney_ranks-pack`, `kenney_input-prompts_1.4.1` und Cursor-Assets.
- Die UI soll taktisch, scanbar und konsistent wirken.

## Umfang
1. Theme-Ressourcen und Design-Tokens definieren:
   - Farben
   - Panel-/Card-Stile
   - Statusfarben
   - kleine Icon-Groessen
   - Progress-/Badge-Stile
2. Kleine Komponenten einfuehren:
   - StatusBadge
   - TacticalCard
   - UnitRosterRow
   - CommandButton
   - ProgressLine
   - Tooltip/Icon-Helfer
3. Erste Anwendung nur an einem begrenzten Screen-Slice, z.B. Selected Fireteam oder FOB-Dropship-Card.
4. Kenney-Assets nur kuratiert importieren.

## Nicht-Ziele
- Kein kompletter UI-Redesign-Pass.
- Keine neue Gameplay-Funktion.
- Kein Massenimport aller UI-Assets.
- Keine dekorativen Hero-Screens.

## Architekturregeln
- UI-Komponenten zeigen Daten, aber halten keine Gameplay-Wahrheit.
- Komponenten bekommen Daten/Snapshots von bestehenden Runtime-Pfaden.
- Keine doppelten State-Maschinen in Control-Skripten.

## Akzeptanzkriterien
- Gemeinsame Theme-/Komponentenbasis existiert.
- Ein sichtbarer Screen-Slice nutzt die neue Basis.
- Alte Funktion bleibt erhalten.
- Importierte Assets sind dokumentiert und klein gehalten.
- UI bleibt auf Desktop lesbar und scanbar.

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_164_ui_theme_component_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_096_recovery_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- [ ] Manuelle Sichtpruefung Homebase/FOB/Mission (im Headless-Durchlauf nicht ausgefuehrt)

## Ergebnis
- `scripts/ui/tactical_ui_theme.gd` definiert gemeinsame Farben, Statusfarben, Icon-Groessen und Style-Helfer fuer Cards, Badges, Buttons und Progress Bars.
- Neue kleine Anzeige-Komponenten liegen unter `scripts/ui/components/`: `StatusBadge`, `TacticalCard`, `UnitRosterRow`, `CommandButton`, `ProgressLine` und `UITooltipIconHelper`.
- Der Mission-Slice `FireteamStatusPanel` nutzt die neue Basis fuer Badge, Suppression-Progress und Return-to-Plan-Button, behaelt aber die bestehende Statuszusammenfassung und den vorhandenen Callback.
- Kenney-Assets wurden nicht neu importiert; der Icon-Helfer verweist nur auf kuratierte vorhandene Repo-Pfade.

## Risiken
- Zu viel Politur kann Gameplay-Tasks blockieren. Deshalb erst Theme und ein Slice.
- Kenney-Assets sind CC0, lokale Kopien sollten trotzdem mit Quelle/Lizenz notiert werden.
