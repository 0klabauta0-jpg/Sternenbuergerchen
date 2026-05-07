# Terrain Height and Hill Rules

## Zweck und Scope
Dieses Dokument ist der gemeinsame Regelvertrag fuer Huegel, Hoehenkanten, Oberflaechen und Objekte. Editor, Runtime, Save/Load, Legacy-2D-Renderer und 2.5D-View muessen dieselben Tile-Daten lesen und duerfen keine eigene Gameplay-Wahrheit erfinden.

TASK_182 ist ein Contract- und Audit-Task. Er beschreibt Zielregeln und Bestandskonflikte, patcht aber bewusst kein Pathfinding, LOS, Combat, Editor-Authoring oder Rendering.

## Datenfelder
`TerrainTileData` ist der Datenanker:

| Feld | Zielregel |
| --- | --- |
| `height_level` | Reine Gelaendehoehe, geclamped auf `0..2`. |
| `object_height` | Hoehe eines Objekts auf dem Tile, geclamped auf `0..3`. Veraendert nie `height_level`. |
| `surface_type` | Bodenoberflaeche: `ground`, `road`, `sand`, `rock`. Gilt auf jeder Hoehe. |
| `walkable` | Tile-weite Begehbarkeit. `false` blockiert Bewegung unabhaengig von Hoehe und Kante. |
| `blocks_los` | Tile-weite LOS-Blockade. Die effektive Blockerhoehe kommt aus `height_level + object_height`. |
| `cover_value` | Tile-/Objekt-Cover fuer Combat. Renderer oder UI duerfen daraus keine neue Wahrheit ableiten. |
| `edge_type` | Hoehenkantenart des hoeheren Tiles: `cliff`, `slope` oder `none`. |

`type_id` und `object_type_id` beschreiben Katalog-/Visual-Typen. Sie duerfen Terrainfelder nicht still ueberschreiben.

## Zielregeln
1. `height_level` beschreibt nur die Bodenoberseite.
2. `object_height` beschreibt Wand, Fels oder andere Blocker auf dieser Bodenoberseite.
3. Fuer LOS und sichtbare Objektpositionen wird die Objektbasis aus `height_level` abgeleitet; die Blockerhoehe ist `height_level + object_height`.
4. Eine Wand auf Huegel bleibt eine Wand auf `height_level > 0`; sie macht den Huegel nicht hoeher.
5. Ein Fels auf Huegel bleibt ein Objekt mit eigener `object_height`; er ersetzt nicht die Gelaendehoehe.
6. `surface_type` bleibt orthogonal zu Hoehe und Objekt: Sand auf H=1 ist Sand, Road auf H=2 ist Road, Rock auf H=1 ist Rock.
7. Die hoehere Kachel bestimmt bei unterschiedlicher Nachbarhoehe die Kantenart und Richtung.
8. Diagonale Bewegung darf keine blockierten orthogonalen Schritte umgehen.

## Bewegungsregeln
`walkable = false` blockiert das Ziel-Tile immer.

Bei gleicher Hoehe ist die Kante fuer Bewegung irrelevant; Surface-Kosten gelten weiter fuer das Ziel-Tile.

Bei unterschiedlicher Hoehe entscheidet das `edge_type` des hoeheren Tiles:

| `edge_type` | Bewegungszielregel |
| --- | --- |
| `slope` | Begehbare Hoehentransition, solange beide Tiles walkable sind. Zusatkosten pro Hoehenstufe. |
| `cliff` | Harte Klippenkante. Cliffs are hard blockers fuer jede Hoehendifferenz. |
| `none` | Keine Hoehentransition. `none` ist fuer Plateau-Innenbereiche oder gleiche Nachbarhoehe gedacht. Bei echter Hoehendifferenz ist es ein Authoring-Konflikt und runtime-seitig wie blockiert zu behandeln. |

Surface-Kosten werden nicht von Hoehe ueberschrieben:

| Surface | Speed | Pfadkosten |
| --- | ---: | ---: |
| `ground` | `1.0` | `1.0` |
| `road` | `1.4` | `0.7` |
| `sand` | `0.6` | `1.5` |
| `rock` | `0.8` | `1.3` |

