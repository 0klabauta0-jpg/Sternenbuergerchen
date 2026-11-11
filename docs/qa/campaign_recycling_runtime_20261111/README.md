# Recycling-Slice: echter Input und vorhandener Rucksackconsumer

Isolierter task/native-glut-maps-20261110; Root hat Slice und Dateibesitz
bestaetigt. Kein Commit/Push durch Teilagent. Keine Fahrzeugmodelle, neuen Items,
Adapter-/SimRoot-/Tabletop-/Bewegungs-/Combataenderungen.

Werkstattentwicklung und selbst gefertigtes Bergungswerkzeug -> einmal100Cr
research_recycling -> neues Rezept backpack_recycling. Einzelherstellung nimmt
2salvage ausschliesslich aus dem Basislager und20Cr, erzeugt1backpack dort.
Dieser benutzt unveraendert _change_backpack mit12Inventarplaetzen. Ein freier
Anzugslot nimmt die erste Datenkarte weiterhin ohne Rucksack auf. Kaufangebote
bleiben gleich. Polisa-Ankauf9Cr/salvage bedeutet38Cr Opportunitaetskosten fuer
den Rucksack gegenueber40Cr Kaufpreis; erste Balance, keine finale Freigabe.

Supply-Vorschau und Mutation teilen denselben pruefenden Ownerpfad.
supply.research.fabrication ist eine revisionierte Nur-Lese-Projektion fuer die
Werkstatt; Material-/Credits-/Lagersperren werden dort angezeigt. UI schreibt
keinen Bestand. Neue Belege trennen Rezept und Output und beweisen die Inputs;
alte echte Fertigungsbelege ohne Materialfelder bleiben lesbar.

## Frisch ausgefuehrte begrenzte Pruefungen
- campaign_recycling_slice_check.gd:27geprueft/0fehlgeschlagen, Exit0, keine
  Script-/Enginefehler oder Leakwarnungen. Normale echte Jobdefinitionen als
  vertrauenswuerdige Fixture, keine gespielten Missionen.
- Voraussetzungen,100Cr einmal, kein Gratisrucksack, fehlendes Material, fremdes
  Schiffslager ist kein Werkstattinput, expliziter Transfer,20Cr+2Inputs atomar,
  Replay/Konflikt, Heimatsperre, vorhandener12Slotconsumer und Anzugchipplatz.
- Ein JSON-Domainroundtrip sowie manipulierte Input-/Preis-/Item-/Recipebelege
  und fehlende Materialfelder abgewiesen; alte Mining-/Salvagebelege erhalten.
- VollerOutput blockiert weiterhin materialfreie alte Rezepte ohne Kosten.
  Recycling2zu1 darf dagegen ein volles Lager nutzen; Endkapazitaet sinkt.
- Unveraenderter bestehender Schutztechnik-Domaincheck:24/0, Exit0.
- Supply, Researchkatalog, ServicesPresenter check-only jeweilsExit0, keine
  Scriptfehler/Warnungen. Kein neuer UI-/Klick-/Screenshot-/Reise-/Kampf-/Save-
  Matrixlauf, keine GPU-/Framerateabnahme.

## Erstlaufdiagnose
Erster kleiner Lauf27/2: Test verglich JSON-Menge2.0 als gesamtes Dictionary mit
manueller Integer2 (Godots Dictionarytypvergleich), obwohl der reale Owner2
entnommen und20Cr belastet hatte. Zweite Fixture lieferte dem bestehenden
Equipgate kein context.unit_id und wurde korrekt abgewiesen. Mengenassertion
prueft nun die kanonisch ganzzahlige Menge; Equipfixture benutzt denselben
Personenkontext wie der Runtimeadapter. Produktguards wurden dafuer nicht
gelockert. Initial-/Diagnoselogs sind erhalten, finale Logs daneben.

## Grenzen
Dies ist ein kleiner konkreter Verarbeitungszweig, kein fertiger Forschungsbaum.
Echter Wrack-Use, Rueckflug, Ausladen, Werkstattklick und gemeinsamer Save/Continue
bleiben spaeter. Die Probe nutzt vertraute Commands/Domainowner ohne Missions-
 oder Actorlauf. Workbench-Ausgangsplanung aktualisiert Root separat; lokale
Nutzerentwuerfe duerfen dadurch nicht ueberschrieben werden. Kein Main/EXE.
