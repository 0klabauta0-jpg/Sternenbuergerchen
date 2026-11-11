# Weltraumkampf: Rotten, Raumflug und Komponenten

Stand: 11.11.2026. **Vom Nutzer bestätigtes Zielkonzept; noch keine Implementierung.**
Auftrag: Konzept festhalten und in kleine umsetzbare Pakete schneiden.
[Task](../tasks/SPACE_COMBAT_2026_11_11_PLAN.md) ·
[Umsetzungsplan](../superpowers/plans/2026-11-11-space-combat.md)

## 1. Ziel und Entscheidungsstand

Der Spieler führt Rotten wie Fireteams: Er bestimmt Auftrag, Ziel, Haltung und
Feuerfreigabe. Piloten führen Anflüge, Drift, Ausweichen und Zusammenarbeit aus.
Der Kampf läuft in Echtzeit ohne Pause. Er soll verständlich zu steuern sein,
sichtbare Raumflugmanöver bieten und auch bei mehreren Rotten lesbar bleiben.

Die Entscheidungen F01–F16 sind durch das Gespräch einschließlich „Ja, so machen
wir das“ bestätigt. Technische Zuschnitte und Zahlen unter „Startannahmen“
sind Umsetzungsvorgaben für den ersten prüfbaren Stand, keine behaupteten
Nutzerentscheidungen und keine bereits abgenommene Balance.

| ID | Verbindliche Festlegung |
| --- | --- |
| F01 | Eine taktische Kampfebene, 2,5D-Darstellung. |
| F02 | Ein leichter Jäger entspricht einem Hexfeld; größere Schiffe beanspruchen mehrere Felder. |
| F03 | Eine Rotte besteht aus **1 bis 6 Schiffen**, ähnlich wie ein Fireteam zusammenstellbar. |
| F04 | Mehrere Rotten können gemeinsam einen Auftrag erhalten und darin Rollen übernehmen. |
| F05 | Fliegen, Patrouillieren, Ort sichern, Beschützen, Ziel angreifen, Bereich angreifen und Zurückziehen/Sammeln. |
| F06 | Schutzobjekt kann ein Ort, ein einzelnes Schiff/Großschiff oder eine andere Rotte sein. |
| F07 | Auftrag, Haltung und Feuerregel bleiben getrennt; passives bis offensives Verhalten ist möglich. |
| F08 | Gekoppelter und ausgekoppelter Raumflug gehören beide zum System. |
| F09 | Masse, Haupt-/Brems-/Seitenschub und Trägheit begrenzen Beschleunigung und Wendigkeit. |
| F10 | J-Hook (ausdrücklich so präzisiert), Ausweichstoß, Schere, rollendes Ausweichen, Strafemanöver nach Quadstrafe-Vorbild und koordinierter Doppelangriff. |
| F11 | Feuerziehen/Ablenken ist ein Manöver mit tatsächlicher Gegnerreaktion, kein erzwungener Zielwechsel. |
| F12 | Pilotenskill verbessert Ausführung und entwickelt sich; anspruchsvolle koordinierte Manöver können freigeschaltet werden. |
| F13 | Zunächst Laser-Repeater; Größenreferenz S1–S5. Schiffsrumpf bestimmt Anzahl, Größe und Richtung der Waffenslots. |
| F14 | Waffen, Schildgeneratoren und Kraftwerke sind austauschbare Komponenten mit tatsächlicher Wirkung. |
| F15 | Sichtbare Laser, Schild-/Hüllentreffer, Explosionen, Haupt-/Manövriertriebwerke und auslaufende Flugspuren. |
| F16 | Sonnenlicht und Schatten dienen zunächst Atmosphäre und Lesbarkeit; Dunkelheit allein erzeugt keine Sensorunsichtbarkeit. |

## 2. Karte, Maßstab und Darstellung

Der Kampf findet auf der vorhandenen Sternkarte statt, ohne obligatorischen
Wechsel auf eine separate Gefechtskarte. Die aktuelle native Karte hat
256×256 Hexe; 512×256 betrifft die Bodenkarten A/B/C. Die Karte komprimiert
astronomische Distanzen. „Ein Jäger = ein Hex“ ist eine Spielgrößenregel,
keine Übernahme realer Meter oder Kilometer aus Star Citizen.

Position und Bugwinkel sind kontinuierlich. Das Hexraster dient Planung,
Auswahl, Belegung und räumlichem Index. Ein leichter Jäger besitzt eine
logische Ankerzelle; während eines Flugsegments sind auch durchflogene
Zellen/Kanten zeitlich zu berücksichtigen. Große Rümpfe benötigen einen
orientierten Mehrfeld-Footprint einschließlich der beim Drehen überstrichenen
Fläche. Freie Start- und Endfelder beweisen keinen freien Flugweg.

