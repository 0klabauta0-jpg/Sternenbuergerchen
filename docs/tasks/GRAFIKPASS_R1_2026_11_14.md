# Grafikpass R1: Kartenlook der Wüstenkarten

## Ziel / Problem
Die Wüstenkarten liegen sichtbar weit von den eigenen Zielbildern entfernt
(`referenzen-r2/03_Landschaft_Gebaeude`: `map_detail_proposal`,
`cliff_detail_proposal` rechte Variante, `03_aussenposten_stilstudie`).
Sichtbarster Abstand im nativen Bild: einheitlich orange Bodenfläche ohne
großräumige Variation, fast schwarze Hexlinien, Felswände mit Streifenmuster
statt gebrochener Flächen, weiß ausgebrannte Gebäudehüllen mit hellblauen Dächern.

## Sinnhaftigkeit / Ursache
- `quiet_tactical_surface` hat die Bodenvariation auf 2,5 % Helligkeit und 12 %
  Detail zurückgenommen (Reaktion auf das abgelehnte unruhige Bodenmuster). Damit
  fehlte auch jede großräumige Variation.
- Die Hexlinie der Wüstenkarten war `Color(0.13, 0.07, 0.025, 0.92)`.
- Die Dachaufhellung im Gebäude-Shader hob Petrol um den Faktor 1,46 an;
  cremefarbene Hüllen liefen in der Sonne ins Weiß.

## Umfang
Nur Darstellung, vier Dateien:
- `shaders/terrain/frontier_ground.gdshader`
  - `wind_drift`: großräumige, in Windrichtung gestreckte helle Sandbahnen und
    dunklere Rostflächen. Nur niedrige Frequenzen, keine Zellstruktur.
    Uniform `drift_strength` (Standard 0,8; 0 schaltet ab).
  - Nahbereich: schwache Windrippel, die vor der Übersicht ausblenden.
  - Ruhiger Modus: Krusten- und Kiesfelder vereinzelt statt flächig.
  - Wege: unregelmäßige Staubüberdeckung, etwas wärmerer Belag.
  - Felswände: `fracture_facets` (gebrochene Kluftflächen, gewählte rechte
    Klippenvariante), abgedunkelter Fuß, sonnengebleichte Krone.
    Uniform `rock_facet_strength`. Geometrie unverändert.
- `shaders/terrain/frontier_building_wear.gdshader`
  - Dachaufhellung 1,46 → 1,18 und schwächer gemischt.
  - Helle neutrale Hüllfarben Richtung Sandcreme, Blaugrün etwas tiefer.
- `scripts/terrain/frontier_art_profile.gd`
  - Wärmere Sonne, kühleres Himmelslicht, Sättigung 1,0, Belichtung 0,84.
  - Schatten-Bias der Heimatbasis auch im ruhigen Wüstenmodus (Streifen auf
    flachen Felskronen).
- `scripts/terrain/terrain_map_3d_view.gd`
  - Hexlinie nur im ariden Kontext rostbraun (`0.30, 0.125, 0.065, 0.74`
    bzw. regional `0.29, 0.13, 0.075, 0.68`).

## Betroffene Dateien
- `shaders/terrain/frontier_ground.gdshader`
- `shaders/terrain/frontier_building_wear.gdshader`
- `scripts/terrain/frontier_art_profile.gd`
- `scripts/terrain/terrain_map_3d_view.gd` (nur `_make_hex_grid_material`)
- `scripts/tests/grafikpass_r1_capture.gd` (neu, nur Aufnahmewerkzeug)
- `docs/qa/grafikpass_r1_20261114/` (neu)

## Basis
Branch `task/claude-grafikpass-r1-20261114` von `main` 03cdccc, nicht von
`integration/core-foundation`.

## Nicht-Ziele
- Keine Änderung an Kartenfakten, Höhen, Sichtlinien, Bewegung, Footprints.
- Keine neue Geometrie, keine neuen Modelle, keine Streuobjekte (Bewuchs sähe
  wie Deckung aus; siehe `docs/dev/nature_terrain_prop_rules.md`).
- GM01-Kartenrand bleibt `102c38` (abgesichert durch
  `gm01_frontier_map_edge_verifier`).
- Hexlinien behalten Deckkraft ≥ 0,65, Mindestbreite 1,8 px und Fernkontrast
  ≥ 0,65 (`review_completion_station_visual_verifier`).
