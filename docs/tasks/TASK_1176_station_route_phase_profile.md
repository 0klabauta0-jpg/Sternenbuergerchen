# TASK_1176 - Station Route Phase Profile

## Ziel / Problem

Die grossen Station-Route-Traces dauern headless sehr lange, aber der
dominante Abschnitt ist bislang nicht belegt.

## Umfang

- Der bestehende reale AA-Trace misst Setup, Route und AA-Interaction.
- Pro Route-Tick werden Walltime und autoritatives Simulation-Budget gelesen.
- Keine Runtime- oder Gameplay-Regel wird geaendert.

## Akzeptanzkriterien

- Der Trace gibt eine `TASK_1176_PHASE_PROFILE`-Zeile aus.
- Setup-, Route- und Interaction-Dauer sowie langsamster Tick sind sichtbar.
- TASK_1175 bleibt gruen.

## Ergebnis

Implementiert im Arbeitsstand. TASK_1175 bleibt 16/16 gruen und exportiert
`TASK_1176_PHASE_PROFILE`. Auf dem aktuellen Rechner lagen Setup bei rund
102,4 s, die beschleunigte AA-Route bei rund 152,4 s und die AA-Interaction
bei rund 10,3 s. Der langsamste Route-Tick lag bei rund 2,14 s; davon entfielen
rund 1,37 s auf `command_queue_usec` und rund 0,78 s auf
`tick_signal_emit_usec`. Effect-, Avoidance-, Objective- und Spacing-Scopes
waren in diesem Tick klein.

Der Befund zeigt einen naechsten engen Produktpfad: Formations-Path-Requests
und der Combat-Subscriber muessen fuer grosse Bewegungsstufen getrennt
profiliert und getaktet werden. Der Task aendert keine Runtime-Regel.
