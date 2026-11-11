# Polisa R03 — größere begehbare Handelsstation

Privater Modell-/Mapkandidat auf Rootbranch task/native-glut-maps-20261110,
Ausgangsstand 7c9b5c7b1. Kein Commit, kein Produktionsüberschreiben.

## Ziel und Ursache
R02 besteht visuell aus einer kleinen offenen Halle und drei Pads. Gewünscht
sind sechs Pads an ±WeltZ, echte Ladenräume, Waren/Rüstungsausstellungen und
eine prägnante technische Ring-/Solarsilhouette an ±WeltX.

## Entwurf vor Implementierung
Siehe layout_target.svg: 68×24 Hub, durchgehende Ost-West-Passage, zentrale
Querpassage, sechs mit Türen betretbare Räume. Drei Pads pro Z-Seite:
18×18 klein / 28×34 groß / 18×18 klein. Die 24×30-Reservehülle im Großpad ist
eine Entwurfsannahme für spätere Frachter, keine verifizierte Caterpillarhülle.
Vier Einheiten Gesamtreserve pro Achse, keine technische Schiffsfreigabe.
Ringbaugruppen und Solarfelder liegen ausschließlich an den X-Enden.

## Daten und Umfang
layout.json ist gemeinsame Quelle für Deck, Wände/Türlücken, Tresen,
Showcase-Footprints, Pads und Marker. Offlinecompiler erzeugt sparse192×192
Map und abgeleitete Visualdaten. Visual liest diese Fakten, keine Registry-
oder SimulationRoot-Mutation. Bestehende semantische Marker bleiben erhalten;
polisa_pad_04..06 kommen hinzu. Root integriert Location-/Shopanschlüsse.
Deckoberfläche0.01, flache Bodenmarkierung höchstens0.04. Echtes Viewhexraster
liegt darüber; kein zweites Raster. Cutaway reduziert Dach/Frontwandhöhe,
aber die gespeicherten Wand-/Tresenblocker bleiben echte Hindernisse.

## Quellen / Verträge
PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, graphics_reference_revision_contract,
godot-procedural-worlds Skill, POLISA_STATION_2026_11_11. Port-Olisar-Referenzen
aus art/polisa_lookdev_20261111/references.json und dortigen Originalbildern
tatsächlich geöffnet. R02-Übersicht geöffnet. Externe Bilder sind nur Form-
referenzen; kein Fremdmesh. R07-Armor ausschließlich vorhandene lokale Assets.

## Akzeptanz und Prüfung
Ein verbundenes begehbares Deck; alle sechs Padmarker, Raumzugänge und
Serviceanker erreichbar. Wände/Tresen aus demselben Layout sind gesperrt.
Native Gesamtansicht mit sichtbarem Hexraster plus Laden-/Rüstungsnahansicht,
beide tatsächlich öffnen. Statische Geometrie etwa unter30kDreiecken,
wenige separat ausgewiesene Showcase-Rigs. Keine aktiven Kollisionen,
Partikel, dynamischen Lichter, proFrameLoops oder Actor-NPC-Suchen.
Nur begrenzte Offlinechecks und wenige versteckte native Artaufnahmen.

## Nicht-Ziele / offene Grenzen
Keine Gefechte, Benchmarks, Reise-/Shop-/Saveabnahme, Mainintegration oder EXE.
Neue Rüstung/Waffen-/Schiffsmodelle und Caterpillarimport bleiben ausgesetzt.
2D-Entwurf und native Modellrevision sind keine ästhetische Nutzerabnahme.
