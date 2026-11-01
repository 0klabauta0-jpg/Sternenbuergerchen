# Navigation und Hex: gemessene Ausgangsbasis

Stand: 01.11.2026. Der Nutzer hat anschließend ausdrücklich den Wechsel auf
Hexfelder beauftragt. Diese Messung hält den unveränderten bisherigen
`square8`-Pfad als Vergleichsbasis fest; sie ist keine Hex-Implementierung.

## Problem und Ursache

Gleich lange Strecken auf der sichtbaren quadratischen 3D-Bodenfläche werden
im bisherigen Bewegungspfad je nach Richtung unterschiedlich schnell gegangen.
Der eigene A*-Pfadfinder bewertet acht Nachbarn mit diagonalen Kosten `sqrt(2)`
([terrain_pathfinder.gd](../../scripts/terrain/terrain_pathfinder.gd):12,162).
Die Bewegung integriert jedoch Strecken in projizierten Iso-`Vector2`-Koordinaten
([simulation_root.gd](../../scripts/core/simulation_root.gd):1897).
Bei Halbbreite 64 und Halbhöhe 32 ist diese Projektion nicht längentreu
([terrain_registry.gd](../../scripts/terrain/terrain_registry.gd):341).
Der 3D-Renderer bildet Grid-X/Y dagegen auf gleich große Bodenachsen ab.

## Tatsächliche Messung

Die synthetische 8×8-Karte enthält ausschließlich flachen, freien Ground.
Der echte Pathfinder liefert die Wegpunkte; die echte private Methode
`SimulationRoot._apply_move_command_with_terrain` bewegt isolierte `Node2D`
mit festem Delta `1/60`. Automatischer Tick, Spacing, lokale Vermeidung und
Requeue sind ausgeschaltet. Es wird keine produktive Mission gestartet.

| Strecke ab Grid (3,3) | Ziel (5,5) | Ziel (5,1) |
|---|---:|---:|
| A*-Pfadkosten | 2,828427 | 2,828427 |
| Länge im vorhandenen 3D-Bodenmaß | 2,828427 | 2,828427 |
| Länge im projizierten Bewegungsraum | 128 | 256 |
| Integrationsschritte | 96 | 193 |
| Simulierte Zeit | 1,600000 s | 3,216667 s |

Beobachtetes Zeitverhältnis: **2,010417**. Der große Unterschied folgt aus
den projizierten Streckenlängen. Der zusätzliche diskrete Ankunftstick gegenüber
idealen 3,2 s ist in der Messung enthalten; Rundung wurde nicht separat untersucht.
Dies sind simulierte Bewegungszeiten, keine FPS- oder Wallclock-Messung.

## Hex-Entscheidung und Migrationsgrenze

Hex bietet sechs gleich weit entfernte Nachbarzentren und eine einheitliche
Nachbarschaft ohne orthogonal/diagonal-Sonderfall. Die nötigen Koordinaten-,
Distanz-, Rundungs- und Linienregeln beschreibt [Red Blob Games](https://www.redblobgames.com/grids/hexagons/).
Diese Regelmäßigkeit unterstützt klare taktische Entscheidungen; faire
Laufzeiten benötigen zusätzlich eine passende physische Bewegungsmetrik.
Ein Hex-Overlay allein würde den gemessenen Metrikwechsel nicht beseitigen.

Sichtbares natürliches Gelände bleibt mit einem unsichtbaren Navigationsgraphen
vereinbar. Godot unterscheidet [Grid-/Graph- und Mesh-Navigation](https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_introduction_3d.html).
[AStarGrid2D](https://docs.godotengine.org/en/stable/classes/class_astargrid2d.html)
bietet konfigurierbare Diagonalregeln; das Projekt verwendet derzeit eigene
A*/HPA-Skripte, nicht diese Klasse.

Der beauftragte Hex-Slice muss Topologie und Version ausdrücklich kennzeichnen.
Betroffen sind Grid-/Weltumrechnung, A*/HPA, Bewegung, Picking und Visuals;
außerdem müssen LOS-Linien, Wand-/Rampenkanten, Deckung/FoW, Editor, Karten-
Saveformat sowie Netzwerkpositionen abgestimmt werden. Bestehende Karten
dürfen nicht still als Hex umgedeutet werden. Dieser Bericht behauptet keine
bereits erfolgte vollständige Migration.

## Dateien, Prüfung und Grenzen

- Probe: [frontier_directional_movement_probe.gd](../../scripts/tests/frontier_directional_movement_probe.gd).
- Rohdaten mit Source-SHA-256, Fixtureparametern und Einzelchecks:
  [directional_movement_probe.json](../../output/grafik_20261101/directional_movement_probe.json).
- Aufruf: `godot_console.exe --headless --path . --script scripts/tests/frontier_directional_movement_probe.gd`.
- Godot 4.6.2, Exit 0, **14/14** Checks und Marker
  `FRONTIER_DIRECTIONAL_MOVEMENT_PROBE_ALL_PASS`; keine Script-/Enginefehler
  oder Leakmeldung im ausgegebenen Lauf. Alle Fixture-Nodes freigegeben,
  Commands/Effects leer, gemessene Produktionsquellen unverändert.
- Kein Combat, keine Hindernisse, Höhen, Multiplayer- oder Crowdlast; direkte
  Integratorprüfung statt normalem Command-/RPC-End-to-End-Pfad.
- Git: neue Diagnoseartefakte; durch diesen Arbeitsschritt kein Commit/Push
  und keine Änderung der produktiven Navigation.
