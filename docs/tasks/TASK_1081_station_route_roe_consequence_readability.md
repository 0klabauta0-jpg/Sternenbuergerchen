# TASK_1081 - Station Route ROE Consequence Readability

## Ziel / Problem

TASK_1080 stellt sicher, dass eine neue Fire-Rule sofort bis in laufende
Unit-Commands propagiert. Im sichtbaren Commander-HUD steht bisher aber nur
`ROE HF`, `ROE RF` oder `ROE FW`. Der Spieler erkennt dadurch nicht unmittelbar,
ob Feuer blockiert ist, auf Beschuss gewartet wird oder ein Kontakt aktiv
bekaempft werden darf.

## Sinnhaftigkeit / Ursache

Die Runtime-Daten sind bereits vorhanden: ausgewaehlte Fire-Rule, aktuelle
Unit-Commands, Return-Fire-Fenster, Contact-Entscheidung sowie LOS-/Range-/Cover-
und Friendly-Fire-Kontext. Sie werden nur noch nicht als eine gemeinsame,
kurze Konsequenz zusammengefasst.

## Umfang

- Einen kleinen read-only `FireRuleConsequenceReadability`-Resolver anlegen.
- Konsequenzzustaende fuer Hold, Return, Free, Suppress und gemischte Auswahl
  liefern.
- Runtime-Konsistenz zwischen Controller-Regel und aktiven Unit-Commands
  diagnostizieren.
- Die vorhandene einzeilige Mission-Control-`ACT`-Anzeige um einen kompakten
  Konsequenz-Token erweitern.
- Bestehenden Contact-Kontext fuer LOS, Range, Cover und Friendly Fire
  wiederverwenden.

## Nicht-Ziele

- Keine neue Combat-, Treffer-, Return-Fire- oder Friendly-Fire-Regel.
- Kein neues Panel und kein Tutorialfenster.
- Keine UI-seitige Gameplay-Wahrheit.
- Kein per-frame SceneTree-Vollscan oder Control-Rebuild.

## Relevante Contracts

- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_command_rules_contract.md`
- `docs/tasks/TASK_570_hold_fire_discipline_mission_bridge.md`
- `docs/tasks/TASK_1080_station_route_live_fire_rule_propagation.md`

## Akzeptanzkriterien

- Hold zeigt kompakt, dass freiwilliges Feuer blockiert ist.
- Return unterscheidet sichtbar zwischen Warten und aktivem Incoming-Fire-
  Fenster.
- Free unterscheidet Ready, Engage und Blocked anhand vorhandener Combat-Daten.
- LOS, Range, Cover und Friendly-Fire-Risiko werden nur angezeigt, wenn die
  bestehenden Combat-Snapshots diese Daten liefern. Planungsrisiken bleiben
  im vorhandenen Threat-Preview und werden nicht erneut berechnet.
- Der reale Station-Guard-Contact zeigt nach einer ROE-Aenderung denselben
  Zustand in Runtime-Commands und HUD-Konsequenz.
- Snapshot-Lesen erzeugt keine Commands, FireEvents oder Gameplay-Mutation.

## Betroffene Dateien

- `scripts/tactical/fire_rule_consequence_readability.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1081_station_route_roe_consequence_readability.gd`
- `scripts/tests/task_1080_station_route_live_fire_rule_propagation.gd`
- `scripts/tests/task_603_mission_hud_density_interaction_polish.gd`
- Task-/Status-/Roadmap-/Report-Dateien nach bestaetigtem Ergebnis

## Lokale Pruefung

- TASK_1081, TASK_1080, TASK_1079, TASK_571, TASK_570 und TASK_607.
- HTML-Script-Syntax und `git diff --check`.

## Risiken / offene Punkte

Die kompakte Anzeige darf die bestehende 180-Zeichen-Grenze der `ACT`-Zeile
nicht sprengen. Ein echter visueller Kontrasttest bleibt separat, weil dieser
Task nach User-Vorgabe keinen manuellen Sichttest erzwingt.

Der historische TASK_546-Meta-Layer-Smoke benoetigt lokal rund 343 Sekunden.
Das ist Testinfrastruktur-Laufzeit und kein Beleg fuer die Spiel-Framerate;
ein spaeterer Fixture-Extraction-Task sollte diesen Pfad gezielt kuerzen.

## Ergebnis

Implementiert. TASK_1081 ist 33/33 gruen. Die vorhandene Mission-Control-
`ACT`-Zeile zeigt jetzt `HF HOLD`, `RF WAIT`, `RF RETURN`, `FW READY`,
`FW ENGAGE`, `FW BLOCK`, `SUP READY` oder `MIX`. Der Resolver liest nur
Fire-Rule, aktive Unit-Commands, Return-Fire-Fenster und aktuelle
Combat-Diagnostics. Planungs-FF bleibt im bestehenden Threat-Preview und wird
nicht doppelt berechnet. Der reale Guard-Trace ist 22/22 gruen und belegt,
dass Runtime-Command und sichtbare Konsequenz nach RF/FW uebereinstimmen.

Zusaetzlich akzeptieren die aelteren TASK_546-/TASK_603-Readability-Gates den
spaeter eingefuehrten `CONTACT FIRE`-Fokus, ohne die darunterliegenden
Objective-, Cargo- oder Combat-Snapshots zu verlieren. Explizite
Command-Feedback-Overrides werden nicht mehr mit Live-Szenentext ueberschrieben.
