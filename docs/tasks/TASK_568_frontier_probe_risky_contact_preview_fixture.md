# TASK_568 - Frontier Probe Risky Contact Preview Fixture

## Ziel / Problem
TASK_567 macht Risiko im First-Move-HUD sichtbar, aber der echte Frontier-Probe-Flow zeigt vor Sichtkontakt bewusst `unknown`. Es fehlt eine kleine reproduzierbare Kontaktlage, in der dieselbe Move-Preview belegbar `RISKY` und `SUICIDAL` meldet.

## Sinnhaftigkeit / Ursache
Taktische Lesbarkeit wird erst spielbar, wenn der Spieler nicht nur "keine Intel" sieht, sondern bei bekannten Feinden auch versteht, warum ein Move riskant oder schlecht ist. Der ThreatAnalyzer kann diese Bewertung bereits; TASK_568 verbindet ihn mit echten ContactTracker-Daten im Mission-Fixture.

## Umfang
- Frontier-Probe-Mission-Fixture mit ausgewaehltem Alpha/Blue-Fireteam aufbauen.
- Gegnerpositionen so setzen, dass der ContactTracker echte Kontakte fuer das Fireteam liefert.
- Einen Move gegen einen Kontakt als `risky` pruefen.
- Einen Move gegen drei klare Kontakte als `suicidal` pruefen.
- HUD-/Order-Text, Preview-Line-Entries und Primary3D-Threat-Line-Zaehler pruefen.
- HTML-Zwischenbericht, Status, Roadmap und Mission-Feedback-Contract auf TASK_568 weiterziehen.

## Nicht-Ziele
- Kein neues Contact-System.
- Kein perfektes Gegnerwissen ohne ContactTracker.
- Kein GO/Combat-Commit.
- Kein Visual-Redesign der Threat-Linien.
- Kein Fix fuer die separate TASK_540-Meta-Homebase-Testhygiene.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_506_tactical_decision_clarity_contract.md`
- `docs/tasks/TASK_567_frontier_probe_first_move_threat_preview_readability_pass.md`

## Akzeptanzkriterien
- Die Risky-Fixture erzeugt mindestens einen echten ContactTracker-Kontakt fuer das selektierte Fireteam.
- Die Move-Preview meldet `risky`, nennt mindestens eine Enemy-Exposure und zeigt `RISKY` im Order-Text.
- Die Suicidal-Fixture erzeugt mindestens drei klare Enemy-Lines fuer dieselbe Move-Preview.
- Die Move-Preview meldet `suicidal`, nennt mindestens drei Enemy-Exposures und zeigt `SUICIDAL` im Order-Text.
- Primary3D meldet Threat-Line-Zaehler passend zu den Preview-Line-Entries.
- Alle Snapshots bleiben read-only und fuehren keinen Befehl aus.

## Betroffene Dateien
- `scripts/tests/task_568_frontier_probe_risky_contact_preview_fixture.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_568_frontier_probe_risky_contact_preview_fixture.gd` (28 passed, 0 failed)
- `godot_console.exe --headless --path . --script scripts/tests/task_567_frontier_probe_first_move_threat_preview_readability_pass.gd` (32 passed, 0 failed)
- `godot_console.exe --headless --path . --script scripts/tests/task_506_tactical_decision_clarity_contract.gd` (24 passed, 0 failed)
- `git diff --check` (Exit 0)

## Risiken / offene Punkte
- Die Fixture belegt Contact-getriebene Risikoentscheidungen, ersetzt aber noch keinen manuellen F6-Sichttest, ob die Linien/Farben im echten Blick angenehm genug sind.
- Als naechster Slice bietet sich ein Visual-/Manual-Review fuer Threat-Linien und Risk-Labels an.
