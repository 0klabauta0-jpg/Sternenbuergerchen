# TASK_278 - Air Asset Loss Recovery Meta Loop

## Ziel
Wenn Dropship oder Frachter beschaedigt oder abgeschossen werden, muss das sinnvolle Meta-Folgen haben: Pilot/Crew-Zustand, Schiff nicht verfuegbar, Reparatur oder Ersatz, Rueckkehr in Heimatbasis, Zeitkosten und Missionsplanung.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_033 - Heimatbasis
- TASK_037 - Rover/Frachter Respawn-Punkte
- TASK_079 - FOB Fireteam-Management Respawn-/Loadout-Staging und Dropship-Wartezone
- TASK_096 - Meta-Layer Recovery
- TASK_106 - Dropship-LZ Insertion und verzoegerte Aktivierung
- TASK_238 - Personnel Events Recruit Leave Dismiss Notifications
- TASK_277 - Dropship Freighter Anti Armor Threat Contract

## Kontext
Der User will, dass ein abgeschossenes Dropship nicht nur ein Explosionseffekt ist. Es soll Folgen haben: Der Pilot ist wieder in der Heimatbasis oder muss geborgen werden, das Schiff muss geholt/repariert werden, der naechste Einsatz dauert laenger oder braucht Ersatz.

## Umfang
1. Meta-Zustaende:
   - craft_available.
   - damaged_repairing.
   - destroyed_replacement_pending.
   - pilot_safe_homebase.
   - pilot_injured/recovering optional.
   - crew_missing optional als spaeterer Task.
2. Zeitkosten:
   - Reparaturdauer.
   - Ersatzbeschaffung.
   - Rueckhol-/Transferzeit.
   - Difficulty-/Scenario-Balance.
3. UI:
   - Homebase/FOB Flightdeck zeigt Status und ETA.
   - Mission-Debrief meldet Air-Asset-Verlust.
   - Help-Popups erklaeren Folgen.
4. Gameplay-Folgen:
   - Dropship nicht sofort wieder einsetzbar.
   - Alternative Transportoptionen koennen spaeter kommen.
   - Evac/Resupply kann blockiert oder verzoegert sein.
5. Save/Load:
   - AirAssetStatus persistiert.
   - Kein Verlust durch Screenwechsel.
6. Verifier:
   - Destroy im Mission-Smoke -> Debrief -> Homebase/FOB Status.
   - Timer laeuft kontrolliert.
   - Pilot/Craft-IDs bleiben konsistent.

## Nicht-Ziele
- Keine komplexe Wirtschaft.
- Keine Crew-Rettungsmission in diesem Task.
- Kein permanenter Softlock, wenn alle Transporter weg sind.
- Keine Storysequenzen.

## Akzeptanzkriterien
- [x] Air-Asset-Verlust erzeugt Meta-Status in Homebase/FOB.
- [x] Pilot/Craft-Zustand ist konsistent und gespeichert.
- [x] Reparatur/Ersatz hat sichtbare Zeitkosten.
- [x] Debrief zeigt Verlust und Folgen.
- [x] Kein Mission-/Campaign-Softlock entsteht.
- [x] Ein Verifier prueft Mission -> Debrief -> Homebase/FOB Roundtrip.

## Erwartete Dateien
- `docs/dev/air_asset_loss_recovery_meta_loop.md`
- `scripts/meta/...`
- `scripts/mission/air_asset_status.gd`
- `scripts/tests/task_278_air_asset_loss_recovery_meta_loop.gd`
- `docs/tasks/TASK_278_air_asset_loss_recovery_meta_loop.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_278_air_asset_loss_recovery_meta_loop.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_096_recovery_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_261_cross_screen_state_loss_playability_smoke.gd`
- [x] `git diff --check`

## Risiken
- Zu harte Folgen koennen Spieler bestrafen, bevor Systeme lesbar genug sind.
- Transportverlust darf keinen unloesbaren Spielstand erzeugen.

## Naechster Schritt
Nach TASK_278 kann TASK_279 LZ-Sicherung, Air-Asset-Bedrohung und Fireteam-Kommunikation in einem Missions-Smoke zusammenfuehren.
