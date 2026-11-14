# Polisar R09, Windbruch 512 × 256, GM02 neu (14.11.2026)

Auftrag von Björn im Grafik-Chat. Branch `task/claude-polisar-windbruch-region-20261114`, Basis `origin/main` `742f36c1`.

## Ziel / Problem

1. Die Stationskarte Polisa soll dem annotierten Zielbild näherkommen: größere, auf die Achse zentrierte Ringe mit Streben, verlängerte Achse, Solarflügel links, vier Tanks rechts, Docks weiter außen, kompaktere Pads, größerer Innenbereich, hintere Hälfte als Dekoration hinter der Kartengrenze.
2. Die Karte Windbruch (Kampagnenort „Gesicherter Außenposten“) war 88 × 72 groß; die anderen Kampagnenorte sind 512 × 256.
3. GM02 (`Ground_Mission02_128x128`) war eine alte Karte im gemischten Thema mit einem Block aus Stationsbodenteilen und soll neu gebaut werden.

## Umfang

- **Polisar R09:** neues Layout, daraus Karte, Fakten und ein in Blender gebautes Modell; Einbindung als Stationsdarstellung. Details und Messwerte: `art/polisar_r09_20261114/README.md`.
- **Windbruch:** Der Kern bleibt an seinen Zellen (0..87, 0..71). Darum liegt die Region als odd-r-Rechteck ab (−200, −90): Flusstal, fünf Pisten, 34 automatisch gesetzte Regionalrampen, vier Nebenorte (Absturzfeld West, Bohrstelle Ost, Horchposten Nord, Altfeld Süd mit drittem Pad). Der alte Rechteckrand ist in Buchten aufgelöst. Detaillierte Klippen bleiben im Kern über das neue Kartenfeld `place_presentation.cliff_detail_bounds`.
- **GM02 „Relay Ridge“:** neuer Generator `tools/build_ground_mission02.py`. Raster (128 × 128 axial), Marker, Patrouillenrouten und Gegnerdaten kommen unverändert aus der alten Karte; das Szenario bleibt, wie es ist. Relais auf einem Felsplateau, zwei Landefelder mit Pads, Straße über zwei Rampen, Pfade über zwei Seitenrampen, Trockenbett.

## Nicht-Ziele

Keine Änderung an Docking, Shuttle, Rekrutierung, Reise, Wegfindung oder Savegames. Keine Dachlogik. Keine Umbenennung der Code-ID `polisa`. Kein EXE-Build.

## Relevante Dokumente

`AGENTS.md`, `docs/dev/graphics_reference_revision_contract.md`, `POLISAR_BLENDER_AUFTRAG.md` und `RAUMKARTEN_RECHERCHE.md` (Übergabepaket `visual-targets-20261114`), `docs/tasks/GRAFIKPASS_R3_WINDBRUCH_2026_11_14.md`, Projektnotiz „Abstimmung Bedienung und Grafik“.

Abweichung vom Blender-Auftrag: Er verlangt einen separaten Kandidaten ohne Einbindung. Björn hat im Chat ausdrücklich die Karte selbst beauftragt und „direkt mergen, pushen“ gesagt; deshalb ist R09 eingebunden.

## Betroffene Dateien

- Polisar: `art/polisar_r09_20261114/*`, `Assets/curated/polisar_r09_20261114/polisar_station.glb`, `maps/polisa_station.json`, `tools/build_polisa_station.py`, `scripts/terrain/polisa_station_visual.gd` (neu geschrieben), `scripts/mission/polisa_station_craft_runtime.gd` (nur `LAYOUT_PATH`), `scripts/tests/polisa_globe_map_verifier.gd` (nur Pfad).
- Windbruch: `tools/build_windbruch_outpost.py`, `maps/windbruch_outpost.json`, `scripts/terrain/terrain_map_3d_view.gd` (`_cliff_detail_bounds`, `_cliff_detail_applies`), `scripts/tests/windbruch_outpost_verifier.gd`, `scripts/tests/grafikpass_r123_navigation_verifier.gd` (Zellzahl).
- GM02: `tools/build_ground_mission02.py`, `maps/Ground_Mission02_128x128.json`, alte Karte umbenannt in `maps/Ground_Mission02_128x128_legacy_theme_fixture.json`, `scripts/tests/ground_mission02_relay_ridge_verifier.gd` (neu), `scripts/tools/generate_ground_mission02_128x128.gd` (schreibt nur noch die Fixture).
- Belege: `docs/qa/polisar_windbruch_gm02_20261114/`.