- Grüne Karten (`ground_mission_mixed_v1`) und Orbitalstation unverändert.
- Keine UI-Änderung in dieser Runde.

## Relevante Verträge / Dokumente
- `docs/dev/graphics_reference_revision_contract.md`
- `docs/dev/terrain_truth_visual_audit_contract.md`
- `docs/dev/nature_terrain_prop_rules.md`
- `docs/tasks/MAP_SURFACES_AND_GROUND_SERVICES_2026_11_14.md` (ruhige Böden,
  große Felsformen behalten, keine weißen Sprenkel)

## Akzeptanzkriterien
1. Wüstenboden zeigt in Übersicht und Mittelzoom lesbare helle und dunkle
   Bahnen; Flächen dazwischen bleiben ruhig.
2. Hexraster bleibt in der taktischen Übersicht lesbar.
3. Felswände zeigen gebrochene Flächen statt Streifen; Felsformen unverändert.
4. Gebäudehüllen lesen cremefarben, Dächer petrol.
5. Nicht-aride Karten bleiben bildgleich.
6. Kein zuvor bestehender Verifier fällt neu aus.

## Lokale Prüfung
Renderer: `gl_compatibility` (llvmpipe), 1280×720, Godot 4.6.2, gleiche Kamera
vorher/nachher über `scripts/tests/grafikpass_r1_capture.gd`. Bilder und
Bewertung: `docs/qa/grafikpass_r1_20261114/`.

Verifier vor und nach der Änderung, jeweils `--headless`:

| Verifier | vorher | nachher |
|---|---|---|
| frontier_art_profile_verifier | 11/0 | 11/0 |
| frontier_main_environment_verifier | 11/0 | 11/0 |
| frontier_pass02_verifier | – | besteht |
| frontier_pass03_geology_verifier | besteht | besteht |
| frontier_pass07_paths_verifier | 23/0 | 23/0 |
| review8_graphics_verifier | besteht | besteht |
| review_completion_graphics_fixes | 519/0 | 519/0 |
| review_completion_station_visual_verifier | 158/0 | 158/0 |
| review_completion_building_material_verifier | – | 30/0 |
| gm01_frontier_map_edge_verifier | 51/0 | 51/0 |
| frontier_start_graphics_verifier | 28/0 | 28/0 |
| task_293_editor_lighting_shadow_readability_pass | – | besteht |
| frontier_pass06_environment_verifier | 1 Fehler | derselbe 1 Fehler |
| homebase_visual_coherence_verifier | 2 Fehler | dieselben 2 Fehler |
| frontier_runtime_map_slice_verifier | 5 Fehler | dieselben 5 Fehler |

Die drei letzten schlagen bereits auf `main` (03cdccc) fehl; die Fehlerlisten
sind vor und nach der Änderung identisch.

## Risiken / offene Punkte
- Nicht im Forward+-Renderer (D3D12) geprüft. Die Tönungen sind über
  `OUTPUT_IS_SRGB` für lineare Ziele umgerechnet, das Ergebnis muss aber im
  echten Spiel angesehen werden; SSAO kommt dort hinzu und dunkelt weiter ab.
- Auf `station_outpost_192x192` wirken die Bahnen kräftig. Feinregler ist
  `drift_strength` im Bodenshader.
- Shaderkosten: Boden plus sechs weiche Rauschabfragen je Pixel, Felswände
  plus eine 3×3-Zellsuche. Kein Profilerlauf auf Zielhardware; bei Bedarf
  `drift_strength` bzw. `rock_facet_strength` auf 0 setzen.
- Kein Gesamttestlauf; nur die oben genannten Darstellungs-Verifier.
- Nutzerurteil steht aus. Stand: separater Kandidat auf eigenem Branch, nicht
  in `main` integriert.

## Nächste Grafikschritte (Vorschlag, nicht umgesetzt)
- Geröll am Klippenfuß als Geometrie (Dreiecksbudget des Chunk-Caches beachten).
- Wege als Sandpisten mit weichen Rändern statt Hex-Kanten.
- Kartenrand der übrigen Karten: Dunst/Horizont statt Flächenfarbe.
- Stationswände und Heimatbasis-Module in die Creme/Petrol-Palette holen.
- Missions-HUD und Heimatbasis-Layout (eigene Runde).
