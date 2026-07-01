# TASK_776 - Station Reentry Contact Pressure Feel Pass

## Ziel / Problem
TASK_775 macht den ersten Stationsgriff lesbar. Jetzt muss der naechste taktische Moment stimmen: Wenn Kontakt entsteht, soll der Spieler vor oder waehrend der ersten Feuerentscheidung verstehen, wo Gefahr herkommt, ob der geplante Zug riskant ist und ob HUD/Contact-Feedback diese Spannung knapp erklaeren.

## Sinnhaftigkeit / Ursache
Die bisherigen Reentry-Schritte pruefen Route, Commands, Performance und Host/Client-Kontext. Ohne Contact-/Pressure-Lesbarkeit wirkt die Station aber nur wie eine Bedienroute. Der Spieler braucht frueh sichtbare Kontaktmeldung, Risiko-/LOS-Grund und kompaktes Combat-HUD, bevor wir echten Kampfdruck weiter polieren.

## Umfang
- Read-only Feel-Pass fuer Contact-/Threat-/Pressure-Lesbarkeit im Station-Reentry-Slice.
- Bewertung von:
  - TASK_775-Interaction-Feel als Voraussetzung
  - Contact-Report mit Position, Confidence, Alter und Kurztext
  - Threat-/Risk-Preview mit sichtbaren Linien/Exposure-Gruenden
  - First-Engagement-/Pressure-Feedback mit Fire/Wait/No-Fire-Kontext
  - kompakter HUD-Zeile mit Contact/Risk/LOS/Cover-Tokens
- Status, Roadmap, Contract und HTML-Handbuch aktualisieren.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine echte Suppression-, Ammo- oder Damage-Aenderung.
- Keine neue Contact-Wahrheit im HUD.
- Keine Commands, Navigation oder FireEvents aus diesem Feel-Pass.
- Kein Ersatz fuer den spaeteren sichtbaren Playtest.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_775_station_reentry_mission_interaction_feel_pass.md`
- `docs/tasks/TASK_542_mission_first_contact_readability_pass.md`
- `docs/tasks/TASK_543_mission_first_engagement_feedback.md`
- `docs/tasks/TASK_546_mission_combat_feedback_hud_density.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- Ohne gruenen TASK_775-Interaction-Feel blockiert der Contact-Pressure-Pass.
- Contact-Report ist sichtbar und enthaelt Typ/Text, ungefaehre Position, Confidence und Alter.
- Threat-/Risk-Preview nennt `safe`, `risky`, `suicidal` oder erklaertes `unknown` plus Exposure-/LOS-Grund.
- Pressure-/Engagement-Feedback nennt Fire/Wait/No-Fire/Contact oder einen Blockgrund.
- Kompakte HUD-Zeile enthaelt Contact/Risk sowie LOS/Cover-Kontext.
- Der Snapshot bleibt read-only, setzt keine Gameplay-Wahrheit und erzeugt keine Commands, Navigation oder FireEvents.
- Bei gruenen Gates meldet der Snapshot `ready_for_contact_pressure_playtest`.

## Betroffene Dateien
- `scripts/mission/station_reentry_contact_pressure_feel_pass.gd`
- `scripts/tests/task_776_station_reentry_contact_pressure_feel_pass.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_776_station_reentry_contact_pressure_feel_pass.gd`
- Regression: TASK_775
- `git diff --check`

## Risiken / offene Punkte
TASK_776 beweist die Lesbarkeit von Kontakt- und Drucksignalen, aber noch nicht die Qualitaet der eigentlichen Kampfauflösung. Danach ist TASK_777 als Firefight-/Combat-Resolution-Feel-Pass sinnvoll.
