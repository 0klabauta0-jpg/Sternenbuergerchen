# TASK_1158 - Selected Fireteam Member Cards 1280 Readability

## Ziel / Problem

Die Member-Karten in `#17 AUSGEWAEHLTES FIRETEAM` sind im exportierten
1280x720-Fenster funktional, aber Namen und taktische Statuszeilen sind nach
der Skalierung zu klein fuer einen schnellen Gefechtsblick.

## Ursache / Sinnhaftigkeit

Die missionsspezifischen Karten verwenden 176x118 interne Pixel, 12 Pixel fuer
Namen und 10 Pixel fuer Runtime-/Detailtext. Im 1280er Fenster bleiben davon
etwa 117x79 sowie 8/6,7 reale Textpixel. Der vorhandene horizontale
Scrollbereich traegt vier moderat groessere Karten ohne Bottom-Dock-Umbau.

## Umfang

- Mission-Member-Karten auf 196x132 interne Pixel setzen.
- Name mit 15 Pixeln, Runtime- und taktischen Detailtext mit 12 Pixeln.
- Missionsspezifische Zeilenhoehen und Portraitgroesse passend stabilisieren.
- Andere Compact-Card-Kontexte unveraendert lassen.
- Read-only Snapshot fuer den 1280er Layoutvertrag bereitstellen.

## Nicht-Ziele

- Keine Aenderung an Unit-, Fireteam-, Combat-, Selection- oder Dropship-State.
- Keine Aenderung an Commands, Effects, RPCs oder Multiplayer-Ownership.
- Kein Umbau des Bottom-Docks und keine zusaetzliche Karteninstanziierung pro Frame.
- Keine Rueckkehr technischer Skills/Traits in die sichtbare Kurzkarte.

## Relevante Contracts / Dokumente

- `docs/tasks/TASK_1137_selected_fireteam_member_card_player_language_polish.md`
- `docs/tasks/TASK_1138_selected_fireteam_member_card_name_priority_fit_polish.md`
- `docs/tasks/TASK_1157_command_matrix_1280_readability.md`
- `docs/dev/mission_command_feedback_contract.md`

## Akzeptanzkriterien

- Mission-Member-Karten verwenden 196x132 Pixel und bleiben horizontal scrollbar.
- Namen verwenden mindestens 15 Pixel; Runtime- und Detailtext mindestens 12 Pixel.
- Vier Karten passen weiterhin in die vorhandene 840-Pixel-Member-Lane.
- Name, aktueller Befehl, Feuerstatus und taktischer Zustand bleiben sichtbar;
  technische Details bleiben im Tooltip.
- Styling und Refresh erzeugen keine Commands, Effects oder Multiplayer-Wahrheit.
- Roster-, FOB- und Dropship-Pilot-Karten behalten ihre bisherigen Defaults.

## Betroffene Dateien

- `scripts/meta/npc_compact_card.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1158_selected_fireteam_member_cards_1280_readability.gd`
- Status, Roadmap, Contract und HTML-Arbeitsbericht

## Lokale Pruefung

- TASK_1158 bei 1280x720.
- TASK_1137, TASK_1138, TASK_472 und TASK_180.
- TASK_1109/1110 sowie aktuelle HUD-/Performance-Gates.
- Exportierter Host/Client-First-Contact-Recapture.
- `git diff --check`.

## Risiken / offene Punkte

Fireteams mit mehr als vier Mitgliedern bleiben bewusst horizontal scrollbar.
Die Karte priorisiert Identitaet und Live-Zustand; Vollwerte bleiben im Tooltip
und Character-Sheet.
