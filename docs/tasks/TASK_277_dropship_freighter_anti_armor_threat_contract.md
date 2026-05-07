# TASK_277 - Dropship Freighter Anti Armor Threat Contract

## Ziel
Dropship und Frachter sollen als taktisch relevante Luft-/Transportassets Schaden nehmen oder abgeschossen werden koennen, z. B. durch Rocket/Panzerfaust-artige Waffen. Daraus entstehen sichtbare Explosionen, LZ-Risiken, Missionsfolgen und Meta-Folgen.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_106 - Dropship-LZ Insertion und verzoegerte Aktivierung
- TASK_117 - Dropship-Deploy als SimulationRoot-Effects
- TASK_190 - Weapon Visual Loadout Expansion and Scale
- TASK_201 - Weapon Range Scale and Tile Distance Patch
- TASK_205 - Weapon Fire VFX Muzzle Flash Particles
- TASK_244 - Combat Movement UI SFX Integration
- TASK_270 - Commander to Fireteam Leader Delegation Contract
- TASK_276 - Tactical Breakout and Exception Behavior

## Kontext
Wenn der Spieler eine Landezone freihaelt, soll das nicht nur Dekoration sein. Feinde mit Raketen-/Heavy-Waffen koennen Dropship oder Frachter bedrohen. Der Spieler muss die LZ sichern, sonst kann Transport verloren gehen. Das ist ein starkes taktisches Ziel, aber es braucht klare, faire Regeln.

## Umfang
1. Asset-Zustaende:
   - intact.
   - threatened/locked.
   - hit/damaged.
   - destroyed/crashed.
   - recovering/unavailable.
2. Zielbarkeit:
   - Nur definierte Heavy-/Rocket-Waffen koennen Air Assets bedrohen.
   - Range/LOS/FoW/Hoehe werden respektiert.
   - Kein zufaelliges Sofort-Abschiessen ohne sichtbare Warnphase.
3. LZ-Regeln:
   - LZ secure reduziert Risiko.
   - Enemy Security/AT-Team in Reichweite erhoeht Risiko.
   - Fireteam kann LZ-Sicherung als Commander-Intent bekommen.
4. VFX/SFX:
   - Rocket/Muzzle/Trail optional.
   - Hit/Explosion.
   - Smoke/debris Marker.
   - Audio aus TASK_244.
5. Runtime:
   - SimulationRoot-authoritative Effects.
   - Snapshot fuer AirAssetStatus.
   - No UI-only destruction.
6. Fairness:
   - Warnung vor Abschuss.
   - Spielerfeedback, wer bedroht und warum.
   - Difficulty/Balancing-Flags.

## Nicht-Ziele
- Keine echte Flugsimulation.
- Keine komplexe ballistische Raketensimulation.
- Kein permanenter Kampagnenverlust ohne Meta-Vertrag aus TASK_278.
- Kein grafisch aufwendiger Crash-Cinematic.

## Akzeptanzkriterien
- [x] Dropship/Frachter haben klare Damage-/Threat-Zustaende.
- [x] Nur definierte Heavy-/Rocket-Waffen koennen Air Assets bedrohen.
- [x] LZ-Sicherung beeinflusst Risiko sichtbar.
- [x] Hit/Destroy loest VFX/SFX und Snapshot-Status aus.
- [x] UI zeigt Warnung vor kritischem Verlust.
- [x] Ein Verifier prueft Threat, Hit, Destroy, LZ-Sicherung und Authority.

## Erwartete Dateien
- `docs/dev/air_asset_threat_damage_contract.md`
- `scripts/mission/air_asset_status.gd`
- `scripts/mission/mission_dropship_effect_adapter.gd`
- `scripts/combat/...`
- `scripts/tests/task_277_dropship_freighter_anti_armor_threat_contract.gd`
- `docs/tasks/TASK_277_dropship_freighter_anti_armor_threat_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_277_dropship_freighter_anti_armor_threat_contract.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/bugfix_dropship_mission_flow_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- [x] `git diff --check`

## Risiken
- Zu harte Air-Asset-Verluste koennen unfair wirken.
- Spieler braucht klare Warnung und Gegenmittel, sonst wird es frustrierend.

## Naechster Schritt
Nach TASK_277 definiert TASK_278 die Meta-Folgen von verlorenen Dropships/Frachtern.
