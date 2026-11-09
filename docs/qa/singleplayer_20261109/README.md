# Einzelspieler: Basis, Orte und UI — Umsetzung und Pruefung

Stand: 09.11.2026. Arbeitsbranch `task/singleplayer-loop-20261109`, Basis
`ed77c105854bf11b3abfd2c90e32a99bcf62f753`. Lokale Commits und anschliessende
direkte lokale Mainintegration ausdruecklich autorisiert; kein Push und kein
EXE-/Releaseauftrag. Main-Smoke und exakter Integrationsstand werden separat
belegt. Der gemeinsame Integrationsbranch
blieb unveraendert; er lag beim Start 91 Commits hinter Main. Die Umsetzung
verwendet einen frischen Taskbranch auf dem geprueften aktuellen Main-Stand.

## Ergebnis und Nachweisgrenze

AP0–AP7 sind als lokaler Implementierungsstand vorhanden. AP8 hat einen echten
Headless-Gesamtlauf bei `Engine.time_scale = 1.0` bestanden: **60/60**, Exit 0,
ohne Script-/Parse-/Enginefehler oder Leaks im Abschlusslog. Es wurden keine
Auftragsgates, Missionsergebnisse oder laufenden Transfers auf Erfolg gesetzt.
Nur die vorhandene initiale Boarding-Testhilfe beschleunigt das Testfixture.

Der Ablauf nutzt reale Operationscommands, MissionSetup, SimulationRoot,
TacticalController, LZ-/Dropship-, Bewegungs-, GO- und zeitgesteuerte Use-Pfade:
Auftrag annehmen → Satellitenort waehlen → Abflug und Landung → Daten sichern →
zum tatsaechlich geparkten Schiff zurueckkehren → einmaliger Abschluss und Belohnung → Rueckflug →
zweiter Ausflug zum Handelsort ohne Kampfauftrag → Haendler benutzen → Kauf und
Betankung → Rueckflug mit demselben Schiff. Pilot, drei Crewmitglieder,
einmalige Mitgliedschaft, alle Portraetidentitaeten und urspruengliches Pad bleiben
erhalten. Abschliessender Beleg nach Reviewfixes:
[singleplayer-loop-postreview.log](raw/singleplayer-loop-postreview.log).
Sechs erfasste Runtime-/Verifierquellen blieben im Lauf bytegleich und stimmen
mit dem Produktcommit ueberein: [Quellenpruefung](postreview-source-verification.json).

Der Lauf bestaetigt Credits `500 + 150 - 50 - 20 = 580`, Fuel
`60 - 24 - 16 + 10 = 30`, genau ein gekauftes Sanitaetsgeraet (`medictool`) und
genau einen Auftragsabschlussbeleg. Diese Werte sind Testbalancing aus Daten,
keine gestalterische oder spielerische Nutzerabnahme.

**Offen bleibt die native Bedienungs- und Gestaltungsabnahme.** Der normale
Hauptmenueeinstieg wurde in einem privaten nativen Profil gestartet; Godot
lieferte eigene Rendercaptures. Windows-Computersteuerung lieferte jedoch
Capture-Timeouts und `coordinate input geometry is unavailable`; Tastendruecke
erreichten den Spielprozess nicht. Ein Headless-Button-/Dragtest ersetzt keinen
echten OS-Maus-/Tastaturtest. Anschliessend verlangte der Nutzer, den PC weiter
nutzen zu koennen. Das eigene Testfenster wurde beendet; seitdem ausschliesslich
Hintergrund-/Headlessarbeit, ohne Fokus-, Maus- oder Tastaturuebernahme.
Keine native Abnahme bei 1280×720, 1920×1080 oder 3440×1440 behauptet.

## Implementierung

- Operationsnavigation mit sichtbarem Rueckweg; regulaere Legacy-/FOB-Eintritte
  gesperrt, interne Transport-/Multiplayerpfade erhalten.
- Kompakte Personenzeilen, vorhandene Sortiermetriken und Rollenbadges,
  Doppelklickdetails, echte Personen-/Trupp-/Schiff-Drags sowie Ausruestungschips
  aus validierten Loadoutoptionen. Keine erfundenen Lagerbestaende.
- Gespeicherte 36×28-Hexbasis mit zwei betretbaren Innenraeumen, authored
  Waenden/Tueren/Boeden, zwei Pads, Service und Erweiterungsflaechen.
  Dachlose Geometrie ist ein funktionaler Kandidat; Original-GLBs bleiben erhalten.
- Langlebige Kampagnen-/Versorgungsowner am SimulationRoot-Commandpfad;
  Annahme, Zielwahl und Reise getrennt. UI-Snapshots mutieren keine Bestaende.
- Eigenstaendige Regionalkarte und Smart Mobile; echte Craft-/Padprojektion
  statt statischem Cutlassprop. Flugdeck nutzt denselben getaktet angeforderten
  Viewport, ohne zweite Welt oder weiterlaufende Commandersteuerung.