Schiffe dürfen sich optisch neigen und rollen. Ihre spielwirksame Lage bleibt
auf einer Ebene; Höhe, Rollen oder Effektausdehnung vergeben keine unsichtbaren
Treffer-/Ausweichvorteile. Die Fassrollen- und Quadstrafe-Varianten werden
entsprechend adaptiert, keine vollständigen räumlichen Schraubenbahnen.

## 3. Rotten und gemeinsame Aufträge

Ein Schiff gehört höchstens einer Rotte an; unzugewiesene Schiffe bleiben im
bestehenden Schiffsbestand. Eine aktive Rotte hat 1–6 Mitglieder und genau
einen bestimmten Rottenführer. Dieselbe Person darf nicht zugleich mehrere
Schiffe pilotieren. Pilotenidentität und Boarding bleiben bestehende Wahrheit.

Gemeinsame Aufträge referenzieren bestehende Rotten und kopieren keine Schiffe.
Ein Auftrag kann beispielsweise Rotte A als engen Begleitschutz und Rotte B als
Abfanggruppe führen. Einzelne Rotten können abgelöst werden; die übrigen führen
den Auftrag weiter aus. Verlust, fehlender Pilot, unerreichbarer Teilnehmer
oder zerstörtes Schutzobjekt führen zu einem sichtbaren Status und einer
definierten Rückfallaktion.

Die Formation ist ein flexibles Zielbild. Bei engem Raum dürfen Mitglieder
geordnet ausweichen und sich sammeln; starre Slots dürfen keine dauernden
Blockaden erzwingen. Unterschiedliche Schiffsgeschwindigkeiten begrenzen das
gemeinsame Marschtempo, nicht automatisch jeden individuellen Abfangflug.

## 4. Auftrag, Haltung und Feuerregel

| Ebene | Inhalt |
| --- | --- |
| Auftrag | Fliegen, Patrouillieren, Ort sichern, Beschützen, Ziel-/Bereichsangriff, Zurückziehen/Sammeln |
| Haltung | Vorsichtig, normal, offensiv; beeinflusst Risiko, Abstand, Anflug und Abbruchbereitschaft |
| Feuerregel | Feuer halten, Antwortfeuer, Feuer frei |
| Passiv-Preset | Feuer halten und Kontakte meiden; kein heimlicher vierter C/N/A-Wertebestand |
| Manöver | Zeitlich begrenzte Ausführung innerhalb des Auftrags, danach Rückkehr zum Plan |

Die Boden-Bediengrammatik wird übernommen, nicht deren Infanterieausführung:
Jäger müssen beim Kontakt nicht wie Bodeneinheiten stehenbleiben.
Feuer halten ist absolut. Ein Angriff mit dieser Feuerregel kann den Anflug
ausführen, meldet aber „Feuerfreigabe fehlt“; die UI darf die Regel nur durch
einen expliziten sichtbaren Command ändern.

Schutzaufträge besitzen Schutzradius, maximale Verfolgungsdistanz und
Rückkehrregel. Eine offensive Eskorte verlässt diese Grenzen nicht für freie
Jagd. Antwortfeuer bei Beschützen umfasst erkannte Angriffe auf das Schutzobjekt.
Auch Feuer frei erlaubt nur Ziele innerhalb der Auftragsgrenzen und der
bekannten Kontakte. Neutrale Schiffe werden nicht still feindlich.

Bereichsangriff bekämpft erkannte Gegner im markierten Raum. Fehlende Kontakte
beweisen nicht, dass überall alle Gegner vernichtet sind. Patrouillen laufen
bis Abbruch weiter. Schutzketten dürfen keine zyklischen Bewegungsbefehle
erzeugen; V1 lehnt neue Schutzzyklen mit verständlichem Grund ab.

## 5. Ein Flugmodell, zwei Assistenzmodi

Jedes Schiff besitzt Position, Geschwindigkeitsvektor, Bugwinkel und
Drehgeschwindigkeit. Hauptschub/Masse bestimmt die Vorwärtsbeschleunigung;
Brems- und Seitentriebwerke besitzen eigene Grenzen. Drehmoment/Trägheit
bestimmen die Drehbeschleunigung. Bugdrehung und Flugbahnkrümmung sind getrennt.

