# A5 – Startfreigabe und Truppübergabe nach Einsatzende

## Problem und Ursache

Nach Grid Sweep, Debriefing und Rückkehr bleibt der alte taktische Plan
im MetaLayer. Abgesetzte Einheiten aktivieren die Startfreigabe für eine
Vorschau, auch während der Cutlass zurückfliegt. Der Folgeeinsatz übernimmt
die alten Einheiten und die Landezone. Der taktische Transportfilter
entfernt bereits abgesetzte IDs aus der neuen Fracht.

## Umfang

- Den taktischen Plan beim Abschluss der Einzelspielermission leeren.
  Ergebnis, Roster, Pilot, Ausrüstung und laufende Meta-Transfers bleiben
  in den dafür zuständigen Komponenten.
- Einen laufenden Rückflug genau einmal abschließen. Der Start für den
  zurückkehrenden Transport bleibt bis zur Bereitschaft gesperrt. Die
  Heimatbasis zeigt die Rückkehr des Schiffs an. Der Missionsreiter
  kann nach dem Debrief nur einen aktiven Einsatz wieder öffnen.
- Zweiten Start, neue Landezone und reguläres Ausladen derselben Operatoren
  in einer frisch exportierten Windows-EXE prüfen.

Der Auftrag umfasst den Homebase-Direct-Einzelspielerpfad. Multiplayer,
Karteninhalte, Kampfregeln und Release-Freigabe liegen außerhalb des Umfangs.

## Verträge und Dateien

- [Homebase Direct](../dev/homebase_direct_dropship_flow_contract.md)
- [Fluggerät-Recovery](../dev/air_asset_loss_recovery_meta_loop.md)
- Metaübergang in scripts/meta/meta_layer_flow.gd, Statusanzeige in
  scripts/meta/homebase_screen.gd und ein fokussierter Verifier unter
  scripts/tests.

## Akzeptanz und lokale Prüfung

Nach dem realen Ergebnis bleibt ein laufender Rücktransfer samt ETA
erhalten. Der neue Einsatz erhält dieselbe gültige Zuordnung und einen
frischen taktischen Plan. Die Windows-EXE belegt den regulären Ablauf bis
zum Ausladen im zweiten Einsatz. Ergänzende isolierte Verifier schützen
Bootstrap, Debrief, parallele Transporte und Recovery. Jeder Lauf
verwendet Pfadguard und frisch geprüfte Original-Roster-Baseline.

Der Verifier second_sortie_planning_lifecycle_verifier.gd nutzt den
regulären Menü- und Debrief-Pfad mit gezielt gesetztem Abschlusszustand.
Die Varianten prüfen frühen Abschluss, beschädigtes Fluggerät und ein
wiederholtes Rücksignal nach der Ankunft.

Risiko ist die Vermischung von Missionsabschluss und laufender
Missionsplanung. Ein zweiter Schiffstransfer in einen noch aktiven Einsatz
muss dessen Planung behalten.
