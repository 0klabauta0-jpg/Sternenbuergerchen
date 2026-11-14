# Bildersatz: Spielzielbilder 14.11.2026

## Ziel / Problem und Anlass
Mindestens 15 konkrete Bild-KI-Zielbilder zeigen den gewuenschten Spielstil aus Star-Citizen-Industriesprache, lesbarem Wimmelbildcharakter und sichtbaren Hexfeldern. Anlass ist der ausdrueckliche Nutzerauftrag fuer Absturzfurche, Steinverteilung, Maps, Basisteile, Gefechte und Weltraum.

## Umfang und Nicht-Ziele
17 eigenstaendige neue Bilder, lokale Quellenrecherche, Originalausgaben, Prompts, SHA-256-Manifest und Offline-Bildgalerie mit Einzelentscheidungen. Keine Runtime-, Modell-, Karten-, Balance- oder Gameplayaenderung. Raumraster ist eine gekennzeichnete Visualisierungsidee, keine neue Navigationsregel.

## Nutzerkorrektur und Revisionen
Acker war nur eine Metapher fuer die lange Einschlagfurche. Aktive Motive 01/02/04 zeigen kargen Mondboden ohne Landwirtschaft; Pflanzen in Motiv 17 bleiben innerhalb geschlossener Anbaupods. Motiv 03 erhielt dichteres Hexraster; Motiv 17 freie durchgehende Zugaenge. Sechs Zwischenstaende samt Prompts bleiben als ueberholte Revisionen erhalten. Alle 17 aktuellen Motive sind einzelne eigenstaendige Entwuerfe, keine geometrisch identischen Modellansichten.

## Arbeitsbasis
Isolierter Sparse-Worktree auf task/visual-targets-20261114 von integration/core-foundation (3cae5a216d380b58fef92724540e95fbc49bde7e). Aktuelle Grafik-/Hex-/Playtestvertraege werden aus C:/dev/SternenBuergerchen (HEAD 970d1ea7a12beae4f678a7e384b6fc58598f1489, fremdes WIP vorhanden) als aktuelle Referenz gelesen. Keine Fortsetzung oder Uebernahme des alten Taskbranch-Codes.

## Relevante Dokumente
Aktueller PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS; graphics_reference_revision_contract.md, html_report_workbench_contract.md, hex_grid_v1_contract.md, gm01_frontier_map_contract.md; ART_2026_11_01_graphics_references.md und aktuelle Playtest-/Artkorrekturen. Fruehere Quadratgitter gelten nur als Stilquelle, neue Bodenbilder verwenden Hexfelder.

## Akzeptanzkriterien
- Mindestens 15 separate vollstaendige Bilder statt einer Collage.
- Absturz mit Satellit und langer Erd-/Truemmerspur; Geologie, Map, Aussenposten, Pad, Details, Boden- und Raumkampf vertreten.
- Bodenbilder zeigen lesbare Hexfelder, Massstab und freie Wege; keine gleichmaessige Stein- oder NPC-Streuung.
- Quellen und generierte Konzepte sichtbar getrennt. Keine Nutzerabnahme, native Integration oder Performance behauptet.
- Originalbilder, Promptset, Werkzeug, Eingabe-/Stilquellen und SHA-256 erhalten.
- Offlinegalerie mit Suche, Filtern, Vergroesserung, Einzelnotizen/Entscheidungen und JSON-Export.

