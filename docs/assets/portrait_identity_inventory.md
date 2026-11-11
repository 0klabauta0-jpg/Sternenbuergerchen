# Portrait Identity Inventory

## Zweck
TASK_233 stellt einen stabilen Portrait-Katalog fuer das Start-Roster bereit.
Seit dem Portraetpass 05.11.2026 zeigen die bestehenden 42 IDs ein gemeinsames
illustriertes Frontier-Ensemble. Alte Originaldateien bleiben unter
`res://Assets/Char/` erhalten. Produktive Bildreferenzen sind ausschliesslich
projektlokale `res://`-Pfade; UI-Skripte skalieren in feste Zielrechtecke.

## Aktive Atlasquellen, aktualisiert 11.11.2026
- Quelle: `res://Assets/curated/portraits/frontier_20261105/`
- Aktive Viererboegen: 12
- Abmessungen je Originalbogen: 1254x1254 RGB; je exakter Quadrant: 627x627
- Regionen: 48 AtlasTexture-Ressourcen, 46 stabile Katalog-IDs und zwei Reserven
- Kein Cropping/Resampling der PNGs; Originale bytegleich ins Projekt kopiert.
- Prompts, SHA-256, Herkunft und Sichturteil: `art/portraits_20261105/manifest.json`
- Die vier zusätzlichen IDs 045–048 verwenden die gezeichnete Revision aus
  `art/portraits_20261111/drawn_revision/manifest.json`. Frühere fotografischer
  wirkende Einzelbilder bleiben als verworfene Kandidaten erhalten.
- Bekannte IDs priorisieren aktuelle Bilder; alte explizite Pfade werden ohne
  Saveaenderung lesend als `legacy_paths` zum selben bisherigen ID-Eintrag erkannt.
- Standardkatalog pro Prozess gecacht, Rueckgaben tief kopiert. Customkataloge
  lesen frisch; `clear_cache_for_tests()` setzt nur den abgeleiteten Cache zurueck.

## Erhaltener Legacy-Scan
- Quelle: `res://Assets/Char/`
- PNG-Dateien gesamt: 99
- Runtime-Katalog fuer Start-Roster: 46 Kandidaten
- Mindestbedarf Start-Roster: 20 bis 30 NPCs
- Lokale absolute Pfade: keine

## Aufloesungen der erhaltenen Legacyquellen
| Aufloesung | Anzahl |
|---|---:|
| 1024x1024 | 9 |
| 1122x1402 | 7 |
| 1184x864 | 67 |
| 1200x896 | 1 |
| 1254x1254 | 7 |
| 1920x1920 | 8 |

## Groessen-Diagnose der erhaltenen Legacyquellen
- 8 Dateien sind groesser als 4 MB und/oder 1920x1920.
- Der vorherige Katalog markierte grosse Quellen und die 12.-Mai-Portraits mit `large_source_png_use_scaled_texture_rect`. Der aktive Atlaspass weist auf gemeinsam genutzte Originalboegen mit `shared_source_atlas_exact_quadrant_use_scaled_texture_rect` hin.
- Roster-Karten duerfen die Originalgroesse nicht als Layoutgroesse verwenden.

## UI-Vertrag
| Nutzung | Zielgroesse | Verhalten |
|---|---:|---|
| Character Sheet | 96x120 | `TextureRect` skaliert/croppt innerhalb des festen Blocks |
| Roster-Karte | 64x64 | Thumbnail bleibt feste Kartengroesse |
| Compact-Karte | 38x38 | Listen/Drag-Previews bleiben kompakt |

## Katalogfelder
- `id`: stabile Portrait-ID, z.B. `char_portrait_001`
- `path`: loadbarer `res://Assets/curated/portraits/frontier_20261105/portraits/...tres`-Pfad
- `width`, `height`, `bytes`: Inventarwerte der AtlasTexture-Region/Ressource
- `sheet_path`, `sheet_sha256`, `region`: zugeordnetes Original und exakte Region
- `legacy_paths`: erhaltener alter PNG-Pfad derselben bestehenden ID
- `candidate`: fuer Start-Roster geeignet
- `tags`: optionale Rollen-/Identity-Hinweise wie `medic`, `pilot`, `leader`, `cybernetic`
- `diagnostics`: sichtbare Hinweise fuer grosse Quellen oder spaetere Crop-Arbeit

## Start-Roster-Anbindung
`scripts/meta/start_roster_generator.gd` fragt den Katalog deterministisch nach einer Seed-Zuweisung. Jede generierte Einheit bekommt `portrait_id` und `portrait_path`. Der Katalogresolver priorisiert die stabile ID, danach einen bekannten Legacy-Alias, danach einen expliziten loadbaren res-Pfad und zuletzt das bestehende Fallback. Die Savedaten werden dadurch nicht umgeschrieben.

## Offene Sichtpruefung
- Character Sheet mit mehreren Portraits oeffnen.
- Homebase-Roster mit 20 bis 30 Karten scrollen.
- FOB-Listen/Drag-Previews auf grosse PNG-Quellen pruefen.
