# TASK_068 – Zoom-Inversion und Auto-Wall-Overlays

- Phase: 14 – Map-Editor-Workflow und Politur
- Status: offen
- Abhaengigkeiten: TASK_067 (Fix Map-Editor 64x64 Flat Ground)

## Ziel
Die Editor-Bedienung soll wieder natuerlich zoomen, und automatische Wall-Overlays muessen sowohl beim Vollaufbau als auch bei lokalen Tile-Updates konsistent mitgezogen werden.

## Anforderungen
1. Das Mausrad soll in die erwartete Richtung zoomen: `WHEEL_UP` hinein, `WHEEL_DOWN` heraus.
2. Wall-Overlays muessen beim kompletten Karten-Rebuild korrekt aufgebaut werden.
3. Wall-Overlays muessen auch bei lokalen Tile-Refreshes oder Property-Aenderungen korrekt nachgezogen werden.

## Akzeptanzkriterien
- Zoom fuehlt sich im Editor wieder richtig herum an.
- Wall-Overlays verschwinden oder entstehen bei Tile-Aenderungen ohne inkonsistente Rest-Sprites.

## Nicht in diesem Task
- freie Kamera-Navigation
- weitere Editor-Gesten oder Touch-Bedienung
- neue Wall-/Cliff-Designsysteme
