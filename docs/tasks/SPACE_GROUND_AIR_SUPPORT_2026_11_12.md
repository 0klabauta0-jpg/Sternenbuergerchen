# Gemeinsamer Flugkampf und Luftunterstützung

## Ziel / Ursache

Auf Bodenkarten sollen ein Dropship und weitere Schiffe Luftunterstützung gegen
Luft- und Bodenziele leisten können. Steuerung und Aufträge entsprechen dem
Weltraumkampf; eine allein fliegende Cutlass ist eine Einerschiffsrotte.
Planetoidenatmosphäre erzwingt gekoppelte Flugunterstützung. Dadurch muss der
bisher rein darstellende Luftlayer mit autoritativer Flug-/Kampflogik verbunden
werden, ohne einen zweiten Simulator zu erzeugen.

## Umfang und Grenzen

Bestehenden Flight-, Wing-, Order- und Combat-Owner wiederverwenden. `mission_air`
bleibt Darstellung. Echt gelandete Schiffe behalten Bodenclaims, Boarding und
Landingguards; überfliegende Schiffe erzeugen keine Bodenblocker. Polisa bleibt
direkt anfliegbar. Keine implizite Höhenmechanik, kein ungedeckter Vorteil durch
Visualhöhe, keine Änderung der aktuellen AP6–8-Abnahme als Voraussetzung.

## Pakete und Akzeptanz

1. **Umgebung und Übergang:** planetaren Luftraum an gemeinsamen Flight- und
   Rottenowner binden; eine Cutlass behält Identität, Crew und Einerschiffsrotte.
   Nur coupled bei planetoidischer Atmosphäre; ungültige Commands atomar ablehnen.
2. **Luft- und Bodenziele:** bestehende Sicht-/Ownergrenzen verbinden, Waffenwinkel
   und erlaubte Ziele prüfen, Treffer und Schaden nur durch jeweilige Autorität.
   Luftkampf und Bodenunterstützung verwenden dieselben Waffendaten und Aufträge.
3. **Begleitung und Aufträge:** zweites Schiff/weitere Rotte kann begleiten,
   beschützen, patrouillieren und auf zulässige Ziele reagieren; Verlust,
   Reichweite und Schutzgrenze bleiben begrenzt. Landung und Transport erhalten.
4. **Fliegerbrief und Bedienung:** Schiff/Rotte ähnlich Fireteam auswählen,
   Auftrag, Ziel, Haltung und Feuerregel setzen; Status und Gründe zeigen und
   bisherige Transportbedienung absichern. Keine UI-Zustandswahrheit.
5. **Bündelprüfung:** echte Crew-/Landungsregression, gekoppelt/ausgekoppelt,
   eindeutige Mitgliedschaft, Luft-/Bodenschaden und Sicht, Begleitschiff sowie
   native Bedienung prüfen. Hostautorität und Leistung getrennt nachweisen.

## Grundlagen / betroffene Dateien / Risiken

`space_combat_contract.md`, `flight_altitude_layer_contract.md`, vorhandene
Flight-/Wing-/Order-/Combatowners, Boden- und Landecontracts sowie Dropship-UI.
Konkrete Integrationsdateien vor Änderung mit dem Parallelchat abstimmen. Neue
Zielmodelle und Umgebungseingaben noch nicht implementiert; aktuelle Visuals
stellen keine Luftkampf- oder freie Flugfähigkeit dar.
