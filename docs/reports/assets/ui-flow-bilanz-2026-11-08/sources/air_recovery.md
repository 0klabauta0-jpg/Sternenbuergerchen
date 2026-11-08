# Air Asset Loss Recovery Meta Loop

## Scope
TASK_278 verbindet den Mission-AirAssetStatus aus TASK_277 mit dem Meta-Layer. Ein beschaedigtes oder verlorenes Dropship/Frachter-Asset wird nicht nur als Explosion behandelt, sondern erzeugt einen sichtbaren, zeitgebundenen Recovery-Zustand in Debrief, Homebase und FOB.

## Meta-Zustaende
- `craft_available`: Asset ist wieder einsatzbereit.
- `damaged_repairing`: Asset ist in Reparatur und kann nicht starten.
- `destroyed_replacement_pending`: Ersatzbeschaffung laeuft; das Asset bleibt bis ETA blockiert.
- `pilot_safe_homebase`: Pilot ist sicher zurueck in der Heimatbasis.
- `pilot_injured_recovering`: optionaler Pilot-Recovery-Zustand fuer spaetere Balance.

`AirAssetRecoveryState` erzeugt diese Zustaende aus `AirAssetStatus` und haelt `runtime_authority = "MetaLayerFlow"` sowie `ui_sets_gameplay_truth = false`.

## Meta-Pfad
1. Mission Controller/SimulationRoot liefern `air_asset_status`.
2. `MetaLayerFlow._build_mission_result()` uebernimmt den Status in das Missionsergebnis.
3. `MetaLayerFlow` baut daraus `air_asset_recovery` und schreibt den Craft in den Homebase-Recovery-Pool.
4. Debrief zeigt Verlust/Reparatur und ETA.
5. Homebase und FOB Flightdeck zeigen denselben Recovery-Status; Board/Send/Start sind blockiert.
6. `advance_air_asset_recovery_time()` oder der bestehende Transport-Timer laesst die ETA laufen.
7. Nach Ablauf kehrt der Status zu `craft_available` zurueck.

## Softlock-Schutz
Recovery-Zustaende enthalten `softlock_guard = true` und `can_recover = true`, solange sie aktiv sind. Der Spieler wird dadurch nicht dauerhaft weichgesperrt: Reparatur/Ersatz laufen zeitbasiert aus, und Homebase kann weiterhin weitere Craft-Typen anlegen.

## Persistenz
`MetaLayerFlow.get_air_asset_recovery_snapshot()` und `load_air_asset_recovery_snapshot()` halten Craft-ID, Pilot-ID, Meta-State, ETA und eingebetteten `AirAssetStatus` screenwechsel-stabil. Die UI liest diese Snapshots nur.

## UI-Regeln
- Debrief: kompakte Air-Asset-Zeile mit Verlust/Reparatur und Pilotstatus.
- Homebase: Flightdeck-Status nennt Reparatur/Ersatz-ETA; Send/Clear/Cargo-Aktionen sind blockiert.
- FOB: Flightdeck zeigt Recovery-ETA und blockiert Boarding/Missionsstart.
- Help: `fob.flightdeck` erklaert, dass beschaedigte/verlorene Assets bis Recovery-Ende nicht verfuegbar sind.
