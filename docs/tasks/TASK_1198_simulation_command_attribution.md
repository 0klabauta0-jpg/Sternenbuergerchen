# TASK 1198 – Simulation Command Attribution

## Ziel und Ursache

Die verbleibende Simulation-Budgetüberschreitung musste nach Command-Typ und
Verarbeitungsphase aufgeschlüsselt werden. TASK 1198 liefert dafür ausschließlich
diagnostische, read-only Attribution; es enthält keine Runtime-Optimierung.

## Ergebnis

Die offizielle Messung erfolgte auf dem unveränderten Instrumentierungs-SHA
`f84e7173fa2c7b255f5dac44fb2e85827229af2e`. Acht von acht Läufen beendeten sich
mit Exit 0 und lieferten SHA-identische JSON-Reports. Pro Report wurden in den
Haupt-Scopes jeweils 1200 Samples gesammelt, conditional `move_to_position`
204 und `hold_position` 350 Samples.

| Scope / Command-Typ | p99-Werte (µs), Läufe 1–8 | Range | Median |
|---|---:|---:|---:|
| `command_queue_usec` | 66917, 65097, 68009, 64018, 63376, 62608, 62986, 61257 | 61257–68009 | 63697 |
| `command_ordering_usec` | 29, 27, 29, 29, 33, 29, 29, 28 | 27–33 | 29 |
| `command_apply_usec` | 66895, 65065, 67985, 63987, 63343, 62577, 62955, 61228 | 61228–67985 | 63665 |
| `move_to_position` | 68407, 69209, 84284, 67180, 65820, 79321, 63413, 60882 | 60882–84284 | 67793.5 |
| `hold_position` | 2126, 2070, 2709, 2230, 2249, 2305, 2421, 2102 | 2070–2709 | 2239.5 |
| `tick_signal_emit_usec` | 121134, 117298, 123024, 117556, 117661, 117797, 116420, 112988 | 112988–123024 | 117608.5 |
| `simulation_total_tick_usec` | 122229, 118298, 126398, 118745, 119152, 119801, 117426, 113832 | 113832–126398 | 118948.5 |

Die p99-Typzähler waren in allen acht Reports `move_to_position=4` und
`hold_position=4`; die Requeue-p99-Werte waren jeweils `move_to_position=1`
und `hold_position=0`. Die Zählersumme des fokussierten Per-Tick-Vertrags
entspricht der Zahl der verarbeiteten Commands. Per-Typ-Zeitwerte sind auf
Ticks mit vorhandenem Typ konditioniert und daher nicht additiv; sie dürfen
den All-Tick-p99 von `command_apply_usec` übersteigen.

Der erste Kaltlauf auf `193c7362276a64af16f6fd7821e1f82c9ac82ed1` ist als
ungültig verworfen: Der große Combat-Fixture-Pfad sammelte keine Attribution,
dadurch hatten Simulation 1200, die Typserien aber nur 200 bzw. 54 Samples.
Seine Werte gehören nicht zur offiziellen Serie.

## Deterministische Auswahl für P04 / TASK 1199

1. Ordering wird nicht gewählt: `29 / 63697` liegt deutlich unter 25 %.
2. `move_to_position` wird gewählt: `67793.5 / 63665` überschreitet 40 %,
   und der Typ ist in 8/8 Läufen dominant.
3. Der Signalpfad wird nicht gewählt, obwohl `117608.5 > 63697`, weil Regel 2
   bereits eindeutig gegriffen hat.

Damit ist exakt der Command-Apply-Pfad von `move_to_position` für TASK 1199
ausgewählt. P03 bleibt diagnostisch; Simulation- und Release-Budgets sind
weiterhin überschritten, daher besteht keine Release-Freigabe.

## Verifikation

- TASK-1198: 24/24
- TASK-162: 23/23
- TASK-166: 15/15
- TASK-168: 20/20
- TASK-501: 10/10
- TASK-218: 81/81
- 8/8 Exit 0, SHA-identische Reports
- `git diff --check`: grün
