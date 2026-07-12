# TASK_1178 - HPA Cache Performance Recapture

## Ziel

TASK_1177 muss gegen denselben Station-Route-Trace zeigen, ob der Cache die
echte Command-Queue reduziert.

## Ergebnis

TASK_1175 bleibt 16/16 gruen. Gegen TASK_1176 sank die Route von rund 152,4 s
auf rund 101,8 s. Der langsamste Command-Queue-Scope sank von rund 1,37 s auf
rund 0,60 s. Der verbleibende groesste Scope ist `tick_signal_emit_usec` mit
rund 0,89 s; dieser gehoert zum Combat-Subscriber und ist der naechste
untersuchte Slice.

## Nicht-Ziele

Keine neue Pathfinding-, Combat- oder Multiplayer-Regel.
