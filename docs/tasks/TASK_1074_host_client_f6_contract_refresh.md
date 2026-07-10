# TASK_1074 - Host Client F6 Contract Refresh

## Ziel / Problem

Der echte TASK-607-Zwei-Instanz-Smoke verbindet lokale ENet-Verbindung,
Host-Authority, Command-Validierung und Client-Snapshot erfolgreich. Beide
Instanzen verlieren jedoch den read-only F6-Lesbarkeits-Gate: die kompakte
ACT-Zeile und die deduplizierte Selected-Fireteam-Anzeige werden nicht mehr
als bestanden bewertet.

## Ursache / Sinnhaftigkeit

Seit dem Station-Route-/Release-HUD-Polish stammen ACT- und
Selected-Fireteam-Texte aus weiterentwickelten Presentern. Im aktiven
Feuerkontakt hingen alte Presenter den vollstaendigen Status erneut hinter
`CONTACT FIRE` und `NEXT`, waehrend der F6-Inspector seine Combat-Dichte zu
einem anderen Zeitpunkt las. Dadurch war die sichtbare Anzeige kompakt, der
read-only Snapshot aber nicht konsistent. Vor einem echten Mehrspieler-
Spielzug muss dieselbe Lesbarkeit auf Host und Client wieder nachweisbar sein.

## Umfang

- Firefight-Fokus auf genau zwei sichtbare Zeilen begrenzen: `CONTACT FIRE`
  und die kompakte `NEXT ... | WHY ...`-Entscheidung.
- Die volle ACT-/Objective-/Cargo-/ROE-Quelle weiter read-only exportieren,
  ohne sie im aktiven Feuerkontakt in die Primaerzeile zu druecken.
- Den gemeinsamen read-only F6-Contract auf denselben sichtbaren
  Presentation-Mode ausrichten.
- Die realen ENet-, Command- und Snapshot-Grenzen unveraendert lassen.
- TASK-607 nach dem Fix mit Host und Client vollstaendig gruen pruefen.

## Nicht-Ziele

- Kein neues Netzwerkprotokoll und keine neue RPC-Route.
- Kein Mission-, Combat-, Objective- oder Command-Rewrite.
- Kein sichtbarer Style-Umbau ohne belegten Fensterbefund.

## Relevante Contracts / Dokumente

- `docs/dev/mission_command_feedback_contract.md`
- `scripts/tests/task_607_two_instance_host_client_runtime_smoke.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- TASK_604, TASK_606, TASK_607, TASK_817

## Akzeptanzkriterien

- Host und Client bestehen im realen Zwei-Instanz-Smoke denselben F6-Gate.
- ACT-Zeile bleibt kompakt und der Selected-Fireteam-Kontext dedupliziert.
- Aktiver Feuerkontakt zeigt auf beiden Seiten dieselbe `CONTACT FIRE`- und
  `NEXT`-Prioritaet ohne alte Statusanhaenge.
- Snapshot-Lesen enqueued weiterhin keine Commands und setzt keine
  Gameplay-Wahrheit.

## Betroffene Dateien

- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_607_two_instance_host_client_runtime_smoke.gd`
- `scripts/tests/task_604_core_loop_host_client_feel_smoke.gd`
- `scripts/tests/task_606_host_client_f6_visual_polish_findings.gd`
- `scripts/tests/task_817_station_reentry_release_candidate_targeted_firefight_polish.gd`
- `scripts/tests/task_833_release_firefight_hud_readability_polish.gd`
- Task-/Contract-/Status-/Roadmap-/HTML-Report-Dateien

## Lokale Pruefung

- TASK_607 41/41, TASK_604 28/28, TASK_606 39/39, TASK_817 34/34,
  TASK_833 23/23, TASK_169 15/15, lokaler ENet-Smoketest 3/3 und
  `git diff --check`.

## Risiken / offene Punkte

Der Task beweist den technischen Host/Client-Readout. Ein menschlicher
Zwei-Fenster-Sichtentscheid und Missionsbalance bleiben bewusst getrennt.
Der Large-Map-Performance-Smoke hielt Streaming und Renderbudget ein, meldete
am Missionsende aber `unit_status_badge_count = 0`; dieser unabhaengige
Badge-Visual-Befund bleibt ein eigener Folge-Task.
