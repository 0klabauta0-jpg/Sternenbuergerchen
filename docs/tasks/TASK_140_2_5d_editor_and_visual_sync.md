# TASK_140 - 2.5D Editor und Visual Sync

## Ziel
2.5D-Hoehendaten im Editor sichtbar und pflegbar machen und die 3D-Darstellung so synchronisieren, dass Terrain, Objekte und spaeter Units auf plausiblen Hoehen erscheinen.

## Status: GEPLANT

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
- [ ] Editor kann 2.5D-Hoehenwerte pro Tile speichern.
- [ ] Overlay macht Hoehen und Blocker lesbar.
- [ ] 3D-Renderer platziert Boden/Objekte auf korrekter Hoehe.
- [ ] Legacy-Karten sehen ohne Hoehenwerte unveraendert flach aus.
- [ ] Verifier prueft JSON-Roundtrip und 3D-Placement-Hoehen.

## Risiken
- Editor kann schnell ueberladen wirken; V1 braucht kompakte Felder und klare Overlays.
- Automatische 3D-Offsets duerfen nicht die pro-Modell-Kalibrierung aus TASK_134 zerstoeren.