Ein Sandhang ist also eine `slope`-Transition auf ein Tile mit `surface_type = sand` und dadurch teurer/langsamer als ein Ground-Hang.

## LOS, Cover und Combat
LOS liest nur autoritative Terrain-Daten. Renderer-Nodes, Editor-Controls und sichtbare Mesh-Hoehen sind keine Gameplay-Quelle.

Die effektive LOS-Blockerhoehe ist:

```text
effective_blocker_height = height_level + object_height
```

Ein LOS-Blocker auf H=2 mit `object_height = 2` blockt also als Hoehe 4. Ein niedriger Fels auf H=0 mit `object_height = 1` blockt als Hoehe 1.

`cover_value` wird als Tile-/Objekt-Cover gelesen und bleibt unabhaengig von der visuellen Darstellung. Combat-Hoehenbonus nutzt die Gelaendehoehe `height_level` der Unit-Tiles, nicht `object_height` und nicht Renderer-Y-Offsets.

Source- und Target-Tiles blockieren sich nicht selbst im einfachen LOS-Pfad; Zwischen-Tiles mit `blocks_los = true` koennen blocken.

## Visuals
Die sichtbare Bodenoberseite liegt bei `height_level`. In der 2.5D-View entspricht das `height_level * height_step`; im Legacy-2D-Pfad entspricht es dem gezeichneten Iso-Tile plus Hoehenkante.

Sichtbare Objektposition:

```text
object_base_height = height_level
object_top_height = height_level + object_height
```

Wand auf Huegel und Fels auf Huegel muessen auf der Huegeloberseite sitzen. `object_height` beeinflusst sichtbares Volumen und LOS-Blockerhoehe, aber nie die Gelaendehoehe.

Huegellinien entstehen aus Nachbarhoehen:

1. Nur orthogonale Nachbarn erzeugen Hoehenkanten-Visuals.
2. Eine Linie entsteht nur, wenn `neighbor.height_level < current.height_level`.
3. Die hoehere Kachel liefert `edge_type`.
4. `edge_type = slope` rendert Hang-/Rampen-Visuals.
5. `edge_type = cliff` rendert Klippen-Visuals.
6. `edge_type = none` rendert keine Hoehenlinie und ist bei Hoehendifferenz ein Authoring-Konflikt, kein versteckter Gratis-Hang.
7. Plateau-Innenbereiche mit gleicher Hoehe erzeugen keine Huegellinie.

## Editor-Authoring
Der Editor schreibt Terrain-Daten, nicht Runtime-State.

Das Hoehenwerkzeug darf `height_level` und `edge_type` schreiben. H=0 muss `edge_type = none` behalten oder herstellen. H>0 braucht eine bewusste Kantenentscheidung: `slope`, `cliff` oder fuer Plateau-Innenbereiche `none`.

Surface-Painting darf `height_level`, `edge_type`, `object_height`, `blocks_los`, `walkable` und `cover_value` nicht still zuruecksetzen.

Objekt-/Wandplatzierung darf die Gelaendehoehe nicht veraendern. Eine Wand auf Huegel setzt objektbezogene Felder wie `object_height`, `blocks_los`, `cover_value`, `walkable` und Objekt-/Typdaten, erhaelt aber `height_level`, `surface_type` und `edge_type`.

## Save/Load
Map-Roundtrips muessen mindestens diese Felder semantisch erhalten:

- `height_level`
- `object_height`
- `surface_type`
- `walkable`
- `blocks_los`
- `cover_value`
- `edge_type`
- `type_id`
- `object_type_id`

Defaults fuer alte Karten bleiben konservativ: `height_level = 0`, `object_height = 0`, `surface_type = ground`, `edge_type = cliff` im Datenmodell und H=0-Authoring mit `none` im Hoehenwerkzeug.

