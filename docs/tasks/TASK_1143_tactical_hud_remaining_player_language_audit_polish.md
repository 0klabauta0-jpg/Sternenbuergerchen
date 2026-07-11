# TASK_1143 - Tactical HUD Remaining Player Language Audit and Polish

## Ziel / Problem
Der Full-HD-HUD mischt nach TASK_1142 weiterhin `LIVE TACTICAL GRID`, `Realtime insertion feed`, `CUE WAIT`, `live fireteam deployment`, `EVENT LOG`, `CONTACT PRESSURE` und `OFF LIVE` mit deutscher Spielsprache.

## Ursache / Sinn
Identitaet, Event Log und Haltungsfeedback besitzen getrennte historische String-Pfade. Die technischen Begriffe sind fuer Evidence nuetzlich, aber als sichtbare Spielerhierarchie inkonsistent.

## Umfang
- Gemeinsamen read-only Sprachpresenter fuer Identitaet, Event-Log und Live-Haltung einfuehren.
- Sichtbare Header und Fallback-Ereignisse in kurze deutsche Spielersprache bringen.
- `LIVE` im Haltungsstatus durch `AKTIV` ersetzen.
- Rohtexte und Event-Dictionaries unveraendert in Snapshots/Tooltips erhalten.

## Nicht-Ziele
- Keine Aenderung an EventRouter, TacticalEventLog, Combat-, Contact-, FireEvent-, Stance- oder Multiplayer-Wahrheit.
- Kein Layoutumbau der HUD-Panels.
- Keine Aenderung an Commands, Effects, RPCs oder Snapshotfeldern.

## Akzeptanzkriterien
- Sichtbar stehen `EINSATZLAGE`, `EREIGNISSE`, `KONTAKTDRUCK`/`FEUERKONTAKT` und `AKTIV`.
- Sichtbar stehen nicht `LIVE TACTICAL GRID`, `Realtime insertion feed`, `live fireteam deployment`, `EVENT LOG`, `CONTACT PRESSURE` oder `OFF LIVE`.
- Event- und Diagnose-Rohtexte bleiben unveraendert pruefbar.
- Event-Dedupe, Selected-Filter, Stance-Wirkung, Multiplayer-Perspektive und Performance bleiben gruen.

## Betroffene Dateien
- `scripts/ui/tactical_hud_language_presenter.gd`
- `scripts/ui/tactical_event_log_panel.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1143_tactical_hud_remaining_player_language_audit_polish.gd`
- sichtbare Haltungsverifier
- Status, Roadmap und HTML-Arbeitsbericht

## Lokale Pruefung
- TASK_1143-Verifier
- TASK_1136 und relevante Event-Log-Verifier
- TASK_1118/1120, TASK_222
- echter Full-HD-Capture

## Risiken / offene Punkte
Historische Release-Findings pruefen absichtlich `CONTACT PRESSURE` als damaligen Rohbefund. Diese Artefakte und Snapshotfelder werden nicht umgeschrieben; nur die aktuelle sichtbare Paneldarstellung wird uebersetzt.
