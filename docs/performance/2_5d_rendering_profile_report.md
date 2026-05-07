# TASK_216 2.5D Rendering Profile Report

Stand: 2026-05-06

## Ziel
Dieser Bericht bewertet den aktuellen `TerrainMap3DView` als primaeren 2.5D-Mission-Renderer. Der Task vertieft Messbarkeit und Budgets; er ist kein visueller Redesign- oder Renderer-Wechsel.

## Snapshot-Erweiterung
`TerrainMap3DView.get_render_snapshot()` enthaelt jetzt:

- `render_budget_by_category`: Node-, Mesh-, Material-, Sprite3D-, Label3D- und MultiMesh-Zaehler pro Root-Kategorie.
- `render_budget_totals`: Summen ueber Map, Marker, Patrol, Selection, Unit, Order, Contact, Drop und Status.
- `render_transparency_budget`: transparente Materialien, Labels, Sprite3D, Surface-Tints, Weapon-VFX und Comic-Bubbles.
- `draw_budget_snapshot`: Render-Monitor-Werte fuer Objects, Primitives, Draw Calls und VRAM-/Buffer-Memory, soweit Godot sie bereitstellt.
- `pipeline_compilation_snapshot`: Pipeline-Compilation-Zaehler fuer Canvas, Mesh, Surface, Draw und Specialization, soweit verfuegbar.

## Kategorien
| Kategorie | Root | Beobachtung |
|---|---|---|
| Map | `MapRoot3D` | Terrain, Hoehenkanten, Surface-Tints, statische Assets |
| Marker | `MarkerRoot3D` | LZ, Auswahl, Tile-/Feldmarker |
| Patrol | `PatrolRoot3D` | Patrouillenlinien |
| Selection | `SelectionRoot3D` | Grid-/Selection-Visuals |
| Unit | `UnitRoot3D` | Unit-Proxies, Animated Characters, Sockets, Attachments |
| Order | `OrderRoot3D` | Waypoints, Area Orders, Movement, VFX, Bubbles |
| Contact | `ContactRoot3D` | Kontaktmarker |
| Drop | `DropRoot3D` | Dropship/LZ-Visuals |
| Status | `StatusRoot3D` | Objective, Mission Result |

## Top-Kosten Nach Kategorie
Aktuelle Prioritaet fuer Folge-Tasks:

1. Map: viele Terrain-/Asset-MeshInstances und Materialvarianten.
2. Unit: Animated Characters, Skeletons, Sockets, Helme/Blaster.
3. Order/Overlay: Labels, VFX, Bubbles, transparente Karten.
4. Drop/Status/Contact: kleiner, aber Pipeline-Stutter-Kandidaten beim ersten Anzeigen.

## MultiMesh-/Instancing-Bewertung
- Terrain-Ground- und wiederholte Edge-/Marker-Geometrien sind Kandidaten fuer spaetere Instancing-/MultiMesh-Pruefung.
- MultiMesh wird nicht blind eingefuehrt, weil zu grosse Gruppen Culling verschlechtern koennen.
- Gute Kandidaten: viele identische, statische, einfache Meshes mit gleicher Materialnutzung.
- Schlechte Kandidaten: Units mit Skeleton/Animation, Labels/Bubbles, pro-Objekt stark unterschiedliche Materialien oder seltene Einzelobjekte.

## Transparenz-Budget
- Labels, Sprite3D-Fallbacks, Bubble-Planes, Muzzle-Flash-Texturen und Surface-Tints zaehlen als transparente/alpha-lastige Overlays.
- Budgetpolitik: klein halten, zeitlich begrenzen, bei sichtbarem Fillrate-/Sortierproblem gezielt in TASK_216+ nachmessen.
- Bubbles und Muzzle-VFX bleiben kurzlebig und visual-only.

## Pipeline-Stutter
Kandidaten fuer erstmalige Pipeline-Kompilation:

- Animated Unit Models mit Skin/Material.
- Dropship-GLB.
- Weapon Fire VFX Texturen und Linien.
- Comic Bubble Texturen.
- Hoehenkanten-/Surface-Tint-Materialien.

Warmup wird nur als spaeterer, testbarer Kandidat dokumentiert. Dieser Task fuehrt keine Hidden-Instance-Warmup-Schicht ein.

## Visual Profiler
Manueller Lauf bleibt offen:

1. 1920 x 1080 Viewport fixieren.
2. Live Mission 2.5D oeffnen.
3. Kameradrehung, Zoom, LZ, Dropship, Objective, Contact, Weapon-VFX und Bubbles nacheinander ausloesen.
4. Visual Profiler fuer Render-CPU-Zeit, Draw-/Primitive-Spikes und Pipeline-Spikes beobachten.
5. Ergebnisse in diesen Bericht oder einen Folge-Task uebertragen.

## Headless Gate
`scripts/tests/task_216_2_5d_rendering_node_draw_budget_pass.gd` prueft:

- Kategoriezaehler fuer Live Mission und Render Spike.
- Node-/Mesh-/Materialsummen sind nicht leer.
- Transparenzbudget erkennt VFX und Bubbles im Overlay-Stress.
- Draw- und Pipeline-Monitor-Snapshots haben stabile Keys.
- TASK_170-Fallback-Zaehler bleiben sauber.

## Risiken
- Transparente Overlays koennen mehr kosten als die eigentlichen Meshes, wenn sie gross oder dauerhaft sind.
- MultiMesh kann Culling verschlechtern.
- Headless-Monitorwerte sind Struktur- und Budgetdaten; der echte Visual-Profiler-Lauf bleibt fuer GPU-/Viewport-Wahrheit wichtig.