## Betroffene Dateien
Diese Taskdatei, docs/reports/ZIELBILDER_2026_11_14.html, docs/reports/assets/zielbilder-2026-11-14/* und eine kurze Statusnotiz.

## Lokale Pruefung
Alle Bilder oeffnen und gegen Motiv, Hexlesbarkeit, Stil, Massstab beurteilen. Dateianzahl/Integritaet/Hashmanifest; Galerie Desktop/schmal, Filter/Dialog/Notizen/Export; git diff --check. Keine Enginepruefung erforderlich, da kein Runtime-Code geaendert wird.

## Risiken / offene Punkte
KI kann Hexgeometrie oder technische Details lokal verzerren; Zielbilder sind weder exakte Bauplaene noch ein Laufzeitnachweis. Raumdarstellungen zeigen visuelles Ziel und muessen spaeter getrennt mit dem Flugvertrag abgestimmt werden. Nutzerbewertung bleibt offen.

## Ursprünglich erzeugter Stand vor der Weltraumkorrektur
17 aktuelle Einzelbilder, sechs erhaltene Zwischenstaende und zehn betrachtete lokale Stilreferenzen. Alle 23 kopierten Generatorausgaben SHA-256-identisch zum jeweiligen Original. Vollstaendige Prompts und tatsaechliche Edit-Eingaben in prompts.json/generation_metadata.json; Dateinachweis in manifest.json. Sichtpruefung und Browserpruefung stehen im Bildpaket in BILDPRUEFUNG.md und GALERIE_QA.md. Unterschiedliche Schiffs-/Gebaeudeformen sind eigene Entwuerfe, keine verbindlichen Mehransichten. Galerie erlaubt Entscheidungen und Notizen mit lokalem JSON-Export.

## Folgeauftrag: Weltraumbilder nach Kartenvertrag
Der Nutzer bestaetigt die Bodenmotive insgesamt als passende Stilrichtung und kritisiert ausschliesslich Weltraum 13–16. Nur diese vier Motive werden ersetzt. Vorher wurden lokale Star-Citizen-Screenshots, Web-Bildquellen und die neueren Weltraumvertraege sowie native Kartenaufnahmen gesichtet. Befunde und Quellen: assets/zielbilder-2026-11-14/RAUMKARTEN_RECHERCHE.md relativ zum Reportordner.

Verbindliche Bildkriterien: lokale Karte 512 Spalten mal 256 Reihen; Planet oder Station oben, Weltraum unten; ueberwiegend freier Raum; orthografische taktische Sicht auf eine Ebene; gleichmaessiges Hexraster im ganzen sichtbaren Kartenausschnitt; leichter Jaeger etwa ein Hex, Cutlass etwa zwei. Reise, Kampf und Wrackbegegnung erscheinen als Spielkartenansichten. Stationsbauweise folgt industriellen Ring-/Tragwerk-/Dockformen. Die Bodenbilder bleiben unveraendert. Alte Weltraumausgaben und Prompts bleiben als verworfene Revision erhalten. Neue Weltraumbilder warten auf Nutzerbewertung; positives Bodenfeedback ist eine Stilbestaetigung, keine native Assetabnahme.

Arbeitsbasis bleibt der isolierte Grafikbranch. Quellen aus neueren Arbeitsbaeumen werden nur gelesen, kein Code daraus uebernommen. Geprueft werden Bildkomposition/Proportionen, Original-Hashes und die aktualisierte Offlinegalerie inklusive revisionsgebundener Notizen. Risiken: KI-Hexgeometrie bleibt illustrativ; exakte Zellenzahl, echte Spielbarkeit und eine implementierte Wrackbergung werden nicht behauptet.

## Aktualisierter Lieferstand
17 aktive Einzelbilder, 15 erhaltene Zwischenstände, 16 gesichtete Referenzen. Raumkarten 13–15 R03 und Polisar 16 R04 ersetzen die kritisierten Weltraumbilder; Bodenbilder sind bytegleich erhalten. R04 folgt der Nutzerannotation: größere Ringe um die verlängerte Nabenachse, Streben, links Solarflächen, rechts vier Tanks, verlängerte Dockarme. Der zusätzliche Auftrag für einen anderen Blender-Chat ist als POLISAR_BLENDER_AUFTRAG.md vollständig beschrieben. Die Code-ID polisa bleibt unverändert; das Bildziel heißt Polisar. Keine Modelle erstellt oder Runtime geändert. Bildgrenzen: Wrack noch größer als zwei Hex; Raster und Konstruktion sind nicht metrisch geprüft. Bei einer Modellumsetzung werden diese Punkte geometrisch geprüft. Neue Bilder bleiben zur Nutzerbewertung offen.
