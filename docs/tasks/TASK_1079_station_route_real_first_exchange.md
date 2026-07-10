# TASK_1079 - Station Route Real First Exchange

## Ziel / Problem

TASK_1078 beweist den ersten echten Bravo-Contact erst nach dem bestaetigten
Approach-Move. Die bestehenden First-Engagement-Smokes stellen Gegner fuer
reproduzierbare Combat-Daten aber noch direkt neben ein Fireteam. Fuer die
spielbare Station Route fehlt damit der Nachweis, dass der reale Guard-Contact
selbst einen lesbaren ersten Fire-/Wait-Entscheid erzeugt.

## Umfang

- Einen Homebase -> Drop -> Deboard -> GO -> Contact -> First-Exchange-Trace
  ohne NPC-Teleport, Status-Manipulation oder erzwungenen Treffer bauen.
- Den bestehenden `get_mission_first_engagement_feedback_snapshot()` als
  read-only Quelle pruefen: Contact, Fire-/Wait-/No-Fire-Entscheid,
  Begruendung und Deckungs-/Range-/LOS-Kontext.
- LZ Evac als bestehende Ausweichentscheidung erhalten.

## Nicht-Ziele

- Kein Combat-, Damage-, LOS-, Cover- oder Enemy-AI-Rewrite.
- Kein Auto-Fire und kein Erzwingen eines Schusses fuer den Test.
- Keine neue HUD- oder Multiplayer-Wahrheit.

## Akzeptanzkriterien

- Der Trace setzt keine Enemy- oder Friendly-Position und keine
  Runtime-Statuswerte direkt.
- Nach dem echten Approach-Contact liefert der vorhandene Engagement-Snapshot
  einen sichtbaren Fire-/Wait-/No-Fire-Entscheid statt eines leeren Zustands.
- Der Snapshot zeigt Contact plus Grund und Deckungs-/Range-/LOS-Kontext.
- Evac bleibt im selben Lauf als read-only, host-autoritative Alternative
  erreichbar.

## Betroffene Dateien

- `scripts/tests/task_1079_station_route_real_first_exchange.gd`
- Task-/Status-/Roadmap-/Report-Dateien nach bestaetigtem Befund

## Lokale Pruefung

- TASK_1079, TASK_1078, TASK_1077, TASK_1069, TASK_1070, TASK_1071 und
  TASK_607.
- `git diff --check`.

## Risiken / offene Punkte

Ein `WAIT` oder `NO FIRE` kann taktisch korrekt sein, wenn der bestehende
Resolver einen Grund samt LOS-/Range-/Cover-Kontext zeigt. Eine spaetere
Balance-Aenderung darf nicht aus einem Test heraus Treffer erzwingen.

Der reale 192x192-End-to-End-Trace dauert rund drei Minuten und ist ein
Lifecycle-/Contract-Gate, kein Framerate-Benchmark.

## Ergebnis

Implementiert als reale Stations-Regression. TASK_1079 ist 12/12 gruen:
Der Scenario-Guard-Contact nach dem bestaetigten Approach-Move liefert ohne
Positions-, Status- oder Treffer-Manipulation einen bestehenden sichtbaren
Engagement-Entscheid, dessen Grund sowie Deckungs-/Range-/LOS-Kontext. LZ
Evac und die read-only Grenze bleiben im selben Lauf erhalten.
