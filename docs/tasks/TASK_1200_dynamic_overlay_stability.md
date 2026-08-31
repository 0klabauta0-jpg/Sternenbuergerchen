# TASK_1200 - Dynamic Overlay Stability

## Ziel / Problem

`terrain.dynamic_overlay_usec` soll im echten TASK-1187-Harness in acht von
acht Laeufen einen p99 von hoechstens 1.000 usec erreichen. Der periodische
Dynamic-Order-Pfad darf bei unveraenderten Quellen weder die Signatur neu
zusammensetzen noch Order-Visuals neu aufbauen.

## Ursache / Sinnhaftigkeit

`TerrainMap3DView._refresh_dynamic_order_visuals_if_needed()` prueft derzeit
periodisch eine neu zusammengesetzte Signatur. Dabei werden auch bei nur vier
relevanten Units alle `_unit_nodes` betrachtet. Der unmittelbar davor laufende
Proxy-Sync kennt relevante Positions-, Rotations-, Sicht- und Proxy-Aenderungen
bereits und kann einen rein abgeleiteten Renderindex gezielt invalidieren.

## Umfang und Nicht-Ziele

- Read-only Relevanzindex aus der sortierten Union der ausgewaehlten und der
  Orientation-Fireteam-IDs.
- Dirty-getriebener Dynamic-Order-Refresh mit Diagnosezaehlern fuer
  Signaturaufbau, Unit-Scans, Rebuilds und Skips.
- Unveraenderte Darstellung fuer Order, Fire Sector, LOS, Contacts und FoW.
- Keine Gameplay-, SimulationRoot-, Command-, Snapshot- oder
  Multiplayer-Wahrheit im Renderer.
- Keine Budgetanhebung und keine menschliche TASK-1193-Evidence.

## Relevante Contracts / Dokumente

- `docs/tasks/TASK_1187_tactical_map_frame_budget.md`
- `docs/tasks/TASK_1188_unit_proxy_dirty_sync.md`
- `docs/tasks/TASK_225_fog_of_war_2_5d_visual_overlay_and_contacts.md`
- `docs/tasks/TASK_364_mission_fireteam_orientation_indicators.md`
- `docs/tasks/TASK_371_fire_sector_security_arc_overlay_toggle.md`

## Akzeptanzkriterien

- Eine 28-Unit-Fixture indexiert exakt die vier Units aus ausgewaehlten oder
  Orientation-Fireteams fuer den Dynamic-Signaturpfad.
- Nach dem ersten Aufbau erzeugen 120 stabile Frames weder einen weiteren
  Signaturaufbau noch einen Order-Rebuild.
- Eine relevante Unit-Bewegung erzeugt genau einen geaenderten Zustand und
  einen Rebuild; eine irrelevante Unit-Bewegung erzeugt keinen sichtbaren
  Rebuild.
- Fire-Sector-, LOS-/Contact-, Orientation-, FoW- und Proxy-Vertraege bleiben
  gruen.
- `terrain.dynamic_overlay_usec` liegt in 8/8 SHA-identischen TASK-1187-Laeufen
  bei p99 hoechstens 1.000 usec.

## Betroffene Dateien

- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_1200_dynamic_overlay_stability.gd`
- `scripts/tests/tactical_map_frame_budget_harness.gd` nur falls fuer
  Diagnosezaehler erforderlich
- `docs/tasks/TASK_1200_dynamic_overlay_stability.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung

- TASK-1200-Verifier mit 28 Units und vier relevanten Units.
- TASK-1188, TASK-225 und TASK-1157.
- Ein kalter TASK-1187-Lauf; bei Budgetpass eine serielle 3-kalt/5-warm-Serie.
- `git diff --check`.

## Risiken / offene Punkte

Ein zu enger Index koennte visuelle Eingaben uebersehen. Deshalb bleiben
Selection, Fire-Sector-Modus, LOS-/Contact-Revision, sichtbare Unit-Position
und -Rotation sowie Live-Orientation Teil des Signaturvertrags. Ein manueller
Full-HD-Sichtcheck ist nur Zusatz und ersetzt nicht die spaetere menschliche
TASK-1193-Evidence.
