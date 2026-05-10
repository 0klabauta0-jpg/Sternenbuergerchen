# Portrait Identity Inventory

## Zweck
TASK_233 stellt einen stabilen Portrait-Katalog fuer das Start-Roster bereit. Die Originaldateien bleiben im Projekt unter `res://Assets/Char/`; UI-Skripte laden sie nur ueber `res://`-Pfade und skalieren sie in feste Zielrechtecke.

## Scan
- Quelle: `res://Assets/Char/`
- PNG-Dateien gesamt: 87
- Runtime-Katalog fuer Start-Roster: 30 Kandidaten
- Mindestbedarf Start-Roster: 20 bis 30 NPCs
- Lokale absolute Pfade: keine

## Aufloesungen
| Aufloesung | Anzahl |
|---|---:|
| 1024x1024 | 9 |
| 1184x864 | 67 |
| 1200x896 | 1 |
| 1254x1254 | 2 |
| 1920x1920 | 8 |

## Groessen-Diagnose
- 8 Dateien sind groesser als 4 MB und/oder 1920x1920.
- Der Katalog markiert diese Quellen mit `large_source_png_use_scaled_texture_rect`.
- Roster-Karten duerfen die Originalgroesse nicht als Layoutgroesse verwenden.

## UI-Vertrag
| Nutzung | Zielgroesse | Verhalten |
|---|---:|---|
| Character Sheet | 96x120 | `TextureRect` skaliert/croppt innerhalb des festen Blocks |
| Roster-Karte | 64x64 | Thumbnail bleibt feste Kartengroesse |
| Compact-Karte | 38x38 | Listen/Drag-Previews bleiben kompakt |

## Katalogfelder
- `id`: stabile Portrait-ID, z.B. `char_portrait_001`
- `path`: loadbarer `res://Assets/Char/...`-Pfad
- `width`, `height`, `bytes`: Inventarwerte aus PNG-Scan
- `candidate`: fuer Start-Roster geeignet
- `tags`: optionale Rollen-/Identity-Hinweise wie `medic`, `pilot`, `leader`, `cybernetic`
- `diagnostics`: sichtbare Hinweise fuer grosse Quellen oder spaetere Crop-Arbeit

## Start-Roster-Anbindung
`scripts/meta/start_roster_generator.gd` fragt den Katalog deterministisch nach einer Seed-Zuweisung. Jede generierte Einheit bekommt `portrait_id` und `portrait_path`. Der Pfad bleibt die Runtime-Anzeigequelle; die ID ist fuer Persistenz, Reset und spaetere Portrait-Auswahl stabil.

## Offene Sichtpruefung
- Character Sheet mit mehreren Portraits oeffnen.
- Homebase-Roster mit 20 bis 30 Karten scrollen.
- FOB-Listen/Drag-Previews auf grosse PNG-Quellen pruefen.
