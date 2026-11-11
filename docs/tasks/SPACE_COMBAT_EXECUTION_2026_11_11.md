# Weltraumkampf: paketweise Umsetzung

## Ziel / Ursache

Das bestätigte Weltraumkampfkonzept schrittweise umsetzen. Reise, Kampf,
Rotten und Komponenten müssen dabei autoritative Zuständigkeiten behalten.

## Umfang und Nicht-Ziele

AP00 bis AP20 des bestehenden Umsetzungsplans in kleinen überprüfbaren
Paketen bearbeiten. Keine stillschweigende Mainintegration oder EXE.

## Grundlagen

- [Konzept](../dev/space_combat_contract.md)
- [Arbeitspakete](../superpowers/plans/2026-11-11-space-combat.md)
- [Reisevertrag](../dev/orbit_quantum_travel_contract.md)
- [Komponentenvertrag](../dev/polisa_ship_equipment_contract.md)
- [Parallele Ortsoperationen](../dev/parallel_location_operations_contract.md)
  ist auf dem weitergelaufenen nativen Branch vorhanden und vor AP01 zu integrieren.

## Akzeptanz und Prüfung

Jedes Paket erfüllt seine konkreten Akzeptanzkriterien; nur betroffene kleine
Verifier und notwendige Regressionen ausführen. Native Sicht, Mehrspieler und
Performance bleiben getrennte spätere Nachweise. Ergebnisse und Abweichungen
werden hier fortgeschrieben.

## Betroffene Dateien

Die Datei- und Schnittstellenkarte steht im Plan. AP00: Commandvertrag,
Verifier und diese Statusdokumentation.

## Lokale Prüfung / Fortschritt

- Warpankunft-Ownerpfad speichert jetzt einen Completionreceipt vor dem
  optionalen Observerabschluss. Gleiche Wiederholung und reentrante
  Benachrichtigung buchen/platzieren nicht erneut; Fleet prüft den konkreten
  Travelowner. Gezielter Test grün. Der produktive Tickanschluss bleibt bis
  zum gesicherten lokalen Warpabflug ausdrücklich offen.

- Wiederanflug nach Abbruch nutzt den schiffseigenen bezahlten Abflugbeleg,
  sofern Root den passenden bestätigten Abbruch und Reiseowner verifiziert.
  Regression: A bricht ab, ein anderer Schiffstransfer erhöht die globale
  Sequenz, A fliegt erneut an; Fuel und Campaign bleiben unverändert. Der
  gezielte Test war vor dem Fix rot und danach grün.

- Warpankunft-Ownerpfad: Root prüft echte Fleet-/Flight- und Equipmentdaten,
  aktuelle Pilotenzuordnung und vorhandene Rotte beziehungsweise bereitet
  eine Einzelrotte vor. Die Suche verarbeitet höchstens 256 Felder pro Aufruf
  im unteren Eintrittsband; nach vollständiger Prüfung werden Flight, Index,
  Rotte und Travel synchron veröffentlicht. Ein gezielter Test mit echtem
  Adapter/Fleet/Equipment und Pilot-Testdouble zeigt Pilotverweigerung sowie
  taktische Aufnahme einer Cutlass mit vollständigem Footprint. Der Pfad ist
  bewusst noch nicht an den produktiven Warptick angeschlossen: lokale
  Warpabreise und Observer-/Adapterabschluss fehlen, damit kein Einbahnweg
  entsteht. Kein nativer Boarding- oder Mehrspielernachweis.

- Warp-Aufnahme-Vorstufe: Flight-Areawechsel und erstmalige lokale Registry-/
  Combataufnahme sind vor dem stillen Schritt separat validierbar; die
  Ersteintrittsfixture nutzt beide nach der Rottenprüfung. Vorläufige
  Katalog-Footprints: Cutlass zwei, Buccaneer ein Hex; keine UI-Werte.
  Ziel-Owner- und Warp-Sliceprüfungen grün. Die produktive Tickanbindung und
  sichere Warp-Abreise sind weiterhin offen.

- Warp-Eintrittsgrundlage: Die lokale Eintrittspose setzt den Flightmodus nun
  ausdrücklich auf taktisch. Die bisherige Fixture übernahm irrtümlich den
  strategischen Modus und war damit für Bewegungs-/Lesepfad nicht nutzbar.
  Regression zuvor rot, danach tatsächlicher Travel-Ersteintritt und
  benachbarte Rückkehr-/Gruppenfixtures grün. Produktiver Warpeintritt ist
  weiterhin nicht angeschlossen.

- Lokaler Anflugabbruch: Der Adapter prüft aktiven Flow-Anflug samt passendem
  Schiffs-/Ziel-/Abflugbeleg und tatsächlichem Pilot-Guard. Root prüft den
  ursprünglichen Travel-Ownerbeleg und reaktiviert Flight/Index mit dem
  vorbereiteten Orbitübergang; keine weitere Fuelbuchung oder Groundmutation.
  Gezielter Test mit echtem Adapter und Ownern sowie Pilot-Testdouble grün.
  Ein erneuter Anflug verwendet nach lesender Pilot-/Zielprüfung und gültigem
  Abbruchbeleg dieselbe Abflug- und Auftragsbindung; nur Travel und Flight
  werden erneut veröffentlicht, ohne zusätzliche Fuelbuchung. Ein zweiter
  Abbruch ist über die aktuelle Reiserevision getrennt belegbar. Gezielter
  Abbruch→erneuter Anflug→Abbruch-Test mit echten Ownern und Testdouble grün.

- Lokaler Oberflächen-Rückflug: Der echte Adapter prüft zunächst Visitbeleg,
  vorhandenen Missions-Pilot-Guard und Fuel ohne Abbuchung. Bei tatsächlichem
  `enter_space_orbit` bereitet Root Fuel, Flightreaktivierung, freien Gate-
  Footprint und Travel vor und veröffentlicht sie synchron; Wiederholung
  bucht nicht erneut. Signale folgen verzögert nach dem Flow-Aufruf. Geprüft
  mit echtem Adapter/Ownern, Pilot-Guard-Testdouble, fehlendem Treibstoff,
  belegtem erstem Gate und reentrantem Observer. Strategischer/Polisa-Pfad
  bleibt erhalten. Produktiver lokaler Warpeintritt, lokaler Anflugabbruch und
  nativer Besuch mit realem AP6-Boarding bleiben offen.
