# Fortsetzung 2026-11-05: Alt-Gates TASK111, TASK113 und TASK468

## Ziel / Problem
Die auf Ausgangs-Main reproduzierten roten Tactical-Gates gegen die heute
geltenden Vertraege pruefen und aussagekraeftig korrigieren. Kein veraltetes
Gameplay nur fuer gruene Tests einschalten.

## Quellenbefund / Ursache
- TASK111 verlangt automatische Overwatch-Bereitschaft, identische
  Member-Richtungen und daraus Schuesse/HUD-Meta. Der neuere
  `fireteam_behavior_modes_contract.md`, Abschnitt Defense, verlangt `DEF`,
  getrennte Member-Richtungen mit Scan und explizit inaktives
  `overwatch_ready`. `FireteamSecurityController._is_overwatch_ready()`
  liefert deshalb absichtlich `false`; `defense_ready` traegt den aktuellen
  Bereitschaftszustand. Acht historische Fehlassertionen sind damit erklaert.
- TASK113 prueft die Szenen-Integration ohne Feature-Opt-in.
  `MissionCombatLoopDriver.flank_vulnerability_enabled` ist seit TASK472
  bewusst standardmaessig `false`; Resolve- und Snapshotpfade sind gegated.
  TASK472 fordert die deaktivierte Drill-Baseline ausdruecklich. Resolver-
  und Damage-Unitchecks koennen davon unabhaengig bestehen.
- TASK468 liest direkt nach `_activate_next_waypoint_for_plan()` den
  Unit-Command. `FireteamMovementController` enqueued jedoch nur; erst
  `SimulationRoot._physics_process()` drainiert und committet ihn. Auch der
  Contact-Halt wird enqueued. Der Test liest somit vor der autoritativen
  Verarbeitung. Die historische erste Fehlassertion verhindert weitere
  ueberhaupt pruefbare Assertions dieses Szenarios.

Diese Befunde sind Quellennachweise. Die neuen Laufresultate bleiben bis zu
den durch Root seriell ausgefuehrten Enginechecks offen.

## Umfang / Nicht-Ziele
Nur die drei genannten Verifier und diese Taskdatei. Keine Produktdatei,
keine Gameplayaktivierung, keine Model-/Visualaenderung. Historische Task-
und Evidenzdateien bleiben erhalten. Bestehende synthetische Testaufstellungen
sind keine nativen physischen Spielbeweise.

## Relevante Vertraege / Dokumente
- `CONTINUE_2026_11_05_command_hitches_and_legacy.md`
- `docs/dev/fireteam_behavior_modes_contract.md` (Defense und Engage-Halt)
- `docs/dev/tactical_command_rules_contract.md`
- `docs/dev/unit_facing_visual_contract.md`
- TASK111, TASK113, TASK468, TASK472, TASK436
- `docs/ARCHITECTURE.md`: SimulationRoot als Command-Mutationsstelle

## Vorgesehene Korrektur / Akzeptanz
- TASK111 prueft Defense-Bereitschaft, inaktive automatische Overwatch,
  getrennte Base-Richtungen/Scan, Defense-Szenenmetadata. Der isolierte
  Legacy-OverwatchController behaelt seine Trigger-/Cooldown-/Rangechecks
  mit ausdruecklichem synthetischem Opt-in; zusaetzlich belegt ein Check,
  dass aktuelle Defense-Snapshots keine Overwatch-Effekte ausloesen.
- TASK113 prueft zuerst, dass die Szenenbaseline deaktiviert ist und keine
  Flank-Wahrheit liefert. Nur die explizite Integrationsfixture aktiviert
  den vorhandenen Schalter, prueft danach den unveraenderten Proxyvertrag
  und deaktiviert wieder, um die leeren Snapshots nachzuweisen.
- TASK468 liest die enqueuete Stage als gezielte Stale-Requeue-Fixture.
  Contact-Halt wird erst nach echten Physics/Process-Paaren auf der Unit
  geprueft; alter Requeue darf danach Hold/Engage/Fire-at-will nicht ersetzen.
  Der bestehende Live-Feuerpfad bleibt unangetastet.

## Betroffene Dateien
- `scripts/tests/task_111_verifier.gd`
- `scripts/tests/task_113_verifier.gd`
- `scripts/tests/task_468_fireteam_engage_live_command_conflict_audit.gd`
- diese Taskdatei

