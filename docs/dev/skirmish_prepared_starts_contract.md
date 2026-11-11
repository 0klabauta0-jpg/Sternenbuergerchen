# Vorbereitete Skirmish-Starts

Stand: 10.11.2026. Datenquelle: `data/skirmish/prepared_starts.json`.

## Einstieg und Trennung

Der Hauptmenübutton **Skirmish** öffnet die Auswahl von Early, Mid und Late Game.
Ein zusätzlicher Zugang startet weiterhin mit dem eigenen gespeicherten Team.
Ein Preset ist ein frischer, reproduzierbarer Weltstart, kein fremdes Teamprofil
und kein Kampagnencheckpoint. `game_start_contract.gd` transportiert ausschließlich
den validierten `preset_id` zusammen mit `mode=skirmish, action=new`.

`skirmish_start_configuration.gd` erzeugt aus diesem Schlüssel eine deterministische
Roster-/Flottenkonfiguration und gibt sie dem bestehenden Flow. Es liest und schreibt
keine Dateien der Teambibliothek. Der Flow darf auch nach Missionen kein Preset in
`local_player` zurückspeichern. Die Kampagnenführung bleibt für Presets ausgeschaltet.
Regionen, Karte und freie Auftragswahl verwenden die gemeinsamen autoritativen Owner;
keine zweite UI-Welt und keine Festlegung einer späteren Galaxienstruktur.

## Inhalte

| Start | Personen insgesamt | Flotte | Betten / Pads |
| --- | --- | --- | --- |
| Early | 8, davon 3 Piloten | Cutlass und zwei Buccaneer | 8 / 3 |
| Mid | 20, davon 5 Piloten | Vanguard, zwei Hornet, Valkyrie, Hercules | 20 / 5 |
| Late | 30, davon 6 Piloten | Idris, Valkyrie, Hercules, zwei Hornet, Jagdbomber | 30 / 6 |

Alle Personen beginnen mit echtem Sturmgewehr (`rifle`), Pistole und abwechselnd
mittlerer/schwerer Rüstung. Piloten zählen zu den angegebenen Gesamtzahlen;
es gibt keine zusätzlich erzeugte unsichtbare Besatzung. Bodentrupps bestehen
aus maximal vier Personen mit expliziter Zuordnung je Mitglied.

Mid/Late besitzen klar benannte Modellplatzhalter, bis der Nutzer die Modelle auswählt.
Jeep/Panzertransport, mobiler Idris-FOB, Trägerhangar, Wiederbewaffnung und Medic Bed
sind sichtbar als noch nicht bedienbare Ausbauziele vermerkt. Ein generischer
Transportplatzhalter ist kein Nachweis dieser Spezialfähigkeiten.

## Infrastruktur und Personen

`BasePersonnelRuntime` besitzt die echten Basisakteure. `base_capacity_layout.gd`
erweitert die vorhandene eingerichtete Basis bei Konfiguration oder Rekrutierung.
Die beiden ursprünglichen Habitatbetten bleiben unverändert. Zusätzliche Feldbetten
liegen in einem gesonderten Anbau-/Feldlagerbereich westlich der Pads. Bettinteraktionen
und weitere Pads müssen auf der echten feinen Navigation erreichbar sein. Visuals
lesen die vom Runtimeowner verwendete Layoutprojektion.

`sync_roster()` ergänzt neue Personen ohne bestehende Akteure, Schlafreservierungen
oder Wege neu anzulegen. `mark_recruit_remote(unit_id, craft_id)` darf nur vom
geprüften Rekrutierungs-Lifecycle aufgerufen werden: ein aufgenommenes Crewmitglied
bleibt an Bord seines tatsächlichen Schiffs, statt gleichzeitig zuhause zu erscheinen.
Ein Bett darf nur einmal belegt oder reserviert werden.

## Prüfung

- `skirmish_prepared_starts_test.gd`: Menübuttons, Startmetadaten, Größen,
  echte Loadout-IDs, deterministischer Neustart und unveränderte Teamdatei.
- `skirmish_prepared_flow_test.gd`: echter Flow-Handoff, Roster/Flotte,
  keine Kampagnensperren, tatsächliche Ausrüstung/Personen/Betten und Pads.
- `base_capacity_layout_test.gd`: unveränderte Originalbetten, passende
  Kapazitäten und echte AStar-Wege zu jedem Bett-/Padziel.
- `base_personnel_expansion_test.gd`: zustandserhaltende Rekrutierung,
  Schiffsanwesenheit und eindeutige Bettreservierung.

Native Gestaltung und Spielspaß sind durch diese technischen Prüfungen nicht abgenommen.
## Vereinfachtes Einsatzprofil und Punkte

Skirmish bietet einen Start mit 1000 oder 1500 Punkten. Personal, Rüstung,
Waffe und Schiff teilen sich das Budget. Personenvorschläge lassen sich
zufällig erzeugen und vor dem Kauf verändern. Kauf und Rückgabe zeigen
die tatsächlichen Katalogkosten und Restpunkte. Das Modell und der
Startvertrag prüfen dieselben festen Preise, bekannte IDs, das Budget,
einen Bodentrupp, einen Transporter und einen Piloten je gewähltem Schiff.