- `get_space_area_projection(craft_id)` löst die exakte Fleetreferenz auf,
  prüft aktiven lokalen Flight und delegiert unverändert das eigene Root-DTO;
  keine Fokusauswahl, Fremdkontakte oder Zustandsmutation. Gezielter Test grün.

- Rückkehrvorbereitung: Der bestehende Adapter trennt die lesende Prüfung von
  Visitbeleg, tatsächlichem Pilot-Guard und Route vom bisherigen Fuelcommit.
  Der Polisa-Backendtest bestätigt abgewiesenen unbesetzten Pilotensitz und
  unveränderte Ownerdaten bei gültiger Vorschau; Legacy-Buchung bleibt gleich.
  Flight-Reaktivierung und Indexaufnahme haben nun getrennte Vorprüfung und
  stillen Veröffentlichungsschritt; der bestehende Travel-Rückkehrtest nutzt
  beides und verweigert Replay nach Reset desselben Einzel-Travelowners.
  Noch kein produktiver atomarer Rückflug: Die aktuelle Flow-Reihenfolge kann
  Treibstoff vor dem Orbitübergang belasten. Ground-/Embark-Effekte gehören
  weiterhin dem parallel bearbeiteten AP6-Owner.

- Reise-Replay prüft zusätzlich den ursprünglichen Fleet-Kandidaten und dessen
  Einzel-Travelowner-Epoche. Ein Reset desselben Owners mit unveränderter
  Flight-Referenz wird sowohl produktiv als auch in der Gruppenfixture
  abgewiesen; beide gezielten Regressionen bestanden.

- Korrektur zur produktiven Anflugtransaktion: Der Parallelstand `eb251eb23`
  liefert die nebenwirkungsfreie `preview_departure`; Root verwendet sie vor
  jeder Ownerveröffentlichung. Adaptertoken und äußerer Anflugbeleg stehen vor
  Commit-Signalen; ein verschachteltes Replay markiert auch `travel_result`
  und löst keinen zweiten Szenenübergang aus. Gezielter Reentranztest und
  Preview-Ownerprüfung grün; das ist noch keine native Boarding-Abnahme.

- Produktiver Adapter/Anflug: Der gebundene Singleplayer-Adapter lässt Root
  Boarding-/Ziel-/Padprüfung erneut ausführen. Root bereitet Fuel, Campaign
  und optional den echten Travel-Anflug gemeinsam vor und veröffentlicht
  sie vor Signalen synchron; lokaler Flight/Index wird dabei am gültigen Gate
  ebenfalls deaktiviert. Der vorhandene strategische Anflug bleibt für alte
  Oberflächen- und Stationspfade erhalten und ist jetzt Teil der Transaktion.
  Der Adapter reicht `space_move` mit strengem Payload an Root weiter.
  Gezielte Owner-/Adaptertests bestehen für falschen Orbit ohne Belastung,
  strategischen und lokalen Anflug, Replay und Flugbewegung; Boarding im
  Transaktionstest stammt aus einem Adapter-Testdouble. Die produktive lokale
  Aufnahme/Warpeintritt, Rückkehranschluss und echter Boarding-Ende-zu-Ende-
  Nachweis bleiben offen. Der alte Orbit-UI-Verifier flog zum Planet und
  erwartete anschließend den inzwischen Glut 1a zugeordneten Satellitenort;
  ein weiterer UI-Lauf scheiterte an fehlenden importierten .godot-Assets.

- Oberflächen-Gruppencommit als ausdrücklich begrenzte Fixture: Root prüft
  Anfluggate, gemeinsame Flight-Identität, Rotte und Revisionen und bereitet
  echte Travel-, Supply- und Campaign-Owner gemeinsam vor. Nach erneuter
  Prüfung veröffentlicht ein synchroner stiller Schritt Deaktivierung,
  Ressourcen, Kampagnenbindung und Anflug; vollständige Root-Quittung schützt
  vor erneutem Abbuchen. Client-Eingang wird abgewiesen. Geprüft mit echtem
  Satellitenauftrag, unzureichendem Treibstoff und Konflikt/Wiederholung.
  Die Bündelung am Anflug ist ein Fixture-Szenario, keine Aussage, dass
  produktiver Flugtreibstoff dort erstmals belastet werden darf. Produktive
  Übergänge, Rückfall bei späteren Änderungen und UI-Anschluss bleiben offen.
- Dieselbe Fixture prüft anschließend Landung, Rückkehr in den Orbit und
  einen Bewegungstick mit demselben Flight-Objekt. Equipment ist echt, der
  Pilotennachweis dabei ein Testdouble; echte Boarding-/Adapteranbindung und
  eine native Sichtprüfung sind dadurch noch nicht belegt.

- AP7-Autoritätsgrenze: Die mutierenden Raumeingänge einschließlich der
  vorbereiteten Area-Transaktion prüfen die bestehende Server-/Clientsperre
  vor jeder Änderung. Lesevorschauen bleiben unverändert. Simulierter
  Client-/Host-Verifier und betroffene Bewegungs-/Rückkehrprüfungen grün;
  eine echte Mehrspieler-Sitzung ist damit noch nicht nachgewiesen. Ein künftig
  ergänzter Root-Gruppencommit muss dieselbe Eingangssperre übernehmen.

- Orbit-Lesepfad: `get_space_area_snapshot` liefert auf Basis eines nach Area
  geführten Registry-Index die aktiven eigenen Fleet-Schiffe mit Flight-,
  Rotten- und Footprintdaten. Vorerst ausschließlich Singleplayer und eigene
  Schiffe; Kontakt-/Feindsicht braucht einen eigenen Sichtbarkeitsvertrag.
  Inaktive Schiffe werden beim Tick und Snapshot sicher ausgelassen. Gezielt
  geprüft: Snapshot, Deaktivierung und echte Rückkehr, jeweils Exit 0.
  Die produktive Flugzulassung und ein vollständiger Reiseübergang bleiben
  weiterhin offen; zur folgenden Bewegungsvorstufe siehe nächsten Eintrag.
