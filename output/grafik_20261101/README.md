# SternenBuergerchen: Grafik und Hex-Basis, 2026-11-01

Die Offline-HTML steht unter `docs/reports/STERNENBUERGERCHEN_GRAFIK_2026-11-01.html`.
Sie enthaelt echte native Ansichten, aktuelle 2D-Ziele, Quellen, offene
Differenzen und lokale Notizen/Entscheidungen mit JSON-Export.

## Start

In diesem Checkout `output/grafik_20261101/START_HEX_BASIS.ps1` ausfuehren.
Godot 4.6.2 muss als `godot_console.exe` oder `godot.exe` im PATH liegen.
Der Launcher importiert und startet `scenes/tests/frontier_art_preview.tscn`
mit Vulkan/Forward+. `-Capture` erstellt20 aktuellePass05-Umgebungsansichten.

Tasten: 1 Gesamtansicht, 2 Halle, 3 Crew, 4 Gelaende, 5 Basis,
6 Aussenposten, 7 Cutlass, 8 Buccaneer, 9 Versorgung,
0 Arbeitsbereiche, C geschlossene Aussenhuelle / Schnittansicht, G Hexraster, Leertaste Bewegung,
Mausrad Zoom, Linksklick Feldauswahl, Escape schliessen.

## Tatsaechlicher Stand

Aktuell Pass05 Umgebung: referenzgefuehrte Formhierarchie, differenzierte
Gebaeudehuellen, lokale Felsbrueche und bewusst gruppierte Arbeitsbereiche.
Die vollstaendige Analyse steht unter docs/reports/FRONTIER_UMGEBUNG_ANALYSE_2026-11-01.md.
Neun feste P4/P5-Kamerapaare und20nativeBilder belegen den wirklichen Stand;
lived_outpost/ground_detail/geology_detail sind zusaetzliche Nahansichten
mit eigener Kamera, keine vorgetaeuschten Vorher/Nachher-Paare.

Drei originale Kenney-Props bleiben geometrisch unveraendert, ihre eigenen
Instanzmaterialien erhalten eine duplizierte warme Toennung. Vier bisherige
Citizens sind neu angeordnet/gedreht; kein zusaetzliches Civilian-/AI-System.
Die gekennzeichnetenR02-Schiffe bleiben unveraenderte kritisierte Zwischenstaende,
weitere Modellarbeit laeuft separat beiAstraUltra/pass05_astra_ultra.

Aktuelle Belege: pass05_environment_verification_manifest.json,
engine_checks_pass05_environment.json,pass05_environment_check_runs/,
pass05_environment_*_capture.json und browser_qa_pass05_environment/.
18/18strengeGodot-Prueflaeufe,21/21eigeneGebaeudegeometrie,12/12Geologie,
19/19Umgebungs-/Platzierungsfakten. ExakteSource-/Gitblob-/PNG-Hashes
sowie die verbleibenden2D-Differenzen stehen in den Manifesten.

Die folgende Beschreibung dokumentiert den erhaltenenPass04:

Pass04/R02 des synthetischen nativen Ausschnitts mit396Hexfeldern:
Kenney-basierte Cutaway-Basis/Halle mit Gebrauchsfeldern, neue tragende
Doppeltankanlage statt altem Serviceaufbau/Lader, zwei flache gefaste Pads
und vereinigte matte Servicewege. Zusaetzliche eigene Godot-Aussenhuellen
zeigen beide Gebaeude geschlossen mit Dachschraegen, Fenster-/Torreihen,
Luefter und wenigen Nieten. C schaltet nur die Darstellung um.

Nach ausdruecklicher Nutzerablehnung der R01-Schiffe folgen zwei weitere
Form-/Look-Iterationen je Schiff: Cutlass und Buccaneer mit neu geformten
Rumpf-/Kanzel-/Motor-/Fluegelgruppen, breiten Fasen und sparsamen Anschluessen.
Die Schiffsmasse sind bewusst stilisiert, keine kanonischen SC-Masse.
Auch R02 bleibt laut Nutzer zu weit vom2D-Ziel entfernt. Diese Schiffe sind
ausdruecklich kritisierte technische Zwischenstaende. Die weitere Blender-
Modellarbeit ist an den angeforderten Astra-Ultra-Nebenchat
01a197d8-ebd0-7100-8d12-21ff6bc52c0d ausgelagert (pass05_astra_ultra).
Originale Kenney-Citizens und Ausruestung aus Pass02 bleiben unveraendert.

