# TASK_508 - Line-of-Fire / Threat Analyzer MVP

## Ziel / Problem
Fuer eine geplante Zielposition soll ein taktischer Service bekannte Sicht-/Schussrisiken bewerten.

## Umfang
- Neuer `TacticalDecisionThreatAnalyzer` unter `scripts/tactical/`.
- Inputs: Kandidatenposition, bekannte Enemy-/Contact-Eintraege, Friendly-Eintraege, TerrainRegistry und `LineOfSightSystem`.
- Outputs: Risk-State, Cover-State, Enemy-Exposure, Friendly-Fire-Risiko und Line-of-Fire-Eintraege.

## Nicht-Ziele
- Keine echte Ballistik.
- Kein neuer ContactTracker.
- Kein perfektes Gegnerwissen.

## Akzeptanzkriterien
- Safe/Risky/Suicidal-Faelle sind im Verifier reproduzierbar.
- Blockierte Linien bleiben grau/blocked.
- Friendly-Fire-Risiko wird getrennt von Enemy-Exposure gemeldet.

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_506_tactical_decision_clarity_contract.gd`

## Risiken / offene Punkte
- Die erste Klassifikation ist bewusst grob und fuer Playtest-Lesbarkeit gedacht.