- Bewegungs-Vorstufe: Cutlass und Buccaneer besitzen vorläufige interne
  Spielbalanceprofile im Equipment-Katalog; Leistungsbudget 1.0 ist eine
  Übergangsannahme und noch kein austauschbarer Kraftwerksslot. Root prüft
  Flight-/Fleet-Identität, Live-Pilot, Rotte, Area, Ziel und Equipment und
  steuert den bestehenden Tick mit einem Zielclaim. Pilot- oder Equipment-
  Änderungen stoppen den Auftrag; Treffer auf eine Sperre geben ihn frei.
  Der Claim reserviert das Ziel, nicht einen vorausberechneten Gesamtkorridor;
  die vorhandene Sweep-Prüfung sichert die tatsächlichen Bewegungsschritte.
  Fixtureprüfung für Bewegung, Replay, Besitz, Pilot und belegtes Ziel sowie
  Bereichstick, Rückkehr und Warp-Slice bestanden. Keine native UI-Abnahme.
  Produktive lokale Aufnahme, Reise-Transaktion, Adapter und vollständiger
  Korridor-/Auftragslebenszyklus bleiben offen; keine Freischaltung behauptet.

- Oberflächenanflug, Vorbereitung: Der bestehende Flight-Owner kann eine
  zuvor geprüfte Deaktivierung ohne zweite Validierung veröffentlichen; der
  Combat-Owner bereitet dazu die Entfernung aus Raumindex und vorhandenen
  Korridorclaims vor. Der parallele Travel-Schritt `9813c7dcd` ist integriert:
  Er bereitet den lokalen Anflug vor, ohne die Flugpose selbst zu verändern.
  Gezielte Prüfungen: Travel-Owner 10/10, Deaktivierung, Rückkehr und erster
  lokaler Eintritt jeweils ohne Fehler. Das ist noch kein gemeinsamer
  produktiver Commit: Root muss Travel, Flight, Combat, Supply und Campaign
  vor der ersten Änderung zusammen prüfen und atomar veröffentlichen.
- Der Rückkehr-Verifier beginnt jetzt mit dem echten vorbereiteten lokalen
  Anflug und veröffentlicht zuvor geprüfte Flight-, Combat- und Travel-Schritte
  in einer Fixture. Landung und Rückkehr nutzen dasselbe Flight-Objekt; Exit 0.
  Supply und Campaign fehlen hierbei; dies ist keine produktive Root-Transaktion.
- Pflichtrotte und Pilotenzuordnung bleiben produktive Integrationsblocker:
  Flugstart und bestehende Adapter müssen frische Fleet-/Pilot-/Boardingdaten
  liefern; Rottenmetadaten allein beweisen keine Besetzung. Die tatsächliche
  Erzeugung und Erneuerung von Navigationsclaims ist ebenfalls noch offen.
  Legacy-Oberflächenrückkehr, Ereignisse und native Sichtprüfung sind nicht
  durch die genannten Ownerprüfungen abgedeckt.

- AP00: typisierte Commandgrenze mit extern bereitgestellter autoritativer
  Berechtigung, Revisionsprüfung, Adress-/Ziel-/Feldvalidierung und reinem
  Replay-Vorcheck. 20/20 Fälle im temporären Minimalprojekt; dessen
  `user://`-Schreibprobe lag im eigenen temporären APPDATA.
  Nachprüfung im Projekt 24/24, einschließlich typfester Replay-Signaturen,
  Dictionary-Reihenfolge und widersprüchlicher Zielangaben. Rottenverifier
  bleibt19/19. Noch kein Produktanschluss.
- AP01 erster Teil: per-Schiff-Flugdatensatz mit Pose, Geschwindigkeit,
  Modus, Masse, Revision und Tick; identischer/alter Tick und veraltete Revision
  werden abgelehnt. Minimalprojektcheck 6/6. Reiseowner und Flottenindex
  referenzieren nun dieselbe Flugzustandsinstanz; Position und Bugrichtung
  werden daraus projiziert. Bindingcheck4/4, bestehender Zwei-Schiffe-
  Fleettravel-Verifier8/8, jeweils isoliertes Minimalprojekt.
- AP01 weiterer Baustein: räumliche Registry für bestehende Flugreferenzen,
  eindeutige IDs, gezielte Feldindexänderung und sortierte Abfrage. Separater
  Minimalprojektcheck6/6.
- AP01 nächster Baustein: CampaignSimulationRoot nutzt einen Raum-Physiktakt
  über den bestehenden Adapter; der Meta-Renderprozess treibt die Reise
  nicht mehr an. Rootvalidierte Gegneraufnahme nutzt die separate Registry und
  erzeugt keinen Flotteneintrag; Spielerreferenz bleibt objektidentisch zum
  Flottenowner. Kleiner Root-/Adaptercheck10/10.
- AP01 Prüfgrenze: Der ältere SpaceTravel-Verifier hat im vorhandenen
  Sternsystem zwei veraltete Erwartungen (fünf Körper und alte Ortsbindungen).
  Der versuchte Minimalprojektlauf war zudem unvollständig, weil er einen
  echten SimulationRoot benötigt; er ist kein Integrationsbeleg.
- AP01 Prüfgrenze: Orbit-Gesamtverifier im neuen Worktree wegen fehlender
  importierter Godot-Ressourcen nicht lauffähig, Zeitlimit nach60s;
  kein bestandener oder gescheiterter Verhaltensnachweis.
- AP01 Korrektur: Der im Plan vorgeschlagene frühe Root-Rücksprung kappte
  Basis-Personnel-Bewegung, da beide denselben Root nutzen. Raumcallback
  läuft jetzt vor dem bestehenden Bodentick, ohne Rücksprung. Kleiner
  Rootcheck11/11, einschließlich synthetischer 30/60/144-Renderaufrufe bei
  jeweils60 Physikticks. Das ist noch kein echter Ansichtswechseltest.
  Nach gezielter Cacheergänzung erreichte der alte
  Orbit-Gesamtverifier Start, Boarding, Abheben, Warp-Abbruch und Neustart:
  26/30; vier alte Satelliten-Orbitannahmen scheiterten, zudem fehlte ein
  importiertes Schiffsmodell. Das ist keine vollständige Orbitfreigabe.
