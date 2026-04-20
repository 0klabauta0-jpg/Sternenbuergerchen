# TASK_066 – Corridor-Wall Typen, Typ-Texturen und Auto-Cliff

- Phase: 14 – Map-Editor-Workflow und Politur
- Status: offen
- Abhaengigkeiten: TASK_065 (Tile-Typ-Katalog und Palette)

## Ziel
Der Tile-Katalog soll nicht nur nackte Terrain-Properties liefern, sondern auch Texturpfade fuer typische Bodenarten sowie automatische Cliff- und Wall-Overlays fuer lesbarere Karten.

## Anforderungen
1. Erweitere den Tile-Katalog um optionale `texture_path`-Eintraege fuer passende Bodentypen.
2. Tile-Sprites sollen die Typ-Textur nutzen, wenn sie vorhanden ist; sonst bleibt ein klarer visueller Fallback erlaubt.
3. Cliff-Overlays sollen automatisch an Kanten mit Hoehendifferenz gezeichnet werden.
4. Cliff-Corner-Pieces sollen dort erscheinen, wo zwei passende Cliff-Kanten aufeinandertreffen.
5. Wall-Overlays sollen fuer Tiles mit `blocks_los=true` an Kanten zu Nicht-Wall-Nachbarn gezeichnet werden.

## Akzeptanzkriterien
- Boden-Typen koennen eigene Texturen aus dem Katalog ziehen.
- Hoehenkanten erzeugen automatisch Cliff-Overlays.
- Wall-Tiles erzeugen automatisch sichtbare Wall-Overlays.
- Die Karte bleibt ohne manuelles Platzieren einzelner Cliff-/Wall-Sprites lesbar.

## Nicht in diesem Task
- perfekte oder finale Art-Passform aller Kenney-Sprites
- diagonale Speziallogik ueber die einfache Nachbarschaft hinaus
- neue Runtime-Gameplay-Systeme ausserhalb des Editor-/Renderpfads
