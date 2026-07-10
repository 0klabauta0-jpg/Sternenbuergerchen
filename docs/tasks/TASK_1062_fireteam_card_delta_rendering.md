# TASK_1062 - Fireteam Card Delta Rendering

## Ziel / Problem

Der Multi-Fireteam-Runtime-Trace aus TASK_1061 misst weiterhin nennenswerte
Kosten im Fireteam-Card-Bereich. Die Mini-Karten werden zwar bei identischem
Runtime-Signature-Snapshot korrekt uebersprungen, konfigurieren bei einer
legitimen Live-Aenderung jedoch erneut ihren vollstaendigen statischen
Kartenaufbau. Das betrifft besonders Suppression, Contact, Bewegung und
Koordination, die haeufig aktualisieren duerfen.

## Ursache

`_refresh_fireteam_mini_cards()` ruft bei jeder geaenderten Runtime-Signatur
`FOBFireteamCard.setup_card()` auf. Diese Methode setzt auch unveraenderliche
Identitaets-, Dichte- und Style-Werte neu. Die Karte wird nicht ersetzt, aber
der statische Aufbau wird unnoetig erneut konfiguriert.

## Umfang

- Die Mini-Card trennt statische Referenzdaten von dynamischem Runtime-Status.
- Statisch sind Fireteam-ID, Anzeigename, Loadout, Lead-Zusammenfassung und
  Mini-Card-Kontext.
- Dynamisch bleiben Auswahl, Aktivitaet, Suppression, Contact, Bewegung,
  Koordination, Readiness, Member-Status und Stance.
- Ein read-only Diagnose-Snapshot misst statische Apply-/Skip- sowie
  Runtime-Status-Apply-Zaehler.
- Portraet-Controls duerfen nur bei geaenderter Identitaet neu befuellt
  werden, nicht bei blossen Live-Status-Aenderungen.

## Nicht-Ziele

- Keine Aenderung an `SimulationRoot`, Command-Queue, Combat oder
  Multiplayer-Ownership.
- Kein Verstecken von Suppression, Contact, Coordination oder Lead-Text, nur
  weil eine Karte nicht statisch neu konfiguriert wird.
- Kein kompletter Austausch des historisch gewachsenen Mission-Controllers.

## Relevante Contracts / Dokumente

- `docs/ARCHITECTURE.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_1061_multi_fireteam_mission_runtime_budget.md`
- `docs/tasks/TASK_1044_mission_hud_runtime_surface_guard.md`

## Akzeptanzkriterien

- Eine reine Suppression-Aenderung aktualisiert sichtbaren Status und Balken.
- Dabei bleibt die statische Mini-Card-Konfiguration fuer dasselbe Fireteam
  aus; Karten-, Titel- und Leader-Portraet-Nodes bleiben erhalten.
- Ein echter Referenzwechsel, etwa Loadout oder Lead-Zusammenfassung, richtet
  die statische Karte erneut ein.
- Der neue Diagnose-Snapshot ist read-only und besitzt keine Gameplay-Wahrheit.
- TASK_1044, TASK_1061, TASK_1060, TASK_1059, TASK_396 und TASK_503 bleiben
  gruen.

## Betroffene Dateien

- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1062_fireteam_card_delta_rendering.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_task1057_1058_2026_07_10.html`

## Lokale Pruefung

- TASK_1062 Red/Green-Verifier.
- Bestehende HUD-/Multi-Fireteam-/Dropship-Regressionen.
- `git diff --check`.

## Risiken / offene Punkte

- Statische Signaturen muessen auch echte Lead-, Label-, Loadout- und
  Mitgliedschaftsaenderungen erkennen.
- Der Task reduziert vermeidbare Kartenarbeit; die verbleibende Headless-Zeit
  ist weiterhin kein FPS-Versprechen.
