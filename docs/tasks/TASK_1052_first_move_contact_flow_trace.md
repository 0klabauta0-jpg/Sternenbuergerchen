# TASK_1052 - First Move and Contact Flow Trace

## Befund

Der komplette Spielerflow erreicht Start, LZ/Drop/Deboard sowie ersten Move und GO innerhalb der Stage-Budgets. Der First-Contact-Snapshot bleibt `review`, weil die Testposition noch keinen gueltigen LOS-Kontakt erzeugt; mehr Detection-Ticks allein aendern das nicht.

## Naechster Schritt

TASK_1053 erstellt eine reproduzierbare First-Contact-Fixture mit belegter LOS, dann prueft der Trace Contact-Report, Overlay und Cover-/Threat-Kontext als echten Spielerzustand.
