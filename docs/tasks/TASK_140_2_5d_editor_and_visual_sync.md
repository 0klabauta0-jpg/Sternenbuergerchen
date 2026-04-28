# TASK_140 - 2.5D Editor und Visual Sync

## Ziel
2.5D-Hoehendaten im Editor sichtbar und pflegbar machen und die 3D-Darstellung so synchronisieren, dass Terrain, Objekte und spaeter Units auf plausiblen Hoehen erscheinen.

## Status: IMPLEMENTIERT

## Kontext
- TASK_135-139 definieren die Runtime-Daten und Kamera-/Picking-Basis.
- Fuer echte Kartenarbeit braucht der Editor Hoehenwerte, Transition-Typen und einfache Overlays, ohne Gameplay-Wahrheit in Editor-Code zu verschieben.

## Umfang
1. Editor-Properties fuer Hoehenfelder aus TASK_135 anzeigen/bearbeiten.
2. Visuelles Overlay fuer `height_level`, `cover_height`, `blocks_los_height` und Transition-Typen.
3. TerrainMap3DRenderer nutzt `floor_height`/`height_level` fuer Boden- und Objekt-Y-Position.
4. Objekt-Layer bleibt getrennt vom Boden-Layer.
5. Test-/Verifier-Map mit flachem Boden, Plattform, Rampe und hoher Deckung.

## Nicht-Ziele
- Keine komfortable Multi-Floor-Bearbeitung.
- Keine finalen 3D-Materialien oder Art Direction.
- Keine automatische Hoehenerkennung aus 3D-Modellen.
- Keine Full-3D-Editorbedienung.

## Akzeptanzkriterien
- [x] Editor kann 2.5D-Hoehenwerte pro Tile speichern.
- [x] Overlay macht Hoehen und Blocker lesbar.
- [x] 3D-Renderer platziert Boden/Objekte auf korrekter Hoehe.
- [x] Legacy-Karten sehen ohne Hoehenwerte unveraendert flach aus.
- [x] Verifier prueft JSON-Roundtrip und 3D-Placement-Hoehen.

## Umsetzung
- Das Tile-Property-Panel zeigt und bearbeitet jetzt `floor_height`, `unit_eye_height_bonus`, `cover_height`, `blocks_los_height` und `height_transition_type`.
- `TerrainMapRenderer` besitzt ein optionales Height-Overlay fuer Editor-Nutzung. Es zeigt nur nicht-flache Tiles und markiert Hoehe, Cover, LOS-Blocker und Rampen/Treppen kompakt.
- Der Map-Editor rendert dieses Overlay im Editor und aktualisiert es bei Tile-Property-Aenderungen.
- `TerrainMap3DRenderer` nutzt bereits den 2.5D-`floor_height`-Pfad aus TASK_139; TASK_140 prueft diesen jetzt explizit fuer Boden und Objekt-Instanzen.
- `scripts/tests/task_140_verifier.gd` deckt Editor-Controls, JSON-Roundtrip, 2D-Overlay, Legacy-Flat-Verhalten und 3D-Placement ab.

## Risiken
- Editor kann schnell ueberladen wirken; V1 braucht kompakte Felder und klare Overlays.
- Automatische 3D-Offsets duerfen nicht die pro-Modell-Kalibrierung aus TASK_134 zerstoeren.
