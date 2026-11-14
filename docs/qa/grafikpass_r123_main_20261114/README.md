# Grafikpass R1, R2, R3: Mainintegration am 14.11.2026

Basis: frisch geholter Main `794d91ac6c25c87641d0618a47e0c665e1edd826`.
Separater Branch `task/grafikpass-r123-main-20261114`; der Hauptcheckout mit
fremdem WIP wurde nicht gewechselt oder bereinigt.

## Uebernahme und begrenzte Korrekturen

Die drei gelieferten Patches wurden mit `git apply --check --index` und
anschliessend `git apply --index` in der Reihenfolge **R1, R2, R3** konfliktfrei
angewendet. [patch_application.json](patch_application.json) dokumentiert
Originalpfade, SHA256, Exitcodes und den Indexbaum nach jedem Schritt.
Die Patchdateien sind unveraendert; historische Tasks und Bilder bleiben
historische Belege, ihre Folgeideen sind kein zusaetzlicher Arbeitsauftrag.

Vor der Freigabe wurden vier konkrete Darstellungsfehler korrigiert:

1. Fallender Klippen-Lichtverlauf als `1.0 - smoothstep(-0.30, 0.20, x)`.
   Umgekehrte Grenzen sind laut [Godot-Shaderreferenz](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/shader_functions.html#shader-func-smoothstep)
   undefiniert; Richtung und Endpunkte des beabsichtigten Verlaufs bleiben erhalten.
2. Die Materialkonfiguration fuer direkten Aufbau und Terrain-Prefill verwendet
   dieselbe Strassenfarbe; Prefill erzeugt weiterhin kein lebendes Strassenobjekt.
3. Einheiten und Hexlinien nutzen auf Strassenrampen den tatsaechlichen Hub des
   Deckmeshes inklusive `GRADED_LIFT`. Unbebaute Rampen bleiben unveraendert.
4. Known-/Explored-FoW liegt ebenfalls oberhalb der erhoehten Strassen/Pads.
   Sichtzustand, regionale Rampenneigung und der Unknown-Blackout bleiben gleich.

Der Katalogverifier erwartet nun 18 Eintraege einschliesslich Windbruch und
unterstuetzt einen optionalen einzelnen `--map`-Test. Seine Standardauswahl
bleibt der vollstaendige Katalog. Keine neue Spielregel oder Gameplayautoritaet.

## Akzeptierte Pruefungen

**17 Integrationsgates bestanden:** 16 Headless-Gates aus dem frischen Lauf B
plus der vollstaendige Surface-/FoW-Gate mit echtem Forward+/D3D12-Renderer.
Zusaetzlich wurden alle 13 neuen Modelle importiert und sieben native Bilder
kontrolliert. Kein akzeptierter Lauf hat Engine-, Parser-, Shader- oder Leakfehler.

- [accepted_checks.json](accepted_checks.json): verbindliche Auswahl und Belege.
- [Lauf B](checks_b/20261114T164232Z-pid69092/metadata/report.json): frischer
  Godot-4.6.2-Import; Windbruchinhalt/-navigation/-prefill, Hexoberflaeche,
  Gridcache, Artprofil, Umgebung, Wege, Gebaeudematerial, Stationsdarstellung,
  GM01-Rand, Kampagneninhalt/-kette, Orbit-Orte, Mapservices und freie Landung.
- [Surface/FoW nativ](captures_b/surface_run.json): **148/148** Assertions
  mit echten MultiMesh-Transforms, Farben, Shaderprofilen und Meshhoehen;
  direkter und aus dem Cache wiederhergestellter Aufbau stimmen ueberein.
- [Navigation](windbruch_navigation.json): **39/39**, 84 Rampenkanten;
  Landefeld -> Chip -> Rueckkehr als zwei kontinuierliche SimulationRoot-
  Bewegungen, jeweils identischer Verlauf mit C++ und GDScript. Keine
  Zwischenteleports, unveraenderte Bewegungsbudgets und Terrain-/Registrydaten.
- Windbruch-Prefill: alle **108 Chunks** vorbereitet und in der empfangenden
  View ohne erneuten Geometrieaufbau wiederhergestellt; kein allgemeiner FPS-Test.
- [GLB-Quellen](glb_source_audit.json): 13 Dateien, 20.852 Dreiecke, finite
  Attribute, keine degenerierten Dreiecke. [Engineimport](captures_a/kit_import.json)
  bestaetigt 13 geladene Modelle mit gueltigen Meshgrenzen.

Die ersten Versuchsergebnisse werden nicht verschwiegen: Lauf A hatte eine
fehlende dynamisch referenzierte `benit_delivery.json` in der Testkopie. Mit
der echten Datei besteht der Kampagneninhalt in B mit 69/69. Der erweiterte
Surface-Test scheiterte in B unter Headless beim MultiMesh-Readback, wie bereits
in bestehenden Projektverifiern dokumentiert. Dasselbe unveraenderte Script
besteht nativ mit allen 148 Assertions; es wurde keine Assertion uebersprungen.
Der Rohreport B mit 16/17 ist deshalb kein pauschal gruener Headless-Gesamtlauf.

## Frische Bilder und Sichtpruefung

Godot 4.6.2, Forward+, D3D12, NVIDIA GeForce RTX 4070 Ti SUPER.
[Renderlauf](captures_b/maps_run.json) enthaelt Kameraargumente, Exitcode und
Fehlerpruefung. Die sechs Kartenaufnahmen sind 1280x720; das Studio ist 1600x1000.

- [Kit im Studio](captures_a/kit_studio.png): alle 13 Modelle, Materialien und
  Geometrie sichtbar; [Lauf](captures_a/kit_run.json) fehlerfrei.
- [Windbruch gesamt](captures_b/windbruch_overview.png),
  [Hof](captures_b/windbruch_yard.png), [Hauptrampe](captures_b/windbruch_ramp.png),
  [Relais](captures_b/windbruch_relay.png): neue Karte, Hoehenstaffelung,
  Gebaeude, Strassen und Pads technisch kontrolliert.
- [GM01-Pad](captures_b/gm01_pad.png): erhoehtes Deck und creme-/petrolfarbene
  Gebaeude in der produktiven Beleuchtung.
- [GM02-Kontrolle](captures_b/gm02_control.png): alte gruene Karte
  `maps/Ground_Mission02_128x128.json`. **Keine gestalterische Freigabe:** Der
  Nutzer hat dieses Bild beanstandet und will die Karte anschliessend separat
  neu erstellen lassen. Die Grafikpass-Patches ersetzen diese Karte nicht.

Die mitgelieferten llvmpipe-Bilder in den R1/R2/R3-Ordnern wurden nicht als
neue Forward+-Nachweise ausgegeben. Kein Anspruch auf pixelgleiche Renderer.

## Quellen, Isolation und Grenzen

[source_verification.json](source_verification.json) bindet die Pruefung an
2.633 bytegleiche Projektdateien in der frischen isolierten Testkopie. Die
18 versionierten Dateien unter `native/navigation` und
`addons/sb_native_navigation` sind unveraendert gegen Main, inklusive DLL.
Die 28 Quellen/Importdateien des Studio-Laufs A sind weiterhin identisch.
`source_head` bezeichnet den Basiscommit; die einzelnen SHA256 identifizieren
den geprueften Kandidaten vor seinem gemeinsamen Commit.

Der Prepare-Helper kopiert echte Abhaengigkeiten, verwendet eine eigene
`user://`-Ablage und einen Testguard. Kein Spielerprofil, keine Map-/Blender-
Generatoren und kein EXE-Export wurden ausgefuehrt. Die isolierten Tests
verwenden den Testguard-Autoload, nicht den gesamten produktiven Appstart.

Fuer eine Wiederholung die Argumente aus [prepare_b_command.json](prepare_b_command.json)
mit einem neuen Ausgabeordner verwenden, `SB_REVIEW2_USER_DIR` aus dem erzeugten
Manifest setzen und [headless_checks.json](headless_checks.json) mit dem
Godot-Verification-Runner ausfuehren. Den Surface-Gate zwingend mit echtem
Renderer gemaess `captures_b/surface_run.json` starten. Die Captureargumente
stehen in den jeweiligen Run-Dateien; `CAP_DIR` muss bereits existieren.

[main_checkout_preservation.json](main_checkout_preservation.json) bestaetigt
unveraenderten Branch/HEAD/Index, die Inhalte der sechs bearbeiteten Dateien
und das Pfad-/Groessen-/Mtime-Inventar aller 102.105 untracked Eintraege.

Keine vollstaendige Kampagnensortie, Kampf-/Boarding-/Save-Continue-Abnahme,
kein Multiplayer-, Fremdplattform- oder Performancefreigabenachweis. Der
angepasste Fuenf-Sortie-Verifier wurde nicht als vollstaendiger Durchlauf gewertet.
