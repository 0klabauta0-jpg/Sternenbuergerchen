# TASK_1183 - Verifier- und Runner-Exitvertrag

## Ziel

Ein fachlich fehlgeschlagener Verifier oder nativer Godot-Prozess darf nicht mit
Exit 0 als gruener Lauf erscheinen.

## Umfang

- Alle GDScript-Verifier mit einem `_failed`-Zaehler beenden bei Fehlern mit
  einem nicht-null Exit-Code.
- Jeder `run_task_*.ps1`-Runner sichert den nativen Exit-Code unmittelbar vor
  weiteren Befehlen.
- `budget_exceeded` im TASK_1045-Timingtrace wird als echter Fehler gezaehlt.

## Nicht-Ziele

- Keine Aenderung fachlicher Assertions, Fixtures oder Budgets.
- Keine Unterdrueckung von Engine-Fehlerausgaben.

## Akzeptanz

- Der dynamische TASK_1183-Audit meldet null Treffer.
- Ein absichtlich fehlgeschlagener Verifier und ein absichtlich zu enges
  Timingbudget liefern Exit 1.
