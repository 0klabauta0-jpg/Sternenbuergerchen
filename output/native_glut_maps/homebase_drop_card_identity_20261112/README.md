# Heimat-Abflugkarten: Craftherkunft

Freeze: nur `_build_homebase_mission_drop_cards` in `scripts/meta/homebase_screen.gd`.
Vier vorhandene Definitionfelder werden konditional weitergegeben, ohne Defaults.
Keine Owner-, Producer-, Cargo-, Crew-, Timing- oder Rendereränderung.

Echter HomebaseScreen-Builder mit kontrolliertem Definition-/Pilot-/Portraitreader:
vollständige Herkunft/Kapazität und unveränderte Quelle; unveränderte bisherige
Pilot-/FT-/Payloadfelder; unbekannte Legacydefinition ohne Namensraten; neu
gelesene Starterdefinition ohne erfundene fehlende Kapazität/Asset-ID.

RED: `drop_card-e3b7bb9dd70247cb98e137214c74a68e/output.log` mit2/2.
GREEN: `drop_card-894bf00e769347bcb108598c3222d077/report.json` und `output.log`,
4/0, Godot4.6.2, Exit0, sauberes Log und echte vollständige Screenkompilierung.
Privates Projekt/Profil mit Canary; echtes Spielerprofil und geladene Quellen
unverändert. Keine native Darstellung/Gameplay-/Reise-/Performanceabnahme.

```powershell
python output/native_glut_maps/homebase_drop_card_identity_20261112/run.py
```

Aktueller Definitionsbefund: Flow `_build_homebase_aircraft_definition` liefert
craft_type, keine model_id/crew_capacity/visual_asset_id. Neue Kampagne ergänzt
ausdrücklich model_id=cutlass; Legacycheckpoint wird nicht umgedeutet. Deshalb
fehlen beim neuen Starter weiterhin crew_capacity und visual_asset_id. Das ist
gesonderte Herkunftsarbeit beim Definitionowner; dieser UI-Hook erfindet nichts.

Kein gemeinsamer Runner geändert. Keine Gitaufnahme/Commits, nur eigene Task/QA.