- Satelliten- und friedlicher Handelsort mit echten Szenariogates. Kampagnenschiffe
  warten nach dem Ausladen tatsaechlich am Pad; expliziter Rueckflug nutzt den
  bestehenden sichtbaren Outboundpfad. Legacy-/verbundene Fluege bleiben erhalten.
- Endliches Angebot, Credits, pro Schiff Fuel und atomare idempotente Transaktionen.
  Belohnung konsumiert einen bestaetigten Runtime-Abschluss genau einmal.

## Gefundene und korrigierte Ursachen

1. Nach abgeschlossenem Bewegungsauftrag ging die Ankunftsbestaetigung waehrend
   zeitgesteuertem Use verloren. Eine echte Dreierformation konnte dadurch nach
   0,8 Sekunden stehenbleiben. Die Runtime behaelt nur den bestaetigten Beleg
   desselben Waypoints und prueft weiterhin Radius, Position und Unterbrechungen.
2. Der alte Homebase-Direct-Pfad flog nach dem Ausladen automatisch zurueck.
   Die neuen explizit friedlichen Einzelspielerszenarien halten das echte Schiff
   am Landeplatz; andere Szenarien und verbundene Multiplayerpfade behalten ihr
   Verhalten.
3. Der erste Ausruestungsdrag hatte keine sichtbare Quelle fuer ein anderes Item.
   Das unabhaengige Review fuehrte zu einer echten validierten Ausruestungspalette
   und einem Test, der das Payload vom sichtbaren Chip erhaelt.
4. Friedliche Szenarien brauchten einen ausdruecklichen Opt-in gegen alte
   Enemy-Fallbackslots, passende Readiness und zurueckgesetzte Szenariozustaende
   fuer den zweiten Ausflug.

## Lokale Pruefungen

Godot: `4.6.2.stable.official.71f334935`. Verifier werden mit
`godot_console.exe --headless --path <Worktree> --script res://scripts/tests/<Name>.gd`
ausgefuehrt. `APPDATA` zeigt fuer alle zustandsbehafteten Runs auf ein privates
Verzeichnis dieses Plans. Normale Profile und die bereits laufende Nutzer-EXE
wurden nicht veraendert oder beendet.

| Bereich | Belegter Zwischenstand |
|---|---|
| Vollstaendiger echter Zweiausflugsablauf | 60/0, Exit 0 |
| Basisinhalt und reale Navigation | 138/0; bestehende Erkundung 26/0 |
| Personal, echte Dragquellen, Tankservice-Navigation | 45/0 |
| Navigation / bestehende Operationsregression | 30/0 / 63/0 |
| Kampagne / Versorgung / reine Abflugpruefung | 33/0 / 41/0 / 15/0 |
| Reale Pads und Abflug / geteilte Vorschau | 33/0 / 10/0 |
| Zeitgesteuerte Ankunft / geparktes Kampagnenschiff | 10/0 / 19/0 |
| Echte Serviceoberflaeche | 26/0 |
| Headless-Layout bei allen drei Aufloesungen | 69/0 |
| Loadout / isolierte Rueckkehr / Handoff / Debrief | 36/0 / 14/0 / 30/0 / 37/0 |
| Verbundene parallele Dropships, TASK1115 | 25/0 |
| Roundtrip-Fuel / echte Craft-Rueckkehrbindung | 9/0 / 16/0 |
| Vollstaendiger einzelner Satelliten-Realablauf | 53/0 |

Abschlussmatrizen auf Produktcommit `6d0e463fe`:
[20 fokussierte Gates](final-quick-matrix.json), alle Godot-Exits 0 und keine
fehlgeschlagenen Assertions; [sechs betroffene Nachbarregressionen](final-connected-matrix.json),
179 Assertions, null Fehler/Warnungen. Der erste Aggregationswrapper zaehlte
versehentlich die Zahl vor `failed=0` als Fehler; die JSON-Matrix wurde durch
korrektes Parsen derselben unveraenderten Godot-Logs berichtigt. Keine erfundene
erneute Testausfuehrung.

Begrenzte Headless-Projektionsprobe, 100 warme synchrone Operationsrefreshs:
35,57 ms Mittel, 39,54 ms P95, 43,68 ms Maximum unter aktueller Maschinenlast;
keine neu erzeugte Personenzeile, derselbe Vorschauviewport, versteckte Welt
mit deaktiviertem Rendering. [Messwerte](projection-profile.json).
Das ist ein Komponentenbefund bei vier Refreshs pro Sekunde, kein nativer
Framezeit-/FPS- oder Ruckelfreiheitsnachweis.

Rohlogs unter [raw](raw/), Assetquellen mit SHA-256 unter
[ap6-source-assets.json](ap6-source-assets.json). Fehlversuche bleiben als
RED-/Diagnosebelege erhalten und sind keine Abschlussresultate. Finale Matrix,
Der unabhaengige [Reviewbericht](REVIEW.md) bezieht sich auf den eingefrorenen
Stand vor dem abschliessenden Fixpass. Beide bestaetigten Befunde wurden behoben:
P1 Hin-/Rueckflugbudget vor Start, RED4/5 → GREEN9/0; P2 echtes Schiff und
festes Pad, RED6/10 → GREEN16/0. Abbruchrueckkehr schliesst die verlassene
Instanz und setzt den aktiven Job fehlgeschlagen ohne Belohnung. Danach wurden
der komplette Zweiausflug und die Abschlussmatrizen erneut auf aktuellen
Produktquellen geprueft. Kein zweites Review oder native Freigabe wird behauptet.