- **Gekoppelt:** Assistenz richtet die Bewegung mit den verfügbaren Triebwerken
  zur gewünschten Flugrichtung aus und baut unerwünschte Drift ab.
- **Ausgekoppelt:** Ohne Schub bleibt die Geschwindigkeit erhalten. Das Schiff
  dreht den Bug unabhängig und kann seitlich oder rückwärts gleitend feuern.
- Umschalten verändert weder Position noch Geschwindigkeit sprunghaft.
- Bremsen und Umlenken benötigen Zeit und Schub. Gleichzeitige Schubachsen
  teilen ein definiertes Leistungsbudget; keine kostenlose diagonale Mehrleistung.
- Piloten wechseln innerhalb der erlaubten Doktrin automatisch. Der Commander
  kann einen Flugstil bevorzugen, ohne jeden einzelnen Schubimpuls zu steuern.
- Schnellere Fahrt vergrößert bei gleichem Seitenschub die Bahnkurve. Sie
  verhindert nicht grundsätzlich eine unabhängige Bugdrehung.

## 6. Gefechtsablauf und Manöver

Grundablauf: Anflug → Feuerfenster → Absetzen → Neuansatz/Sammeln. Je nach Lage
kann ein ausgekoppeltes Feuerfenster an die Stelle eines klassischen Vorbeiflugs
treten. Kein erzwungenes Dauerkreisen und kein garantiert siegreiches Rückwärtsfeuern.

| Manöver | Spielwirksamer Ablauf und Grenze |
| --- | --- |
| J-Hook | Vorbeiflug, Auskuppeln, Bug zum Gegner drehen, Driftfeuer, Absetzen. |
| Ausweichstoß | Seitlicher Schub verändert tatsächlich die Bahn und gegnerischen Vorhalt. |
| Schere | Begrenzte Richtungswechsel, um Verfolgung/Feuerfenster zu erschweren. |
| Rollendes Ausweichen | Seitlicher Ausweichbogen mit sichtbarer Rollanimation; Rollen allein gibt keinen Bonus. |
| Quadstrafe-Adaption | Kombinierte Schubimpulse und Drehung auf der Ebene, innerhalb derselben Schubgrenzen. |
| Doppelangriff | Zeitlich versetzte Feuerfenster zweier Mitglieder/Rotten; Abbruch bei Verlust/Unerreichbarkeit. |
| Feuerziehen | Zeigen/Angreifen/Absetzen in eine Richtung; Gegner können folgen oder beim ursprünglichen Ziel bleiben. |

Jedes Manöver hat Eintrittsbedingungen, Phasen, maximale Dauer,
Abbruchbedingungen und Rückkehr zum Auftrag. Freie Flugbahn, Schiffsvermögen,
Feuerregel und Schutzbindung gewinnen vor einer schönen Animation.

## 7. Treffer, Komponenten und Pilotenskill

Schaden bleibt datenbasiert. Die Simulation prüft Kontakt, Feuerfreigabe,
Reichweite, Waffenwinkel/Schwenkvermögen und freie Schussbahn. Relative Bewegung
und Zielstabilität beeinflussen den Treffer. Sichtbare Laser sind Projektion
autoritativ entschiedener Schüsse. Friendly Fire bleibt gemäß Projektgrundsatz
aktiv; ein eigener Rumpf kann eine Schussbahn abfangen.

Die erste Waffenfamilie sind Laser-Repeater. S1 Bulldog, S2 Badger, S3 Panther,
S4 Rhino und S5 Galdereen dienen als Größenreferenz. Das ist weder ein Anspruch
auf die größte aktuell existierende SC-Waffe noch ein Import von SC-Balancewerten.
Eigene Katalogwerte definieren Masse, Energiebedarf, Reichweite und Wirkung.

| Komponente | Verbraucher |
| --- | --- |
| Waffen | Feuerfolge, Wirkung, Reichweite, Waffenreserve und Feuerrichtung |
| Schildgenerator | Kapazität, Erholungsverzögerung, Wiederaufladung und Energiebedarf |
| Kraftwerk | Verfügbare Leistung für Schubbudget, Waffenreserve und Schildaufladung |

Der Rumpf legt Anzahl/Maximalgröße der Slots und feste oder schwenkbare
Feuerbereiche fest. Mehr/größere Waffen brauchen passende Slots, Masse und
Leistung. Installation tauscht echte Bestände aus; ausgebaute Teile gehen
in einen autoritativen Container zurück. Eine Komponentenanzeige ohne
Runtimewirkung gilt nicht als fertige Ausrüstung.