- AP01 Phasengrenze: Spieleraufnahme während Quantum abgelehnt; ein im
  taktischen Modus befindlicher Flugzustand weist neue Reisecommands zurück;
  Gegneraufnahme kann keine Spieler-Craft-ID übernehmen. Taktische Bewegung
  wird nur über den Root committet und aktualisiert den Feldindex;
  identischer Tick wird abgelehnt. Aufnahme und Eintritt prüfen die Reisephase
  getrennt; zwischenzeitlicher Warp verhindert Kampfeintritt. Bewegte
  registrierte Flugzustände aktualisieren ihre Feldindizes revisionsbasiert.
  Rootcheck27/27 einschließlich eines fixturegesteuerten Resolver-Commits.
- AP01 echter Ansichtswechsel: reale Kampagne, Auftrag, Boarding, Abflug,
  Warp, Heimatansicht während der Reise, Sternkarte und Abbruch. Gezielter
  headless Szenenlauf14/14, inklusive30/60/144-Renderbegrenzungen, Exit0,
  keine Fehler. Beleg:
  `docs/qa/orbit_quantum_20261109/raw/space-ap01-real-view-fps-62cc0def794c48298207edab1c650726/space_combat_ap01_view_verifier.log`.
- AP01 begrenzt abgeschlossen: Warp-Komponenten-/Checkpointstand integriert;
  vorhandene Reiseownerprüfung nach Anpassung zweier überholter Kartendaten-
  erwartungen69/69, Flottenreise8/8, echte Sichtwechselprobe14/14.
  Diese Prüfung ersetzt weder volle Kampagnen-, Stil- noch Performanceabnahme.
- AP02 erster reiner Resolver: gekoppeltes seitliches Gegensteuern,
  ausgekoppeltes Gleiten, getrennte Bugdrehung, Masse-/Schubwirkung und
  gemeinsames Achsbudget. Kleiner Verifier8/8 mit explizitem Fixture-Rumpf;
  zusätzlich ein einzelner Fixture-Commit über den tatsächlichen Root.
  Produkt-Rumpfkatalog, automatische Tickanbindung, Kollision und
  vollständige AP02-Abnahme fehlen.
- AP03 Vorstufe: deterministische Feldreservierung für Bewegungs-/Drehpfade;
  Segment-Supercover erfasst eine getestete exakte Randberührung, Drehbögen
  erhalten eine konservative Krümmungszugabe. Mehrfeldrümpfe werden beim
  Indexieren als gedrehte Hexflächen abgebildet; ein Einfeldjäger behält
  genau ein Ankerfeld. Vierzehn gezielte Geometriefälle bestanden,
  einschließlich benachbarter Rümpfe bei großen Kartenkoordinaten.
  Zeitliche Batchreservierung, Blockadeauflösung und begrenzte Laufzeitkosten
  bleiben offen; allgemeine Geometrie- und Performanceabnahme stehen aus.
- AP03 Einzelcommit: Root prüft Ziel-Footprint und durchflogenen Korridor
  gegen registrierte andere Schiffe, einschließlich gedrehter Mehrfeldrümpfe;
  außerhalb der Karte wird vor der Mutation abgelehnt. Rootcheck43/43,
  Geometriecheck11/11, Registry6/6. Geländeblocker, zeitliche
  Batchreservierungen und Blockadeauflösung bleiben offen.
- AP03 Batch-Vorstufe: Root validiert alle Revisionen vor einer Mutation,
  prüft konservative Sweepreservierungen und committet zugelassene Vorschläge
  in stabiler Reihenfolge. Kreuzende Wege und veralteter Batch geprüft,
  Batchcheck8/8. Die Reservierung umfasst derzeit den gesamten Tick;
  feinere Zeitfenster, Blockadeauflösung und echte Kartenhindernisse fehlen.
- AP03 gezielte Kostenprobe: P95 dreizelliger Einzel-Sweep833→442µs nach
  geometrischer Kandidatenbegrenzung; 25 Messungen je Stand, laufende
  Fremdlast, kein Frame-/FPS-Nachweis. Geometrie14/14 und Batch8/8.
  Belege: `docs/qa/space_combat_20261111/README.md`.
- AP04 erster isolierter Rottenowner: Zuordnung1–6, eindeutige Schiffs- und
  Pilotenbelegung, stabiler Ersatzführer, Ownership und actorbezogene
  Replayquittungen. Leere Entwurfsrotten sind inaktiv, letzte Entfernung
  löst sie auf. Verifier19/19. Root nimmt die Commandkategorie über den
  gemeinsamen Singleplayer-Ownerpfad an; Root-/Ownercheck30/30 und
  Warp-Rootregression7/7. Singleplayer-Adapter liest eigene Flotte und die
  bestehende Pilotenzuordnung; keine UI-Berechtigungsdaten. Identische
  Wiederholung funktioniert auch nach Reisebeginn; neue Umstellung während
  Warp/Anflug bleibt gesperrt. Adaptercheck9/9. UI-Anschluss,
  Tod-/Verlustereignisse im Raumkampf und Checkpointintegration fehlen.
- AP04 Lifecycle-Vorstufe: bestehende Änderungen an Pilotenzuordnungen und
  Flottensynchronisierung prüfen Rotten erneut. Ohne zugeordneten Piloten
  bleibt das Schiff Mitglied; ein verfügbarer Führer wird stabil gewählt,
  sonst ist die Rotte inaktiv. Entfernte Schiffe werden gelöst. Prüfung12/12;
  kein Nachweis für spätere Kampf-/Todereignisse.
- AP02 Tick-Vorstufe: Fixture-Flugsteuerung wird im Root-Physiktakt über
  die Batch-Kollisionsprüfung angewandt; echte Schiffs-IDs sind gesperrt, bis
  Kartenhindernisse und Ausrüstung angebunden sind. Gezielt 8/8; keine
  spielbare Steuerung oder Abnahme von AP02.
- AP05 Rottenpanel-Vorstufe: Sternkarte liest den Root-Rottensnapshot und
  sendet Erstellen, Umbenennen, Zuordnen, Entfernen und Führerwahl über den
  bestehenden Adapter. Mitglieder und Fehler werden angezeigt; Auswahl ist
  nur UI-Zustand. Die noch fehlende Speicherung wird im Panel benannt.
  Panelprüfung8/8, Adapter9/9, bestehende Sternkarten-UI89/89. Kartenwahl,
  sichtbarer Kampfflug und native Sichtabnahme fehlen; AP05 bleibt offen.
  Ruling: Panel unter der bestehenden Anflugbedienung angeordnet — erster
  Einbau oberhalb verschob bestehende Bedienelemente aus dem sichtbaren
  Bereich; dafür ist die Rottenverwaltung gegebenenfalls durch Scrollen zu
  erreichen. Native Ergonomie bleibt zu prüfen.
  Die Listen werden nur bei geänderten Rotten oder Schiffsnamen/-IDs neu
  aufgebaut, nicht bei fortlaufenden Pad-Animationsdaten; Panelprüfung9/9
  und Sternkarten-UI89/89.
