# TASK_368 - FTL Readiness Gauge

## Ziel
Einen kompakten visuellen Gauge fuer FTL-Readiness bauen, der den Snapshot aus TASK_367 anzeigt.

## Status: GEPLANT

## Sinnhaftigkeitscheck
Der Review-Punkt ist sinnvoll, aber erst nach einem sauberen Snapshot. Der HTML-Snippet nutzt Defaultwerte; im Projekt darf die Anzeige stattdessen nur echte oder explizit unavailable Readiness-Daten visualisieren.

## Problem
Reaktionszeit, Moral und Planqualitaet sind zu textlastig und schwer schnell zu vergleichen.

## Ursache
Es gibt noch kein kleines Control, das FTL-Metriken auf enger Flaeche ohne neue Gameplay-Logik darstellt.

## Umfang
- `FTLReadinessGauge` als reines `Control` oder vorhandene Tactical-UI-Komponente einfuehren.
- Ringe/Balken fuer Reaction und Morale, farbliche Planqualitaet oder Label.
- Kleine Groesse mit stabiler Mindestdimension, keine Layout-Spruenge.
- Tooltip oder Snapshot-Metadaten fuer Testbarkeit, aber keine langen In-App-Erklaertexte.
- Nur `set_snapshot()` lesen; keine Resolver-Aufrufe direkt im Control.

## Akzeptanzkriterien
- [ ] Gauge rendert valide Snapshot-Werte deterministisch.
- [ ] Unavailable-Werte werden neutral und eindeutig angezeigt.
- [ ] Text passt in die feste Komponentengroesse.
- [ ] Headless-Verifier prueft Render-/Snapshot-Diagnose fuer high, medium und low Readiness.
- [ ] Gauge kann in Fireteam-Karten eingebettet werden, ohne deren Hoehe unkontrolliert wachsen zu lassen.

## Erwartete Dateien
- `scripts/ui/ftl_readiness_gauge.gd`
- `scripts/tests/task_368_ftl_readiness_gauge.gd`
- ggf. `scripts/ui/tactical_ui_theme.gd`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_368_ftl_readiness_gauge.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_367_ftl_public_readiness_snapshot_contract.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
- Mini-Kreisdiagramme koennen schnell zu klein werden. Falls die Lesbarkeit schlecht ist, soll der Task auf kompakte Balken umschwenken.
- Keine Animation einfuehren, wenn sie nicht klar testbar und performant bleibt.

