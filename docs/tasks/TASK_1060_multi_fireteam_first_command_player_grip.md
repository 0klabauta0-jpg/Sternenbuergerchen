# TASK_1060 - Multi-Fireteam First Command Player Grip

## Ziel / Problem

Nach der belegten Landung und dem ersten Kontakt von zwei Fireteams muss der
naechste Spielergriff eindeutig bleiben: Beide Teams lassen sich gemeinsam
auswaehlen, erhalten jeweils einen Move-Preview und starten erst mit dem
bestehenden `GO`-Befehl. Ihre getrennten Contact-Reports duerfen dabei nicht
verloren gehen oder auf ein Team zusammenschrumpfen.

## Ursache / Sinnhaftigkeit

TASK_1059 beweist Runtime-Aktivierung und ContactTracker-Daten fuer `ft1` und
`ft2`. Die bisherigen First-Move- und First-Contact-Verifier pruefen jedoch
hauptsaechlich einen einzelnen ausgewaehlten Fireteam-Pfad. Gerade nach zwei
parallel gelandeten Dropships ist die gemeinsame Auswahl mit getrennten
Preview- und Contact-Kontexten der erste echte Commander-Griff.

## Umfang

- Kontrollierte Homebase -> zwei Dropships -> zwei LZs -> Deboarding ->
  bestaetigte Kontakte fuer `ft1` und `ft2` wiederverwenden.
- Beide Fireteams gemeinsam auswaehlen und mit einem bestehenden
  Right-Click-Move-Pfad planen.
- Pro Fireteam einen read-only Waypoint-/Threat-Preview vor `GO` nachweisen.
- Mit dem vorhandenen `execute_selected_fireteam_orders()` ausfuehren und
  getrennte aktive oder nachvollziehbar abgeschlossene Ausfuehrung pruefen.
- ContactTracker-/Overlay-Snapshots nach `GO` weiter fuer beide Teams lesbar
  halten.

## Nicht-Ziele

- Kein neuer Command-Button und keine neue UI-Gameplay-Wahrheit.
- Kein Combat-, Pathfinding- oder Local-Avoidance-Rewrite.
- Kein manueller F6-Sichttest; der Nutzer hat den Sichttest fuer diesen Stand
  bewusst uebersprungen.
- Kein Multiplayer-Resync; Daten bleiben fireteam- und ownership-neutral.

## Relevante Contracts

- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/contact_report_contract.md`
- `docs/dev/combat_loop_authority_contract.md`
- `docs/dev/homebase_direct_dropship_flow_contract.md`
- `docs/tasks/TASK_1059_multi_fireteam_first_contact_runtime_trace.md`

## Akzeptanzkriterien

- `ft1` und `ft2` sind gleichzeitig ausgewahlt, runtime-aktiv und besitzen
  jeweils einen bestaetigten, lesbaren Contact-Report.
- Ein gemeinsamer Move erzeugt je einen Pending-Preview-Eintrag fuer `ft1`
  und `ft2`, jeweils mit Ghost, Pfad und gueltigem Risk-State.
- Vor `GO` wurde kein Move-Command ausgefuehrt.
- `GO` nutzt nur den bestehenden Command-/Simulation-Pfad und startet oder
  dokumentiert fuer beide Teams den Bewegungszustand.
- Nach `GO` bleiben die Contact-Snapshots pro Fireteam getrennt lesbar.
- Die Mehr-Dropship- und HUD-Regressionen bleiben gruen.

## Betroffene Dateien

- Neuer Verifier unter `scripts/tests/`.
- `scripts/tests/mission_tactical_sandbox_controller.gd` nur, wenn die
  vorhandenen read-only Snapshots keinen Multi-Fireteam-Payload liefern.
- Diese Task-Datei sowie Status-, Roadmap- und Zwischenbericht-Dateien.

## Lokale Pruefung

- Neuer TASK_1060-Verifier.
- `task_1059_multi_fireteam_first_contact_runtime_trace.gd`.
- `task_396_mission_dropship_lz_drop_hotfix.gd`.
- `task_503_mission_dropship_fireteam_hud_truth.gd`.
- `git diff --check`.

## Risiken / offene Punkte

Die zwei Teams koennen unterschiedliche Pfade, Distanzen und Risk-States
haben. Der Verifier darf deshalb weder nur den ersten Preview-Eintrag noch
eine zusammengefasste Kontaktliste als ausreichend bewerten. Der bestehende
Controller ist gross; der Slice muss sich auf einen kleinen read-only
Snapshot-Helfer beschraenken, falls eine Luecke besteht.

## Ergebnis

- TASK_1060 prueft 14/14 den echten Alpha-/Beta-Pfad bis zum ersten
  gemeinsamen Move und `GO`.
- Vor `GO` besitzt jedes Team einen eigenen Ghost-/Pfad-/Risk-Preview sowie
  seinen separaten bestaetigten Contact-Report.
- Nach `GO` gehen keine Plaene verloren: Der bestehende
  CoordinationManager macht bei derselben Bewegungsphase bewusst einen
  Fireteam-Vorstoss mit Partner-Deckung. Der neue read-only Snapshot und die
  bestehende Mini-Card-Koordination machen beide Rollen lesbar.
- Der neue Snapshot setzt weder Commands noch Contact-, Movement- oder
  Multiplayer-Wahrheit.