- AP06 Owner-Vorstufe: Ein validierter Auftrag kann atomar mehrere aktive
  Rotten ersetzen; passive Kontakt-/Feuerregeln bleiben im Snapshot,
  Wiederholung ist idempotent, Abbruch prüft die aktuelle Auftrags-ID.
  Inaktive oder fremde Rotten verhindern die gesamte Änderung. 13/13;
  Adapter, UI, Flugausführung und Speicherung sind noch nicht angeschlossen.
- AP06 Navigationsvorstufe: reiner Ziel-/Statusresolver für Bewegen,
  Patrouille, Sichern und Rückzug; Ankunft erfordert auch niedrige
  Geschwindigkeit, blockierte Gruppen liefern keine Bewegungsabsicht und
  abgeschlossene Aufträge keine alten Absichten. 10/10, Owner13/13,
  Kollisionsbatch8/8. Ruling: gemeinsames Ziel hier nur als abstrakte
  Absicht ausgeben — Formation, Bremssteuerung und Korridorauflösung sind
  nicht angeschlossen; andernfalls würden mehrere Schiffe denselben Punkt
  ansteuern. Daher ausdrücklich kein produktiver Taktanschluss und keine
  spielbare Auftragsausführung behauptet.
- AP06 Einzel-Guidance-Vorstufe: separates Fixture berechnet aus Ziel und
  Geschwindigkeit Vorwärts-/Seitenschub und bremst; ein einzelner simulierter
  Flug erreicht sein Ziel mit geringer Geschwindigkeit. Prüfung5/5 sowie
  Flugresolver8/8 und Zielresolver10/10. Keine Kollisionsvermeidung,
  Formationsziele oder Bindung an echte Ausrüstungswerte; nicht im Produktpfad.
- AP06 Fixture-Integration: Root führt Einzel-Guidance im vorhandenen
  Physiktakt über die Kollisionsbatchprüfung aus; nur `space_fixture_`-IDs
  sind zugelassen. 11/11 einschließlich versperrtem Ziel, Flugtakt und
  Bodenbewegungsverifier ebenfalls erfolgreich. Bei Blockade wird Bewegung
  konservativ nicht committet; Geschwindigkeit bleibt erhalten, es findet
  noch keine vorausschauende Bremsung oder Blockadeauflösung statt. Keine
  Produktfreigabe.
- AP02/AP03/AP04/AP05/AP06 Rest und AP07–AP20: offen.

## Risiken / offene Punkte

- Supply-Preparedpatch 3f5b4ae04 als b555288d1 und Campaign-Preparedpatch
  07ca63a89 als b4d0b497f integriert; beide Ownerchecks erneut je12/12 mit
  isoliertem APPDATA. Noch kein gemeinsamer Root-Gruppencommit; vorbereiteter
  Travel-BeginApproach und die vollständige private Contextbindung fehlen.
- Polisa-Flight-ID-Fix 78f5966b5 als e521b3ebe integriert. Identitätscheck,
  echte Ersteintrittsfixture, Saumvorschau und Autoritätstick gezielt grün.
  Warpankunft, Oberflächenanflug/-abflug und Stationsverkehr benötigen
  getrennte Transitionen; der gemeinsame Produktanschluss steht noch aus.
- AP04a inaktiver Flightmode: gesonderte Activity-Validierung/-Commit für
  local tactical→inactive und inactive→tactical; Deaktivierung bewahrt Pose,
  Area und Objekt, Reaktivierung benötigt eine lokale Zielpose. Normale Motion-
  und Area-Commits können den Modus nicht umgehen. Prüfung21/21, bestehende
  Reise-/Rootfixtures grün. Root muss Gate/Index/Claims/Travel/Economy noch
  gemeinsam und atomar koordinieren; keine produktive Freischaltung.
- AP04a Root-Deaktivierungsvorschau baut nach gültiger Saumprüfung einen
  für den nächsten Roottick validierten `inactive`-Vorschlag, ohne Flight,
  Belegung oder Rotte zu mutieren. Saum-/Activityprüfung18/18, Flight21/21
  und Ersteintrittsfixture grün. Noch kein gemeinsamer Commit, keine
  Reaktivierung oder produktive Oberflächenfreigabe.
- AP04a Raumowner-Lifecycle: Ein bereits inaktives Flightobjekt kann aus
  aktivem Index, Steuerung und Korridorclaims genommen und mit derselben
  Objektreferenz samt erhaltenem Footprint später wieder eingetragen werden.
  Reaktivierungsvorschau prüft Flightrevision, ganze Fläche und Fremdbelegung;
  belegtes Ziel bleibt inaktiv. 9/9, Claims-/Saum-/Ersteintrittschecks grün.
  Root-Transaktion, Saum-/Travel-/Economyprüfung und produktiver Aufrufer
  bleiben offen; der Raumowner erstellt keinen neuen Piloten-/Rottenzustand.
- AP04a Root-Reaktivierungsvorschau: prüft inaktives identisches Flightobjekt,
  vorhandene Rotte, Surface-/Approach-Location→Orbit→Body, vier Revisionen,
  erlaubte Zielpose, Körpermaske, Saumkontakt, vollständigen Footprint und
  fremde Belegung/Claims. 8/8 mit veraltetem Stand, falschem Ort, Körper und
  belegtem Ziel. Keine Mutation, kein Travel-/Economycommit; Legacy-Surface
  ohne vorherigen lokalen Bestand braucht weiterhin eigenen Aufnahmeweg.
- AP04a echte Rückkehrfixture: Travelguard 346144881 als c4d1bda94 integriert,
  echter Ownercheck isoliert11/11. Root bereitet `enter_orbit` für ein bereits
  lokal inaktives Flightobjekt am freien Saum vor und verbindet im Fixture-Tail
  Activity, Index und stillen echten Travelowner; dieselbe Rotte bleibt.
  Gezielte Prüfung15/15 einschließlich Abbruch, neuer Blockade und Replay;
  bisherige Warp-/Fakefixtures grün. Der Test stellt die vorherige
  Anflugphase gezielt her, er beweist keinen vollständigen Oberflächenbesuch,
  keinen produktiven Caller und keine Supply-/Campaign-/Eventtransaktion.