Sechs Vorher-/Nachher-Paare verwenden identische Kameras, Licht und1600x900.
Pass03 bleibt bytegleich unter engine_pass04/before. Neue Schiff-/Utility-/
Aussenposten-/geschlossene Ansichten haben keine vorgetaeuschten Vorherbilder.
Die vom Nutzer abgelehnten R01-Schiffbilder bleiben getrennt erhalten.

Die Felsen erhalten mehr gebrochene Lippen und die kleinen Steine ungleiche
angefaste Koerper;55Gesteinsgruppen-Meshes mit21744Vertices bleiben in den
urspruenglichen14Navhuellen. Boden/Wege erhalten weiche Sediment-/Pigmentfelder.
Hex/Registries/SimulationRoot behalten die autoritative Karten-/Bewegungswahrheit.
Keine Flug-/Betankungs-/Innenraum-/Tor-/Wirtschaftsmechanik, keine Kampagnen-
oder Editor-Migration, keine allgemeine Nutzer-Art-/Performance-/Release-Abnahme.

## Belege und Reproduktion

- pass04_verification_manifest.json: aktueller Code-SHA,17strenge Engine-Laeufe,
  sechs gleiche Kamerapaare,17nativeAnsichten und exakter Browserbeleg.
- engine_checks_pass04.json, pass04_check_runs/, pass04_*_capture.json:
  Verifier, Kamera-/Licht-/Modell-/Quellenhashes.
- browser_qa_pass04/: Desktop/Mobil, funktionale Bild-/Sichtzustandsvergleiche,
  lokale Notizen/Entscheidungen, echte JSON-Exporte ohne externe Abhaengigkeiten.
- art/frontier_illustrated_20261101/structures/pass04/manifest.json:
 14echte Kenney-Quellen/Lizenzen, Source-/Fresh-GLB-QA und akzeptierte Warnungen.
- art/frontier_illustrated_20261101/ships/pass04_r02/{cutlass,buccaneer}/manifest.json:
  neue Quellen, beide Arbeitsiterationen und frische GLB-Roundtrips.
- pass04_rejected_r01_manifest.json: Nutzerablehnung und unveraenderte R01-PNGs.
- pass04_reference_manifest.json: Thedus-Ingamebild als visuelle Padreferenz.

Die folgenden Belege dokumentieren den erhaltenen Pass03:

- pass03_verification_manifest.json:16/16strengeLaeufe,fuenfBildpaare,achtAufnahmen.
- browser_qa_pass03/:136/136Browserchecks am unveraenderten historischen HTML.
- art/frontier_illustrated_20261101/structures/pass03/manifest.json:
  zehn echte Kenney-Quellen und damalige Montage-/Kontaktwarnungen.

Die folgenden Belege dokumentieren den erhaltenen Pass02:

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

## Erhaltene Arbeitsproben

pass04_*_review.log, pass04_geometry_check.log, pass04_fresh_import.log und
pass04_check_runs/20261101T153427Z-pid20432/ sind fruehere Arbeitsstaende,
keine Belege fuer die finale R02-Revision. Die aktuelle strenge Serie steht
im pass04_verification_manifest.json. probe_geology_pass03.gd bewahrt eine
isolierte aeltere Geometrie-/Lookprobe ausserhalb der aktiven Tests.

Pass05-Arbeitsproben vor der finalen Materialrunde:
pass05_environment_setup.log,pass05_environment_geometry.log,
pass05_environment_review.log und die erste18erSerie
pass05_environment_check_runs/20261101T175458Z-pid132920/.
Sie sind historische Arbeitsbelege. Der aktuelle finale18erLauf ist im
pass05_environment_verification_manifest.json gepinnt.

Pass05-HTML frisch297/297BrowserchecksPASS;111Bilder,222Decodes,
38Screenshotsund5Sichtnachweise,2echteJSONexports. AktuelleQA/HTML-Hashes
sind im pass05_environment_verification_manifest.json gebunden.
