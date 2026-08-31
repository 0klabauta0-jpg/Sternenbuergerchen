# TASK_1199 - Dominant Simulation Slice

## Status

Implementiert und verifiziert; Release bleibt blockiert.

## Grundlage und Ziel

Die Mess-/Produktionsbasis ist `bd8c2f4b343f0655898629001ca470253ee7cb77`. Der unveraenderte Mess-/Produktions-SHA fuer die P04-Evidence ist `c738a43bdade08ac26b836875b3d42a5121c3d8d`. Der Slice behandelt ausschliesslich den dominanten `move_to_position`-Command-Apply-Pfad.

## Aenderung

Exakt drei Movement-Requeue-Call-Sites geben `cmd` direkt an `enqueue_command()` weiter. Die eigene Deep-Copy-Grenze in `enqueue_command()` bleibt unveraendert und ist weiterhin die autoritative Queue-Speicherkopie. Es gibt keine Aenderung an Authority, UI-Truth, Snapshots, Payload, Reihenfolge oder sichtbarem Verhalten.

## Evidence und Verifikation

- RED: TASK-1199 17/18; ausschliesslich `oracle 0: movement requeues pass cmd directly` war rot.
- GREEN: TASK-1199 18/18, Exit 0.
- Regressionen: TASK-1198 24/24, TASK-162 23/23, TASK-166 15/15, TASK-168 20/20, TASK-501 10/10; `git diff --check` gruen.
- Gueltiger Cold-Control: total `117573`, queue `63893`, ordering `28`, apply `63870`, tick `116699`; move timing p99 `64329` (204 Samples), hold timing p99 `2071` (350 Samples), movement command-count p99 `4`, movement requeue-count p99 `1`.
- Offizielle 3-cold/5-warm-Serie: Exit 0, acht JSON-Laeufe mit exakt demselben SHA; je Lauf 1200 Main-Samples, 204 `move_to_position`-Timing-Samples, 350 `hold_position`-Timing-Samples, movement command-count p99 `4` und movement requeue-count p99 `1`.
- Baseline-Medianen: total `118948.5`, queue `63697`, ordering `29`, apply `63665`, tick `117608.5`, move `67793.5`, hold `2239.5` usec.
- Vollstaendige P04-Werte (je acht p99-Werte; usec): total `[116920,117860,118206,117230,118188,118024,118014,114867]`, Range `114867-118206`, Baseline `118948.5`, Median `117937`, Delta `-0.850%`; queue `[63745,64496,64109,62769,64255,64162,64667,62877]`, Range `62769-64667`, Baseline `63697`, Median `64135.5`, Delta `+0.688%`; ordering `[30,28,29,30,30,29,29,28]`, Range `28-30`, Baseline `29`, Median `29`, Delta `0%`; apply `[63723,64475,64080,62745,64222,64140,64644,62853]`, Range `62745-64644`, Baseline `63665`, Median `64110`, Delta `+0.699%`; tick `[116088,116988,116873,116404,117143,117019,116976,113908]`, Range `113908-117143`, Baseline `117608.5`, Median `116924.5`, Delta `-0.582%`; move timing `[67967,65362,66744,65734,64791,64115,66822,67013]`, Range `64115-67967`, Baseline `67793.5`, Median `66239`, Delta `-2.293%`; hold timing `[2179,2106,2335,2167,2099,2166,2189,2180]`, Range `2099-2335`, Baseline `2239.5`, Median `2173`, Delta `-2.969%`.
- Gate: keine andere Median-Regression `>5%`; die groesste andere Abweichung ist Apply `+0.699%`.

## Gate und Folge

Das Gate ist bestanden: Der ausgewaehlte `move_to_position`-Median ist reduziert, und keine andere Median-Regression ueberschreitet 5 %. Das ist eine eng begrenzte Optimierung und kein Gesamtbudget- oder Release-Nachweis. Release bleibt wegen der bestehenden Combat-/Simulation-/Interaktionsbudgets und fehlender echter TASK-1193-128x128-Manuell-Evidence blockiert. Naechster serieller Schritt ist TASK_1200.
