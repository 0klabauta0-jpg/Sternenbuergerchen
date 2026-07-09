# TASK_948 - Tactical Decision Clarity Scenario Return

## Ziel / Problem
Die First-Exchange-Polish-Kette hat den ersten Feuerblick immer weiter verfeinert. TASK_947 routet bei Restreibung bewusst weg von noch einem Fire-Lane-Mikropolish. TASK_948 legt diesen Wechsel fest: Der naechste Schritt soll wieder ein kleiner spielbarer Entscheidungsgriff vor `GO` werden.

## Sinnhaftigkeit / Ursache
Das Projekt kommt dem Ziel "rundes kleines Spiel" naeher, wenn Bewegung, Risiko und Konsequenz vor dem Befehl lesbar sind. Die Systeme aus TASK_506 bis TASK_510 existieren bereits; jetzt sollen sie wieder in ein kleines Szenario statt in isolierte Screenshot-Politur fuehren.

## Umfang
- TASK_947-Return-Route pruefen.
- Vorhandene Decision-Clarity-Faehigkeiten als konkreten Playability-Stack benennen.
- Den naechsten Slice als `TASK_949 - Order Preview Threat Overlay Playtest Scenario` festlegen.
- Read-only-Grenzen halten: Preview/Planung zeigt nur, mutiert aber nichts.

## Nicht-Ziele
- Kein weiterer Fire-Lane-Wertepolish.
- Kein Combat-Rewrite.
- Kein neues Movement-, Damage-, Multiplayer- oder UI-Wahrheitssystem.
- Kein Smoke-Run und kein Screenshot-Capture in diesem Task.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_947_release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_visual_findings.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_506_tactical_decision_clarity_contract.md`
- `docs/tasks/TASK_507_order_preview_ghosts_mvp.md`
- `docs/tasks/TASK_508_line_of_fire_threat_analyzer_mvp.md`
- `docs/tasks/TASK_509_combined_preview_overlay.md`
- `docs/tasks/TASK_510_contact_report_upgrade.md`

## Akzeptanzkriterien
- `TacticalDecisionClarityScenarioReturn.build_snapshot()` blockt fehlende oder nicht passende TASK_947-Quellen.
- Bei `ready_for_tactical_decision_clarity_return` empfiehlt der Snapshot `TASK_949 - Order Preview Threat Overlay Playtest Scenario`.
- Der Snapshot nennt die Spielerfragen: Wo geht das Fireteam hin, wer sieht das Ziel, warum ist der Move safe/risky/suicidal, und was passiert erst nach `GO`.
- Die vorhandenen Faehigkeiten Ghost, Pfad, Threat-Level, Line-of-Fire, Contact-Awareness und AI-Intent-Debug werden als Stack benannt.
- Der Snapshot bleibt read-only und erzeugt keine Commands, Movement-, Fire-, Damage- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `docs/tasks/TASK_948_tactical_decision_clarity_scenario_return.md`
- `scripts/mission/tactical_decision_clarity_scenario_return.gd`
- `scripts/tests/task_948_tactical_decision_clarity_scenario_return.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_948_tactical_decision_clarity_scenario_return.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_947_release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_visual_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_948 ist der Rueckkehr- und Schnittpunkt, noch nicht der eigentliche Playtest. Der naechste Task muss nun wirklich eine kleine spielbare Preview-/Threat-Situation bauen oder verbinden, statt erneut nur einen Bericht zu erzeugen.

## Naechster Schritt
TASK_949 - Order Preview Threat Overlay Playtest Scenario.
