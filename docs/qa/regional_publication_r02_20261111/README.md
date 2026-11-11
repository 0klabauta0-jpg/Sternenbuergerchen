# Regionale Chunk-/FoW-Publikation — R02

11.11.2026. Isolierter bestehender Taskbranch task/native-glut-maps-20261110,
Basis85fd00afc. R02 wurde mit 7ef57c931 auf diesem Taskbranch gesichert; keine Main-/EXE-Freigabe.
Task: REGIONAL_NAV_PUBLICATION_R02_2026_11_11.md.

## Befund und enger Fix

Der echte native B-Bericht dokumentierte27–37ms in _publish_regional_chunks.
Das ist die visuelle Chunk-/FoW-Projektion, keine Pfadsuch- oder Navigations-
Eigentümerschaft. Eine zusätzliche Headless-Diagnose auf echter B mit6.912Tiles
und108Chunks zerlegte diesen Pfad: Overlay-Metadatenbau23,487–28,836ms,
Overlay-Rebuild0,951–1,843ms, Meshallokation0,051–0,081ms. Diese ersten Werte
entstanden bei parallel laufender Artarbeit und sind explorative Ursachen-
Eingrenzung, kein isolierter Vorher/Nachher- oder FPS-Nachweis.

Statische Overlay-Metadaten werden jetzt einmal mit jedem regionalen Chunk
vorbereitet, innerhalb dessen bereits begrenztem Baupfad. Publication führt
nur noch die vorbereiteten Arrays/Lookups/Bounds/Höhen zusammen. Die
wiederholten6912 Oberflächen-Geometrieabfragen fallen im warmen Publish auf0.
Es gibt keinen zusätzlichen Vorbereitungsjob und keine neue atomare Wechsel-
oder Blackoutlogik. Der bestehende Publish wechselt unverändert vollständig.

Der Cache enthält geordnete Tile-IDs, Tile-Referenzen, Sicherheitsbounds und
konservative Blackouthöhe. Kein Team, keine Sichtrevision, kein erkundet/
sichtbar-Zustand. Aktuelles Wissen wird weiterhin aus dem autoritativen
FoW-Snapshot in die Overlay-Slots geschrieben. Cacheeinträge leben exakt mit
Chunknodes, werden beim Retire entfernt und beim Map-Rebuild geleert.
Retained-Chunks können Metadaten mit ihrer vorhandenen Geometrie wiederverwenden;
der bestehende Retained-Grenzwert64 wird nicht erhöht.

Kalte Arbeit verschwindet nicht vollständig: Metadaten werden beim
budgetierten Chunkbau einmal berechnet. Dafür wird etwas zusätzliche statische
Metadatenhaltung je residentem Chunk benötigt. Keine globale Vollkarten-
Vorbereitung, keine Sichtweiten-/Detail-/Gegnerreduktion. A/B/C bleiben512×256.

## Gezielte Prüfungen

Godot4.6.2.stable.official.71f334935; ausschließlich headless Dummy-Renderer,
private APPDATA unter output/native_glut_maps/regional_publication_r02/profile.
Keine Nutzerstände und keine Live-Blender-Sitzung verwendet.

- Neuer regional_fow_publication_test: RED0/1 fehlender Cachepfad, GREEN13/0.
- Echter B-Ausschnitt, alle residenten Chunkcaches vorhanden.
-0 statt6912 wiederholte Oberflächenabfragen; ungecachter Oraclepfad besucht
 weiter alle Quelltiles. Exakt gleiche geordnete IDs, Lookups, Bounds/Höhe.
- Unexplored-Sicherheitshülle bis Overlayabschluss; neue Sichtrevision während
 Vorbereitung gewinnt. Kein Sichtwissen wird durch den statischen Cache ersetzt.
- Retire löst Cache, neu gebauter Chunk liest aktualisierte Quellhöhe,
 Mapwechsel entfernt alle alten Einträge und veröffentlicht nur Ersatztiles.
- Bestehendes native_glut_streaming_verifier headless3/0:
 Kameraumkehr, Retained-Revisit64, verstecktes Viewport.
- R4-FoW-Projektion29/0; TASK225Overlay/Kontakte34/0.
- Keine Script-/Enginefehler oder Leakwarnungen in diesen Läufen.

Keine neue breite Regression, deren Zusammenhang nicht betroffen wäre.
Headless-Prüfung ist kein Pixel-, nativer Schatten- oder Frameratebeweis.

## Isolierte CPU-Paarmessung

Root führte die eingefrorene Paarprobe nach ausdrücklicher Pause der parallelen
Blender-/Godot-Arbeiten aus. Zwölf AB/BA-Paare auf derselben echten B wechseln
zwischen107 und108 warmen Chunks. FoW-Füllung liegt außerhalb des Timers.
Headless-Dummy, identischer Prozess und unveränderte Kartendatei.

| Publish | Median | Maximum | Minimum |
| --- | ---: | ---: | ---: |
| Vorher85fd00afc |21,186ms |25,102ms |19,352ms |
| NachherR02 |3,7465ms |4,489ms |3,170ms |

Rohwerte: paired_cpu.json und paired_cpu.log; Berechnung: paired_summary.json.
Das ist ein CPU-Nachweis für die warme Publikation, kein GPU- oder Gesamt-FPS-
Nachweis. Native B-1×-Nachprüfung bleibt bis nach Art-/Importarbeit offen.

## Eingefrorene Paarquellen

paired_sources.zip enthält die tatsächlichen Before-/After-GDScript-Quellen,
nur globalen class_name entfernt. paired_sources.json bindet deren Hashes.
run_pair.py entpackt ausschließlich die zwei bekannten Einträge unter output,
prüft die Hashes und nutzt private APPDATA. So kann spätere Ressourcen-Cache-
Arbeit nicht unbemerkt in die R02-Messung geraten.

Die produktive Terrain-View-SHA zum historischen R02-Stand7ef57c931 ist
`e3d1d9f701f54d5b27edb4acea8b75c62bb2f99417fedc2d91ad902e998a1a61`.
Sie beschreibt ausdrücklich diesen Stand, nicht spätere Änderungen derselben Datei.