- AP04a Warpdeparture-Vorschau: prüft aktiven lokalen Flight, seine Rotte,
  Gebiet/Belegung/Claims und vier Revisionen; Zielorbit muss zu einem anderen
  Körper gehören. Strategischer Startpunkt wird aus dem bestehenden
  Quellkörper abgeleitet; ein Area-/Travelvorschlag wird nur geprüft, nicht
  übernommen. 6/6, Surface-/First-Entry-Fixture grün. Echte Travel-/Warp-
  Vorbereitung, Fuel-/Kampfregeln, Frame-/Geschwindigkeitssemantik und
  gemeinsamer Commit fehlen; kein produktiver Warpstart.
- Autoritätskorrektur: Client-Skip wird vor Raumcallback und
  Indexsynchronisierung geprüft. Kleiner reproduzierter Client-/Hostcheck4/4,
  Raumtakt-, echte Reiseownerfixture und Bewegungsschuss grün. Der Test
  simuliert die Skipentscheidung; er ist kein vollständiger Multiplayerlauf.
- AP04a Saumgate-Vorbereitung: Root-/Adaptergrenze und Mehrhexregel mit dem
  Orbitchat abgestimmt; Details in `SPACE_ORBIT_WING_HANDOFF_2026_11_11.md`.
  Raumregistry besitzt pro Bereich monotone Belegungsrevisionen, unveränderte
  Updates erhöhen sie nicht. Registryprüfung15/15, Rotten- und
  Ersteintrittsfixture grün; keine Freigabe.
- AP04a Root-Saumvorschau: `preview_surface_approach` prüft autoritativen
  Flight-/Travel-/Rottenowner, Gebiet und deren erwartete Revisionen, den
  aktuellen indexierten vollständigen Footprint, fremde Belegung, Körpermaske,
  echten Gatekontakt und Location→Orbit→Body-Bindung. Ein großer Rumpf darf
  außerhalb der einfeldtiefen Gatezeile bleiben, solange ein Feld Kontakt hat
  und der Rest frei ist. Prüfung17/17 einschließlich fremder Belegung/Claims,
  veraltetem Index, Körperüberdeckung und falschem Oberflächenziel. Der echte
  Body muss das Ziel explizit als `surface_location_id` ausweisen und darf
  keine Station sein; Orbit-/Stationsziele erhalten kein Planetensaumgate.
  Keine Freigabe oder Produktaufrufer: weitere Ziel-/Lifecycleklassifikation,
  Pilot/Crew/Job, Supply/Campaign/Departure, spätere Revalidierung und
  gemeinsame stille Veröffentlichung fehlen. Der Bereichsowner führt nun
  konservative zellbasierte Navigationsclaims; Belegungs- und Claimsänderungen
  erhöhen gemeinsam die abgefragte Bereichsrevision. Claimowner6/6,
  Bereichsbatch7/7 und Eintrittssuche7/7. **Produktblocker:** Die echte
  Flugsteuerung veröffentlicht/erneuert/löst diese Claims noch nicht; keine
  zeitlichen Reservierungsfenster und keine volle Lifecycle-/Leistungsabnahme.
  Ein leerer Claimindex beweist daher noch keine freien Zukunftswege.
- Parallelcommit 26303641d (Boden-Türguard und Root) als 2a872b762
  integriert; Türguard, echte und Fake-Orbitfixture sowie Raumtakt gezielt
  grün. Keine vollständige native oder Boden-/Mehrspielerfreigabe.
- Parallelcommit 615327eaf (Bewegungsschuss und Root) als 4bf5d3d41
  integriert; Statuskonflikt mit Erhalt beider Einträge gelöst. Bewegungs-
  schuss, Bodenkonsumenten, Rootfixture, Bereichsbatch und Raumtakt geprüft
  und grün; keine vollständige native Freigabe.
- Parallelcommit 6a3f9c535 (Boden-Gruppen-/3D-Bewegungsleser und Root) als
  73ddde704 integriert. Bodenbewegung, Konsumenten, Raumtakt, Bereichsflug
  und Eintrittsvorschau gezielt grün; keine umfassende native Abnahme.
- Neue Nutzerfestlegung aus parallelem Chat: fliegende Schiffe immer genau eine
  Rotte, einschließlich Einzelschiff/Dropship; ein 512×256-Orbitraum pro
  Körper ersetzt drei getrennte Marker. Ownergrenze, Abhängigkeiten und
  Prüffälle: `docs/tasks/SPACE_ORBIT_WING_HANDOFF_2026_11_11.md`; AP04a im
  Plan. Aktuelle Implementierung erfüllt diese Vorgaben noch nicht; konkrete
  API und gemeinsam berührte Produktdateien vor Änderung abstimmen.
- AP04a Bereichskennung: Flightstate führt `space_area_id` und
  `coordinate_frame`; alte Zustände bleiben strategisch/ohne Bereich. Lokale
  Zustände benötigen eine Bereichs-ID; normale Motioncommits können den
  Rahmen nicht wechseln. Gezielte Prüfung8/8, Raumtakt-/Guidance- und
  Fleettravelprüfungen grün. Noch keine Bereichstransition, lokaler Index
  oder Produktanbindung; Layout-/Reisegate stammen vom parallelen Chat.
- AP04a Flighttransition-Baustein: mutationsfreie Revisions-/Tick-/Pose-
  Vorprüfung und separater Commit für den reinen Flightowner; Geschwindigkeit
  und Bereich werden gemeinsam übernommen. 13/13, vorhandene Flugtakt- und
  Fleettravelprüfungen grün. Dies ist noch keine transaktionale Root-/Travel-/
  Wing-/Registry-Verbindung und schaltet keine lokalen Bereiche frei.
  Der alte `commit_travel_pose` verweigert lokale Koordinaten; Flightprüfung
  14/14 und vorhandene Reiseprüfungen grün. Vor produktiver Freigabe muss der
  Reiseowner alte Aktionen auf lokalen Zuständen abfangen: dessen bisheriger
  `_set_travel_pose` erwartet Erfolg per Assertion.
