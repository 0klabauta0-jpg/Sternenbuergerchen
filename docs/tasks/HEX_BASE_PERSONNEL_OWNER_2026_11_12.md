# AP6: Basispersonen an den gemeinsamen Hexowner anschließen

## Ziel / Ursache

Basisactors sind Projektionen echter Kampagnenpersonen ohne taktische
UnitCommandfähigkeiten. Freie Position und gemeinsames Boardingziel würden
im Hexmodus Belegung und Ankunft umgehen. Der existierende Basisowner behält
Aktionen, Betten und Transportabsicht; Root/Ground besitzen Feld und Bewegung.

## Umfang / Nicht-Ziele

Gesonderter interner Rootzugang nur für den gebundenen Basisowner, seine echten
Actors und dieselbe Registry. Begrenzte gemeinsame Startplatzplanung bewahrt
gewünschte Anker, verteilt Kollisionen innerhalb legal verbundener Felder und
committet vollständig. Basiswalk nutzt tokenisierte Rootabsichten und tatsächliche
Ankunft. Admission erst nach Restorestatus/-position; an Bord oder auswärts
erzeugt keine Groundpräsenz. Boarding/Aussteigen folgen als eigene Teilgrenzen.
Kein künstliches UnitCommandinterface am BaseActor, keine neue Basiskarte,
Produktionskennung, Content-/Balanceänderung, Main, EXE oder große Abnahme.

## Dokumente / Verträge

- `docs/dev/hex_tactical_runtime_contract.md`
- `docs/dev/explicit_hex_ramps_contract.md`
- `docs/dev/base_automatic_rest_contract.md`
- `docs/tasks/HEX_GROUND_LIFECYCLE_2026_11_11.md`
- `docs/superpowers/plans/2026-11-11-hex-sight-occupancy.md`, AP6

## Akzeptanz

- Nur der tatsächlich konfigurierte Basisowner mit dessen Actor, Knownbindung,
  gemeinsamer Registry und wahrer örtlicher Präsenz kann Basisground mutieren.
- Aboard bleibt auch am heimischen Pad ohne Groundfeld. Fremde oder entfernte
  Personen und NPCprojektionen erhalten über diesen Zugang keine Zulassung.
- Gruppenstart ist atomar, maximal64 Expansionen, explizite Rampen bleiben
  gemeinsame Übergangsquelle. Verschiedene gültige Anker bleiben erhalten.
- Echter Basiswalk und Bett-/Terminalankunft lesen denselben Groundowner; freie
  Renderposition kann Ankunft weder vorziehen noch abbrechen. Geschwindigkeit80
  mit bestehendem Basisfaktor1 bleibt erhalten, kein neues Skillbalancing.
- Abbruch räumt Bewegungsabsicht und vorhandene Bettvormerkung; Legacy bleibt
  beim bestehenden Pfad. Kleine private Fixture statt ganzer Kampagne.

## Dateien / lokale Prüfung

`hex_ground_admission.gd`, `simulation_root.gd`, `base_personnel_runtime.gd`,
neuer kleiner Verifier und vorhandener isolierter Runner. Kleine Root-/Registry-
Basisactorprobe mit höchstens12 Zellen, gezieltes RED/GREEN, enger Review.

## Risiken / offene Punkte

Die tatsächliche Basisnavigation verwendet `base_interior_navigation.json`
(feines384×392-Hexraster), nicht die grobe Renderkarte. Produktionsdaten bleiben
unverändert ohne `tactical_grid_rules`. Parent besitzt neue RemoteHandoff-/
Reisegates; diese werden nicht ersetzt. Distinkte Boardingannäherungen,
Aussteigevormerkung, Setup/Respawn und AP7-Aktionsrestore sind weitere Teilpakete.

## Geprüfter Kernteil

Base63/0 und Lifecycle64/0, Quellen-/Profilguards grün; QA
`hex_base_owner_20261112`. Frischer unabhängiger Review schloss den P2 einer
statisch unerreichbaren begehbaren Bettzelle mit sauberem RED62/1→GREEN63/0.
`blocked/unreachable_target` beendet die Basisaktion und Bettvormerkung;
vorläufige Belegungswartefälle werden weiter erwartet. Legacygraph bleibt
unverändert, Hexwalk berechnet dort keinen zweiten Weg.

Configure legt Ground erst nach Restorestatus/-position an; kleine Fixture prüft
die tatsächliche nachfolgende Presence-/Walkgrenze, nicht die große Basiskarte.
Boarding/Aussteigen, Setup/Respawn und AP7 bleiben offen, AP6 noch nicht vollständig.

## Nächster Teil: reale Boarding-/Aussteigegrenze

Die bestehende Boardinggruppe erhält vollständige unterschiedliche Annäherungshexes
innerhalb zweier Felder des Padankers. Der bestehende Transportowner entscheidet
weiter über Payload und Boardingzeit. Bis zu dessen tatsächlicher Bestätigung
bleiben Personen physisch am Boden; erst danach wird ihr Groundclaim freigegeben.
Bereits an Bord befindliche Personen werden nicht erneut als Ground benutzt.

Aussteigen prüft die ganze Gruppe und merkt freie verbundene Plätze im Ground
vor, bevor der vorhandene Payloadowner angefragt wird. Bei Platzmangel oder
abgelehnter Payloadänderung bleiben Bordstatus und Claims konsistent, ohne
Teleport auf denselben Padpunkt. Bereits am Boden wartende Boardingpersonen
behalten beim Abbruch ihr tatsächliches Hex. RemoteHandoff-Methoden des Parent
bleiben unverändert. Kleine bekannte Transportfixture prüft den tatsächlichen
Basis-/Rootpfad; keine volle Kampagne oder neue Reise-/Payloadwahrheit.

Dieser zweite Teil ist mit Boarding53/0 und Basisowner63/0 geprüft,
QA `hex_base_boarding_20261112`. Unabhängiger Review schloss Piloten als eigene
Fireteammitglieder mit RED51/2→GREEN53/0: bereits ausgestiegene Personen sperren
den Rest nicht; vollständige Fireteams reservieren ihre Plätze in einem Vorgang.
Remote-Rekrutierungsbindung räumt vorhandenen lokalen Ground. Parent behält
alle zusätzlichen RemoteHandoff-/Reise-/Landingpadmethoden.
MissionSetup/Respawn, taktisches Member-Retirement und AP7/8 bleiben nächste Teile.
