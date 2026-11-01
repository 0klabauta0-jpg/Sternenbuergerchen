# Grafikreferenz- und Revisionsvertrag

## Zweck

Dieser Vertrag beschreibt den referenzgefuehrten Grafikablauf fuer Gelaende,
Strukturen, Fahrzeuge und Menschen. Er ergaenzt den
[HTML-Workbench-Vertrag](html_report_workbench_contract.md), den
[Terrain-Visual-Vertrag](terrain_truth_visual_audit_contract.md) und den
[Unit-Facing-Vertrag](unit_facing_visual_contract.md).

## Referenz und Bildstatus

- Die aktuelle Nutzeranweisung bestimmt das visuelle Ziel. Jedem bearbeiteten
  Asset oder zusammengehoerigen Ensemble eine eigene 2D-Zielvorlage zuordnen;
  gemeinsame Stilbilder ergaenzen Farbe, Material, Umgebung und Komposition.
- Externe Quellen, generierte 2D-Zielbilder und native Godot-Aufnahmen sichtbar
  unterscheiden. Ein Konzeptbild zeigt eine Absicht; eine native Aufnahme zeigt
  das tatsaechlich importierte Modell unter den angegebenen Bedingungen.
- Quellen mit lokalem Pfad beziehungsweise Original-URL, Herkunft und Stand
  festhalten. Fuer verwendete lokale Bilder und Modelle SHA-256 dokumentieren.
  Bei generierten Bildern Eingabevorlagen, Prompt, Werkzeug und Originalausgabe
  im Grafikpaket erhalten.
- Mehrere Ansichten desselben Entwurfs muessen dieselbe Identitaet zeigen:
  Silhouette, Proportionen, Ausstattung und Palette gemeinsam vergleichen.
  Sichtbare Widersprueche benennen und korrigieren, bevor das Paar als gemeinsame
  Modellvorlage verwendet wird.

## Revision und Nachweis

- Die aktuelle Quelle und den wichtigsten sichtbaren Unterschied zur eigenen
  Vorlage zuerst ansehen. Die Revision daran ausrichten; lesbare Hauptformen,
  menschlicher Massstab, plausible Konstruktion und zusammengehoerige
  Funktionsflaechen helfen mehr als beliebig verteilte Zusatzdetails.
- Aktive Quellen, Nutzerbilder sowie fruehere Kandidaten und Berichte erhalten.
  Neue Varianten in einem zugeordneten Grafikpaket ablegen und ihre Herkunft
  gegenueber der aktiven Quelle kennzeichnen.
- Bei tatsaechlichen Mesh-Aenderungen editierbare Quelle und Export ablegen,
  Geometrie pruefen und frisch in Godot importieren. Bounds, Massstab,
  Orientierung, Pivot und Materialzuordnung am importierten Ergebnis pruefen.
  Bei Rig, Animation oder beweglichen Baugruppen die betroffenen Posen,
  Bewegungen und Anschluesse pruefen. Bei reinen Materialproben den
  unveraenderten Geometriestand angeben.
- Modellkandidaten nativ vor und nach der Revision bei gleicher Kamera,
  Bildausschnitt, Beleuchtung, Renderer und Materialroute vergleichen. Den
  beabsichtigten Spielabstand zeigen; weitere Vorder-, Seiten-, Rueck- oder
  Massstabsansichten nach der konkreten Formfrage waehlen.
- Die erzeugten Bilder oeffnen und das sichtbare Ergebnis beurteilen.
  Technische Pruefungen, Verbesserungen und verbleibende Formfehler getrennt
  festhalten. Eine bestandene Importpruefung ist keine gestalterische Abnahme.
- Pro Asset den erreichten Stand angeben: Referenz, 2D-Ziel, nativer Ist-Stand,
  separater Modellkandidat oder tatsaechlich integrierte Variante. Nutzerurteil,
  aktive Integration und geprueftes Spielverhalten einzeln belegen.
- Bei Zwischenstaenden konkrete naechste Grafikschritte nennen: zugeordnete
  Zielreferenz, sichtbarer Abstand, vorgeschlagene Aenderung und Bildvergleich
  danach. Offene Vorschlaege nicht als implementiert ausgeben. Vorlaeufige
  Grundlagen nicht als unveraenderliche Endentscheidung festschreiben.

## Externe Grafik im nativen Hex-Ausschnitt

Ein mehrzelliges Klippen-/Gebaeudemodell darf eine explizite, schwach
referenzierte Visual-Owner-Zuordnung fuer seine Zellen erhalten. Das verhindert
doppelte Ersatzobjekte, veraendert jedoch keine Karten-, LOS- oder
Bewegungsfakten. Ohne lebenden Owner greift wieder die normale Darstellung.
Ein expliziter flacher Ground-Owner darf nur die Kappen der Ebene 0 ersetzen;
er ersetzt weder Hoehendaten noch Hex-Picking oder Auswahl. Der synthetische
Fixture-Builder setzt Hindernis-/LOS-Fakten vor der Registry-Registrierung.
Die Visual-Builder liefern dazu nur Footprint-Huellen zurueck.

## HTML-Vergleich

Grafikberichte folgen dem vorhandenen Workbench-Format und funktionieren lokal
ohne Server und externe Laufzeitabhaengigkeiten. Bilder im Paket mitliefern oder
einbetten; Originale und Quellenmanifest bleiben nachvollziehbar erhalten.

- Uebersicht mit Auftrag, Stand und tatsaechlich bearbeitetem Umfang.
- Katalog mit Suche, passenden Gruppenfiltern und lesbaren Eintraegen fuer
  Vorlage, Ist-Stand und Kandidat; Ansichts- und Abstandsschalter halten
  Vergleichspaare synchron.
- Vergroesserung per Bilddialog mit Beschriftung, Quelle und Bildstatus.
- Je Eintrag sichtbare Notizen, Entscheidung und offene Differenzen; Quellen-
  und Pruefdetails koennen einklappbar sein.
- Sichtbarer Button `JSON exportieren` und Download-/Textfallback nach dem
  bestehenden Schema `sternenbuergerchen.html_workbench.v1`. Der Export erfasst
  die Asset-Zuordnung, Entscheidungen, Bedienelemente und Notizen. Diese Daten
  bleiben Arbeitsnotizen der Workbench.
- Die fertige lokale Seite auf Desktop und schmaler Ansicht pruefen; Suche,
  Filter, Bilddialog, Ansichtswechsel, Notizen und JSON-Export ausprobieren.

## Beispiel: Grafikpaket vom 01.11.2026

Der Auftrag [ART_2026_11_01](../tasks/ART_2026_11_01_graphics_references.md)
verbindet Gelaende-, Struktur- und Personenbilder mit Schiffsentwuerfen.
Cutlass und Buccaneer erhalten mit dem Bildgenerator jeweils eine Vorder- und
Heck-Dreiviertelansicht. Die spaetere Nutzerkorrektur legt Wimmelbildstil mit
etwas weniger Details fest; fruehere Himmelbildfassungen bleiben Vergleich.
Vorhandene
Schiffquellen und Star-Citizen-Bilder erklaeren die Fahrzeugform; die
InselKrieg-Illustrationen dienen als Referenz fuer Bildsprache und Komposition.
Die beiden Ansichten je Schiff werden als ein zusammengehoeriger Entwurf
geprueft. Diese Paketzuordnung ist keine allgemeine Themenvorgabe des Projekts.
