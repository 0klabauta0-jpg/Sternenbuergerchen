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

## Abgleich mit dem aktuellen Bodenstand

Die isolierte Arbeitsbasis `task/space-air-parent-20261112` führt den Stand
`1b924b640` mit dem Raumkampfstand `99d82f999` zusammen; der Fünf-Minuten-
Autosave bleibt erhalten. Der Godot-Ressourcenimport wurde nachgeholt; die
Referenzdatei `art/polisa_lookdev_20261111/references/port_olisar_official.jpg`
meldete dabei einen Importfehler. Der anschliessend wiederholte Polisa-Rundflug
bestand 25/25 ohne Laufzeitfehler und ohne Änderungen der überwachten Quellen.
Eine vollständige Szenen-/Grafikprüfung ist damit nicht belegt.

Der gemeinsame Flugowner liegt bislang im übergeordneten Reise-Root, während
eine Bodenmission ihren eigenen SimulationRoot und ihre Hex-Registry besitzt.
Das Dropship darf deshalb nicht durch einen frei erfundenen zweiten Flugzustand
oder den visuellen Luftlayer als bereits kampfbereit gelten. Für den nächsten
produktiven Schritt müssen derselbe Flug- und Rottenowner, reale Crewbindung,
atmosphärische Kartenkoordinaten, Landungsübergang und Bodentreffer gemeinsam
gebunden werden. Die übrigen Akzeptanzpunkte oben sind weiterhin offen.

Der reguläre Aufbau einer dauerhaften Singleplayer-Bodenmission bindet deren
SimulationRoot jetzt an den vorhandenen übergeordneten Raumkampf-Root. Der
missionsinterne Zugriff prüft Ort und Identität jedes Mal neu und liefert
Referenzen auf die bestehende Fleet-Fluginstanz sowie Rotten-, Kampf- und
Equipmentowner; er erzeugt keine zweite Schiffswahrheit. Auch bereits
vorhandene Missionsorte werden beim erneuten Betreten gebunden. Der vorbereitete
Piloten-/Bodentrefferpfad kann darüber das tatsächliche Schiffsequipment lesen
und weist eine abweichende Pilotenzuordnung oder einen nicht eingebordeten bzw.
flugunfähigen Piloten ab. Ein Fixture mit zwei realen Roots und echten Ownern
prüft Identität, Ortswechsel, Pilotensperre, Treffer und Replay. Das Nachschlagen
allein startet keinen Atmosphärenflug und erteilt keinen Spieler-Feuerbefehl;
die entsprechenden Aufträge, Sicht-/Waffenfreigaben und Darstellung sind offen.

Ein Root-interner Einschlagpfad liest jetzt das belegte Hexfeld direkt aus dem
autoritativen Bodenowner und gibt einen belegten Treffer an den vorhandenen
Schadenspfad. Er erlaubt auch Treffer auf eigene Einheiten, behandelt leere
Felder als Fehlschuss und verbucht eine Ereignis-ID höchstens einmal. Der
aufrufende Flugkampf muss Schiff, Pilot, Auftrag, Sicht, Waffe, Energie und
Streuung weiterhin vorab selbst prüfen; dieser interne Pfad ist noch nicht
mit Spielerbefehlen oder dem Flugtick verbunden. Ein isolierter Test mit echten
Hex- und Schadensownern prüft Treffer, Friendly Fire, Replay, ID-Konflikt,
Fehlschuss und das Entfernen einer eingebordeten Einheit aus dem Bodenindex.

Der Root-interne Pilotenpfad liest inzwischen den Schiffstyp aus dem Equipment-
Owner und `dropship_piloting` beziehungsweise `fighter_piloting` aus dem
registrierten Pilotenprofil, berechnet damit die gestreute Einschlagzelle und
verwendet den Boden-Schadenspfad. Gleiche Ereignisse treffen höchstens einmal;
ein fehlender oder ungültiger Skill wird abgewiesen. Ein Ownercheck nutzt
echte Equipment- und Bodenowner und ein Profilfixture. Zuordnung des Piloten
zum Schiff, Sicht, Feuerauftrag, Waffenkosten und Flugzustand muss der noch
fehlende produktive Aufrufer prüfen. Das ist noch kein spielbarer Feuerbefehl.

