# TASK_1192 - Release First Exchange Fixture Isolation

## Status: IMPLEMENTIERT

## Ziel / Problem

Der Release-Direkteinstieg fuer den ersten Feuerwechsel enthielt bisher einen
synthetischen Testaufbau im normalen `MetaLayerFlow`: Gegner wurden versetzt,
Kontaktfortschritt und Combat-Ticks wurden direkt geschrieben und ein privater
Attack-Helper wurde aufgerufen. Das verschleiert die Grenze zwischen normalem
Spielablauf und reproduzierbarer Testinszenierung.

## Umfang

- Die ausschliesslich fuer den Release-Test benoetigte Inszenierung liegt in
  `scripts/tests/release_first_exchange_fixture.gd`.
- Der Meta-Flow aktiviert sie nur bei dem bestehenden expliziten
  `--release-singleplayer-first-go-firefight`-Argument und dokumentiert das
  Ergebnis mit `synthetic_fixture=true`.
- Der normale Meta-Flow besitzt keine Teleport-, private Tick-, Detection- oder
  Attack-Ausloese-Logik mehr.
- TASK_284 prueft die enge Deeplink-Funktion gegen einen bewusst injizierten
  Verstoss; der Check durchsucht nicht pauschal alle Meta-Tokens.

## Nicht-Ziele

- Kein Redesign des First-Contact-/First-Fire-Spielablaufs.
- Keine Aenderung an Combat-Regeln, Schaden, Zielwahl, ROE oder Multiplayer.
- Kein Anspruch, die synthetische Fixture als echtes Spielerlebnis zu werten.

## Akzeptanzkriterien

- Fixture, Meta-Delegation und Evidenz sind statisch und durch einen fokussierten
  Verifier nachweisbar.
- Die Fixture kennzeichnet jedes Ergebnis explizit als synthetisch.
- TASK_284 erkennt einen injizierten direkten Gameplay-Eingriff innerhalb der
  Deeplink-Funktion.
- Bestehende TASK_832-/TASK_868-Evidenz bleibt als Test- bzw. Snapshot-Evidenz
  lesbar.

## Lokale Pruefung

- `scripts/tests/task_1192_release_first_exchange_fixture.gd`
- `scripts/tests/task_284_gameplay_truth_architecture_boundary_audit.gd`
- `scripts/tests/task_832_release_first_go_firefight_deeplink_evidence.gd`
- `scripts/tests/task_868_release_first_exchange_los_setup_polish.gd`
- `git diff --check`

## Ergebnis

- `MetaLayerFlow` delegiert den bestehenden, explizit per Launch-Argument
  angeforderten Release-Aufbau an die Test-Fixture. Der normale Deeplink-Body
  enthaelt keine Teleport- oder privaten Combat-Driver-Eingriffe mehr.
- Jede Fixture-Evidenz und jeder Deeplink-Snapshot weist
  `synthetic_fixture=true` aus. Die vorhandenen Snapshot-Contracts bleiben
  read-only und sind damit nicht mit einem normalen Spielerpfad zu verwechseln.
- TASK_1192 ist 10/10, TASK_284 66/66, TASK_832 40/40 und TASK_868 44/44
  gruen. Der neue Worktree benoetigte fuer den Lauf lediglich die lokalen,
  ignorierten Godot-Importartefakte; es wurden keine Assets kopiert oder
  versioniert.
