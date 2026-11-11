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
  Die erneute Ausführung bestätigt keinen Produktanschluss.
- AP01–AP20: offen.

## Risiken / offene Punkte

Basis: Plancommit de87366a6 und integrierter Groundcommit ac53ff105. Der
parallele native Branch ist bei b3f9ab26d weiter: insbesondere
`singleplayer_runtime_adapter.gd`, `meta_layer_flow.gd` und Ansichten wurden
dort geändert. Vor AP01 diesen Stand erneut prüfen und gezielt integrieren;
nicht den parallelen Worktree oder dessen uncommittete Arbeit verändern.
Die Replay-Quittungen müssen vom künftigen autoritativen Owner pro Absender
geführt werden; der reine Validator speichert sie nicht selbst.