Pilotenskill verwendet die bestehende Personenidentität und „Jäger steuern“.
Grundlegendes Ausweichen, Absetzen und beide Flugmodi sind allen Piloten möglich.
Skill verbessert Reaktion, Vorhalt, Schubdosierung, Zielstabilisierung und
Zusammenarbeit. Heftiges Ausweichen erschwert auch das eigene Zielen; erfahrene
Piloten verlieren dabei weniger Stabilität. Physische Schiffsgrenzen bleiben.

Erfahrung entsteht aus belegten Einsätzen/Kampfhandlungen. Freischaltungen
betreffen anspruchsvollere koordinierte Abläufe. Derselbe Einsatz/Beitrag
wird durch Wiederholung, Gruppenauftrag, Ansichtswechsel oder Laden nicht
mehrfach belohnt. Keine Erfahrung nur für wiederholte Manöver im leeren Raum.

## 8. Sichtbarkeit und Bedienung

Rottenkarten zeigen Mitglieder, Pilot, Auftrag, Haltung, Feuerregel und den
entscheidenden Zustand. Mehrfachauswahl erteilt gemeinsame Aufträge. Auf der
Karte erscheinen bei Auswahl Flugweg, Bewegungsrichtung/Bugrichtung, Ziel,
Schutzradius und Feuerbereiche. Normale Ansicht bleibt ruhig.

Kurze Zustände: „Fängt ab“, „Kehrt zur Eskorte zurück“, „Feuerfreigabe fehlt“,
„Sammelt sich“, „Schild kritisch“, „Gegner folgt“, „Gegner hält Kurs“.
Ausgefallene oder unmögliche Aufträge verschwinden nicht still.

VFX lesen tatsächliche Ereignisse: Repeaterimpulse/Mündungsblitze,
unterschiedliche Schild-/Hüllentreffer, zur Schiffsklasse passende Explosionen,
Trümmer und Funken. Hauptstrahl folgt aktuellem Schub; seitliche Düsen zeigen
Manövrierimpulse. Ausgekoppeltes Gleiten erzeugt keinen Dauerschub.
Schweife bleiben kurz im Raum und laufen aus, statt starr am Schiff zu hängen.
Schatten lassen Identität, Konturen und Auswahlmarken lesbar.

VFX-Ausblendung, Kamerawechsel und geringere Effektqualität verändern weder
Treffer noch Flugbahn, XP oder Auftragsfortschritt.

## 9. Architektur und belegter Ausgangsstand

Geprüfte Planbasis: nativer Taskstand
`84dd481b187299d3832ded3596bbc01dfd62abe9`,
`task/native-glut-maps-20261110`; noch nicht als Mainintegration ausgegeben.
Der Doku-Branch baut bewusst darauf auf. Vor Umsetzung AP00 Drift und
Integration mit laufenden Ground-/Lifecycle-Arbeiten erneut prüfen.

- `scripts/core/strategic_hex_grid.gd`: axiales 256×256-Raster, Kurvenroute,
  normalisierte Reiseprojektion.
- `scripts/ui/star_map_world_view.gd`: orthografische 3D-Sternkarte, ebene
  Schiffsposition und Heading; keine vollständige Kampfsimulation.
- `singleplayer_space_travel_state.gd` / `singleplayer_fleet_travel_state.gd`:
  individuelle Reisezustände und Spielerflottenindex.
- `campaign_space_encounter.gd`: begrenzte Begegnung mit festem Schaden;
  keine allgemeine Rotte-, Bewegungs-, Schild- oder Komponentenmechanik.
- `docs/dev/polisa_ship_equipment_contract.md`: Komponenten ausdrücklich
  noch offen; Erkul-Daten nur Referenz.
- `scripts/npc/unit_profile_math.gd`: vorhandener Wert
  `fighter_piloting` auf Skala 0–1, noch kein belegter Manöververbraucher.

Zieldatenfluss: Commander-Command → Rotten-/Gruppenplan → reine Resolver →
SimulationRoot-Commit → gemeinsame Snapshots → UI/Visuals.

Ein gemeinsamer pro-Schiff-Flugzustand wird von Reise und Kampf referenziert,
nicht kopiert. Root bestimmt pro Tick genau einen Bewegungsmodus:
Reise/Quantum oder taktischer Flug. Der Reiseowner behält Phasen-/Ortsbindung;
er darf im taktischen Modus nicht zusätzlich die Quantumroute fortschreiben.
Gegner und neutrale Kampfobjekte erhalten eigene Runtimeidentitäten, aber
keinen Eintrag in Spielerhangar, Supply, Padbelegung oder Spieler-Roster.

