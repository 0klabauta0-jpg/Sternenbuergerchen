# TASK_201 - Weapon Range Scale and Tile Distance Patch

## Ziel
Waffenreichweiten sollen auf komprimierte, tile-basierte Spielwerte umgestellt oder eindeutig daraus abgeleitet werden. Combat, Overwatch, Enemy-Taktik und Multiplayer muessen dieselbe effektive Reichweite sehen.

Zielgroesse: 32x32 und 64x64 als Standardkarten. Waffen sollen taktisch fuehlbar sein, aber nicht sofort die ganze Karte abdecken.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_089 - Enemy Cover-Seeking on Damage
- TASK_092 - Stealth and Contact Range Contract
- TASK_166 - Multiplayer Authority Command Contract
- TASK_168 - Multiplayer Snapshot Replication Contract
- TASK_189 - Medic Adjacent Tile Healing Rule
- TASK_200 - Enemy Team Tactics Contract and Editor Config

## Kontext
Der aktuelle Combat nutzt fuer Zielbarkeit stark `contact_range` und Target-Stealth. `WeaponData` enthaelt zwar Waffenwerte, aber die effektive Angriffsreichweite ist nicht sauber der aktiven Waffe zugeordnet. Dadurch koennen UI, Gegnerlogik und Combat schnell auseinanderlaufen.

Der neue Vertrag soll Reichweite in Tiles denken und nur am Rand in Weltkoordinaten umrechnen.

## Vorgeschlagene Basiswerte
- `smg`: 10 Tiles
- `support_lmg` oder `lmg`: 20 Tiles, Name im Task final klaeren
- `rifle`: 25 Tiles
- `sniper`: 40 Tiles
- `medictool`: 1 Tile fuer direkte Heilung, synchron zu TASK_189

Diese Werte sind Startwerte. Der Task soll sie strukturell sauber machen, nicht eine endgueltige Balance behaupten.

## Umfang
1. Reichweitenvertrag:
   - Jede Waffe bekommt `effective_tile_range`.
   - Wenn bestehende Systeme Weltkoordinaten brauchen, wird aus Tile-Range und Terrain-Tilegroesse abgeleitet.
   - Fallback ohne TerrainRegistry ist dokumentiert und testbar.
2. Combat-Zielbarkeit:
   - Normale Angriffe nutzen Angreiferwaffe + LOS + Zielzustand.
   - `contact_range` bleibt optionaler Wahrnehmungs-/Kontaktwert, ersetzt aber nicht die Waffenreichweite.
   - Stealth darf die Entdeckung beeinflussen, aber nicht unklar die Waffenwerte ueberschreiben.
3. Overwatch und Security:
   - Overwatch nutzt dieselbe aktive Waffenreichweite.
   - Sniper darf weit wirken, aber nicht still jede Standardmap komplett abdecken.
4. Editor-/Datenanzeige:
   - Editor/Loadout koennen Range in Tiles anzeigen.
   - Kurze Labels reichen, z. B. `10`, `25`, `40`.
5. Multiplayer-Grenze:
   - Reichweitenentscheidung bleibt authority-seitig.
   - Snapshot zeigt Range/Weapon nur als Anzeige oder Diagnose, nicht als Client-Wahrheit.
6. Verifier:
   - 32x32- und 64x64-Fixtures.
   - SMG erreicht nicht Rifle-Range.
   - Rifle erreicht nicht Sniper-Range.
   - Medictool heilt nur adjacent, wenn TASK_189 aktiv ist.

## Nicht-Ziele
- Keine Projektilphysik.
- Keine Munition.
- Keine endgueltige Waffenliste.
- Keine Explosionen, Splash-Damage oder Panzerfaust-Balance.
- Kein komplettes Stealth-Rework.

## Akzeptanzkriterien
- [x] `WeaponData` oder ein klarer Resolver liefert tile-basierte Reichweiten fuer alle aktiven Waffen.
- [x] Combat-Fire-Entscheidungen nutzen die aktive Waffenreichweite des Angreifers.
- [x] Overwatch nutzt dieselbe Reichweitenlogik.
- [x] Die vorgeschlagenen Basiswerte fuer SMG, LMG/Support, Rifle, Sniper und Medictool sind als Defaults abgebildet oder bewusst dokumentiert angepasst.
- [x] 32x32- und 64x64-Tests verhindern versehentliches Map-wide Shooting.
- [x] Multiplayer-Snapshots duplizieren keine clientseitige Range-Entscheidung.
- [x] Ein TASK_201-Verifier deckt Range, LOS, Stealth-Fallback und Snapshot-Diagnose ab.

## Erwartete Dateien
- `scripts/core/weapon_data.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tactical/overwatch_resolver.gd`
- `scripts/multiplayer/multiplayer_snapshot_contract.gd`
- `scripts/tests/task_201_weapon_range_scale_and_tile_distance_patch.gd`
- `docs/tasks/TASK_201_weapon_range_scale_and_tile_distance_patch.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_201_weapon_range_scale_and_tile_distance_patch.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_092_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_111_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_168_multiplayer_snapshot_contract_verifier.gd`
- [x] `git diff --check`

## Risiken
- Alte Tests koennen Weltkoordinaten erwarten. Der Task braucht klare Adapter statt stiller Mischwerte.
- Wenn `contact_range` weiter als Waffenreichweite verwendet wird, entsteht wieder ein zweites Balancing.

## Naechster Schritt
Nach TASK_201 kann TASK_202 Enemy-Sichtlinien und Gefechtsrichtungen auf echte Waffenreichweiten beziehen.