## Lokale Pruefung
Root ist alleiniger Enginekoordinator und nutzt isolierte Userdaten/Overlays.
Jeweils `--headless --path <overlay> --script res://scripts/tests/<verifier>`.
Abschlussmarker aller drei: `=== RESULTS: N passed, 0 failed ===` und
`ALL TESTS PASSED`, Prozesscode 0. Gezielte Nachbarn: TASK436, TASK472,
TASK465, TASK466, TASK467 und TASK501; nur serial und nach Root-Plan.

## Risiken / offene Punkte
Bei TASK468 kann der bisherige fruehe Return weitere historische Annahmen
verdecken; echte neue Fehler werden getrennt untersucht. Die aktivierte
Flankfixture und Legacy-Overwatchfixture gelten ausschliesslich als
synthetische Compatibility-/Integrationschecks, nicht als Produktfreigabe.

## Status
Quellenaudit und vereinbarte Testaenderungen abgeschlossen; Enginepruefung
durch Root noch offen. Die drei Originalverifier liegen byteidentisch unter
`output/continue_20261105/original_tests/` (SHA256 vor Aenderung geprueft).

## Beobachteter TASK468-Nachlauf
Root-Lauf `output/continue_20261105/engage_red/20261105T141228Z-c0045148/`:
23/23 Assertions, Exit 0, Fehler 0, Isolation bestaetigt. Der Log prueft nun
tatsaechlich Stage-Queue, Physics-Commit des Contact-Halts, abweichenden
Contact-Halt-Token, unveraenderten Hold/Engage/Fire-at-will nach Stale-Requeue
und den Live-Engage-Fire-Event ohne `_try_enqueue_attacks()`-Abkuerzung.
Der vorher verdeckte Replaypfad besteht; kein Corepatch daraus erforderlich.

Verifier-SHA256:
`28cc9461f0ce897edbe7c82fe3da1873e59ec55e9d2820c4af421180bedf1862`.
Das ist ein synthetischer Drill-/Command-Integrationsbeleg und keine native
physische Gameplayabnahme. Originalroster-Hash, Laenge und Schreibzeit sind
laut Report unveraendert.

## Delegierte Command-HUD-Regression
Ergaenzter Scope: ausschliesslich neuer Verifier
`scripts/tests/continue_20261105_command_hud_batch_verifier.gd` und dieser
Auditnachtrag. Root besitzt den Controllerpatch und alle Engine-/Gitlaeufe.

Ziel: Oeffentliche Move-/GO-Aktionen sollen Plan und enqueuete Commands
sofort publizieren sowie kompakte A5-/GO-Zustaende sofort zeigen. Die teuren
HUD-Surfaces werden pro Eingabeburst einmal in der bestehenden Kadenz
nachgezogen. Eine geoeffnete oder sofort danach geoeffnete Teamdetailansicht
muss aktuelle Quellen zeigen. GO behaelt die bestehende Continue-Policy.

Akzeptanz und Pruefung:
- Echte `mission_reactivity_test.tscn` ohne Actor-, HP-, Skill- oder
  Positionswrites; Move und GO laufen synchron im selben Testframe.
- Surface-Aufrufe werden ueber vorhandene Guard-Apply-/Skipzaehler gemessen,
  nicht ueber Hardwarezeiten. Beide Eingaben erzeugen synchron keine Heavy-
  Surface-Aufrufe und hinterlassen einen pending Command-HUD-Refresh.
- Ein kontrollierter echter `_process()`-Aufruf des pausierten UI-Owners
  bis zur konfigurierten Kadenz flushes einmal den aktuellsten Zustand mit
  Force und leert pending. Keine wiederholten Forced-Rebuilds ohne Eingabe.
- Die vorhandene Kartenkadenz betraegt 350 ms, die schwere periodische
  Kadenz 1 s. Der direkte Process-Aufruf ist eine synthetische Scheduling-
  Komponentenfixture und behauptet weder physische Fortbewegung noch
  nativen 1x-Durchsatz. Der normale native Lauf bleibt Roots eigener Beleg.
- Details werden als separater Fall geoeffnet, weil sofortiges Oeffnen bei
  pending absichtlich einen vollstaendigen UI-Refresh ausloesen darf.
- Originalsource muss an den Batchingassertionen rot werden; Enginechecks
  und konkrete Resultate bleiben bis Roots seriellem Lauf offen.
