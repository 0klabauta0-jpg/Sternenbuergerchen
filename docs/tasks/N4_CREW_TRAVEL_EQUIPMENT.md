# N4 · Wege, Einsteigen, Reise und persönliche Ausrüstung

13.09.2026. Nutzerauftrag nach dem N3-Spieltest; Basis `ef502214d862024980e581386af57fd098aed87d`, Arbeitsbranch `codex/rostgrenze-crew-reise-ausruestung`.

## Bestätigte Änderungen

1. Figuren laufen durch tatsächliche Türöffnungen und um Schiffe, Felsen, Mobiliar und Wände. Darstellung und autoritative Navigation verwenden dieselben Hindernisdefinitionen. Kein unsichtbarer Teleport ins Schiff: Einsteigen am erreichbaren Zugang, ausdrücklicher Abflug erst nach Besetzung.
2. Ausgewählte Crew + Rechtsklick aufs Schiff steigt ein; ohne Platzvorgabe verteilt der Kern die Rollen nach Fähigkeiten. Manuelle Zuweisung über Plätze/Umschalt+Rechtsklick hat Vorrang: Pilot, Turmschütze, Passagier. Rollen sind besetzbare Plätze, keine festen Namen Ida/Jaro. Aussteigen ist getrennt vom Landen.
3. Reiseweg: einsteigen → abheben → Orbit → Reiseziel → Zielgebiet am Rand schwebend erreichen → bewusst landen → aussteigen. Ein sichtbarer Orbit ist eine eigene Karte und eine übersichtliche Zielkarte zeigt benannte Orte statt unklarer Flugmarkierung. Begegnungen können Reisen unterbrechen, ohne neu zu würfeln.
4. Koop: beide verbundenen Commander dürfen sämtliche Crew, Schiff, Arbeit, Handel und gemeinsame Pause befehligen. Netzwerkautorität/Validierung bleiben beim Host. Das ist keine Aufweichung eines späteren PvP-Besitzmodells; Sitzungsverwaltung und lokale Dateizugriffe bleiben beim Host.
5. Doppelklick auf das Crewporträt öffnet das persönliche Dossier. Sichtbare Figur mit passenden Drag-and-drop-Ausrüstungsplätzen für Helm, Rüstung, Werkzeug und kaufbaren Rucksack. Inventartransfers prüfen Herkunft, Ausrüstbarkeit, Nähe und Kapazität; keine Materialduplizierung.
6. Multi-Tool mit auswechselbaren Mining-/Salvage-Aufsätzen bildet den ersten Handberuf. Medgun behandelt eine erreichbare Person mit tatsächlicher Wirkung und begrenztem Verbrauch. Kauf/Herstellung und aktive Ausrüstung sind sichtbar.
7. Gleiche Wandform vorn/hinten, vorne nur reduzierte Deckkraft. Betten an die Unterkunftswand; für diese Runde zwei bestehende plus vier zusätzliche Betten, ohne dadurch schon Rekrutierung zu behaupten. Bunker geschlossener wirken lassen. Wege etwas organischer, bestehender Rostwelt-Referenzstil bleibt; kein neuer InselKrieg-Geländestil und keine Gebirgsgeneration.
8. Entersäbel lokal in Blender nachbearbeiten: übersichtliches Fahrwerk, störende vordere Flügel-Anbauten entfernen, Waffen nur am tatsächlich drehbaren Turm. Originalquelle unangetastet.
9. Kamera fährt passend zur Zoomstufe flotter; WASD bleibt Kamerabewegung. Außenkarten mindestens 960×960 m, Verteilzentrum darf großzügiger sein. Raum-/Innenkarten erhalten eigene zweckmäßige Grenzen.

## Arbeitsteilung und Abnahme

Der Kernvertrag für Schema, Commands, Sitzbelegung, Orbit und persönliche Gegenstände wird zuerst in `docs/contracts/N4_CREW_TRAVEL.md` festgelegt. Kern und UI bleiben getrennt. Welt/Nav müssen gemeinsame statische Anordnung und dynamischen Schiffsumriss teilen. Geeignete Integrationstests prüfen Umwege, Türdurchgänge, Einsteigebewegung, unbesetzten Abflug, Rolle/Turm, Orbitalreise, schwebende Ankunft, Inventar/Heilung, Save-Migration und echte gemeinsame Koop-Befehle.

Der echte Fensterweg muss die neuen Bedienhandlungen belegen, einschließlich Drag-and-drop und Doppelklick. Abschließend aktuelle Bilder, mobiler Bericht und Windows-Paket erneuern. Git nur eigener Branch; private Modelle bleiben lokal, keine Veröffentlichung des Spiel-ZIP.

Langfristig unabhängig auf verschiedenen Karten arbeitende Teams sind die bestätigte Organisationsvision. N4 schafft gemeinsame Befehle und explizite Besatzung; parallele unabhängige Regionssimulation ist ein eigener größerer Folgeschritt und wird nicht allein durch neue Koop-Rechte als geliefert bezeichnet.

Nachgereichte Gestaltung: Außenposten und Bunker nach Bethesda/Starfield-Bildreferenzen und gegebenenfalls vorhandenen Bildern im KlabsCom-Projekt. Der Nutzer hat begehbare Schiffsinnenräume ausdrücklich für den nächsten Ausbau gewählt: Schnittansicht und sichtbare Wege zwischen Cockpit, Turm, Lade-/Betankungsstationen. N4 zeigt die Wege bis zum Schiffszugang. Keine neuen Großschiffe ohne konkreten ersten Spielweg.
