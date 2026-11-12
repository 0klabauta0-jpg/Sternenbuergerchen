# Heimatbasis: nativer Grafikvergleich 12.11.2026

## Ergebnis und aktuelle Vorgaben
Der Heimatboden ist durchgehend gedämpft rostfarben und besitzt eine dezente
Oberflächenstruktur. Die großen gemalten Sand-/Straßenfelder werden im expliziten
Heimatprofil nicht mehr als Farbstreifen gezeigt. Die gespeicherten Oberflächen-
und Navigationsdaten bleiben bestehen.

Nach der letzten Nutzerkorrektur ist der Weg wieder eine **durchgehende gebaute
Asphaltfläche**, mit weich geführten Kurven zwischen echten Türen und Pad,
vereinigten Polygonen, sparsamen Randsteinen und kleinen Markierungen. Die
zwischenzeitlichen Trittsteine wurden verworfen. Die alte rechteckige Straße
steht als `native/earlier_square_path.png` zum Vergleich bereit.

Das echte Kartenhexraster ist eingeschaltet und mit der vorhandenen
pixelbezogenen Linienabdeckung besser sichtbar. Es ist das grobe Kartenraster;
die Basis-Innenraumnavigation verwendet weiterhin den feineren Faktor 4.
Flache H0-Bodenkappen werfen im Heimatprofil keinen Selbstschatten mehr,
wodurch das vorherige diagonale Muster verschwindet. Erhöhtes Gelände behält
seinen Schatten. Basislicht bleibt gerichtet; für dieses Profil sind Biaswerte
angepasst. Der Pad-Renderoffset von 12 mm vermeidet koplanare Bodenüberlagerung,
ohne die autoritative Stehhöhe zu ändern.

Die drei nördlichen Felsgruppen verwenden wieder die **unveränderte vorhandene
Geometrie** `Assets/kenney_space-kit/Models/GLTF format/rock_largeA.glb`.
Schlichte Hexsäulen wurden ausdrücklich verworfen. Das bestehende Modell wird
mittig und innerhalb einer tatsächlichen Hexhülle eingepasst: hohe Zentren
0,84; sechs niedrige Nachbarn 0,32. `homebase_rock_rules.gd` ist die gemeinsame
Positions-/Wertequelle für grobe und feine Terrainkarte sowie Visualprojektion.
Die tatsächliche LOS-/Deckungsprüfung stammt aus dem separaten
`homebase_rock_rules_verifier.gd`; diese Grafikprobe erfindet keine Deckungswerte.

## Referenzen und Bildstatus
Geöffnet und verglichen:
- Native frühere Basisreferenz `Assets/curated/main_menu/frontier_outpost_main_20261101.png`.
- 2D-Ziele `01_rostgrenze_cutaway.png`, `02_freihafen_distribution_center.png`,
  `03_taktische_rostwelt_gesamtkarte.png` unter
  `docs/reports/assets/grafik-2026-11-01/references/current/`.
- Stilquelle `docs/reports/assets/ui-2026-11-01/references/aussenposten_stilstudie.png`.
- UI-Ziele `menu_heimatbasis.png` und `mockup_a5_mission_zweireihig.png`
  unter `docs/reports/assets/ui-2026-11-01/`.

Schiffe in den Referenzen waren ausdrücklich kein Änderungsziel. SHA-256 für
die verwendeten Referenzen, das vorhandene Modell, aktuelle Quellen und Bilder
stehen im Manifest. Die neue KI-UI-/Iconstudie liegt separat unter
`art/homebase_ui_study_20261112/`; sie ist keine native Aufnahme und keine
Nutzerfreigabe. Zwischenzeitliche ganze Habitatkopien sind ebenfalls keine
Abnahme der neu verlangten modularen Schlaf-/Lagerräume.

## Native Nachweise
`native/before_overview.png` gegen `native/after_overview.png`: gleiche Weltkamera
(Größe 34, Yaw 24, Standardpitch), Auflösung 1280×720, Lichtfamilie und
OpenGL-Compatibility-Renderer. Das neue Heimatprofil korrigiert Palette/Bias;
die inzwischen parallel geänderte UI ist kein pixelidentischer Vergleich.
`native/after_paths.png` zeigt den Spielabstand bei Kameragröße 18.
`native/before_rocks.png` und `native/after_rocks.png` verwenden dieselbe nahe
Kamera bei Größe 9. Die alte Aufnahme zeigt die originale Farb-/Materialroute;
die neue das Originalmodell mit den neuen Zell-/Höhenzuordnungen.
Alle sechs abgelegten Vergleichsbilder wurden geöffnet und visuell beurteilt.

Capture: Godot 4.6.2, OpenGL Compatibility, NVIDIA RTX 4070 Ti SUPER,
isoliertes APPDATA. Ein eigens erstellter Windows-Desktop wird nie aktiviert;
SW_HIDE ist zusätzlich gesetzt. Kein sichtbares Fenster, Maus- oder Desktop-
Eingriff. `capture.gd` und `hidden_desktop_run.py` erhalten den reproduzierbaren
Ablauf; der Runner muss aus dem Projektroot ausgeführt werden. Die Ausgabe
geht weiterhin nach `output/home_visual_final_20261112`.

## Prüfung und Grenzen
`scripts/tests/homebase_visual_coherence_verifier.gd`: **21/0**, Exit 0.
Belegt Opt-in-/Defaulttrennung, Rasterparameter, flache versus erhöhte
Bodenschatten, unveränderte Layoutdaten, drei vereinigte Straßenlayer,
gebatchte kleine Randsteine ohne Collider sowie Zentrierung, exakte Höhen und
Hexhülle des ursprünglichen Felsmodells. Kein per-frame Aufbau eingeführt.

Frischer nativer Straßen-/Felslauf: Exit 0, keine Script-/Shaderfehler. Zwei
bereits vorhandene Szenen-UID-Warnungen verwenden erfolgreich den Textpfad.
Der anfängliche Probeabbruch durch einen falschen Diagnose-Methodennamen und
zwei korrigierte Verifierannahmen sind keine Produktfehler; der hier abgelegte
finale Lauf enthält diese nicht.

Offen bleiben persönliche Gestaltungsgenehmigung, vollständige native
Gefechts-/Save-/Mehrortprüfung und Messung der tatsächlichen Echtzeitleistung.
Das Gelände ist noch vergleichsweise leer; die Referenzen enthalten deutlich
reichere Landschaftskomposition. Die Felsen sind bewusst auf eine Zelle
eingepasst, die Quellgeometrie ist erhalten, ihre Proportionen ändern sich durch
die getrennte Höhen-/Breitenanpassung. Kein Commit, Main-Merge oder EXE durch
diesen Teilauftrag; Root sammelt den gemeinsamen Arbeitsstand.
