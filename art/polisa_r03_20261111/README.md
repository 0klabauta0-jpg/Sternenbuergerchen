# Polisa R03 — privater, eingefrorener Integrationskandidat

Status: native Modellrevision, **keine ästhetische Nutzerabnahme**, keine aktive
Integration durch diesen Agenten. Rootworktree task/native-glut-maps-20261110,
Ausgangsstand7c9b5c7b1. Produktionskarte und Produktionsvisual unverändert.

## Ergebnis

- Hub68×24 mit durchgehender Mittelpassage und zentraler Querpassage.
- Sechs echte Räume: Werkzeug, Infanterie, Rüstung, Versorgung, Med/Service,
  Fracht/Schiffsbüro. Wände, Türöffnungen, Schaufenster, Tresen und Warenregale.
- Vier18×18Kleinpads und zwei28×34Großpads: ±Z je klein/groß/klein.
  X-Enden tragen technische Ringe und vier Solarflächen, keine Pads.
- Drei vollständige vorhandene R07-Rüstungen in statischer Idlepose auf Sockeln.
  Originaler personnel_armor_visual-Helper einschließlich R07-Körperform;
  keine neue Rüstungsrevision, AnimationPlayer pausiert, Modelprocessing aus.
- Editierbare gebatchte Godot-Primitives, neun statische Meshgruppen.
  14.124statische Dreiecke plus22.472Dreiecke in sechs Showcase-Meshes.
  Keine CollisionObjects, dynamischen Lichter oder eigenen Frame-Schleifen.

## Gemeinsame Quellen

1. `layout.json`: authoritative authoring facts, nicht neue Runtime-Wahrheit.
2. `build_candidate.py`: erzeugt gemeinsame `layout_compiled.json` und private
   `output/native_glut_maps/polisa_r03_20261111/polisa_station_candidate.json`.
3. `polisa_r03_visual.gd` + `.tscn`: liest ausschließlich die abgeleiteten Fakten
   für Deck/Wände/Türöffnungen/Möbel; zusätzlicher technischer Zierrat bleibt visual.
4. `layout_target.svg`: eigene 2D-Zielskizze, vor der Implementierung angelegt.

Der Compiler prüft volle Hexflächen gegen Deckunion und Wand-/Möbelrechtecke.
5.565gespeicherte Deckfelder:4.899begehbar, alle in einer Komponente;
666Wand-/Mobiliarfelder gesperrt. Sechs Padanker und alle bestehenden Marker-IDs
erhalten bzw. erweitert. Raum-/Serviceanker stehen in den Layoutdaten.
Keine zweite Registry, Navigation oder Inventarverwaltung.

## Frachterreserve

Großpads enthalten eine freie24×30Entwurfshülle mit je2Einheiten Randreserve.
Das ist geometrischer Platz, keine bekannte Caterpillar-Meshhülle und keine
nachgewiesene Landbarkeit. Zum Vergleich ergibt der vorhandene Cutlass-
Visualkatalog mit scale0.22 etwa2,657×3,52 in X/Z. Es wurde kein neuer Frachter
importiert. Kleinpads enthalten jeweils14×14 freie Reservehüllen.

## Native Bilder / Prüfung

Finale Originale unter `output/native_glut_maps/polisa_r03_20261111/`:

- `polisa_r03_overview.png`: Kamera123, yaw24°, pitch56°, Fokus0/0.
- `polisa_r03_armor_room.png`: Kamera18, yaw8°, pitch42°, Fokus16/-6 in X/Z.
- `r03_final.json`/`.log`: Godot4.6.2, D3D12Forward+,1280×720, Exit0,
  Errors0, Warnings0, versteckter Host, eigenes absolutes APPDATA-Profil.
- `native_metrics.json`, `offline_checks.json`: abgegrenzte Geometrie-/Datenwerte.

Beide finalen Bilder tatsächlich geöffnet. Vollständige Padmarkierungen und
Türschilder, eingerichtete Räume und drei unterscheidbare R07-Displays sichtbar.
Echtes Viewhexraster ist im Nahbild klar, im Gesamtmaßstab entsprechend fein.
Root hob stationseigene Rasterlinien über die Propböden an und erhöhte ihren
Fernkontrast; es existiert kein zweites Visual-/Gameplayraster.
Decktop0.01, sichtbare flache Markierungen maximal0.052, Raster bei0.074.

Der erste Artlauf bleibt als r01_* plus r03_art01.log/json erhalten. Er lieferte
die zwei Bilder, wurde wegen relativem APPDATA-Pfad und Shadercachefolder-ERROR
nicht als sauberer Lauf gewertet. Absoluter Profilpfad behebt dies im finalen Lauf.
Insgesamt zwei Ansichten in zwei gezielten Artläufen, keine Variantenserie.
Unabhängiger Read-only-Sourcecheck ohne konkreten Blocker.

## Integration durch Root

Private Map und Scene/Script/compiled layout zusammen übernehmen; die Scene
referenziert bewusst dieses Artpaket. Alternativ Produktpfade kontrolliert
umbiegen. Root bindet polisa_pad_01..06 in locations.json ein. Alte Marker
spawn_alpha/spawn_bravo/ship_return/objective_point/trade_service bleiben
benannt, ihre Koordinaten liegen jetzt auf den neuen Decks.
Neue Ladenräume sind räumliche Fakten und Ausstellungen; der Kandidat erzeugt
keine neuen Handelsangebote, Shopowner oder separate Interaktionslogik.

## Grenzen

Offlinekonnektivität und Artaufnahmen sind kein Laufweg-/Reise-/Shop-/Save-
oder Schiffslande-PASS. Keine Gefechte, Benchmarks, großen Tests, Main oder EXE.
Keine Produktivdatei, IMPLEMENTATION_STATUS oder ACTIVEWORKPLAN geändert.
Keine Commits/Push. GPU-Fenster nach dem finalen Bildlauf freigegeben.
Quellen-/Bildhashes und Referenzprovenienz stehen in manifest.json.
