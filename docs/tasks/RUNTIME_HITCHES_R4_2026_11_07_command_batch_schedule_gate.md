# R4: Command-HUD-Nachbar an verteilten Scheduler binden

## Problem und Ursache
Der bestehende `continue_20261105_command_hud_batch_verifier.gd` erwartet
nach einem direkten Controller-`_process` den gesamten schweren HUD-Burst.
Die R4-Architekturaenderung ersetzt genau diesen periodischen Burst durch
vier UpdateManager-Jobs. Der frische unveraenderte Nachbartest liefert
39/4: sofortige Commands, GO/Physics, Transport-Force und Details bestehen;
die vier Fehler betreffen den alten synchronen Flush-/Guard-/Kartenzeitpunkt.
Originalquelle und roter Lauf bleiben erhalten. Kein Produktfix aus diesem
Testfehler ohne weiteren Befund.

## Ziel, Umfang und Akzeptanz
Nur den Schedulingteil dieses Nachbarverifiers aktualisieren. Alle bisherigen
43 Gameplay-/Feedback-/Force-/Karten-/Detailspruefungen inhaltlich behalten.
Nach Heavy-Due zuerst keinen schweren synchronen Durchlauf erwarten, dann
alle vier echten Managerphasen innerhalb vier unterschiedlicher Renderframes
bedienen. Anschliessend unveraendert Craft-/Cards-Force, committed Move,
sichtbare aktuelle Karte und versteckte Memberidentitaeten pruefen. Auch den
ungezwungenen periodischen Durchlauf vor seiner Skippruefung real drainen.
Keine Sleeps oder weicheren State-/Force-/Zaehler-/Commanderwartungen.

## Grenzen, Dateien und Pruefung
Task, genannter Verifier; Produkt, Cadence, Manager-Core, Runtime-Actors,
HP/Positionen/Timer und Commandautoritaet bleiben unveraendert. Controller
und Manager-Autoscheduling duerfen fuer diesen synthetischen Komponenten-
test angehalten werden; reale Simulation/Commands bleiben aktiv. Direkte
Managerdrains sind keine native FPS-/Bewegungsabnahme. Root ist einziger
Engine-/Gitrunner. Neuer GREEN und unabhängiges Diffreview erforderlich.

AGENTS, ARCHITECTURE, mission_hud_projection_authority_contract und
`RUNTIME_HITCHES_R4_2026_11_07_periodic_hud_queue.md` gelten. Der historische
R3-PASS wird nicht umgeschrieben; der neue Test belegt den neuen Scheduler.

## Gebundener Befund und Schedulingmigration
Root-Lauf `final_regression_matrix/20261107T110517Z-78f3a92e` bestaetigt39/4.
Alle vier roten Assertions lesen Flush-/Craft-/Cards-/Guardzaehler unmittelbar
nach dem direkten `_process`, noch vor einem Manager-/Renderframe. Sofortige
Commands, echter Physicscommit, interleaved Transportforce und Details sind
gruen. Das ist eine ueberholte Schedulingoracle, kein neuer Produktbefund.

Der aktualisierte Verifier behaelt alle43 bisherigen fachlichen Assertions
und fuegt nur die neue Request-/Drain-Grenze hinzu. Nach Heavy-Due wird zuerst
kein synchroner Durchlauf und vier pending Keys verlangt; danach bedient der
echte Manager-HUDbatch je neuem Renderframe hoechstens den vorhandenen Job.
Nach maximal vier Frames folgen die bisherigen strikten Apply-/Skip-/Move-/
Karten-/Identitaetsassertions. Der unforced periodische Guard wird ebenfalls
erst nach vier realen Phasen beurteilt. Controller und Managerautoablauf sind
nur fuer dieses Komponentenfixture aus; Simulation und Commands bleiben live.
Neue GREEN-/Sourcepruefung durch Root PENDING; Originalquelle/RED unveraendert.

Root-GREEN48/0, errors0/stabile Quellen: `command_batch_schedule_green/20261107T111155Z-1915a15f`; unabhaengiges Diffreview APPROVED scoped in `docs/reviews/RUNTIME_HITCHES_R4_2026_11_07_command_review.md`.
