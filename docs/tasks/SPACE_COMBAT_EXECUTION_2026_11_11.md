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
  Nachprüfung im Projekt 22/22, einschließlich typfester Replay-Signaturen
  und unabhängig von Dictionary-Reihenfolge. Noch kein Produktanschluss.
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
  Gegneraufnahme kann keine Spieler-Craft-ID übernehmen. Rootcheck14/14.
- AP01 weiterhin offen: vollständige Bewegungstakt-Exklusivität und
  tatsächlicher Adapter-/Root-/Ansichtswechselcheck bei30/60/144Render-FPS,
  und vollständiger Reiselauf.
- AP02 erster reiner Resolver: gekoppeltes seitliches Gegensteuern,
  ausgekoppeltes Gleiten, getrennte Bugdrehung, Masse-/Schubwirkung und
  gemeinsames Achsbudget. Kleiner Verifier5/5. Nur Fixtureparameter;
  Rumpfkatalog, Tickanbindung und vollständige AP02-Abnahme fehlen.
- AP01/AP02 Rest und AP03–AP20: offen.

## Risiken / offene Punkte

Basis: Plancommit de87366a6, integrierter Groundcommit ac53ff105 und
integrierter paralleler Adapterstand b3f9ab26d als 23f0df031. Der parallele
Worktree und dessen uncommittete Arbeit bleiben unverändert; vor weiterer
gemeinsamer Integration die aktuelle Entwicklung erneut prüfen.
Die Replay-Quittungen müssen vom künftigen autoritativen Owner pro Absender
geführt werden; der reine Validator speichert sie nicht selbst.
