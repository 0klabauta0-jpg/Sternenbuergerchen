# Altlasten — kontrollierte Bereinigung 10.11.2026

Basis: Main fbb7f52be, eigener task/altlasten-fuenf-schritte-20261110.
Alle Godotlaeufe 4.6.2 mit run_review2_isolated.py, frischem user://,
Canary und unveraendertem echten Rosterhash/mtime. Rohlogs liegen lokal unter
.godot/altlasten; diese Datei enthaelt nur die nachvollziehbaren Ergebnisse.

## 1. LOS / Cache
Gemeinsame Blockersuche im LineOfSightSystem; Runtime behaelt ihre bisherigen
Welthoehen, Reichweiten-, Wandsegment- und Endpointregeln. PrimaryView liest
die explizit gebundene Registry. Cache erfasst deren Identitaet und Revision;
Revision macht auch stationaere sichtbare Linien dirty. Map-only-Authoring
ohne Revisionsquelle benutzt keinen langlebigen LOS-Cache.

- Neue altlasten_los_runtime_verifier.gd: urspruenglich11/9, anschliessend20/0.
- Review entdeckte einen Hoehenrandfall bei fehlender Endpunktzelle. Neue echte
  Sparse-Fixture zuerst22/1, mit erhaltener Runtime-Welthoehe23/0.
- Prueft Square/Hex, warmen Cache offen/geschlossen, Registryersatz, reine
  Reads, mutable Editor-Map und stationaere Revision ohne neue Befehle.
- TASK456 Wandsegment-LOS/Editorinspektor, HUD Door Runtime Authority und
  CPU/HUD R7 LOS-Projektion: drei bestandene isolierte Nachbargates.
- Keine neue Gameplay-LOS-Regel, kein gemessener Performancegewinn.

Reproduktion (pro Skript, success-marker passend setzen):
`python scripts/tests/run_review2_isolated.py --project . --script res://scripts/tests/altlasten_los_runtime_verifier.gd --success-marker 'ALTLASTEN_LOS passed=' --baseline .godot/altlasten/roster_baseline.json --output .godot/altlasten/recheck --timeout 150`

## Fortschritt
2 Loadoutowner, 3 Controls, 4 Diagnostik, 5 Portraetexport folgen seriell.
Keine Mainintegration oder neue Release-EXE. Allgemeine Performance und native
Gestaltungsabnahme sind kein Ergebnis dieser Komponentenregressionen.