## Regelmatrix
| Fall | Datenform | Bewegung | LOS/Combat | Visual |
| --- | --- | --- | --- | --- |
| Flach zu flach | Beide Tiles gleiche `height_level` | Nach `walkable` und Surface-Kosten begehbar | Normale Hoehe | Keine Huegellinie |
| Flach zu Hang | Hoeheres Tile `edge_type = slope` | Begehbar mit Hangkosten | Hoehenbonus nach `height_level` | Slope-/Rampenlinie am hoeheren Tile |
| Flach zu Klippe | Hoeheres Tile `edge_type = cliff` | Blockiert | LOS nutzt Daten, nicht Kantenvisual | Klippenlinie am hoeheren Tile |
| Hang mit Sand | Hoeheres Ziel `edge_type = slope`, `surface_type = sand` | Begehbar, teurer/langsamer als Ground-Hang | Normale Hoehenregeln | Sand-Top bleibt sichtbar, Hangseite bleibt sichtbar |
| Klippe mit Sand | Hoeheres Tile `edge_type = cliff`, `surface_type = sand` | Blockiert | Normale Hoehenregeln | Sand-Top plus Klippenlinie |
| Plateau-Innenbereich | Gleiche `height_level`, `edge_type = none` erlaubt | Begehbar nach `walkable` | Normale Hoehenregeln | Keine Huegellinie |
| Wand auf flach | `height_level = 0`, `object_height > 0`, oft `blocks_los = true` | Nach `walkable`; Wand-Tile meist blockiert | Blockerhoehe `height_level + object_height` | Objektbasis auf Bodenoberseite |
| Wand auf Huegel | `height_level > 0`, `object_height > 0`, oft `blocks_los = true` | Nach `walkable`; Wand-Tile meist blockiert | Hoeherer Blocker durch `height_level + object_height` | Wand sitzt auf Huegeloberseite |
| Fels auf Huegel | `height_level > 0`, `object_height > 0`, Cover/LOS nach Katalog | Nach `walkable`; Fels meist blockiert oder deckungsgebend | Blocker/Cover nach Daten | Fels sitzt auf Huegeloberseite |

## Bestandskonflikte
Diese Punkte sind bekannte Abweichungen oder offene Pruefstellen und werden nicht in TASK_182 gepatcht:

1. `TerrainPathfinder` erlaubt aktuell bei `edge_type = cliff` noch Hoehendifferenzen von 1. Zielregel: Cliff ist harter Blocker. Folgepatch: TASK_184.
2. `edge_type = none` mit echter Hoehendifferenz wird aktuell nicht als eigener Fehlerfall validiert. Zielregel: nur Plateau-/Same-Height oder Authoring-Konflikt. Folgepatches: TASK_183 und TASK_184.
3. Das Hoehenwerkzeug kann H>0 mit `none` schreiben. Das ist fuer Plateau-Innenbereiche erlaubt, braucht aber Validierung gegen Nachbarn. Folgepatch: TASK_183.
4. Legacy-2D-Objekt-Overlays muessen noch gegen die Objektbasis auf Huegeloberseiten geprueft werden. Folgepatch: TASK_185.
5. 2.5D-Objekte sitzen bereits auf `top_y`, aber Edge-Linien, Missing-Asset-Fallbacks, Marker und Mapping-Y-Offsets muessen mit einer Huegel-Fixture abgesichert werden. Folgepatch: TASK_185.
6. Alte Doku aus TASK_058 beschreibt Cliffs als nur bei `height_diff > 1` blockierend. Der neue Vertrag ersetzt diese Gameplay-Entscheidung fuer die kommenden Patchtasks.

## Verifier-Strategie
TASK_182 prueft nur Vertrag und Bestand:

- Existenz zentraler Konstanten und Felder in `TerrainTileData`.
- Surface-Speed- und Path-Cost-Werte.
- Clamp-Grenzen fuer `height_level` und `object_height`.
- Existenz von Pathfinding-, LOS-, Renderer- und Editor-Authoring-Ankerpunkten.
- Existenz der Pflichtabschnitte und Pflichtfaelle in diesem Dokument.

TASK_183 prueft Editor-Authoring und Save/Load-Roundtrips.

TASK_184 prueft Gameplay-Semantik fuer A*, HPA, LOS, Cover, Combat und Diagonalregeln.

TASK_185 prueft 2.5D-/Legacy-Visuals, Hoehenanker, Edge-Linien, Surface-Lesbarkeit und fehlende 3D-Mappings.
