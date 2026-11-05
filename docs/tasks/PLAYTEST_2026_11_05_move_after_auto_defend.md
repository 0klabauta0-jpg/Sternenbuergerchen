# Playtest 2026-11-05: Move nach Auto DEF wieder aufnehmen

## Ziel und belegtes Problem

Der normale Vollbildlauf muss nach einem abgeschlossenen Move und dessen
automatischer DEF-360-Sicherung erneut Move + GO mit denselben Units ausfuehren.
Die Motionprobe `motion_trace/20261105T080031Z-13cf75d8/motion_motion.json`
belegt: Spieler 01 bewegt sich zuletzt bei 34,900542 s, 02 bei 31,166559 s,
03 bei 28,152723 s. Danach bleiben alle Positionen bis 49,809523 s exakt gleich.
Bei 34,901 s ist wp_0003 regulaer abgeschlossen, Execution und Plan sind leer,
alle drei Units sind fit und halten mit `source_task_type=auto_defend`.
GO bei 36 s aktiviert wp_0004 mit neuen Movementtargets; die Runtimecommands
bleiben aber Auto DEF. GO bei 48 s fuegt wp_0005 pending hinzu.

## Ursache und enger Umfang

`SimulationRoot._apply_unit_command_status` merkt sich bisher nur nichtleere
committed Tokens. Der autoritativ ueber die gleiche Simulation angenommene
untokenisierte Hold laesst deshalb den vorherigen Move-Token als committed
stehen. `_is_stale_tokenized_move_command` verwirft anschliessend den frisch
eingereihten Move, weil der aktuelle Hold-Token leer ist und vom alten
committed Token abweicht. Der Plan wurde bereits als aktiv markiert.

Geplanter Fixscope: Commandcommit und Stale-Token-Pruefung in SimulationRoot.
Keine Aenderung von Gameplayregeln, Formation, Wegfindung, Timer, Actorpositionen,
HP, Tickrate, UI- oder Plan-Ausfuehrungslogik. Keine unbegrenzte Tokenhistorie.
Autoritative leere Token muessen explizit von unbekanntem Commit unterscheidbar
sein; vor dem Hold eingereihte alte Moves muessen verworfen bleiben.

## Relevante Vertraege

- AGENTS.md; PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/tasks/PLAYTEST_2026_11_05_performance.md`
- TASK_501 Movement Command Lifecycle; TASK_462 /463 Auto DEF Completion

## Akzeptanz

1. Zwei frische TestUnit-Nodes starten ueber SimulationRoot aus initialem
   untokenisiertem Hold ohne vorherigen Move-Commit physisch. Der normale
   Post-Drop-Pfad hat dagegen tokenisierte `post_drop_security`-Commands und
   wird im nativen Test als solcher dokumentiert, nicht als leerer Erst-Hold.
2. Der erste Move endet durch echte 1x-Simulation von selbst in Auto DEF.
3. Ein neuer normaler Move + GO ersetzt den Hold mit frischem Token und bewegt
   jede gleiche Unit um mehr als zwei Welt-Einheiten; kein stale Discard dafuer.
4. Alte abgeschlossene Move-Tokens bleiben nach Hold und nach Folge-Move stale.
5. Unbekannte/extern ersetzte Token sowie abgemeldete Units bleiben geschuetzt;
   vorhandener TASK_501 bleibt unveraendert gruen.
6. Nativer Lauf bestaetigt Vollbild und aktive Displayaufloesung; keine Actor-,
   HP-, Timer-, Phasen- oder Geschwindigkeits-Patches zum Erzeugen eines PASS.

## Dateien und lokale Pruefung

- Neu: `scripts/tests/playtest_20261105_move_after_autodefend_verifier.gd`
- Neu: `scripts/tests/playtest_20261105_empty_token_commit_verifier.gd`
- Geplanter Produktfix: `scripts/core/simulation_root.gd`, nur Commit/Tokenpfad
- Bestehende Normalroute und privater Namespace-Guard werden unveraendert geerbt.

Root fuehrt zuerst native RED, danach den gezielten Fix und denselben GREEN
seriell aus. Marker: `PLAYTEST_MOVE_AUTODEFEND_DONE`. Namespace-Endkomponente:
`SternenBuergerchen_UI_Zielbild_Normal_QA`, frischer privater Parent.
Die getrennte kurze Erst-Hold-/Queued-Requeue-Probe laeuft headless mit
echten unveraenderten Physicsframes; Marker `PLAYTEST_EMPTY_TOKEN_COMMIT_DONE`.
Nachbarn: TASK_501 und TASK_468 Command Conflict; danach erneute echte
90-s-Motion-/Performanceprobe mit andauernder, belegter Bewegung.

## Risiken und offene Punkte

Leere Tokens einfach zu loeschen kann alte queued Moves wiederbeleben. Der Fix
muss neue autoritativ eingereihte Tokens zulassen und vor dem Hold vorhandene
Requeues entwerten. Die hohen spaeten FPS des bisherigen 90-s-Laufs beschreiben
den belegten Stillstand und sind kein allgemeiner Bewegungs-Performancebeleg.

## Native RED

`move_autodefend_red/20261105T081450Z-d98fbb50/` belegt sieben echte Folgefehler:
alle drei neuen Move-Tokens werden nicht committed, alle drei Units bleiben
nach GO exakt auf derselben Position, stale Discards steigen von 2 auf 215.
`last_discard` nennt den neuen `ft1_2`-Token mit `stale_command_token`.
Weitere fuenf RED-Asserts beruhten auf meiner falschen Annahme, der Post-Drop-
Security-Pfad sei untokenisiert; die Rohdaten zeigen dort tokenisierte
`post_drop_security`-Befehle. Diese Praemisse wurde im Helper korrigiert und der
geforderte leere Erst-Hold als getrennte kurze Zwei-Unit-Probe hinzugefuegt.
