# TASK_219 - UI HUD Meta Comic Bubble Performance Pass

## Ziel
Homebase, FOB, Mission-HUD, Settings, Rank-Badges und Comic-Bubbles sollen auf UI-Performance, Control-Anzahl, Textkosten, Theme-Reuse, Pooling, Toggle-Gates und Fixed-Window-Verhalten geprueft werden.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_164 - UI Theme and Component Library
- TASK_177 bis TASK_181 - Drop Light Fixed UI Layout und Audit
- TASK_190 - Weapon Visual Loadout Expansion and Scale
- TASK_207 - NPC Rank Skill Badge Derivation
- TASK_209 bis TASK_214 - Comic Bubble Feedback and NPC Thoughts
- TASK_215 - Performance Deep Pass Baseline and Research

## Kontext
Die UI wird dichter: feste Fenster, Loadout, NPC-Karten, Rank-Badges, Hauptmenue, Settings und Bubble-Feedback. Godot-UI kann sehr gut funktionieren, aber viele Controls, haeufige Label-Rebuilds, Shadow/Outline-Stile oder staendige Reparent-/Resize-Arbeit koennen stottern.

## Umfang
1. Screen-Matrix:
   - Homebase.
   - FOB.
   - Mission-HUD.
   - Main Menu/Settings, sobald TASK_199 aktiv ist.
   - Bubble-heavy Mission-Frame.
2. Control-/Theme-Audit:
   - Control count pro Screen.
   - Label/RichTextLabel count.
   - Icon/TextureRect count.
   - Theme-/StyleBox-Reuse statt pro Frame neue Styles.
   - Keine variable Hauptfenstergroesse im Drop-Light-Vertrag.
3. Update-Kosten:
   - Keine kompletten UI-Rebuilds pro Tick, wenn nur Werte wechseln.
   - Badge-/Loadout-/Roster-Listen nur bei Datenwechsel neu bauen.
   - Bubble-Pooling statt dauerndem Instanzieren/Free, wenn Messung es rechtfertigt.
4. Bubbles:
   - Off/Minimal/Normal muss Renderdaten wirklich begrenzen.
   - Max gleichzeitige Bubbles und Cooldowns wirken messbar.
   - Thought-Hold erzeugt keine dauerhaften Nodes.
5. Text und Fonts:
   - Kurze Labels.
   - Keine teuren Outline/Shadow-Spielereien ohne Sichtnutzen.
   - Text passt in feste Panels ohne Layout-Thrash.
6. Verifier:
   - Control-/Bubble-/Label-Zaehler und Update-Zaehler.
   - Off-Modus reduziert Bubble-Kosten auf null sichtbare Bubble-Nodes.

## Nicht-Ziele
- Kein neues UI-Design.
- Kein Wechsel zu komplett selbstgezeichnetem UI.
- Keine neuen Gameplay-Infos.
- Keine Lockerung der festen Fenster.

## Akzeptanzkriterien
- [x] Homebase, FOB und Mission-HUD haben UI-Zaehler und Update-Budgets.
- [x] Comic-Bubbles respektieren Off/Minimal/Normal auch performance-seitig.
- [x] Bubble-Hold erzeugt keine dauerhafte Node-Flut.
- [x] Theme-/StyleBox-Reuse ist dokumentiert und getestet.
- [x] UI-Updates laufen datengetrieben statt pauschal pro Frame.
- [x] Ein TASK_219-Verifier prueft UI-/Bubble-Budgets und Fixed-Window-Stabilitaet.

## Erwartete Dateien
- `scripts/meta/homebase_screen.gd`
- `scripts/meta/fob_screen.gd`
- `scripts/ui/tactical_ui_theme.gd`
- `scripts/ui/comic_bubble_runtime_gate.gd`
- `scripts/tests/ui_hud_comic_bubble_performance_harness.gd`
- `docs/performance/ui_hud_comic_bubble_profile_report.md`
- `scripts/tests/task_219_ui_hud_meta_comic_bubble_performance_pass.gd`
- `docs/tasks/TASK_219_ui_hud_meta_comic_bubble_performance_pass.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_219_ui_hud_meta_comic_bubble_performance_pass.gd` (48/0)
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_181_drop_light_fixed_window_audit_verifier.gd` (43/0)
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_214_comic_bubble_feedback_playability_smoke.gd` (34/0)
- [ ] Manueller Profiler-Lauf auf Homebase/FOB/Mission-HUD.
- [x] `git diff --check`

## Umsetzung
- `TacticalUITheme.build_flat_stylebox()` nutzt einen Parameter-Cache fuer wiederverwendete `StyleBoxFlat`-Ressourcen.
- `ComicBubbleRuntimeGate.build_filter_performance_snapshot()` liefert eine read-only Probe fuer Input, Emit, Rejection, Cooldown-Key-Restore und Filterzeit.
- `ui_hud_comic_bubble_performance_harness.gd` zaehlt UI-Nodes/Controls/Labels/Buttons/TextureRects fuer Homebase, FOB, Mission-HUD und Main Menu.
- Bubble-Renderproben pruefen Off, Minimal, Normal, Thought Hidden und Thought Hold gegen das 2.5D-Render-Snapshot.
- `ui_hud_comic_bubble_profile_report.md` dokumentiert Screen-Matrix, StyleBox-Reuse, Bubble-Budgets und Fixed-Window-Risiko.

## Risiken
- Zu starkes Pooling kann Code komplizierter machen als die Kosten rechtfertigen. Erst zaehlen.
- UI-Optimierung darf die festen Fenster nicht wieder flexibel machen.

## Naechster Schritt
Nach TASK_219 prueft TASK_220 Assets, VRAM und Shader-/Pipeline-Stutter.
