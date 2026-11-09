# Basis: groessere Karte und erhaltene moeblierte Gebaeude wiederherstellen

## Nutzerkorrektur und Ursache

Die Kampagne soll keine verkleinerte, kahle Basis erhalten. Die vereinfachte Gestaltung war fuer den Handelsposten gedacht. Die vorhandenen huebschen Gebaeude mit kleinen eingerichteten Raeumen sollen wieder sichtbar sein. Die Kampagneneinfuehrung hatte die Basis auf22x24 reduziert; AP3 hatte die bestehenden GLBs ausgeblendet und durch kahle Hexwaende ersetzt. Beide Entscheidungen werden fuer die Heimatbasis korrigiert.

## Umfang und Nicht-Ziele

Kampagnenbasis auf die bestehende groessere36x28-Heimatbasis zurueckfuehren. Vorhandene moeblierte Cutaway-Quellen habitat_cutaway_01 und freihafen_hall_01 wieder verwenden; keine neue Assetgenerierung oder Aenderung der Originalmeshes. Keine Ersetzung der Basis durch einen Handelsposten. Handelspostenkarte, zwei Start-NPCs, Auftrag, Versorgung, Fortschritt und Spielstaende bleiben beim bestehenden Runtime-Pfad.

## Referenz

Erhaltene native Aufnahme: docs/reports/assets/grafik-2026-11-01/engine_pass07_paths/after/cutaway.png. Status: historische native Aufnahme des moeblierten Quellenmodells, kein neuer Nachher-Nachweis. Verwendete GLBs unter Assets/curated/frontier_illustrated_20261101/structures_pass04/. SHA256 werden im QA-Paket protokolliert. Grafikreferenz- und Revisionsvertrag sowie homebase_map_services_contract beachten.

## Akzeptanz und Pruefung

- Beide Basisvarianten verwenden36x28-Hexfelder, beide vorhandenen Gebaeudemodelle und stabile Pad-IDs. Ein Startschiff erzeugt weiterhin nur ein reales Schiff.
- Die Originalmodelle bleiben unveraendert und sichtbar; die kahlen Ersatzwaende werden in der Basis nicht zusaetzlich gerendert.
- Bestehende gespeicherte Navigations-/Tuer-/Terminalfakten bleiben pruefbar und erreichbar. Technische Pfadpruefung ersetzt keine native Abnahme der visuellen Gebaeude-/Wegepassung.
- Zwei NPCs, Fortsetzen und Missionspfade bleiben funktionsfaehig; kein Reset alter Profile.
- Hintergrund/Headless, keine sichtbaren Fenster oder Fokuswechsel; lokaler Commit und Mainintegration, kein Push. Eine aktualisierte EXE fuer den Nutzer bereitstellen.

## Dateien und Risiken

maps/campaign_intro_base.json, scripts/meta/explorable_homebase.gd, betroffene Basisverifier, Task-/Vertrags-/QA-Doku. Keine Meshrevision. Originale bleiben als Quellen erhalten. Die alten moeblierten Quellen besitzen ihre eigenen Proportionen und Inneneinrichtung; visuelle Passung zur gespeicherten Navdarstellung ist getrennt zu kennzeichnen und nicht aus einem Gruen im Pathfinder abzuleiten.
