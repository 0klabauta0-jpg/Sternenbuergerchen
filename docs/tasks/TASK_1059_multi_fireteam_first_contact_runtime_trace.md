# TASK_1059 - Multi-Fireteam First Contact Runtime Trace

## Ziel / Problem

Nach dem verifizierten Deboarding von zwei Direct-Dropships muss der erste Kontakt auf echten Runtime-Units funktionieren: Beide Fireteams sind in Combat-/Unit-Registry sichtbar, mindestens ein gueltiger LOS-Kontakt wird bestaetigt und der Contact-Overlay-/Feedback-Pfad bleibt lesbar.

## Ursache / Sinnhaftigkeit

TASK_1052 bis TASK_1054 fanden vor der spaeter geklaerten Transferankunft keine deployed Combat-Friendlies. TASK_1057 beweist inzwischen das Deboarding beider Teams. Der alte First-Contact-Befund muss daher gegen den aktuellen, echten Mehr-Fireteam-Pfad neu erhoben werden.

## Umfang

- Reproduzierbare Homebase -> zwei Dropships -> zwei LZs -> Deboarding -> LOS-Kontakt-Fixture.
- Nachweis fuer ft1 und ft2: Runtime-Aktivierung, Combat-Registry und eindeutige Unit-/Fireteam-Paare.
- Mindestens ein bestaetigter Contact-Report/Overlay-Kontext aus dem bestehenden Combat-Pfad.
- Read-only Trace-/Snapshot-Daten fuer Timing und Fehlerdiagnose.

## Nicht-Ziele

- Kein Combat-Rewrite und keine neue Enemy-AI.
- Keine neue UI-Wahrheit oder Contact-Schattenkopie.
- Kein Multiplayer-Resync in diesem Slice; die Datenform bleibt jedoch ownership-neutral.

## Relevante Contracts

- `docs/dev/homebase_direct_dropship_flow_contract.md`
- `docs/dev/combat_loop_authority_contract.md`
- `docs/dev/contact_report_contract.md`
- `docs/tasks/TASK_1057_controlled_dropship_inbound_to_deboard_trace.md`

## Akzeptanzkriterien

- Beide Teams besitzen nach Deboarding aktive Runtime-Units in Unit- und Combat-Registry.
- ft1 und ft2 behalten getrennte Unit-IDs und Fireteam-IDs.
- Eine kontrollierte, gueltige LOS-Position erzeugt bestaetigten Kontakt im bestehenden Contact-Pfad.
- Kontakt-Feedback unterscheidet sichtbaren Kontakt von fehlendem/ueberholtem Kontakt.
- Die bestehende Dropship- und HUD-Regressionsmatrix bleibt gruen.

## Ergebnis

- TASK_1059 prueft 10/10 den echten Homebase-zu-Mission-Pfad mit Alpha und Beta.
- Nach getrenntem Deboarding sind `unit_alpha`/`unit_bravo` als `ft1` und `unit_charlie`/`unit_delta` als `ft2` in der Combat-Registry vorhanden und beide Fireteams runtime-aktiv.
- Fuer jedes Fireteam findet die Fixture eine Terrain-gueltige LOS-Position. Beide erzeugen bestaetigte ContactTracker-Reports; der Multi-Fireteam-First-Contact-Snapshot bleibt read-only.
- Damit ist der historische First-Contact-Befund aus TASK_1052 bis TASK_1054 als durch die inzwischen korrigierte Transport-/Activation-Kette ueberholt dokumentiert.

## Betroffene Dateien

- Neuer Verifier unter `scripts/tests/`
- Bestehende Mission-/Combat-Skripte nur, falls der Trace eine reale Runtime-Grenze belegt
- diese Task-Datei sowie Status-/Roadmap-Dokumente

## Lokale Pruefung

- Neuer TASK_1059-Verifier
- `task_396_mission_dropship_lz_drop_hotfix.gd`
- `task_503_mission_dropship_fireteam_hud_truth.gd`
- `bugfix_mission_multi_dropship_cards.gd`
- `git diff --check`

## Risiken / offene Punkte

Der bestehende First-Contact-Trace umfasst bewusste Timing-Gates. Der neue Verifier darf keine globale Missionszeit oder Frames kuenstlich ueberspringen; nur die bekannten, kontrollierten Dropship-Sequenzen duerfen testseitig fortgeschrieben werden.
