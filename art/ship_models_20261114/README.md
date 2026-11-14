# Fuenf Schiffmodelle — Blender-Kandidaten vom 14.11.2026

## Auftrag und Stand
Prospector, Vulture, Caterpillar, Gladius und die vorhandene F7C-Hornet-Quelle
werden aus den lokalen Benutzerdateien aufbereitet. Je Schiff liegen eine
editierbare `.blend` und ein `.glb` im gleichnamigen Unterordner.
Die binaeren Modelle und Bildnachweise bleiben lokal; dieses oeffentliche
Repository erhaelt Werkzeuge, Quellen-/Messprotokolle und Dokumentation.

Dies sind separate Modellkandidaten. Keine Integration in das laufende Spiel,
keine EXE, keine Gameplay-Abnahme. Die gemeinsame Blender-MCP-Sitzung wurde
nicht verwendet. Alle Blender-Aufrufe liefen im eigenen Background-Prozess
mit Factory-Startup und zwei Threads; die Originale wurden nur gelesen.

## Quellen
Basis: `C:/Users/bjoer/3D Objects/drive-download-20250521T120706Z-1-001/`
und `...-1-002/`. Genaue Dateien und SHA-256 stehen je Schiff in
`source_manifest.json` beziehungsweise `caterpillar/metrics.json`.
Das lokale `[Readme] & CTM Model Links.docx` nennt Purrfect Blinky als
Konvertierer der RSI-Modelle. Es wird keine eigene Urheberschaft oder
Weiterverbreitungslizenz fuer diese Schiffentwuerfe behauptet.
Der Dateiname `ANVIL-HORNET` legt die Variante nicht eindeutig fest; verwendet
wurde die vom Nutzer bestaetigte vorhandene Quelle, keine Mk-II-Neubeschaffung.

## Massstab, Orientierung, Farben
Wie im archivierten Buccaneer-/Cutlass-Ablauf: Laenge fuer das Authoring auf
8 Einheiten normiert, Unterseite auf Bodenhoehe 0. Dies sind **keine kanonischen
Schiffsmasse**. Vor Spieleinbau pro Schiff den Zielmassstab einstellen.
Blender Z-oben, Nase -Y; GLB/Godot Y-oben, Nase +Z passend zum heutigen Ref03-Pfad.
Die Rohdateien liefern keine nutzbaren Originaltexturen. Die einfachen
Farbmaterialien sind neu zugewiesene Vorschaufarben, kein originales Paintset.

## Reduktion und Nachweise
Vorbild: archivierte `prepare_shuttle.py`, `prepare_freibeuter.py`,
`prepare_geier.py` im Neustart-Archiv vom 11.11.2026. Angepasster Ablauf:
Schweissen -> Voxelhuelle -> leichte Glaettung -> direkte Collapse-Reduktion ->
frischer Meshdatenblock -> kleine Geometriefragmente entfernen -> Normalen -> UV.
Planarer Dissolve **nach** Voxel wurde verworfen: gefaltete Polygone beschaedigten
die resultierende Topologie. Keine X-Symmetrie erzwingen.

`qa/source.png` und `qa/candidate.png` zeigen dieselbe Original-/Kandidatenkamera.
`qa/material.png`, `qa/wire.png` und `qa/parts.png` zeigen den echten Kandidaten.
Caterpillar hat eigene gleichnamige Mehransichten im Schiffordner.
`qa/geometry.json` enthaelt rohe Asset-QA; `metrics.json` bindet Polygonzahlen,
Bounds, Source-Unveraendertheit und GLB-/Blend-Roundtrip.
`godot_probe/` ist ein eigenes minimales Engineprojekt, das die tatsaechlichen
GLBs unabhaengig importiert. Headless- und native Bildnachweise sind getrennt.

## Caterpillar
Klappen und Aufzug duerfen beim Folgeeinbau nicht mit `Hull` verschmolzen werden.
Die seitlichen Klappen werden aus der echten Quellhaut getrennt und erhalten
eigene Scharnierpivots. Ein neu konstruiertes Liftdeck mit Fuehrung ist als
Kandidat markiert. Der Bewegungsclip demonstriert nur die Geometriebewegung;
Kollisionen, tragfaehiger Frachtraumboden, Personen-/Frachttransport und
autoritative Gameplay-Ansteuerung sind spaetere Integrationsarbeit.
Die quellgetreue Liftkonstruktion ist durch dieses Modell nicht belegt.

## Reproduktion
Blender lokal: `C:/Program Files/Blender Foundation/Blender 5.1/blender.exe`.
Aus diesem Worktree:

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.1/blender.exe' --background --factory-startup --threads 2 --python-exit-code 1 --python art/ship_models_20261114/tools/prepare_ships.py -- prospector --stage inspect
& 'C:/Program Files/Blender Foundation/Blender 5.1/blender.exe' --background --factory-startup --threads 2 --python-exit-code 1 --python art/ship_models_20261114/tools/prepare_ships.py -- prospector --voxel 0.035
```

Andere Parameter: Vulture `.025`, Gladius `.018`, Hornet `.022`.
Die Blender-QA-Werkzeuge werden aus den lokal installierten Skills geladen.
Das Caterpillar-Skript verarbeitet jedes Bewegungsteil separat.
Siehe `godot_probe/README.md` fuer unabhaengigen Import und native Aufnahmen.

## Arbeitsbasis
Eigener Branch `task/ship-model-preparation-20261114` ab
`integration/core-foundation` (`3cae5a216`, Auguststand), nur neues Assetpaket.
Das November-Gameplay und fremdes Grafik-/Playtest-WIP wurden nicht geaendert.
Aktuelle Grafikcontracts wurden im Hauptarbeitsbereich gelesen; die Modelle
sind damit nicht automatisch in dessen Spielstand integriert.
