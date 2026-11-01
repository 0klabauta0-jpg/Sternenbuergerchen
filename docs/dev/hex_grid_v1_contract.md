# Hex Grid V1: Koordinaten, Karte und Navigation

Vertrag zum Nutzerauftrag [HEX_2026_11_01](../tasks/HEX_2026_11_01_foundation.md).
Der neue Hex-Untergrund verwendet `grid_topology = "hex_axial_v1"`.
Fehlt das Feld, bleibt eine Karte `square8`; alte Karten werden nicht umgedeutet.
Unbekannte Topologien werden beim Laden mit einem Load-Issue abgewiesen.

## Geometrie

`HexGrid` ist ein reiner statischer Helper, keine zweite Kartenwahrheit.
Axialkoordinaten `(q,r)` ergeben die physische Bodenebene:

```text
x = q + 0.5*r
z = sqrt(3)/2*r
Nachbarn = (1,0), (1,-1), (0,-1), (-1,0), (-1,1), (0,1)
Hexdistanz = max(abs(dq), abs(dr), abs(dq+dr))
Radius = 1/sqrt(3), Eckwinkel = 30 + 60*i Grad
```

Alle Nachbarzentren sind eine physische Ebeneinheit voneinander entfernt.
`round_axial` verwendet Cube-Rundung statt getrenntem Runden von q und r.
`line` verwendet dieselbe Rundung; kanonische Endpunktreihenfolge mit Umkehr
garantiert die gleiche Zellliste für entgegengesetzte Sichtstrahlen.

Öffentliche statische API: `axial_to_plane`, `plane_to_axial`, `round_axial`,
`neighbor_directions`, `neighbors`, `are_neighbors`, `distance`, `line`, `corners`.
Das `grid_size` einer neuen leeren Karte begrenzt q/r als Parallelogramm;
es bezeichnet keinen Hexradius und garantiert keine sechseckige Kartenkontur.

## Karten- und Registrybesitz

`TerrainMapData.create_empty` akzeptiert als letzten optionalen Parameter
`grid_topology: String = "square8"`. `load_from_file`, `save_to_file` und
`get_grid_topology` erhalten den ausgewählten Topologiestand.

`TerrainRegistry.configure_iso_grid(origin, half_width, half_height, topology)`
hat denselben kompatiblen Default. Wer eine Hexkarte registriert, muss deren
Topologie ausdrücklich übergeben. Weltpositionen werden weiterhin im
vorhandenen Iso-Vector2-Raum gespeichert: erst Axial→Ebene, dann die bestehende
Iso-Projektion. Die inverse Umrechnung hebt beide Schritte auf.

`world_to_grid` verwendet im Hexmodus Cube-Rundung. `get_grid_line` und
`are_grid_neighbors` liefern Regeln der ausgewählten Topologie.

`get_movement_distance(a,b)` misst im Hexmodus die Entfernung der
entprojizierten physischen Ebene, multipliziert mit
`sqrt(half_width² + half_height²)`. Für 64/32 entsprechen alle sechs direkten
Nachbarschritte deshalb demselben Bewegungsmaß von rund 71,554 Einheiten.
Im Legacy-Modus bleibt die bisherige projizierte Vector2-Distanz unverändert.
Die Simulation muss diese API konsumieren; ein Helper allein ändert Bewegung
nicht. Der Renderer muss Axialkoordinaten über dieselbe Ebene zeichnen/picken.

## Pfade und Höhen

Der bestehende Pathfinder liest die Registrytopologie. Hex hat sechs echte
Kanten; `(1,1)` ist kein Nachbar, `(1,-1)` dagegen schon. Quadratische
Corner-Cut-Prüfungen und der Diagonalaufschlag gelten nur für `square8`.
Flache Hexkanten kosten den Surfacewert; eine erlaubte Rampe zusätzlich eine
Kosteneinheit pro Höhenstufe. Klippen/`none` blockieren echte Höhenwechsel,
`walkable = false` blockiert immer.

Hexheuristik, Exposure-Distanz, Linien, Korridorabstand und Blocker-Radien
verwenden Hexdistanz beziehungsweise die physische Hexebene. HPA-Komponenten,
Portale und Dirty-Nachbarcluster verwenden dieselben sechs Kanten. Hex-Portal-
Scoring berücksichtigt lokale Wege und löst gleiche Eingangskosten zugunsten
der näheren Zielseite auf; die Legacy-Scoringroute bleibt erhalten.

HPA bleibt eine komponentenweise Annäherung. Der Verifier beweist die gleiche
Pfadkostenfolge für eine offene gerade Route sowie legale Wege/Dirty-Portale,
keine globale Optimalität auf beliebigen Karten und kein Großkartenbudget.

## Prüfung und Migrationsgrenze

`scripts/tests/frontier_hex_foundation_verifier.gd` prüft Geometrie einschließlich
negativer Koordinaten und sechs Auswahlgrenzen, gleiche Nachbarkosten/-metriken,
Hindernisse, Rampen/Klippen, HPA und neu geöffnete Diagonalportale, Save/Load
sowie unveränderte Legacypositionen und zwei konkrete Legacydiagonalpfade.

Der unveränderte Altpfad ist zusätzlich durch die
[synthetische Richtungsprobe](../reports/FRONTIER_NAVIGATION_UND_HEX_2026-11-01.md)
dokumentiert. Ihre bestandenen Diagnosechecks bedeuten keine faire Altbewegung.

Dieser Vertrag behauptet keine vollständige Migration alter Missionen,
Mauertypen, Editortools oder Netzwerk-/Saveinhalte. Konkrete LOS/FOW-,
Simulation-, Grafik-/Picking- und native Bildnachweise gehören zu den jeweils
ausgeführten Integrationsschritten; UI/Visuals erzeugen keine neue Topologie.
