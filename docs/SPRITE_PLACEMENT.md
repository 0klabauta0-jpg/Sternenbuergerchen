# Sprite Placement & Offset Referenz

Dieses Dokument beschreibt die finalen Textur-Zuordnungen und Offsets
fuer isometrische Overlay-Sprites (Kenney Space Kit, 512x512px Canvas, 128x128px ISO Diamond).

## Grundlagen

- **ISO Grid**: `x = origin.x + (gx - gy) * half_w`, `y = origin.y + (gx + gy) * half_h`
- **half_w** = 64px, **half_h** = 32px
- **Richtungen (Grid → Welt)**:
  - `(+1, 0)` = SE
  - `(-1, 0)` = NW
  - `(0, +1)` = SW
  - `(0, -1)` = NE
- **Sprite-Positionierung**: `sprite.centered = false; sprite.position = world_position - (texture.get_size() * 0.5) + offset`

---

## Wall Overlays (corridor_wall / corridor_wallCorner)

Jedes Wall-Tile bekommt **genau 1 Overlay** basierend auf seiner strukturellen Rolle.

### Gerade Waende (2 gegenueberliegende Wall-Nachbarn)

Die Wandachse bestimmt die Textur. Per Perpendicular-Scan wird erkannt,
ob die Wand auf der Innen- oder Aussenseite liegt.

| Wandachse  | Textur            | Seite (Kartenrichtung) | Offset                                      |
|------------|-------------------|------------------------|----------------------------------------------|
| SE+NW Achse | `corridor_wall_SE` | SW-Seite (innere Wand nach SW) | `(0, 0)` — kein Offset                      |
| SE+NW Achse | `corridor_wall_SE` | NE-Seite (innere Wand nach NE) | `(half_w * 0.9, -half_h * 0.9)` = `(+57.6, -28.8)` |
| NE+SW Achse | `corridor_wall_SW` | NW-Seite (innere Wand nach NW) | `(0, 0)` — kein Offset                      |
| NE+SW Achse | `corridor_wall_SW` | SE-Seite (innere Wand nach SE) | `(half_w * 0.9, +half_h * 0.9)` = `(+57.6, +28.8)` |

**Perpendicular-Scan**: Senkrecht zur Wandachse suchen, ob in einer Richtung
eine weitere Wand existiert → das ist die Innenseite.
- SE+NW Achse: Scan Richtung SW `(0,+1)` — wenn Wand gefunden → Innenseite ist SW → Tile ist NE-Seite
- NE+SW Achse: Scan Richtung SE `(+1,0)` — wenn Wand gefunden → Innenseite ist SE → Tile ist NW-Seite

### Corner Waende (2 benachbarte Wall-Nachbarn)

Corners sitzen zentriert auf ihrem Tile, kein Offset.

| Wall-Nachbarn (Grid-Offsets)     | Textur                   | Offset   |
|----------------------------------|--------------------------|----------|
| SE `(+1,0)` + SW `(0,+1)`       | `corridor_wallCorner_SW` | `(0, 0)` |
| SE `(+1,0)` + NE `(0,-1)`       | `corridor_wallCorner_SE` | `(0, 0)` |
| NW `(-1,0)` + SW `(0,+1)`       | `corridor_wallCorner_NW` | `(0, 0)` |
| NW `(-1,0)` + NE `(0,-1)`       | `corridor_wallCorner_NE` | `(0, 0)` |

### Sonderfaelle

| Situation         | Textur            | Offset   |
|-------------------|-------------------|----------|
| 1 Wall-Nachbar    | `corridor_wall_XX` (Richtung des Nachbarn) | `(0, 0)` |
| 3 Wall-Nachbarn   | `corridor_wall_XX` (Richtung der offenen Seite) | `(0, 0)` |
| 4 Wall-Nachbarn   | `corridor_wall_SW` | `(0, 0)` |
| 0 Wall-Nachbarn   | `corridor_wall_SW` | `(0, 0)` |

---

## Cliff Overlays (terrain_sideCliff / terrain_sideCorner)

_(Bestehendes System, funktioniert korrekt)_

Cliffs werden auf **niedrigere Nachbar-Tiles** platziert (nicht auf dem Cliff-Tile selbst).

| Richtung zum niedrigeren Nachbarn | Textur                   |
|-----------------------------------|--------------------------|
| SE `(+1, 0)`                      | `terrain_sideCliff_SE`   |
| SW `(0, +1)`                      | `terrain_sideCliff_SW`   |
| NE `(0, -1)`                      | `terrain_sideCliff_NE`   |
| NW `(-1, 0)`                      | `terrain_sideCliff_NW`   |

Corner Cliffs werden bei 2 benachbarten Cliff-Kanten gestapelt.

---

## Testmap

`maps/wall_test_4x4.json` — 8x8 Grid mit geschlossener 4x4 Mauer:
- 4 Corner-Tiles + 8 Straight-Tiles = 12 Wall-Overlays gesamt
- Korrekte Darstellung: Geschlossener Ring, alle Kanten aligned

---

## Sprite-Dateien (Kenney Space Kit)

### Walls
- `corridor_wall_SE.png` / `corridor_wall_SW.png` / `corridor_wall_NE.png` / `corridor_wall_NW.png`
- `corridor_wallCorner_SE.png` / `corridor_wallCorner_SW.png` / `corridor_wallCorner_NE.png` / `corridor_wallCorner_NW.png`

### Corridors (fuer zukuenftige Verwendung)
- `corridor_SE.png` / `corridor_SW.png` — Gerade Korridore (Tunnel mit Waenden beidseitig)
- `corridor_corner_XX.png` — L-Kurven
- `corridor_end_XX.png` — Sackgassen
- `corridor_split_XX.png` — T-Kreuzungen
- `corridor_cross_SW.png` — 4-Wege-Kreuzung

### Cliffs
- `terrain_sideCliff_SE.png` / `terrain_sideCliff_SW.png` / `terrain_sideCliff_NE.png` / `terrain_sideCliff_NW.png`
- `terrain_sideCorner_SE.png` / `terrain_sideCorner_SW.png` / `terrain_sideCorner_NE.png` / `terrain_sideCorner_NW.png`
