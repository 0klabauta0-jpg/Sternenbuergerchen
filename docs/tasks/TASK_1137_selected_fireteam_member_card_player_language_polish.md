# TASK_1137 - Selected Fireteam Member Card Player Language Polish

## Ziel / Problem
Die Member-Cards im Bereich `Selected Fireteam` mischen deutsche Spielsprache mit englischen Runtime-Begriffen (`Move`, `Aim up`, `Run`) und zeigen rohe Skill-Kuerzel (`A:`, `S:`) in der knappen sichtbaren Flaeche.

## Ursache / Sinn
Der bestehende Presenter reicht interne Enum-Namen und den technischen Skill-Summary direkt an die kompakte Karte weiter. Die Daten sind korrekt, aber fuer Spieler schlecht lesbar und konkurrieren mit den unmittelbar taktischen Informationen.

## Umfang
- Command-, Waffen- und Bewegungsstatus in einheitliche deutsche Spielsprache uebersetzen.
- Aim-Readiness als `Zielbereit` statt `Aim` beschriften.
- Skill- und Trait-Details aus der sichtbaren Kurzkarte entfernen.
- Vollstaendige technische Werte im Tooltip der Karte erhalten.

## Nicht-Ziele
- Keine Aenderung an Unit-, Fireteam-, Combat-, Stance- oder Movement-State.
- Keine Aenderung an RPCs, Commands, Effects oder Snapshots.
- Kein Umbau des Card-Layouts oder des Dirty-Refresh-Pfads.

## Relevante Contracts / Dokumente
- `docs/ARCHITECTURE.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_1136_live_tactical_stance_effect_playtest_feedback.md`

## Akzeptanzkriterien
- Sichtbare Karten enthalten keine bekannten englischen Runtime-Begriffe oder rohen `A:`-/`S:`-Skillwerte.
- Command, Waffenhaltung, Bewegung und Zielbereitschaft sind ohne Entwicklerwissen lesbar.
- Skill-/Trait-Diagnose bleibt per Tooltip erreichbar.
- Bestehende Card-Instanzen und Dirty-/Delta-Refresh bleiben erhalten.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/meta/npc_compact_card.gd`
- `scripts/tests/task_1137_selected_fireteam_member_card_player_language_polish.gd`
- Status-, Roadmap- und HTML-Arbeitsbericht

## Lokale Pruefung
- TASK_1137-Verifier
- Stance-, Dropship-/Fireteam-, Multiplayer- und Performance-Regressionen
- echter Full-HD-F6-Lauf

## Risiken / offene Punkte
Die Karte bleibt bewusst knapp. Weitere Detailinformationen gehoeren in das bestehende Character-Sheet und nicht zurueck in die vier sichtbaren Kartenzeilen.