## Bekannte Grenzen und offene Abnahme

- Zwei alte Layoutgates TASK346 (21/2) und TASK388 (17/2) schlagen auf dem
  unveraenderten Main identisch fehl; Baselinelogs liegen im Paket.
- TASK348-FOB-Fallback scheitert mit 14/3 auf diesem Stand und auf unveraendertem
  Main ed77c1058 identisch; [Baseline](raw/baseline-task_348_homebase_fob_payload_state_isolation.log).
  Somit drei bekannte alte rote Gates, keine pauschale Behauptung einer komplett
  gruenen historischen Testsammlung.
- Headless-Layout, Cache-/Viewport- und Ownerpruefungen belegen keine allgemeine
  native Leistung, Ruckelfreiheit, menschliche Verstaendlichkeit oder Stilfreigabe.
- Keine Savegame-Migration, volle Lager-/Bauwirtschaft, weiteren Aussenposten,
  sichtbaren Boardingfiguren oder EXE-Erstellung.
- Der diktierte Begriff Cutlist bleibt ungeklaert; kein benanntes Element wurde
  allein aufgrund dieser Vermutung geloescht. Rang bedeutet vorhandene
  Rollen-/Faehigkeitsbadges, kein neues militaerisches Rangsystem.

## Dokumentierte Entscheidungen

1. Aktuellen geprueften Mainstand als frische Taskbasis verwenden, statt den
   andernorts ausgecheckten gemeinsamen Integrationsbranch zu bewegen.
2. Drei Startorte insgesamt; vorhandenes `medictool` als einziges endliches
   Kaufangebot. Zahlen sind Testbalancing, keine Nutzerfreigabe des Balancings.
3. Vorhandene Rollen-/Faehigkeitsbadges nutzen; keine Dienstgrade erfinden.
   Ungeklaerte Cutlist nicht blind loeschen; Personalansicht bleibt personenbezogen.
4. Datenbasierte dachlose Innenraumdarstellung als funktionalen Kandidaten
   integrieren; Originalmodelle und Navigationsfakten getrennt erhalten.
5. Einen schmalen Runtimeadapter hinzufuegen, um die langlebigen Owner anzubinden;
   bestehender Transportowner behaelt alle Phasen und Payloads.
6. Hin- plus Rueckflugbudget vor Start verlangen und nur die tatsaechliche
   Strecke abbuchen. Spaetere gewollte One-way-Reisen braeuchten eigene Regeln.
7. Neue friedliche Einzelspielerorte verwenden das feste gespeicherte Pad mit
   echter Belegungspruefung. Freie Kampagnenlandungen waeren eine Folgeaenderung
   mit dynamisch gebundenem Rueckkehrziel; alte/verbundene freie LZ bleiben erhalten.
8. Tatsaechliche vorzeitige Heimkehr ohne Abschluss beendet die verlassene Szene
   und den Auftrag ohne Belohnung. Spaetere Wiederaufnahme abgebrochener Jobs
   braeuchte einen gesonderten Lebenszyklusvertrag.
9. Frueheres Code-/Testverbot durch aktuelle Umsetzungserlaubnis ersetzt;
   spaetere lokale Mainintegration erlaubt. Push und Release bleiben ausgenommen.
10. Nach der PC-Nutzungsanweisung keine weiteren sichtbaren Testfenster,
    Fokuswechsel oder Maus-/Tastatureingaben. Native Abnahme bleibt offen.

## Lokale Mainintegration

Auf ausdruecklichen Nutzerauftrag per Fast-forward von ed77c1058 auf739cc7b65
uebernommen, ohne Push. Frischer kompletter Main-Headless-Smoke60/60, Exit0,
null Fehler/Leaks; HEAD und alle sechs erfassten Main-Quellhashes vor/nach identisch.
Drei weitere Main-Smokes fuer Views, Roundtrip-Fuel und reale Craftbindung
bestanden.52 geaenderte Produktdateien stimmen inhaltlich mit dem Taskstand
ueberein; sechs Checkout-Zeilenendendifferenzen sind separat dokumentiert.
792 vorhandene untracked Text-/Code-/Konfigurationsdateien blieben bytegleich;
keine Stash-/Reset-/Cleanaktion und keine fremde Datei ersetzt.
Der anschliessende Belegcommit aendert nur QA/Dokumentation und wird ebenfalls
lokal nach Main uebernommen. Details: [Integrationsbeleg](main_receipt.json),
[Main-Lauf](raw/main-singleplayer-loop.log), [Quellbeleg](raw/main-loop-tested-sources.json).
Native OS-/Stil-/Performanceabnahme bleibt offen. Die bereits vorhandene
Nutzer-EXE wurde weder ersetzt noch beendet; keine EXE-Erstellung.
