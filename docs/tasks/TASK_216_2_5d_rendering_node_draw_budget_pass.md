# TASK_216 - 2.5D Rendering Node and Draw Budget Pass

## Ziel
Der 2.5D-Mission-Renderer soll intensiv auf Nodes, Draw-/Materialkosten, Fallbacks, Visibility, Transparenz, Schatten/Lichter, Mesh-/Material-Wiederverwendung und Pipeline-Stutter geprueft werden.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_159 - 2.5D Mission Load/Offset Fix
- TASK_160 - Tactical Mission Playability Smoke
- TASK_170 - Performance and Warning Budget Gate
- TASK_185 - Hill Visuals and Edge Lines Patch
- TASK_205 - Weapon Fire VFX Muzzle Flash Particles
- TASK_215 - Performance Deep Pass Baseline and Research

## Kontext
`TerrainMap3DView` ist inzwischen der primaere Mission-View-Pfad. Er rendert Terrain, Hoehenkanten, Units, Dropship, Objective, Contacts, Wegpunkte, Area Orders und bald Muzzle-/Bubble-Visuals. Genau dort koennen viele kleine Nodes, transparente Overlays, Materialvarianten und Pipeline-Kompilierungen unschoen werden.

## Umfang
1. Render-Snapshot vertiefen:
   - Node-/Mesh-/Materialzaehler pro Kategorie.
   - GLB-Instanzen, Marker, Labels, Edges, Overlays, VFX.
   - Missing-/Fallback-Zaehler aus TASK_170 beibehalten.
2. Visual-Profiler-Check:
   - Feste 1920x1080-Viewportgroesse.
   - Frame-Spikes bei Kameradrehung, Zoom, LZ, Dropship, Combat und Objective.
   - CPU/GPU-Renderzeiten getrennt dokumentieren.
3. Draw-/Material-Kandidaten:
   - Identische Terrain-/Edge-/Marker-Objekte auf automatische Instancing-Faehigkeit pruefen.
   - MultiMesh nur fuer wirklich viele identische statische oder einfache Instanzen bewerten.
   - Material-/Shader-Varianten reduzieren, wo es sichtbar nichts kostet.
4. Visibility und Culling:
   - Visibility ranges fuer entfernte VFX/Labels/Overlays pruefen.
   - Occlusion/Frustum-Annahmen dokumentieren.
   - Keine sichtbaren Marker ausserhalb relevanter Kartenbereiche.
5. Transparenz:
   - Transparente Overlays, Bubble-Planes, Labels und Particles nach Fillrate-/Sortierkosten beurteilen.
   - Alpha-Blending klein halten; wo moeglich alpha hash/scissor oder opaque nutzen.
6. Pipeline-Stutter:
   - Erstmalige Instanzierung von Muzzle, Bubbles, Dropship, Units, Edge-Modellen als Stutter-Kandidaten pruefen.
   - Warmup-/Hidden-instance-Strategie nur dokumentiert und testbar einfuehren.

## Nicht-Ziele
- Kein visueller Redesign-Pass.
- Kein Renderer-Wechsel.
- Kein Gameplay-Refactor.
- Kein blinder MultiMesh-Umbau ohne Messwert.

## Akzeptanzkriterien
- [x] 2.5D-Render-Snapshot enthaelt Kategoriezaehler fuer Nodes/Meshes/Materials/Overlays.
- [x] Visual-Profiler-Ergebnisse fuer feste Viewportgroesse sind dokumentiert.
- [x] Top-Renderkosten sind nach Kategorie priorisiert.
- [x] MultiMesh-/Instancing-Kandidaten sind bewertet, nicht blind umgesetzt.
- [x] Transparenz-/VFX-/Label-Kosten haben klare Budgets.
- [x] Pipeline-Compilation-Zaehler werden im Render-Stress erfasst.
- [x] Ein TASK_216-Verifier prueft Renderbudgets und dass keine Fallbacks reinkommen.

## Erwartete Dateien
- `scripts/terrain/terrain_map_3d_view.gd`
- `docs/performance/2_5d_rendering_profile_report.md`
- `scripts/tests/task_216_2_5d_rendering_node_draw_budget_pass.gd`
- `docs/tasks/TASK_216_2_5d_rendering_node_draw_budget_pass.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_216_2_5d_rendering_node_draw_budget_pass.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_170_performance_warning_gate_verifier.gd`
- [ ] Manueller Visual-Profiler-Lauf in Godot bei 1920x1080.
- [x] `git diff --check`

## Umsetzung
- `TerrainMap3DView.get_render_snapshot()` enthaelt jetzt `render_budget_by_category`, `render_budget_totals`, `render_transparency_budget`, `draw_budget_snapshot` und `pipeline_compilation_snapshot`.
- `docs/performance/2_5d_rendering_profile_report.md` dokumentiert Kategorie-Prioritaeten, MultiMesh-/Instancing-Kandidaten, Transparenzbudget, Pipeline-Stutter-Kandidaten und den manuellen Visual-Profiler-Ablauf.
- `task_216_2_5d_rendering_node_draw_budget_pass.gd` prueft Live Mission und Render Spike strukturell gegen diese Budgets und die bestehenden Fallback-Grenzen.

## Risiken
- MultiMesh kann Culling verschlechtern, wenn zu viel in eine grosse Gruppe gepackt wird.
- Transparente Labels/Bubbles koennen mehr kosten als die eigentlichen Meshes.

## Naechster Schritt
Nach TASK_216 prueft TASK_217 Navigation, Terrain und LOS.