## Nutzerfestlegung: bodennahes Repeaterfeuer

Ein Angriff kann auf eine sichtbare gegnerische Einheit oder ein markiertes
feindliches Zielgebiet befohlen werden. Einzelne Lasertreffer streuen um das
Ziel: geringer Pilotenskill bedeutet ein sehr grosses Gefahrengebiet (als
grobe Spielvorstellung etwa 20 mal 20 Hexfelder); mit steigendem Skill wird es
kleiner. Bei maximalem Skill bleiben das Zielfeld und seine sechs direkten
Nachbarn mögliche Trefforte. Auch dort sind Fehlschüsse und Treffer auf andere
Einheiten möglich. Die Laser sollen als Folge einzelner Schüsse wirken und
sichtbar sein, nicht als garantierter Flächenschaden. Exakte Verteilung,
Skalierung und Taktung sind durch Spieltests zu bestimmen; 20 mal 20 ist kein
festgelegtes exaktes Hexradiusmass.

Der Skill muss aus dem autoritativen Profil des tatsächlich zugewiesenen Piloten
und dem passenden Schiffstyp stammen (vorhanden: `dropship_piloting`,
`fighter_piloting`, `freighter_piloting`); keine eigene UI-Wahrheit und kein
vom Client vorgegebener Skill. Zufall und Treffereignisse sind reproduzierbar,
treffen nur belegte Felder und werden durch den Bodencombat-Owner angewandt.
Gebiet, Sicht und Risiko eigener/neutraler Einheiten sind vor dem Befehl
verständlich darzustellen. Das ist ein Zielvertrag, noch keine implementierte
oder balancierte Waffenwirkung.

Zwischenstand: `air_support_dispersion.gd` berechnet zustandslos ein axiales
Hexgebiet mit vorläufig Radius 10 bei Skill 0 und Radius 1 bei Skill 1 und
wählt mit einem übergebenen Seed ein einzelnes Feld gleichverteilt daraus.
Radius 10 umfasst 331 Felder und etwa 21 Felder Breite; dies ist eine
vorläufige spielbare Interpretation der groben 20-mal-20-Vorstellung, keine
festgelegte Balance. Kartenrand wird nicht künstlich nach innen geklemmt.
Der Baustein ist noch nicht an Pilot, Bodenziele, Sicht, Feuerzyklus oder
Anzeige angeschlossen und bewirkt noch keine Luftunterstützung im Spiel. Der
oben beschriebene Root-Pilotenpfad ist ausschließlich intern und noch nicht
an einen produktiven Flug- oder Feuerbefehl gebunden.

## Vorbereiteter Flugregel-Baustein

Der bestehende zustandslose Flugresolver kann den vom autoritativen Aufrufer
gelieferten Kontext `atmosphere` prüfen und weist ausgekoppelte Absichten dort
ohne Mutation zurück. Bisherige Aufrufe ohne Kontext behalten `space` und beide
Modi. Der produktive Bodenkarten-Owner liefert den Kontext noch nicht; deshalb
ist dies keine aktivierte oder global erzwungene Atmosphärenregel. Der kleine
Atmosphärencheck und bestehende AP02-Flugresolvercheck liefen jeweils Exit 0.

Fortschreibung: Der gemeinsame Flugtick und die interne Flugsteuerung werten
für registrierte Bereiche mit `atmosphere:` nun den Atmosphärenkontext aus;
Zulassung und Bewegungscommit weisen ausgekoppelte Zustände zurück. Die Prüfung
verwendet ein lokal registriertes Testschiff. Die Bodenmission erzeugt oder
bindet diesen Bereich noch nicht, und die gemeinsame räumliche Navigation ist
für Bodenkarten weiterhin nicht aktiviert.
