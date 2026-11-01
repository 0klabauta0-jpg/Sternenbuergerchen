# SternenBuergerchen: Grafik und Hex-Basis, 2026-11-01

Die Offline-HTML steht unter `docs/reports/STERNENBUERGERCHEN_GRAFIK_2026-11-01.html`.
Sie enthaelt echte native Ansichten, aktuelle 2D-Ziele, Quellen, offene
Differenzen und lokale Notizen/Entscheidungen mit JSON-Export.

## Start

In diesem Checkout `output/grafik_20261101/START_HEX_BASIS.ps1` ausfuehren.
Godot 4.6.2 muss als `godot_console.exe` oder `godot.exe` im PATH liegen.
Der Launcher importiert und startet `scenes/tests/frontier_art_preview.tscn`
mit Vulkan/Forward+. `-Capture` erstellt sieben Pass02-Ansichten.

Tasten: 1 Gesamtansicht, 2 Werkstatt, 3 Crew, 4 Gelaende, G Hexraster, Leertaste Bewegung,
Mausrad Zoom, Linksklick Feldauswahl, Escape schliessen.

## Tatsaechlicher Stand

Pass02 des synthetischen nativen Ausschnitts mit 396 Hexfeldern: geschichtete
Klippen, Fels-/Pflanzengruppen, markierte Wege und Landeflaeche, neues Licht,
drei ueberarbeitete Gebaeude und vier modulare Ausruestungskandidaten auf
unveraenderter Kenney-Grundfigur mit originalen Idle-/Walk-Clips. Die frueheren
eigenen Citizen-Koerper bleiben verworfen. Neue Kandidaten sind keine bereits
erfolgte gestalterische Nutzerabnahme.

Vier Vorher-/Nachher-Paare haben dieselben festen Kameras/1600x900 und denselben
Renderer; Licht und dargestellte Assets wurden bewusst ueberarbeitet. Vorher
bleibt bytegleich unter `engine_pass02/before`, Nachher unter `engine_pass02/after`.
Eine neue weite Gelaendeansicht hat kein vorgetaeuschtes Vorher-Gegenstueck.
Die drei ergaenzten Nutzerreferenzen und acht historische Kontextbilder sind
mit Herkunft/Hashes katalogisiert; Quadratfelder im Kartenbild aendern Hex nicht.

Hex besitzt einen versionierten Daten-/Registry-/Pfad-/Bewegungs-/Sichtvertrag;
Darstellung und Auswahl verwenden dieselben Zellen. SimulationRoot bleibt
autoritaer. Bestehende Kampagnen, der Editor und sechsseitige Mauer-Inhalte
sind noch nicht vollstaendig migriert. Die Vorschau prueft keine Menschenmengen
oder Spaetspiel-Performance. Cutlass/Buccaneer sind vereinfachte 2D-Ziele;
die alten Rohgeometrie-Materialstudien sind nicht als Runtime-Modelle geeignet.

## Belege und Reproduktion

- `pass02_verification_manifest.json`: aktueller Code-SHA, 15/15 strenge
  Engine-Laeufe, vier Bildpaare, sieben native Aufnahmen und genaue Grenzen.
- `engine_checks_pass02.json` und `pass02_check_runs/`: aktuelle Verifier.
- `pass02_before_capture.json` / `pass02_after_capture.json`: Kameras,
  Renderer, Licht und Modell-/Quellenhashes.
- `reference_manifest.json`: drei aktuelle + acht historische Bildquellen.
- `browser_qa_pass02/`: neuer Browsernachweis fuer den Pass02-Vergleich.

Die folgenden Belege dokumentieren den erhaltenen Pass01:

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
