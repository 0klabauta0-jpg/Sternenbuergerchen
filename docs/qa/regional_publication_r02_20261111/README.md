# Regionale Chunk-/FoW-Publikation — R02

11.11.2026. Isolierter bestehender Taskbranch task/native-glut-maps-20261110,
Basis85fd00afc. Noch keine Commits/Pushes oder native Freigabe durch Teilagent.
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

## Noch ausstehende Messung / Wiederholung

Eine Paarprobe ist vorbereitet: compare_publication.gd verwendet eine
unveränderte Before-Kopie aus85fd00afc (nur globalen class_name entfernt,
damit beide Versionen im selben Testprozess geladen werden), die aktuelle
After-Quelle und dieselbe echte B. Zwölf AB/BA-Paare wechseln zwischen107 und
108 bereits residenten Chunks; komplette FoW-Füllung liegt außerhalb des
Publikationstimers. Vorherquelle ist als terrain_view_before.gd in diesem QA-Ordner erhalten;
die archivierte Paarprobe lädt diese explizit. Erst nach exklusiver Root-
Freigabe ausführen; bisher bewusst nicht parallel zu Astra-Rendern gestartet.

Native B-1×-Nachprüfung und belastbare Gesamtframerate bleiben beim Root,
nach Ende der Art-/Importarbeit. Die beobachteten Spiel- und Kartenfakten
werden durch den Fix nicht geändert. Kein Main-/EXE-Schritt.

## Eingefrorene Paarquellen
Root hat beide tatsächlichen Terrain-View-Quellen separat als
terrain_view_before.gd (85fd00afc) und terrain_view_after.gd (R02) archiviert,
nur globalen class_name entfernt. Die Paarprobe lädt diese Kopien, damit
spätere Ressourcen-Cache-Arbeit nicht versehentlich in diese Messung gerät.
Die produktive Source-SHA zum R02-Stand ist
e3d1d9f701f54d5b27edb4acea8b75c62bb2f99417fedc2d91ad902e998a1a61.
Messung weiterhin ausstehend; keine CPU-/GPU-Freigabe vorweggenommen.

Die beiden großen GDScript-Snapshots sind platzsparend in paired_sources.zip
mit Hashliste paired_sources.json erhalten. run_pair.py entpackt ausschließlich
die zwei bekannten Einträge nach output/native_glut_maps/regional_publication_r02,
prüft ihre Hashes und startet die Probe mit privater APPDATA. Vor Ausführung
exklusives CPU/GPU-Fenster koordinieren. Globale Art-/Quellenänderungen nach
R02 werden damit nicht unbemerkt in diese isolierte Paarprobe aufgenommen.