## Geänderte Testerwartungen (bewusst)

- `windbruch_outpost_verifier`: 131 072 Zellen, 240 Rampenzellen, drei Pads.
- `grafikpass_r123_navigation_verifier`: 131 072 statt 6336 Zellen. Der Test braucht die native Erweiterung und lief hier nicht.
- `task_413_terrain_theme_packs_ground_mission_variant`, `review_completion_station_visual_verifier`, `review_completion_cliff_station_revision_verifier`: Sie nutzten GM02 als Beispiel für das gemischte Thema bzw. für eine nicht-aride Karte und lesen jetzt die Fixture. Im Cliff-Test steht das neue GM02 zusätzlich als aride Karte.

## Lokale Prüfung (Godot 4.6.2, Linux, headless, ohne native Erweiterung)

| Prüfung | Ergebnis |
| --- | --- |
| `windbruch_outpost_verifier` | 41 / 0 |
| `ground_mission02_relay_ridge_verifier` | 35 / 0 |
| 34 Polisa-Verifier (`polisa_*`, `campaign_polisa_help`) | 27 bestehen, 7 schlagen fehl – dieselben 7 mit denselben Meldungen wie auf `742f36c1` vor der Änderung |
| `polisa_actual_station_collision_verifier` im Einzelnen | 11 Fehlschläge vorher und nachher, zeilengleich |
| `review_completion_station_visual_verifier` | 158 / 0 |
| `review_completion_hex_surface_verifier` | 246 / 0 |
| `frontier_art_profile_verifier` | 11 / 0 |
| `task_413_…` | 65 / 1; der eine Fehlschlag („Theme renders Nature ground visuals“) besteht hier auch mit der alten Karte |
| `review_completion_cliff_station_revision_verifier` | 3357 / 2; beide Fehlschläge (Wand-/Tür-Ensembles der Stationskarten) bestanden schon vorher |
| Offline-Prüfungen des Polisar-Layouts (`build_candidate.py`) | alle wahr, eine zusammenhängende begehbare Fläche |
| Achsprüfung am Modell | Ringmitten und Achse deckungsgleich |

Nicht gelaufen: `grafikpass_r123_surface_verifier` und `review_completion_map_preparation_verifier` (Prozess hier wegen Speicher beendet), alles mit nativer Erweiterung, das laufende Spiel.

## Risiken / offene Punkte

- Nichts davon ist im Spiel unter D3D12 gesehen worden. Bei R1–R3 hat Codex beim Einbau vier Fehler gefunden, die hier nicht sichtbar waren.
- Polisar: Landung, Shuttle und Rekrutierung hängen an Pad-Markern und Zellen, die sich verschoben haben. Die Verifier sehen keinen Unterschied zum Stand davor, ein Durchlauf im Spiel fehlt.
- Polisar: Drawcalls 28 → 108, Dreiecke 23 388 → 45 680; nicht profiliert.
- Windbruch: Die Regionalrampen sind automatisch gesetzt und nur auf Erreichbarkeit geprüft, nicht auf Spielgefühl. Der Kern ist nicht mehr von Fels umschlossen; Gegner und Spieler haben zusätzliche Zugänge.
- GM02: Die Luftabwehr ist nur Marker und Deckung, es stehen keine Geschützmodelle mehr auf der Karte. Der alte Test verlangte drei „Space Kit“-Geschütze; ob sie spielerisch gebraucht werden, ist nicht geprüft.
- Die alte GM02-Karte liegt als Fixture weiter im Repo, weil drei Tests das gemischte Thema an ihr prüfen.
