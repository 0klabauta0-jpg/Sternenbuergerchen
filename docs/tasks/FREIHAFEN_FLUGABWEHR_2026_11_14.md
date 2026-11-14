# Freihafen nach Referenz, Flugabwehr-Fahrzeuge fuer GM02 (14.11.2026)

## Ziel / Problem
- Der Freihafen auf `maps/trade_outpost.json` sah nach verstreuten Einzelteilen aus. Der Nutzer hat drei
  Referenzbilder gegeben ("Freihafen / Distribution Center", "Rostgrenze Aussenposten", Basis im roten
  Gelaende) und will etwas Kommerzielles: gepflasterter Hof, helle Gebaeude, Container, Tanks, Funkmast.
- GM02 hatte am Ziel "Flugabwehr" keine sichtbaren Geschuetze.

## Ursache
Die Gebaeude kamen aus der alten geschlossenen Huellenfamilie, der Boden war Wueste, die Requisiten standen
ohne Ordnung. Fuer die Flugabwehr gab es nur Marker.

## Umfang
- Neues Modell-Kit `art/freihafen_kit_20261114/` (Lagerhalle, Buero, Werkstatt, Tankpaar, Funkmast, Tor ohne
  Schranke, Mauerstuecke 4/2/1, Containerbloecke, Paletten, Hoflampe, Vorfeldrahmen mit Bodenmarkierung).
- `tools/dress_trade_outpost.py`: Gebaeude, Warenhof und Landefeld liegen auf einem gepflasterten Vorfeld in
  einer Mauer. Tore nach Osten (Strasse) und Sueden (Pfad). Die Strasse fuehrt an beiden Erzstellen vorbei bis
  vor die Halle des fernen Aussenlagers. Felsen auf und direkt neben der Strasse werden entfernt.
- `scripts/terrain/place_reference_dressing.gd`: ein Eintrag in `structures` darf mit `model` ein eigenes
  Aussenmodell nennen (gleiche Grundflaeche, Front nach +Z). Ohne `model` bleibt die alte Huelle.
- Neues Kit `art/flugabwehr_kit_20261114/`: "Hagel" (Lkw mit Vierlings-Flak) und "Donnerkeil" (Lkw mit zwei
  aufgerichteten Raketen). Eigene Entwuerfe, keine fremden Modelle oder Zeichnungen als Vorlage.
- `tools/build_ground_mission02.py`: beide Fahrzeuge an der Flugabwehr-Stellung, als feste Hindernisse.

## Nicht-Ziele
- Gelaende, Marker, Pads, Dienste, Ressourcen und Missionsdaten beider Karten bleiben unveraendert.
- Die Gebaeude sind weiterhin geschlossene Huellen auf gesperrten Feldern. **Begehbare Innenraeume** (Auftrag
  des Nutzers vom 14.11.: "die Dinger muessen auch von innen nutzbar sein") sind ein eigener Schritt: dafuer
  muessen die Grundflaechen groesser werden und Daecher ausblendbar sein.
- Die Fahrzeuge sind Kulisse. Sie schiessen nicht und sind nicht zerstoerbar.

## Nutzerentscheidungen (14.11.2026)
- Mauer statt Zaun. Keine Schranken, kein Gabelstapler, kein Hofwagen, kein Kran an der Werkstatt.
- Containerbloecke mit einem freien Feld Abstand, damit eine Figur durchpasst.
- Der gerade Vorfeldrand darf Hexfelder halb ueberdecken.
- Die Strasse darf nicht in einem Stummel enden; keine Steine auf der Strasse.
- Fahrzeugnamen eingedeutscht: "Hagel", "Donnerkeil".

## Spielwirkung
- Die Mauer sperrt eine Feldreihe, verdeckt die Sicht und gibt Deckung (80). Durchgaenge: Osttor und Suedtor,
  je drei Felder breit.
- Die Mauer haelt Abstand zu den Landepads (Pad plus 1,2 Felder), damit grosse Schiffe weiter landen koennen.
- Das Vorfeld und die Strasse sind `surface_type: road`.

## Akzeptanzkriterien
- Alle Marker und Ressourcenpunkte bleiben erreichbar (Pruefung im Werkzeug).
- Karten-, Ressourcen- und Handelstests bestehen wie vorher.
- GM02-Pruefer besteht; kein Fahrzeug steht auf einem Weg.

## Betroffene Dateien
`art/freihafen_kit_20261114/`, `art/flugabwehr_kit_20261114/`, `Assets/curated/freihafen_kit_20261114/`,
`Assets/curated/flugabwehr_kit_20261114/`, `tools/dress_trade_outpost.py`, `tools/build_ground_mission02.py`,
`scripts/terrain/place_reference_dressing.gd`, `maps/trade_outpost.json`, `maps/Ground_Mission02_128x128.json`.

## Lokale Pruefung
Siehe `docs/qa/freihafen_flugabwehr_20261114/README.md`.

## Risiken / offene Punkte
- Der Vorfeldrahmen ist ein Modell mit festen Massen fuer genau diesen Hof. Wer `YARD` im Werkzeug aendert,
  muss `APRON_RECT` im Kit nachziehen.
- Keine Stilfreigabe des Nutzers fuer die Fahrzeuge; die Bilder liegen ihm vor.
- Nicht im laufenden Spiel gespielt.