Der aktuelle Renderprozess treibt Reisezeit noch über den Runtimeadapter an;
AP01 ersetzt dies durch einen begrenzten Physiktick im CampaignSimulationRoot.
Ansichtswechsel dürfen diesen Takt nicht stoppen. Bestehende Bodenroots
erhalten dadurch keinen zusätzlichen Raum- oder zweiten Bewegungstick.

Schiffsausrüstung und Rotten sind eigene begrenzte Datenbereiche unter Root.
Registries indexieren, Resolver schlagen vor; weder Registry noch UI erfinden
Gameplayzustand. Bestehende Boden-Combat-/LOS-/Höhenregeln bleiben eigenständig.
Die interne vollständige Weltsicht wird vor UI-/Clientprojektion auf die
berechtigte Fraktion gefiltert. Unbekannte Gegnerdaten werden nicht übertragen.
Laufende Manöverphasen liegen im Combatowner; Schussereignisse bewahren ihre
Geometrie vom Ereigniszeitpunkt auch nach Bewegung oder Zerstörung des Ziels.

## 10. Startannahmen und Grenzen für V1

Diese Zuschnitte machen die Umsetzung prüfbar und dürfen anhand der kleinen
Spielprobe nachjustiert werden:

- Zunächst lokale autoritative Gefechtsfixture; kein neuer Matchmakingdienst.
- Ein gemeinsamer Schildpool pro Schiff, feste automatische Leistungspriorität
  für Flugsicherheit, anschließend Waffenreserve und Schildaufladung.
  Keine manuelle Energie-Dreiecksbedienung in diesem ersten Umfang.
- Komponenten bleiben kataloggebundene Stückware im bestehenden Inventar.
  Slots speichern Item-IDs; keine neue individuelle Komponenteninstanzverwaltung.
- V1 verhindert Rumpfdurchdringung; Rammen als Schadensmechanik wird nicht eingeführt.
- Quantum/Anflug/Landung sind während aktiver Kampfbindung gesperrt.
  Rückzug beendet die Bindung erst nach tatsächlich erreichtem sicheren
  Sammel-/Austrittspunkt; kein sofortiger Schutz durch einen UI-Klick.
- Bestehende Heimatcheckpoint-Grenze bleibt. Neue Rotten/Ausrüstung/Skills werden
  dort versioniert gespeichert. Saves mitten im Gefecht oder an fremden Orten
  werden durch diesen Plan nicht still freigeschaltet.
- Kampagnenverlust/Besatzungsfolgen verwenden die bestehenden zuständigen Pfade.
  Keine neue Rettungskapsel-, Versicherungs-, Wrackbergungs- oder Respawnökonomie.
- Erstes sichtbares Gefecht: zwei eigene Rotten, ein zu schützendes großes
  Schiff und zwei gegnerische Rotten. Prüffixture zunächst je zwei Jäger;
  separate Grenzfälle prüfen 1 und 6 Mitglieder.
- Balancewerte, Dauer, Reichweite und Skill-Schwellen sind ausdrücklich
  Startparameter, keine endgültige Balanceabnahme.
- Keine Raketen/Torpedos, vollständige Sechs-Freiheitsgrad-Simulation,
  spielwirksame Nacht-Sensorik oder neuen Fahrzeugmodellserien.

## 11. Abnahme und Quellen

Jede Festlegung ist im Plan einem Paket zugeordnet. Kleine Domain-/Ownerchecks,
native Bedien-/Sichtprüfung, Performance und Mehrspielerprüfung werden getrennt
belegt. Reine Dokumentation erfüllt keine dieser Laufzeitabnahmen.

Projektgrundlagen:
[Architektur](../ARCHITECTURE.md),
[Fireteam-Modi](fireteam_behavior_modes_contract.md),
[Commander-Delegation](commander_fireteam_delegation_contract.md),
[Orbitreise](orbit_quantum_travel_contract.md),
[Komponentengrenze](polisa_ship_equipment_contract.md),
[Grafikreferenzen](graphics_reference_revision_contract.md).

Externe Referenzen, im Gespräch am 11.11.2026 geprüft:
[RSI: gekoppelt/ausgekoppelt](https://support.robertsspaceindustries.com/hc/en-us/articles/360020925254-How-to-Land-Your-Ship),
[RSI-Schiffsmatrix: Repeatergrößen](https://robertsspaceindustries.com/en/ship-matrix).
Sie erläutern Referenzbegriffe, ersetzen keine eigenen Runtimewerte.
