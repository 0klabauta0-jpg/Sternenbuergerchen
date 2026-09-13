# Internet, Ausrüstung und neue Außenposten

Nutzerauftrag 13.09.2026, aufbauend auf 7f5fcc4. Arbeitsbranch `codex/rostgrenze-internet-aussenposten`.

## Zusammenhängende Spielerwege

1. Das alte Hintergrundbild mit der Frau begrüßt im neuen Hauptmenü. Bestehende Karriere fortsetzen, neu beginnen oder Internet-/LAN-Koop öffnen. Internet-Koop soll zwei Heimnetze ohne manuelle Routerkonfiguration verbinden; ein zeitweiliger verschlüsselter Einladungslink führt durch einen vom Spiel verwalteten Tunnel. Zugangsschlüssel, Protokoll und Schema werden vor Spielzustandübertragung geprüft. Öffentlich erreichbarer echter Transport wird getrennt von Loopback geprüft. Kein dauerhafter Systemdienst und keine Routeränderung.
2. Rüstung kaufen oder an der Werkbank herstellen, ausrüsten und sichtbar an der vorhandenen Helmfigur tragen. Schutz wirkt auf tatsächlichen Bodenschaden. Fähigkeiten erhalten nachvollziehbare Wirkungen; die Crewakte und der Handybericht nennen vorhandene Werte, Auswirkungen und verbleibende Grenzen der Charakterentwicklung.
3. Das Satellitengebiet wächst und erhält Erkundungsgründe: Erzstelle, Schiffswrack und Restmaterial am bereits geborgenen Satelliten. Ein Miet-Bergungsschiff „Geier“ aus dem lokalen Vulture-Modell verlangt zunächst verdiente Credits. Mietkosten, Rückgabe und Bergungsertrag bleiben beim Simulationskern.
4. Bunkeroberfläche mit schwacher Flak und einfachen Gegnern. Entfernt landen, zu Fuß ins Gebäude, transparente Sichtseiten und Aufzug in eine separat geladene unterirdische Bunkerkarte. Erster einfacher Bodenkampf und Rückkehr nach Ausfall ohne permanenten Figurenverlust.
5. Eigenständiges großzügiges Verteilzentrum mit Hallen, Frachtflächen und mehreren Wegen; zusätzlich kleiner Handelsposten auf eigener großer Karte. Weitere Fundstellen machen auch Erkundung abseits des Marktes sinnvoll. Jeder Ort wird einzeln geladen.

## Ausführung und Zuständigkeiten

- Kern und Katalog: versionierte Zustände, Migration v1/v2, Befehle, Skills, Ausrüstung, Berufe, Miete, Bodenbegegnungen, Grenzen und Wegfindung. V3-Vertrag vor paralleler Integration.
- Welt: bestehende Kenney-Basis, lokale Blender-Konvertierung, separate Ortslayouts, Rüstungsdarstellung und Sichtwände. Keine eigene Gameplay-Wahrheit.
- Netzwerk: bestehendes ENet-LAN erhalten, zusätzlicher Internettransport mit Authentifizierung und begrenztem Lebenszyklus. Keine UI- oder Kernmutation neben dem Gateway.
- Root: Menü, Kontextoberfläche, Integration, tatsächliche Fensterprüfungen und Aktualisierung derselben privaten mobilen Site.

## Abnahme

Reale Spielhandlungen mit vorhandenen Saves und neuer Karriere, isolierte Kernregressionen, sichtbare Rüstung/Orte/Schiff, Laden jeder Karte, Mining-/Bergungs-/Miettransaktionen, Bodenkampf/Rückkehr, Aufzug und Navigation. Internetprüfung mit echten Prozessen über öffentlichen WSS-Endpunkt sowie falschem Schlüssel/Protokoll. Keine Behauptung einer Heimnetzprüfung in Österreich ohne dortigen zweiten Rechner. Kurze Leistungsstichproben der größeren Karten, frischer Clone ohne lokale Modelle und eindeutig datierter Handybericht. Nicht implementierte langfristige Systeme bleiben ausdrücklich als geplant markiert.