- AP04a geometrische Eintrittsvorschau: baut kanonisches Orbitlayout, prüft
  Flugrevision, unteres Eintrittsband, vollständigen Rumpf, Körpermaske und
  belegte Zielfelder ohne Mutation. Prüfung7/7 einschließlich echter
  gebietsspezifischer Registry, Flight- und Footprintchecks
  grün. Sie ist keine Berechtigungsprüfung: reale Körper-/Reisezuordnung,
  Travelrevision, Rottenrevision, produktiver Token und atomarer Commit fehlen
  in dieser reinen Vorschau weiterhin.
- AP04a Root-Ownerfixture: `prepare_space_area_transition`,
  `commit_space_area_transition` und `release_space_area_transition` sind
  ausschließlich für `space_fixture_`-IDs und einen expliziten Test-Fleetowner
  nutzbar. Geprüft werden unter anderem Orbit-/Revisionsbindung,
  Mehrfachrequest, Belegung, Abbruch, Ablauf, ein stiller Übernahmepfad und
  erneuter Commit; Test18/18. Normale lokale Flugcommits bleiben gesperrt.
  Dies ist **keine produktive atomare Transaktion**: Der synchron geprüfte
  Fixture-Tail setzt nicht fehlschlagende Fixture-Ownercommits voraus und hat
  keinen Rollback; echter Travelcandidate, Root-generierter Berechtigungs-
  kontext, Supply/Campaign/Departure, Events und native Integration fehlen.
  Vor Produktfreigabe müssen diese Voraussetzungen und Fehlerfälle gemeinsam
  abgesichert werden; keine Fuel-/Oberflächenfreigabe aus diesem Pfad.
- AP04a echte Reiseowner-Fixture: Parallelcommit ce57b07f7 als 82c636c5f
  übernommen. Beim Konflikt blieb der gemeinsame Flightstate als Poseowner
  erhalten; Travel-Seal und -Epoch wurden ergänzt. Der echte vorbereitete
  Fleet-/Travelowner wurde in einer separaten, explizit auf Testschiff-IDs
  beschränkten Rootfixture gebunden: Warpabschluss, Flight-/Wing-/Index- und
  stiller Travel-Tail, Wiederholung, Abbruch und konkurrierender No-op-Request
  gezielt14/14. Der ursprüngliche Ownercheck lief erneut isoliert15/15;
  bestehende Fleettravel- und Fake-Rootfixturechecks grün. Kein produktiver
  Aufrufer, keine Surface-/Fuel-/Campaign-/Departureintegration, keine native
  Freigabe. Die echten Tail- und Rootinvarianten sind vor Produktanschluss
  noch gemeinsam zu reviewen; insbesondere lokaler Travel-Snapshot/Projektion,
  Root-Kontextbesitz, Rollback-/Fehlergrenzen und Events sind nicht abgenommen.
- AP04a Ersteintrittsfixture: Ein vorhandenes Flugobjekt muss vor einem
  Warpabschluss nicht künstlich im Kampfindex registriert sein. Die Fixture
  prüft einen expliziten Test-Footprint vor und nimmt das identische Objekt
  erst im Übergang in den lokalen Index auf. Eine zwischenzeitliche Aufnahme
  wird vor Mutation abgewiesen; gezielte Prüfung9/9, bereits registrierter
  Reise- und Fakeownerfall grün. Footprintquelle und Aufnahmeautorität sind
  noch Fixturewerte, nicht produktiver Rumpf-/Ownershipcontract.
- AP04a Eintrittsverteilung: reiner deterministischer Allocator plant für
  mehrere Testschiffe getrennte vollständige Footprints im Eintrittsband,
  berücksichtigt bestehende Bereichsbelegung und verändert keinen Owner.
  Gezielte Prüfung6/6. Eine neue inkrementelle Suche bearbeitet höchstens256
  Kandidaten pro Aufruf, prüft Flugrevisionen und erkennt zwischenzeitliche
  Belegung; gezielte Suche6/6. Der synchrone Wrapper ist nur für Fixtures.
  Produktanbindung, tatsächliche Kostenmessung und erneute Commitprüfung der
  Belegung fehlen; Vorschau reserviert keine Felder.
- AP04a Reviewkorrektur: Eintrittsvorschau prüft das **gesamte** Footprint im
  Eintrittsband, nicht nur den Anker (8/8). Erfolgreiche Fixtureübergänge
  verlassen den begrenzten Pool offener Tokens; Replayquittungen liegen
  separat (Rootfixture20/20 einschließlich 128 vorhandener Quittungen).
  Produktiver Receipt-Lifecycle und echte Ownertransaktion bleiben offen.
- AP04a Flugtaktfixture: strategischer und lokaler Testakteur werden im selben
  Roottakt getrennt nach Bereich gebatcht und bewegen sich unabhängig; 6/6,
  strategische Tick-/Rootfixtureprüfungen grün. Körpermaske wird mitgeführt.
  Keine Produktfreigabe oder Performanceabnahme.
- AP04a Raumindex: ShipRegistry trennt Zellbelegung nach Bereichs-ID; drei
  Schiffe auf derselben Zellkoordinate in zwei lokalen Bereichen und im
  strategischen Raum werden isoliert abgefragt. Lokale Kampfaufnahme wird
  bis zur Umstellung von Bounds, Footprint und Navigation explizit abgelehnt.
  Registry-/Sperrprüfung12/12, alte Registry-, Roottakt- und Batchprüfung
  grün. Das Orbitlayout des Parallelchats 9874511c4 ist als be6b9cc74
  integriert; keine Freigabe des noch fehlenden Bereichswechsels.
- AP04a lokale Aufnahmefixture: `SpaceCombatState` kann ausdrücklich markierte
  Testschiffe in getrennten lokalen Bereichen aufnehmen und verhindert dort
  Mehrfachbelegung; revisionsbasierte Indexsynchronisierung nutzt die lokalen
  Grenzen. Prüfung8/8; normale lokale Produktaufnahme bleibt gesperrt
  und die Fixture ersetzt keine Pflichtrotten-/Reiseprüfung.
