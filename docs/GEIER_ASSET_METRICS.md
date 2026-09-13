# Geier / N3-Welt: lokale Asset- und Sichtprüfung

Stand: 13.09.2026. Blender 5.1.1, Godot 4.6.2, Windows/OpenGL Compatibility. Private Ableitung aus der vom Nutzer bereitgestellten Vulture-Datei; keine Behauptung einer Weiterverbreitungslizenz. Die Originaldatei wurde nicht verändert. `assets/local/` bleibt Git-ignoriert.

## Quelle und reproduzierbare Ableitung

- Quelle: `C:/Users/bjoer/3D Objects/drive-download-20250521T120706Z-1-001/DRAKE/DRAKE-VULTURE.obj`
- SHA-256: `a182080cf1d711b4e4731fa2760ac84bc3bc65acdc84fde6512f8df6278c2ef2`
- Converter: `tools/prepare_geier.py`
- Ausführung: Blender 5.1 `--background --factory-startup --python tools/prepare_geier.py`
- GLB: `assets/local/geier/geier.glb`
- Blender-Datei: `assets/local/geier/source/geier.blend`; `source/.gdignore` verhindert den Import der Studio-Szene.
- Vorschau: `assets/local/geier/preview.png`
- Maschinenlesbare Messungen: `assets/local/geier/metrics.json`, `source-inspection.json`

| Kennzahl | Original | Spielableitung |
|---|---:|---:|
| Mesh-Objekte | 1 | 1 |
| Vertices | 510.088 | 8.914 vor Export |
| Dreiecke | 999.904 | 17.998 |
| Materialien | keine definiert | 4 |
| Export-Vertices einschließlich harter Normalen-/Materialgrenzen | — | 53.922 |
| GLB-Dateigröße | — | 1.405.988 Byte |

Die Geometrie wurde auf knapp acht Meter Länge normiert, verschweißt, voxelbereinigt, geglättet und auf rund 18.000 Dreiecke reduziert. Vier flache Materialfarben markieren Rumpf, Unterseite, Bergungsarme und Cockpit. Godot-Abmessungen des unverzerrten GLB: X 3,833 m, Y 2,097 m, Z 7,976 m; unten Y=0, vorwärts -Z. Die Weltansicht skaliert Schiffe einheitlich und verwendet den bestätigten `ship.model`-Wert. In einem Checkout ohne private Modelle greifen die mitgeführten Kenney-Modelle; `ResourceLoader.exists` unterstützt auch importierte Ressourcen in einem PCK.

Blender hat das exportierte GLB erneut importiert, die gespeicherte `.blend` wieder geöffnet und vier Materialien sowie 17.998 Dreiecke bestätigt. Die erneute Prüfung der Originaldatei ergab denselben Hash. Die Vorschau wurde visuell geprüft. Eine echte Godot-Fensterprobe hat den Geier durch reguläres Erz-/Legierungsverkaufen und anschließendes Mieten erreicht.

## N3-Weltprüfung

`scripts/world/world_ground_probe.gd` nutzt die echte `scenes/game.tscn` mit neuem isoliertem Spielstand. Der vollständige Fensterlauf bestätigte **92 Prüfungen, keine Fehler**: Rüstung herstellen/anlegen, Auftrag, Radarsuche, getrennte Erz-/Wrackbergung, Verkauf, Geier-Miete, Reisen, Gegnerauswahl per Physikstrahl, Kämpfe, Aufzug, Bunkerbergung und je Karte identische Katalog-/Darstellungsrechtecke. Nur die aktive Karte ist angehängt. Ein anschließender kurzer `--armor-only`-Lauf bestätigte neun Prüfungen ohne Fehler und erneuerte die Nahaufnahme von vorn.

Belege unter `output/ground-world/`: `world-results.json`, jeweiliger Snapshot als JSON und unveränderte echte Viewport-PNGs:

- `armor.png`: Ida mit Brust-/Schulterteilen an drei Animationsknochen; Jaro ohne nachgerüstete Panzerung.
- `geier.png`: durch regulären Handel finanziertes Mietschiff auf dem Stationspad.
- `rust-mining.png`, `rust-wreck.png`: getrennte, zuvor unbekannte Fundstellen.
- `bunker-surface.png`, `bunker-depths.png`: Außenanlage und eigenständiges Untergeschoss.
- `distribution.png`: Hallen, Funktionsgassen, Sicherheitsbereich und Bergedock im Gesamtüberblick.
- `tradepost.png`, `tradepost-landscape.png`: kleiner Handelsposten mit großem Umfeld.

Überlappende Wege-/Grundplatten wurden zu einer einzigen, farblich gegliederten Fläche vereinigt. Für prozedurale Frontwände wird die tatsächlich wirksame `material_override` transparent; die begehbaren Türöffnungen bleiben sechs Meter breit. Die Kamera hat eine feste Blickrichtung von +X/+Z, daher sind die entsprechenden Vorderwände ausgeblendet. Kampf-/Ressourcenwerte bleiben im Core. Schussspuren lesen bestätigte Cooldown-/Schadensänderungen; sie berechnen keine Treffer oder Belohnungen.

### Begrenzte Framezeit-Stichproben

Je drei Sekunden bei unverändertem bestätigtem Snapshot, 1440 × 900, 225 Frames nach 0,35 s Aufwärmzeit. Gemeinsamer Desktop/GPU, ungefähr 75-Hz-Begrenzung; dies ist kein Leistungsversprechen für andere Geräte, laufende Großkämpfe oder eine ganze Kampagne.

| Sicht | p95 Frameabstand | Nodes | Objekte | Draw Calls |
|---|---:|---:|---:|---:|
| Rostwelt / Mining | 13,484 ms | 456 | 2.762 | 198 |
| Bunkeroberfläche | 13,432 ms | 416 | 2.647 | 510 |
| Untergeschoss | 13,640 ms | 418 | 2.649 | 613 |
| Distribution | 13,533 ms | 541 | 2.976 | 1.022 |
| Handelsposten / Umfeld | 13,448 ms | 364 | 2.543 | 686 |

## Gestaltungsquellen

Eigene vereinfachte Module, keine übernommene Star-Citizen-Geometrie oder Textur der Einrichtungen. Offizielle Referenzen: [Inside Star Citizen: Distribution Allocution](https://www.youtube.com/watch?v=8VKzP-T8mIA), [RSI Monthly Report März 2024](https://robertsspaceindustries.com/en/comm-link/transmission/19869-Star-Citizen-Monthly-Report-March-2024), [RSI Further Underground](https://robertsspaceindustries.com/en/comm-link/transmission/18960-Inside-Star-Citizen) und das [offizielle Underground-Konzeptposting](https://twitter.com/RobertsSpaceInd/status/1591521557087657985). Das [CIG-Lobbybild](https://starcitizen.tools/File:Crusader_Industries_Distribution_Center_Lobby_-_March_2024_Monthly_Report.webp) ist über einen Wiki-Spiegel mit nachvollziehbarem RSI-Quellnachweis verfügbar. Abgeleitet wurden getrennte Funktionsbereiche, klare Torrahmen, offene Ladehöfe und eine zentrale Liftachse; Umfang und Navigation folgen dem N3-Vertrag.
