# TASK_1162 - Left Tactical Stack 1280 Readability and Focus Balance

## Ziel / Problem
Nach TASK_1161 ist das primaere HUD im 1280x720-Release wieder gemeinsam geprueft. Der sichtbare Folgefund liegt links: Fireteam-Mini-Cards und Tactical Event Log sind funktional, wirken im echten Release-Bild aber dicht und klein. Der Spieler soll links sofort erkennen, welches Fireteam ausgewaehlt ist, ob es kampfbereit ist und welche neuesten Ereignisse dazu passen.

## Sinnhaftigkeit / Ursache
Die Mini-Cards wurden ueber viele Tasks kompakter und informationsreicher. Das Event Log wurde separat fuer 1280 lesbarer. Zusammen bilden beide aber eine eigene linke Taktikspalte. Ohne eigenen Stack-Vertrag kann die Mini-Card-Fokusmarkierung mit Header-/Status-/Stance-Elementen konkurrieren oder #19 wirkt daneben wie ein fremdes Panel.

## Umfang
- Read-only Snapshot fuer die linke 1280-Taktikspalte aus Fireteam-Mini-Cards und Event Log.
- Mini-Cards behalten Lead-/Status-/Stance-Vertraege, bekommen aber eine stabile TASK_1162-Fokusmarkierung und lesbare Mindestwerte fuer 1280.
- Event Log wird als Nachbarflaeche im Stack mitgeprueft, nicht neu gebaut.
- Bestehende Dirty-/Runtime-Guards bleiben erhalten.

## Nicht-Ziele
- Kein neues Missions-HUD-Layout.
- Keine neuen Fireteam-, Dropship-, Combat- oder Multiplayer-Regeln.
- Kein Ersatz fuer TASK_1159 Event-Log-Panel-Vertrag.
- Kein per-frame Komplett-Rebuild der linken UI.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_1130_fireteam_mini_card_identity_typography_polish.md`
- `docs/tasks/TASK_1131_fireteam_mini_card_header_contrast_status_compression.md`
- `docs/tasks/TASK_1132_fireteam_mini_card_tactical_state_language_polish.md`
- `docs/tasks/TASK_1133_fireteam_mini_card_stance_control_readability.md`
- `docs/tasks/TASK_1159_tactical_event_log_1280_readability.md`
- `docs/tasks/TASK_1161_1280_release_recapture_primary_hud_balance.md`

## Akzeptanzkriterien
- `MissionTacticalSandboxController` liefert `get_left_tactical_stack_1280_readability_snapshot()`.
- Der Snapshot nennt Fireteam-Mini- und Event-Log-Surfaces, Style-ID, Stack-Layout und Fokusstatus.
- Mindestens zwei Mini-Cards sind bei 1280 lesbar: Titel >= 13 px, Status/Lead >= 11 px, Stance-Segmente bleiben vorhanden.
- Genau die ausgewaehlte Mini-Card ist als Fokuskarte markiert und hat eine staerkere visuelle Prioritaet.
- #19 Event Log bleibt im selben Stack lesbar, verwendet seinen TASK_1159-Vertrag und ueberlappt die Mini-Cards nicht.
- Der Snapshot ist read-only und erzeugt keine Commands, Effects, Fire-/Damage-Events oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1162_left_tactical_stack_1280_readability_focus_balance.gd`
- `docs/tasks/TASK_1162_left_tactical_stack_1280_readability_focus_balance.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- Neuer Verifier: `scripts/tests/task_1162_left_tactical_stack_1280_readability_focus_balance.gd`
- Regressionen: TASK_1130, TASK_1131, TASK_1132, TASK_1133, TASK_1154, TASK_1159, TASK_1109, TASK_1110, TASK_222.
- `git diff --check`.

## Risiken / offene Punkte
Der Task haertet die linke Stack-Lesbarkeit strukturell. Ein echter 1280x720-Release-Sichttest bleibt danach sinnvoll, weil Headless-Tests keine subjektive Blickruhe beweisen.
