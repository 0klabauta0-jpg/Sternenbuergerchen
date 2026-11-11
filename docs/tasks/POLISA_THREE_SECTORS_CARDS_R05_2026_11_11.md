# Polisa R05: Stationsmasse und kompakte Produktkarten

## Ziel und Ursache
R04 wirkt zu klein und flach. Der Nutzer verlangt eine maechtige Port-Olisar-inspirierte Station mit wiederholten Sektoren, geraden Ringen, groesseren sichtbaren Shops und kompaktem Kaufmenue mit ganzen Ruestungsbildern.

## Umfang / Nicht-Ziele
- Drei verbundene Sektoren gleicher Weltgroesse, vier gerade Ringe, aeussere Solar-/Dockingausleger, gesperrte technische Unterbauten. Je Sektor L mittig, zwei M links nebeneinander, vier S rechts in 2x2; L doppelte M-Laenge.
- Groesserer Globusraum und fuenf Shops pro Sektor ohne Kameradrehzwang.
- Lokale sparse Stationskarte darf wachsen; A/B/C512x256 und Sternkarte256x256 unveraendert.
- Kompakte Kaufkarten; Ruestungen mit ganzen Vorderansichten der vorhandenen freigegebenen 2D-Modellvorlagen. Bestehende Runtimecommands und Zugangssperren bleiben Wahrheit.
- Frachtfluss am echten gelandeten Schiff nachvollziehen; keine erfundene lokale Schiffsauslieferung, Komponentenfunktion oder grosse Schiffsdockingfreigabe.
- Keine Tabletop-Owner-/Bewegungsarbeit hier und keine grossen Tests.

## Grundlagen
graphics_reference_revision_contract.md; polisa_ship_equipment_contract.md; POLISA_ROOMS_FIVE_PADS_2026_11_11.md als historischer Vorlaeufer; ACTIVE_WORKPLAN_2026_11_11.md. Externe Referenzen und neue KI-Proposals: art/polisa_r05_20261111/references. KI-Bilder sind Konzepte, keine native Evidenz.

## Akzeptanz
1. Gemeinsame Layoutquelle erzeugt Karte und Visual; keine begehbaren technischen Fuellflaechen oder doppeltes Paddressing.
2. 21 echte Pads, vier parallele Ringe, drei Sektoren ohne verkleinerte Figuren; Nahansicht und ganze Karte getrennt zeigen.
3. Shops aus derselben Standardkamera einsehbar; zwei aeussere Dockingreserven als Geometrie bezeichnet.
4. Ruestungskarten begrenzter Breite zeigen Helm bis Stiefel und gueltige Preise/Bestand/Schiffslager. Ausruesten benutzt bestehende echte Personen-/Inventarcommands.
5. Kleine Compile-/Layoutpruefung und angeforderte native Ansichten; keine Aussage zu vollstaendiger Reise-, Gefechts-, Save- oder Performanceabnahme.

## Dateien / Aufteilung
Artagent: art/polisa_r05_20261111 und privates output/native_glut_maps/polisa_r05_20261111, danach Root-Integration maps/polisa_station.json, scripts/terrain/polisa_station_visual.gd, tools/build_polisa_station.py und Orts-/Padkatalog.
Root: scripts/ui/polisa_station_screen.gd, Assets/curated/ui/polisa_armor, passende Adapter-/Service-Lesepfade falls erforderlich, gezielte docs/qa/polisa_r05_20261111 und Status.

## Risiken / offen
Groessere sparse Karte braucht passende Kamera- und Zoomgrenzen. Technische Unterbauten duerfen Hex-Picking/Navigation nicht ersetzen. Die zwei KI-Proposals koennen Layoutfehler enthalten; konkrete Nutzerregeln haben Vorrang. Ruestungsbilder sind 2D-Illustrationen, kein Beleg fuer native Modellgleichheit. Lokale Schiffsauslieferung und Schiffswaffenowner bleiben eigene Folgeaufgaben.

## Lokale Pruefung
Enger Check der geaenderten Scripts/Authoringdaten; native Karten- und Menuebilder visuell oeffnen. Kauf/Equip-Gates erhalten; grosses End-to-End-Paket spaeter.
