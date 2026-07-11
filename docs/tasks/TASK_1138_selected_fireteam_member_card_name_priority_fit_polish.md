# TASK_1138 - Selected Fireteam Member Card Name and Priority Fit Polish

## Ziel / Problem
Nach TASK_1137 ist die Spielsprache klar, aber der echte Full-HD-Blick zeigt weiterhin abgeschnittene Namen und konkurrierende Rangbadges in den nur 156 Pixel breiten Member-Cards.

## Ursache / Sinn
Die taktische Kurzkarte uebernimmt denselben Badge-Header wie Roster-/FOB-Karten. Zusammen mit Portrait, Lead-Aktion und vier Statuszeilen bleibt fuer die Operator-Identitaet zu wenig Platz, obwohl der horizontale Selected-Fireteam-Scrollbereich breitere Karten vertraegt.

## Umfang
- Mission-Member-Cards moderat auf 176 Pixel verbreitern.
- Rangbadges nur in diesem taktischen Kurzkontext ausblenden; sie bleiben in FOB, Roster, Character-Sheet und Tooltipdaten erhalten.
- Vollstaendigen Operatornamen in den technischen Karten-Tooltip aufnehmen.
- Bestehende Statusprioritaet und vier Karten im horizontalen Scrollbereich erhalten.

## Nicht-Ziele
- Keine Aenderung an Profil-, Rank-, Lead-, Fireteam- oder Combat-Wahrheit.
- Kein Umbau des Bottom-Docks.
- Keine Aenderung an Commands, RPCs, Effects oder Snapshots.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1137_selected_fireteam_member_card_player_language_polish.md`
- `docs/tasks/TASK_472_fireteam_contact_perf_bubble_card_readability.md`
- `docs/dev/mission_command_feedback_contract.md`

## Akzeptanzkriterien
- Mission-Member-Cards verwenden 176 x 118 Pixel und bleiben horizontal scrollbar.
- Der Namensbereich ist groesser und wird nicht durch Rangbadges verkleinert.
- Vollname und technische Details bleiben im Tooltip erreichbar.
- Andere Compact-Card-Kontexte zeigen ihre Badges weiterhin.
- Keine neue per-frame Instanziierung oder Gameplay-Mutation.

## Betroffene Dateien
- `scripts/meta/npc_compact_card.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_472_fireteam_contact_perf_bubble_card_readability.gd`
- `scripts/tests/task_1138_selected_fireteam_member_card_name_priority_fit_polish.gd`
- Status, Roadmap und HTML-Arbeitsbericht

## Lokale Pruefung
- TASK_1138-Verifier
- TASK_207, TASK_472, TASK_503, TASK_1109, TASK_1136, TASK_222
- echter Full-HD-Capture

## Risiken / offene Punkte
Sehr lange Namen koennen weiterhin gekuerzt dargestellt werden; der Vollname bleibt dann bewusst per Tooltip erreichbar. Weitere Verdichtung soll nicht wieder taktische Prioritaeten verstecken.
