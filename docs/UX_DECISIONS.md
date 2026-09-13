# Oberfläche und Bedienung · 13.09.2026

## Aktuelle N4-Entscheidungen

Der Skill `game-ux-design` bleibt Grundlage. Auswahl und Befehl sind getrennt: Linksklick wählt, Rahmen wählt eine Gruppe, Rechtsklick auf Boden bewegt die Auswahl. Rechtsklick auf das gelandete Schiff startet Einsteigen nach Fähigkeiten; Umschalt + Rechtsklick beziehungsweise „Plätze“ erlaubt manuelle Rollen. Der Pilotenplatz und alle aktuellen Personen müssen tatsächlich an Bord sein, bevor Abheben angeboten wird. Im Koop darf jeder Commander dieselbe Crew befehligen.

Lokale Flugziele tragen eine eigene Beschriftung. Die Reisekarte ist ein separates Fenster mit benannten Orten, Größe, Ankunftsregel und Begegnungsrisiko. Sie kann aus dem lokalen Flug als Übersicht geöffnet werden; den Ortswechsel erlaubt erst der Orbit. Landen und Aussteigen sind getrennte Aktionen. Der native Rollenpopup berücksichtigt die Hauptfensterposition und die Viewporttransformation.

Doppelklick auf ein Porträt öffnet das Dossier. Fünf Slots stehen bei der sichtbaren Figur, daneben Lager, Schiffsfracht und persönlicher Rucksack. Gegenstandsquelle, Menge und Kapazität bleiben sichtbar; Hostbestätigung und Ablehnung werden unterschieden. Pflichtwerkzeuge werden vor dem Gewinnungsauftrag erklärt. Die Medgun-Schaltfläche respektiert Ausrüstung, Ladung und Einsatzfähigkeit; der Kern prüft zusätzlich Entfernung und Sicht.

Werkstatt und Markt verwenden kompakte Symbolaktionen in einem scrollbaren Kontext, damit zusätzliche Gegenstände die Karte nicht vollständig verdecken. Der Markt erklärt jetzt bewusstes Entladen am Heimatdock. Kamera-WASD bleibt von Figurensteuerung getrennt und bewegt sich weiter herausgezoomt schneller; Mausradzoom wurde beschleunigt.

Abnahme: 76 Prüfungen im aktuellen Produktweg, 7 in der manuellen Rollen-/Popup-Probe, 13 Steuerungsprüfungen und 22 Dossierprüfungen. Das sind technische Bediennachweise, kein Ersatz für menschliche Spiel- und Verständlichkeitstests. Details: [N4_ACCEPTANCE.md](N4_ACCEPTANCE.md).

## Historische Grundlage N1 · 12.09.2026

Angewendet: lokal angelegter Skill `game-ux-design`, besonders `design-playbook.md`. Ziel ist eine kleine Crew aus der Welt heraus zu führen, Aufträge zu verstehen und mit tatsächlich vorhandenen Materialien zu arbeiten. Plattform dieser Prüfung: Windows, Maus/Tastatur, Godot 4.6.2.

## Konkrete Befunde und Änderungen

| Evidenz | Hindernis | Umgesetzt | Technische Prüfung |
|---|---|---|---|
| Screenshot und Code | Hohe Textleisten und große Dauerkarte verdrängen die Welt | Schmale Statusleiste, linke Objekt-Icons, Crewporträts unten, Kontextaktionen nur bei Auswahl | Echte Basis-, Werkbank-, Markt- und Missionsfenster |
| Code | Crewwahl schloss das geöffnete Arbeitsmenü und versetzte die Kamera | Auswahl getrennt von Fokus; Klick und 1/2 wählen, eigenes Zielsymbol fokussiert | Produktpfad prüft Kontext nach Crewwechsel |
| Code | Sperrgründe für Material, Technik oder Besitz erst nach Klick | Kurzer Sperrstatus am Rezept, voller Grund/Kosten im Tooltip; Core prüft weiterhin selbst | Ungeeigneter Arbeiter, reservierte Materialien, Blueprint und Besitz |
| Screenshot und Code | Pausierte Arbeit ohne eindeutiges Rezept oder gebundenen Arbeiter | Rezept, Person, Reservierung und Arbeitsphase; laufender Auftrag auch außerhalb seines Menüs sichtbar | Herstellung, Pause, Abbruch, Save/Laden |
| Nutzerkorrektur | WASD-Figurensteuerung entsprach nicht dem gewünschten Point-and-Click | Rechtsklick bewegt Auswahl; Rahmen wählt Gruppen; Ansichtsschalter aktiviert Kamerafolge | Reale Maus-/Tastaturereignisse im Produktfenster |
| Code | Fehlgeschlagener Autosave konnte beim Schließen untergehen | Bei Speicherfehler offen bleiben, sichtbarer Grund; gültige Karriere beim Start fortsetzen | Vier getrennte Produktstarts einschließlich defekter/unbeschreibbarer Testdatei |

Besitz ist als DU/HOST/GAST beschriftet. Auswahl, Objektkontext, Kamerafokus und Laufziel bleiben unterschiedliche Zustände. Die dünnen, kantigen Flächen und Icons sind bewusst eine neue Gestaltung; keine Oberfläche anderer Spiele wurde als Asset übernommen.

## Betrachtete Bildreferenzen

Über Web-Bildsuche gefunden und zusätzlich im Browser visuell betrachtet:

- [Homeworld 3 – Screenshotgalerie](https://www.gamestar.de/galerien/homeworld_3,136199.html): kompakte Einheitenkarte unten, schmale Befehlsleisten und priorisierte Akzentfarbe.
- [IXION – offizielle Galerie](https://www.kasedogames.com/ixion): feine technische Rahmen, Symbolfunktionen und kurze objektbezogene Informationen.
- [Dune: Spice Wars – Gameplay-Screenshot](https://www.altchar.com/features/dune-spice-wars-preview-the-spice-must-flow-aZMO29j838Pg): Ressourcen am Rand, kompakte Auswahlfelder, freie Kartenmitte.

Die Übertragung auf dieses Spiel ist eine Designentscheidung. Technisch geprüfte Klickpfade und Screenshots belegen weder allgemeine Verständlichkeit noch Spielspaß. Menschliche Spieltests, Controller, Screenreader und Textskalierung sind noch nicht abgenommen.
