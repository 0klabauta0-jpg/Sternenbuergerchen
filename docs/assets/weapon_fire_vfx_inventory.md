# Weapon Fire VFX Inventory

Datum: 2026-05-06
Status: TASK_205 implementiert

## Zweck
Dieses Inventar beschreibt das kleine Muzzle-Flash-Subset fuer sichtbares Waffenfeuer. Die Assets sind reine Darstellung. Schaden, Trefferwurf, Suppression und Multiplayer-Authority bleiben im bestehenden Combat-/Snapshot-System.

## Quelle
| Source ID | Lokale Quelle | Projektpfad | Lizenz | Import |
| --- | --- | --- | --- | --- |
| `kenney_particle_pack` | `%USERPROFILE%/Pictures/Sternenbuerger/kenney_particle-pack` | `res://Assets/curated/kenney/particles/muzzle/` | Creative Commons Zero, CC0 | 5 transparente PNG + `License.txt` |

## Regeln
1. PNG-only, kein Massenimport des Particle Packs.
2. VFX wird nur aus autoritativen `fire_events` oder Snapshot-`fire_events` getrieben.
3. VFX erzeugt keine `SimulationRoot`-Commands oder -Effects.
4. Runtime-Referenzen nutzen nur `res://...`, keine lokalen Quellpfade.
5. Muzzle-Flash ist kurz, klein und darf Unit/Ziel nicht dauerhaft verdecken.

## Muzzle IDs
| ID | Datei | Quelle | Standardnutzung | Barrel-Offset |
| --- | --- | --- | --- | --- |
| `muzzle_flash_01` | `res://Assets/curated/kenney/particles/muzzle/muzzle_01.png` | `PNG (Transparent)/muzzle_01.png` | Rifle/default | 28 world units |
| `muzzle_flash_02` | `res://Assets/curated/kenney/particles/muzzle/muzzle_02.png` | `PNG (Transparent)/muzzle_02.png` | SMG | 24 world units |
| `muzzle_flash_03` | `res://Assets/curated/kenney/particles/muzzle/muzzle_03.png` | `PNG (Transparent)/muzzle_03.png` | Reserve compact flash | 26 world units |
| `muzzle_flash_04` | `res://Assets/curated/kenney/particles/muzzle/muzzle_04.png` | `PNG (Transparent)/muzzle_04.png` | Sniper | 34 world units |
| `muzzle_flash_05` | `res://Assets/curated/kenney/particles/muzzle/muzzle_05.png` | `PNG (Transparent)/muzzle_05.png` | Heavy/rocket visuals | 38 world units |

## Runtime-Vertrag
- Katalog: `res://data/weapon_fire_vfx_catalog.json`
- Anzeige: `TerrainMap3DView` liest `fire_event_dicts` im Primary-View-Order-Payload.
- Position: `attacker_position` plus Richtung zu `target_position` und katalogisiertem Barrel-Offset.
- Rotation: Die Sprite-Karte bleibt kamerafest; Schussrichtung wird ueber die kurze Trace-Linie sichtbar.
- Multiplayer: Clients zeigen `fire_events` aus TASK_204 an und rechnen keinen Combat neu.
