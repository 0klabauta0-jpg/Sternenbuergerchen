# A5-Integration auf Review 7

A5 (`854a19e3b`) auf den geprüften Review-7-Stand (`bc6deb3a7`) übernehmen.
Die getrennt entwickelten UI-, GM01-, HPA- und FoW-Pfade treffen in sechs
Konfliktdateien zusammen. Der ursprüngliche Checkout bleibt unangetastet.

- Umfang: Merge der A5-Linie und erforderliche Konfliktkorrekturen.
- Grenzen: bestehende Runtime-Verträge, keine neue UI-Wahrheit, kein Release.
- Grundlagen: Architektur, Roster-Generierungsvertrag, Review-7-Task und
  `docs/qa/mission_a5_kartenrand_20261102/README.md`.
- Betroffene Konfliktpfade: Implementation Status, Roster-Vertrag und Generator,
  HPA-Pathfinder, Terrain-View und Tactical Sandbox Controller.
- Abnahme: A5-Matrix und Review-7-Matrix seriell mit synchronem Pfadguard
  und frischer Roster-Baseline. Abweichungen gegen die jeweiligen Baselines
  prüfen. Den kombinierten Commit per Fast-forward auf Main veröffentlichen.
- Risiken: unterschiedliches Routing- und Rendering-Verhalten bei gleichen
  Verifiern sowie bekannte Altfehler der Review-7-Matrix.

## Konfliktauflösung und Abschlussprüfung

- HPA behält die vorwärts und rückwärts gerichteten Komponentenkostenkarten
  und ergänzt A5s abfragebezogenen Kostenkontext, Portal-Pruning und
  revisionsgebundenen FIFO-Ergebniscache mit 64 Einträgen. Der Verifier prüft
  331 Assertions inklusive exakter geordneter Pfade.
- FoW verwendet fortlaufende Review-7-Deltas und A5s vollständigen
  Snapshotabgleich bei Revisionslücken während des Aufbaus. HUD-Details
  behalten wiederverwendete Dropship-Karten, Fokus und Scrollposition.
  Eingeschiffte Fireteams zeigen ihren Status im A5-HUD. Der Roster-Validator
  akzeptiert nur endliche effektive Werte im Bereich 0 bis 1.
- Die betroffenen älteren Verifier prüfen die echten A5-Steuerelemente und
  getrennte HPA-Cache-Ebenen. Für die Menübildprüfung wurde die versionierte,
  hashgeprüfte Herkunftsdatei in das private Overlay kopiert.
- Getesteter Indexbaum vor dieser Dokuergänzung: `84db57f50826526314485d5ba9e170d55273bc08`.
  A5 13/13, Review 7 100/103, davon alle elf neuen Review-7-Gates grün.
  TASK839 (29/2), TASK1122 (9/2) und Lobby-/Assetfollowup (35/3) stimmen
  in Exitcode, Fehlertext und Assertionzahlen mit dem geprüften Review-7-Stand
  überein. Alle 116 finalen Headless-Fälle hatten eigene Pfade und Canaries.
- Nativ: Review-7-FoW 39/39 mit GPU-Readback, A5-Vulkan-FoW 56/56,
  A5-UI 113/113. Normalstart bei 1920×1080 83/83 einschließlich
  Westgrenzübertritt, bei 1280×720 70/70. Der erste 1280er-Lauf meldete eine
  ObjectDB-Warnung beim Beenden. Die frische Wiederholung mit ausführlichem
  Log endete ohne Warnung. Beide Logs bleiben im Integrationsworktree.
- Original-Roster unverändert in SHA-256, Länge und Schreibzeit. Rohbelege
  und Guard-Helfer unter `.godot/a5_integration/` im Integrationsworktree,
  Übersicht `final_summary.json`. Die Belege sind lokale Prüfergebnisse.