Drei Erfahrungsstufen setzen bei neu gekauften Personen feste Fähigkeiten.
Wenig erfahren entspricht 0,40, mittelerfahren 0,55 und gut erfahren 0,72.
Die übrigen Kernwerte und Verhaltensachsen folgen der Stufe. Führung
erhält der jeweilige Truppführer, Flugfähigkeiten der Pilot. Zufällige
Eigenschaftsboni entfallen bei diesen gekauften Personen. Der Sanitätskauf
enthält das Medictool. Schiffe und Personen werden über die vorhandene
Startkonfiguration in die autoritativen Runtime-Owner überführt.

Die normale Charakteransicht bezeichnet nur eine exakte Uebereinstimmung aller
vier Faehigkeitsgruppen als Entspricht Vorlage: [Stufe]. Angepasste oder andere
Personen heissen Individuelles Profil; eine Mittelwerteinschaetzung wird nicht
als Erfahrungsstufe ausgegeben. Das beschreibt aktuelle Werte, keine bewiesene
Ausbildungs-/Kaufherkunft. Profilwirkung aus derselben bestehenden Ableitung
bleibt im Werte-Foldout/Tooltip erklaert; Ausruestung, Gelaende und Zustand
bestimmen zusaetzlich die Laufzeitwirkung. Keine alten Profile werden umgeschrieben.

Die ersten Preise sind ein Balanceentwurf. Die bisher spielbaren Cutlass
und Buccaneer bilden den ersten kaufbaren Flottenumfang. Der Punkte-Start
beginnt mit der gekauften Ausrüstung und 0 Cr Handelsguthaben. Unverbrauchte
Punkte sind freie Budgetreserve des Entwurfs. Early/Mid/Late und das eigene
gespeicherte Team bleiben über die Auswahl erreichbar.

Die neue Beschaffung erhält einen kleinen Trupp vollständig. Ein älterer
Startschutz, der für Standardstarts mindestens vier Operatoren herstellte,
darf den bezahlten Roster und die Flotte eines Punkte-Starts nicht ergänzen.

## Begehbare Punktebasis vom 11.11.2026

Der normale Punktezugang wählt zunächst 1000 oder 1500 Punkte und startet mit
`base_setup=true` an der leeren Heimatbasis. Erzeugt werden weder ein freier
Commander noch ein Startschiff, ein Gratislager oder automatisch an den Roster
angepasste Betten. Eine reine Kamera-Verankerung ist keine registrierte Person.
Die ältere vollständig konfigurierte `points_draft`-Startform bleibt lesbar.

`SkirmishEconomyState` besitzt das Budget, bezahlte Infrastruktur, Personal-/
Schiffsrückgabepreise und erfolgreiche Requestbelege am SimulationRoot.
Belege enthalten IDs und Preise, keine zweite lebende Roster-/Loadoutkopie.
Der Runtimeadapter prüft reale Kapazität und Anwesenheit und führt synchrone
Transaktionen mit den bestehenden Besitzern aus. Erst danach wird abgebucht.
Gleiche erfolgreiche Anfrage bedeutet Replay, andere Nutzdaten mit derselben
ID werden abgelehnt. Ein abgewiesener Kauf verändert keine Punkte.

Personenvorschläge werden deterministisch erzeugt und nach dem nächsten
Kaufschlüssel und den belegten Porträt-IDs gecacht. Die tatsächlich gekaufte
Identität entspricht dem angezeigten Vorschlag. Die drei Erfahrungsstufen
gelten für neu konfigurierte Personen. Das Sanitätspaket enthält ein bezahltes
Medictool. Getragene Gegenstände erscheinen ausschließlich beim Loadoutowner.
Neue Personen erhalten das Anzugfach und können einen Rucksack separat kaufen.

Entlassen verlangt eine heimische Person außerhalb von Boarding/Schiff.
Der aktuelle Loadout und der gesamte persönliche Container werden vor der
Mutation gegen die Lagerkapazität geprüft. Das Lager übernimmt die Gegenstände,
der Personalpreis wird erstattet. Wege, Bettreservierungen, Pilotenzuweisung,
Truppmitgliedschaft, Registry, Loadout und persönlicher Container werden gelöst.
Das zuletzt ausgewählte Modell wechselt synchron auf den Basisanker oder die
nächste vorhandene Person.

Habitat und Werkhalle verwenden die vorhandenen Modelle an festen Bauplätzen.
Ein Habitat bezahlt zwei Betten. Zusätzliche Betten liegen im Feldlagerbereich.
Pads werden einzeln gekauft. Die bestehende automatische Roster-Erweiterung
gilt für die bisherigen Presets. Punktebasen lesen ausschließlich ihre bezahlte
Kapazität. Unbebaute Gebäudeflächen öffnen die gespeicherten Blockerzellen.
Errichtung stellt deren ursprüngliche Walkability-, Sicht-, Deckungs- und
Objekthöhenwerte wieder her. Belegte Bauplätze und darüber laufende Wege
werden vor dem Bau abgewiesen. Visuals lesen dieselbe Layoutprojektion.

Schiffe benötigen jeweils einen freien gebauten Landeplatz. Die gekauften
Modelle verwenden den normalen Piloten-, Trupp-, Boarding- und Abflugweg.
Leere, gelandete, unbesetzte Schiffe lassen sich zum bezahlten Preis zurückgeben.
Dabei werden auch Reise- und Supply-Einträge entfernt. Ein zusätzlicher
Pilot-Boardingklick erhält einen bereits akzeptierten Gruppenweg.
