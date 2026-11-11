# Polisa R08: groessere Ringe, sichtbare Ports, gefasste Zugaenge

## Ziel / Ursache
Nutzer gefaellt die R07-Grundform sehr gut. Gezielte Anschlusskorrekturen: Ringe etwas groesser, Achse unter dem Weg und etwas nach hinten, groessere Solarzellen/laengere Ausleger, sichtbare Dockingports und Mauern mit Tuerdurchgaengen zwischen Pads, Weg und Globusraum.

## Umfang / Nicht-Ziele
R07-Einheiten/Menschen/S8x6 aus Heimatbasis, M12x12/L16x24, ein Globusraum, fuenf Shops, sieben Pads und512x256 behalten. Ringe moderat vergroessern, beide exakt auf gemeinsamer gerader Achse. Ausleger bleiben gerade/orthogonal. Durchgaenge von Wandsegmenten einfassen und freihalten; dieselben Rechtecke erzeugen sichtbare Mauern und Groundblocker. Keine eigene Tuerzustands-/NPC-/Transportwahrheit, keine neue Dockingmechanik oder automatische Schiffsfitfreigabe.

## Quellen / Vertraege
R07-Layout/KI-Leitbild, graphics_reference_revision_contract.md, polisa_static_deck_visual_contract.md, polisa_ship_equipment_contract.md, POLISA_HOME_PAD_SCALE_R07_2026_11_11.md. Bestehenden Tuerowner erst suchen, falls interaktive Tueren erforderlich werden; reine offene Tuerportale als solche kennzeichnen.

## Akzeptanz
- R07-Grundform und Basis-Padmassstab erhalten; keine erneute globale Skalierung.
- Zwei etwas groessere, dicke Ringe auf gleicher Y-/Z-Mitte unter der hinteren Weghälfte; Ausleger/Solararme gerade.
- Beide Ports in einer Stationsgesamtansicht und mindestens einem ausreichend nahen Ausschnitt erkennbar/beschriftet.
- Wandschotten zwischen Padzugang/Weg/Lobby; klar begrenzte Durchgaenge statt freier Uebertritte. Alle7Pad-/5Shop-/Globusanker verbunden; Waren ohne Kamerarotation sichtbar.
- Sichtbare echte Hexe in Standard-/Padnahansicht; gesamte deklarierte Karte weiterhin auszoom-/panbar.

## Dateien / Verantwortung
Artagent privat art/polisa_r08_20261111 + output/native_glut_maps/polisa_r08_20261111. Root integriert Produktmap/-visual, Buildtool und enge QA nach Freeze. Runtime-/Tabletopowner bleiben im anderen Chat; MissionSetup-Kamerafunktion/Stationsview bleiben Root.

## Pruefung / Risiken
Nur kleine Layout-/Blocker-/Compilechecks und angeforderte native Ansichten. Grosse Tests spaeter. Hohe Frontwaende koennen Shopwaren verdecken: Cutaway/Glas/Portalhoehen bewusst komponieren. Ports sind sichtbare Geometrie mit Anflugreserve, noch keine grosse Schiffsdockingfunktion. R07 bleibt akzeptierte Grundform, R08 ist gezielte Folge.
