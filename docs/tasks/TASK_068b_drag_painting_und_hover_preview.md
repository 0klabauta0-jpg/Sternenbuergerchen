# TASK_068b – Drag-Painting und Hover-Preview

- Phase: 14 – Map-Editor-Workflow und Politur
- Status: implementiert
- Abhaengigkeiten: TASK_068 (Zoom-Inversion und Auto-Wall-Overlays)

## Ziel
Der Brush-Workflow soll fluessiger werden: Typen sollen beim Ziehen durchgehend aufgetragen werden koennen, und der Editor soll eine kleine Vorschau am Hover-Punkt zeigen.

## Anforderungen
1. Linksklick-Halten und Ziehen soll im Brush-Modus durchgehend malen.
2. Ein halbtransparentes Hover-Preview-Sprite soll den aktuell gewaehlten Tile-Typ an der Mausposition anzeigen.
3. Das Hover-Preview soll nur sichtbar sein, wenn ein Tile-Typ aktiv ausgewaehlt ist.

## Akzeptanzkriterien
- Durch Ziehen mit gedrueckter linker Maustaste koennen mehrere Tiles nacheinander bemalt werden.
- Das Hover-Preview zeigt vor dem Klick, welcher Typ gesetzt wird.

## Nicht in diesem Task
- komplexe Brush-Formen
- Multi-Tile-Hover-Preview fuer grosse Brush-Radien
- Undo-Historie ueber lange Brush-Zuege
