# TASK_506 - Tactical Decision Clarity Contract

## Ziel / Problem
Move-Preview und Line-of-Fire sollen denselben Datenvertrag nutzen, damit der Spieler vor `GO` versteht, warum ein Ziel sicher, riskant oder suizidal ist.

## Sinnhaftigkeit / Ursache
`TASK_375` zeigte bereits Ghost-Pfad und ETA, aber Risiko blieb mangels echter Daten `unknown`. Der neue Slice erweitert diesen Vertrag, ohne Combat oder UI zur Gameplay-Wahrheit zu machen.

## Umfang
- Contract fuer Preview-, Threat- und Visualdaten.
- Read-only-Grenze dokumentieren.
- Bestehenden `waypoint_intent_preview` erweitern, nicht ersetzen.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Kein Command-Point-System.
- Keine neue Contact-Report-UI.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/dev/runtime_script_layout_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/tasks/TASK_375_waypoint_intent_preview.md`

## Akzeptanzkriterien
- Preview-Payload nennt Ghost, Pfad, ETA, Risk-State, Threat-Analyse und Read-only-Grenze.
- Ohne Threat-Kontext bleibt Risiko `unknown`.
- Bestehender Waypoint-Preview-Pfad bleibt erhalten.

## Betroffene Dateien
- `docs/dev/tactical_decision_clarity_contract.md`
- `scripts/tactical/waypoint_intent_preview_resolver.gd`
- `scripts/tactical/tactical_decision_threat_analyzer.gd`
- `scripts/tests/task_506_tactical_decision_clarity_contract.gd`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_506_tactical_decision_clarity_contract.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die Bewertung nutzt bekannte Kontakte/uebergebene Fixtures, keine Allwissenheit.