- AP04a Grenzen: separater `space_area_grid` prüft axiale Zellen über die
  vorhandene Offsetkonvertierung gegen strategische256×256 oder lokale
  Orbitlayout512×256-Grenzen; das strategische Grid bleibt unverändert.
  Grenzprüfung8/8 und bestehende Geometrieprüfung grün. Bereichsidentität/
  Berechtigung bleiben Rootpflicht; lokale Kampfaufnahme bleibt gesperrt.
- AP04a Navigation: Sweeps und Blockerzellen nutzen den jeweiligen
  Koordinatenrahmen, gemischte Bereichs-IDs werden abgewiesen. Lokale Tests
  jenseits der strategischen 256er-Grenze, Blocker und Kartenrand4/4;
  strategische Geometrie, Batch und Fixture-Flugtakt grün. Root-Mutation,
  lokale Kampfaufnahme und tatsächliche Layoutblocker noch nicht verbunden.
- AP04a Bereichsbatch-Fixture: Root filtert Akteure und Zielbelegung nach
  Raum-ID; lokale Batchcommits verlangen expliziten Fixturekontext und
  Testschiff-ID. Körpermasken des kanonischen Orbitlayouts werden als
  Blockerzellen ergänzt und pro Bereich zwischengespeichert. Bereichstrennung,
  Sperre und Körperkollision6/6, bestehende Batch- und Übergangsfixture grün.
  Keine produktive lokale Bewegung; KI/Guidance und gemischte Formationen sind
  nicht angebunden. Fixturecache und volle Tickkosten sind nicht abgenommen.
- AP04a Footprint: einzellige und große Rümpfe prüfen die Grenzen des
  jeweiligen Koordinatenrahmens, einschließlich lokaler Kartenkante.
  Footprintprüfung4/4 und strategische Geometrie-/Rootchecks grün; lokale
  Aufnahme bleibt bis zur vollständigen Transaktion gesperrt.
  Die validierte Footprintvorschau und gebietsbezogene Zellabfrage stehen
  für die spätere Root-Vorprüfung bereit; Test5/5, keine Mutation.
- AP04a Commands/Zielresolver: Ziel- und Wegpunktgrenzen folgen dem allein
  vom Runtime-Kontext gelieferten Koordinatenrahmen; strategische Defaults
  bleiben kompatibel. Bereichs-Command4/4, Zielresolver11/11, AP00 und
  Rottenauftragsowner grün. Bereichszuordnung mehrerer beauftragter Rotten
  und produktive Runtime-Kontextlieferung bleiben offen.
- AP04 Pflichtrotte Owner-Vorstufe: `ensure_flying_wings` ergänzt fehlende
  Einzelrotten nach vollständiger atomarer Vorprüfung, erhält vorhandene
  Mitgliedschaften und bleibt beim Wiederholen unverändert. Fehlender Pilot
  lässt die Rotte inaktiv; fremde oder doppelte Schiffe und doppelte Piloten
  werden abgewiesen. Gezielte Prüfung9/9, alte Rotten-/Lifecycle-/Auftrags-
  verifier grün. Noch kein Anschluss an Flugstart, Gegneraufnahme, Transfer-
  Commands oder Speicherung; die Flug-Invariante ist damit noch nicht global
  durchgesetzt. Betroffene Reise- und Orbitdateien bleiben bis Abstimmung frei.
- AP04a Vorbereitung: `preview_flying_wings` prüft die Zuordnung auf einer
  isolierten Kopie und liefert die erwartete Rottenrevision ohne Liveänderung;
  Vorschau und anschließende Zuordnung liefern gleiche IDs. Prüfung12/12;
  Root muss die Revision beim Commit erneut prüfen. Keine Transaktion fertig.
  `ensure_flying_wings` kann nun die vorbereitete Revision erneut prüfen;
  ein veralteter Stand bleibt unverändert. Prüfung13/13; Rootanbindung offen.
- AP04 Transfer-Vorstufe: interner Ownerwechsel verschiebt ein Schiff atomar,
  prüft Ownership und Zielkapazität, löst eine geleerte Quellrotte auf und
  erhält beziehungsweise ersetzt die Führung. Der validierte Ownercommand
  `wing_transfer` nutzt diesen Wechsel und seine vorhandenen Replaybelege;
  Prüfung18/18 inklusive Sechsergrenze und Wiederholung, AP00 und Owner grün.
  Adapter, UI und Flugstart sind noch nicht angeschlossen.
- AP04 Entfernungsgate-Vorstufe: Der Owner verweigert `wing_remove`, wenn
  der vertrauenswürdige Runtime-Kontext das Schiff als fliegend ausweist.
  Prüfung10/10, Transfer18/18 und bestehender Adapter9/9. Der Adapter liefert
  die Liste bisher nicht; ohne sie ist die Regel noch nicht produktiv
  durchgesetzt. Reise-/Adapteranbindung gehört zur abgestimmten Folgearbeit.
- Parallelcommit c5e536d0d (Boden-Hexbewegung und Root) als bcd721bac
  integriert; Konflikt in Statusdoku unter Erhalt beider Einträge aufgelöst.
  Bodenbewegung und betroffene Raumtakt-/Auftragsprüfungen Exit0, keine
  vollständige Boden- oder native Sichtabnahme. Paralleler Worktree unverändert.
- Parallelcommit d539cbe89 (Polisa-Schiffsübernahme und Rückkehr) als
  381f06802 integriert. Backend-, Übergabe-, Weltraumtakt-, echter Szenen-,
  Rottenadapter-, Panel- und Auftragsownercheck jeweils Exit0 ohne Fehler.
  Der parallele Worktree wurde nicht geändert.
- Parallelstand b67b307b0 als 1ced3be19 integriert: Warp-Ausrüstung besitzt
  bereits eigenen Root-Owner, Katalog, Supply-Transaktionen und Savevalidierung.
  AP09/15/16 müssen diese vorhandene Struktur erweitern und Warp-Belege samt
  Komponentenbilanz erhalten. Kein zweiter Equipmentowner.

Basis: Plancommit de87366a6, integrierter Groundcommit ac53ff105 und
integrierter paralleler Adapterstand b3f9ab26d als 23f0df031. Der parallele
Worktree und dessen uncommittete Arbeit bleiben unverändert; vor weiterer
gemeinsamer Integration die aktuelle Entwicklung erneut prüfen.
Die Replay-Quittungen müssen vom künftigen autoritativen Owner pro Absender
geführt werden; der reine Validator speichert sie nicht selbst.
