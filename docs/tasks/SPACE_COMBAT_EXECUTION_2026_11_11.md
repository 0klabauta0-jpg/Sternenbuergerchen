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
- AP04 erster isolierter Rottenowner: Zuordnung1–6, eindeutige Schiffs- und
  Pilotenbelegung, stabiler Ersatzführer, Ownership und actorbezogene
  Replayquittungen. Leere Entwurfsrotten sind inaktiv, letzte Entfernung
  löst sie auf. Verifier19/19. Root nimmt die Commandkategorie über den
  gemeinsamen Singleplayer-Ownerpfad an; Root-/Ownercheck30/30 und
  Warp-Rootregression7/7. Der autoritative Aufrufer muss eine vollständige
  aktuelle Craft-/Pilotenzuordnung liefern; Adapter-/UI-Anschluss,
  Lifecycle- und Checkpointintegration fehlen.
- AP02/AP03/AP04 Rest und AP05–AP20: offen.

## Risiken / offene Punkte

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
