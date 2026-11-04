# Drei ältere Gates auf Main

Die drei reproduzierten Gates aus der A5-/Review-7-Matrix auf Basis
`01d6eec75` untersuchen und korrigieren. Bei veralteten Erwartungen gelten
die jeweils aktuellen Projektverträge. Bestehende Verhaltensabdeckung
bleibt erhalten.

- Umfang: TASK839 mit relevanten Vorgängergates, TASK1122 und TASK326.
- Grundlagen: Architektur, TASK839, TASK1122, Lobby-/Team-Ownership und
  Map-Editor-Asset-Verträge sowie A5-Integrationsbericht.
- Akzeptanz: alle drei Gates und die Review-7-Matrix mit unverändertem
  Pfadguard, eigenen Profilen und frisch erfasster Roster-Baseline.
- Grenzen: gezielte Korrekturen, keine allgemeine Release-Abnahme.
- Risiken: ältere Produktproben können von späteren UI- oder
  Grafikverträgen abweichen. Echte Laufzeitfehler am Ursprung korrigieren.

## Ursachen und Korrekturen

- TASK839: Die Weltlabel-Prüfungen waren grün. Der Gesamtstatus erbte über
  TASK838 und TASK836 die Geometrie- und Stylingprüfungen des alten HUD.
  TASK838 prüft jetzt das sichtbare Ereignisprotokoll samt Zeilen und
  schreibgeschütztem Fallback im aktiven Firefight. Der historische Status
  von TASK836 bleibt in der Diagnose. TASK839 verlangt weiterhin ein
  bestandenes TASK838-Gate. Der ergänzte TASK838-Verifier prüft außerdem
  den Originalfallback bei leerem Rohlog und dessen Unverändertheit.
- TASK1122: GM01 aktiviert das Frontier-Profil mit ACES und neutraler
  Helligkeit. Der Verifier prüft diesen Pfad und separat Filmic mit
  begrenzter Helligkeitskorrektur für eine Karte ohne Frontier-Profil.
- TASK326: TASK520 bestimmt Host-Roster als Standard und lokale Roster
  als ausdrückliche Auswahl. TASK485 setzt die modulare Bodenplatte auf
  Maßstab 0.25. Der Verifier prüft Standard, explizite Wahl einschließlich
  Session-Propagation sowie Maßstab und bodenbündige Platzierung.

Betroffene Laufzeitpfade sind `scripts/meta/meta_layer_flow.gd`,
`scripts/tests/mission_tactical_sandbox_controller.gd` und der
First-Exchange-HUD-Source-Sync. Die übrigen Anpassungen betreffen
Verifier und Verträge.

## Verifikation

- RED auf Main `01d6eec75`: TASK839 29/2, TASK1122 9/2, TASK326 35/3.
- GREEN: TASK839 31/31, TASK1122 14/14, TASK326 41/41.
- Gezielte Reihe 6/6, Nachbargates 5/5, A5 13/13, Review 7 103/103.
- 127 erfolgreiche Headless-Läufe mit unterschiedlichen frischen
  Nutzerdatenpfaden und bestätigtem Pfadguard. SHA-256, Länge und
  Schreibzeit des Original-Rosters stimmen mit der frischen Baseline
  überein.
- Getesteter Indexbaum vor dieser Dokuergänzung
  `1e84c64485cae2737d9f299e360062d4b40258a7`. Lokale Rohberichte,
  RED-Belege und Ergebnisindex unter `.godot/legacy_gates/` im
  Integrationsworktree. Prüfgegenstand sind die genannten Headless-Gates.
