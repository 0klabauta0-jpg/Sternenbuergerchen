# SternenBuergerchen: Grafik und Hex-Basis, 2026-11-01

Die Offline-HTML steht unter `docs/reports/STERNENBUERGERCHEN_GRAFIK_2026-11-01.html`.
Sie enthaelt echte native Ansichten, aktuelle 2D-Ziele, Quellen, offene
Differenzen und lokale Notizen/Entscheidungen mit JSON-Export.

## Start

In diesem Checkout `output/grafik_20261101/START_HEX_BASIS.ps1` ausfuehren.
Godot 4.6.2 muss als `godot_console.exe` oder `godot.exe` im PATH liegen.
Der Launcher importiert und startet `scenes/tests/frontier_art_preview.tscn`
mit Vulkan/Forward+. `-Capture` erstellt die sechs dokumentierten Ansichten.

Tasten: 1 Gesamtansicht, 2 Werkstatt, 3 Crew, G Hexraster, Leertaste Bewegung,
Mausrad Zoom, Linksklick Feldauswahl, Escape schliessen.

## Tatsaechlicher Stand

Erster synthetischer nativer Ausschnitt mit 396 Hexfeldern, drei neuen
Strukturmodellen und vier originalen Kenney-Astronauten. Koerper, Koepfe,
Proportionen, UVs, Gewichte und Texturen der Astronauten bleiben original;
nur einheitliche Skalierung und Export der originalen Idle-/Walk-Clips.
Die selbst gebauten Figurenstudien sind nach Nutzerkorrektur verworfen.
Kenney ist die vorlaeufige Grundlage: Ruestung, Ausruestung und etwas Aussehen
sollen spaeter weiterentwickelt werden. Die HTML beschreibt sechs konkrete
naechste Grafikschritte mit Referenz, sichtbarer Differenz und Vergleich danach.

Hex besitzt einen versionierten Daten-/Registry-/Pfad-/Bewegungs-/Sichtvertrag;
Darstellung und Auswahl verwenden dieselben Zellen. SimulationRoot bleibt
autoritaer. Bestehende Kampagnen, der Editor und sechsseitige Mauer-Inhalte
sind noch nicht vollstaendig migriert. Die Vorschau prueft keine Menschenmengen
oder Spaetspiel-Performance. Cutlass/Buccaneer sind vereinfachte 2D-Ziele;
die alten Rohgeometrie-Materialstudien sind nicht als Runtime-Modelle geeignet.

## Belege und Reproduktion

- `final_verification_manifest.json`: immutable Code-SHA, 14/14 strenge
  Godot-Laeufe, Capture-Hashes und genaue Grenzen.
- `engine_checks.json`: portables Manifest fuer den Godot-Verification-Runner.
- `frontier_engine_capture.json`: tatsaechlicher Renderer, Licht, Assets und
  Kameras der nativen Bilder.
- `hex_movement_verification.json`: 25/25 Assertions, zwoelf Richtungsversuche.
- `browser_qa/`: Browserfunktionstests, echte Exportdateien und Screenshots.
- `generation_manifest.json`, `generation_revisions.json` und
  `asset_source_manifest.json`: Bildgenerator-Herkunft, Revisionen, Quellen.
- `build_report.py`: Offline-HTML aus den Quelldaten erneut erzeugen.
- `next_art_steps.py` / `next_art_steps.json`: noch offene referenzbezogene
  Vorschlaege fuer Gelaende, Gebaeude, Ausstattung, Licht, Figuren und Schiffe.

Bilddateien bleiben als Original-PNGs unter `docs/reports/assets/`; die HTML
enthaelt kompakte WebP-Anzeigekopien. Externe rohe Schiffsmodelle und verworfene
Figurenstudien bleiben lokal erhalten und werden nicht als aktive Assets verteilt.
