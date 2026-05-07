# Nature Cliff Hill Edge Visual Checklist

Stand: 2026-05-07
Status: TASK_252 manuelle Abnahme offen

## Setup
- [ ] Kleine Huegel-Testkarte mit Sand-Slope, Brown-Cliff, Rock/Grey-Kandidaten und Mauer auf Huegel laden.
- [ ] 2.5D-Kamera drehen, zoomen und pitchen.

## Cliff Edges
- [ ] Harte `edge_type = cliff`-Kanten lesen sich als Klippen und nicht als begehbare Rampe.
- [ ] Gerade Kanten und Outer-Corner sitzen am Tile-Rand der hoeheren Kachel.
- [ ] Plateau-Innenbereiche mit `edge_type = none` bleiben frei von falschen Kanten.

## Slope Steps
- [ ] `edge_type = slope` nutzt Step-/Ramp-Visuals und wirkt begehbar.
- [ ] Step-Visuals werden nicht an harten Klippen verwendet.
- [ ] Slope-Visuals verdecken Top-Surface und Marker nicht.

## Theme
- [ ] Brown-Nature-Kit-Theme ist als V1-Default stimmig fuer Sand/Dirt.
- [ ] Grey-Varianten sind im Katalog vorhanden und fuer Rock/Asteroid-Follow-up plausibel.

## Architektur
- [ ] Keine Walkability-, LOS-, Cover- oder SimulationRoot-Aenderung durch den Visual-Pass.
- [ ] Missing-Mapping-Diagnosen bleiben sichtbar statt stiller Fallbacks.
